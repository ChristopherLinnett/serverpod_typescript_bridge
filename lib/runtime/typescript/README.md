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
| `ws_messages.ts`   | Serverpod 4's method-stream frames: key tables matching `websocket_message_keys.dart`, one builder per frame, `parseEnvelope`, `classNamed` |
| `serialization.ts` | `SerializationManager` (abstract; project `Protocol` extends it), `ModelRegistry`, per-primitive `encode*` / `decode*` helpers, `decodeMap`, `decodeRecord`, UUID generators |
| `exceptions.ts`    | `ServerpodClientException` and the 5 status-mapped subclasses (400/401/403/404/500), plus `exceptionFromStatus` |
| `types.ts`         | `SerializableModel`, `SerializableException`, `ClientOptions`, `MethodCallContext`, `ClientAuthKeyProvider`, `RefreshableClientAuthKeyProvider` |
| `index.ts`         | Barrel re-export |

## Wire-format contract

The runtime mirrors `serverpod_serialization` byte-for-byte. Highlights:

- **HTTP unary call:** `POST <host>/<endpointName>` with body `JSON.stringify({ method: '<methodName>', ...encodedArgs })`.
- **HTTP error mapping:** `400 → BadRequest`, `401 → Unauthorized`, `403 → Forbidden`, `404 → NotFound`, `500 → InternalServerError`. Typed `{className, data}` envelopes decode through `Protocol.deserializeByClassName(...)` and throw the resulting `Error` subclass.
- **Auth header:** `Authorization: <wrappedAuthValue>`. Suppressed when the call site sets `{ authenticated: false }`.
- **Auth refresh:** if the provider implements `RefreshableClientAuthKeyProvider` and the server returns 401, the runtime calls `refresh()` once and retries.
- **WebSocket streaming:** `ws(s)://<host>/v1/websocket`, one connection per client, opened by the first streaming call and closed when the last stream ends. Frames follow Serverpod 4's method-stream protocol: `{type, data}` with abbreviated keys, a UUID connection id, a `done`/`error` reason on every close, and credentials in the open command (not the URL). Pings on connect and every 20 s; a connection silent for 40 s is dropped. Each stream value is a `{className, data}` pair.
- **Primitive encodings:** ISO-8601 UTC for `Date`, integer ms for `Duration`, `decode('<base64>', 'base64')` for `Uint8Array`, string for `BigInt`, list of `{k,v}` for non-string-keyed `Map`s, pgvector text (`[1.0,2.5]`) for vectors; `Map<String,V>` decodes to a real `Record<string,V>` via `decodeRecord`.
- **Models:** `ModelRegistry` holds a package's decoders by class name; generated model files register themselves and decode each other through it, following the `__className__` on the wire.

The runtime needs the global `fetch`, `WebSocket` and `crypto`: any current browser, or Node 22+.

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
