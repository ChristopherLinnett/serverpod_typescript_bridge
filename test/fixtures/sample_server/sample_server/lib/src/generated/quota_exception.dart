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
import 'protocol.dart' as _il2as5qe;

/// Thrown when a caller exceeds a limit. Extends [AppException].
abstract class QuotaException extends _il2as5qe.AppException
    implements
        _is.SerializableException,
        _is.SerializableModel,
        _is.ProtocolSerialization {
  QuotaException._({
    required super.message,
    required this.limit,
  });

  factory QuotaException({
    required String message,
    required int limit,
  }) = _QuotaExceptionImpl;

  factory QuotaException.fromJson(Map<String, dynamic> jsonSerialization) {
    return QuotaException(
      message: jsonSerialization['message'] as String,
      limit: jsonSerialization['limit'] as int,
    );
  }

  /// The limit that was exceeded.
  int limit;

  /// Returns a shallow copy of this [QuotaException]
  /// with some or all fields replaced by the given arguments.
  @override
  @_is.useResult
  QuotaException copyWith({
    String? message,
    int? limit,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'QuotaException',
      'message': message,
      'limit': limit,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'QuotaException',
      'message': message,
      'limit': limit,
    };
  }

  @override
  String toString() {
    return 'QuotaException(message: $message, limit: $limit)';
  }
}

class _QuotaExceptionImpl extends QuotaException {
  _QuotaExceptionImpl({
    required String message,
    required int limit,
  }) : super._(
         message: message,
         limit: limit,
       );

  /// Returns a shallow copy of this [QuotaException]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  QuotaException copyWith({
    String? message,
    int? limit,
  }) {
    return QuotaException(
      message: message ?? this.message,
      limit: limit ?? this.limit,
    );
  }
}
