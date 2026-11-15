import { ServerpodClientException } from './exceptions.js';
import { randomUuidV4, type SerializationManager } from './serialization.js';
import type {
  ClientAuthKeyProvider,
  RefreshableClientAuthKeyProvider,
} from './types.js';
import {
  buildBadRequest,
  buildCloseMethodStream,
  buildMethodStreamException,
  buildMethodStreamMessage,
  buildOpenMethodStream,
  buildPing,
  buildPong,
  parseEnvelope,
  WsKey,
  WsType,
  type ClassNamedValue,
  type CloseReason,
  type OpenMethodStreamResponseType,
  type StreamAddress,
} from './ws_messages.js';

/**
 * One input stream of a streaming call: the values to send, and how to
 * turn each into the `{ className, data }` pair the server decodes it by.
 */
export interface InputStreamSpec<T = unknown> {
  iterable: AsyncIterable<T>;
  encode: (value: T) => ClassNamedValue;
}

export interface MethodStreamCall<T> {
  endpoint: string;
  method: string;
  /** Already-encoded call arguments. */
  args: Record<string, unknown>;
  /** Decodes the `data` of each value the server sends. */
  decode: (raw: unknown) => T;
  inputStreams?: Record<string, InputStreamSpec>;
}

/** Timings of the connection. Serverpod's own client uses the defaults. */
export interface MethodStreamTimings {
  /** How long to wait for the socket to open and answer the first ping. */
  connectionTimeout?: number;
  /** How often to ping an open connection. */
  pingInterval?: number;
  /** How long the server may stay silent before the connection is dropped. */
  idleTimeout?: number;
}

const DEFAULT_CONNECTION_TIMEOUT_MS = 20_000;
const DEFAULT_PING_INTERVAL_MS = 20_000;
const DEFAULT_IDLE_TIMEOUT_MS = 40_000;

/**
 * Runs every streaming call of a client over one WebSocket to
 * `<host>/v1/websocket`, opened on the first call and closed when the
 * last stream ends. A port of `ClientMethodStreamManager` in
 * `serverpod_client`.
 */
export class ClientMethodStreamManager {
  constructor(
    private readonly host: string,
    private readonly serializer: SerializationManager,
    private readonly authProvider?: ClientAuthKeyProvider,
    private readonly timings: MethodStreamTimings = {},
  ) {}

  private socket: WebSocket | undefined;
  private connecting: Promise<WebSocket> | undefined;
  private pingTimer: ReturnType<typeof setInterval> | undefined;
  private idleTimer: ReturnType<typeof setTimeout> | undefined;
  private readonly streams = new Map<string, _MethodStream>();

  /**
   * Opens a streaming call and resolves once the server has accepted it.
   * Values arrive on the returned iterable; breaking out of it tells the
   * server to stop.
   *
   * An `authenticationFailed` answer is retried once when the auth
   * provider can refresh its key — an expired access token is the usual
   * cause.
   */
  async openMethodStream<T>(call: MethodStreamCall<T>): Promise<AsyncIterable<T>> {
    try {
      return await this._open(call);
    } catch (e) {
      const provider = this.authProvider;
      if (
        e instanceof ServerpodClientException &&
        e.statusCode === 401 &&
        _isRefreshable(provider)
      ) {
        await provider.refresh();
        return this._open(call);
      }
      throw e;
    }
  }

  private async _open<T>(call: MethodStreamCall<T>): Promise<AsyncIterable<T>> {
    const socket = await this._connect();
    const to: StreamAddress = {
      endpoint: call.endpoint,
      method: call.method,
      connectionId: randomUuidV4(),
    };
    const inputs = call.inputStreams ?? {};
    const stream = new _MethodStream(to, call.decode as (raw: unknown) => unknown);
    this.streams.set(to.connectionId, stream);

    let response: OpenMethodStreamResponseType;
    try {
      const authentication = await this.authProvider?.getAuthHeaderValue();
      socket.send(
        buildOpenMethodStream(to, {
          args: call.args,
          inputStreams: Object.keys(inputs),
          authentication: authentication ?? null,
        }),
      );
      response = await stream.opened;
    } catch (e) {
      this._forget(stream);
      throw e;
    }
    if (response !== 'success') {
      this._forget(stream);
      throw _openError(response);
    }

    for (const [parameter, spec] of Object.entries(inputs)) {
      void this._feed(stream, parameter, spec);
    }

    return stream.iterable<T>(() => {
      this._send(buildCloseMethodStream(to, 'done'));
      this._forget(stream);
    });
  }

  /** Forwards one input stream, then tells the server it has ended. */
  private async _feed(
    stream: _MethodStream,
    parameter: string,
    spec: InputStreamSpec,
  ): Promise<void> {
    const iterator = spec.iterable[Symbol.asyncIterator]();
    stream.inputs.set(parameter, iterator);
    let reason: CloseReason = 'done';
    try {
      for (;;) {
        const next = await iterator.next();
        if (next.done || !stream.inputs.has(parameter)) break;
        this._send(
          buildMethodStreamMessage(stream.to, parameter, spec.encode(next.value)),
        );
      }
    } catch (e) {
      reason = 'error';
      const typed = this._classNamedException(e);
      if (typed) {
        this._send(buildMethodStreamException(stream.to, parameter, typed));
      }
    }
    // Absent means the server (or the end of the call) closed this input
    // first; there is nobody left to tell.
    if (!stream.inputs.delete(parameter)) return;
    this._send(buildCloseMethodStream(stream.to, reason, parameter));
    this._closeSocketIfUnused();
  }

  private _classNamedException(error: unknown): ClassNamedValue | undefined {
    if (error === null || typeof error !== 'object') return undefined;
    const toJson = (error as { toJson?: unknown }).toJson;
    if (typeof toJson !== 'function') return undefined;
    const data = toJson.call(error) as Record<string, unknown>;
    const className = data['__className__'];
    return typeof className === 'string' ? { className, data } : undefined;
  }

  private _connect(): Promise<WebSocket> {
    if (this.socket) return Promise.resolve(this.socket);
    // Shared by concurrent callers, and dropped on failure so the next
    // call can try again rather than inherit a rejected promise.
    this.connecting ??= this._handshake().finally(() => {
      this.connecting = undefined;
    });
    return this.connecting;
  }

  /**
   * Opens the socket and proves the server is answering before any stream
   * uses it: a ping goes out, and the first frame back completes the
   * handshake.
   */
  private _handshake(): Promise<WebSocket> {
    const timeout =
      this.timings.connectionTimeout ?? DEFAULT_CONNECTION_TIMEOUT_MS;
    return new Promise<WebSocket>((resolve, reject) => {
      const ws = new WebSocket(this._url());
      let settled = false;
      const fail = (message: string): void => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        ws.close();
        reject(new ServerpodClientException(message, 0));
      };
      const timer = setTimeout(
        () => fail('WebSocket connection attempt timed out'),
        timeout,
      );
      ws.addEventListener('open', () => ws.send(buildPing()));
      ws.addEventListener('error', () => fail('WebSocket connection failed'));
      ws.addEventListener('close', () => {
        fail('WebSocket closed before the connection was established');
        this._onSocketClosed(ws);
      });
      ws.addEventListener('message', (event) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          this.socket = ws;
          this._startKeepAlive();
          resolve(ws);
        }
        this._onMessage(String(event.data));
      });
    });
  }

  private _url(): string {
    const url = new URL(this.host);
    url.protocol = url.protocol === 'https:' ? 'wss:' : 'ws:';
    url.pathname = '/v1/websocket';
    return url.toString();
  }

  private _startKeepAlive(): void {
    this._stopKeepAlive();
    const interval = this.timings.pingInterval ?? DEFAULT_PING_INTERVAL_MS;
    this.pingTimer = setInterval(() => this._send(buildPing()), interval);
    this._restartIdleTimer();
  }

  private _restartIdleTimer(): void {
    clearTimeout(this.idleTimer);
    const idle = this.timings.idleTimeout ?? DEFAULT_IDLE_TIMEOUT_MS;
    this.idleTimer = setTimeout(() => this.socket?.close(), idle);
  }

  private _stopKeepAlive(): void {
    clearInterval(this.pingTimer);
    clearTimeout(this.idleTimer);
    this.pingTimer = undefined;
    this.idleTimer = undefined;
  }

  private _onMessage(raw: string): void {
    this._restartIdleTimer();
    const envelope = parseEnvelope(raw);
    if (!envelope) {
      this._send(buildBadRequest(raw));
      this.socket?.close();
      return;
    }
    const data = envelope.data ?? {};
    const stream = this.streams.get(String(data[WsKey.connectionId]));
    switch (envelope.type) {
      case WsType.ping:
        this._send(buildPong());
        return;
      case WsType.pong:
      case WsType.openMethodStream:
        return;
      case WsType.openMethodStreamResponse:
        stream?.onOpenResponse(
          data[WsKey.responseType] as OpenMethodStreamResponseType,
        );
        return;
      case WsType.methodStreamMessage:
        this._onValue(stream, data);
        return;
      case WsType.methodStreamException:
        if (!stream) return;
        stream.fail(this._decodeException(data[WsKey.exception]));
        this._forget(stream);
        return;
      case WsType.closeMethodStream:
        if (stream) this._onServerClose(stream, data);
        return;
      case WsType.badRequest:
        this.socket?.close();
        return;
      default:
        this._send(buildBadRequest(raw));
        this.socket?.close();
    }
  }

  private _onValue(
    stream: _MethodStream | undefined,
    data: Record<string, unknown>,
  ): void {
    if (stream && stream.accept(data[WsKey.object])) return;
    // Nobody is listening for this value; tell the server to stop sending.
    this._send(
      buildCloseMethodStream(
        {
          endpoint: String(data[WsKey.endpoint]),
          method: String(data[WsKey.method]),
          connectionId: String(data[WsKey.connectionId]),
        },
        'error',
      ),
    );
    if (stream) this._forget(stream);
  }

  private _onServerClose(
    stream: _MethodStream,
    data: Record<string, unknown>,
  ): void {
    const parameter = data[WsKey.parameter];
    if (typeof parameter === 'string') {
      // The server is done reading one input stream; stop producing it.
      const iterator = stream.inputs.get(parameter);
      stream.inputs.delete(parameter);
      void iterator?.return?.();
      this._closeSocketIfUnused();
      return;
    }
    if (data[WsKey.closeReason] === 'error') {
      stream.fail(
        new ServerpodClientException('The server closed the stream with an error', 0),
      );
    } else {
      stream.end();
    }
    this._forget(stream);
  }

  private _decodeException(envelope: unknown): unknown {
    const decoded = this.serializer.deserializeByClassName(envelope);
    if (decoded instanceof Error) return decoded;
    const className = (envelope as { className?: unknown } | null)?.className;
    return new ServerpodClientException(
      `The stream failed with ${String(className)}`,
      0,
    );
  }

  /** Stops a stream's inputs and drops it; closes the socket when it was the last. */
  private _forget(stream: _MethodStream): void {
    this.streams.delete(stream.to.connectionId);
    for (const iterator of stream.inputs.values()) void iterator.return?.();
    stream.inputs.clear();
    this._closeSocketIfUnused();
  }

  /**
   * Detached before it is closed: closing is asynchronous, and a call made
   * in the meantime must open a fresh connection rather than write to one
   * that is on its way out.
   */
  private _closeSocketIfUnused(): void {
    if (this.streams.size > 0) return;
    const socket = this.socket;
    if (!socket) return;
    this.socket = undefined;
    this._stopKeepAlive();
    socket.close();
  }

  private _onSocketClosed(ws: WebSocket): void {
    if (this.socket !== ws) return;
    this.socket = undefined;
    this._stopKeepAlive();
    const error = new ServerpodClientException('WebSocket connection closed', 0);
    const open = [...this.streams.values()];
    this.streams.clear();
    for (const stream of open) {
      for (const iterator of stream.inputs.values()) void iterator.return?.();
      stream.inputs.clear();
      stream.fail(error);
    }
  }

  private _send(frame: string): void {
    if (this.socket?.readyState === WebSocket.OPEN) this.socket.send(frame);
  }

  /** Ends every stream and closes the connection. */
  close(): void {
    const socket = this.socket;
    if (socket) this._onSocketClosed(socket);
    socket?.close();
  }
}

type _Waiter = {
  resolve: (result: IteratorResult<unknown>) => void;
  reject: (error: unknown) => void;
};

/** The client's half of one streaming call: values in, input streams out. */
class _MethodStream {
  constructor(
    readonly to: StreamAddress,
    private readonly decode: (raw: unknown) => unknown,
  ) {}

  /** The input streams still being forwarded, by parameter name. */
  readonly inputs = new Map<string, AsyncIterator<unknown>>();

  private readonly buffered: unknown[] = [];
  private readonly waiters: _Waiter[] = [];
  private error: unknown;
  private failed = false;
  private ended = false;
  private resolveOpened!: (type: OpenMethodStreamResponseType) => void;
  private rejectOpened!: (error: unknown) => void;

  /** Settles with the server's answer to the open command. */
  readonly opened = new Promise<OpenMethodStreamResponseType>(
    (resolve, reject) => {
      this.resolveOpened = resolve;
      this.rejectOpened = reject;
    },
  );

  onOpenResponse(type: OpenMethodStreamResponseType): void {
    this.resolveOpened(type);
  }

  /** Returns `false` when the value cannot be delivered. */
  accept(object: unknown): boolean {
    if (this.ended) return false;
    let value: unknown;
    try {
      value = this.decode((object as ClassNamedValue).data);
    } catch (e) {
      this.fail(e);
      return false;
    }
    const waiter = this.waiters.shift();
    if (waiter) waiter.resolve({ value, done: false });
    else this.buffered.push(value);
    return true;
  }

  end(): void {
    if (this.ended) return;
    this.ended = true;
    for (const waiter of this.waiters.splice(0)) {
      waiter.resolve({ value: undefined, done: true });
    }
  }

  fail(error: unknown): void {
    this.rejectOpened(error);
    if (this.ended) return;
    this.ended = true;
    this.failed = true;
    this.error = error;
    for (const waiter of this.waiters.splice(0)) waiter.reject(error);
  }

  iterable<T>(onCancel: () => void): AsyncIterable<T> {
    const next = (): Promise<IteratorResult<unknown>> => {
      // Values that arrived before the failure are still delivered first.
      if (this.buffered.length > 0) {
        return Promise.resolve({ value: this.buffered.shift(), done: false });
      }
      if (this.failed) return Promise.reject(this.error);
      if (this.ended) return Promise.resolve({ value: undefined, done: true });
      return new Promise((resolve, reject) =>
        this.waiters.push({ resolve, reject }),
      );
    };
    const cancel = (): void => {
      if (this.ended) return;
      this.end();
      onCancel();
    };
    return {
      [Symbol.asyncIterator]: (): AsyncIterator<T> => ({
        next: next as () => Promise<IteratorResult<T>>,
        return: async (value?: unknown): Promise<IteratorResult<T>> => {
          cancel();
          return { value: value as T, done: true };
        },
      }),
    };
  }
}

/**
 * An iterable that opens its source on first use. A streaming endpoint
 * method returns one synchronously — `for await (const v of
 * client.feed.watch())` — while the call itself is asynchronous.
 */
export function deferredIterable<T>(
  open: () => Promise<AsyncIterable<T>>,
): AsyncIterable<T> {
  return {
    [Symbol.asyncIterator](): AsyncIterator<T> {
      let source: Promise<AsyncIterator<T>> | undefined;
      const iterator = (): Promise<AsyncIterator<T>> =>
        (source ??= open().then((it) => it[Symbol.asyncIterator]()));
      return {
        next: async () => (await iterator()).next(),
        return: async (value?: unknown) => {
          // Never opened: there is nothing to close on the server.
          if (source === undefined) return { value: value as T, done: true };
          const it = await source;
          return it.return ? it.return(value) : { value: value as T, done: true };
        },
      };
    },
  };
}

/**
 * The single result of a call that takes input streams but returns a
 * `Future`: the server sends at most one value and closes the stream.
 */
export async function streamResult<T>(stream: AsyncIterable<T>): Promise<T> {
  for await (const value of stream) return value;
  return undefined as T;
}

function _openError(type: OpenMethodStreamResponseType): ServerpodClientException {
  switch (type) {
    case 'endpointNotFound':
      return new ServerpodClientException('Endpoint not found', 404);
    case 'authenticationFailed':
      return new ServerpodClientException('Authentication failed', 401);
    case 'authorizationDeclined':
      return new ServerpodClientException('Authorization declined', 403);
    case 'invalidArguments':
      return new ServerpodClientException('Invalid arguments', 400);
    default:
      return new ServerpodClientException(
        `Failed to open the stream: ${String(type)}`,
        0,
      );
  }
}

function _isRefreshable(
  provider: ClientAuthKeyProvider | undefined,
): provider is RefreshableClientAuthKeyProvider {
  return (
    provider !== undefined &&
    typeof (provider as RefreshableClientAuthKeyProvider).refresh === 'function'
  );
}
