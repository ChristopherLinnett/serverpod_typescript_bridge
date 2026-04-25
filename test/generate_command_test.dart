import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end tests for `generate`. Asserts the generated source is in
/// place and (default behaviour) `dist/` was built — the package is
/// import-ready straight out of the gate. The `--no-build` opt-out is
/// also exercised.
void main() {
  final packageRoot = Directory.current.path;

  group('generate (default = build)', () {
    test(
      'emits source AND runs npm install + npm run build, leaving dist/',
      () async {
        final tempOutput =
            Directory.systemTemp.createTempSync('sptb_generate_build_');
        try {
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              'serverpod_typescript_bridge:serverpod_typescript_bridge',
              'generate',
              '-d',
              'test/fixtures/sample_server/sample_server',
              '-o',
              tempOutput.path,
            ],
            workingDirectory: packageRoot,
          );

          expect(
            result.exitCode,
            0,
            reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}',
          );

          for (final rel in const [
            'package.json',
            'tsconfig.json',
            '.gitignore',
            'src/index.ts',
            'src/runtime/index.ts',
            // Auto-build artefacts:
            'dist/index.js',
            'dist/index.d.ts',
            'node_modules/typescript/package.json',
          ]) {
            expect(
              File(p.join(tempOutput.path, rel)).existsSync(),
              isTrue,
              reason: 'missing $rel',
            );
          }
        } finally {
          if (tempOutput.existsSync()) tempOutput.deleteSync(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });

  group('generate --no-build', () {
    test(
      'emits source ONLY, leaves dist/ + node_modules/ unmade',
      () async {
        final tempOutput =
            Directory.systemTemp.createTempSync('sptb_generate_nobuild_');
        try {
          final result = await Process.run(
            Platform.executable,
            [
              'run',
              'serverpod_typescript_bridge:serverpod_typescript_bridge',
              'generate',
              '-d',
              'test/fixtures/sample_server/sample_server',
              '-o',
              tempOutput.path,
              '--no-build',
            ],
            workingDirectory: packageRoot,
          );

          expect(
            result.exitCode,
            0,
            reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}',
          );

          // Source files present.
          expect(
            File(p.join(tempOutput.path, 'src', 'index.ts')).existsSync(),
            isTrue,
          );
          // No build artefacts.
          expect(
            Directory(p.join(tempOutput.path, 'dist')).existsSync(),
            isFalse,
            reason: '--no-build should leave dist/ unmade',
          );
          expect(
            Directory(p.join(tempOutput.path, 'node_modules')).existsSync(),
            isFalse,
            reason: '--no-build should leave node_modules/ unmade',
          );
        } finally {
          if (tempOutput.existsSync()) tempOutput.deleteSync(recursive: true);
        }
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
