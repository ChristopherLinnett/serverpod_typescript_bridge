import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Verifies that `generate` against a Serverpod *module* (`type: module`
/// in generator.yaml) emits a `<Nickname>Caller extends
/// ModuleEndpointCaller` instead of a top-level `Client`.
void main() {
  final packageRoot = Directory.current.path;

  test(
    '`generate -d <module-fixture>` emits a Caller-style client',
    () async {
      final tempOutput =
          Directory.systemTemp.createTempSync('sptb_module_e2e_');
      try {
        final result = await Process.run(
          Platform.executable,
          [
            'run',
            'serverpod_typescript_bridge:serverpod_typescript_bridge',
            'generate',
            '-d',
            'test/fixtures/sample_module/testmod_server',
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

        final clientFile = File(p.join(tempOutput.path, 'src', 'client.ts'));
        expect(clientFile.existsSync(), isTrue);
        final clientSrc = await clientFile.readAsString();
        expect(clientSrc, contains('TestmodCaller'));
        expect(clientSrc, contains('extends r.ModuleEndpointCaller'));
        expect(
          clientSrc,
          isNot(contains('extends r.ServerpodClientShared')),
          reason: 'modules should not emit a top-level Client',
        );

        final protocolFile =
            File(p.join(tempOutput.path, 'src', 'protocol.ts'));
        final protocolSrc = await protocolFile.readAsString();
        expect(
          protocolSrc,
          contains("modulePrefix = 'testmod'"),
          reason: 'modules export their wire prefix as a const',
        );
        expect(
          protocolSrc,
          contains("raw.split('.').pop()"),
          reason: 'Protocol switch must strip module prefixes from '
              'incoming __className__ values',
        );

        // Type-check the generated package using the runtime's tsc.
        final tscBinary = File(p.join(
          packageRoot,
          'lib',
          'runtime',
          'typescript',
          'node_modules',
          '.bin',
          Platform.isWindows ? 'tsc.cmd' : 'tsc',
        ));
        if (!tscBinary.existsSync()) {
          printOnFailure(
            'Skipping tsc smoke check: ${tscBinary.absolute.path} missing.',
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
