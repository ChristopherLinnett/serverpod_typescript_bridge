import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Enum arguments and returns — an enum sent by index and one sent by name
/// are both plain values to a TypeScript caller, so the generated code has
/// to encode each by its declared type.
class EnumsEndpoint extends Endpoint {
  /// Echo a `byIndex` enum.
  Future<Priority> echoPriority(Session session, Priority value) async => value;

  /// Echo a `byName` enum.
  Future<Colour> echoColour(Session session, Colour value) async => value;

  /// Echo a nullable enum.
  Future<Priority?> echoNullablePriority(
    Session session,
    Priority? value,
  ) async => value;

  /// Echo a list of enums.
  Future<List<Priority>> echoPriorities(
    Session session,
    List<Priority> values,
  ) async => values;

  /// Echo a map with enum values.
  Future<Map<String, Colour>> echoColourMap(
    Session session,
    Map<String, Colour> values,
  ) async => values;
}
