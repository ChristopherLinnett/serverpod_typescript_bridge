# serverpod_typescript_bridge — Architecture

## Goal

Generate a fully-typed TypeScript client package for a Serverpod project, so a TS/JS frontend (React, Vue, plain JS) can call a Serverpod backend with end-to-end type safety, parity-mirroring `serverpod generate` for the Dart client.

## Top-level shape (v0.2)

```
                                                              ┌──────────────────────────────────────┐
                                                          ┌──▶│  serverpod_auth_idp_typescript_client│
                                                          │   │  (auto-generated, sibling to app)    │
                                                          │   └──────────────────────────────────────┘
┌──────────────────────────┐    ┌─────────────────────────┐   ┌──────────────────────────────────────┐
│  Serverpod app server    │    │  serverpod_typescript_  │──▶│  serverpod_auth_core_typescript_client│
│  lib/src/endpoints/      │───▶│  bridge (this package)  │   │  (auto-generated, sibling to app)    │
│  lib/src/models/         │    │                         │   └──────────────────────────────────────┘
│  config/generator.yaml   │    │  ─ analyzer (reused)    │   ┌──────────────────────────────────────┐
│  pubspec.yaml            │    │  ─ discovery (modules)  │──▶│  <app>_typescript_client/            │
└──────────────────────────┘    │  ─ TS emitter (ours)    │   │  package.json (file:.. deps wired)   │
        │                       │  ─ post-build (npm)     │   │  tsconfig.json                       │
        ▼                       └─────────────────────────┘   │  src/                                │
.dart_tool/package_config.json                                │    runtime/  (vendored)              │
        │                                                     │    protocol/ (one .ts per model)     │
        └─────────── walked for module deps ──────────────────│    endpoints/ (one .ts per endpoint) │
                                                              │    client.ts                         │
                                                              │    protocol.ts                       │
                                                              └──────────────────────────────────────┘
```

The app client picks its module-client siblings up via `file:..` deps in `package.json`; `npm install` from the consumer resolves the whole graph in place. No npm publishing required.

## Two-tier design

The package has two cleanly separable pieces:

1. **The generator** — Dart code that runs at build time. Analyzes the Serverpod project (and every Serverpod module it depends on), then emits TypeScript files. Lives in `lib/` and `bin/`.
2. **The TypeScript runtime** — TypeScript source the *generated* clients depend on. Lives as TS source files in `lib/runtime/typescript/` and is copied verbatim into each generated client at generate time (vendored). v0.2 deliberately stayed vendored — see "Runtime distribution" below.

These two have separate concerns, separate tests, and could be split into separate releases later.

---

## Frontend: reuse Serverpod's analyzer

`package:serverpod_cli/analyzer.dart` is a public library that exports everything we need:

```dart
import 'package:serverpod_cli/analyzer.dart';

// Available: EndpointsAnalyzer, SerializableModelAnalyzer,
// ProtocolDefinition, GeneratorConfig, TypeDefinition,
// ClassDefinition, EnumDefinition, ExceptionClassDefinition,
// SerializableModelFieldDefinition, FutureCallsAnalyzer, ...
```

The package additionally reaches into a small set of `serverpod_cli/src/` paths (StatefulAnalyzer, ModelHelper, CodeGenerationCollector, the experimental-features singleton, ModuleConfig, ServerpodFeature). That coupling is documented in `lib/src/analyzer/protocol_loader.dart`'s file header; Serverpod's own internal generators (e.g. `EndpointDescriptionGenerator`) use the same `src/` types, so the IR shape is stable across patch releases.

We:
- Add `serverpod_cli: ^3.4.7` and `serverpod_shared: ^3.4.7` as deps.
- Use `GeneratorConfig.load()` for the **app's** project discovery and config parsing.
- For **module** packages (loaded out of pub-cache), `GeneratorConfig.load` would fail because it validates the sibling Dart client package — pub-cache modules don't ship one. `ProtocolLoader.loadForModule(...)` synthesises a minimal `GeneratorConfig` from the module's own `pubspec.yaml` + `config/generator.yaml` instead, populating only the fields the IR analyzers actually consult.
- Use `EndpointsAnalyzer` + `StatefulAnalyzer` to produce a `ProtocolDefinition` (the same IR Serverpod uses internally).
- Walk the IR and emit TypeScript.

**Why reuse over re-implement:**
- Single source of truth — we inherit every feature the Dart generator already understands.
- Zero parser drift — when Serverpod adds a new feature, the IR carries it for us automatically.
- All edge cases (sealed hierarchies, doc-comment macros, `@unauthenticatedClientCall`, module prefixing) are already handled by analyzers we don't have to maintain.
- The `protocol.yaml` Serverpod emits is too shallow (just `endpointName: [methodNames]`) — confirmed by reading `EndpointDescriptionGenerator`. So we cannot use it as the bridge.

**Risk:** we depend on a Serverpod-internal-but-public-exported API. If Serverpod renames/restructures it, we break. Mitigation: pin the Serverpod minor version range in `pubspec.yaml`, run CI against multiple Serverpod versions, fail loudly if the IR shape changes.

---

## Module discovery (v0.2)

```
lib/src/discovery/
├── module_discoverer.dart       — walks `.dart_tool/package_config.json` upward from the
│                                  server dir, filters to packages whose
│                                  `config/generator.yaml` declares `type: module`. Skips
│                                  the project itself when it is module-typed.
├── module_client_layout.dart    — per-module output dir + npm name resolution; default
│                                  `<server>/../<module-stripped-of-_server>_typescript_client/`,
│                                  overridable via `typescript_client_modules:` in
│                                  generator.yaml.
├── module_class_index.dart      — `className → ModuleClientLayout` index; built once per
│                                  generation by walking each discovered module's IR.
│                                  Tracks sealed/enum class names separately.
│                                  `excluding(localNames)` returns a per-run-scoped copy
│                                  so the project being emitted doesn't self-import.
└── server_directory_finder.dart — walks up from cwd looking for the Serverpod server pkg.
```

The `ModuleClassIndex` is the cross-package bridge: when emitting the app client, the type mapper consults it to decide whether `AuthSuccess` (say) is a local model, a module-defined class (→ cross-package import), or genuinely unknown (→ `unknown` fallback).

---

## Backend: TypeScript code emission

```
lib/src/emit/
├── ts_writer.dart           — line-buffered writer with indent tracking
├── ts_type_mapper.dart      — single Dart→TS mapping function. Owns the canonical table
│                              below; consults `projectClassNames` (local-wins) then
│                              `moduleIndex` (cross-package) then `unknown` fallback
├── module_import_lines.dart — groups referenced module classes by npm package and
│                              emits one alphabetised `import { ... } from '<pkg>';` line
│                              per package (plus the matching `Codec`/`Base` siblings)
├── model_emitter.dart       — one TS file per model / exception / enum / sealed base,
│                              plus the `protocol/index.ts` barrel (with `export {};`
│                              fallback if empty)
├── endpoint_emitter.dart    — one TS file per endpoint, plus the `endpoints/index.ts`
│                              barrel (same `export {};` fallback)
├── client_emitter.dart      — top-level `client.ts` (or `<Nickname>Caller` for modules)
│                              + `protocol.ts` (the `Protocol extends SerializationManager`
│                              with the deserialize switch, including module-class cases)
├── scaffold_emitter.dart    — `package.json` (with `file:..` deps), `tsconfig.json`,
│                              `.gitignore`, `src/index.ts` barrel, copies the runtime
├── output_paths.dart        — resolves where the TS client package lives (CLI flag,
│                              generator.yaml override, or default sibling-to-server)
└── generated_file_tracker.dart — records every file we write so an orphan sweep can
                                 delete stale outputs from a previous gen run
```

The **generation pipeline** that ties these together:

```
lib/src/cli/generation_pipeline.dart
  GenerationPipeline.run({serverDir, outputDir, moduleIndex,
                          isModulePackage, knownModules})
    1. Load config (real or synthesised for modules)
    2. Load IR via ProtocolLoader
    3. Compute per-run scoped moduleIndex (excludes local class names)
    4. Walk IR for cross-package referenced classes
    5. ScaffoldEmitter (package.json, tsconfig.json, runtime copy, index)
    6. ModelEmitter   (mapper without `p.` prefix)
    7. EndpointEmitter (mapper WITH `p.` prefix — endpoints reach into protocol/)
    8. ClientEmitter  (top-level client.ts + protocol.ts switch)
    9. tracker.sweepOrphans()
```

`generate_command.dart` then drives this twice: first per discovered module (with `isModulePackage: true`), then once for the app. With `--build` (default), it also runs `npm install` + `npm run build` per generated client in dependency order so the consumer's `npm install` of the app client resolves a built graph.

### Type mapping (canonical table)

| Dart                          | TypeScript                       | JSON wire form                |
|-------------------------------|----------------------------------|-------------------------------|
| `int`, `double`, `num`        | `number`                         | number                        |
| `bool`                        | `boolean`                        | boolean (also accepts 0/1)    |
| `String`                      | `string`                         | string                        |
| `DateTime`                    | `Date`                           | ISO-8601 UTC string           |
| `Duration`                    | `number` (ms)                    | integer ms                    |
| `BigInt`                      | `bigint`                         | string                        |
| `UuidValue`, `Uri`            | `string`                         | string                        |
| `ByteData` / `Uint8List`      | `Uint8Array`                     | base64 string                 |
| `List<T>`                     | `T[]`                            | array                         |
| `Set<T>`                      | `Set<T>`                         | array                         |
| `Map<String, V>`              | `Record<string, V>`              | object                        |
| `Map<K, V>` (K ≠ String)      | `Map<K, V>`                      | array of `{k, v}` pairs       |
| `T?`                          | `T \| null`                      | omitted on the wire when null |
| `void`                        | `void` (returns `undefined`)     | (no body)                     |
| `dynamic`, `Object`           | `unknown`                        | passthrough                   |
| `enum E` (project-local)      | TS `enum E` + sibling `ECodec`   | int (byIndex) or string (byName) |
| `enum E` (module-defined)     | imported `E` + `ECodec`          | same                          |
| `class M` (project-local)     | TS `class M`                     | object with `__className__`   |
| `class M` (module-defined)    | imported `M` from `<module-pkg>` | same; wire form `<prefix>.M`  |
| `sealed class S`              | discriminated union via `__className__` (with `<Name>Base` dispatcher) | object with `__className__` |
| Foreign / unknown class       | `unknown /* TODO */`             | passthrough                   |

### Doc comments

Every Dart `///` comment passes through verbatim into a TSDoc `/** */` block. `{@template foo} ... {@endtemplate}` and `{@macro foo}` are already resolved by the analyzer's `DartDocTemplateRegistry`, so we don't have to handle them ourselves.

### Models — generated TS shape

```ts
/** Represents a logged-in user. */
export class User implements SerializableModel {
  id: number | null;
  email: string;
  joinedAt: Date;

  // Nullable fields are OMITTABLE on the constructor's init bag and
  // default to `null` at construction. Non-nullable fields stay required.
  // (v0.2.4)
  constructor(init: { id?: number | null; email: string; joinedAt: Date }) {
    this.id = init.id ?? null;
    this.email = init.email;
    this.joinedAt = init.joinedAt;
  }

  static fromJson(json: Record<string, unknown>): User { ... }
  toJson(): Record<string, unknown> { ... }
  copyWith(partial: Partial<{ id: number | null; ... }>): User { ... }
}
```

For sealed hierarchies, we emit an abstract base class plus concrete subclasses, with a discriminated-union TS type alias and a `fromJson` that dispatches on `__className__`. The dispatcher walks the full sealed-ancestor chain so multi-level hierarchies (sealed `A` → sealed `B` → concrete `C`) all resolve correctly:

```ts
export type Animal = Dog | Cat;
export abstract class AnimalBase implements SerializableModel {
  abstract toJson(): Record<string, unknown>;
  static fromJson(json: Record<string, unknown>): Animal {
    switch (json.__className__) {
      case 'Dog': return Dog.fromJson(json);
      case 'Cat': return Cat.fromJson(json);
      default: throw new Error(`Unknown Animal subtype: ${json.__className__}`);
    }
  }
}
```

The top-level `Protocol.deserializeByClassName` strips an optional `<module>.` prefix from incoming `__className__` values before switching, so a server's `auth.AuthSuccess` and a bare `AuthSuccess` both dispatch to the same case.

### Endpoints — generated TS shape

```ts
/** Greeting endpoint. */
export class EndpointGreeting extends EndpointRef {
  override get name(): string { return 'greeting'; }

  /** Say hello to a user. */
  async sayHello(name: string): Promise<string> {
    return this.caller.callServerEndpoint<string>('greeting', 'sayHello', { name });
  }

  /** @deprecated Use `sayHello` instead. */
  async sayHi(name: string): Promise<string> {
    return this.caller.callServerEndpoint<string>('greeting', 'sayHi', { name });
  }
}
```

Public-call endpoints (`@unauthenticatedClientCall`) add `{ authenticated: false }`. Optional named params emit `?:` (omittable); optional positional params likewise. Required-positional and `required`-named params stay required to match the Dart contract. Wire keys always use the original Dart parameter name even when the local TS variable is escaped (so a Dart param named `class` keeps `class:` on the wire).

Streaming endpoints emit a non-async signature returning `AsyncIterable<T>`:

```ts
chat(named: { since?: Date | null }, streams: { incoming: AsyncIterable<string> }):
  AsyncIterable<string>
{
  return this.caller.callStreamingServerEndpoint<string>(
    'chat', 'chat', { since: named.since },
    (raw) => raw as string,
    { incoming: { iterable: streams.incoming, encode: (v) => ({...}) } },
  ) as unknown as AsyncIterable<string>;
}
```

### Top-level `Client`

```ts
export class Client extends ServerpodClientShared {
  readonly greeting: EndpointGreeting;
  readonly users: EndpointUsers;
  readonly modules: Modules;   // present only when the project declares modules

  constructor(host: string, options: ClientOptions = {}) {
    super(host, new Protocol(), options);
    this.greeting = new EndpointGreeting(this);
    this.users = new EndpointUsers(this);
    this.modules = new Modules(this);
  }
}
```

The `Modules` companion currently exposes `unknown`-typed accessors per declared module (a stub). Cross-package types resolve directly through the generated module client packages (`import { AuthSuccess } from 'serverpod_auth_idp_typescript_client'`), and `Protocol.deserializeByClassName` dispatches module classes through the matching package's `<Name>(.fromJson|Codec.fromJson|Base.fromJson)`. A typed `Modules.<nickname>: <Caller>` surface is post-v0.2 work.

For module-typed projects (`type: module` in `generator.yaml`), the same emitter writes `<Nickname>Caller extends ModuleEndpointCaller` instead, plus a `modulePrefix` const carrying the nickname so consumers know what to expect on the wire.

---

## TypeScript runtime (`lib/runtime/typescript/`)

A hand-written TS package that mirrors `serverpod_client`. Lives in this Dart package as `lib/runtime/typescript/` and is copied verbatim into each generated client at generate time.

### Runtime distribution (vendored)

The runtime stays vendored in the v0.2 line. The original v0.1 plan was to publish it to npm in v0.2 and have the generator declare it as a regular `dependencies` entry; v0.2 went a different direction (module-aware generation) and the vendored approach turned out to compose cleanly with the new `file:..` module-deps wiring — every generated package brings its own runtime copy and there's no version skew across module clients in a graph. Migration to a published runtime stays an option but isn't on a date.

### Runtime surface

```
lib/runtime/typescript/src/
├── client.ts         — ServerpodClientShared, ClientOptions, MethodCallContext
├── endpoint.ts       — EndpointRef, EndpointCaller, ModuleEndpointCaller, HttpEndpointCaller
├── exceptions.ts     — ServerpodClientException + status-mapped subclasses (400/401/403/404/500)
├── serialization.ts  — SerializationManager (abstract; project Protocol extends it)
│                       + per-primitive encode*/decode* helpers, decodeMap, decodeRecord
├── http_transport.ts — fetch-based unary call dispatch (auth header, 401 refresh)
├── ws_transport.ts   — WebSocket-based streaming dispatch (multiplexed handlers,
│                       per-handler iterator semantics, server ping/pong, bad_request
│                       failure propagation, status-mapped open errors)
├── ws_messages.ts    — Sealed message types matching websocket_messages.dart
├── types.ts          — SerializableModel, SerializableException, ClientAuthKeyProvider,
│                       RefreshableClientAuthKeyProvider
└── index.ts          — barrel re-export
```

### Wire format — must match Dart byte-for-byte

The runtime's `SerializationManager` mirrors `serverpod_serialization`:

- **HTTP unary:** `POST <host>/<endpointName>`, body = `JSON.stringify({ method: '<methodName>', ...args })` after each value is converted to wire form. Status-mapped error envelopes (400/401/403/404/500) are decoded into their TS exception subclasses; typed `{className, data}` envelopes decode through `Protocol.deserializeByClassName`.
- **Auth header:** `Authorization: <wrappedAuthValue>`. Suppressed when the call site sets `{ authenticated: false }`. If the provider implements `RefreshableClientAuthKeyProvider` and the server returns 401, the runtime calls `refresh()` once and retries.
- **WebSocket streaming:** `ws://<host>/v1/websocket?auth=<rawKey>` (the runtime strips a `Bearer ` / `Basic ` prefix from the auth header value before putting it in the query). Messages use a `{type, data}` envelope; `OpenMethodStreamCommand` carries `args` as a *double-encoded JSON string* matching the Dart contract. Server-initiated `ping` is replied to with `pong`; `bad_request` fails every active handler with a 400-status exception.
- **Primitive encodings:** ISO-8601 UTC for `Date`, integer ms for `Duration`, base64 for `Uint8Array`, string for `BigInt`, list of `{k,v}` for non-string-keyed maps.

These rules are spec'd by `vitest` tests in `lib/runtime/typescript/src/__tests__/`, not by the generator.

---

## CLI shape

```
$ dart run serverpod_typescript_bridge --help

Generate a TypeScript client for a Serverpod project.

Usage: serverpod_typescript_bridge <command> [arguments]

Commands:
  generate   Generate the TypeScript client package next to the Serverpod project.
  inspect    Print the parsed protocol IR as JSON (for debugging).

Options (generate):
  -d, --directory      Path to the Serverpod server package (auto-detected if omitted).
  -o, --output         Path to the TypeScript client package to (re-)generate.
                       Default: <server>/../<name>_typescript_client/
                       Override via `typescript_client_package_path` in generator.yaml.
      --[no-]build         npm install + npm run build per generated client (default: on).
                           Modules first, then app. Build failures are non-fatal.
      --[no-]gen-modules   Recursively generate TS clients for every module dep
                           (default: on).
```

`--watch` (re-generate on file changes) was sketched in v0.1 but isn't implemented. `serverpod generate` itself doesn't drive a watch loop into our generator yet.

### Per-module overrides in `generator.yaml`

```yaml
typescript_client_modules:
  serverpod_auth_idp_server:
    output: ../my_custom_path
    npm_name: '@my-org/auth-idp-ts'
```

---

## Dependency policy

| Dep                  | Why                                                                | Version range          |
|----------------------|--------------------------------------------------------------------|------------------------|
| `serverpod_cli`      | Reused analyzer + IR                                               | `^3.4.7` (pin minor)   |
| `serverpod_shared`   | `DatabaseDialect` for the synthesised module GeneratorConfig       | `^3.4.7`               |
| `args`               | CLI parsing                                                        | `^2.5.0`               |
| `path`               | Path manipulation                                                  | `^1.9.0`               |
| `yaml`               | Reading `generator.yaml`                                           | `^3.1.2`               |
| `analyzer`           | Required by serverpod_cli's analyzer chain; we import a few internals via the `// ignore_for_file: implementation_imports` policy documented in `protocol_loader.dart` | `^8.1.0` |
| `meta`               | `@visibleForTesting` on `ModuleClassIndex.forTesting`               | `^1.16.0`              |
| `pub_semver`         | Version constraint parsing (transitively required)                 | `^2.1.4`               |

We deliberately do **not** depend on `serverpod` itself — only `serverpod_cli`. The runtime bridges to user code via the IR, not by importing user types.

---

## Testing strategy

Three layers:

1. **Unit tests (Dart)** — focused tests for individual emitters / helpers / discovery components: `module_discoverer`, `module_client_layout`, `module_import_lines`, `client_emitter_modules`, `empty_barrel_emission`, `nullable_constructor_omission`, `ts_writer`, `output_paths`, `generated_file_tracker`. All registered in `dart_test.yaml`.
2. **Fixture-driven integration tests (Dart)** — drive the CLI as a subprocess against committed Serverpod fixtures (`test/fixtures/sample_server/` and `test/fixtures/sample_module/`), then assert on the generated source. `generate_command_test` additionally runs the generated package through `npm install` + `tsc` to catch downstream type errors. `module_emission_test` and `bidi_streaming_emission_test` cover the module-typed and streaming paths respectively.
3. **TypeScript runtime tests (vitest)** — every primitive converter (round-trip both directions), every HTTP status mapping, the auth-refresh single-retry behaviour, and the WS envelope parser. Lives under `lib/runtime/typescript/src/__tests__/`.

The committed fixtures (`sample_server`, `sample_module`) are the parity oracle — every supported Serverpod feature gets exercised there. Adding a new feature surface = update the fixture, regenerate, commit the regenerated `lib/src/generated/` alongside.

Current totals: **109 Dart tests, 62 TypeScript tests** (as of v0.2.4). Both layers must pass before opening a PR.

---

## Versioning

| Tag    | Theme                                                                       |
|--------|-----------------------------------------------------------------------------|
| `0.1.x`| Initial vendored-runtime release; full Serverpod feature surface (endpoints, models, sealed hierarchies, enums, exceptions, streaming, modules as `Caller`-emission-only). |
| `0.2.x`| Module-aware generation: the consumer side. Recursive generation per module dep (sibling layout), `file:..` deps wiring, cross-package `import { Name } from '<module-pkg>';` lines, protocol switch dispatching module classes. v0.2.4 added omittable-nullable model constructors. |
| `1.0.0`| Once the IR-shape contract has been stable across two Serverpod minor versions and a real production project has shipped on it. |

## Out of scope (post-v0.2)

- **Records** (Dart 3 records as endpoint params/return). Defer until there's user demand.
- **Watch mode.** Nice-to-have but not blocking; the user can re-run `generate`.
- **npm-published runtime.** Vendored is composing well with the v0.2 module-deps wiring; a published runtime stays an option but isn't on a date.
- **Typed `Modules.<nickname>: <Caller>` surface.** Currently a `unknown`-typed stub; cross-package types resolve directly through their generated packages.
- **IDE / LSP integration.**
