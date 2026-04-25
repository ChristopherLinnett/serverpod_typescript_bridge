// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';

import '../analyzer/ir_walker.dart';
import '../analyzer/protocol_loader.dart';
import '../discovery/module_class_index.dart';
import '../emit/client_emitter.dart';
import '../emit/endpoint_emitter.dart';
import '../emit/generated_file_tracker.dart';
import '../emit/model_emitter.dart';
import '../emit/output_paths.dart';
import '../emit/scaffold_emitter.dart';
import '../emit/ts_type_mapper.dart';

/// One end-to-end generation against a single Serverpod server
/// package — used by [GenerateCommand] for both the user's app and
/// every module dependency. Doesn't run the post-build (npm install +
/// build); the command runs that once at the end against the app.
class GenerationPipeline {
  /// Generates a TypeScript client for the project at [serverDir],
  /// writing to [outputDir]. [moduleIndex] supplies cross-package
  /// import information for types defined in OTHER modules the
  /// project (transitively) depends on.
  static Future<void> run({
    required Directory serverDir,
    required Directory outputDir,
    required ModuleClassIndex moduleIndex,
    bool isModulePackage = false,
    List<ModuleDependency> knownModules = const [],
  }) async {
    // Module packages typically live under pub-cache and don't ship a
    // sibling dart client, so `GeneratorConfig.load` would fail on the
    // client-pubspec validation. We synthesise a config from the
    // module's own pubspec + generator.yaml ONCE here and reuse it for
    // both emission (below) and IR loading — a second pass would
    // re-read the same files and could legitimately see different
    // on-disk state if the user is generating mid-edit.
    // [knownModules] lets the synthesised config resolve cross-module
    // references inside the module being generated.
    final config = isModulePackage
        ? ProtocolLoader.synthesizeModuleConfig(serverDir,
            knownModules: knownModules)
        : await _loadConfig(serverDir);
    final ir = await ProtocolLoader.loadFromConfig(config);

    final paths = OutputPaths(
      outputDir: outputDir,
      packageName: '${config.name}_typescript_client',
    );

    final tracker = GeneratedFileTracker([
      Directory(p.join(outputDir.path, 'src', 'runtime')),
      Directory(p.join(outputDir.path, 'src', 'protocol')),
      Directory(p.join(outputDir.path, 'src', 'endpoints')),
    ]);

    // Scope the module index for THIS run by stripping out the project's
    // own classes. `ModuleClassIndex.build` walks every discovered
    // module — including the one we're about to emit — so without
    // this filter `ModuleImportLines` would treat the project's own
    // classes as foreign module classes and emit a self-referential
    // cross-package import on top of the legitimate local cross-file
    // import (and the protocol switch would emit a duplicate case
    // dispatching to the project's own npm name).
    final localNames = {for (final m in ir.models) m.className};
    final scopedIndex = moduleIndex.excluding(localNames);
    final mapperConfig = _MapperConfig.fromIr(ir, scopedIndex);

    final referencedClassNames = IrWalker.allReferencedClassNames(ir);
    final referencedExternalNames = referencedClassNames.difference(localNames);

    final moduleDeps = scopedIndex.referencedPackages(
      referencedClassNames: referencedExternalNames,
      consumerDir: outputDir,
    );

    final referencedModuleClassNames = <String>{
      for (final name in referencedExternalNames)
        if (scopedIndex.layoutFor(name) != null) name,
    };

    final scaffold = ScaffoldEmitter(
      outputPaths: paths,
      tracker: tracker,
      additionalBarrelExports: const [
        './protocol/index.js',
        './endpoints/index.js',
        './protocol.js',
        './client.js',
      ],
      moduleDependencies: moduleDeps,
    );
    await scaffold.emit();

    ModelEmitter(
      outputDir: outputDir,
      tracker: tracker,
      mapper: mapperConfig.build(modelPrefix: ''),
    ).emitAll(ir.models);
    EndpointEmitter(
      outputDir: outputDir,
      tracker: tracker,
      mapper: mapperConfig.build(modelPrefix: 'p.'),
    ).emitAll(ir.endpoints);
    ClientEmitter(
      outputDir: outputDir,
      tracker: tracker,
      config: config,
      moduleIndex: scopedIndex,
      referencedModuleClassNames: referencedModuleClassNames,
    ).emit(endpoints: ir.endpoints, models: ir.models);

    tracker.sweepOrphans();
  }

  static Future<GeneratorConfig> _loadConfig(Directory serverDir) async {
    return GeneratorConfig.load(
      serverRootDir: serverDir.path,
      interactive: false,
    );
  }
}

/// Bundles every shape the [TsTypeMapper] needs about a project's
/// own IR so the model and endpoint mappers can be constructed from a
/// single derivation pass instead of duplicating the same five
/// arguments at each call site.
class _MapperConfig {
  _MapperConfig._({
    required this.sealedClassNames,
    required this.enumClassNames,
    required this.projectClassNames,
    required this.moduleIndex,
  });

  factory _MapperConfig.fromIr(
    ProtocolDefinition ir,
    ModuleClassIndex moduleIndex,
  ) {
    return _MapperConfig._(
      sealedClassNames: ir.models
          .whereType<ModelClassDefinition>()
          .where((m) => m.isSealed)
          .map((m) => m.className)
          .toSet(),
      enumClassNames:
          ir.models.whereType<EnumDefinition>().map((e) => e.className).toSet(),
      projectClassNames: {for (final m in ir.models) m.className},
      moduleIndex: moduleIndex,
    );
  }

  final Set<String> sealedClassNames;
  final Set<String> enumClassNames;
  final Set<String> projectClassNames;
  final ModuleClassIndex moduleIndex;

  TsTypeMapper build({required String modelPrefix}) {
    return TsTypeMapper(
      modelPrefix: modelPrefix,
      sealedClassNames: sealedClassNames,
      enumClassNames: enumClassNames,
      projectClassNames: projectClassNames,
      moduleIndex: moduleIndex,
    );
  }
}
