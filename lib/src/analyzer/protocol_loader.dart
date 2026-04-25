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
import 'package:serverpod_cli/src/config/experimental_feature.dart';
import 'package:serverpod_cli/src/generator/code_generation_collector.dart';
import 'package:serverpod_cli/src/util/model_helper.dart';

/// Builds a [ProtocolDefinition] for a Serverpod server package by reusing
/// `serverpod_cli`'s own analyzers — same IR, no parser drift.
class ProtocolLoader {
  /// Loads the IR for the given [serverDirectory].
  ///
  /// Throws [ProtocolLoaderException] if the analyzer reports severe
  /// errors (malformed YAML, invalid endpoint signature, etc.).
  static Future<ProtocolDefinition> load(Directory serverDirectory) async {
    _ensureExperimentalFeaturesInitialised();
    final config = await _loadConfig(serverDirectory);
    final models = await _runModelAnalysis(config);
    final endpoints = await _runEndpointAnalysis(config);
    return ProtocolDefinition(
      endpoints: endpoints,
      models: models,
      futureCalls: const [],
    );
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
    } catch (e) {
      throw ProtocolLoaderException._(
        ProtocolLoaderPhase.config,
        'Failed to load GeneratorConfig from ${serverDirectory.path}: $e',
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
