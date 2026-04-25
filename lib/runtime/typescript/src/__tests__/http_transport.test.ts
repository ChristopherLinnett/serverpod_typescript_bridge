import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  ServerpodClientBadRequest,
  ServerpodClientException,
  ServerpodClientInternalServerError,
  ServerpodClientNotFound,
  ServerpodClientUnauthorized,
} from '../exceptions.js';
import { HttpTransport } from '../http_transport.js';
import { SerializationManager } from '../serialization.js';
import type {
  ClientAuthKeyProvider,
  RefreshableClientAuthKeyProvider,
} from '../types.js';

class StubProtocol extends SerializationManager {
  deserialize<T>(json: unknown): T {
    return json as T;
  }
  deserializeByClassName(envelope: unknown): unknown | undefined {
    if (
      envelope === null ||
      typeof envelope !== 'object' ||
      !('className' in envelope)
    ) {
      return undefined;
    }
    return undefined;
  }
}

const fetchMock = vi.fn<typeof fetch>();

beforeEach(() => {
  fetchMock.mockReset();
  // @ts-expect-error — overwriting the global for the test
  globalThis.fetch = fetchMock;
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe('HttpTransport.call', () => {
  it('POSTs to <host>/<endpoint> with the method-injected JSON body', async () => {
    fetchMock.mockResolvedValueOnce(
      new Response(JSON.stringify({ greeting: 'hi' }), { status: 200 }),
    );
    const transport = new HttpTransport('https://api.example.com', new StubProtocol());

    await transport.call(
      'greet',
      'sayHi',
      { name: 'world', count: 3 },
      (raw) => raw,
    );

    expect(fetchMock).toHaveBeenCalledTimes(1);
    const [url, init] = fetchMock.mock.calls[0]!;
    expect(url).toBe('https://api.example.com/greet');
    expect(init?.method).toBe('POST');
    const body = JSON.parse(init!.body as string) as Record<string, unknown>;
    expect(body['method']).toBe('sayHi');
    expect(body['name']).toBe('world');
    expect(body['count']).toBe(3);
    expect(
      (init!.headers as Record<string, string>)['Content-Type'],
    ).toMatch(/application\/json/);
  });

  it('returns the decoded response body on 200', async () => {
    fetchMock.mockResolvedValueOnce(
      new Response('"echoed"', { status: 200 }),
    );
    const transport = new HttpTransport('https://x.test', new StubProtocol());
    const out = await transport.call('e', 'm', {}, (raw) => raw as string);
    expect(out).toBe('echoed');
  });

  it.each([
    [400, ServerpodClientBadRequest],
    [401, ServerpodClientUnauthorized],
    [404, ServerpodClientNotFound],
    [500, ServerpodClientInternalServerError],
  ])('throws on status %i', async (status, ctor) => {
    fetchMock.mockResolvedValueOnce(new Response('boom', { status }));
    const transport = new HttpTransport('https://x.test', new StubProtocol());

    await expect(transport.call('e', 'm', {}, (r) => r)).rejects.toBeInstanceOf(
      ctor,
    );
  });

  it('attaches the Authorization header when a provider yields a value', async () => {
    fetchMock.mockResolvedValueOnce(new Response('null', { status: 200 }));
    const provider: ClientAuthKeyProvider = {
      getAuthHeaderValue: async () => 'wrapped-token',
    };
    const transport = new HttpTransport(
      'https://x.test',
      new StubProtocol(),
      { authKeyProvider: provider },
    );

    await transport.call('e', 'm', {}, (r) => r);

    const init = fetchMock.mock.calls[0]![1]!;
    expect((init.headers as Record<string, string>)['Authorization']).toBe(
      'wrapped-token',
    );
  });

  it('omits Authorization on a public/unauthenticated call', async () => {
    fetchMock.mockResolvedValueOnce(new Response('null', { status: 200 }));
    const provider: ClientAuthKeyProvider = {
      getAuthHeaderValue: async () => 'wrapped-token',
    };
    const transport = new HttpTransport(
      'https://x.test',
      new StubProtocol(),
      { authKeyProvider: provider },
    );

    await transport.call('e', 'm', {}, (r) => r, { authenticated: false });

    const headers = fetchMock.mock.calls[0]![1]!.headers as Record<string, string>;
    expect(headers['Authorization']).toBeUndefined();
  });

  it('refreshes once on 401 and retries with the new auth value', async () => {
    let nextValue = 'expired';
    const refresh = vi.fn(async () => {
      nextValue = 'fresh';
    });
    const provider: RefreshableClientAuthKeyProvider = {
      getAuthHeaderValue: async () => nextValue,
      refresh,
    };
    fetchMock
      .mockResolvedValueOnce(new Response('expired', { status: 401 }))
      .mockResolvedValueOnce(new Response('"ok"', { status: 200 }));

    const transport = new HttpTransport(
      'https://x.test',
      new StubProtocol(),
      { authKeyProvider: provider },
    );

    const out = await transport.call('e', 'm', {}, (raw) => raw as string);
    expect(out).toBe('ok');
    expect(refresh).toHaveBeenCalledTimes(1);

    const firstAuth = (fetchMock.mock.calls[0]![1]!.headers as Record<string, string>)[
      'Authorization'
    ];
    const secondAuth = (fetchMock.mock.calls[1]![1]!.headers as Record<string, string>)[
      'Authorization'
    ];
    expect(firstAuth).toBe('expired');
    expect(secondAuth).toBe('fresh');
  });

  it('does not retry on 401 if the provider is not refreshable', async () => {
    fetchMock.mockResolvedValueOnce(new Response('nope', { status: 401 }));
    const provider: ClientAuthKeyProvider = {
      getAuthHeaderValue: async () => 'expired',
    };
    const transport = new HttpTransport(
      'https://x.test',
      new StubProtocol(),
      { authKeyProvider: provider },
    );

    await expect(transport.call('e', 'm', {}, (r) => r)).rejects.toBeInstanceOf(
      ServerpodClientUnauthorized,
    );
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('does not retry a second time if the refreshed call also returns 401', async () => {
    const refresh = vi.fn(async () => {});
    const provider: RefreshableClientAuthKeyProvider = {
      getAuthHeaderValue: async () => 'still-bad',
      refresh,
    };
    fetchMock
      .mockResolvedValueOnce(new Response('nope', { status: 401 }))
      .mockResolvedValueOnce(new Response('still nope', { status: 401 }));

    const transport = new HttpTransport(
      'https://x.test',
      new StubProtocol(),
      { authKeyProvider: provider },
    );

    await expect(transport.call('e', 'm', {}, (r) => r)).rejects.toBeInstanceOf(
      ServerpodClientUnauthorized,
    );
    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(refresh).toHaveBeenCalledTimes(1);
  });

  it('strips a trailing slash on host', async () => {
    fetchMock.mockResolvedValueOnce(new Response('null', { status: 200 }));
    const transport = new HttpTransport(
      'https://x.test/',
      new StubProtocol(),
    );
    await transport.call('e', 'm', {}, (r) => r);
    expect(fetchMock.mock.calls[0]![0]).toBe('https://x.test/e');
  });

  it('falls back to the base class for an unmapped status', async () => {
    fetchMock.mockResolvedValueOnce(new Response('teapot', { status: 418 }));
    const transport = new HttpTransport('https://x.test', new StubProtocol());
    const error = (await transport
      .call('e', 'm', {}, (r) => r)
      .catch((e) => e)) as Error;
    expect(error).toBeInstanceOf(ServerpodClientException);
    expect(error).not.toBeInstanceOf(ServerpodClientBadRequest);
    expect((error as ServerpodClientException).statusCode).toBe(418);
  });

  it('rejects an empty host at construction time', () => {
    expect(() => new HttpTransport('', new StubProtocol())).toThrow();
  });
});
