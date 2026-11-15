import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Parameter shapes: named, optional positional, and typed arguments that
/// need encoding on the way in.
class ParamsEndpoint extends Endpoint {
  /// Required and optional named parameters.
  Future<String> named(
    Session session,
    String a, {
    required int b,
    String? c,
  }) async => '$a|$b|${c ?? 'none'}';

  /// Optional positional parameter.
  Future<String> optional(Session session, String a, [int? b]) async =>
      '$a|${b ?? 'none'}';

  /// Typed arguments: each needs its own wire encoding.
  Future<String> typed(
    Session session,
    DateTime at,
    Duration length,
    BigInt big,
    Set<int> ids,
    Map<int, String> labels,
    List<UserProfile> profiles,
  ) async =>
      '${at.toUtc().toIso8601String()}|${length.inMilliseconds}|$big|'
      '${(ids.toList()..sort()).join(',')}|'
      '${labels.entries.map((e) => '${e.key}=${e.value}').join(',')}|'
      '${profiles.map((p) => p.displayName).join(',')}';

  /// A model that carries defaults; the server fills what the caller omits.
  Future<Settings> echoSettings(Session session, Settings settings) async =>
      settings;

  /// A model built by the server from its defaults alone.
  Future<Settings> defaultSettings(Session session) async => Settings();

  /// Vector and geography values.
  Future<Embedding> echoEmbedding(Session session, Embedding value) async =>
      value;

  /// Throws an exception that extends another.
  Future<void> throwQuota(Session session) async {
    throw QuotaException(message: 'Over quota', limit: 3);
  }

  /// Returns a subclass where its parent is declared.
  Future<UserProfile> asParent(Session session, AdminProfile admin) async =>
      admin;

  /// Echo a `Uri`.
  Future<Uri> echoUri(Session session, Uri value) async => value;
}
