# `@serverpod-typescript-bridge/runtime`

The TypeScript runtime that every generated Serverpod client depends on.

## Status

**Internal / pre-alpha.** Not yet published to npm. For v0.1, the generator copies these files verbatim into each generated client at generate time (vendored deployment). v0.2 will publish this as a regular npm package and the generator will switch to declaring it as a `dependencies` entry.

## What's here

| Module | Public surface |
|---|---|
| `client.ts` | `ServerpodClientShared` — base for the generated `Client` |
| `endpoint.ts` | `EndpointRef`, `EndpointCaller`, `ModuleEndpointCaller`, `HttpEndpointCaller` |
| `http_transport.ts` | `HttpTransport`, `UnaryCallOptions` — the unary call dispatcher |
| `serialization.ts` | `SerializationManager` (abstract; project `Protocol` extends it) + per-primitive `encode*` / `decode*` helpers |
| `exceptions.ts` | `ServerpodClientException` and the 5 status-mapped subclasses, plus `exceptionFromStatus` |
| `types.ts` | `SerializableModel`, `SerializableException`, `ClientOptions`, `MethodCallContext`, `ClientAuthKeyProvider`, `RefreshableClientAuthKeyProvider` |
| `index.ts` | Barrel re-export |

## Wire-format contract

The runtime mirrors `serverpod_serialization` byte-for-byte. Highlights:

- **Unary call:** `POST <host>/<endpointName>` with body `JSON.stringify({ method: '<methodName>', ...encodedArgs })`.
- **Auth:** `Authorization: <wrappedAuthValue>` header; suppressed when the call site sets `{ authenticated: false }`.
- **Auth refresh:** if the provider implements `RefreshableClientAuthKeyProvider` and the server returns 401, the runtime calls `refresh()` once and retries.
- **Typed exceptions:** the server may return a `{ className, data }` JSON envelope; the runtime decodes it via `Protocol.deserializeByClassName(...)` and throws the resulting `Error` subclass.
- **Primitive encodings:** ISO-8601 UTC for `Date`, integer ms for durations, base64 for `Uint8Array`, string for `BigInt`, list of `{k,v}` for non-string-keyed maps.

See [`docs/architecture.md`](../../../docs/architecture.md) in the parent Dart package for the canonical mapping table.

## Running the tests

```bash
cd lib/runtime/typescript
npm install
npm test
```

Vitest covers every primitive converter (round-trip in both directions), every HTTP status mapping, and the auth-refresh single-retry behaviour.

## Streaming

Streaming endpoints (WebSocket transport) are deliberately out of scope for this issue. They land in [issue #10](https://github.com/ChristopherLinnett/serverpod_typescript_bridge/issues/10).
