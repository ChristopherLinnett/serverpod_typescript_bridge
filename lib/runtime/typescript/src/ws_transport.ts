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
 */
export interface InputStreamSpec<T = unknown> {
  iterable: AsyncIterable<T>;
  encode: (value: T) => { className: string; data: Record<string, unknown> };
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
    this.socketReady = this._connect();
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
    });
    ws.addEventListener('message', (e) => this._onMessage(String(e.data)));
    ws.addEventListener('close', () => this._onClose());
  }

  private async _buildUrl(): Promise<string> {
    const base = this.host.endsWith('/')
      ? this.host.slice(0, -1)
      : this.host;
    let url = base.replace(/^http/, 'ws') + '/v1/websocket';
    const auth = await this.authProvider?.getAuthHeaderValue();
    if (auth) url += `?auth=${encodeURIComponent(auth)}`;
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
      // ping/pong handled at the WebSocket layer; bad_request surfaces
      // via the connection-level error path.
      default:
        return;
    }
  }

  private _onClose(): void {
    for (const h of this.handlers.values()) h.onClose();
    this.handlers.clear();
    this.socket = undefined;
    this.socketReady = undefined;
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
    this.socket!.send(buildEnvelope('open_method_stream_command', command));
    await handler.openResponse;

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

class _StreamHandler {
  constructor(
    private readonly decode: (raw: unknown) => unknown,
    private readonly serializer: SerializationManager,
  ) {}

  private readonly _values: unknown[] = [];
  private readonly _waiters: Array<(v: IteratorResult<unknown>) => void> = [];
  private _error: unknown | undefined;
  private _closed = false;
  private _openResolve: (() => void) | undefined;
  private _openReject: ((e: unknown) => void) | undefined;

  readonly openResponse: Promise<void> = new Promise((resolve, reject) => {
    this._openResolve = resolve;
    this._openReject = reject;
  });

  onOpenResponse(data: OpenMethodStreamResponseData): void {
    if (data.responseType === 'success') {
      this._openResolve?.();
    } else {
      this._openReject?.(
        new ServerpodClientException(
          `Failed to open stream: ${data.responseType}`,
          0,
        ),
      );
    }
  }

  onValue(data: MethodStreamMessageData): void {
    if (this._closed) return;
    const value = this.decode(data.object.data);
    this._dispatch(value);
  }

  onException(data: MethodStreamSerializableExceptionData): void {
    const err = this.serializer.deserializeByClassName(data.object);
    this._error = err instanceof Error
      ? err
      : new ServerpodClientException(
          `Stream exception: ${data.object.className}`,
          0,
        );
    this._dispatchEnd();
  }

  onClose(): void {
    if (this._closed) return;
    this._closed = true;
    this._dispatchEnd();
  }

  private _dispatch(value: unknown): void {
    const waiter = this._waiters.shift();
    if (waiter) {
      waiter({ value, done: false });
    } else {
      this._values.push(value);
    }
  }

  private _dispatchEnd(): void {
    while (this._waiters.length > 0) {
      this._waiters.shift()!({ value: undefined, done: true });
    }
  }

  iterable<T>(onUserClose: () => void): AsyncIterable<T> {
    const self = this;
    return {
      [Symbol.asyncIterator](): AsyncIterator<T> {
        return {
          next(): Promise<IteratorResult<T>> {
            return new Promise<IteratorResult<unknown>>((resolve) => {
              if (self._error) {
                throw self._error;
              }
              if (self._values.length > 0) {
                resolve({ value: self._values.shift(), done: false });
                return;
              }
              if (self._closed) {
                resolve({ value: undefined, done: true });
                return;
              }
              self._waiters.push(resolve);
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
