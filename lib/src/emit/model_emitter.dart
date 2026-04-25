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
/// exception. Sealed hierarchies are out of scope for this pass; that
/// emitter is added in issue #6.
class ModelEmitter {
  ModelEmitter({
    required this.outputDir,
    required this.tracker,
    required this.mapper,
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;
  final TsTypeMapper mapper;

  /// Emits every non-sealed model in [models], plus a `protocol/index.ts`
  /// barrel re-exporting them all. Returns the list of emitted basenames
  /// (without the `.ts` suffix), in alphabetical order.
  List<String> emitAll(List<SerializableModelDefinition> models) {
    final emitted = <String>[];
    final classNames = <String>[];
    for (final model in models) {
      if (model is ModelClassDefinition) {
        if (model.isSealed) continue; // Issue #6.
        emitted.add(_emitClass(model));
        classNames.add(model.className);
      } else if (model is ExceptionClassDefinition) {
        emitted.add(_emitException(model));
        classNames.add(model.className);
      } else if (model is EnumDefinition) {
        emitted.add(_emitEnum(model));
        classNames.add(model.className);
      }
    }
    emitted.sort();
    _emitProtocolBarrel(emitted);
    return emitted;
  }

  void _emitProtocolBarrel(List<String> filenames) {
    final w = TsWriter()..writeRaw(_generatedHeader);
    for (final f in filenames) {
      final stem = f.replaceAll(RegExp(r'\.ts$'), '');
      w.writeln("export * from './$stem.js';");
    }
    _writeFile('index.ts', w.toString());
  }

  String _emitClass(ModelClassDefinition model) {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln(
        "import * as r from '../runtime/index.js';",
      )
      ..blankLine();

    final fields = model.fields
        .where((f) => f.shouldIncludeField(false /* serverCode */))
        .toList();

    w.docComment(model.documentation?.join('\n'));
    w.writeln('export class ${model.className} implements r.SerializableModel {');
    w.indent(() {
      // Public fields
      for (final field in fields) {
        w.docComment(field.documentation?.join('\n'));
        final type = mapper.map(field.type);
        w.writeln('${field.name}: ${type.tsType};');
      }
      w.blankLine();

      // Constructor
      w.writeln('constructor(init: {');
      w.indent(() {
        for (final field in fields) {
          final type = mapper.map(field.type);
          w.writeln('${field.name}: ${type.tsType};');
        }
      });
      w.writeln('}) {');
      w.indent(() {
        for (final field in fields) {
          w.writeln('this.${field.name} = init.${field.name};');
        }
      });
      w.writeln('}');
      w.blankLine();

      // fromJson
      w.writeln(
        'static fromJson(json: Record<string, unknown>): ${model.className} {',
      );
      w.indent(() {
        w.writeln('return new ${model.className}({');
        w.indent(() {
          for (final field in fields) {
            final type = mapper.map(field.type);
            final fromExpr =
                type.fromJsonExpr("json['${field.name}']");
            w.writeln('${field.name}: $fromExpr,');
          }
        });
        w.writeln('});');
      });
      w.writeln('}');
      w.blankLine();

      // toJson
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
              w.writeln('${field.name}: ${type.toJsonExpr('this.${field.name}')},');
            }
          }
        });
        w.writeln('};');
      });
      w.writeln('}');
      w.blankLine();

      // copyWith
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
            // Use `??` for non-nullable fields; for nullables, let the
            // explicit-null case fall through (caller must use partial).
            w.writeln(
              '${field.name}: partial.${field.name} ?? this.${field.name},',
            );
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
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';")
      ..blankLine();

    final fields = model.fields
        .where((f) => f.shouldIncludeField(false))
        .toList();

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
        // Best-effort: use `init.message` if there's a `message` field;
        // otherwise the class name as the Error message.
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
            w.writeln('${field.name}: ${type.toJsonExpr('this.${field.name}')},');
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
      // toJson
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
      // fromJson
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

  String _filenameOf(String className) {
    final snake = className
        .replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}')
        .replaceFirst(RegExp(r'^_'), '');
    return '$snake.ts';
  }

  String _enumMemberName(String name) {
    // TS enum members are valid identifiers; the value names from
    // Serverpod YAML are already valid Dart identifiers, so simple
    // capitalisation is safe.
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
