import { describe, expect, it } from 'vitest';
import { deferredIterable, streamResult } from '../ws_transport.js';

async function* numbers(count: number): AsyncGenerator<number> {
  for (let i = 1; i <= count; i++) yield i;
}

describe('deferredIterable', () => {
  it('does not open its source until it is iterated', async () => {
    let opened = 0;
    const iterable = deferredIterable(async () => {
      opened++;
      return numbers(2);
    });
    expect(opened).toBe(0);
    const seen: number[] = [];
    for await (const value of iterable) seen.push(value);
    expect(seen).toEqual([1, 2]);
    expect(opened).toBe(1);
  });

  it('surfaces a failure to open on the first read', async () => {
    const iterable = deferredIterable<number>(async () => {
      throw new Error('refused');
    });
    await expect(iterable[Symbol.asyncIterator]().next()).rejects.toThrow('refused');
  });

  it('breaking out closes the source', async () => {
    let closed = false;
    const source: AsyncIterable<number> = {
      [Symbol.asyncIterator]: () => ({
        next: async () => ({ value: 1, done: false }),
        return: async () => {
          closed = true;
          return { value: undefined, done: true };
        },
      }),
    };
    for await (const _ of deferredIterable(async () => source)) break;
    expect(closed).toBe(true);
  });

  it('returning before the first read opens nothing', async () => {
    let opened = false;
    const iterator = deferredIterable(async () => {
      opened = true;
      return numbers(1);
    })[Symbol.asyncIterator]();
    await iterator.return?.();
    expect(opened).toBe(false);
  });
});

describe('streamResult', () => {
  it('resolves to the first value', async () => {
    expect(await streamResult(numbers(3))).toBe(1);
  });

  it('resolves to undefined for a stream that ends without one', async () => {
    expect(await streamResult(numbers(0))).toBeUndefined();
  });

  it('rejects when the stream fails', async () => {
    const failing = deferredIterable<number>(async () => {
      throw new Error('boom');
    });
    await expect(streamResult(failing)).rejects.toThrow('boom');
  });
});
