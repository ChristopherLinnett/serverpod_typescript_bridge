// `StatefulAnalyzer`, `ModelHelper`, `CodeGenerationCollector`, and the
// experimental-features singleton are not re-exported by the public
// `serverpod_cli/analyzer.dart`, so we reach into `src/`. Serverpod's own
// internal generators (e.g. `EndpointDescriptionGenerator`) do the same;
// the IR shape is stable across patch releases. The dependency is pinned
// to a minor range in pubspec.yaml.
//
// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart'
    show EndpointDefinition;
import 'package:serverpod_cli/src/analyzer/models/stateful_analyzer.dart';
import 'package:serverpod_cli/src/config/config.dart' show ModuleConfig;
import 'package:serverpod_cli/src/config/experimental_feature.dart';
import 'package:serverpod_cli/src/config/serverpod_feature.dart';
import 'package:serverpod_cli/src/generator/code_generation_collector.dart';
import 'package:serverpod_cli/src/util/model_helper.dart';
import 'package:serverpod_shared/serverpod_shared.dart' show DatabaseDialect;
import 'package:yaml/yaml.dart';

/// Builds a [ProtocolDefinition] for a Serverpod server package by reusing
/// `serverpod_cli`'s own analyzers — same IR, no parser drift.
class ProtocolLoader {
  /// Loads the IR for the given [serverDirectory] via `GeneratorConfig.load`.
  /// Use this for the user's own server package, where the sibling Dart
  /// client package lives at the path declared in `config/generator.yaml`.
  ///
  /// Throws [ProtocolLoaderException] if the analyzer reports severe
  /// errors (malformed YAML, invalid endpoint signature, etc.).
  static Future<ProtocolDefinition> load(Directory serverDirectory) async {
    _ensureExperimentalFeaturesInitialised();
    final config = await _loadConfig(serverDirectory);
    return _runAnalyses(config);
  }

  /// Loads the IR for a Serverpod *module* whose source typically lives
  /// under the user's pub-cache. `GeneratorConfig.load` would fail here:
  /// it validates that the dart client sibling package's `pubspec.yaml`
  /// exists at `client_package_path`, but pub-cache modules ship the
  /// server package alone — the client is a separate hosted package.
  ///
  /// This builds a minimal [GeneratorConfig] from the module's own
  /// `config/generator.yaml` + `pubspec.yaml` instead, populating only
  /// the fields the IR analyzers actually consult.
  ///
  /// [knownModules] is the full list of modules the parent project
  /// discovered. It's used to resolve cross-module references inside
  /// the loaded module — e.g. `serverpod_auth_idp_server` declares
  /// `module:auth:AuthUser` references and the `auth` nickname must
  /// resolve to `serverpod_auth_core_server`'s server-pkg dir or the
  /// analyzer fails with `The referenced module "auth" is not found`.
  static Future<ProtocolDefinition> loadForModule(
    Directory serverDirectory, {
    List<ModuleDependency> knownModules = const [],
  }) async {
    _ensureExperimentalFeaturesInitialised();
    final config = _synthesizeModuleConfig(
      serverDirectory,
      knownModules: knownModules,
    );
    return _runAnalyses(config);
  }

  /// Runs the same model + endpoint analyses as [load] / [loadForModule]
  /// but against an already-built [config]. Useful when the caller has
  /// synthesised a config out-of-band (e.g. [GenerationPipeline.run] in
  /// module mode) and wants to reuse it for both emission AND IR loading
  /// — a single read of `pubspec.yaml` + `config/generator.yaml`, no
  /// risk of the two halves seeing different on-disk state.
  static Future<ProtocolDefinition> loadFromConfig(
    GeneratorConfig config,
  ) async {
    _ensureExperimentalFeaturesInitialised();
    return _runAnalyses(config);
  }

  static Future<ProtocolDefinition> _runAnalyses(GeneratorConfig config) async {
    final models = await _runModelAnalysis(config);
    final endpoints = await _runEndpointAnalysis(config);
    return ProtocolDefinition(
      endpoints: endpoints,
      models: models,
      futureCalls: const [],
    );
  }

  /// Public sibling of [loadForModule]: builds the same synthesised
  /// [GeneratorConfig] for callers that need the config object directly
  /// (e.g. the generation pipeline, which threads it into emitters).
  static GeneratorConfig synthesizeModuleConfig(
    Directory serverDirectory, {
    List<ModuleDependency> knownModules = const [],
  }) =>
      _synthesizeModuleConfig(serverDirectory, knownModules: knownModules);

  /// Reads the module's `pubspec.yaml` (for the package name) and
  /// `config/generator.yaml` (for the client-path declaration) and
  /// builds a [GeneratorConfig] without any cross-package validation.
  ///
  /// The dart client fields are placeholders — we never emit a dart
  /// client for the module, so they're never read. The `modules:`
  /// list is populated from the module's own `modules:` block in
  /// `generator.yaml`, cross-referenced against [knownModules].
  static GeneratorConfig _synthesizeModuleConfig(
    Directory serverDirectory, {
    required List<ModuleDependency> knownModules,
  }) {
    final dirParts = p.split(serverDirectory.path);
    final pubspecName = _readPubspecName(serverDirectory);
    final generatorYaml = _readGeneratorYaml(serverDirectory);
    final clientPath = generatorYaml['client_package_path'] is String
        ? generatorYaml['client_package_path'] as String
        : '../${pubspecName}_client';

    return GeneratorConfig(
      name: pubspecName,
      type: PackageType.module,
      serverPackage: pubspecName,
      dartClientPackage: '${pubspecName}_client',
      dartClientDependsOnServiceClient: false,
      serverPackageDirectoryPathParts: dirParts,
      sharedModelsSourcePathsParts: const {},
      relativeDartClientPackagePathParts: p.split(clientPath),
      modules: _moduleDependenciesFor(generatorYaml, knownModules),
      extraClasses: const [],
      enabledFeatures: ServerpodFeature.values
          .where((f) => f.defaultValue)
          .toList(),
      databaseDialect: DatabaseDialect.postgres,
    );
  }

  /// Builds [ModuleConfig] entries for every module this module
  /// declares as a dep in its own `generator.yaml`. The [knownModules]
  /// list (every Serverpod module the PARENT project discovered)
  /// supplies the on-disk path each entry needs.
  ///
  /// Modules referenced in generator.yaml but NOT in [knownModules]
  /// are skipped silently — the analyzer will surface the missing
  /// reference if the module's source actually depends on them.
  static List<ModuleConfig> _moduleDependenciesFor(
    YamlMap generatorYaml,
    List<ModuleDependency> knownModules,
  ) {
    final modulesNode = generatorYaml['modules'];
    if (modulesNode is! YamlMap) return const [];

    // Index discovered modules by their `<name-without-_server>`,
    // matching how generator.yaml's `modules:` block names them.
    final knownByBase = <String, ModuleDependency>{
      for (final m in knownModules) _stripServerSuffix(m.dartPkgName): m,
    };

    final out = <ModuleConfig>[];
    for (final entry in modulesNode.entries) {
      final base = entry.key;
      final spec = entry.value;
      if (base is! String) continue;
      final known = knownByBase[base];
      if (known == null) continue;
      final nickname = (spec is YamlMap && spec['nickname'] is String)
          ? spec['nickname'] as String
          : known.nickname;
      out.add(ModuleConfig(
        type: PackageType.module,
        name: base,
        nickname: nickname,
        migrationVersions: const [],
        serverPackageDirectoryPathParts: p.split(known.serverPkgPath),
      ));
    }
    return out;
  }

  static String _stripServerSuffix(String pkg) =>
      pkg.endsWith('_server') ? pkg.substring(0, pkg.length - '_server'.length) : pkg;

  static String _readPubspecName(Directory serverDirectory) {
    final pubspec = File(p.join(serverDirectory.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw ProtocolLoaderException._(
        ProtocolLoaderPhase.config,
        'Module package at ${serverDirectory.path} has no pubspec.yaml. '
        'Cannot determine module name.',
      );
    }
    final yaml = _safeLoadYaml(
      pubspec,
      context: 'module pubspec.yaml',
    );
    if (yaml is! YamlMap || yaml['name'] is! String) {
      throw ProtocolLoaderException._(
        ProtocolLoaderPhase.config,
        'Module pubspec.yaml at ${pubspec.path} is missing a top-level '
        '`name:` field.',
      );
    }
    return yaml['name'] as String;
  }

  static YamlMap _readGeneratorYaml(Directory serverDirectory) {
    final file = File(
      p.join(serverDirectory.path, 'config', 'generator.yaml'),
    );
    if (!file.existsSync()) return YamlMap();
    final yaml = _safeLoadYaml(
      file,
      context: 'module config/generator.yaml',
    );
    return yaml is YamlMap ? yaml : YamlMap();
  }

  /// Reads + parses a YAML file, translating any `YamlException` /
  /// `FileSystemException` / `FormatException` into a typed
  /// [ProtocolLoaderException] with [ProtocolLoaderPhase.config] so the
  /// CLI surfaces a consistent error class instead of leaking raw
  /// parser exceptions. Stack trace preserved via
  /// [Error.throwWithStackTrace].
  static dynamic _safeLoadYaml(File file, {required String context}) {
    try {
      return loadYaml(file.readAsStringSync());
    } on YamlException catch (e, st) {
      Error.throwWithStackTrace(
        ProtocolLoaderException._(
          ProtocolLoaderPhase.config,
          'Failed to parse $context at ${file.path}: ${e.message}',
        ),
        st,
      );
    } on FileSystemException catch (e, st) {
      Error.throwWithStackTrace(
        ProtocolLoaderException._(
          ProtocolLoaderPhase.config,
          'Failed to read $context at ${file.path}: ${e.message}',
        ),
        st,
      );
    } on FormatException catch (e, st) {
      Error.throwWithStackTrace(
        ProtocolLoaderException._(
          ProtocolLoaderPhase.config,
          'Failed to parse $context at ${file.path}: ${e.message}',
        ),
        st,
      );
    }
  }

  static bool _experimentalFeaturesInitialised = false;

  /// `GeneratorConfig.load` reads the experimental-features singleton at
  /// CLI start time. We never enable any flags, but the singleton must
  /// exist or the load will fail with a `LateInitializationError`. A
  /// local flag avoids relying on internal Dart error types we can't
  /// catch by name.
  static void _ensureExperimentalFeaturesInitialised() {
    if (_experimentalFeaturesInitialised) return;
    CommandLineExperimentalFeatures.initialize(const []);
    _experimentalFeaturesInitialised = true;
  }

  static Future<GeneratorConfig> _loadConfig(Directory serverDirectory) async {
    try {
      return await GeneratorConfig.load(
        serverRootDir: serverDirectory.path,
        interactive: false,
      );
    } catch (e, st) {
      // Preserve the original stack trace so config-load failures
      // remain debuggable; we only translate the exception type.
      Error.throwWithStackTrace(
        ProtocolLoaderException._(
          ProtocolLoaderPhase.config,
          'Failed to load GeneratorConfig from ${serverDirectory.path}: $e',
        ),
        st,
      );
    }
  }

  static Future<List<SerializableModelDefinition>> _runModelAnalysis(
    GeneratorConfig config,
  ) async {
    final collector = CodeGenerationCollector();
    final yamlModels = await ModelHelper.loadProjectYamlModelsFromDisk(config);
    final analyzer = StatefulAnalyzer(
      config,
      yamlModels,
      (uri, collected) => collector.addErrors(collected.errors),
    );
    final models = analyzer.validateAll();
    if (CodeAnalysisCollector.containsSevereErrors(collector.errors)) {
      throw ProtocolLoaderException._(
        ProtocolLoaderPhase.models,
        _formatErrors('Model analysis', collector),
      );
    }
    return models;
  }

  static Future<List<EndpointDefinition>> _runEndpointAnalysis(
    GeneratorConfig config,
  ) async {
    final libDir = Directory(p.joinAll(config.libSourcePathParts));
    final endpointsAnalyzer = EndpointsAnalyzer(libDir);
    final collector = CodeGenerationCollector();
    final endpoints = await endpointsAnalyzer.analyze(collector: collector);
    if (CodeAnalysisCollector.containsSevereErrors(collector.errors)) {
      throw ProtocolLoaderException._(
        ProtocolLoaderPhase.endpoints,
        _formatErrors('Endpoint analysis', collector),
      );
    }
    return endpoints;
  }

  static String _formatErrors(String phase, CodeGenerationCollector c) {
    return '$phase surfaced ${c.errors.length} error(s):\n'
        '${c.errors.map((e) => '  - $e').join('\n')}';
  }
}

enum ProtocolLoaderPhase { config, models, endpoints }

class ProtocolLoaderException implements Exception {
  ProtocolLoaderException._(this.phase, this.message);

  final ProtocolLoaderPhase phase;
  final String message;

  @override
  String toString() =>
      'ProtocolLoaderException[${phase.name}]: $message';
}

/// Minimal description of a discovered Serverpod module — passed into
/// [ProtocolLoader.loadForModule] / [ProtocolLoader.synthesizeModuleConfig]
/// so the synthesised [GeneratorConfig] can resolve cross-module
/// references (e.g. `module:auth:AuthUser`).
///
/// Decoupled from the richer `DiscoveredModule` class in
/// `discovery/module_discoverer.dart` to keep `protocol_loader.dart`
/// from depending on the discovery layer (which depends on this file
/// transitively for IR loading).
class ModuleDependency {
  const ModuleDependency({
    required this.dartPkgName,
    required this.nickname,
    required this.serverPkgPath,
  });

  /// Dart package name as seen in `package_config.json`
  /// (e.g. `serverpod_auth_core_server`).
  final String dartPkgName;

  /// The wire / generator.yaml nickname (e.g. `auth`).
  final String nickname;

  /// Absolute on-disk path to the module's server package directory.
  final String serverPkgPath;
}
