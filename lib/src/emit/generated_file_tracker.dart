import 'dart:io';

import 'package:path/path.dart' as p;

/// Tracks every file the generator writes during a single run, then
/// deletes any pre-existing file under the same managed directories
/// that wasn't (re-)written this run.
///
/// Mirrors `cleanPreviouslyGeneratedDartFiles` in serverpod_cli — the
/// generator owns its output directories.
class GeneratedFileTracker {
  GeneratedFileTracker(this._managedDirectories);

  /// Directories whose entire `.ts` contents are owned by the generator.
  /// Anything not written this run is removed at sweep time.
  final List<Directory> _managedDirectories;
  final Set<String> _writtenAbsolutePaths = {};

  /// Records that [file] was (re-)written this run. Idempotent.
  void recordWrite(File file) {
    _writtenAbsolutePaths.add(p.canonicalize(file.absolute.path));
  }

  /// Deletes any `.ts` file under one of the managed directories that
  /// wasn't recorded as written this run.
  void sweepOrphans() {
    for (final dir in _managedDirectories) {
      if (!dir.existsSync()) continue;
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is! File) continue;
        if (!entity.path.endsWith('.ts')) continue;
        final canonical = p.canonicalize(entity.absolute.path);
        if (_writtenAbsolutePaths.contains(canonical)) continue;
        entity.deleteSync();
      }
    }
  }
}
