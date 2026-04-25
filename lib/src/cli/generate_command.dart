// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/config/experimental_feature.dart';

import '../analyzer/protocol_loader.dart';
import '../discovery/server_directory_finder.dart';
import '../emit/client_emitter.dart';
import '../emit/endpoint_emitter.dart';
import '../emit/generated_file_tracker.dart';
import '../emit/model_emitter.dart';
import '../emit/output_paths.dart';
import '../emit/scaffold_emitter.dart';
import '../emit/ts_type_mapper.dart';

/// `generate` — produce the TypeScript client package for a Serverpod
/// project.
///
/// In v0.1 this writes the static scaffold (package.json, tsconfig,
/// runtime, barrel). Issues #5–#10 layer in model and endpoint emission
/// on top.
class GenerateCommand extends Command<int> {
  GenerateCommand() {
    argParser
      ..addOption(
        'directory',
        abbr: 'd',
        help: 'Path to the Serverpod server package. '
            'Auto-detected (walking up from cwd) if omitted.',
      )
      ..addOption(
        'output',
        abbr: 'o',
        help: 'Path to the TypeScript client package to (re-)generate. '
            'Defaults to `<server>/../<name>_typescript_client/`, '
            'overridable via `typescript_client_package_path` in '
            '`config/generator.yaml`.',
      );
  }

  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate the TypeScript client package next to the Serverpod project.';

  @override
  Future<int> run() async {
    final ar = argResults!;

    final Directory serverDir;
    try {
      serverDir = ServerDirectoryFinder.find(
        override: ar['directory'] as String?,
      );
    } on StateError catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    final GeneratorConfig config;
    try {
      _ensureExperimentalFeaturesInitialised();
      config = await GeneratorConfig.load(
        serverRootDir: serverDir.path,
        interactive: false,
      );
    } catch (e) {
      stderr.writeln('Failed to load generator.yaml: $e');
      return 70;
    }

    final paths = OutputPaths.resolve(
      config,
      explicitOutput: ar['output'] as String?,
    );

    // Load the IR up front so we fail fast on analyzer errors before
    // touching disk.
    final ProtocolDefinition ir;
    try {
      ir = await ProtocolLoader.load(serverDir);
    } on ProtocolLoaderException catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    final tracker = GeneratedFileTracker([
      Directory(p.join(paths.outputDir.path, 'src')),
    ]);

    final scaffold = ScaffoldEmitter(
      outputPaths: paths,
      tracker: tracker,
      additionalBarrelExports: const [
        './protocol/index.js',
        './endpoints/index.js',
        './protocol.js',
        './client.js',
      ],
    );
    await scaffold.emit();

    final sealedClassNames = ir.models
        .whereType<ModelClassDefinition>()
        .where((m) => m.isSealed)
        .map((m) => m.className)
        .toSet();
    ModelEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
      mapper: TsTypeMapper(sealedClassNames: sealedClassNames),
    ).emitAll(ir.models);
    EndpointEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
      mapper: TsTypeMapper(
        modelPrefix: 'p.',
        sealedClassNames: sealedClassNames,
      ),
    ).emitAll(ir.endpoints);
    ClientEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
    ).emit(endpoints: ir.endpoints, models: ir.models);

    // Sweep orphans now that every emitter has run.
    tracker.sweepOrphans();

    stdout.writeln('Wrote TypeScript client to ${paths.outputDir.path}');
    return 0;
  }

  static bool _experimentalFeaturesInitialised = false;
  static void _ensureExperimentalFeaturesInitialised() {
    if (_experimentalFeaturesInitialised) return;
    CommandLineExperimentalFeatures.initialize(const []);
    _experimentalFeaturesInitialised = true;
  }
}
