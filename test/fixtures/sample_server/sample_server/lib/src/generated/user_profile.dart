/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;

/// A user profile.
///
/// Exercises every primitive that the v0.1 generator must support, plus
/// a representative mix of nullable fields. Used as a parity oracle for
/// the model emitter.
class UserProfile implements _i1.SerializableModel, _i1.ProtocolSerialization {
  UserProfile({
    required this.id,
    required this.displayName,
    this.birthYear,
    required this.rating,
    required this.isPublic,
    required this.createdAt,
    required this.membershipDuration,
    required this.karma,
    required this.deviceId,
    this.bio,
  });

  factory UserProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfile(
      id: jsonSerialization['id'] as int,
      displayName: jsonSerialization['displayName'] as String,
      birthYear: jsonSerialization['birthYear'] as int?,
      rating: (jsonSerialization['rating'] as num).toDouble(),
      isPublic: _i1.BoolJsonExtension.fromJson(jsonSerialization['isPublic']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      membershipDuration: _i1.DurationJsonExtension.fromJson(
        jsonSerialization['membershipDuration'],
      ),
      karma: _i1.BigIntJsonExtension.fromJson(jsonSerialization['karma']),
      deviceId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      bio: jsonSerialization['bio'] as String?,
    );
  }

  /// Stable user identifier.
  int id;

  /// Display name shown on the profile page.
  String displayName;

  /// Year of birth, optional.
  int? birthYear;

  /// Average rating, in `[0.0, 5.0]`.
  double rating;

  /// Whether the profile is publicly visible.
  bool isPublic;

  /// When the profile was created (UTC).
  DateTime createdAt;

  /// How long the user has been a member.
  Duration membershipDuration;

  /// Lifetime karma points (can grow large).
  BigInt karma;

  /// Stable cross-device identifier.
  _i1.UuidValue deviceId;

  /// Optional bio markdown blob.
  String? bio;

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserProfile copyWith({
    int? id,
    String? displayName,
    Object? birthYear = _Undefined,
    double? rating,
    bool? isPublic,
    DateTime? createdAt,
    Duration? membershipDuration,
    BigInt? karma,
    _i1.UuidValue? deviceId,
    Object? bio = _Undefined,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      birthYear: birthYear is int? ? birthYear : this.birthYear,
      rating: rating ?? this.rating,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      membershipDuration: membershipDuration ?? this.membershipDuration,
      karma: karma ?? this.karma,
      deviceId: deviceId ?? this.deviceId,
      bio: bio is String? ? bio : this.bio,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserProfile',
      'id': id,
      'displayName': displayName,
      if (birthYear != null) 'birthYear': birthYear,
      'rating': rating,
      'isPublic': isPublic,
      'createdAt': createdAt.toJson(),
      'membershipDuration': membershipDuration.toJson(),
      'karma': karma.toJson(),
      'deviceId': deviceId.toJson(),
      if (bio != null) 'bio': bio,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'UserProfile',
      'id': id,
      'displayName': displayName,
      if (birthYear != null) 'birthYear': birthYear,
      'rating': rating,
      'isPublic': isPublic,
      'createdAt': createdAt.toJson(),
      'membershipDuration': membershipDuration.toJson(),
      'karma': karma.toJson(),
      'deviceId': deviceId.toJson(),
      if (bio != null) 'bio': bio,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}
