/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:sample_client/src/protocol/colour.dart' as _is36gx7z;
import 'package:sample_client/src/protocol/priority.dart' as _iy4p1hnt;
import 'package:sample_client/src/protocol/user_profile.dart' as _iye2z13d;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'admin_profile.dart' as _iatoqpz1;
import 'animal.dart' as _icwrltez;
import 'app_exception.dart' as _it4z223c;
import 'colour.dart' as _iy6jkkge;
import 'embedding.dart' as _isx0ustv;
import 'not_found_exception.dart' as _i6jvclsf;
import 'priority.dart' as _isecxwh3;
import 'quota_exception.dart' as _isik728p;
import 'settings.dart' as _ibmr8d9c;
import 'user_profile.dart' as _ir2mn8w1;
export 'admin_profile.dart';
export 'animal.dart';
export 'quota_exception.dart';
export 'app_exception.dart';
export 'colour.dart';
export 'embedding.dart';
export 'not_found_exception.dart';
export 'priority.dart';
export 'settings.dart';
export 'user_profile.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager
    implements _isc.ProtocolDeserializationProvider {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  _isc.ProtocolDeserialization get deserializationMetadata =>
      _isc.ProtocolDeserialization.cached(
        this,
        types: const [
          _isc.getType<_iatoqpz1.AdminProfile>,
          _isc.getType<_icwrltez.Cat>,
          _isc.getType<_icwrltez.Dog>,
          _isc.getType<_isik728p.QuotaException>,
          _isc.getType<_it4z223c.AppException>,
          _isc.getType<_iy6jkkge.Colour>,
          _isc.getType<_isx0ustv.Embedding>,
          _isc.getType<_i6jvclsf.NotFoundException>,
          _isc.getType<_isecxwh3.Priority>,
          _isc.getType<_ibmr8d9c.Settings>,
          _isc.getType<_ir2mn8w1.UserProfile>,
          _isc.getType<_iatoqpz1.AdminProfile?>,
          _isc.getType<_icwrltez.Cat?>,
          _isc.getType<_icwrltez.Dog?>,
          _isc.getType<_isik728p.QuotaException?>,
          _isc.getType<_it4z223c.AppException?>,
          _isc.getType<_iy6jkkge.Colour?>,
          _isc.getType<_isx0ustv.Embedding?>,
          _isc.getType<_i6jvclsf.NotFoundException?>,
          _isc.getType<_isecxwh3.Priority?>,
          _isc.getType<_ibmr8d9c.Settings?>,
          _isc.getType<_ir2mn8w1.UserProfile?>,
          _isc.getType<List<_isecxwh3.Priority>>,
          _isc.getType<List<int>>,
          _isc.getType<Set<String>>,
          _isc.getType<Map<String, int>>,
          _isc.getType<Map<int, String>>,
          _isc.getType<List<_iy4p1hnt.Priority>>,
          _isc.getType<Map<String, _is36gx7z.Colour>>,
          _isc.getType<List<int>?>,
          _isc.getType<Set<int>>,
          _isc.getType<List<_iye2z13d.UserProfile>>,
        ],
        modules: const [],
        classNames: const [
          'AdminProfile',
          'Cat',
          'Dog',
          'QuotaException',
          'AppException',
          'Colour',
          'Embedding',
          'NotFoundException',
          'Priority',
          'Settings',
          'UserProfile',
          'List<int>',
        ],
      );

  static String? getClassNameFromObjectJson(dynamic data) =>
      _isc.ProtocolDeserialization.readClassName(data);

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    final rawDataClassName = _isc.ProtocolDeserialization.readClassName(data);
    final dataClassName = rawDataClassName;
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _iatoqpz1.AdminProfile) {
      return _iatoqpz1.AdminProfile.fromJson(data) as T;
    }
    if (t == _icwrltez.Cat) {
      return _icwrltez.Cat.fromJson(data) as T;
    }
    if (t == _icwrltez.Dog) {
      return _icwrltez.Dog.fromJson(data) as T;
    }
    if (t == _isik728p.QuotaException) {
      return _isik728p.QuotaException.fromJson(data) as T;
    }
    if (t == _it4z223c.AppException) {
      return _it4z223c.AppException.fromJson(data) as T;
    }
    if (t == _iy6jkkge.Colour) {
      return _iy6jkkge.Colour.fromJson(data) as T;
    }
    if (t == _isx0ustv.Embedding) {
      return _isx0ustv.Embedding.fromJson(data) as T;
    }
    if (t == _i6jvclsf.NotFoundException) {
      return _i6jvclsf.NotFoundException.fromJson(data) as T;
    }
    if (t == _isecxwh3.Priority) {
      return _isecxwh3.Priority.fromJson(data) as T;
    }
    if (t == _ibmr8d9c.Settings) {
      return _ibmr8d9c.Settings.fromJson(data) as T;
    }
    if (t == _ir2mn8w1.UserProfile) {
      return _ir2mn8w1.UserProfile.fromJson(data) as T;
    }
    if (t == _isc.getType<_iatoqpz1.AdminProfile?>()) {
      return (data != null ? _iatoqpz1.AdminProfile.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icwrltez.Cat?>()) {
      return (data != null ? _icwrltez.Cat.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_icwrltez.Dog?>()) {
      return (data != null ? _icwrltez.Dog.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_isik728p.QuotaException?>()) {
      return (data != null ? _isik728p.QuotaException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_it4z223c.AppException?>()) {
      return (data != null ? _it4z223c.AppException.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iy6jkkge.Colour?>()) {
      return (data != null ? _iy6jkkge.Colour.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_isx0ustv.Embedding?>()) {
      return (data != null ? _isx0ustv.Embedding.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i6jvclsf.NotFoundException?>()) {
      return (data != null ? _i6jvclsf.NotFoundException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_isecxwh3.Priority?>()) {
      return (data != null ? _isecxwh3.Priority.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ibmr8d9c.Settings?>()) {
      return (data != null ? _ibmr8d9c.Settings.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ir2mn8w1.UserProfile?>()) {
      return (data != null ? _ir2mn8w1.UserProfile.fromJson(data) : null) as T;
    }
    if (t == List<_isecxwh3.Priority>) {
      return (data as List)
              .map((e) => deserialize<_isecxwh3.Priority>(e))
              .toList()
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
    if (t == List<_iy4p1hnt.Priority>) {
      return (data as List)
              .map((e) => deserialize<_iy4p1hnt.Priority>(e))
              .toList()
          as T;
    }
    if (t == Map<String, _is36gx7z.Colour>) {
      return (data as Map).map(
            (k, v) => MapEntry(
              deserialize<String>(k),
              deserialize<_is36gx7z.Colour>(v),
            ),
          )
          as T;
    }
    if (t == _isc.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == Set<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toSet() as T;
    }
    if (t == List<_iye2z13d.UserProfile>) {
      return (data as List)
              .map((e) => deserialize<_iye2z13d.UserProfile>(e))
              .toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _iatoqpz1.AdminProfile => 'AdminProfile',
      _icwrltez.Cat => 'Cat',
      _icwrltez.Dog => 'Dog',
      _isik728p.QuotaException => 'QuotaException',
      _it4z223c.AppException => 'AppException',
      _iy6jkkge.Colour => 'Colour',
      _isx0ustv.Embedding => 'Embedding',
      _i6jvclsf.NotFoundException => 'NotFoundException',
      _isecxwh3.Priority => 'Priority',
      _ibmr8d9c.Settings => 'Settings',
      _ir2mn8w1.UserProfile => 'UserProfile',
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
      case _iatoqpz1.AdminProfile():
        return 'AdminProfile';
      case _icwrltez.Cat():
        return 'Cat';
      case _icwrltez.Dog():
        return 'Dog';
      case _isik728p.QuotaException():
        return 'QuotaException';
      case _it4z223c.AppException():
        return 'AppException';
      case _iy6jkkge.Colour():
        return 'Colour';
      case _isx0ustv.Embedding():
        return 'Embedding';
      case _i6jvclsf.NotFoundException():
        return 'NotFoundException';
      case _isecxwh3.Priority():
        return 'Priority';
      case _ibmr8d9c.Settings():
        return 'Settings';
      case _ir2mn8w1.UserProfile():
        return 'UserProfile';
    }
    if (data is List<int>) {
      return 'List<int>';
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
      return deserialize<_iatoqpz1.AdminProfile>(data['data']);
    }
    if (dataClassName == 'Cat') {
      return deserialize<_icwrltez.Cat>(data['data']);
    }
    if (dataClassName == 'Dog') {
      return deserialize<_icwrltez.Dog>(data['data']);
    }
    if (dataClassName == 'QuotaException') {
      return deserialize<_isik728p.QuotaException>(data['data']);
    }
    if (dataClassName == 'AppException') {
      return deserialize<_it4z223c.AppException>(data['data']);
    }
    if (dataClassName == 'Colour') {
      return deserialize<_iy6jkkge.Colour>(data['data']);
    }
    if (dataClassName == 'Embedding') {
      return deserialize<_isx0ustv.Embedding>(data['data']);
    }
    if (dataClassName == 'NotFoundException') {
      return deserialize<_i6jvclsf.NotFoundException>(data['data']);
    }
    if (dataClassName == 'Priority') {
      return deserialize<_isecxwh3.Priority>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_ibmr8d9c.Settings>(data['data']);
    }
    if (dataClassName == 'UserProfile') {
      return deserialize<_ir2mn8w1.UserProfile>(data['data']);
    }
    if (dataClassName == 'List<int>') {
      return deserialize<List<int>>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

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
