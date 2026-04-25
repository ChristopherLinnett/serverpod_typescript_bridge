/**
 * Wire-format encode/decode helpers. Mirrors `serverpod_serialization`'s
 * extensions on each primitive — the rules MUST match byte-for-byte
 * with the Dart side. See `docs/architecture.md` for the canonical table.
 */

const BASE64_CHARS =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

// ---------- DateTime ----------

export function encodeDateTime(value: Date): string {
  // Always UTC ISO-8601, matching `value.toUtc().toIso8601String()` in Dart.
  return value.toISOString();
}

export function decodeDateTime(json: unknown): Date {
  if (typeof json === 'string') return new Date(json);
  if (typeof json === 'number') return new Date(json);
  throw new TypeError(
    `Cannot decode DateTime from ${typeof json}: ${JSON.stringify(json)}`,
  );
}

// ---------- Duration (encoded as integer milliseconds) ----------

/** Wraps a Dart `Duration`, encoded as an integer count of milliseconds. */
export function encodeDuration(milliseconds: number): number {
  if (!Number.isInteger(milliseconds)) {
    throw new TypeError(
      `Duration must be an integer number of ms, got ${milliseconds}`,
    );
  }
  return milliseconds;
}

export function decodeDuration(json: unknown): number {
  if (typeof json === 'number' && Number.isInteger(json)) return json;
  if (typeof json === 'string') {
    const parsed = Number.parseInt(json, 10);
    if (!Number.isNaN(parsed)) return parsed;
  }
  throw new TypeError(
    `Cannot decode Duration from ${typeof json}: ${JSON.stringify(json)}`,
  );
}

// ---------- BigInt (string on the wire) ----------

export function encodeBigInt(value: bigint): string {
  return value.toString();
}

export function decodeBigInt(json: unknown): bigint {
  if (typeof json === 'string') return BigInt(json);
  if (typeof json === 'number' && Number.isInteger(json)) return BigInt(json);
  throw new TypeError(
    `Cannot decode BigInt from ${typeof json}: ${JSON.stringify(json)}`,
  );
}

// ---------- bool (also accepts 0/1) ----------

export function decodeBool(json: unknown): boolean {
  if (typeof json === 'boolean') return json;
  if (json === 0) return false;
  if (json === 1) return true;
  throw new TypeError(
    `Cannot decode bool from ${typeof json}: ${JSON.stringify(json)}`,
  );
}

// ---------- ByteData (base64) ----------

export function encodeBytes(value: Uint8Array): string {
  return base64Encode(value);
}

export function decodeBytes(json: unknown): Uint8Array {
  if (typeof json !== 'string') {
    throw new TypeError(
      `Cannot decode ByteData from ${typeof json}: ${JSON.stringify(json)}`,
    );
  }
  return base64Decode(json);
}

function base64Encode(bytes: Uint8Array): string {
  // Avoids relying on `btoa` (browser-only) or `Buffer` (Node-only) so the
  // runtime works in both environments without polyfills.
  let result = '';
  let i = 0;
  for (; i + 2 < bytes.length; i += 3) {
    const a = bytes[i]!;
    const b = bytes[i + 1]!;
    const c = bytes[i + 2]!;
    result += BASE64_CHARS[a >> 2];
    result += BASE64_CHARS[((a & 0x03) << 4) | (b >> 4)];
    result += BASE64_CHARS[((b & 0x0f) << 2) | (c >> 6)];
    result += BASE64_CHARS[c & 0x3f];
  }
  if (i < bytes.length) {
    const a = bytes[i]!;
    const b = i + 1 < bytes.length ? bytes[i + 1]! : 0;
    result += BASE64_CHARS[a >> 2];
    result += BASE64_CHARS[((a & 0x03) << 4) | (b >> 4)];
    result += i + 1 < bytes.length ? BASE64_CHARS[(b & 0x0f) << 2] : '=';
    result += '=';
  }
  return result;
}

function base64Decode(text: string): Uint8Array {
  const cleaned = text.replace(/[^A-Za-z0-9+/=]/g, '');
  const padded = cleaned.replace(/=+$/, '');
  const out = new Uint8Array(Math.floor((padded.length * 3) / 4));
  let outIdx = 0;
  for (let i = 0; i < padded.length; i += 4) {
    const c0 = BASE64_CHARS.indexOf(padded[i]!);
    const c1 = BASE64_CHARS.indexOf(padded[i + 1] ?? 'A');
    const c2 = BASE64_CHARS.indexOf(padded[i + 2] ?? 'A');
    const c3 = BASE64_CHARS.indexOf(padded[i + 3] ?? 'A');
    out[outIdx++] = (c0 << 2) | (c1 >> 4);
    if (i + 2 < padded.length) {
      out[outIdx++] = ((c1 & 0x0f) << 4) | (c2 >> 2);
    }
    if (i + 3 < padded.length) {
      out[outIdx++] = ((c2 & 0x03) << 6) | c3;
    }
  }
  return out.slice(0, outIdx);
}

// ---------- Map / Set / List ----------

/**
 * Encode a `Map<K, V>`. Dart's wire form is an object when K is `string`,
 * otherwise a list of `{ k, v }` pairs.
 */
export function encodeMap<K, V>(
  map: Map<K, V> | Record<string, V>,
  valueEncoder?: (v: V) => unknown,
): unknown {
  const enc = valueEncoder ?? ((v: V) => v as unknown);
  if (map instanceof Map) {
    const allStringKeys = [...map.keys()].every((k) => typeof k === 'string');
    if (allStringKeys) {
      const out: Record<string, unknown> = {};
      for (const [k, v] of map) out[k as unknown as string] = enc(v);
      return out;
    }
    return [...map].map(([k, v]) => ({ k, v: enc(v) }));
  }
  // Plain object: assumed string-keyed.
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(map)) out[k] = enc(v);
  return out;
}

/**
 * String-keyed sibling of {@link decodeMap} that returns a plain
 * JavaScript object — generated client code for `Map<String, V>`
 * uses this to keep the ergonomic `Record<string, V>` TS type.
 */
export function decodeRecord<V>(
  json: unknown,
  valueDecoder: (raw: unknown) => V,
): Record<string, V> {
  if (json === null || typeof json !== 'object' || Array.isArray(json)) {
    throw new TypeError(
      `Cannot decode Record from ${typeof json}: ${JSON.stringify(json)}`,
    );
  }
  const out: Record<string, V> = {};
  for (const [k, v] of Object.entries(json as Record<string, unknown>)) {
    out[k] = valueDecoder(v);
  }
  return out;
}

export function decodeMap<K, V>(
  json: unknown,
  keyDecoder: (raw: unknown) => K,
  valueDecoder: (raw: unknown) => V,
): Map<K, V> {
  if (Array.isArray(json)) {
    const m = new Map<K, V>();
    for (const entry of json) {
      if (
        entry === null ||
        typeof entry !== 'object' ||
        !('k' in entry) ||
        !('v' in entry)
      ) {
        throw new TypeError(
          `Map entry is not a {k, v} pair: ${JSON.stringify(entry)}`,
        );
      }
      const e = entry as { k: unknown; v: unknown };
      m.set(keyDecoder(e.k), valueDecoder(e.v));
    }
    return m;
  }
  if (json !== null && typeof json === 'object') {
    const m = new Map<K, V>();
    for (const [k, v] of Object.entries(json as Record<string, unknown>)) {
      m.set(keyDecoder(k), valueDecoder(v));
    }
    return m;
  }
  throw new TypeError(
    `Cannot decode Map from ${typeof json}: ${JSON.stringify(json)}`,
  );
}

export function encodeSet<T>(
  set: Set<T>,
  valueEncoder?: (v: T) => unknown,
): unknown[] {
  const enc = valueEncoder ?? ((v: T) => v as unknown);
  return [...set].map(enc);
}

export function decodeSet<T>(
  json: unknown,
  valueDecoder: (raw: unknown) => T,
): Set<T> {
  if (!Array.isArray(json)) {
    throw new TypeError(
      `Cannot decode Set from ${typeof json}: ${JSON.stringify(json)}`,
    );
  }
  return new Set(json.map(valueDecoder));
}

export function encodeList<T>(
  list: T[],
  valueEncoder?: (v: T) => unknown,
): unknown[] {
  const enc = valueEncoder ?? ((v: T) => v as unknown);
  return list.map(enc);
}

export function decodeList<T>(
  json: unknown,
  valueDecoder: (raw: unknown) => T,
): T[] {
  if (!Array.isArray(json)) {
    throw new TypeError(
      `Cannot decode List from ${typeof json}: ${JSON.stringify(json)}`,
    );
  }
  return json.map(valueDecoder);
}

// ---------- SerializationManager ----------

/**
 * Project-specific serialization manager. Each generated `Client`
 * imports a generated `Protocol` class that extends this and overrides
 * `deserialize<T>` with a switch over every model class in the project.
 */
export abstract class SerializationManager {
  /**
   * Decode a JSON value into an instance of `T`. Implemented by the
   * generated `Protocol` class for each project.
   */
  abstract deserialize<T>(json: unknown, t?: new (...args: never[]) => T): T;

  /**
   * Decode a `{ className, data }` envelope into an instance of the
   * named class. Used by the HTTP transport to decode typed exception
   * responses. Returns `undefined` if the className is unknown.
   */
  abstract deserializeByClassName(envelope: unknown): unknown | undefined;

  /**
   * Encode any value to its JSON-encodable wire form. Default behaviour
   * walks primitives + collections + `SerializableModel`s. Override to
   * handle project-specific records.
   */
  encode(value: unknown): unknown {
    if (value === null || value === undefined) return null;
    if (typeof value === 'string') return value;
    if (typeof value === 'number') return value;
    if (typeof value === 'boolean') return value;
    if (typeof value === 'bigint') return encodeBigInt(value);
    if (value instanceof Date) return encodeDateTime(value);
    if (value instanceof Uint8Array) return encodeBytes(value);
    if (value instanceof Set) return encodeSet(value, (v) => this.encode(v));
    if (value instanceof Map) return encodeMap(value, (v) => this.encode(v));
    if (Array.isArray(value)) return value.map((v) => this.encode(v));
    if (typeof value === 'object' && 'toJson' in value &&
        typeof (value as { toJson: unknown }).toJson === 'function') {
      return (value as { toJson: () => unknown }).toJson();
    }
    if (typeof value === 'object') {
      const out: Record<string, unknown> = {};
      for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
        out[k] = this.encode(v);
      }
      return out;
    }
    return value;
  }
}
