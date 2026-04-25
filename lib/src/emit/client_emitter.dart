// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart'
    show EndpointDefinition;

import 'generated_file_tracker.dart';
import 'ts_writer.dart';

const _generatedHeader = '''
// AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND
// To regenerate, run: dart run serverpod_typescript_bridge generate
''';

/// Emits the top-level `Client` class and the project `Protocol` class.
///
/// `Client` extends `ServerpodClientShared` and exposes one field per
/// top-level endpoint. `Protocol` extends `SerializationManager` and
/// owns the per-class `deserialize`/`deserializeByClassName` switch.
class ClientEmitter {
  ClientEmitter({
    required this.outputDir,
    required this.tracker,
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;

  void emit({
    required List<EndpointDefinition> endpoints,
    required List<SerializableModelDefinition> models,
  }) {
    _emitClient(endpoints);
    _emitProtocol(models);
  }

  void _emitClient(List<EndpointDefinition> endpoints) {
    final concrete = endpoints.where((e) => !e.isAbstract).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from './runtime/index.js';")
      ..writeln("import { Protocol } from './protocol.js';");
    for (final ep in concrete) {
      w.writeln(
        "import { Endpoint${_pascal(ep.name)} } from './endpoints/endpoint_${_filenameStem(ep.name)}.js';",
      );
    }
    w.blankLine();

    w.writeln('export class Client extends r.ServerpodClientShared {');
    w.indent(() {
      for (final ep in concrete) {
        w.writeln(
          'readonly ${ep.name}: Endpoint${_pascal(ep.name)};',
        );
      }
      w.blankLine();

      w.writeln('constructor(host: string, options: r.ClientOptions = {}) {');
      w.indent(() {
        w.writeln('super(host, new Protocol(), options);');
        for (final ep in concrete) {
          w.writeln(
            'this.${ep.name} = new Endpoint${_pascal(ep.name)}(this);',
          );
        }
      });
      w.writeln('}');
    });
    w.writeln('}');

    _writeRoot('client.ts', w.toString());
  }

  void _emitProtocol(List<SerializableModelDefinition> models) {
    final classNames = <String>[];
    for (final m in models) {
      if (m is ModelClassDefinition && m.isSealed) {
        // Sealed bases are dispatched via <Name>Base.fromJson.
        classNames.add(m.className);
      } else if (m is ModelClassDefinition) {
        classNames.add(m.className);
      } else if (m is ExceptionClassDefinition) {
        classNames.add(m.className);
      } else if (m is EnumDefinition) {
        // Enums use ${Name}Codec, not <Name>.fromJson.
        classNames.add('${m.className}Codec');
      }
    }
    classNames.sort();

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from './runtime/index.js';")
      ..writeln("import * as p from './protocol/index.js';")
      ..blankLine();

    w.writeln('export class Protocol extends r.SerializationManager {');
    w.indent(() {
      // deserialize<T> — dispatches by an optional `t` class reference.
      // Most callers pass the className via fromJson directly, so this
      // is a thin wrapper for legacy-style polymorphic decode paths.
      w.writeln(
        'override deserialize<T>(json: unknown, _t?: new (...args: never[]) => T): T {',
      );
      w.indent(() {
        w.writeln(
          'const decoded = this.deserializeByClassName(json);',
        );
        w.writeln(
          'if (decoded !== undefined) return decoded as T;',
        );
        w.writeln('return json as T;');
      });
      w.writeln('}');
      w.blankLine();

      w.writeln(
        'override deserializeByClassName(envelope: unknown): unknown | undefined {',
      );
      w.indent(() {
        w.writeln(
          "if (envelope === null || typeof envelope !== 'object') return undefined;",
        );
        w.writeln(
          "const obj = envelope as Record<string, unknown>;",
        );
        w.writeln(
          "const className = (obj['className'] ?? obj['__className__']) as string | undefined;",
        );
        w.writeln(
          "const data = obj['data'] !== undefined ? obj['data'] as Record<string, unknown> : obj;",
        );
        w.writeln('switch (className) {');
        w.indent(() {
          for (final name in classNames) {
            // Sealed bases live as `<Name>Base` in the protocol barrel.
            // For non-sealed/exception/enum the bare name works.
            final isSealed = models
                .whereType<ModelClassDefinition>()
                .any((m) => m.isSealed && m.className == name);
            final receiver = isSealed ? '${name}Base' : name;
            w.writeln(
              "case '$name': return p.$receiver.fromJson(data);",
            );
          }
          w.writeln('default: return undefined;');
        });
        w.writeln('}');
      });
      w.writeln('}');
    });
    w.writeln('}');

    _writeRoot('protocol.ts', w.toString());
  }

  void _writeRoot(String filename, String content) {
    final destDir = Directory(p.join(outputDir.path, 'src'));
    destDir.createSync(recursive: true);
    final file = File(p.join(destDir.path, filename));
    file.writeAsStringSync(content);
    tracker.recordWrite(file);
  }

  String _pascal(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _filenameStem(String name) =>
      name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
}
