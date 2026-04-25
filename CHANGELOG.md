## 0.2.0

- Module-aware generation. The CLI now walks `.dart_tool/package_config.json`
  for the project's Serverpod module dependencies and recursively generates a
  TS client for each as a sibling of the app client (default
  `<server>/../<module>_typescript_client/`). The app client's `package.json`
  declares the module clients via `file:..` deps so a single `npm install`
  resolves the whole graph in place — no npm publishing required.
- Cross-package emission. Model and endpoint files now emit
  `import { Name<, NameBase>?<, NameCodec>? } from '<module-pkg>';` lines for
  every module-defined type they reference, instead of falling back to the
  v0.1.4 `unknown /* TODO */` placeholder. Sealed bases bring in `Name + NameBase`,
  enums bring in `Name + NameCodec`, plain classes bring in `Name`.
- Protocol switch dispatches module classes. The generated `Protocol`'s
  `deserializeByClassName` switch now contains a case per referenced module
  class — dispatching through the bare imported symbol — so the wire form
  `auth.AuthSuccess` round-trips into a real typed value rather than `unknown`.
- New CLI flag `--no-gen-modules` skips the recursive module generation
  (default: enabled). Useful when module clients are managed separately.
- New optional `typescript_client_modules:` block in `config/generator.yaml`
  overrides the per-module output directory or npm package name:
  ```yaml
  typescript_client_modules:
    serverpod_auth_idp_server:
      output: ../my_custom_path
      npm_name: '@my-org/auth-idp-ts'
  ```
- Internal: extracted `lib/src/analyzer/ir_walker.dart` (shared IR walks),
  `lib/src/emit/module_import_lines.dart` (cross-package import grouping),
  and `lib/src/cli/generation_pipeline.dart` (single per-project flow used
  by both the app and every module dep).

## 0.1.4

- Bugfix: type mapper now handles `void`, `dynamic`, and `Object`
  explicitly. Previously these fell through to the project-model branch
  and emitted invalid `p.void.fromJson(...)` / `p.dynamic` etc.,
  breaking `tsc --noEmit` on any endpoint with a `Future<void>` return.
- Bugfix: types defined in Serverpod modules the project depends on
  (e.g. `AuthSuccess` from `serverpod_auth_idp`) are no longer
  emitted as `p.AuthSuccess`. Until module-aware imports land in v0.2,
  they fall back to `unknown /* TODO(v0.2): module type AuthSuccess */`
  so the package compiles and the gap is surfaced via the IDE hover.
  Endpoint-side callers can cast at the call site.
- The mapper now takes a `projectClassNames` set so it can distinguish
  "in our protocol/ barrel" from "defined in a module dependency". The
  generate command computes this from the IR's models list and passes
  it through to both model and endpoint emitters.

## 0.1.3

- Bugfix: model emitter now emits cross-file imports for fields whose
  type references other project models. Previously a `field: SomeOther`
  would compile only if every file happened to be in the same scope —
  for any non-trivial Serverpod project the generated `tsc --noEmit`
  reported `TS2304: Cannot find name 'SomeOther'`. Each model file now
  walks its field types (descending into generics like `List<T>` /
  `Map<K, V>`) and emits one `import { Name<, NameBase>?<, NameCodec>? }
  from './<snake>.js';` per referenced project type. Self-references
  are skipped.
- Fixture's `UserProfile` extended with cross-references to `Priority`
  (enum), `Colour` (enum, byName), `Animal` (sealed), and
  `List<Priority>` (collection-wrapped enum) so the e2e regression-tests
  this path going forward.

## 0.1.2

- `generate` now runs `npm install` + `npm run build` in the output
  directory by default, so the generated package is import-ready as
  soon as the command exits — no manual build step before
  `npm install ../<your_project>_typescript_client` from a consumer.
- New `--no-build` flag opts out of the install + build (e.g. for
  pnpm/yarn/bun toolchains, or CI pipelines that build separately).
- If `npm` isn't on PATH, `generate` still emits source cleanly
  and prints a hint with the manual recovery commands; non-fatal.

## 0.1.1

- Bidirectional streaming endpoints (input `Stream<T>` parameters
  paired with an output `Stream<T>` return) now generate real call
  bodies. The runtime spawns a per-input-stream feeder that
  forwards each value as a `MethodStreamMessage` and sends a
  parameter-scoped `CloseMethodStreamCommand` when the user's
  AsyncIterable completes. Closes #25.
- `ClientMethodStreamManager.openOutputStream` is now an alias for
  `openMethodStream` (kept for source compatibility — pre-#25
  generated clients keep working).

## 0.1.0

First usable release. Generates a `tsc --noEmit` clean TypeScript client
for a Serverpod project, matching the Dart client's wire format
byte-for-byte.

### Generator
- `dart run serverpod_typescript_bridge generate` produces
  `<server>/../<name>_typescript_client/` (overridable via `--output`
  or `typescript_client_package_path:` in `config/generator.yaml`).
- `dart run serverpod_typescript_bridge inspect` dumps the parsed
  IR as JSON for debugging.
- Project discovery walks up from cwd; honours `--directory`.
- Reuses `serverpod_cli`'s public analyzer so every feature Serverpod
  understands flows through automatically.

### Generated TS client
- One TS class per Serverpod model (`fromJson` / `toJson` / `copyWith`).
- Sealed hierarchies emit a discriminated-union type alias plus an
  abstract `<Name>Base.fromJson` dispatcher; multi-level sealed
  hierarchies dispatch correctly through every ancestor.
- Enums emit a TS `enum` plus a sibling `<Name>Codec` for both
  `byIndex` and `byName` serialisation.
- Exceptions extend `Error` and round-trip via `Protocol`.
- One TS class per endpoint with one async method per server method.
  Required/optional positional/named parameters all supported;
  optional params are spread-guarded so omitted args become omitted
  keys (not explicit `null`s). `@unauthenticatedClientCall` and
  `@Deprecated` propagate.
- Top-level `Client extends ServerpodClientShared` with one field
  per top-level endpoint; project `Protocol extends
  SerializationManager` with the per-class deserialise switch.
- Module-type projects emit a `<Nickname>Caller extends
  ModuleEndpointCaller` plus a `modulePrefix` const; the Protocol
  switch normalises module-prefixed `__className__` values.

### Runtime (vendored under `src/runtime/`)
- HTTP unary calls via `fetch`. Status mapping (400/401/403/404/500),
  one-shot 401 refresh for `RefreshableClientAuthKeyProvider`, typed
  exception decoding via `Protocol.deserializeByClassName`.
- WebSocket transport (`<host>/v1/websocket`) for output streams.
  Generated streaming methods return `AsyncIterable<T>`.
- All wire-format converters match `serverpod_serialization`
  byte-for-byte: ISO-8601 UTC for DateTime, integer ms for Duration,
  string for BigInt, base64 for ByteData, list for Set, list of
  `{k,v}` for non-string-keyed Maps.

### Tests
- 77+ Dart cases (analyzer integration, emitters, e2e via spawned
  CLI + `tsc --noEmit`).
- 60+ vitest cases for the runtime (every primitive converter, every
  HTTP status mapping, auth-refresh single-retry, WS envelope
  round-trip).

### Known limitations (deferred)
- Bidirectional streaming (input `Stream<T>` parameters) — generated
  body throws; tracked at #25.
- Records (Dart 3) — not supported.
- Watch mode (`-w`) — not supported.
- npm-published runtime — vendored for now; v0.2 will publish.
