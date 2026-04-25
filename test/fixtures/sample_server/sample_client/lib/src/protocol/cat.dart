/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

part of 'animal.dart';

/// A cat. Concrete subclass of the sealed [Animal].
abstract class Cat extends _i1.Animal implements _i2.SerializableModel {
  Cat._({
    required super.name,
    required this.livesRemaining,
    required this.isIndoor,
  });

  factory Cat({
    required String name,
    required int livesRemaining,
    required bool isIndoor,
  }) = _CatImpl;

  factory Cat.fromJson(Map<String, dynamic> jsonSerialization) {
    return Cat(
      name: jsonSerialization['name'] as String,
      livesRemaining: jsonSerialization['livesRemaining'] as int,
      isIndoor: _i2.BoolJsonExtension.fromJson(jsonSerialization['isIndoor']),
    );
  }

  /// Number of lives remaining.
  int livesRemaining;

  /// Whether the cat is an indoor cat.
  bool isIndoor;

  /// Returns a shallow copy of this [Cat]
  /// with some or all fields replaced by the given arguments.
  @override
  @_i2.useResult
  Cat copyWith({
    String? name,
    int? livesRemaining,
    bool? isIndoor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Cat',
      'name': name,
      'livesRemaining': livesRemaining,
      'isIndoor': isIndoor,
    };
  }

  @override
  String toString() {
    return _i2.SerializationManager.encode(this);
  }
}

class _CatImpl extends Cat {
  _CatImpl({
    required String name,
    required int livesRemaining,
    required bool isIndoor,
  }) : super._(
         name: name,
         livesRemaining: livesRemaining,
         isIndoor: isIndoor,
       );

  /// Returns a shallow copy of this [Cat]
  /// with some or all fields replaced by the given arguments.
  @_i2.useResult
  @override
  Cat copyWith({
    String? name,
    int? livesRemaining,
    bool? isIndoor,
  }) {
    return Cat(
      name: name ?? this.name,
      livesRemaining: livesRemaining ?? this.livesRemaining,
      isIndoor: isIndoor ?? this.isIndoor,
    );
  }
}
