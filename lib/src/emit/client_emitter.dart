// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart'
    show EndpointDefinition;
import 'package:serverpod_cli/src/config/config.dart' show ModuleConfig;
import 'package:yaml/yaml.dart';

import '../discovery/module_class_index.dart';
import 'generated_file_tracker.dart';
import 'module_import_lines.dart';
import 'ts_writer.dart';

const _generatedHeader = '''
// AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND
// To regenerate, run: dart run serverpod_typescript_bridge generate
''';

/// Emits the top-level entry point for the generated TypeScript client
/// — either a `Client extends ServerpodClientShared` (when the source
/// project is `type: server`) or a `[Nickname]Caller extends
/// ModuleEndpointCaller` (when it is `type: module`).
///
/// Also emits the project `Protocol` extends `SerializationManager`
/// with the per-class `deserialize`/`deserializeByClassName` switch.
class ClientEmitter {
  ClientEmitter({
    required this.outputDir,
    required this.tracker,
    required this.config,
    this.moduleIndex,
    this.referencedModuleClassNames = const {},
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;
  final GeneratorConfig config;

  /// Index of every class defined in modules this project (transitively)
  /// depends on. Null for projects with no modules.
  final ModuleClassIndex? moduleIndex;

  /// The subset of [moduleIndex] class names that this project actually
  /// references. Drives the cross-package `import` lines emitted at the
  /// top of `protocol.ts` and the extra cases in
  /// `deserializeByClassName`. The pipeline has already walked the IR
  /// to build this set, so we don't recompute it here.
  final Set<String> referencedModuleClassNames;

  bool get _isModule => config.type == PackageType.module;

  void emit({
    required List<EndpointDefinition> endpoints,
    required List<SerializableModelDefinition> models,
  }) {
    if (_isModule) {
      _emitModuleCaller(endpoints);
    } else {
      _emitClient(endpoints);
    }
    _emitProtocol(models);
  }

  void _emitClient(List<EndpointDefinition> endpoints) {
    final concrete = endpoints.where((e) => !e.isAbstract).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    final modules = config.modulesDependent;

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

    if (modules.isNotEmpty) {
      _emitModulesClass(w, modules);
      w.blankLine();
    }

    w.writeln('export class Client extends r.ServerpodClientShared {');
    w.indent(() {
      for (final ep in concrete) {
        w.writeln('readonly ${ep.name}: Endpoint${_pascal(ep.name)};');
      }
      if (modules.isNotEmpty) {
        w.writeln('readonly modules: Modules;');
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
        if (modules.isNotEmpty) {
          w.writeln('this.modules = new Modules(this);');
        }
      });
      w.writeln('}');
    });
    w.writeln('}');

    _writeRoot('client.ts', w.toString());
  }

  /// Generates a small wrapper exposing one Caller-shaped field per
  /// module the project declares. Type-safe, real Caller wiring is
  /// already covered by the protocol-switch dispatch — module classes
  /// resolve through cross-package imports — so we keep this wrapper
  /// as a `unknown`-typed convenience until callers actually request
  /// a typed namespace surface (tracked by the `Modules.<nickname>`
  /// stub below).
  void _emitModulesClass(TsWriter w, List<ModuleConfig> modules) {
    w.writeln('/**');
    w.writeln(' * Per-module callers, instantiated lazily by [Client].');
    w.writeln(' *');
    w.writeln(' * Each field is typed as `unknown` for now; cross-package');
    w.writeln(' * deserialization already routes through the project');
    w.writeln(' * Protocol switch, so consumers can reach module types');
    w.writeln(' * directly via the generated module client packages.');
    w.writeln(' */');
    w.writeln('export class Modules {');
    w.indent(() {
      for (final m in modules) {
        w.writeln('readonly ${m.nickname}: unknown;');
      }
      w.blankLine();
      w.writeln('constructor(_parent: r.EndpointCaller) {');
      w.indent(() {
        for (final m in modules) {
          w.writeln('this.${m.nickname} = undefined;');
        }
      });
      w.writeln('}');
    });
    w.writeln('}');
  }

  void _emitModuleCaller(List<EndpointDefinition> endpoints) {
    final concrete = endpoints.where((e) => !e.isAbstract).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final nickname = _readSelfNickname();
    final callerClass = '${_pascal(nickname)}Caller';

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

    w.writeln(
      'export class $callerClass extends r.ModuleEndpointCaller {',
    );
    w.indent(() {
      for (final ep in concrete) {
        w.writeln('readonly ${ep.name}: Endpoint${_pascal(ep.name)};');
      }
      w.writeln('readonly protocol: Protocol;');
      w.blankLine();

      w.writeln('constructor(parent: r.EndpointCaller) {');
      w.indent(() {
        w.writeln('super(parent);');
        w.writeln('this.protocol = new Protocol();');
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
    // Compute the `__className__` prefix for this project's models.
    // For modules the protocol emits class names as `<nickname>.<Class>`
    // on the wire; the consumer's Protocol must recognise both the
    // bare and prefixed forms so server/client agree across modules.
    final ownPrefix = _isModule ? _readSelfNickname() : null;

    final entries = <_ClassEntry>[
      for (final m in models) ..._projectEntriesFor(m),
      ..._moduleEntries(),
    ]..sort((a, b) => a.name.compareTo(b.name));
    final moduleImportLines = _moduleImportLines();

    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from './runtime/index.js';")
      ..writeln("import * as p from './protocol/index.js';");
    for (final line in moduleImportLines) {
      w.writeln(line);
    }
    w.blankLine();

    w.writeln('export class Protocol extends r.SerializationManager {');
    w.indent(() {
      w.writeln(
        'override deserialize<T>(json: unknown, _t?: new (...args: never[]) => T): T {',
      );
      w.indent(() {
        w.writeln('const decoded = this.deserializeByClassName(json);');
        w.writeln('if (decoded !== undefined) return decoded as T;');
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
        w.writeln('const obj = envelope as Record<string, unknown>;');
        w.writeln(
          "const raw = (obj['className'] ?? obj['__className__']) as string | undefined;",
        );
        // Strip an optional module prefix so a server's `auth.User`
        // dispatches to the same case label as the bare `User`.
        w.writeln(
          "const className = raw === undefined ? undefined : raw.includes('.') ? raw.split('.').pop() : raw;",
        );
        w.writeln(
          "const data = obj['data'] !== undefined ? obj['data'] as Record<string, unknown> : obj;",
        );
        w.writeln('switch (className) {');
        w.indent(() {
          for (final e in entries) {
            w.writeln("case '${e.name}': return ${e.receiver}.fromJson(data);");
          }
          w.writeln('default: return undefined;');
        });
        w.writeln('}');
      });
      w.writeln('}');
    });
    w.writeln('}');

    if (ownPrefix != null) {
      w.blankLine();
      w.writeln(
        '/** Wire-prefix this module emits on every `__className__`. */',
      );
      w.writeln("export const modulePrefix = '$ownPrefix';");
    }

    _writeRoot('protocol.ts', w.toString());
  }

  void _writeRoot(String filename, String content) {
    final destDir = Directory(p.join(outputDir.path, 'src'));
    destDir.createSync(recursive: true);
    final file = File(p.join(destDir.path, filename));
    file.writeAsStringSync(content);
    tracker.recordWrite(file);
  }

  String _pascal(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _filenameStem(String name) =>
      name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  /// Builds the dispatch entries for a single project-defined model.
  /// Returns an empty list for unsupported model kinds so the caller
  /// can splat results unconditionally.
  List<_ClassEntry> _projectEntriesFor(SerializableModelDefinition m) {
    if (m is ModelClassDefinition) {
      return [
        _ClassEntry(
          name: m.className,
          receiver: _receiverFor(
            name: m.className,
            prefix: 'p.',
            isEnum: false,
            isSealed: m.isSealed,
          ),
        ),
      ];
    }
    if (m is ExceptionClassDefinition) {
      return [
        _ClassEntry(
          name: m.className,
          receiver: _receiverFor(
            name: m.className,
            prefix: 'p.',
            isEnum: false,
            isSealed: false,
          ),
        ),
      ];
    }
    if (m is EnumDefinition) {
      return [
        _ClassEntry(
          name: m.className,
          receiver: _receiverFor(
            name: m.className,
            prefix: 'p.',
            isEnum: true,
            isSealed: false,
          ),
        ),
      ];
    }
    return const [];
  }

  /// Dispatch entries for every referenced module-defined class —
  /// imported under bare names so calling `<Name>.fromJson(...)`
  /// resolves through the matching `import { Name } from '<pkg>'` line.
  List<_ClassEntry> _moduleEntries() {
    final mi = moduleIndex;
    if (mi == null || referencedModuleClassNames.isEmpty) return const [];
    return [
      for (final name in referencedModuleClassNames)
        if (mi.layoutFor(name) != null)
          _ClassEntry(
            name: name,
            receiver: _receiverFor(
              name: name,
              prefix: '',
              isEnum: mi.isEnum(name),
              isSealed: mi.isSealed(name),
            ),
          ),
    ];
  }

  /// `import { ... } from '<pkg>';` lines for every module package the
  /// protocol switch dispatches into. Empty when there are no module
  /// references — keeps the no-modules emission byte-identical to v0.1.
  List<String> _moduleImportLines() {
    final mi = moduleIndex;
    if (mi == null) return const [];
    return ModuleImportLines(mi).forClassNames(referencedModuleClassNames);
  }

  /// Single source of truth for "what symbol do I call `.fromJson` on
  /// for a given name?". Used by both project and module entry paths.
  String _receiverFor({
    required String name,
    required String prefix,
    required bool isEnum,
    required bool isSealed,
  }) {
    if (isEnum) return '$prefix${name}Codec';
    if (isSealed) return '$prefix${name}Base';
    return '$prefix$name';
  }

  /// Reads the top-level `nickname:` key from this project's
  /// `config/generator.yaml`. Required for module-type projects so the
  /// emitter can name the Caller and the wire prefix correctly.
  String _readSelfNickname() {
    final genFile = File(p.joinAll([
      ...config.serverPackageDirectoryPathParts,
      'config',
      'generator.yaml',
    ]));
    if (!genFile.existsSync()) {
      throw StateError(
        'Module project ${config.name} has no config/generator.yaml. '
        'Cannot determine module nickname.',
      );
    }
    final yaml = loadYaml(genFile.readAsStringSync());
    if (yaml is! YamlMap || yaml['nickname'] is! String) {
      throw StateError(
        'Module project ${config.name}: generator.yaml is missing a top-level '
        '`nickname:` key. Required for module-type projects.',
      );
    }
    return yaml['nickname'] as String;
  }
}

class _ClassEntry {
  _ClassEntry({required this.name, required this.receiver});

  /// The wire-form `__className__` (after stripping any `module.` prefix).
  final String name;

  /// The full TS expression to call `.fromJson(...)` on, including any
  /// import-alias prefix (`p.` for project-local, bare for module).
  final String receiver;
}
