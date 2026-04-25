import type { HttpTransport, UnaryCallOptions } from './http_transport.js';
import type {
  ClientMethodStreamManager,
  InputStreamSpec,
} from './ws_transport.js';

/**
 * Bridges a generated `EndpointXxx` class to whatever transport its
 * containing `Client` is using. Generated code calls
 * `caller.callServerEndpoint(...)`; the parent `Client` (or
 * `ModuleEndpointCaller`) implements the method.
 */
export interface EndpointCaller {
  callServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    options?: UnaryCallOptions,
  ): Promise<T>;

  /**
   * Open a server-side streaming method. Implementations route through
   * the parent's [ClientMethodStreamManager]. Pass [inputStreams] for
   * bidirectional methods — one entry per `Stream<T>` parameter the
   * server expects.
   */
  callStreamingServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    inputStreams?: Record<string, InputStreamSpec>,
  ): Promise<AsyncIterable<T>>;
}

/**
 * Base class for every generated `EndpointXxx`.
 *
 * Generated subclasses override `name` and add typed methods that
 * delegate to `caller.callServerEndpoint(...)`.
 */
export abstract class EndpointRef {
  constructor(public readonly caller: EndpointCaller) {}

  abstract get name(): string;
}

/**
 * Module endpoints route through the parent `Client`. Generated module
 * `Caller` classes extend this; their endpoint fields call back through
 * `parent.callServerEndpoint(...)`.
 */
export abstract class ModuleEndpointCaller implements EndpointCaller {
  constructor(protected readonly parent: EndpointCaller) {}

  callServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    options?: UnaryCallOptions,
  ): Promise<T> {
    return this.parent.callServerEndpoint(
      endpoint,
      method,
      args,
      decode,
      options,
    );
  }

  callStreamingServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    inputStreams?: Record<string, InputStreamSpec>,
  ): Promise<AsyncIterable<T>> {
    return this.parent.callStreamingServerEndpoint(
      endpoint,
      method,
      args,
      decode,
      inputStreams,
    );
  }
}

/**
 * Default `EndpointCaller` impl backed by an `HttpTransport`. The
 * generated top-level `Client` extends `ServerpodClientShared` (which
 * delegates here).
 */
export class HttpEndpointCaller implements EndpointCaller {
  constructor(
    private readonly transport: HttpTransport,
    private readonly streams?: ClientMethodStreamManager,
  ) {}

  callServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    options?: UnaryCallOptions,
  ): Promise<T> {
    return this.transport.call(endpoint, method, args, decode, options);
  }

  callStreamingServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    inputStreams?: Record<string, InputStreamSpec>,
  ): Promise<AsyncIterable<T>> {
    if (!this.streams) {
      throw new Error(
        'No ClientMethodStreamManager configured — streaming endpoints ' +
          'require ServerpodClientShared with the streaming runtime wired.',
      );
    }
    return this.streams.openMethodStream<T>({
      endpoint,
      method,
      args,
      decode,
      ...(inputStreams ? { inputStreams } : {}),
    });
  }
}
