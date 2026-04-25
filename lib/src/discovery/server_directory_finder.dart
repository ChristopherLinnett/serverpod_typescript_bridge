import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Locates the Serverpod server package directory for the current invocation.
///
/// "Server package" means a directory whose `pubspec.yaml` either is named
/// `serverpod` itself, or declares `serverpod` as a dependency. This mirrors
/// `serverpod_cli`'s `isServerDirectory` predicate.
class ServerDirectoryFinder {
  /// Returns the resolved server directory.
  ///
  /// Resolution order:
  ///   1. If [override] is non-null and valid, return it.
  ///   2. Walk up from [start] (defaults to `Directory.current`), returning
  ///      the first ancestor that is a server directory.
  ///   3. Throw [StateError] if no server can be found.
  static Directory find({Directory? start, String? override}) {
    if (override != null) return _validateOverride(override);

    final origin = start ?? Directory.current;
    if (!origin.existsSync()) {
      throw StateError('Start directory does not exist: ${origin.path}');
    }

    Directory? cursor = origin;
    while (cursor != null) {
      if (_isServerDirectory(cursor)) return cursor;
      final parent = cursor.parent;
      if (p.equals(parent.path, cursor.path)) break;
      cursor = parent;
    }

    throw StateError(
      'No Serverpod server directory found at or above '
      '${p.canonicalize(origin.path)}. '
      'Pass --directory to point at one explicitly.',
    );
  }

  static Directory _validateOverride(String overridePath) {
    final dir = Directory(overridePath);
    if (!dir.existsSync()) {
      throw StateError('Override directory does not exist: $overridePath');
    }
    if (!_isServerDirectory(dir)) {
      throw StateError(
        '$overridePath is not a Serverpod server directory '
        '(no pubspec.yaml with a `serverpod` dependency).',
      );
    }
    return dir;
  }

  // Reads + parses pubspec.yaml at every directory the walk visits. On a
  // deep path that's O(depth) synchronous reads; in practice always single
  // digits. If a future caller needs a faster walk (e.g. an LSP server
  // with many starts), extract a `PubspecPredicate` interface so a
  // pre-parsed pubspec can be passed in.
  static bool _isServerDirectory(Directory dir) {
    final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) return false;
    final dynamic yaml;
    try {
      yaml = loadYaml(pubspec.readAsStringSync());
    } catch (_) {
      // An invalid pubspec.yaml on the walk path means "not a Serverpod
      // server" — keep walking. Don't let a malformed yaml in a parent
      // directory blow up the whole search.
      return false;
    }
    if (yaml is! YamlMap) return false;
    if (yaml['name'] == 'serverpod') return true;
    final deps = yaml['dependencies'];
    return deps is YamlMap && deps.containsKey('serverpod');
  }
}
