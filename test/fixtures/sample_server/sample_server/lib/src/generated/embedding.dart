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
import 'package:serverpod/serverpod.dart' as _is;

/// Vector and geography values.
abstract class Embedding
    implements _is.SerializableModel, _is.ProtocolSerialization {
  Embedding._({
    required this.vec,
    required this.half,
    required this.sparse,
    required this.bits,
    this.point,
  });

  factory Embedding({
    required _is.Vector vec,
    required _is.HalfVector half,
    required _is.SparseVector sparse,
    required _is.Bit bits,
    _is.GeographyPoint? point,
  }) = _EmbeddingImpl;

  factory Embedding.fromJson(Map<String, dynamic> jsonSerialization) {
    return Embedding(
      vec: _is.VectorJsonExtension.fromJson(jsonSerialization['vec']),
      half: _is.HalfVectorJsonExtension.fromJson(jsonSerialization['half']),
      sparse: _is.SparseVectorJsonExtension.fromJson(
        jsonSerialization['sparse'],
      ),
      bits: _is.BitJsonExtension.fromJson(jsonSerialization['bits']),
      point: jsonSerialization['point'] == null
          ? null
          : _is.GeographyPointJsonExtension.fromJson(
              jsonSerialization['point'],
            ),
    );
  }

  /// A dense vector.
  _is.Vector vec;

  /// A half-precision vector.
  _is.HalfVector half;

  /// A sparse vector.
  _is.SparseVector sparse;

  /// A bit vector.
  _is.Bit bits;

  /// A point on the globe.
  _is.GeographyPoint? point;

  /// Returns a shallow copy of this [Embedding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Embedding copyWith({
    _is.Vector? vec,
    _is.HalfVector? half,
    _is.SparseVector? sparse,
    _is.Bit? bits,
    _is.GeographyPoint? point = const _is.$UndefinedGeographyPoint(),
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Embedding',
      'vec': vec.toJson(),
      'half': half.toJson(),
      'sparse': sparse.toJson(),
      'bits': bits.toJson(),
      if (point != null) 'point': point?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Embedding',
      'vec': vec.toJson(),
      'half': half.toJson(),
      'sparse': sparse.toJson(),
      'bits': bits.toJson(),
      if (point != null) 'point': point?.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _EmbeddingImpl extends Embedding {
  _EmbeddingImpl({
    required _is.Vector vec,
    required _is.HalfVector half,
    required _is.SparseVector sparse,
    required _is.Bit bits,
    _is.GeographyPoint? point,
  }) : super._(
         vec: vec,
         half: half,
         sparse: sparse,
         bits: bits,
         point: point,
       );

  /// Returns a shallow copy of this [Embedding]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Embedding copyWith({
    _is.Vector? vec,
    _is.HalfVector? half,
    _is.SparseVector? sparse,
    _is.Bit? bits,
    _is.GeographyPoint? point = const _is.$UndefinedGeographyPoint(),
  }) {
    return Embedding(
      vec: vec ?? this.vec.clone(),
      half: half ?? this.half.clone(),
      sparse: sparse ?? this.sparse.clone(),
      bits: bits ?? this.bits.clone(),
      point: point is _is.UndefinedSentinel ? this.point : point,
    );
  }
}
