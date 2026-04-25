import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Integration test for the `inspect` CLI command. Runs the CLI as a
/// subprocess against the v0.1 fixture and asserts the stdout is valid
/// JSON with the expected top-level shape.
void main() {
  // Capture cwd at load time so individual tests don't depend on the
  // runner's working directory state — `dart test` may invoke from
  // anywhere.
  final packageRoot = Directory.current.path;

  setUpAll(() {
    final fixture = Directory(
      '$packageRoot/test/fixtures/sample_server/sample_server',
    );
    expect(
      fixture.existsSync(),
      isTrue,
      reason: 'fixture missing at ${fixture.absolute.path}',
    );
  });

  test('`inspect -d <fixture>` prints valid IR JSON to stdout', () async {
    final result = await Process.run(
      Platform.executable, // dart
      [
        'run',
        'serverpod_typescript_bridge:serverpod_typescript_bridge',
        'inspect',
        '-d',
        'test/fixtures/sample_server/sample_server',
      ],
      workingDirectory: packageRoot,
    );

    expect(
      result.exitCode,
      0,
      reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}',
    );

    final decoded = jsonDecode(result.stdout as String);
    expect(decoded, isA<Map<String, dynamic>>());
    final json = decoded as Map<String, dynamic>;
    expect(json['endpoints'], isA<List<dynamic>>());
    expect(json['models'], isA<List<dynamic>>());
    expect((json['endpoints'] as List), isNotEmpty);
    expect((json['models'] as List), isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
