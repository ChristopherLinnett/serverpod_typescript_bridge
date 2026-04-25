/**
 * Sealed union of WebSocket frame types. Mirrors
 * `serverpod_serialization-3.4.7/lib/src/websocket_messages.dart`
 * byte-for-byte; the envelope MUST match the Dart side exactly or
 * Serverpod will reject the frame.
 *
 * Envelope shape: `{ "type": "<typeName>", "data": { ... } }`.
 */

export type WsMessageType =
  | 'ping'
  | 'pong'
  | 'bad_request'
  | 'open_method_stream_command'
  | 'open_method_stream_response'
  | 'close_method_stream_command'
  | 'method_stream_message'
  | 'method_stream_serializable_exception';

export interface WsEnvelope<TData = unknown> {
  type: WsMessageType;
  data: TData;
}

export interface OpenMethodStreamCommandData {
  endpoint: string;
  method: string;
  connectionId: string;
  /** Double-encoded JSON string of the args map — matches Dart contract. */
  args: string;
  inputStreams: string[];
  authentication?: string;
}

export type OpenMethodStreamResponseType =
  | 'success'
  | 'endpointNotFound'
  | 'authenticationFailed'
  | 'authorizationDeclined'
  | 'invalidArguments';

export interface OpenMethodStreamResponseData {
  endpoint: string;
  method: string;
  connectionId: string;
  responseType: OpenMethodStreamResponseType;
}

export interface CloseMethodStreamCommandData {
  endpoint: string;
  method: string;
  connectionId: string;
  parameter?: string;
}

export interface MethodStreamMessageData {
  endpoint: string;
  method: string;
  connectionId: string;
  /**
   * If set, this message is an INPUT stream value the client is
   * sending to the server. Omitted means it's an OUTPUT stream value
   * the server sent to the client.
   */
  parameter?: string;
  /**
   * `{ className, data }` envelope per `wrapWithClassName` in Dart.
   *
   * `data` is `unknown` rather than `Record<…>` because stream values
   * can serialize to a primitive, an array, or an object depending on
   * the type mapper output. The receiver-side decoder is responsible
   * for validating the actual JSON shape.
   */
  object: { className: string; data: unknown };
}

export interface MethodStreamSerializableExceptionData {
  endpoint: string;
  method: string;
  connectionId: string;
  /** `{ className, data }` envelope of the typed exception. */
  object: { className: string; data: Record<string, unknown> };
}

export interface BadRequestMessageData {
  reason: string;
}

export function buildEnvelope<T>(type: WsMessageType, data: T): string {
  return JSON.stringify({ type, data });
}

export function parseEnvelope(raw: string): WsEnvelope | null {
  try {
    const parsed = JSON.parse(raw);
    if (
      parsed === null ||
      typeof parsed !== 'object' ||
      typeof parsed.type !== 'string'
    ) {
      return null;
    }
    return parsed as WsEnvelope;
  } catch {
    return null;
  }
}
