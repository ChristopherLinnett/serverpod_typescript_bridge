/**
 * The frames exchanged on Serverpod's method-stream WebSocket.
 *
 * Mirrors `serverpod_serialization/src/websocket_messages.dart` and
 * `websocket_message_keys.dart` (Serverpod 4): every key below is the
 * abbreviated form Serverpod puts on the wire, and a frame the server
 * cannot parse closes the whole connection.
 *
 * Envelope: `{ "type": "<type>", "data": { ... } }`; `data` is absent on
 * `ping` and `pong`.
 */

export const WsType = {
  badRequest: 'brm',
  closeMethodStream: 'cmsc',
  methodStreamMessage: 'msm',
  methodStreamException: 'msse',
  openMethodStream: 'omsc',
  openMethodStreamResponse: 'omsr',
  ping: 'ping',
  pong: 'pong',
} as const;

export type WsMessageType = (typeof WsType)[keyof typeof WsType];

export const WsKey = {
  args: 'args',
  authMode: 'am',
  authentication: 'auth',
  closeReason: 'cr',
  connectionId: 'cid',
  endpoint: 'en',
  exception: 'ex',
  inputStreams: 'is',
  method: 'm',
  object: 'o',
  parameter: 'p',
  request: 'req',
  responseType: 'res',
} as const;

export type OpenMethodStreamResponseType =
  | 'success'
  | 'endpointNotFound'
  | 'authenticationFailed'
  | 'authorizationDeclined'
  | 'invalidArguments';

/** Why a stream ended: it completed, or it failed. */
export type CloseReason = 'done' | 'error';

/** A value with the class name the receiver decodes it by. */
export interface ClassNamedValue {
  className: string;
  data: unknown;
}

/**
 * Pairs an encoded value with the class name the server decodes it by.
 *
 * A model's own `__className__` wins over [declared]: it names the
 * concrete class, which is the only name the server knows when the
 * declared type is a sealed parent.
 */
export function classNamed(declared: string, data: unknown): ClassNamedValue {
  if (data === null || data === undefined) return { className: 'null', data: null };
  if (typeof data === 'object' && !Array.isArray(data)) {
    const own = (data as Record<string, unknown>)['__className__'];
    if (typeof own === 'string') return { className: own, data };
  }
  return { className: declared, data };
}

/** The three fields that identify one method stream on a connection. */
export interface StreamAddress {
  endpoint: string;
  method: string;
  /** A UUID. The server parses it as one and rejects anything else. */
  connectionId: string;
}

export interface WsEnvelope {
  type: string;
  data?: Record<string, unknown>;
}

function build(type: WsMessageType, data?: Record<string, unknown>): string {
  return JSON.stringify(data === undefined ? { type } : { type, data });
}

function address(to: StreamAddress): Record<string, unknown> {
  return {
    [WsKey.endpoint]: to.endpoint,
    [WsKey.method]: to.method,
    [WsKey.connectionId]: to.connectionId,
  };
}

export function buildPing(): string {
  return build(WsType.ping);
}

export function buildPong(): string {
  return build(WsType.pong);
}

/** Echoes back a frame this client could not parse, as Serverpod's client does. */
export function buildBadRequest(request: string): string {
  return build(WsType.badRequest, { [WsKey.request]: request });
}

export function buildOpenMethodStream(
  to: StreamAddress,
  opts: {
    /** Already-encoded call arguments; sent as a JSON string inside the frame. */
    args: Record<string, unknown>;
    inputStreams: string[];
    authentication?: string | null;
  },
): string {
  return build(WsType.openMethodStream, {
    ...address(to),
    [WsKey.args]: JSON.stringify(opts.args),
    [WsKey.inputStreams]: opts.inputStreams,
    ...(opts.authentication
      ? { [WsKey.authentication]: opts.authentication }
      : {}),
  });
}

/** Closes the whole call, or one of its input streams when [parameter] is set. */
export function buildCloseMethodStream(
  to: StreamAddress,
  reason: CloseReason,
  parameter?: string,
): string {
  return build(WsType.closeMethodStream, {
    ...address(to),
    ...(parameter !== undefined ? { [WsKey.parameter]: parameter } : {}),
    [WsKey.closeReason]: reason,
  });
}

/** One value on the input stream named [parameter]. */
export function buildMethodStreamMessage(
  to: StreamAddress,
  parameter: string,
  object: ClassNamedValue,
): string {
  return build(WsType.methodStreamMessage, {
    ...address(to),
    [WsKey.parameter]: parameter,
    [WsKey.object]: object,
  });
}

/** A typed exception thrown by the input stream named [parameter]. */
export function buildMethodStreamException(
  to: StreamAddress,
  parameter: string,
  exception: ClassNamedValue,
): string {
  return build(WsType.methodStreamException, {
    ...address(to),
    [WsKey.parameter]: parameter,
    [WsKey.exception]: exception,
  });
}

/** Returns `null` for anything that is not a `{ type, data? }` object. */
export function parseEnvelope(raw: string): WsEnvelope | null {
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    return null;
  }
  if (parsed === null || typeof parsed !== 'object') return null;
  const { type, data } = parsed as { type?: unknown; data?: unknown };
  if (typeof type !== 'string') return null;
  if (data !== undefined && (data === null || typeof data !== 'object')) {
    return null;
  }
  return { type, ...(data ? { data: data as Record<string, unknown> } : {}) };
}
