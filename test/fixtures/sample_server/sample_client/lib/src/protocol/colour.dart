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

/// A colour. Uses `byName` serialization (wire form is the value's name string).
enum Colour implements _i1.SerializableModel {
  /// Red.
  red,

  /// Green.
  green,

  /// Blue.
  blue;

  static Colour fromJson(String name) {
    switch (name) {
      case 'red':
        return Colour.red;
      case 'green':
        return Colour.green;
      case 'blue':
        return Colour.blue;
      default:
        throw ArgumentError('Value "$name" cannot be converted to "Colour"');
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
