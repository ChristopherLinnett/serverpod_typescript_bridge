import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// End-to-end test: spawn the CLI with `generate` against the fixture,
/// targeting a temp output directory, and assert the resulting package
/// is `tsc --noEmit` clean.
void main() {
  final packageRoot = Directory.current.path;

  test(
    '`generate -d <fixture> -o <tmp>` produces a tsc-clean scaffold',
    () async {
      final tempOutput =
          Directory.systemTemp.createTempSync('sptb_generate_e2e_');
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

        // Required files present
        for (final rel in const [
          'package.json',
          'tsconfig.json',
          '.gitignore',
          'src/index.ts',
          'src/runtime/index.ts',
        ]) {
          expect(
            File(p.join(tempOutput.path, rel)).existsSync(),
            isTrue,
            reason: 'missing $rel',
          );
        }

        // Type-check the generated package using the tsc that ships
        // with the runtime project (already installed at lib/runtime/
        // typescript/node_modules/.bin/tsc by `npm install`). Skips
        // silently if the runtime hasn't been npm-installed yet.
        final tscBinary = File(p.join(
          packageRoot,
          'lib',
          'runtime',
          'typescript',
          'node_modules',
          '.bin',
          'tsc',
        ));
        if (!tscBinary.existsSync()) {
          printOnFailure(
            'Skipping tsc smoke check: ${tscBinary.absolute.path} missing. '
            'Run `npm install` inside lib/runtime/typescript/ to enable.',
          );
          return;
        }
        final tscCheck = await Process.run(
          tscBinary.path,
          ['--noEmit'],
          workingDirectory: tempOutput.path,
        );
        if (tscCheck.exitCode != 0) {
          printOnFailure('tsc stdout:\n${tscCheck.stdout}\n'
              'tsc stderr:\n${tscCheck.stderr}');
        }
        expect(tscCheck.exitCode, 0, reason: 'tsc --noEmit failed');
      } finally {
        if (tempOutput.existsSync()) tempOutput.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
