// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:yaml/yaml.dart';

/// Where one module's generated TS client lives, and what the rest of
/// the codebase calls it.
class ModuleClientLayout {
  ModuleClientLayout({
    required this.dartPkgName,
    required this.outputDir,
    required this.npmPackageName,
    required this.relativeFromAppClient,
  });

  /// The Dart module's pkg name (e.g. `serverpod_auth_idp_server`).
  final String dartPkgName;

  /// Where the module's TS client should be written.
  final Directory outputDir;

  /// The `name` field that goes in the module client's `package.json`.
  /// Must match the file: dep entry the app client declares.
  final String npmPackageName;

  /// The relative path the app client's `package.json` uses (e.g.
  /// `../serverpod_auth_idp_typescript_client`). Used for `file:..`
  /// dependency resolution.
  final String relativeFromAppClient;

  @override
  String toString() => 'ModuleClientLayout($dartPkgName → '
      '${outputDir.path}, npm=$npmPackageName)';
}

/// Computes [ModuleClientLayout]s for every module a project depends
/// on. Default convention puts each module client as a sibling of the
/// app client, named `<module>_typescript_client` (matching the
/// Dart-side `<module>_client` convention).
///
/// Overrideable via `typescript_client_modules:` in
/// `config/generator.yaml`:
///
/// ```yaml
/// typescript_client_modules:
///   serverpod_auth_idp_server:
///     output: ../my_custom_path
///     npm_name: '@my-org/auth-idp-ts'
/// ```
class ModuleLayoutResolver {
  ModuleLayoutResolver({
    required this.appClientOutputDir,
    required this.config,
  });

  /// Where the user's APP client is being written. All module clients
  /// are computed as siblings of this directory (unless overridden).
  final Directory appClientOutputDir;

  /// The user's [GeneratorConfig] — used to read the optional
  /// `typescript_client_modules:` override block from generator.yaml.
  final GeneratorConfig config;

  late final Map<String, _Override> _overrides = _readOverrides();

  ModuleClientLayout resolve(String dartPkgName) {
    final override = _overrides[dartPkgName];
    final defaultDirName = _defaultDirName(dartPkgName);

    final outputDir = override?.output != null
        ? Directory(_resolveOverridePath(override!.output!))
        : Directory(p.join(appClientOutputDir.parent.path, defaultDirName));

    final npmName = override?.npmName ?? defaultDirName;

    final relativeFromAppClient = p.relative(
      outputDir.path,
      from: appClientOutputDir.path,
    );

    return ModuleClientLayout(
      dartPkgName: dartPkgName,
      outputDir: outputDir,
      npmPackageName: npmName,
      relativeFromAppClient: relativeFromAppClient,
    );
  }

  /// `serverpod_auth_idp_server` → `serverpod_auth_idp_typescript_client`.
  /// Strips a trailing `_server` if present (matches Serverpod's own
  /// `<name>_client` convention) and appends `_typescript_client`.
  String _defaultDirName(String dartPkgName) {
    final stripped = dartPkgName.endsWith('_server')
        ? dartPkgName.substring(0, dartPkgName.length - '_server'.length)
        : dartPkgName;
    return '${stripped}_typescript_client';
  }

  String _resolveOverridePath(String overridePath) {
    if (p.isAbsolute(overridePath)) return overridePath;
    // Relative paths in the override are interpreted from the app
    // client's PARENT (so `../foo` works the same way the default does).
    return p.normalize(
      p.join(appClientOutputDir.parent.path, overridePath),
    );
  }

  Map<String, _Override> _readOverrides() {
    final yamlFile = File(p.joinAll([
      ...config.serverPackageDirectoryPathParts,
      'config',
      'generator.yaml',
    ]));
    if (!yamlFile.existsSync()) return const {};

    final dynamic raw;
    try {
      raw = loadYaml(yamlFile.readAsStringSync());
    } catch (_) {
      return const {};
    }
    if (raw is! YamlMap) return const {};
    final modulesNode = raw['typescript_client_modules'];
    if (modulesNode is! YamlMap) return const {};

    final out = <String, _Override>{};
    for (final entry in modulesNode.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      if (value is YamlMap) {
        out[key] = _Override(
          output: value['output'] as String?,
          npmName: value['npm_name'] as String?,
        );
      } else if (value is String) {
        // Shorthand: just the npm package name.
        out[key] = _Override(output: null, npmName: value);
      }
    }
    return out;
  }
}

class _Override {
  _Override({this.output, this.npmName});
  final String? output;
  final String? npmName;
}
