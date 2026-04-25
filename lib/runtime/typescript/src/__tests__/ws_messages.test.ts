import { describe, expect, it } from 'vitest';
import { buildEnvelope, parseEnvelope } from '../ws_messages.js';

describe('WebSocket envelope', () => {
  it('round-trips a typed envelope', () => {
    const json = buildEnvelope('open_method_stream_command', {
      endpoint: 'e',
      method: 'm',
      connectionId: 'c0',
      args: '{}',
      inputStreams: [],
    });
    const parsed = parseEnvelope(json);
    expect(parsed?.type).toBe('open_method_stream_command');
    expect((parsed?.data as { endpoint: string }).endpoint).toBe('e');
  });

  it('returns null on malformed JSON', () => {
    expect(parseEnvelope('not json')).toBeNull();
  });

  it('returns null on JSON without a type field', () => {
    expect(parseEnvelope('{"foo":"bar"}')).toBeNull();
  });

  it('encodes args as a double-encoded JSON string per Dart contract', () => {
    const env = buildEnvelope('open_method_stream_command', {
      args: JSON.stringify({ name: 'world', count: 3 }),
    });
    const parsed = parseEnvelope(env)!;
    const data = parsed.data as { args: string };
    // The args field is a STRING containing JSON, not a nested object.
    expect(typeof data.args).toBe('string');
    expect(JSON.parse(data.args)).toEqual({ name: 'world', count: 3 });
  });
});
