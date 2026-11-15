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
import 'priority.dart' as _isecxwh3;

/// A model whose fields carry defaults.
abstract class Settings
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Settings._({
    int? count,
    String? label,
    bool? enabled,
    _isecxwh3.Priority? mode,
    double? ratio,
    this.note,
  }) : count = count ?? 3,
       label = label ?? 'untitled',
       enabled = enabled ?? true,
       mode = mode ?? _isecxwh3.Priority.normal,
       ratio = ratio ?? 1.5;

  factory Settings({
    int? count,
    String? label,
    bool? enabled,
    _isecxwh3.Priority? mode,
    double? ratio,
    String? note,
  }) = _SettingsImpl;

  factory Settings.fromJson(Map<String, dynamic> jsonSerialization) {
    return Settings(
      count: jsonSerialization['count'] as int?,
      label: jsonSerialization['label'] as String?,
      enabled: jsonSerialization['enabled'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['enabled']),
      mode: jsonSerialization['mode'] == null
          ? null
          : _isecxwh3.Priority.fromJson((jsonSerialization['mode'] as int)),
      ratio: (jsonSerialization['ratio'] as num?)?.toDouble(),
      note: jsonSerialization['note'] as String?,
    );
  }

  /// Defaults to 3.
  int count;

  /// Defaults to `'untitled'`.
  String label;

  /// Defaults to `true`.
  bool enabled;

  /// Defaults to `normal`.
  _isecxwh3.Priority mode;

  /// Defaults to 1.5.
  double ratio;

  /// No default; nullable.
  String? note;

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Settings copyWith({
    int? count,
    String? label,
    bool? enabled,
    _isecxwh3.Priority? mode,
    double? ratio,
    String? note,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Settings',
      'count': count,
      'label': label,
      'enabled': enabled,
      'mode': mode.toJson(),
      'ratio': ratio,
      if (note != null) 'note': note,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Settings',
      'count': count,
      'label': label,
      'enabled': enabled,
      'mode': mode.toJson(),
      'ratio': ratio,
      if (note != null) 'note': note,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SettingsImpl extends Settings {
  _SettingsImpl({
    int? count,
    String? label,
    bool? enabled,
    _isecxwh3.Priority? mode,
    double? ratio,
    String? note,
  }) : super._(
         count: count,
         label: label,
         enabled: enabled,
         mode: mode,
         ratio: ratio,
         note: note,
       );

  /// Returns a shallow copy of this [Settings]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Settings copyWith({
    int? count,
    String? label,
    bool? enabled,
    _isecxwh3.Priority? mode,
    double? ratio,
    Object? note = _Undefined,
  }) {
    return Settings(
      count: count ?? this.count,
      label: label ?? this.label,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      ratio: ratio ?? this.ratio,
      note: note is String? ? note : this.note,
    );
  }
}
