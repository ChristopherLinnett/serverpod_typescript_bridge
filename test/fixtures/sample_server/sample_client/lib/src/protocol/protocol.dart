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
import 'admin_profile.dart' as _i2;
import 'animal.dart' as _i3;
import 'colour.dart' as _i4;
import 'not_found_exception.dart' as _i5;
import 'priority.dart' as _i6;
import 'user_profile.dart' as _i7;
export 'admin_profile.dart';
export 'animal.dart';
export 'colour.dart';
export 'not_found_exception.dart';
export 'priority.dart';
export 'user_profile.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AdminProfile) {
      return _i2.AdminProfile.fromJson(data) as T;
    }
    if (t == _i3.Cat) {
      return _i3.Cat.fromJson(data) as T;
    }
    if (t == _i3.Dog) {
      return _i3.Dog.fromJson(data) as T;
    }
    if (t == _i4.Colour) {
      return _i4.Colour.fromJson(data) as T;
    }
    if (t == _i5.NotFoundException) {
      return _i5.NotFoundException.fromJson(data) as T;
    }
    if (t == _i6.Priority) {
      return _i6.Priority.fromJson(data) as T;
    }
    if (t == _i7.UserProfile) {
      return _i7.UserProfile.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AdminProfile?>()) {
      return (data != null ? _i2.AdminProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Cat?>()) {
      return (data != null ? _i3.Cat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Dog?>()) {
      return (data != null ? _i3.Dog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Colour?>()) {
      return (data != null ? _i4.Colour.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.NotFoundException?>()) {
      return (data != null ? _i5.NotFoundException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.Priority?>()) {
      return (data != null ? _i6.Priority.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.UserProfile?>()) {
      return (data != null ? _i7.UserProfile.fromJson(data) : null) as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == Set<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toSet() as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
          as T;
    }
    if (t == Map<int, String>) {
      return Map.fromEntries(
            (data as List).map(
              (e) => MapEntry(
                deserialize<int>(e['k']),
                deserialize<String>(e['v']),
              ),
            ),
          )
          as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AdminProfile => 'AdminProfile',
      _i3.Cat => 'Cat',
      _i3.Dog => 'Dog',
      _i4.Colour => 'Colour',
      _i5.NotFoundException => 'NotFoundException',
      _i6.Priority => 'Priority',
      _i7.UserProfile => 'UserProfile',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('sample.', '');
    }

    switch (data) {
      case _i2.AdminProfile():
        return 'AdminProfile';
      case _i3.Cat():
        return 'Cat';
      case _i3.Dog():
        return 'Dog';
      case _i4.Colour():
        return 'Colour';
      case _i5.NotFoundException():
        return 'NotFoundException';
      case _i6.Priority():
        return 'Priority';
      case _i7.UserProfile():
        return 'UserProfile';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AdminProfile') {
      return deserialize<_i2.AdminProfile>(data['data']);
    }
    if (dataClassName == 'Cat') {
      return deserialize<_i3.Cat>(data['data']);
    }
    if (dataClassName == 'Dog') {
      return deserialize<_i3.Dog>(data['data']);
    }
    if (dataClassName == 'Colour') {
      return deserialize<_i4.Colour>(data['data']);
    }
    if (dataClassName == 'NotFoundException') {
      return deserialize<_i5.NotFoundException>(data['data']);
    }
    if (dataClassName == 'Priority') {
      return deserialize<_i6.Priority>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_i7.UserProfile>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }

  /// Maps container types (like [List], [Map], [Set]) containing
  /// [Record]s or non-String-keyed [Map]s to their JSON representation.
  ///
  /// It should not be called for [SerializableModel] types. These
  /// handle the "[Record] in container" mapping internally already.
  ///
  /// It is only supposed to be called from generated protocol code.
  ///
  /// Returns either a `List<dynamic>` (for List, Sets, and Maps with
  /// non-String keys) or a `Map<String, dynamic>` in case the input was
  /// a `Map<String, …>`.
  Object? mapContainerToJson(Object obj) {
    if (obj is! Iterable && obj is! Map) {
      throw ArgumentError.value(
        obj,
        'obj',
        'The object to serialize should be of type List, Map, or Set',
      );
    }

    dynamic mapIfNeeded(Object? obj) {
      return switch (obj) {
        Record record => mapRecordToJson(record),
        Iterable iterable => mapContainerToJson(iterable),
        Map map => mapContainerToJson(map),
        Object? value => value,
      };
    }

    switch (obj) {
      case Map<String, dynamic>():
        return {
          for (var entry in obj.entries) entry.key: mapIfNeeded(entry.value),
        };
      case Map():
        return [
          for (var entry in obj.entries)
            {
              'k': mapIfNeeded(entry.key),
              'v': mapIfNeeded(entry.value),
            },
        ];

      case Iterable():
        return [
          for (var e in obj) mapIfNeeded(e),
        ];
    }

    return obj;
  }
}
