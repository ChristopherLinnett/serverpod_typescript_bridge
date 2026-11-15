import { describe, expect, it } from 'vitest';
import {
  bareClassName,
  decodeBigInt,
  decodeBool,
  decodeBytes,
  decodeDateTime,
  decodeDuration,
  decodeList,
  decodeMap,
  decodeSet,
  decodeVector,
  encodeBigInt,
  encodeBytes,
  encodeVector,
  ModelRegistry,
  randomUuidV4,
  randomUuidV7,
  encodeDateTime,
  encodeDuration,
  encodeList,
  encodeMap,
  encodeSet,
  SerializationManager,
} from '../serialization.js';

describe('DateTime', () => {
  it('encodes to UTC ISO-8601', () => {
    const d = new Date(Date.UTC(2025, 5, 15, 12, 30, 45, 123));
    expect(encodeDateTime(d)).toBe('2025-06-15T12:30:45.123Z');
  });

  it('decodes from ISO-8601 string', () => {
    const d = decodeDateTime('2025-06-15T12:30:45.123Z');
    expect(d.getTime()).toBe(Date.UTC(2025, 5, 15, 12, 30, 45, 123));
  });

  it('decodes from epoch milliseconds (Dart compat)', () => {
    const epoch = Date.UTC(2025, 5, 15, 12, 30, 45);
    expect(decodeDateTime(epoch).getTime()).toBe(epoch);
  });

  it('round-trips', () => {
    const d = new Date(Date.UTC(2024, 0, 1, 0, 0, 0));
    expect(decodeDateTime(encodeDateTime(d)).getTime()).toBe(d.getTime());
  });
});

describe('Duration', () => {
  it('encodes a positive integer ms count', () => {
    expect(encodeDuration(1500)).toBe(1500);
  });

  it('throws on a non-integer ms count', () => {
    expect(() => encodeDuration(1.5)).toThrow(TypeError);
  });

  it('decodes from integer', () => {
    expect(decodeDuration(2500)).toBe(2500);
  });

  it('decodes from string (Dart sometimes encodes as JSON-string)', () => {
    expect(decodeDuration('300')).toBe(300);
  });

  it('rejects garbage input', () => {
    expect(() => decodeDuration({})).toThrow(TypeError);
  });
});

describe('BigInt', () => {
  it('encodes to a string', () => {
    expect(encodeBigInt(9007199254740993n)).toBe('9007199254740993');
  });

  it('decodes from a string', () => {
    expect(decodeBigInt('9007199254740993')).toBe(9007199254740993n);
  });

  it('round-trips a value larger than Number.MAX_SAFE_INTEGER', () => {
    const big = 12345678901234567890n;
    expect(decodeBigInt(encodeBigInt(big))).toBe(big);
  });
});

describe('bool', () => {
  it.each([
    [true, true],
    [false, false],
    [1, true],
    [0, false],
  ])('decodes %s as %s', (input, expected) => {
    expect(decodeBool(input)).toBe(expected);
  });

  it('rejects garbage', () => {
    expect(() => decodeBool('yes')).toThrow(TypeError);
  });
});

describe('Bytes (ByteData)', () => {
  it("encodes as Serverpod's decode('<base64>', 'base64') literal", () => {
    const bytes = new Uint8Array([0x68, 0x65, 0x6c, 0x6c, 0x6f]); // "hello"
    expect(encodeBytes(bytes)).toBe("decode('aGVsbG8=', 'base64')");
  });

  it('round-trips', () => {
    const bytes = new Uint8Array([1, 2, 3, 4, 5]);
    const decoded = decodeBytes(encodeBytes(bytes));
    expect(Array.from(decoded)).toEqual([1, 2, 3, 4, 5]);
  });

  it('handles empty input', () => {
    const empty = new Uint8Array(0);
    expect(encodeBytes(empty)).toBe("decode('', 'base64')");
    expect(decodeBytes(encodeBytes(empty)).length).toBe(0);
  });

  it.each([
    [[0x4d], 'TQ=='], // single byte
    [[0x4d, 0x61], 'TWE='], // two bytes
    [[0x4d, 0x61, 0x6e], 'TWFu'], // three bytes (no padding)
  ])('matches RFC 4648 padding for %j → %s', (bytes, expected) => {
    expect(encodeBytes(new Uint8Array(bytes))).toBe(
      `decode('${expected}', 'base64')`,
    );
  });

  it('decodes bare base64 as well as the wrapped literal', () => {
    expect(Array.from(decodeBytes('TWFu'))).toEqual([0x4d, 0x61, 0x6e]);
    expect(Array.from(decodeBytes("decode('TWFu', 'base64')"))).toEqual([
      0x4d, 0x61, 0x6e,
    ]);
  });
});

describe('Vector', () => {
  it('writes every component with a decimal point', () => {
    // A whole number without one reaches Dart as an int, which
    // Serverpod's vector decoder refuses.
    expect(encodeVector([1, 2.5, -3, 0])).toBe('[1.0,2.5,-3.0,0.0]');
  });

  it('encodes an empty vector', () => {
    expect(encodeVector([])).toBe('[]');
  });

  it('decodes a list and the text form', () => {
    expect(decodeVector([1, 2.5])).toEqual([1, 2.5]);
    expect(decodeVector('[1.0,2.5]')).toEqual([1, 2.5]);
  });

  it('rejects anything else', () => {
    expect(() => decodeVector(5)).toThrow(TypeError);
  });
});

describe('UUIDs', () => {
  const shape = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/;

  it('randomUuidV4 is a version 4, variant 1 UUID', () => {
    const uuid = randomUuidV4();
    expect(uuid).toMatch(shape);
    expect(uuid[14]).toBe('4');
    expect('89ab').toContain(uuid[19]);
    expect(randomUuidV4()).not.toBe(uuid);
  });

  it('randomUuidV7 is a version 7 UUID that starts with the current time', () => {
    const before = Date.now();
    const uuid = randomUuidV7();
    const after = Date.now();
    expect(uuid).toMatch(shape);
    expect(uuid[14]).toBe('7');
    const ms = Number.parseInt(uuid.slice(0, 8) + uuid.slice(9, 13), 16);
    expect(ms).toBeGreaterThanOrEqual(before);
    expect(ms).toBeLessThanOrEqual(after);
  });
});

describe('ModelRegistry', () => {
  class Parent {
    constructor(readonly kind: string) {}
  }
  const registry = () => {
    const models = new ModelRegistry();
    models.register('Parent', () => new Parent('parent'));
    models.register('Child', () => new Parent('child'));
    return models;
  };

  it('decodes as the declared class when the object names none', () => {
    expect(registry().decode<Parent>('Parent', {}).kind).toBe('parent');
  });

  it('decodes as the class the object names, over the declared one', () => {
    const decoded = registry().decode<Parent>('Parent', { __className__: 'Child' });
    expect(decoded.kind).toBe('child');
  });

  it('ignores a module prefix on the class name', () => {
    const decoded = registry().decode<Parent>('Parent', {
      __className__: 'some_module.Child',
    });
    expect(decoded.kind).toBe('child');
  });

  it('falls back to the declared class for a name it does not know', () => {
    const decoded = registry().decode<Parent>('Parent', { __className__: 'Newer' });
    expect(decoded.kind).toBe('parent');
  });

  it('throws when neither the named nor the declared class is known', () => {
    // A sealed parent is never registered: only the name on the wire
    // can say which subclass to build.
    expect(() => registry().decode('Sealed', {})).toThrow(/no __className__/);
    expect(() => registry().decode('Sealed', { __className__: 'Nope' })).toThrow(
      /unknown class "Nope"/,
    );
  });

  it('refuses a value that is not an object', () => {
    for (const value of [null, 'x', 3, [1]]) {
      expect(() => registry().decode('Parent', value)).toThrow(TypeError);
    }
  });
});

describe('bareClassName', () => {
  it('strips a module prefix', () => {
    expect(bareClassName('serverpod_auth_core.AuthUser')).toBe('AuthUser');
    expect(bareClassName('AuthUser')).toBe('AuthUser');
  });
});

describe('List', () => {
  it('encodes via the per-element encoder', () => {
    expect(encodeList([1n, 2n, 3n], encodeBigInt)).toEqual(['1', '2', '3']);
  });

  it('decodes via the per-element decoder', () => {
    expect(decodeList(['1', '2', '3'], decodeBigInt)).toEqual([1n, 2n, 3n]);
  });
});

describe('Set', () => {
  it('encodes to an array', () => {
    expect(encodeSet(new Set(['a', 'b', 'c']))).toEqual(['a', 'b', 'c']);
  });

  it('decodes from an array', () => {
    expect(decodeSet(['x', 'y'], (v) => v as string)).toEqual(
      new Set(['x', 'y']),
    );
  });
});

describe('Map', () => {
  it('encodes a Map<string,V> as a JSON object', () => {
    const m = new Map<string, number>([['a', 1], ['b', 2]]);
    expect(encodeMap(m)).toEqual({ a: 1, b: 2 });
  });

  it('encodes a plain Record as a JSON object', () => {
    expect(encodeMap({ a: 1, b: 2 })).toEqual({ a: 1, b: 2 });
  });

  it('encodes a Map<int,V> as a list of {k,v} pairs', () => {
    const m = new Map<number, string>([[1, 'a'], [2, 'b']]);
    expect(encodeMap(m)).toEqual([
      { k: 1, v: 'a' },
      { k: 2, v: 'b' },
    ]);
  });

  it('decodes a JSON object as a Map<string,V>', () => {
    const m = decodeMap(
      { a: 1, b: 2 },
      (k) => k as string,
      (v) => v as number,
    );
    expect(m).toEqual(new Map([['a', 1], ['b', 2]]));
  });

  it('decodes a list of pairs as a Map<K,V>', () => {
    const m = decodeMap(
      [{ k: 1, v: 'a' }, { k: 2, v: 'b' }],
      (k) => k as number,
      (v) => v as string,
    );
    expect(m).toEqual(new Map([[1, 'a'], [2, 'b']]));
  });
});

describe('SerializationManager.encode (default impl)', () => {
  // Minimal subclass with stub deserialize methods so we can instantiate.
  class TestProtocol extends SerializationManager {
    deserialize<T>(json: unknown): T {
      return json as T;
    }
    deserializeByClassName(): unknown {
      return undefined;
    }
  }

  const proto = new TestProtocol();

  it('passes primitives through', () => {
    expect(proto.encode(42)).toBe(42);
    expect(proto.encode('hello')).toBe('hello');
    expect(proto.encode(true)).toBe(true);
  });

  it('encodes null/undefined as null', () => {
    expect(proto.encode(null)).toBe(null);
    expect(proto.encode(undefined)).toBe(null);
  });

  it('encodes Date / BigInt / Uint8Array via the wire helpers', () => {
    expect(proto.encode(new Date(0))).toBe('1970-01-01T00:00:00.000Z');
    expect(proto.encode(123n)).toBe('123');
    expect(proto.encode(new Uint8Array([0x68, 0x69]))).toBe("decode('aGk=', 'base64')");
  });

  it('encodes nested collections recursively', () => {
    const nested = {
      ids: [1n, 2n],
      tags: new Set(['a', 'b']),
      attrs: new Map<string, string>([['k', 'v']]),
    };
    expect(proto.encode(nested)).toEqual({
      ids: ['1', '2'],
      tags: ['a', 'b'],
      attrs: { k: 'v' },
    });
  });

  it('calls toJson() on SerializableModel-like objects', () => {
    const obj = {
      toJson: () => ({ __className__: 'X', n: 1 }),
    };
    expect(proto.encode(obj)).toEqual({ __className__: 'X', n: 1 });
  });
});
