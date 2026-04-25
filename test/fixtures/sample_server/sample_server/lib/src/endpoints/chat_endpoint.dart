import 'package:serverpod/serverpod.dart';

/// Endpoint with both an input `Stream<String>` and an output `Stream<String>`.
///
/// Exercises the bidirectional streaming path: client emits messages on an
/// `AsyncIterable`, server echoes each one back (uppercased).
class ChatEndpoint extends Endpoint {
  /// Echo each inbound message back, uppercased.
  Stream<String> echoStream(
    Session session,
    Stream<String> messages,
  ) async* {
    await for (final msg in messages) {
      yield msg.toUpperCase();
    }
  }
}
