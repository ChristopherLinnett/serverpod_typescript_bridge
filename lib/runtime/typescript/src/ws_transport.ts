import { ServerpodClientException } from './exceptions.js';
import type { SerializationManager } from './serialization.js';
import type { ClientAuthKeyProvider } from './types.js';
import {
  buildEnvelope,
  parseEnvelope,
  type CloseMethodStreamCommandData,
  type MethodStreamMessageData,
  type MethodStreamSerializableExceptionData,
  type OpenMethodStreamCommandData,
  type OpenMethodStreamResponseData,
} from './ws_messages.js';

/**
 * Spec for a single input stream the client is sending into a
 * server-side method. The encoder turns each value into the
 * `{ className, data }` envelope the server expects on
 * `MethodStreamMessage.object`.
 *
 * `data` is intentionally `unknown`: stream values can serialize to a
 * primitive, an array, or a record (see `r.encodeList`/etc.), so the
 * generated encoder isn't always producing a JSON object. The wire
 * payload preserves whatever shape the type mapper emits.
 */
export interface InputStreamSpec<T = unknown> {
  iterable: AsyncIterable<T>;
  encode: (value: T) => { className: string; data: unknown };
}

/**
 * Manages a single multiplexed WebSocket connection to
 * `<host>/v1/websocket`. Generated client code calls
 * `openMethodStream(...)` for both output-only and bidirectional
 * streaming methods.
 */
export class ClientMethodStreamManager {
  constructor(
    private readonly host: string,
    private readonly serializer: SerializationManager,
    private readonly authProvider?: ClientAuthKeyProvider,
  ) {}

  private socket: WebSocket | undefined;
  private socketReady: Promise<void> | undefined;
  private nextConnectionId = 0;
  private readonly handlers = new Map<string, _StreamHandler>();

  async open(): Promise<void> {
    if (this.socket && this.socket.readyState === WebSocket.OPEN) return;
    if (this.socketReady) return this.socketReady;
    // Cache the connect promise so concurrent open() calls share it.
    // Crucially, clear the cache on rejection so callers can retry —
    // otherwise a single transient failure would poison every future
    // call by always returning the same rejected promise.
    this.socketReady = this._connect().catch((e) => {
      this.socketReady = undefined;
      this.socket = undefined;
      throw e;
    });
    return this.socketReady;
  }

  private async _connect(): Promise<void> {
    const url = await this._buildUrl();
    const ws = new WebSocket(url);
    this.socket = ws;
    await new Promise<void>((resolve, reject) => {
      ws.addEventListener('open', () => resolve(), { once: true });
      ws.addEventListener(
        'error',
        () => reject(new ServerpodClientException('WebSocket error', 0)),
        { once: true },
      );
      // A 'close' arriving before 'open' (auth failure, immediate
      // server reject) would otherwise leave this await hanging
      // forever. Treat it as a failed handshake.
      ws.addEventListener(
        'close',
        () =>
          reject(
            new ServerpodClientException(
              'WebSocket closed before open',
              0,
            ),
          ),
        { once: true },
      );
    });
    ws.addEventListener('message', (e) => this._onMessage(String(e.data)));
    ws.addEventListener('close', () => this._onClose());
  }

  private async _buildUrl(): Promise<string> {
    const base = this.host.endsWith('/')
      ? this.host.slice(0, -1)
      : this.host;
    let url = base.replace(/^http/, 'ws') + '/v1/websocket';
    // The auth provider returns a wrapped header value (e.g.
    // `Bearer <key>`). Serverpod's WS contract expects the raw key in
    // the `?auth=` query param, so strip the scheme prefix if present.
    const headerValue = await this.authProvider?.getAuthHeaderValue();
    const rawKey = _extractRawAuthKey(headerValue);
    if (rawKey) url += `?auth=${encodeURIComponent(rawKey)}`;
    return url;
  }

  private _onMessage(raw: string): void {
    const env = parseEnvelope(raw);
    if (!env) return;
    switch (env.type) {
      case 'open_method_stream_response': {
        const data = env.data as OpenMethodStreamResponseData;
        this.handlers.get(data.connectionId)?.onOpenResponse(data);
        return;
      }
      case 'method_stream_message': {
        const data = env.data as MethodStreamMessageData;
        // Only output-stream values land here; the parameter field is
        // omitted for server→client messages.
        if (data.parameter !== undefined) return;
        this.handlers.get(data.connectionId)?.onValue(data);
        return;
      }
      case 'method_stream_serializable_exception': {
        const data = env.data as MethodStreamSerializableExceptionData;
        this.handlers.get(data.connectionId)?.onException(data);
        return;
      }
      case 'close_method_stream_command': {
        const data = env.data as CloseMethodStreamCommandData;
        this.handlers.get(data.connectionId)?.onClose();
        return;
      }
      case 'ping':
        // Serverpod uses app-level ping/pong (browsers can't reply to
        // WS control frames). Echo back so the server doesn't drop us.
        this.socket?.send(buildEnvelope('pong', {}));
        return;
      case 'pong':
        // No keepalive timer yet; just consume.
        return;
      case 'bad_request': {
        // The server can't parse what we sent. Tear every active
        // handler down with a connection-level error rather than
        // silently leaking pending iterators.
        const err = new ServerpodClientException(
          'Server reported bad_request on the WebSocket; closing',
          400,
        );
        this._failAllHandlers(err);
        this.socket?.close();
        return;
      }
      default:
        return;
    }
  }

  private _onClose(): void {
    // Reject any pending open handshakes so callers awaiting
    // `openResponse` don't hang forever after a mid-handshake drop.
    const err = new ServerpodClientException(
      'WebSocket closed before stream completed',
      0,
    );
    for (const h of this.handlers.values()) {
      h.failOpenIfPending(err);
      h.onClose();
    }
    this.handlers.clear();
    this.socket = undefined;
    this.socketReady = undefined;
  }

  private _failAllHandlers(err: unknown): void {
    for (const h of this.handlers.values()) {
      h.failOpenIfPending(err);
      h.onError(err);
    }
    this.handlers.clear();
  }

  /**
   * Open a streaming method call. Output values arrive on the returned
   * AsyncIterable. If [inputStreams] is supplied, the runtime spawns
   * one feeder task per input stream and forwards values to the server
   * as `MethodStreamMessage` frames; on each feeder's completion it
   * sends a `CloseMethodStreamCommand` for that parameter.
   *
   * Throws on auth/endpoint open errors.
   */
  async openMethodStream<T>(opts: {
    endpoint: string;
    method: string;
    args: Record<string, unknown>;
    decode: (raw: unknown) => T;
    inputStreams?: Record<string, InputStreamSpec>;
  }): Promise<AsyncIterable<T>> {
    await this.open();
    const connectionId = `c${this.nextConnectionId++}`;
    const auth = await this.authProvider?.getAuthHeaderValue();
    const inputStreamNames = Object.keys(opts.inputStreams ?? {});
    const command: OpenMethodStreamCommandData = {
      endpoint: opts.endpoint,
      method: opts.method,
      connectionId,
      // Double-encoded JSON string per Dart contract.
      args: JSON.stringify(this._encodeArgs(opts.args)),
      inputStreams: inputStreamNames,
      ...(auth ? { authentication: auth } : {}),
    };

    const handler = new _StreamHandler(opts.decode, this.serializer);
    this.handlers.set(connectionId, handler);
    try {
      this.socket!.send(buildEnvelope('open_method_stream_command', command));
      await handler.openResponse;
    } catch (e) {
      // Failed open → eject the handler so it doesn't keep routing
      // messages to a stream the caller never receives.
      this.handlers.delete(connectionId);
      throw e;
    }

    // Spawn a feeder per input stream. Each runs in the background
    // for the lifetime of the call.
    if (opts.inputStreams) {
      for (const [name, spec] of Object.entries(opts.inputStreams)) {
        // Fire-and-forget — the iterable's lifetime drives the feeder.
        // Errors during a feeder are reported by closing that input
        // parameter early; the server's behaviour on early close is
        // its own concern.
        void this._feedInputStream(
          opts.endpoint,
          opts.method,
          connectionId,
          name,
          spec,
        );
      }
    }

    return handler.iterable<T>(() => {
      const close: CloseMethodStreamCommandData = {
        endpoint: opts.endpoint,
        method: opts.method,
        connectionId,
      };
      this.socket?.send(
        buildEnvelope('close_method_stream_command', close),
      );
      this.handlers.delete(connectionId);
    });
  }

  /** Backwards-compatible alias for output-only streams. */
  openOutputStream<T>(opts: {
    endpoint: string;
    method: string;
    args: Record<string, unknown>;
    decode: (raw: unknown) => T;
  }): Promise<AsyncIterable<T>> {
    return this.openMethodStream(opts);
  }

  private async _feedInputStream(
    endpoint: string,
    method: string,
    connectionId: string,
    parameter: string,
    spec: InputStreamSpec,
  ): Promise<void> {
    try {
      for await (const value of spec.iterable) {
        if (!this.handlers.has(connectionId)) return;
        const message: MethodStreamMessageData = {
          endpoint,
          method,
          connectionId,
          parameter,
          object: spec.encode(value),
        };
        this.socket?.send(
          buildEnvelope('method_stream_message', message),
        );
      }
    } catch (_) {
      // If the user's iterable throws, close the stream cleanly so
      // the server doesn't wait forever for the next value.
    } finally {
      // Tell the server "no more values for this parameter".
      const close: CloseMethodStreamCommandData = {
        endpoint,
        method,
        connectionId,
        parameter,
      };
      this.socket?.send(
        buildEnvelope('close_method_stream_command', close),
      );
    }
  }

  private _encodeArgs(
    args: Record<string, unknown>,
  ): Record<string, unknown> {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(args)) {
      out[k] = this.serializer.encode(v);
    }
    return out;
  }

  /** Test/dispose hook. Closes the underlying WebSocket. */
  close(): void {
    this.socket?.close();
    this.socket = undefined;
    this.socketReady = undefined;
    this.handlers.clear();
  }
}

type _Waiter = {
  resolve: (v: IteratorResult<unknown>) => void;
  reject: (e: unknown) => void;
};

class _StreamHandler {
  constructor(
    private readonly decode: (raw: unknown) => unknown,
    private readonly serializer: SerializationManager,
  ) {}

  private readonly _values: unknown[] = [];
  private readonly _waiters: _Waiter[] = [];
  private _error: unknown | undefined;
  private _closed = false;
  private _openSettled = false;
  private _openResolve: (() => void) | undefined;
  private _openReject: ((e: unknown) => void) | undefined;

  readonly openResponse: Promise<void> = new Promise((resolve, reject) => {
    this._openResolve = resolve;
    this._openReject = reject;
  });

  onOpenResponse(data: OpenMethodStreamResponseData): void {
    this._openSettled = true;
    if (data.responseType === 'success') {
      this._openResolve?.();
      return;
    }
    this._openReject?.(_openErrorFor(data.responseType));
  }

  /// Called by the manager when the connection drops before the
  /// open-response arrives. Without this, callers can hang forever
  /// awaiting `openResponse`.
  failOpenIfPending(err: unknown): void {
    if (this._openSettled) return;
    this._openSettled = true;
    this._openReject?.(err);
  }

  onValue(data: MethodStreamMessageData): void {
    if (this._closed) return;
    // Pass the full envelope so the decoder sees both `className` and
    // `data` — the generated `Protocol.deserializeByClassName` walks
    // the envelope; passing only `data` discards polymorphic dispatch.
    const value = this.decode(data.object);
    this._dispatch(value);
  }

  onException(data: MethodStreamSerializableExceptionData): void {
    const err = this.serializer.deserializeByClassName(data.object);
    this.onError(
      err instanceof Error
        ? err
        : new ServerpodClientException(
            `Stream exception: ${data.object.className}`,
            0,
          ),
    );
  }

  /// Terminates the stream with an error. Any already-awaiting
  /// consumers receive the error through their `next()` rejection;
  /// later consumers re-throw the cached `_error` synchronously.
  onError(err: unknown): void {
    if (this._closed) return;
    this._error = err;
    this._closed = true;
    this._dispatchError(err);
  }

  onClose(): void {
    if (this._closed) return;
    this._closed = true;
    this._dispatchEnd();
  }

  private _dispatch(value: unknown): void {
    const waiter = this._waiters.shift();
    if (waiter) {
      waiter.resolve({ value, done: false });
    } else {
      this._values.push(value);
    }
  }

  private _dispatchEnd(): void {
    while (this._waiters.length > 0) {
      this._waiters.shift()!.resolve({ value: undefined, done: true });
    }
  }

  private _dispatchError(err: unknown): void {
    while (this._waiters.length > 0) {
      this._waiters.shift()!.reject(err);
    }
  }

  iterable<T>(onUserClose: () => void): AsyncIterable<T> {
    const self = this;
    return {
      [Symbol.asyncIterator](): AsyncIterator<T> {
        return {
          next(): Promise<IteratorResult<T>> {
            return new Promise<IteratorResult<unknown>>((resolve, reject) => {
              if (self._error) {
                reject(self._error);
                return;
              }
              if (self._values.length > 0) {
                resolve({ value: self._values.shift(), done: false });
                return;
              }
              if (self._closed) {
                resolve({ value: undefined, done: true });
                return;
              }
              self._waiters.push({ resolve, reject });
            }) as Promise<IteratorResult<T>>;
          },
          async return(value): Promise<IteratorResult<T>> {
            self._closed = true;
            onUserClose();
            return { value: value as T, done: true };
          },
        };
      },
    };
  }
}

/// Maps a non-success `responseType` from the server's open-stream
/// response onto the closest HTTP-style status so callers can
/// `instanceof`-check against the existing exception hierarchy.
function _openErrorFor(responseType: string): ServerpodClientException {
  switch (responseType) {
    case 'endpointNotFound':
      return new ServerpodClientException(
        'Endpoint not found',
        404,
      );
    case 'authenticationFailed':
      return new ServerpodClientException(
        'Authentication failed',
        401,
      );
    case 'authorizationDeclined':
      return new ServerpodClientException(
        'Authorization declined',
        403,
      );
    case 'invalidArguments':
      return new ServerpodClientException(
        'Invalid arguments',
        400,
      );
    default:
      return new ServerpodClientException(
        `Failed to open stream: ${responseType}`,
        0,
      );
  }
}

/// Strips a header-style prefix (`Bearer foo`, `Basic abc=`) from
/// [headerValue] and returns just the raw key the WS query expects.
function _extractRawAuthKey(
  headerValue: string | null | undefined,
): string | undefined {
  if (!headerValue) return undefined;
  const trimmed = headerValue.trim();
  if (!trimmed) return undefined;
  const sep = trimmed.indexOf(' ');
  if (sep === -1) return trimmed;
  const rest = trimmed.slice(sep + 1).trim();
  return rest || undefined;
}
