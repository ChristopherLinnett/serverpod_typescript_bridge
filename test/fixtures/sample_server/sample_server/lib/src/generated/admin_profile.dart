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
import 'protocol.dart' as _i1;
import 'package:serverpod/serverpod.dart' as _i2;
import 'priority.dart' as _i3;
import 'colour.dart' as _i4;
import 'animal.dart' as _i5;
import 'package:sample_server/src/generated/protocol.dart' as _i6;

/// Profile for an administrator.
///
/// Exercises non-sealed inheritance — `AdminProfile` extends [UserProfile]
/// and adds a privilege scope.
abstract class AdminProfile extends _i1.UserProfile
    implements _i2.SerializableModel, _i2.ProtocolSerialization {
  AdminProfile._({
    required super.id,
    required super.displayName,
    super.birthYear,
    required super.rating,
    required super.isPublic,
    required super.createdAt,
    required super.membershipDuration,
    required super.karma,
    required super.deviceId,
    super.bio,
    required super.priority,
    super.favouriteColour,
    super.pet,
    required super.priorityHistory,
    required this.scope,
  });

  factory AdminProfile({
    required int id,
    required String displayName,
    int? birthYear,
    required double rating,
    required bool isPublic,
    required DateTime createdAt,
    required Duration membershipDuration,
    required BigInt karma,
    required _i2.UuidValue deviceId,
    String? bio,
    required _i3.Priority priority,
    _i4.Colour? favouriteColour,
    _i5.Animal? pet,
    required List<_i3.Priority> priorityHistory,
    required String scope,
  }) = _AdminProfileImpl;

  factory AdminProfile.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminProfile(
      id: jsonSerialization['id'] as int,
      displayName: jsonSerialization['displayName'] as String,
      birthYear: jsonSerialization['birthYear'] as int?,
      rating: (jsonSerialization['rating'] as num).toDouble(),
      isPublic: _i2.BoolJsonExtension.fromJson(jsonSerialization['isPublic']),
      createdAt: _i2.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      membershipDuration: _i2.DurationJsonExtension.fromJson(
        jsonSerialization['membershipDuration'],
      ),
      karma: _i2.BigIntJsonExtension.fromJson(jsonSerialization['karma']),
      deviceId: _i2.UuidValueJsonExtension.fromJson(
        jsonSerialization['deviceId'],
      ),
      bio: jsonSerialization['bio'] as String?,
      priority: _i3.Priority.fromJson((jsonSerialization['priority'] as int)),
      favouriteColour: jsonSerialization['favouriteColour'] == null
          ? null
          : _i4.Colour.fromJson(
              (jsonSerialization['favouriteColour'] as String),
            ),
      pet: jsonSerialization['pet'] == null
          ? null
          : _i6.Protocol().deserialize<_i5.Animal>(jsonSerialization['pet']),
      priorityHistory: _i6.Protocol().deserialize<List<_i3.Priority>>(
        jsonSerialization['priorityHistory'],
      ),
      scope: jsonSerialization['scope'] as String,
    );
  }

  /// Privilege scope for this administrator (e.g. `superuser`).
  String scope;

  /// Returns a shallow copy of this [AdminProfile]
  /// with some or all fields replaced by the given arguments.
  @override
  @_i2.useResult
  AdminProfile copyWith({
    int? id,
    String? displayName,
    Object? birthYear,
    double? rating,
    bool? isPublic,
    DateTime? createdAt,
    Duration? membershipDuration,
    BigInt? karma,
    _i2.UuidValue? deviceId,
    Object? bio,
    _i3.Priority? priority,
    Object? favouriteColour,
    Object? pet,
    List<_i3.Priority>? priorityHistory,
    String? scope,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminProfile',
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
      'scope': scope,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminProfile',
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
      'scope': scope,
    };
  }

  @override
  String toString() {
    return _i2.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminProfileImpl extends AdminProfile {
  _AdminProfileImpl({
    required int id,
    required String displayName,
    int? birthYear,
    required double rating,
    required bool isPublic,
    required DateTime createdAt,
    required Duration membershipDuration,
    required BigInt karma,
    required _i2.UuidValue deviceId,
    String? bio,
    required _i3.Priority priority,
    _i4.Colour? favouriteColour,
    _i5.Animal? pet,
    required List<_i3.Priority> priorityHistory,
    required String scope,
  }) : super._(
         id: id,
         displayName: displayName,
         birthYear: birthYear,
         rating: rating,
         isPublic: isPublic,
         createdAt: createdAt,
         membershipDuration: membershipDuration,
         karma: karma,
         deviceId: deviceId,
         bio: bio,
         priority: priority,
         favouriteColour: favouriteColour,
         pet: pet,
         priorityHistory: priorityHistory,
         scope: scope,
       );

  /// Returns a shallow copy of this [AdminProfile]
  /// with some or all fields replaced by the given arguments.
  @_i2.useResult
  @override
  AdminProfile copyWith({
    int? id,
    String? displayName,
    Object? birthYear = _Undefined,
    double? rating,
    bool? isPublic,
    DateTime? createdAt,
    Duration? membershipDuration,
    BigInt? karma,
    _i2.UuidValue? deviceId,
    Object? bio = _Undefined,
    _i3.Priority? priority,
    Object? favouriteColour = _Undefined,
    Object? pet = _Undefined,
    List<_i3.Priority>? priorityHistory,
    String? scope,
  }) {
    return AdminProfile(
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
      favouriteColour: favouriteColour is _i4.Colour?
          ? favouriteColour
          : this.favouriteColour,
      pet: pet is _i5.Animal? ? pet : this.pet?.copyWith(),
      priorityHistory:
          priorityHistory ?? this.priorityHistory.map((e0) => e0).toList(),
      scope: scope ?? this.scope,
    );
  }
}
