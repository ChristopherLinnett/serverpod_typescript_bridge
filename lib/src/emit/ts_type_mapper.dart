// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';

/// A TypeScript type reference plus the JSON conversion expressions that
/// turn a value of that type into wire form (and back).
class TsTypeRef {
  TsTypeRef({
    required this.tsType,
    required this.toJsonExpr,
    required this.fromJsonExpr,
  });

  /// The fully-qualified TS type, e.g. `string | null` or `User[]`.
  final String tsType;

  /// Builds a `toJson` expression for a Dart value of this type, given
  /// a TS source variable name.
  final String Function(String sourceVarName) toJsonExpr;

  /// Builds a `fromJson` expression that parses a raw JSON value
  /// (typically `unknown`) back into the typed value.
  final String Function(String sourceVarName) fromJsonExpr;
}

/// Maps a Serverpod analyzer [TypeDefinition] to its TypeScript
/// counterpart. Per the canonical mapping table in
/// [docs/architecture.md](../../../docs/architecture.md).
///
/// [modelPrefix] is prepended to project-model TS types and `fromJson`
/// calls — used by the endpoint emitter to reach across into the
/// protocol barrel (`p.UserProfile.fromJson(...)`). Model emitters
/// that already live inside the protocol directory pass an empty
/// prefix.
class TsTypeMapper {
  TsTypeMapper({
    this.modelPrefix = '',
    Set<String>? sealedClassNames,
    Set<String>? enumClassNames,
    Set<String>? projectClassNames,
  })  : sealedClassNames = sealedClassNames ?? const {},
        enumClassNames = enumClassNames ?? const {},
        projectClassNames = projectClassNames ?? const {};

  final String modelPrefix;

  /// Class names that were emitted as sealed bases. References to these
  /// types still use the bare name (the discriminated-union alias), but
  /// `fromJson` routes through `<Name>Base` (the abstract dispatcher).
  final Set<String> sealedClassNames;

  /// Class names that were emitted as TS enums. The model emitter uses
  /// a sibling `<Name>Codec` object for `toJson`/`fromJson`, so the
  /// generated expressions for enum-typed fields must call
  /// `<Name>Codec.toJson(value)` and `<Name>Codec.fromJson(json)`
  /// instead of `<value>.toJson()` / `<Name>.fromJson(json)`.
  final Set<String> enumClassNames;

  /// Every class name emitted as part of THIS project (sealed, enum,
  /// regular class, exception). Anything not in here is a foreign
  /// type — typically defined in a Serverpod module the project
  /// depends on. v0.1.x stubs foreign types as `unknown`; v0.2 will
  /// emit a real cross-package import.
  final Set<String> projectClassNames;

  TsTypeRef map(TypeDefinition type) {
    final base = _mapInner(type);
    if (!type.nullable) return base;
    return TsTypeRef(
      tsType: '${base.tsType} | null',
      toJsonExpr: (v) => '$v === null ? null : ${base.toJsonExpr(v)}',
      fromJsonExpr: (v) =>
          '$v === null || $v === undefined ? null : ${base.fromJsonExpr(v)}',
    );
  }

  TsTypeRef _mapInner(TypeDefinition type) {
    switch (type.className) {
      case 'int':
      case 'double':
      case 'num':
        return _passthrough('number');
      case 'String':
        return _passthrough('string');
      case 'bool':
        return TsTypeRef(
          tsType: 'boolean',
          toJsonExpr: (v) => v,
          fromJsonExpr: (v) => 'r.decodeBool($v)',
        );
      case 'DateTime':
        return TsTypeRef(
          tsType: 'Date',
          toJsonExpr: (v) => 'r.encodeDateTime($v)',
          fromJsonExpr: (v) => 'r.decodeDateTime($v)',
        );
      case 'Duration':
        return TsTypeRef(
          tsType: 'number',
          toJsonExpr: (v) => 'r.encodeDuration($v)',
          fromJsonExpr: (v) => 'r.decodeDuration($v)',
        );
      case 'BigInt':
        return TsTypeRef(
          tsType: 'bigint',
          toJsonExpr: (v) => 'r.encodeBigInt($v)',
          fromJsonExpr: (v) => 'r.decodeBigInt($v)',
        );
      case 'UuidValue':
      case 'Uri':
        return _passthrough('string');
      case 'ByteData':
      case 'Uint8List':
        return TsTypeRef(
          tsType: 'Uint8Array',
          toJsonExpr: (v) => 'r.encodeBytes($v)',
          fromJsonExpr: (v) => 'r.decodeBytes($v)',
        );
      case 'List':
        return _mapList(type);
      case 'Set':
        return _mapSet(type);
      case 'Map':
        return _mapMap(type);
      case 'Future':
      case 'Stream':
        // Streaming params/returns are stubbed by the endpoint emitter,
        // so the precise type doesn't matter at the call site — but we
        // still need a TS placeholder that compiles.
        return TsTypeRef(
          tsType: 'unknown',
          toJsonExpr: (v) => v,
          fromJsonExpr: (v) => v,
        );
      case 'void':
        // Endpoint emitter inspects `tsReturnInner == 'void'` and emits
        // `() => undefined as void` for the decoder, so the to/from
        // expressions here are unreachable in practice. Keep them
        // identity-passes for safety.
        return TsTypeRef(
          tsType: 'void',
          toJsonExpr: (v) => v,
          fromJsonExpr: (v) => 'undefined as void',
        );
      case 'dynamic':
      case 'Object':
        return _passthrough('unknown');
      default:
        return _mapModelOrEnum(type);
    }
  }

  TsTypeRef _passthrough(String tsType) {
    return TsTypeRef(
      tsType: tsType,
      toJsonExpr: (v) => v,
      fromJsonExpr: (v) => '$v as $tsType',
    );
  }

  TsTypeRef _mapList(TypeDefinition type) {
    final elem = map(type.generics.first);
    return TsTypeRef(
      tsType: '${_parens(elem.tsType)}[]',
      toJsonExpr: (v) =>
          'r.encodeList($v, (x: ${elem.tsType}) => ${elem.toJsonExpr('x')})',
      fromJsonExpr: (v) =>
          'r.decodeList($v, (x: unknown) => ${elem.fromJsonExpr('x')})',
    );
  }

  TsTypeRef _mapSet(TypeDefinition type) {
    final elem = map(type.generics.first);
    return TsTypeRef(
      tsType: 'Set<${elem.tsType}>',
      toJsonExpr: (v) =>
          'r.encodeSet($v, (x: ${elem.tsType}) => ${elem.toJsonExpr('x')})',
      fromJsonExpr: (v) =>
          'r.decodeSet($v, (x: unknown) => ${elem.fromJsonExpr('x')})',
    );
  }

  TsTypeRef _mapMap(TypeDefinition type) {
    final key = map(type.generics[0]);
    final value = map(type.generics[1]);
    final isStringKeyed = type.generics[0].className == 'String';
    if (isStringKeyed) {
      return TsTypeRef(
        tsType: 'Record<string, ${value.tsType}>',
        toJsonExpr: (v) =>
            'r.encodeMap($v, (x: ${value.tsType}) => ${value.toJsonExpr('x')})',
        fromJsonExpr: (v) =>
            'r.decodeRecord($v, (x: unknown) => ${value.fromJsonExpr('x')})',
      );
    }
    return TsTypeRef(
      tsType: 'Map<${key.tsType}, ${value.tsType}>',
      toJsonExpr: (v) =>
          'r.encodeMap($v, (x: ${value.tsType}) => ${value.toJsonExpr('x')})',
      fromJsonExpr: (v) =>
          'r.decodeMap($v, (x: unknown) => ${key.fromJsonExpr('x')}, (x: unknown) => ${value.fromJsonExpr('x')})',
    );
  }

  TsTypeRef _mapModelOrEnum(TypeDefinition type) {
    final qualifiedType = '$modelPrefix${type.className}';

    // Foreign type — typically defined in a Serverpod module the
    // project depends on (e.g. AuthSuccess from serverpod_auth_idp).
    // v0.1.x falls back to `unknown` so the package compiles; v0.2
    // will emit real `import type { ... } from '<module-ts-pkg>';`
    // statements based on `TypeDefinition.url`.
    if (projectClassNames.isNotEmpty &&
        !projectClassNames.contains(type.className)) {
      return TsTypeRef(
        // The `unknown` cast keeps tsc happy and surfaces the gap to
        // users via the IDE's hover.
        tsType: 'unknown /* TODO(v0.2): module type ${type.className} */',
        toJsonExpr: (v) => '$v as unknown',
        fromJsonExpr: (v) => '$v as unknown',
      );
    }

    if (enumClassNames.contains(type.className)) {
      // Enums use a sibling `<Name>Codec` object for both directions.
      final codec = '$modelPrefix${type.className}Codec';
      return TsTypeRef(
        tsType: qualifiedType,
        toJsonExpr: (v) => '$codec.toJson($v)',
        fromJsonExpr: (v) => '$codec.fromJson($v)',
      );
    }

    // Sealed bases route `fromJson` through `<Name>Base` (the abstract
    // dispatcher); the type itself is the bare union alias. Plain
    // classes / exceptions use `<Name>.fromJson(...)`.
    final fromJsonReceiver = sealedClassNames.contains(type.className)
        ? '$modelPrefix${type.className}Base'
        : qualifiedType;
    return TsTypeRef(
      tsType: qualifiedType,
      toJsonExpr: (v) => '$v.toJson()',
      fromJsonExpr: (v) =>
          '$fromJsonReceiver.fromJson($v as Record<string, unknown>)',
    );
  }

  String _parens(String t) => t.contains(' ') || t.contains('|') ? '($t)' : t;
}
