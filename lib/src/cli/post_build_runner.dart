import 'dart:io';

/// Runs `npm install` then `npm run build` in [outputDir].
///
/// On success, returns null. On any failure (node missing, install
/// failed, build failed) returns a multi-line warning the caller can
/// print verbatim. The generator never treats these failures as fatal —
/// the source files are correct regardless.
class PostBuildRunner {
  PostBuildRunner({
    required this.outputDir,
    Stdout? stdoutSink,
    Stdout? stderrSink,
  })  : _stdout = stdoutSink ?? stdout,
        _stderr = stderrSink ?? stderr;

  final Directory outputDir;
  final Stdout _stdout;
  final Stdout _stderr;

  Future<String?> run() async {
    final npm = _resolveNpm();
    if (npm == null) {
      return _hint(
        'Skipped `npm install` + `npm run build`: npm is not on PATH. '
        'Install Node.js (https://nodejs.org/), then run:',
      );
    }

    _stdout.writeln('Running `npm install` in ${outputDir.path}...');
    final installResult = await Process.run(
      npm,
      ['install', '--silent', '--no-fund', '--no-audit'],
      workingDirectory: outputDir.path,
    );
    if (installResult.exitCode != 0) {
      _stderr.writeln(installResult.stdout);
      _stderr.writeln(installResult.stderr);
      return _hint(
        '`npm install` failed (exit ${installResult.exitCode}). '
        'Source files are still correct. To recover, run:',
      );
    }

    _stdout.writeln('Running `npm run build`...');
    final buildResult = await Process.run(
      npm,
      ['run', 'build'],
      workingDirectory: outputDir.path,
    );
    if (buildResult.exitCode != 0) {
      _stderr.writeln(buildResult.stdout);
      _stderr.writeln(buildResult.stderr);
      return _hint(
        '`npm run build` failed (exit ${buildResult.exitCode}). '
        'Source files are still correct. To recover, run:',
      );
    }

    return null;
  }

  /// Returns the platform-specific `npm` executable, or null if missing.
  ///
  /// On systems where `which`/`where` themselves aren't available (or
  /// process spawning is blocked) the lookup must NOT crash `generate`
  /// — post-build is intentionally non-fatal. We swallow [ProcessException]
  /// and treat it the same as "npm not found".
  String? _resolveNpm() {
    final candidates = Platform.isWindows
        ? const ['npm.cmd', 'npm']
        : const ['npm'];
    for (final c in candidates) {
      try {
        final result = Process.runSync(
          Platform.isWindows ? 'where' : 'which',
          [c],
        );
        if (result.exitCode == 0 &&
            (result.stdout as String).trim().isNotEmpty) {
          return c;
        }
      } on ProcessException {
        return null;
      }
    }
    return null;
  }

  /// Quotes [outputDir]'s path so a copy-pasted recovery command works
  /// even when the path contains spaces, quotes, or shell metacharacters.
  String _quotedOutputDirPath() {
    final path = outputDir.path;
    if (Platform.isWindows) {
      return '"${path.replaceAll('"', r'\"')}"';
    }
    return "'${path.replaceAll("'", r"'\''")}'";
  }

  String _hint(String reason) {
    return '$reason\n'
        '  cd ${_quotedOutputDirPath()}\n'
        '  npm install\n'
        '  npm run build';
  }
}
