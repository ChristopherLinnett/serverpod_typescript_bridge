# `@serverpod-typescript-bridge/runtime`

The TypeScript runtime that every generated Serverpod client depends on.

## Status

**Vendored, internal.** Not published to npm. The Dart-side generator copies these source files verbatim into each generated client at generate time (`src/runtime/`); each generated package is therefore self-contained and brings its own pinned-by-source runtime.

A migration to a published npm package was originally pencilled in for v0.2 but didn't ship — v0.2 went to module-aware generation instead, and the vendored approach turned out to compose cleanly with the new `file:..` module-deps wiring (no version skew across module clients in a graph). Migration to a published runtime stays an option but isn't on a date.

## What's here

| Module             | Public surface |
|--------------------|---|
| `client.ts`        | `ServerpodClientShared` — base for the generated `Client` |
| `endpoint.ts`      | `EndpointRef`, `EndpointCaller`, `ModuleEndpointCaller`, `HttpEndpointCaller` |
| `http_transport.ts`| `HttpTransport`, `UnaryCallOptions` — fetch-based unary call dispatcher; auth header + 401-refresh |
| `ws_transport.ts`  | `ClientMethodStreamManager`, `InputStreamSpec` — multiplexed WebSocket streaming dispatcher (output, output-only, and bidi) with status-mapped open errors, server `ping`/`pong`, `bad_request` propagation, and per-handler iterator semantics |
| `ws_messages.ts`   | Sealed message types matching `websocket_messages.dart`; `parseEnvelope`, `buildEnvelope` |
| `serialization.ts` | `SerializationManager` (abstract; project `Protocol` extends it) + per-primitive `encode*` / `decode*` helpers, `decodeMap`, `decodeRecord` |
| `exceptions.ts`    | `ServerpodClientException` and the 5 status-mapped subclasses (400/401/403/404/500), plus `exceptionFromStatus` |
| `types.ts`         | `SerializableModel`, `SerializableException`, `ClientOptions`, `MethodCallContext`, `ClientAuthKeyProvider`, `RefreshableClientAuthKeyProvider` |
| `index.ts`         | Barrel re-export |

## Wire-format contract

The runtime mirrors `serverpod_serialization` byte-for-byte. Highlights:

- **HTTP unary call:** `POST <host>/<endpointName>` with body `JSON.stringify({ method: '<methodName>', ...encodedArgs })`.
- **HTTP error mapping:** `400 → BadRequest`, `401 → Unauthorized`, `403 → Forbidden`, `404 → NotFound`, `500 → InternalServerError`. Typed `{className, data}` envelopes decode through `Protocol.deserializeByClassName(...)` and throw the resulting `Error` subclass.
- **Auth header:** `Authorization: <wrappedAuthValue>`. Suppressed when the call site sets `{ authenticated: false }`.
- **Auth refresh:** if the provider implements `RefreshableClientAuthKeyProvider` and the server returns 401, the runtime calls `refresh()` once and retries.
- **WebSocket streaming:** `ws://<host>/v1/websocket?auth=<rawKey>` (the runtime strips a `Bearer ` / `Basic ` prefix from the auth header value before putting it in the query). Messages use a `{type, data}` envelope; `OpenMethodStreamCommand` carries `args` as a *double-encoded JSON string* matching the Dart contract. Server-initiated `ping` is replied to with `pong`; `bad_request` fails every active handler with a 400-status exception.
- **Primitive encodings:** ISO-8601 UTC for `Date`, integer ms for `Duration`, base64 for `Uint8Array`, string for `BigInt`, list of `{k,v}` for non-string-keyed `Map`s; `Map<String,V>` decodes to a real `Record<string,V>` via `decodeRecord`.

See [`docs/architecture.md`](../../../docs/architecture.md) in the parent Dart package for the canonical Dart→TS mapping table.

## Running the tests

```bash
cd lib/runtime/typescript
npm ci          # or `npm install` for first-run if no lockfile in cache
npm run typecheck
npm test
```

`vitest` covers every primitive converter (round-trip both directions), every HTTP status mapping, the auth-refresh single-retry behaviour, and the WS envelope parser. Current count: 62 cases.

## Streaming

Streaming is supported. `Stream<T>` returns from Dart endpoints emit a TS method that returns `AsyncIterable<T>`; `Stream<T>` parameters become a separate `streams: { name: AsyncIterable<T> }` argument on the generated method, with values forwarded to the server as `MethodStreamMessage` frames. See `ws_transport.ts` for the lifecycle (open handshake, multiplexed handlers, error propagation, close cleanup).
