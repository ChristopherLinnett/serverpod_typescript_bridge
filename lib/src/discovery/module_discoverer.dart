import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// One Serverpod module the user's project depends on.
class DiscoveredModule {
  DiscoveredModule({
    required this.dartPkgName,
    required this.nickname,
    required this.serverPkgDir,
  });

  /// The Dart package name as it appears in pubspec / package_config
  /// (e.g. `serverpod_auth_idp_server`).
  final String dartPkgName;

  /// The wire prefix Serverpod uses for class names from this module
  /// (e.g. `auth`). Read from the module's `config/generator.yaml`.
  final String nickname;

  /// On-disk root of the module's Dart server package (typically under
  /// the user's pub-cache).
  final Directory serverPkgDir;

  @override
  String toString() => 'DiscoveredModule($dartPkgName, '
      'nickname=$nickname, dir=${serverPkgDir.path})';
}

/// Locates every Serverpod module *server* package the project at
/// [serverDir] depends on, by reading the workspace's
/// `.dart_tool/package_config.json` and filtering to packages that
/// declare `type: module` in their `config/generator.yaml`.
class ModuleDiscoverer {
  /// Returns an empty list if the project has no module deps.
  /// Throws [StateError] if `package_config.json` cannot be located —
  /// that means `dart pub get` hasn't been run yet.
  static List<DiscoveredModule> discover(Directory serverDir) {
    final configFile = _locatePackageConfig(serverDir);
    if (configFile == null) {
      throw StateError(
        'No .dart_tool/package_config.json found at or above '
        '${serverDir.path}. Run `dart pub get` first.',
      );
    }

    final config = jsonDecode(configFile.readAsStringSync())
        as Map<String, dynamic>;
    final packages = (config['packages'] as List).cast<Map<String, dynamic>>();
    final configDir = configFile.parent.parent; // walks .dart_tool/

    final modules = <DiscoveredModule>[];
    for (final pkg in packages) {
      final name = pkg['name'] as String;
      final rootUri = pkg['rootUri'] as String;
      final pkgDir = _resolvePackageDir(rootUri, configDir);
      if (pkgDir == null) continue;

      final generatorYaml =
          File(p.join(pkgDir.path, 'config', 'generator.yaml'));
      if (!generatorYaml.existsSync()) continue;

      final yaml = _safeLoadYaml(generatorYaml);
      if (yaml is! YamlMap) continue;
      if (yaml['type'] != 'module') continue;

      final nickname = yaml['nickname'];
      if (nickname is! String || nickname.isEmpty) continue;

      modules.add(DiscoveredModule(
        dartPkgName: name,
        nickname: nickname,
        serverPkgDir: pkgDir,
      ));
    }

    modules.sort((a, b) => a.dartPkgName.compareTo(b.dartPkgName));
    return modules;
  }

  /// Walks up from [start] looking for `.dart_tool/package_config.json`.
  /// Returns null if none found at or above the starting directory.
  static File? _locatePackageConfig(Directory start) {
    Directory? cursor = start;
    while (cursor != null) {
      final candidate =
          File(p.join(cursor.path, '.dart_tool', 'package_config.json'));
      if (candidate.existsSync()) return candidate;
      final parent = cursor.parent;
      if (p.equals(parent.path, cursor.path)) return null;
      cursor = parent;
    }
    return null;
  }

  /// `rootUri` may be absolute (`file:///...`) or relative to the
  /// directory containing `.dart_tool/`. Returns the resolved directory,
  /// or null if it doesn't exist.
  static Directory? _resolvePackageDir(String rootUri, Directory configDir) {
    final uri = Uri.parse(rootUri);
    final String absolutePath;
    if (uri.scheme == 'file') {
      absolutePath = uri.toFilePath();
    } else if (uri.scheme.isEmpty) {
      absolutePath = p.normalize(p.join(configDir.path, uri.path));
    } else {
      return null;
    }
    final dir = Directory(absolutePath);
    return dir.existsSync() ? dir : null;
  }

  static dynamic _safeLoadYaml(File f) {
    try {
      return loadYaml(f.readAsStringSync());
    } catch (_) {
      return null;
    }
  }
}
