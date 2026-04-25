import { HttpEndpointCaller, type EndpointCaller } from './endpoint.js';
import { HttpTransport, type UnaryCallOptions } from './http_transport.js';
import type { SerializationManager } from './serialization.js';
import type { ClientOptions } from './types.js';
import {
  ClientMethodStreamManager,
  type InputStreamSpec,
} from './ws_transport.js';

/**
 * Base for every generated top-level `Client`. The generated subclass
 * adds one field per top-level endpoint, instantiated in its constructor.
 *
 * The generated subclass passes the `SerializationManager` it owns
 * (the project `Protocol` extends `SerializationManager`) so the
 * transport encodes/decodes via a project-aware deserializer.
 */
export abstract class ServerpodClientShared implements EndpointCaller {
  protected readonly transport: HttpTransport;
  protected readonly streams: ClientMethodStreamManager;
  private readonly _caller: HttpEndpointCaller;

  constructor(
    public readonly host: string,
    public readonly serializer: SerializationManager,
    public readonly options: ClientOptions = {},
  ) {
    this.transport = new HttpTransport(host, serializer, options);
    this.streams = new ClientMethodStreamManager(
      host,
      serializer,
      options.authKeyProvider,
    );
    this._caller = new HttpEndpointCaller(this.transport, this.streams);
  }

  callServerEndpoint<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    options?: UnaryCallOptions,
  ): Promise<T> {
    return this._caller.callServerEndpoint(
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
    return this._caller.callStreamingServerEndpoint(
      endpoint,
      method,
      args,
      decode,
      inputStreams,
    );
  }
}
