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
import 'post_build_runner.dart';

/// `generate` — produce the TypeScript client package for a Serverpod
/// project. Default: emits source AND runs `npm install` + `npm run
/// build` so the resulting package is import-ready. Pass `--no-build`
/// to skip the install + build steps (e.g. for non-npm toolchains
/// or CI pipelines that build separately).
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
      )
      ..addFlag(
        'build',
        defaultsTo: true,
        help: 'After emitting source, run `npm install` + `npm run '
            'build` in the output directory so it is import-ready. '
            'Pass `--no-build` to skip; you can build manually later.',
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

    final ProtocolDefinition ir;
    try {
      ir = await ProtocolLoader.load(serverDir);
    } on ProtocolLoaderException catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    final tracker = GeneratedFileTracker([
      Directory(p.join(paths.outputDir.path, 'src', 'runtime')),
      Directory(p.join(paths.outputDir.path, 'src', 'protocol')),
      Directory(p.join(paths.outputDir.path, 'src', 'endpoints')),
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
    final enumClassNames = ir.models
        .whereType<EnumDefinition>()
        .map((e) => e.className)
        .toSet();
    ModelEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
      mapper: TsTypeMapper(
        sealedClassNames: sealedClassNames,
        enumClassNames: enumClassNames,
      ),
    ).emitAll(ir.models);
    EndpointEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
      mapper: TsTypeMapper(
        modelPrefix: 'p.',
        sealedClassNames: sealedClassNames,
        enumClassNames: enumClassNames,
      ),
    ).emitAll(ir.endpoints);
    ClientEmitter(
      outputDir: paths.outputDir,
      tracker: tracker,
      config: config,
    ).emit(endpoints: ir.endpoints, models: ir.models);

    tracker.sweepOrphans();

    stdout.writeln('Wrote TypeScript client to ${paths.outputDir.path}');

    if (ar['build'] as bool) {
      final warning =
          await PostBuildRunner(outputDir: paths.outputDir).run();
      if (warning != null) {
        stderr.writeln(warning);
      } else {
        stdout.writeln('Built dist/. Package is import-ready.');
      }
    } else {
      stdout.writeln(
        'Skipping build (--no-build). Package source is in place; run '
        '`npm install && npm run build` in the output directory before '
        'importing.',
      );
    }
    return 0;
  }

  static bool _experimentalFeaturesInitialised = false;
  static void _ensureExperimentalFeaturesInitialised() {
    if (_experimentalFeaturesInitialised) return;
    CommandLineExperimentalFeatures.initialize(const []);
    _experimentalFeaturesInitialised = true;
  }
}
