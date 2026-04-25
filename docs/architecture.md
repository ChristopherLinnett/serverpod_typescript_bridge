# serverpod_typescript_bridge — Architecture

## Goal

Generate a fully-typed TypeScript client package for a Serverpod project, so a TS/JS frontend (React, Vue, plain JS) can call a Serverpod backend with end-to-end type safety, parity-mirroring `serverpod generate` for the Dart client.

## Top-level shape

```
┌──────────────────────────┐    ┌─────────────────────────────┐    ┌────────────────────────────────┐
│  Serverpod server pkg    │    │  serverpod_typescript_      │    │  <project>_typescript_client/  │
│  lib/src/endpoints/*.dart│───▶│  bridge (this package)      │───▶│  package.json                  │
│  lib/src/models/*.yaml   │    │  ─ analyzer (reused)        │    │  tsconfig.json                 │
│  config/generator.yaml   │    │  ─ TS emitter (ours)        │    │  src/protocol/                 │
└──────────────────────────┘    └─────────────────────────────┘    │    client.ts                   │
                                                                   │    protocol.ts                 │
                                                                   │    <one_per_model>.ts          │
                                                                   │  src/runtime/                  │
                                                                   │    (vendored TS runtime)       │
                                                                   └────────────────────────────────┘
```

## Two-tier design

The package has two cleanly separable pieces:

1. **The generator** — Dart code that runs at build-time. Analyzes the Serverpod project and emits TypeScript files. Lives in `lib/` and `bin/`.
2. **The TypeScript runtime** — TypeScript source that the *generated* client depends on. Lives as TS source files in `lib/runtime/` (included in the Dart package); copied verbatim into each generated client at generate time.

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

We will:
- Add `serverpod_cli: ^3.4.7` as a dependency.
- Use `GeneratorConfig.load()` for project discovery and config parsing.
- Use `EndpointsAnalyzer` + `SerializableModelAnalyzer` to produce a `ProtocolDefinition` (the same IR Serverpod uses internally).
- Walk the IR and emit TypeScript.

**Why reuse over re-implement:**
- Single source of truth — we inherit every feature the Dart generator already understands (current and future).
- Zero parser drift — when Serverpod adds a new feature, the IR carries it for us automatically.
- All edge cases (sealed hierarchies, records, doc-comment macros, `@unauthenticatedClientCall`, module prefixing) are already handled by analyzers we don't have to maintain.
- The `protocol.yaml` Serverpod emits is too shallow (just `endpointName: [methodNames]`) — confirmed by reading `EndpointDescriptionGenerator`. So we cannot use it as the bridge.

**Risk:** we depend on a Serverpod-internal-but-public-exported API. If Serverpod renames/restructures it, we break. Mitigation: pin the Serverpod minor version range in `pubspec.yaml`, run CI against multiple Serverpod versions, fail loudly if the IR shape changes (compile-time check in our walker).

---

## Backend: TypeScript code emission

A small Dart-side TS emitter:

- `lib/src/emit/ts_writer.dart` — line-buffered writer with indent tracking.
- `lib/src/emit/ts_type_mapper.dart` — single function `mapType(TypeDefinition) → TsType`. Owns the canonical Dart→TS mapping.
- `lib/src/emit/model_emitter.dart` — emits one TS file per `ClassDefinition`/`EnumDefinition`/`ExceptionClassDefinition`.
- `lib/src/emit/endpoint_emitter.dart` — emits `client.ts` (per-endpoint classes + top-level `Client`).
- `lib/src/emit/protocol_emitter.dart` — emits `protocol.ts` (the `Protocol extends SerializationManager` with the deserialize switch).
- `lib/src/emit/scaffold_emitter.dart` — emits `package.json`, `tsconfig.json`, `index.ts`, `.gitignore`, copies the runtime.

**Why a hand-rolled emitter, not `code_builder`-equivalent?**
- No mature Dart library that emits TS.
- The generated TS surface is small and stable; our writer needs ~200 lines.
- Avoiding a Node-side toolchain (e.g. `ts-morph`) means our Dart CLI has zero external runtime dependencies.

### Type mapping (canonical table)

| Dart                          | TypeScript                       | JSON wire form                |
|-------------------------------|----------------------------------|-------------------------------|
| `int`, `double`               | `number`                         | number                        |
| `bool`                        | `boolean`                        | boolean (also accepts 0/1)    |
| `String`                      | `string`                         | string                        |
| `DateTime`                    | `Date`                           | ISO-8601 UTC string           |
| `Duration`                    | `number` (ms)                    | integer ms                    |
| `BigInt`                      | `bigint`                         | string                        |
| `UuidValue`                   | `string`                         | string                        |
| `Uri`                         | `string`                         | string                        |
| `ByteData` / `Uint8List`      | `Uint8Array`                     | base64 string                 |
| `List<T>`                     | `T[]`                            | array                         |
| `Set<T>`                      | `Set<T>`                         | array                         |
| `Map<String, V>`              | `Record<string, V>`              | object                        |
| `Map<K, V>` (K ≠ String)      | `Map<K, V>`                      | array of `{k, v}` pairs       |
| `T?`                          | `T \| null`                      | omitted or `null`             |
| `enum E`                      | TS `enum E` (or const union)     | int (byIndex) or string (byName) |
| `class M`                     | TS `class M`                     | object with `__className__`   |
| `sealed class S` / subclasses | discriminated union via `__className__` | object with `__className__` |
| Records `(int, {String n})`   | TS object literal type           | (special — see "Records")     |
| `Vector(N)` / `HalfVector` etc| `number[]`                       | array of numbers              |

### Doc comments

Every Dart `///` comment passes through verbatim into a TSDoc `/** */` block. `{@template foo} ... {@endtemplate}` and `{@macro foo}` are already resolved by the analyzer's `DartDocTemplateRegistry`, so we don't have to handle them ourselves.

### Models — generated TS shape

```ts
/** Represents a logged-in user. */
export class User implements SerializableModel {
  id: number | null;
  email: string;
  joinedAt: Date;

  constructor(init: { id?: number | null; email: string; joinedAt: Date }) {
    this.id = init.id ?? null;
    this.email = init.email;
    this.joinedAt = init.joinedAt;
  }

  static fromJson(json: Record<string, unknown>): User {
    return new User({
      id: json.id as number | null,
      email: json.email as string,
      joinedAt: new Date(json.joinedAt as string),
    });
  }

  toJson(): Record<string, unknown> {
    return {
      __className__: 'User',
      ...(this.id !== null && { id: this.id }),
      email: this.email,
      joinedAt: this.joinedAt.toISOString(),
    };
  }

  copyWith(partial: Partial<{ id: number | null; email: string; joinedAt: Date }>): User {
    return new User({
      id: partial.id !== undefined ? partial.id : this.id,
      email: partial.email ?? this.email,
      joinedAt: partial.joinedAt ?? this.joinedAt,
    });
  }
}
```

For sealed hierarchies, we emit an abstract base class plus concrete subclasses, with a discriminated-union TS type alias and a `fromJson` that dispatches on `__className__`:

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

Public-call endpoints add `{ authenticated: false }`:

```ts
async ping(): Promise<void> {
  return this.caller.callServerEndpoint<void>('public', 'ping', {}, { authenticated: false });
}
```

### Top-level `Client`

```ts
export class Client extends ServerpodClientShared {
  readonly greeting: EndpointGreeting;
  readonly users: EndpointUsers;
  readonly modules: Modules;

  constructor(host: string, opts?: ClientOptions) {
    super(host, new Protocol(), opts);
    this.greeting = new EndpointGreeting(this);
    this.users = new EndpointUsers(this);
    this.modules = new Modules(this);
  }

  override get endpointRefLookup(): Record<string, EndpointRef> {
    return { greeting: this.greeting, users: this.users };
  }
}
```

---

## TypeScript runtime (`lib/runtime/`)

A hand-written TS package that mirrors `serverpod_client`. Lives in this Dart package as `lib/runtime/typescript/` and is copied verbatim into each generated client at generate time.

**Tradeoff considered:**
- *Vendored* (chosen for v0.1): zero npm publish dependency, generated client is self-contained.
- *Published npm package* (deferred to v0.2): smaller generated output, runtime upgrades without regen.

The vendored approach lets us iterate on the runtime + generator together without coordinating npm releases. Once stable, we publish `@chrislinnett/serverpod-client-ts` and the generator switches to importing from npm; users just need to regen.

### Runtime surface

```
lib/runtime/typescript/
├── src/
│   ├── client.ts              # ServerpodClientShared, ClientOptions, MethodCallContext
│   ├── endpoint.ts            # EndpointRef, EndpointCaller, ModuleEndpointCaller
│   ├── exceptions.ts          # ServerpodClientException + HTTP-status subclasses
│   ├── auth.ts                # ClientAuthKeyProvider, RefresherClientAuthKeyProvider
│   ├── serialization.ts       # SerializationManager (encode/decode), wire converters
│   ├── http_transport.ts      # fetch-based unary call dispatch
│   ├── ws_transport.ts        # WebSocket-based streaming dispatch
│   ├── ws_messages.ts         # Sealed message types matching websocket_messages.dart
│   └── index.ts               # barrel
├── package.json
├── tsconfig.json
└── README.md
```

### Wire format — must match Dart byte-for-byte

The runtime's `SerializationManager` mirrors `serverpod_serialization`:

- HTTP unary: `POST <host>/<endpointName>`, body = `JSON.stringify({ method: '<methodName>', ...args })` after each value is converted to wire form.
- HTTP error mapping (matches `getExceptionFrom` in Dart):
  - `400 → BadRequest`, `401 → Unauthorized`, `403 → Forbidden`, `404 → NotFound`, `500 → InternalServerError`
  - If body is `{className, data}`, decode as a typed `SerializableException` via `Protocol.deserializeByClassName`.
- Auth header: `Authorization: <wrappedAuthValue>`.
- Streaming: `WebSocket` to `<host>/v1/websocket` (auth via `?auth=<unwrappedValue>`); message envelope `{type, data}`; `OpenMethodStreamCommand` carries `args` as a *double-encoded JSON string* (matching the Dart contract exactly).

These rules are spec'd by tests, not by the generator. The runtime test suite asserts the exact wire form for every primitive and every message type.

---

## CLI shape

```
$ dart run serverpod_typescript_bridge --help

Generate a TypeScript client for a Serverpod project.

Usage: serverpod_typescript_bridge <command> [arguments]

Commands:
  generate   Generate the TypeScript client package next to the Serverpod server.
  inspect    Print the parsed protocol IR as JSON (for debugging).

Options:
  -d, --directory   Path to the Serverpod server package (auto-detected if omitted).
  -w, --watch       Re-generate on file changes.
```

The flag set intentionally mirrors `serverpod generate`.

---

## Dependency policy

| Dep                  | Why                                            | Version range                |
|----------------------|------------------------------------------------|------------------------------|
| `serverpod_cli`      | Reused analyzer + IR                           | `^3.4.7` (pin minor)         |
| `args`               | CLI parsing                                    | `^2.5.0`                     |
| `path`               | Path manipulation                              | `^1.9.0`                     |
| `yaml`               | Reading `generator.yaml` (also used by cli)    | `^3.1.2`                     |
| `analyzer`           | Transitive via `serverpod_cli`; we don't import directly if avoidable | (transitive) |

We deliberately do **not** depend on `serverpod` itself — only `serverpod_cli`. The runtime bridges to user code via the IR, not by importing user types.

---

## Testing strategy

Three layers:

1. **Unit tests (Dart)** — each emitter, each type mapper, the project autodetection logic. Pure function tests, no I/O.
2. **Golden tests (Dart)** — feed a fixture `ProtocolDefinition` into the emitter, assert the exact emitted TS string against checked-in golden files. Catches all subtle output drift.
3. **Integration tests (Dart + TS)** — a real Serverpod fixture project lives in `test/fixtures/sample_server/`. Tests:
   - Run our generator against it
   - Run `tsc --noEmit` on the output
   - Run a TS test suite (vitest) that imports the generated client and round-trips against a live `serverpod_test` server harness
   - Asserts behaviour matches the Dart-client equivalent

The fixture project is the parity oracle — every supported Serverpod feature gets exercised there.

---

## Out of scope for v0.1

- Records (Dart 3 records as endpoint params/return). Defer until there's user demand.
- Watch mode. Nice-to-have but not blocking; the user can re-run `generate`.
- npm-published runtime. v0.2.
- IDE / LSP integration.

## In scope for v0.1 (shippable)

- Endpoints with primitive, model, collection, nullable, enum params/return
- Sealed hierarchies (required for serverpod_auth integration)
- Modules (required for serverpod_auth integration)
- Doc-comment passthrough
- HTTP unary calls with auth header
- Exceptions (typed via `SerializableException`)
- WebSocket streaming endpoints

## Versioning

- `0.1.x` — initial vendored-runtime release.
- `0.2.x` — npm-published runtime, npm dep declared in generated `package.json`.
- `1.0.0` — once the IR-shape contract has been stable across two Serverpod minor versions and a real production project has shipped on it.
