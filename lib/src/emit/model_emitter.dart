// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';

import 'generated_file_tracker.dart';
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
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;
  final TsTypeMapper mapper;

  /// Class names emitted as TS enums. Used for cross-file imports —
  /// enum imports also need to bring in `<Name>Codec`.
  Set<String> get _enumClassNames => mapper.enumClassNames;

  /// Class names emitted as sealed bases. Cross-file imports must also
  /// bring in `<Name>Base` (the dispatcher) when a field references the
  /// sealed type.
  Set<String> get _sealedClassNames => mapper.sealedClassNames;

  /// Every class name in the project — sealed bases, plain classes,
  /// exceptions, and enums. Populated by [emitAll] before any per-file
  /// emission so cross-file imports can be resolved.
  late Set<String> _allClassNames;

  /// Emits every model in [models], plus a `protocol/index.ts` barrel
  /// re-exporting them all. Sealed bases get an extra discriminated-union
  /// type alias and a static `fromJson` that dispatches on `__className__`.
  /// Returns the list of emitted filenames (with the `.ts` suffix),
  /// in alphabetical order — the barrel writer strips `.ts`.
  List<String> emitAll(List<SerializableModelDefinition> models) {
    _allClassNames = {for (final m in models) m.className};

    final modelClasses = models.whereType<ModelClassDefinition>().toList();
    final classByName = {for (final m in modelClasses) m.className: m};
    final subclassesBySealedAncestor =
        <String, List<ModelClassDefinition>>{};
    for (final m in modelClasses) {
      if (m.isSealed) continue;
      for (final ancestor in _sealedAncestorChain(m, classByName)) {
        subclassesBySealedAncestor
            .putIfAbsent(ancestor, () => [])
            .add(m);
      }
    }
    for (final list in subclassesBySealedAncestor.values) {
      list.sort((a, b) => a.className.compareTo(b.className));
    }

    final emitted = <String>[];
    for (final model in models) {
      if (model is ModelClassDefinition) {
        if (model.isSealed) {
          emitted.add(_emitSealedBase(
            model,
            subclassesBySealedAncestor[model.className] ?? const [],
          ));
        } else {
          emitted.add(_emitClass(
            model,
            sealedAncestor: _nearestSealedAncestorName(model, classByName),
          ));
        }
      } else if (model is ExceptionClassDefinition) {
        emitted.add(_emitException(model));
      } else if (model is EnumDefinition) {
        emitted.add(_emitEnum(model));
      }
    }
    emitted.sort();
    _emitProtocolBarrel(emitted);
    return emitted;
  }

  /// Walks up from [model], yielding every sealed ancestor (not including
  /// `model` itself) in order from nearest to outermost.
  Iterable<String> _sealedAncestorChain(
    ModelClassDefinition model,
    Map<String, ModelClassDefinition> byName,
  ) sync* {
    ModelClassDefinition? cursor = byName[model.parentClass?.className];
    while (cursor != null) {
      if (cursor.isSealed) yield cursor.className;
      cursor = byName[cursor.parentClass?.className];
    }
  }

  String? _nearestSealedAncestorName(
    ModelClassDefinition model,
    Map<String, ModelClassDefinition> byName,
  ) {
    return _sealedAncestorChain(model, byName).firstOrNull;
  }

  void _emitProtocolBarrel(List<String> filenames) {
    final w = TsWriter()..writeRaw(_generatedHeader);
    for (final f in filenames) {
      final stem = f.replaceAll(RegExp(r'\.ts$'), '');
      w.writeln("export * from './$stem.js';");
    }
    _writeFile('index.ts', w.toString());
  }

  /// Walks a [TypeDefinition] recursively (descending into generics)
  /// and yields every project-class name referenced. Skips primitives,
  /// collections (List/Set/Map/Future/Stream), and any self-reference.
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

  /// Builds the cross-file import lines for [ownClassName], based on
  /// the project types referenced in [fields] (plus an optional
  /// extra symbol like a sealed ancestor we always need to import).
  ///
  /// Each emitted line covers ONE other file in `protocol/` and
  /// brings in every required symbol from it (`Name`, `NameBase`,
  /// `NameCodec`) so a single file's worth of references collapses
  /// to one import statement.
  List<String> _buildImportLines({
    required String ownClassName,
    required List<SerializableModelFieldDefinition> fields,
    String? extraImport,
  }) {
    final referenced = <String>{};
    for (final f in fields) {
      _collectReferencedProjectTypes(f.type, referenced);
    }
    if (extraImport != null) referenced.add(extraImport);
    referenced.remove(ownClassName); // never self-import

    final sorted = referenced.toList()..sort();
    return [
      for (final ref in sorted)
        "import { ${_importSymbols(ref).join(', ')} } from './${_filenameStemOf(ref)}.js';",
    ];
  }

  /// Symbols we need to bring in from the file that defines [className].
  /// Mirrors what `TsTypeMapper` emits at the use site:
  ///   plain class       → just `Name`
  ///   exception         → just `Name`
  ///   sealed base       → `Name` (the union alias) + `NameBase` (dispatcher)
  ///   enum              → `Name` + `NameCodec`
  List<String> _importSymbols(String className) {
    if (_enumClassNames.contains(className)) {
      return [className, '${className}Codec'];
    }
    if (_sealedClassNames.contains(className)) {
      return [className, '${className}Base'];
    }
    return [className];
  }

  String _emitSealedBase(
    ModelClassDefinition model,
    List<ModelClassDefinition> subclasses,
  ) {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';");
    // Subclass imports are *value* imports — the switch dispatcher
    // calls `Sub.fromJson(...)` so we need the runtime symbol.
    for (final sub in subclasses) {
      w.writeln(
        "import { ${sub.className} } from './${_filenameStemOf(sub.className)}.js';",
      );
    }
    w.blankLine();

    final union = subclasses.isEmpty
        ? 'never'
        : subclasses.map((s) => s.className).join(' | ');
    w.docComment(model.documentation?.join('\n'));
    w.writeln('export type ${model.className} = $union;');
    w.blankLine();

    w.writeln(
      'export abstract class ${model.className}Base implements r.SerializableModel {',
    );
    w.indent(() {
      w.writeln('abstract toJson(): Record<string, unknown>;');
      w.blankLine();
      w.writeln(
        'static fromJson(json: Record<string, unknown>): ${model.className} {',
      );
      w.indent(() {
        w.writeln(
          "const className = json['__className__'] as string | undefined;",
        );
        w.writeln('switch (className) {');
        w.indent(() {
          for (final sub in subclasses) {
            w.writeln(
              "case '${sub.className}': return ${sub.className}.fromJson(json);",
            );
          }
          w.writeln(
            "default: throw new Error('Unknown ${model.className} subtype: ' + className);",
          );
        });
        w.writeln('}');
      });
      w.writeln('}');
    });
    w.writeln('}');

    return _writeFile(_filenameOf(model.className), w.toString());
  }

  String _emitClass(
    ModelClassDefinition model, {
    String? sealedAncestor,
  }) {
    final fields = model.fields
        .where((f) => f.shouldIncludeField(false /* serverCode */))
        .toList();

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';");
    final imports = _buildImportLines(
      ownClassName: model.className,
      fields: fields,
      extraImport: sealedAncestor,
    );
    for (final line in imports) {
      w.writeln(line);
    }
    w.blankLine();

    w.docComment(model.documentation?.join('\n'));
    if (sealedAncestor != null) {
      w.writeln(
        'export class ${model.className} extends ${sealedAncestor}Base implements r.SerializableModel {',
      );
    } else {
      w.writeln(
        'export class ${model.className} implements r.SerializableModel {',
      );
    }
    w.indent(() {
      for (final field in fields) {
        w.docComment(field.documentation?.join('\n'));
        final type = mapper.map(field.type);
        w.writeln('${field.name}: ${type.tsType};');
      }
      w.blankLine();

      w.writeln('constructor(init: {');
      w.indent(() {
        for (final field in fields) {
          final type = mapper.map(field.type);
          w.writeln('${field.name}: ${type.tsType};');
        }
      });
      w.writeln('}) {');
      w.indent(() {
        if (sealedAncestor != null) w.writeln('super();');
        for (final field in fields) {
          w.writeln('this.${field.name} = init.${field.name};');
        }
      });
      w.writeln('}');
      w.blankLine();

      w.writeln(
        'static fromJson(json: Record<string, unknown>): ${model.className} {',
      );
      w.indent(() {
        w.writeln('return new ${model.className}({');
        w.indent(() {
          for (final field in fields) {
            final type = mapper.map(field.type);
            final fromExpr = type.fromJsonExpr("json['${field.name}']");
            w.writeln('${field.name}: $fromExpr,');
          }
        });
        w.writeln('});');
      });
      w.writeln('}');
      w.blankLine();

      w.writeln('toJson(): Record<string, unknown> {');
      w.indent(() {
        w.writeln('return {');
        w.indent(() {
          w.writeln("__className__: '${model.className}',");
          for (final field in fields) {
            final type = mapper.map(field.type);
            if (field.type.nullable) {
              w.writeln(
                '...(this.${field.name} !== null && '
                '{ ${field.name}: ${type.toJsonExpr('this.${field.name}')} }),',
              );
            } else {
              w.writeln(
                '${field.name}: ${type.toJsonExpr('this.${field.name}')},',
              );
            }
          }
        });
        w.writeln('};');
      });
      w.writeln('}');
      w.blankLine();

      w.writeln('copyWith(partial: Partial<{');
      w.indent(() {
        for (final field in fields) {
          final type = mapper.map(field.type);
          w.writeln('${field.name}: ${type.tsType};');
        }
      });
      w.writeln('}>): ${model.className} {');
      w.indent(() {
        w.writeln('return new ${model.className}({');
        w.indent(() {
          for (final field in fields) {
            if (field.type.nullable) {
              w.writeln(
                '${field.name}: '
                "'${field.name}' in partial "
                '? (partial.${field.name} ?? null) '
                ': this.${field.name},',
              );
            } else {
              w.writeln(
                '${field.name}: partial.${field.name} ?? this.${field.name},',
              );
            }
          }
        });
        w.writeln('});');
      });
      w.writeln('}');
    });
    w.writeln('}');

    return _writeFile(_filenameOf(model.className), w.toString());
  }

  String _emitException(ExceptionClassDefinition model) {
    final fields = model.fields
        .where((f) => f.shouldIncludeField(false))
        .toList();

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';");
    final imports = _buildImportLines(
      ownClassName: model.className,
      fields: fields,
    );
    for (final line in imports) {
      w.writeln(line);
    }
    w.blankLine();

    w.docComment(model.documentation?.join('\n'));
    w.writeln(
      'export class ${model.className} extends Error implements r.SerializableException {',
    );
    w.indent(() {
      for (final field in fields) {
        w.docComment(field.documentation?.join('\n'));
        final type = mapper.map(field.type);
        w.writeln('readonly ${field.name}: ${type.tsType};');
      }
      w.blankLine();

      w.writeln('constructor(init: {');
      w.indent(() {
        for (final field in fields) {
          final type = mapper.map(field.type);
          w.writeln('${field.name}: ${type.tsType};');
        }
      });
      w.writeln('}) {');
      w.indent(() {
        final hasMsg = fields.any((f) => f.name == 'message');
        if (hasMsg) {
          w.writeln('super(init.message as string);');
        } else {
          w.writeln("super('${model.className}');");
        }
        w.writeln("this.name = '${model.className}';");
        for (final field in fields) {
          w.writeln('this.${field.name} = init.${field.name};');
        }
      });
      w.writeln('}');
      w.blankLine();

      w.writeln(
        'static fromJson(json: Record<string, unknown>): ${model.className} {',
      );
      w.indent(() {
        w.writeln('return new ${model.className}({');
        w.indent(() {
          for (final field in fields) {
            final type = mapper.map(field.type);
            w.writeln(
              '${field.name}: ${type.fromJsonExpr("json['${field.name}']")},',
            );
          }
        });
        w.writeln('});');
      });
      w.writeln('}');
      w.blankLine();

      w.writeln('toJson(): Record<string, unknown> {');
      w.indent(() {
        w.writeln('return {');
        w.indent(() {
          w.writeln("__className__: '${model.className}',");
          for (final field in fields) {
            final type = mapper.map(field.type);
            w.writeln(
              '${field.name}: ${type.toJsonExpr('this.${field.name}')},',
            );
          }
        });
        w.writeln('};');
      });
      w.writeln('}');
    });
    w.writeln('}');

    return _writeFile(_filenameOf(model.className), w.toString());
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
