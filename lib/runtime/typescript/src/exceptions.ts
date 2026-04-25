/**
 * Base for every error the Serverpod TS client surfaces. Concrete
 * subclasses signal HTTP-status categories or specific transport
 * conditions.
 */
export class ServerpodClientException extends Error {
  constructor(
    message: string,
    public readonly statusCode: number,
    public readonly responseBody?: string,
  ) {
    super(message);
    this.name = 'ServerpodClientException';
  }
}

export class ServerpodClientBadRequest extends ServerpodClientException {
  constructor(responseBody: string) {
    super('Bad request', 400, responseBody);
    this.name = 'ServerpodClientBadRequest';
  }
}

export class ServerpodClientUnauthorized extends ServerpodClientException {
  constructor(responseBody?: string) {
    super('Unauthorized', 401, responseBody);
    this.name = 'ServerpodClientUnauthorized';
  }
}

export class ServerpodClientForbidden extends ServerpodClientException {
  constructor(responseBody?: string) {
    super('Forbidden', 403, responseBody);
    this.name = 'ServerpodClientForbidden';
  }
}

export class ServerpodClientNotFound extends ServerpodClientException {
  constructor(responseBody?: string) {
    super('Not found', 404, responseBody);
    this.name = 'ServerpodClientNotFound';
  }
}

export class ServerpodClientInternalServerError extends ServerpodClientException {
  constructor(responseBody?: string) {
    super('Internal server error', 500, responseBody);
    this.name = 'ServerpodClientInternalServerError';
  }
}

/**
 * Maps an HTTP status code (and the response body text) to the
 * corresponding `ServerpodClientException` subclass. Mirrors Dart's
 * `getExceptionFrom` function.
 */
export function exceptionFromStatus(
  statusCode: number,
  body: string,
): ServerpodClientException {
  switch (statusCode) {
    case 400:
      return new ServerpodClientBadRequest(body);
    case 401:
      return new ServerpodClientUnauthorized(body);
    case 403:
      return new ServerpodClientForbidden(body);
    case 404:
      return new ServerpodClientNotFound(body);
    case 500:
      return new ServerpodClientInternalServerError(body);
    default:
      return new ServerpodClientException(
        `Unknown error, statusCode=${statusCode}`,
        statusCode,
        body,
      );
  }
}
