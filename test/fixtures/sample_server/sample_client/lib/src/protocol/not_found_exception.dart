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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// Thrown when a requested resource cannot be located.
///
/// Round-trips as a typed `SerializableException` over the wire. Exercises the
/// typed-exception decoding path in the runtime.
abstract class NotFoundException
    implements _i1.SerializableException, _i1.SerializableModel {
  NotFoundException._({
    required this.resourceId,
    required this.message,
  });

  factory NotFoundException({
    required String resourceId,
    required String message,
  }) = _NotFoundExceptionImpl;

  factory NotFoundException.fromJson(Map<String, dynamic> jsonSerialization) {
    return NotFoundException(
      resourceId: jsonSerialization['resourceId'] as String,
      message: jsonSerialization['message'] as String,
    );
  }

  /// Identifier of the missing resource.
  String resourceId;

  /// Human-readable message.
  String message;

  /// Returns a shallow copy of this [NotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  NotFoundException copyWith({
    String? resourceId,
    String? message,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'NotFoundException',
      'resourceId': resourceId,
      'message': message,
    };
  }

  @override
  String toString() {
    return 'NotFoundException(resourceId: $resourceId, message: $message)';
  }
}

class _NotFoundExceptionImpl extends NotFoundException {
  _NotFoundExceptionImpl({
    required String resourceId,
    required String message,
  }) : super._(
         resourceId: resourceId,
         message: message,
       );

  /// Returns a shallow copy of this [NotFoundException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  NotFoundException copyWith({
    String? resourceId,
    String? message,
  }) {
    return NotFoundException(
      resourceId: resourceId ?? this.resourceId,
      message: message ?? this.message,
    );
  }
}
