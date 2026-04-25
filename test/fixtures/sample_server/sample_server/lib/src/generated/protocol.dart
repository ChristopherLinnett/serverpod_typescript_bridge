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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:serverpod/protocol.dart' as _i2;
import 'admin_profile.dart' as _i3;
import 'animal.dart' as _i4;
import 'colour.dart' as _i5;
import 'not_found_exception.dart' as _i6;
import 'priority.dart' as _i7;
import 'user_profile.dart' as _i8;
export 'admin_profile.dart';
export 'animal.dart';
export 'colour.dart';
export 'not_found_exception.dart';
export 'priority.dart';
export 'user_profile.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i3.AdminProfile) {
      return _i3.AdminProfile.fromJson(data) as T;
    }
    if (t == _i4.Cat) {
      return _i4.Cat.fromJson(data) as T;
    }
    if (t == _i4.Dog) {
      return _i4.Dog.fromJson(data) as T;
    }
    if (t == _i5.Colour) {
      return _i5.Colour.fromJson(data) as T;
    }
    if (t == _i6.NotFoundException) {
      return _i6.NotFoundException.fromJson(data) as T;
    }
    if (t == _i7.Priority) {
      return _i7.Priority.fromJson(data) as T;
    }
    if (t == _i8.UserProfile) {
      return _i8.UserProfile.fromJson(data) as T;
    }
    if (t == _i1.getType<_i3.AdminProfile?>()) {
      return (data != null ? _i3.AdminProfile.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Cat?>()) {
      return (data != null ? _i4.Cat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Dog?>()) {
      return (data != null ? _i4.Dog.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Colour?>()) {
      return (data != null ? _i5.Colour.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.NotFoundException?>()) {
      return (data != null ? _i6.NotFoundException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Priority?>()) {
      return (data != null ? _i7.Priority.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.UserProfile?>()) {
      return (data != null ? _i8.UserProfile.fromJson(data) : null) as T;
    }
    if (t == List<_i7.Priority>) {
      return (data as List).map((e) => deserialize<_i7.Priority>(e)).toList()
          as T;
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
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i3.AdminProfile => 'AdminProfile',
      _i4.Cat => 'Cat',
      _i4.Dog => 'Dog',
      _i5.Colour => 'Colour',
      _i6.NotFoundException => 'NotFoundException',
      _i7.Priority => 'Priority',
      _i8.UserProfile => 'UserProfile',
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
      case _i3.AdminProfile():
        return 'AdminProfile';
      case _i4.Cat():
        return 'Cat';
      case _i4.Dog():
        return 'Dog';
      case _i5.Colour():
        return 'Colour';
      case _i6.NotFoundException():
        return 'NotFoundException';
      case _i7.Priority():
        return 'Priority';
      case _i8.UserProfile():
        return 'UserProfile';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
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
      return deserialize<_i3.AdminProfile>(data['data']);
    }
    if (dataClassName == 'Cat') {
      return deserialize<_i4.Cat>(data['data']);
    }
    if (dataClassName == 'Dog') {
      return deserialize<_i4.Dog>(data['data']);
    }
    if (dataClassName == 'Colour') {
      return deserialize<_i5.Colour>(data['data']);
    }
    if (dataClassName == 'NotFoundException') {
      return deserialize<_i6.NotFoundException>(data['data']);
    }
    if (dataClassName == 'Priority') {
      return deserialize<_i7.Priority>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_i8.UserProfile>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'sample';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i2.Protocol().mapRecordToJson(record);
    } catch (_) {}
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
