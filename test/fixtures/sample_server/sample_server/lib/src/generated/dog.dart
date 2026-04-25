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

/// A dog. Concrete subclass of the sealed [Animal].
abstract class Dog extends _i1.Animal
    implements _i2.SerializableModel, _i2.ProtocolSerialization {
  Dog._({
    required super.name,
    required this.breed,
    required this.goodWithKids,
  });

  factory Dog({
    required String name,
    required String breed,
    required bool goodWithKids,
  }) = _DogImpl;

  factory Dog.fromJson(Map<String, dynamic> jsonSerialization) {
    return Dog(
      name: jsonSerialization['name'] as String,
      breed: jsonSerialization['breed'] as String,
      goodWithKids: _i2.BoolJsonExtension.fromJson(
        jsonSerialization['goodWithKids'],
      ),
    );
  }

  /// Breed name.
  String breed;

  /// Whether the dog is good with children.
  bool goodWithKids;

  /// Returns a shallow copy of this [Dog]
  /// with some or all fields replaced by the given arguments.
  @override
  @_i2.useResult
  Dog copyWith({
    String? name,
    String? breed,
    bool? goodWithKids,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Dog',
      'name': name,
      'breed': breed,
      'goodWithKids': goodWithKids,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Dog',
      'name': name,
      'breed': breed,
      'goodWithKids': goodWithKids,
    };
  }

  @override
  String toString() {
    return _i2.SerializationManager.encode(this);
  }
}

class _DogImpl extends Dog {
  _DogImpl({
    required String name,
    required String breed,
    required bool goodWithKids,
  }) : super._(
         name: name,
         breed: breed,
         goodWithKids: goodWithKids,
       );

  /// Returns a shallow copy of this [Dog]
  /// with some or all fields replaced by the given arguments.
  @_i2.useResult
  @override
  Dog copyWith({
    String? name,
    String? breed,
    bool? goodWithKids,
  }) {
    return Dog(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      goodWithKids: goodWithKids ?? this.goodWithKids,
    );
  }
}
