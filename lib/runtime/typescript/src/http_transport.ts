import {
  exceptionFromStatus,
  ServerpodClientException,
  ServerpodClientUnauthorized,
} from './exceptions.js';
import type { SerializationManager } from './serialization.js';
import type {
  ClientAuthKeyProvider,
  ClientOptions,
  MethodCallContext,
  RefreshableClientAuthKeyProvider,
} from './types.js';

export interface UnaryCallOptions {
  authenticated?: boolean;
}

/**
 * Issues unary HTTP calls against a Serverpod backend.
 *
 * Wire contract:
 *   POST <host>/<endpointName>
 *   Content-Type: application/json; charset=utf-8
 *   Authorization: <auth value>   (when authenticated and provider non-null)
 *   body: JSON.stringify({ method: '<methodName>', ...encodedArgs })
 */
export class HttpTransport {
  constructor(
    private readonly host: string,
    private readonly serializer: SerializationManager,
    private readonly options: ClientOptions = {},
  ) {
    if (!host) throw new Error('HttpTransport: host must be a non-empty URL');
  }

  async call<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    callOptions: UnaryCallOptions = {},
  ): Promise<T> {
    const ctx: MethodCallContext = {
      endpoint,
      method,
      arguments: args,
    };
    try {
      const result = await this._dispatch<T>(
        endpoint,
        method,
        args,
        decode,
        callOptions,
        false,
      );
      this.options.onSucceededCall?.(ctx);
      return result;
    } catch (error) {
      this.options.onFailedCall?.(ctx, error);
      throw error;
    }
  }

  /**
   * Single retry on 401 when the auth provider supports refresh. The
   * `_alreadyRetried` flag prevents infinite recursion if the second
   * attempt also returns 401.
   */
  private async _dispatch<T>(
    endpoint: string,
    method: string,
    args: Record<string, unknown>,
    decode: (raw: unknown) => T,
    callOptions: UnaryCallOptions,
    alreadyRetried: boolean,
  ): Promise<T> {
    const url = `${this._normalizeHost()}/${endpoint}`;
    const body = JSON.stringify({
      method,
      ...this._encodeArgs(args),
    });
    const headers = await this._headers(callOptions.authenticated ?? true);

    const response = await this._fetchWithTimeout(url, body, headers);
    if (response.ok) {
      if (response.status === 204) return undefined as unknown as T;
      const text = await response.text();
      if (text === '') return undefined as unknown as T;
      return decode(JSON.parse(text));
    }

    const responseBody = await response.text();
    if (
      response.status === 401 &&
      !alreadyRetried &&
      this._isRefreshable(this.options.authKeyProvider)
    ) {
      await this.options.authKeyProvider.refresh();
      return this._dispatch(endpoint, method, args, decode, callOptions, true);
    }

    const typed = this._tryDecodeTypedException(responseBody);
    if (typed instanceof Error) throw typed;
    throw exceptionFromStatus(response.status, responseBody);
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

  private async _headers(
    authenticated: boolean,
  ): Promise<Record<string, string>> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json; charset=utf-8',
    };
    if (!authenticated) return headers;
    const provider = this.options.authKeyProvider;
    if (!provider) return headers;
    const value = await provider.getAuthHeaderValue();
    if (value) headers['Authorization'] = value;
    return headers;
  }

  private _normalizeHost(): string {
    return this.host.endsWith('/') ? this.host.slice(0, -1) : this.host;
  }

  private async _fetchWithTimeout(
    url: string,
    body: string,
    headers: Record<string, string>,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeout =
      this.options.connectionTimeout !== undefined
        ? setTimeout(() => controller.abort(), this.options.connectionTimeout)
        : null;
    try {
      return await fetch(url, {
        method: 'POST',
        headers,
        body,
        signal: controller.signal,
      });
    } finally {
      if (timeout !== null) clearTimeout(timeout);
    }
  }

  private _isRefreshable(
    provider: ClientAuthKeyProvider | undefined,
  ): provider is RefreshableClientAuthKeyProvider {
    return (
      provider !== undefined &&
      typeof (provider as RefreshableClientAuthKeyProvider).refresh ===
        'function'
    );
  }

  private _tryDecodeTypedException(body: string): Error | undefined {
    if (body === '') return undefined;
    let parsed: unknown;
    try {
      parsed = JSON.parse(body);
    } catch {
      return undefined;
    }
    if (
      parsed === null ||
      typeof parsed !== 'object' ||
      !('className' in parsed) ||
      !('data' in parsed)
    ) {
      return undefined;
    }
    const decoded = this.serializer.deserializeByClassName(parsed);
    return decoded instanceof Error ? decoded : undefined;
  }
}

// Re-export so consumers can `instanceof`-check without crossing files.
export { ServerpodClientException, ServerpodClientUnauthorized };
