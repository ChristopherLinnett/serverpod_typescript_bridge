import { describe, expect, it } from 'vitest';
import {
  buildBadRequest,
  buildCloseMethodStream,
  buildMethodStreamException,
  buildMethodStreamMessage,
  buildOpenMethodStream,
  buildPing,
  buildPong,
  classNamed,
  parseEnvelope,
} from '../ws_messages.js';

// The expected frames are what Serverpod 4's own client writes; the
// server closes the connection on a frame it cannot parse.
const to = {
  endpoint: 'chat',
  method: 'echo',
  connectionId: '550e8400-e29b-41d4-a716-446655440000',
};
const address = { en: 'chat', m: 'echo', cid: to.connectionId };

describe('WebSocket frames', () => {
  it('ping and pong carry no data', () => {
    expect(JSON.parse(buildPing())).toEqual({ type: 'ping' });
    expect(JSON.parse(buildPong())).toEqual({ type: 'pong' });
  });

  it('open command: abbreviated keys, args as a JSON string', () => {
    const frame = JSON.parse(
      buildOpenMethodStream(to, {
        args: { name: 'world', count: 3 },
        inputStreams: ['messages'],
        authentication: 'Bearer abc',
      }),
    );
    expect(frame).toEqual({
      type: 'omsc',
      data: {
        ...address,
        args: '{"name":"world","count":3}',
        is: ['messages'],
        auth: 'Bearer abc',
      },
    });
  });

  it('open command omits authentication when there is none', () => {
    for (const authentication of [undefined, null, '']) {
      const frame = JSON.parse(
        buildOpenMethodStream(to, { args: {}, inputStreams: [], authentication }),
      );
      expect(frame.data).toEqual({ ...address, args: '{}', is: [] });
    }
  });

  it('close command always carries a reason', () => {
    expect(JSON.parse(buildCloseMethodStream(to, 'done'))).toEqual({
      type: 'cmsc',
      data: { ...address, cr: 'done' },
    });
    expect(JSON.parse(buildCloseMethodStream(to, 'error', 'messages'))).toEqual({
      type: 'cmsc',
      data: { ...address, p: 'messages', cr: 'error' },
    });
  });

  it('stream message names its parameter and wraps the value', () => {
    const frame = JSON.parse(
      buildMethodStreamMessage(to, 'messages', { className: 'String', data: 'hi' }),
    );
    expect(frame).toEqual({
      type: 'msm',
      data: { ...address, p: 'messages', o: { className: 'String', data: 'hi' } },
    });
  });

  it('stream exception travels under its own key', () => {
    const exception = { className: 'NotFound', data: { __className__: 'NotFound' } };
    expect(JSON.parse(buildMethodStreamException(to, 'messages', exception))).toEqual({
      type: 'msse',
      data: { ...address, p: 'messages', ex: exception },
    });
  });

  it('bad request echoes the frame it could not parse', () => {
    expect(JSON.parse(buildBadRequest('garbage'))).toEqual({
      type: 'brm',
      data: { req: 'garbage' },
    });
  });
});

describe('parseEnvelope', () => {
  it('reads type and data', () => {
    expect(parseEnvelope('{"type":"omsr","data":{"res":"success"}}')).toEqual({
      type: 'omsr',
      data: { res: 'success' },
    });
  });

  it('accepts a frame with no data', () => {
    expect(parseEnvelope('{"type":"pong"}')).toEqual({ type: 'pong' });
  });

  it.each(['not json', '{"foo":"bar"}', '"text"', 'null', '{"type":"x","data":3}'])(
    'returns null for %s',
    (raw) => expect(parseEnvelope(raw)).toBeNull(),
  );
});

describe('classNamed', () => {
  it('uses the declared name for values that carry none', () => {
    expect(classNamed('String', 'x')).toEqual({ className: 'String', data: 'x' });
    expect(classNamed('List<int>', [1])).toEqual({ className: 'List<int>', data: [1] });
    expect(classNamed('Priority', 2)).toEqual({ className: 'Priority', data: 2 });
  });

  it("prefers a model's own class name: the concrete class, not the sealed parent", () => {
    const data = { __className__: 'Cat', name: 'Tom' };
    expect(classNamed('Animal', data)).toEqual({ className: 'Cat', data });
  });

  it('names null', () => {
    expect(classNamed('int', null)).toEqual({ className: 'null', data: null });
  });
});
