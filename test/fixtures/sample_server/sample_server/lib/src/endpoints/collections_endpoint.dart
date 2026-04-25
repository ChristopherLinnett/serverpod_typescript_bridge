import 'package:serverpod/serverpod.dart';

/// Endpoint that exercises every collection shape the wire format supports.
///
/// Includes `Map<int, _>` to exercise the non-string-key wire form
/// (serialized as a list of `{k, v}` pairs).
class CollectionsEndpoint extends Endpoint {
  /// Round-trip a `List<int>`.
  Future<List<int>> echoIntList(Session session, List<int> values) async =>
      values;

  /// Round-trip a `Set<String>` (serialized as a JSON array).
  Future<Set<String>> echoStringSet(
    Session session,
    Set<String> values,
  ) async {
    return values;
  }

  /// Round-trip a `Map<String, int>` (serialized as a JSON object).
  Future<Map<String, int>> echoStringIntMap(
    Session session,
    Map<String, int> entries,
  ) async {
    return entries;
  }

  /// Round-trip a `Map<int, String>` — non-string keys serialize as a list
  /// of `{k, v}` pairs.
  Future<Map<int, String>> echoIntStringMap(
    Session session,
    Map<int, String> entries,
  ) async {
    return entries;
  }
}
