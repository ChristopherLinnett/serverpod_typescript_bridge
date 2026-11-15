import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Streaming methods — exercises the WebSocket transport in both directions.
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

  /// Never ends on its own; the caller has to stop listening.
  Stream<int> endless(Session session) async* {
    var i = 0;
    while (true) {
      yield i++;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// A stream of models.
  Stream<UserProfile> profiles(Session session, UserProfile seed, int count) async* {
    for (var i = 0; i < count; i++) {
      yield seed.copyWith(id: seed.id + i);
    }
  }

  /// A stream of a sealed type; each value is one of its subclasses.
  Stream<Animal> animals(Session session) async* {
    yield Dog(name: 'Rex', breed: 'Collie', goodWithKids: true);
    yield Cat(name: 'Tom', livesRemaining: 9, isIndoor: false);
  }

  /// A stream of enums.
  Stream<Priority> priorities(Session session) async* {
    yield Priority.low;
    yield Priority.high;
  }

  /// A stream of lists.
  Stream<List<int>> chunks(Session session, int count) async* {
    for (var i = 1; i <= count; i++) {
      yield List.generate(i, (j) => j);
    }
  }

  /// Yields `count` values, then fails with a typed exception.
  Stream<int> failAfter(Session session, int count) async* {
    for (var i = 1; i <= count; i++) {
      yield i;
    }
    throw NotFoundException(resourceId: '$count', message: 'Ran out');
  }

  /// Input stream with a single `Future` result.
  Future<int> sum(Session session, Stream<int> values) async {
    var total = 0;
    await for (final v in values) {
      total += v;
    }
    return total;
  }

  /// Input stream with no result at all.
  Future<void> drain(Session session, Stream<String> values) async {
    await values.drain<void>();
  }

  /// Models in, models out.
  Stream<Animal> echoAnimals(Session session, Stream<Animal> animals) async* {
    await for (final a in animals) {
      yield a;
    }
  }

  /// Lists as input stream values.
  Stream<String> describeLists(Session session, Stream<List<int>> lists) async* {
    await for (final l in lists) {
      yield 'list:${l.join(',')}';
    }
  }

  /// Enums as input stream values.
  Stream<String> describePriorities(
    Session session,
    Stream<Priority> priorities,
  ) async* {
    await for (final p in priorities) {
      yield 'priority:${p.name}';
    }
  }
}
