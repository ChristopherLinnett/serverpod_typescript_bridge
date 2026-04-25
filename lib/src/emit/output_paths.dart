// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:yaml/yaml.dart';

/// Resolves where the TypeScript client package should live for a given
/// Serverpod project.
///
/// Resolution order:
///   1. Explicit override (CLI `--output` flag).
///   2. `typescript_client_package_path` in `config/generator.yaml`.
///   3. Sibling of the server package: `<server>/../<name>_typescript_client/`.
class OutputPaths {
  /// Construct directly when caller already knows the explicit dir +
  /// pkg name (used by [GenerationPipeline] for module clients);
  /// otherwise prefer [resolve] which derives both from a
  /// [GeneratorConfig].
  OutputPaths({
    required this.outputDir,
    required this.packageName,
  });

  final Directory outputDir;
  final String packageName;

  static const _generatorYamlOverrideKey = 'typescript_client_package_path';

  /// Resolves the paths from a loaded [config], optionally overridden by
  /// [explicitOutput] (e.g. `--output` CLI flag).
  static OutputPaths resolve(
    GeneratorConfig config, {
    String? explicitOutput,
  }) {
    final outputPath = explicitOutput ??
        _readFromGeneratorYaml(config) ??
        _defaultPath(config);
    return OutputPaths(
      outputDir: Directory(outputPath),
      packageName: '${config.name}_typescript_client',
    );
  }

  static String? _readFromGeneratorYaml(GeneratorConfig config) {
    final generatorYaml = File(
      p.joinAll([
        ...config.serverPackageDirectoryPathParts,
        'config',
        'generator.yaml',
      ]),
    );
    if (!generatorYaml.existsSync()) return null;
    final yaml = loadYaml(generatorYaml.readAsStringSync());
    if (yaml is! YamlMap) return null;
    final raw = yaml[_generatorYamlOverrideKey];
    if (raw is! String || raw.isEmpty) return null;
    // Resolve relative paths against the server package directory.
    if (p.isAbsolute(raw)) return raw;
    return p.normalize(
      p.joinAll([...config.serverPackageDirectoryPathParts, raw]),
    );
  }

  static String _defaultPath(GeneratorConfig config) {
    return p.normalize(
      p.joinAll([
        ...config.serverPackageDirectoryPathParts,
        '..',
        '${config.name}_typescript_client',
      ]),
    );
  }
}
