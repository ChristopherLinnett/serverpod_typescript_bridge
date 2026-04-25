/**
 * Anything that can be sent over the wire. Generated model classes
 * implement this. The `__className__` field embedded by `toJson` is what
 * lets the runtime dispatch polymorphic decode at the receiving end.
 */
export interface SerializableModel {
  toJson(): Record<string, unknown>;
}

/**
 * A serializable Dart-side `SerializableException` subclass. On the wire
 * it looks like `{ className, data }`; the runtime decodes it back into
 * the corresponding generated TS class so callers can `instanceof`-check
 * the typed exception.
 */
export interface SerializableException extends SerializableModel {
  readonly name: string;
  readonly message: string;
}

/**
 * Per-call context passed to onSucceededCall / onFailedCall callbacks.
 * Mirrors `MethodCallContext` from serverpod_client.
 */
export interface MethodCallContext {
  readonly endpoint: string;
  readonly method: string;
  readonly arguments: Record<string, unknown>;
}

/**
 * Construction options for a generated `Client`. Mirrors the named
 * arguments on `ServerpodClientShared(...)` in Dart.
 */
export interface ClientOptions {
  /** Wall-clock timeout for unary HTTP calls, in milliseconds. */
  connectionTimeout?: number;
  /** Auth provider used to attach `Authorization` headers. */
  authKeyProvider?: ClientAuthKeyProvider;
  /** Invoked after every successful call. */
  onSucceededCall?: (ctx: MethodCallContext) => void;
  /** Invoked after every failed call (any thrown exception). */
  onFailedCall?: (
    ctx: MethodCallContext,
    error: unknown,
  ) => void;
}

/**
 * Provides the value sent in the `Authorization` header. Stable across
 * calls unless the consumer rotates its credentials.
 */
export interface ClientAuthKeyProvider {
  /** Returns the wrapped auth header value, or `null` to send no header. */
  getAuthHeaderValue(): Promise<string | null>;
}

/**
 * Auth provider that supports a one-shot retry after a 401 response —
 * the runtime will call `refresh()` once, then retry the call with the
 * provider's new value. If the second call also fails, the exception
 * propagates.
 */
export interface RefreshableClientAuthKeyProvider extends ClientAuthKeyProvider {
  refresh(): Promise<void>;
}
