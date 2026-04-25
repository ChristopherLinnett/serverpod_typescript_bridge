import 'package:serverpod/serverpod.dart';

/// Endpoint with an output-only stream — exercises the WebSocket return path.
class StreamingEndpoint extends Endpoint {
  /// Yield `count` integer values, in order, separated by 10 ms.
  ///
  /// Used by the streaming runtime tests.
  Stream<int> countTo(Session session, int count) async* {
    for (var i = 1; i <= count; i++) {
      yield i;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }
}
