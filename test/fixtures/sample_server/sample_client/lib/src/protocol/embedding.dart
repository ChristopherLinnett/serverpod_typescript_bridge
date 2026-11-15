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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

/// Vector and geography values.
abstract class Embedding
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Embedding._({
    required this.vec,
    required this.half,
    required this.sparse,
    required this.bits,
    this.point,
  });

  factory Embedding({
    required _isc.Vector vec,
    required _isc.HalfVector half,
    required _isc.SparseVector sparse,
    required _isc.Bit bits,
    _isc.GeographyPoint? point,
  }) = _EmbeddingImpl;

  factory Embedding.fromJson(Map<String, dynamic> jsonSerialization) {
    return Embedding(
      vec: _isc.VectorJsonExtension.fromJson(jsonSerialization['vec']),
      half: _isc.HalfVectorJsonExtension.fromJson(jsonSerialization['half']),
      sparse: _isc.SparseVectorJsonExtension.fromJson(
        jsonSerialization['sparse'],
      ),
      bits: _isc.BitJsonExtension.fromJson(jsonSerialization['bits']),
      point: jsonSerialization['point'] == null
          ? null
          : _isc.GeographyPointJsonExtension.fromJson(
              jsonSerialization['point'],
            ),
    );
  }

  /// A dense vector.
  _isc.Vector vec;

  /// A half-precision vector.
  _isc.HalfVector half;

  /// A sparse vector.
  _isc.SparseVector sparse;

  /// A bit vector.
  _isc.Bit bits;

  /// A point on the globe.
  _isc.GeographyPoint? point;

  /// Returns a shallow copy of this [Embedding]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Embedding copyWith({
    _isc.Vector? vec,
    _isc.HalfVector? half,
    _isc.SparseVector? sparse,
    _isc.Bit? bits,
    _isc.GeographyPoint? point = const _isc.$UndefinedGeographyPoint(),
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
    return _isc.SerializationManager.encode(this);
  }
}

class _EmbeddingImpl extends Embedding {
  _EmbeddingImpl({
    required _isc.Vector vec,
    required _isc.HalfVector half,
    required _isc.SparseVector sparse,
    required _isc.Bit bits,
    _isc.GeographyPoint? point,
  }) : super._(
         vec: vec,
         half: half,
         sparse: sparse,
         bits: bits,
         point: point,
       );

  /// Returns a shallow copy of this [Embedding]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Embedding copyWith({
    _isc.Vector? vec,
    _isc.HalfVector? half,
    _isc.SparseVector? sparse,
    _isc.Bit? bits,
    _isc.GeographyPoint? point = const _isc.$UndefinedGeographyPoint(),
  }) {
    return Embedding(
      vec: vec ?? this.vec.clone(),
      half: half ?? this.half.clone(),
      sparse: sparse ?? this.sparse.clone(),
      bits: bits ?? this.bits.clone(),
      point: point is _isc.UndefinedSentinel ? this.point : point,
    );
  }
}
