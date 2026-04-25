import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

/// Endpoint that exchanges custom serializable models in both directions.
///
/// Exercises `fromJson` / `toJson` round-tripping for nested models, including
/// non-sealed inheritance ([UserProfile] / [AdminProfile]) and the sealed
/// [Animal] hierarchy.
class ModelsEndpoint extends Endpoint {
  /// Echo a [UserProfile] back to the caller.
  Future<UserProfile> echoProfile(
    Session session,
    UserProfile profile,
  ) async {
    return profile;
  }

  /// Promote a [UserProfile] to an [AdminProfile] with the given scope.
  ///
  /// Exercises non-sealed inheritance on the return type.
  Future<AdminProfile> promoteToAdmin(
    Session session,
    UserProfile profile,
    String scope,
  ) async {
    return AdminProfile(
      id: profile.id,
      displayName: profile.displayName,
      birthYear: profile.birthYear,
      rating: profile.rating,
      isPublic: profile.isPublic,
      createdAt: profile.createdAt,
      membershipDuration: profile.membershipDuration,
      karma: profile.karma,
      deviceId: profile.deviceId,
      bio: profile.bio,
      scope: scope,
    );
  }

  /// Echo a sealed [Animal] back to the caller. Exercises polymorphism via
  /// `__className__` dispatch.
  Future<Animal> echoAnimal(Session session, Animal animal) async => animal;

  /// Throws a typed [NotFoundException] so the runtime's typed-exception
  /// decoder can be exercised.
  Future<UserProfile> findOrThrow(Session session, int id) async {
    throw NotFoundException(
      resourceId: id.toString(),
      message: 'No user with id=$id',
    );
  }
}
