// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/config/experimental_feature.dart';

import '../analyzer/protocol_loader.dart';
import '../discovery/module_class_index.dart';
import '../discovery/module_client_layout.dart';
import '../discovery/module_discoverer.dart';
import '../discovery/server_directory_finder.dart';
import '../emit/output_paths.dart';
import 'generation_pipeline.dart';
import 'post_build_runner.dart';

/// `generate` — produce the TypeScript client package for a Serverpod
/// project. Defaults: discovers every Serverpod module the project
/// depends on, generates a TS client for each as a sibling of the app
/// client, then generates the app client with `file:..` deps wired up
/// and `npm install` + `npm run build` run at the end.
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
      )
      ..addFlag(
        'gen-modules',
        defaultsTo: true,
        help: 'Recursively generate TS clients for every Serverpod '
            'module the project depends on (placed as siblings of the '
            'app client). Pass `--no-gen-modules` to skip — only useful '
            'if you manage module clients separately.',
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

    final appPaths = OutputPaths.resolve(
      config,
      explicitOutput: ar['output'] as String?,
    );

    // Pre-flight the IR for the app — fail fast on analyzer errors
    // before discovering modules (recursive failures are harder to
    // attribute back to the caller).
    try {
      await ProtocolLoader.load(serverDir);
    } on ProtocolLoaderException catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    final layoutResolver = ModuleLayoutResolver(
      appClientOutputDir: appPaths.outputDir,
      config: config,
    );

    // 1. Discover modules + build the cross-package class index.
    final discovered = (ar['gen-modules'] as bool)
        ? _discoverModules(serverDir)
        : <DiscoveredModule>[];
    final moduleIndex = await ModuleClassIndex.build(
      discovered: discovered,
      layoutResolver: layoutResolver,
    );

    final knownModules = [
      for (final m in discovered)
        ModuleDependency(
          dartPkgName: m.dartPkgName,
          nickname: m.nickname,
          serverPkgPath: m.serverPkgDir.path,
        ),
    ];

    // 2. Generate each discovered module FIRST so the app client can
    //    declare `file:..` deps that resolve cleanly.
    for (final mod in discovered) {
      final layout = layoutResolver.resolve(mod.dartPkgName);
      stdout.writeln(
        'Generating module client: ${mod.dartPkgName} → '
        '${layout.outputDir.path}',
      );
      try {
        await GenerationPipeline.run(
          serverDir: mod.serverPkgDir,
          outputDir: layout.outputDir,
          moduleIndex: moduleIndex,
          isModulePackage: true,
          knownModules: knownModules,
        );
      } catch (e) {
        stderr.writeln(
          'Failed to generate module ${mod.dartPkgName}: $e',
        );
        return 70;
      }
    }

    // 3. Generate the app client with module-aware imports + deps.
    try {
      await GenerationPipeline.run(
        serverDir: serverDir,
        outputDir: appPaths.outputDir,
        moduleIndex: moduleIndex,
      );
    } catch (e) {
      stderr.writeln('Failed to generate app client: $e');
      return 70;
    }

    stdout.writeln('Wrote TypeScript client to ${appPaths.outputDir.path}');

    // 4. Build module clients first, then the app. The app's tsc
    //    consumes module `dist/` outputs through the `file:..` deps;
    //    if those `dist/` directories don't exist yet the app's
    //    typecheck fails (`Cannot find module 'auth_typescript_client'
    //    or its corresponding type declarations`). npm doesn't run
    //    `prepare` for `file:` deps, so we have to drive the builds
    //    ourselves and in dependency order.
    if (ar['build'] as bool) {
      for (final mod in discovered) {
        final layout = layoutResolver.resolve(mod.dartPkgName);
        final modWarn =
            await PostBuildRunner(outputDir: layout.outputDir).run();
        if (modWarn != null) {
          stderr.writeln(
            'Module client ${mod.dartPkgName} build skipped: $modWarn',
          );
        }
      }
      final warning =
          await PostBuildRunner(outputDir: appPaths.outputDir).run();
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

  List<DiscoveredModule> _discoverModules(Directory serverDir) {
    try {
      return ModuleDiscoverer.discover(serverDir);
    } on StateError catch (e) {
      stderr.writeln(
        'Skipping module discovery: ${e.message}\n'
        'Pass `--no-gen-modules` to suppress this attempt.',
      );
      return const [];
    }
  }

  static bool _experimentalFeaturesInitialised = false;
  static void _ensureExperimentalFeaturesInitialised() {
    if (_experimentalFeaturesInitialised) return;
    CommandLineExperimentalFeatures.initialize(const []);
    _experimentalFeaturesInitialised = true;
  }
}
