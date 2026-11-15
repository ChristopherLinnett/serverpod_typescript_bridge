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
import 'package:sample_server/src/generated/protocol.dart' as _ihzje0n3;
import 'package:serverpod/serverpod.dart' as _is;
import 'animal.dart' as _icwrltez;
import 'colour.dart' as _iy6jkkge;
import 'priority.dart' as _isecxwh3;

/// A user profile.
///
/// Exercises every primitive that the v0.1 generator must support, plus
/// a representative mix of nullable fields. Used as a parity oracle for
/// the model emitter.
class UserProfile implements _is.SerializableModel, _is.ProtocolSerialization {
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
    required this.priority,
    this.favouriteColour,
    this.pet,
    required this.priorityHistory,
  });

  factory UserProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserProfile(
      id: jsonSerialization['id'] as int,
      displayName: jsonSerialization['displayName'] as String,
      birthYear: jsonSerialization['birthYear'] as int?,
      rating: (jsonSerialization['rating'] as num).toDouble(),
      isPublic: _is.BoolJsonExtension.fromJson(jsonSerialization['isPublic']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      membershipDuration: _is.DurationJsonExtension.fromJson(
        jsonSerialization['membershipDuration'],
      ),
      karma: _is.BigIntJsonExtension.fromJson(jsonSerialization['karma']),
      deviceId: _is.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      bio: jsonSerialization['bio'] as String?,
      priority: _isecxwh3.Priority.fromJson(
        (jsonSerialization['priority'] as int),
      ),
      favouriteColour: jsonSerialization['favouriteColour'] == null
          ? null
          : _iy6jkkge.Colour.fromJson(
              (jsonSerialization['favouriteColour'] as String),
            ),
      pet: jsonSerialization['pet'] == null
          ? null
          : _ihzje0n3.Protocol().deserialize<_icwrltez.Animal>(
              jsonSerialization['pet'],
            ),
      priorityHistory: _ihzje0n3.Protocol()
          .deserialize<List<_isecxwh3.Priority>>(
            jsonSerialization['priorityHistory'],
          ),
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
  _is.UuidValue deviceId;

  /// Optional bio markdown blob.
  String? bio;

  /// Account priority — exercises a cross-model enum field reference
  /// (forces the model emitter to emit `import { Priority, PriorityCodec }`).
  _isecxwh3.Priority priority;

  /// Favourite colour — exercises a cross-model enum field reference
  /// with `byName` serialization.
  _iy6jkkge.Colour? favouriteColour;

  /// Pet — exercises a cross-model field referencing a sealed hierarchy
  /// (forces `import { Animal, AnimalBase }`).
  _icwrltez.Animal? pet;

  /// Tags — exercises a generic-wrapped enum reference (`List<Priority>`
  /// should still pull a Priority import).
  List<_isecxwh3.Priority> priorityHistory;

  /// Returns a shallow copy of this [UserProfile]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  UserProfile copyWith({
    int? id,
    String? displayName,
    Object? birthYear = _Undefined,
    double? rating,
    bool? isPublic,
    DateTime? createdAt,
    Duration? membershipDuration,
    BigInt? karma,
    _is.UuidValue? deviceId,
    Object? bio = _Undefined,
    _isecxwh3.Priority? priority,
    Object? favouriteColour = _Undefined,
    Object? pet = _Undefined,
    List<_isecxwh3.Priority>? priorityHistory,
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
      priority: priority ?? this.priority,
      favouriteColour: favouriteColour is _iy6jkkge.Colour?
          ? favouriteColour
          : this.favouriteColour,
      pet: pet is _icwrltez.Animal? ? pet : this.pet?.copyWith(),
      priorityHistory:
          priorityHistory ?? this.priorityHistory.map((e0) => e0).toList(),
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
      'priority': priority.toJson(),
      if (favouriteColour != null) 'favouriteColour': favouriteColour?.toJson(),
      if (pet != null) 'pet': pet?.toJson(),
      'priorityHistory': priorityHistory.toJson(valueToJson: (v) => v.toJson()),
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
      'priority': priority.toJson(),
      if (favouriteColour != null) 'favouriteColour': favouriteColour?.toJson(),
      if (pet != null) 'pet': pet?.toJsonForProtocol(),
      'priorityHistory': priorityHistory.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}
