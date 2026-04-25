import type { HttpTransport, UnaryCallOptions } from './http_transport.js';

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
}

/**
 * Default `EndpointCaller` impl backed by an `HttpTransport`. The
 * generated top-level `Client` extends `ServerpodClientShared` (which
 * delegates here).
 */
export class HttpEndpointCaller implements EndpointCaller {
  constructor(private readonly transport: HttpTransport) {}

  callServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    options?: UnaryCallOptions,
  ): Promise<T> {
    return this.transport.call(endpoint, method, args, decode, options);
  }
}
