import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Endpoint where every parameter and return is nullable. Exercises the
/// `omit-on-null` `toJson` shape and the optional-arg generator path.
class NullablesEndpoint extends Endpoint {
  /// All-nullable primitive round-trip.
  Future<int?> nullableInt(Session session, int? value) async => value;

  /// All-nullable string round-trip.
  Future<String?> nullableString(Session session, String? value) async => value;

  /// Nullable model round-trip.
  Future<UserProfile?> nullableProfile(
    Session session,
    UserProfile? profile,
  ) async {
    return profile;
  }

  /// Nullable list round-trip.
  Future<List<int>?> nullableList(Session session, List<int>? values) async =>
      values;
}
