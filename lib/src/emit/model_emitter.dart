// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/generator/types.dart'
    show DefaultValueAllowedType;
import 'package:serverpod_shared/serverpod_shared.dart' show parseDuration;

import 'generated_file_tracker.dart';
import 'module_import_lines.dart';
import 'ts_type_mapper.dart';
import 'ts_writer.dart';

const _generatedHeader = '''
// AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND
// To regenerate, run: dart run serverpod_typescript_bridge generate
''';

/// Emits one TypeScript file per Serverpod model — class, enum, or
/// exception — plus a `protocol/index.ts` barrel re-exporting them.
class ModelEmitter {
  ModelEmitter({
    required this.outputDir,
    required this.tracker,
    required this.mapper,
    this.classNamePrefix = '',
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;
  final TsTypeMapper mapper;

  /// Prepended to every `__className__` this package writes: `<nickname>.`
  /// for a module, empty for an app — the same form Serverpod's Dart client
  /// puts on the wire.
  final String classNamePrefix;

  static const _registryStem = '_registry';

  /// The registry's filename under `src/protocol/`.
  static const registryFilename = '$_registryStem.ts';

  late final ModuleImportLines _moduleImports =
      ModuleImportLines(mapper.moduleIndex);

  /// Appends one cross-package `import` line per module package
  /// referenced by [fields] to [w]. Shared between `_emitClass` and
  /// `_emitException` so the two paths can't drift.
  void _writeModuleImports(
    TsWriter w,
    List<SerializableModelFieldDefinition> fields,
  ) {
    for (final line in _moduleImports.forTypes(fields.map((f) => f.type))) {
      w.writeln(line);
    }
  }

  /// Every class name in the project — sealed bases, plain classes,
  /// exceptions, and enums. Populated by [emitAll] before any per-file
  /// emission so cross-file imports can be resolved.
  late Set<String> _allClassNames;
  late Set<String> _enumNames;

  /// Emits one `.ts` file per model, the registry they decode through, and
  /// the barrel. Returns the model filenames, sorted.
  List<String> emitAll(List<SerializableModelDefinition> models) {
    _allClassNames = {for (final m in models) m.className};
    _enumNames = {
      for (final m in models.whereType<EnumDefinition>()) m.className,
    };

    final emitted = <String>[];
    for (final model in models) {
      if (model is ClassDefinition) {
        emitted.add(_emitClass(model));
      } else if (model is EnumDefinition) {
        emitted.add(_emitEnum(model));
      }
    }
    emitted.sort();
    _emitRegistry();
    _emitProtocolBarrel(emitted);
    return emitted;
  }

  /// Concrete (non-sealed) descendants of a sealed class, by name — the
  /// members of its TypeScript union.
  List<ClassDefinition> _concreteDescendants(ClassDefinition sealed) {
    final out = sealed.descendantClasses.where((c) => !c.isSealed).toList()
      ..sort((a, b) => a.className.compareTo(b.className));
    return out;
  }

  /// The registry is a leaf module: it imports only the runtime, so a model
  /// file can decode a sibling through it without importing the sibling.
  /// Two model files that import each other's classes cannot both be
  /// evaluated first, and a subclass needs its parent evaluated before it —
  /// which is how a sealed base that imported its own subclasses made the
  /// whole package fail on import.
  void _emitRegistry() {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';")
      ..blankLine()
      ..writeln('/**')
      ..writeln(
        ' * Decoders for every model in this package, keyed by wire class name.',
      )
      ..writeln(' * Each model file registers itself when it loads.')
      ..writeln(' */')
      ..writeln('export const models = new r.ModelRegistry();');
    _writeFile(registryFilename, w.toString());
  }

  void _emitProtocolBarrel(List<String> filenames) {
    final w = TsWriter()..writeRaw(_generatedHeader);
    for (final f in filenames) {
      final stem = f.replaceAll(RegExp(r'\.ts$'), '');
      w.writeln("export * from './$stem.js';");
    }
    // Empty barrels need an `export {};` so TS treats the file as a
    // module — otherwise `import * as p from '../protocol/index.js'`
    // fails with `is not a module`.
    if (filenames.isEmpty) w.writeln('export {};');
    _writeFile('index.ts', w.toString());
  }

  /// Walks a [TypeDefinition] recursively (descending into generics)
  /// and adds every project-class name referenced to [out]. Primitives
  /// and collection wrappers are skipped because they're not in
  /// [_allClassNames].
  ///
  /// Self-references ARE collected here; [_buildImportLines] strips the
  /// owner's own className before writing the import lines so the file
  /// doesn't import itself.
  void _collectReferencedProjectTypes(
    TypeDefinition type,
    Set<String> out,
  ) {
    final name = type.className;
    if (_allClassNames.contains(name)) out.add(name);
    for (final g in type.generics) {
      _collectReferencedProjectTypes(g, out);
    }
  }

  /// Import lines for the sibling types [fields] mention.
  ///
  /// Classes are imported as TYPES only: decoding goes through the registry,
  /// so no model file needs another's runtime value, and none can form an
  /// evaluation cycle. Enums are the exception — their codec is a runtime
  /// value — and they are safe because an enum file imports nothing.
  List<String> _buildImportLines({
    required String ownClassName,
    required List<SerializableModelFieldDefinition> fields,
    String? parentClassName,
  }) {
    final referenced = <String>{};
    for (final f in fields) {
      _collectReferencedProjectTypes(f.type, referenced);
    }
    referenced
      ..remove(ownClassName)
      ..remove(parentClassName);

    final sorted = referenced.toList()..sort();
    return [
      for (final ref in sorted)
        if (_enumNames.contains(ref))
          "import { $ref, ${ref}Codec } from './${_filenameStemOf(ref)}.js';"
        else
          "import type { $ref } from './${_filenameStemOf(ref)}.js';",
    ];
  }

  /// The TypeScript class a Dart class is emitted as. A sealed class is an
  /// abstract `<Name>Base`; its bare name is the union of its concrete
  /// descendants, which is what lets a `switch` over them be exhaustive.
  String _tsClassNameOf(ClassDefinition model) =>
      model.isSealed ? '${model.className}Base' : model.className;

  List<SerializableModelFieldDefinition> _clientFields(
    Iterable<SerializableModelFieldDefinition> fields,
  ) =>
      fields.where((f) => f.shouldIncludeField(false /* serverCode */)).toList();

  /// Emits a model or exception class: its own fields, a constructor taking
  /// every field including inherited ones, and — unless it is sealed —
  /// `fromJson` / `toJson` / `copyWith` and its registration.
  String _emitClass(ClassDefinition model) {
    final isException = model is ExceptionClassDefinition;
    final parent = model.parentClass;
    final ownFields = _clientFields(model.fields);
    final allFields = _clientFields(model.fieldsIncludingInherited);
    final tsName = _tsClassNameOf(model);
    final parentIsLocal =
        parent != null && _allClassNames.contains(parent.className);

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';")
      ..writeln("import { models } from './$_registryStem.js';");
    if (parent != null && parentIsLocal) {
      // The one value import between model files: `extends` needs the parent
      // at evaluation time, and a parent never imports a descendant's value.
      w.writeln(
        "import { ${_tsClassNameOf(parent)} } from './${_filenameStemOf(parent.className)}.js';",
      );
    }
    for (final line in _buildImportLines(
      ownClassName: model.className,
      fields: allFields,
      parentClassName: parentIsLocal ? parent.className : null,
    )) {
      w.writeln(line);
    }
    if (model.isSealed) {
      for (final member in _concreteDescendants(model)) {
        w.writeln(
          "import type { ${member.className} } from './${_filenameStemOf(member.className)}.js';",
        );
      }
    }
    _writeModuleImports(w, allFields);
    if (parent != null && !parentIsLocal) {
      for (final line in _moduleImports.forClassNames([parent.className])) {
        w.writeln(line);
      }
    }
    w.blankLine();

    if (model.isSealed) {
      final union = _concreteDescendants(model);
      w.docComment(model.documentation?.join('\n'));
      w.writeln(
        'export type ${model.className} = '
        '${union.isEmpty ? 'never' : union.map((s) => s.className).join(' | ')};',
      );
      w.blankLine();
    } else {
      w.docComment(model.documentation?.join('\n'));
    }

    final superClass = parent != null
        ? _tsClassNameOf(parent)
        : (isException ? 'Error' : null);
    final contract =
        isException ? 'r.SerializableException' : 'r.SerializableModel';
    w.writeln(
      'export ${model.isSealed ? 'abstract ' : ''}class $tsName'
      '${superClass == null ? '' : ' extends $superClass'}'
      ' implements $contract {',
    );
    w.indent(() {
      for (final field in ownFields) {
        w.docComment(field.documentation?.join('\n'));
        final type = mapper.map(field.type);
        w.writeln(
          '${isException ? 'readonly ' : ''}${field.name}: ${type.tsType};',
        );
      }
      if (ownFields.isNotEmpty) w.blankLine();

      _writeConstructor(
        w,
        model: model,
        ownFields: ownFields,
        allFields: allFields,
        hasParent: parent != null,
      );
      w.blankLine();

      if (model.isSealed) {
        w.writeln('abstract toJson(): Record<string, unknown>;');
        w.blankLine();
        // No class of its own to build: the wire's `__className__` names
        // the concrete descendant.
        w.writeln(
          'static fromJson(json: Record<string, unknown>): ${model.className} {',
        );
        w.indent(() {
          w.writeln(
            "return models.decode<${model.className}>('${model.className}', json);",
          );
        });
        w.writeln('}');
      } else {
        _writeFromJson(w, model, allFields);
        w.blankLine();
        _writeToJson(w, model, allFields);
        w.blankLine();
        _writeCopyWith(w, model, allFields);
      }
    });
    w.writeln('}');

    if (!model.isSealed) {
      w.blankLine();
      w.writeln(
        "models.register('${model.className}', (json) => ${model.className}.fromJson(json));",
      );
    }

    return _writeFile(_filenameOf(model.className), w.toString());
  }

  /// Nullable fields are optional on the `init` bag and default to `null`,
  /// so callers do not pad every nullable field; the class field itself
  /// stays `T | null`.
  void _writeConstructor(
    TsWriter w, {
    required ClassDefinition model,
    required List<SerializableModelFieldDefinition> ownFields,
    required List<SerializableModelFieldDefinition> allFields,
    required bool hasParent,
  }) {
    final isException = model is ExceptionClassDefinition;
    if (allFields.isEmpty) {
      if (!hasParent && isException) {
        w.writeln('constructor() {');
        w.indent(() {
          w.writeln("super('${model.className}');");
          w.writeln("this.name = '${model.className}';");
        });
        w.writeln('}');
      } else {
        w.writeln('constructor() {');
        w.indent(() {
          if (hasParent) w.writeln('super();');
          if (isException) w.writeln("this.name = '${model.className}';");
        });
        w.writeln('}');
      }
      return;
    }

    w.writeln('constructor(init: {');
    w.indent(() {
      for (final field in allFields) {
        final type = mapper.map(field.type);
        // `| undefined` on a defaulted field: `fromJson` passes the key
        // explicitly when the wire has no value for it.
        final hasDefault = _defaultExpr(field) != null;
        final optional = field.type.nullable || hasDefault;
        w.writeln(
          '${field.name}${optional ? '?' : ''}: ${type.tsType}'
          '${hasDefault ? ' | undefined' : ''};',
        );
      }
    });
    w.writeln('}) {');
    w.indent(() {
      if (hasParent) {
        final inherited = allFields.length - ownFields.length;
        w.writeln(inherited == 0 ? 'super();' : 'super(init);');
      } else if (isException) {
        final message = allFields.where(
          (f) => f.name == 'message' && f.type.className == 'String',
        );
        w.writeln(
          message.isEmpty
              ? "super('${model.className}');"
              : message.first.type.nullable
                  ? "super(init.message ?? '${model.className}');"
                  : 'super(init.message);',
        );
      }
      // A field called `name` owns that slot; the class name must not
      // overwrite the value the server sent.
      if (isException && !allFields.any((f) => f.name == 'name')) {
        w.writeln("this.name = '${model.className}';");
      }
      for (final field in ownFields) {
        final fallback =
            _defaultExpr(field) ?? (field.type.nullable ? 'null' : null);
        w.writeln(
          fallback == null
              ? 'this.${field.name} = init.${field.name};'
              : 'this.${field.name} = init.${field.name} ?? $fallback;',
        );
      }
    });
    w.writeln('}');
  }

  /// The TypeScript expression for a field's model default, or `null` when
  /// it has none. A field with one is optional on the `init` bag, and an
  /// absent or `null` value on the wire falls back to it — the behaviour of
  /// the Dart client's generated constructor.
  String? _defaultExpr(SerializableModelFieldDefinition field) {
    final value = field.defaultModelValue;
    if (value == null) return null;
    final text = '$value';
    switch (field.type.defaultValueType) {
      case null:
        return null;
      case DefaultValueAllowedType.dateTime:
        return text == 'now' ? 'new Date()' : "new Date('$text')";
      case DefaultValueAllowedType.bool:
        return text == 'true' || text == 'false' ? text : null;
      case DefaultValueAllowedType.int:
        return int.tryParse(text)?.toString();
      case DefaultValueAllowedType.double:
        return double.tryParse(text)?.toString();
      // Already a quoted literal in the model file.
      case DefaultValueAllowedType.string:
      case DefaultValueAllowedType.uri:
        return text;
      case DefaultValueAllowedType.uuidValue:
        return switch (text) {
          'random' => 'r.randomUuidV4()',
          'random_v7' => 'r.randomUuidV7()',
          _ => text,
        };
      case DefaultValueAllowedType.bigInt:
        return "BigInt('$text')";
      case DefaultValueAllowedType.duration:
        return '${parseDuration(text).inMilliseconds}';
      case DefaultValueAllowedType.isEnum:
        return '${field.type.className}.${_enumMemberName(text)}';
    }
  }

  void _writeFromJson(
    TsWriter w,
    ClassDefinition model,
    List<SerializableModelFieldDefinition> allFields,
  ) {
    w.writeln(
      'static fromJson(json: Record<string, unknown>): ${model.className} {',
    );
    w.indent(() {
      if (allFields.isEmpty) {
        w.writeln('return new ${model.className}();');
        return;
      }
      w.writeln('return new ${model.className}({');
      w.indent(() {
        for (final field in allFields) {
          final type = mapper.map(field.type);
          final access = "json['${field.name}']";
          final decoded = type.fromJsonExpr(access);
          w.writeln(
            _defaultExpr(field) == null
                ? '${field.name}: $decoded,'
                // `undefined`, so the constructor applies the default.
                : '${field.name}: $access === undefined || $access === null '
                    '? undefined : $decoded,',
          );
        }
      });
      w.writeln('});');
    });
    w.writeln('}');
  }

  /// Mirrors Dart's `toJsonForProtocol`: `__className__` first, with this
  /// package's module prefix, and a `null` field left out rather than sent.
  void _writeToJson(
    TsWriter w,
    ClassDefinition model,
    List<SerializableModelFieldDefinition> allFields,
  ) {
    w.writeln('toJson(): Record<string, unknown> {');
    w.indent(() {
      w.writeln('return {');
      w.indent(() {
        w.writeln("__className__: '$classNamePrefix${model.className}',");
        for (final field in allFields) {
          final type = mapper.map(field.type);
          final value = type.toJsonExpr('this.${field.name}');
          w.writeln(
            field.type.nullable
                ? '...(this.${field.name} !== null && { ${field.name}: $value }),'
                : '${field.name}: $value,',
          );
        }
      });
      w.writeln('};');
    });
    w.writeln('}');
  }

  /// A nullable field is cleared by passing it as `null`; leaving the key
  /// out keeps the current value.
  void _writeCopyWith(
    TsWriter w,
    ClassDefinition model,
    List<SerializableModelFieldDefinition> allFields,
  ) {
    if (allFields.isEmpty) {
      w.writeln('copyWith(): ${model.className} {');
      w.indent(() => w.writeln('return new ${model.className}();'));
      w.writeln('}');
      return;
    }
    w.writeln('copyWith(partial: Partial<{');
    w.indent(() {
      for (final field in allFields) {
        w.writeln('${field.name}: ${mapper.map(field.type).tsType};');
      }
    });
    w.writeln('}>): ${model.className} {');
    w.indent(() {
      w.writeln('return new ${model.className}({');
      w.indent(() {
        for (final field in allFields) {
          w.writeln(
            field.type.nullable
                ? "${field.name}: '${field.name}' in partial "
                    '? (partial.${field.name} ?? null) : this.${field.name},'
                : '${field.name}: partial.${field.name} ?? this.${field.name},',
          );
        }
      });
      w.writeln('});');
    });
    w.writeln('}');
  }

  String _emitEnum(EnumDefinition model) {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..blankLine();

    w.docComment(model.documentation?.join('\n'));
    w.writeln('export enum ${model.className} {');
    w.indent(() {
      for (var i = 0; i < model.values.length; i++) {
        final v = model.values[i];
        w.docComment(v.documentation?.join('\n'));
        final memberName = _enumMemberName(v.name);
        w.writeln("$memberName = '${v.name}',");
      }
    });
    w.writeln('}');
    w.blankLine();

    final byIndex = model.serialized.name == 'byIndex';
    final namespaceName = '${model.className}Codec';
    w.writeln('export const $namespaceName = {');
    w.indent(() {
      if (byIndex) {
        w.writeln('toJson(value: ${model.className}): number {');
        w.indent(() {
          w.writeln('switch (value) {');
          w.indent(() {
            for (var i = 0; i < model.values.length; i++) {
              w.writeln(
                'case ${model.className}.${_enumMemberName(model.values[i].name)}: return $i;',
              );
            }
          });
          w.writeln('}');
        });
        w.writeln('},');
      } else {
        w.writeln(
          'toJson(value: ${model.className}): string { return value; },',
        );
      }
      w.blankLine();
      w.writeln('fromJson(json: unknown): ${model.className} {');
      w.indent(() {
        if (byIndex) {
          w.writeln(
            "if (typeof json !== 'number') throw new Error('Expected number for ${model.className}, got ' + typeof json);",
          );
          w.writeln('switch (json) {');
          w.indent(() {
            for (var i = 0; i < model.values.length; i++) {
              w.writeln(
                'case $i: return ${model.className}.${_enumMemberName(model.values[i].name)};',
              );
            }
            w.writeln(
              "default: throw new Error('Unknown ${model.className} index: ' + json);",
            );
          });
          w.writeln('}');
        } else {
          w.writeln(
            "if (typeof json !== 'string') throw new Error('Expected string for ${model.className}, got ' + typeof json);",
          );
          w.writeln('switch (json) {');
          w.indent(() {
            for (final v in model.values) {
              w.writeln(
                "case '${v.name}': return ${model.className}.${_enumMemberName(v.name)};",
              );
            }
            w.writeln(
              "default: throw new Error('Unknown ${model.className} name: ' + json);",
            );
          });
          w.writeln('}');
        }
      });
      w.writeln('},');
    });
    w.writeln('};');

    return _writeFile(_filenameOf(model.className), w.toString());
  }

  String _filenameOf(String className) => '${_filenameStemOf(className)}.ts';

  String _filenameStemOf(String className) {
    return className
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _enumMemberName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _writeFile(String filename, String content) {
    final destDir = Directory(p.join(outputDir.path, 'src', 'protocol'));
    destDir.createSync(recursive: true);
    final file = File(p.join(destDir.path, filename));
    file.writeAsStringSync(content);
    tracker.recordWrite(file);
    return filename;
  }
}
