import { describe, expect, it } from 'vitest';
import {
  exceptionFromStatus,
  ServerpodClientBadRequest,
  ServerpodClientException,
  ServerpodClientForbidden,
  ServerpodClientInternalServerError,
  ServerpodClientNotFound,
  ServerpodClientUnauthorized,
} from '../exceptions.js';

describe('exceptionFromStatus', () => {
  it.each([
    [400, ServerpodClientBadRequest],
    [401, ServerpodClientUnauthorized],
    [403, ServerpodClientForbidden],
    [404, ServerpodClientNotFound],
    [500, ServerpodClientInternalServerError],
  ])('maps %i to its specific subclass', (status, ctor) => {
    const err = exceptionFromStatus(status, 'body');
    expect(err).toBeInstanceOf(ctor);
    expect(err).toBeInstanceOf(ServerpodClientException);
    expect(err.statusCode).toBe(status);
  });

  it('falls back to the base class for unmapped statuses', () => {
    const err = exceptionFromStatus(418, 'I am a teapot');
    expect(err).toBeInstanceOf(ServerpodClientException);
    expect(err).not.toBeInstanceOf(ServerpodClientBadRequest);
    expect(err.statusCode).toBe(418);
    expect(err.responseBody).toBe('I am a teapot');
  });

  it('preserves the response body for diagnostics', () => {
    const err = exceptionFromStatus(400, '{"reason":"bad arg"}');
    expect(err.responseBody).toBe('{"reason":"bad arg"}');
  });
});
