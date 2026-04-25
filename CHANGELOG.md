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
