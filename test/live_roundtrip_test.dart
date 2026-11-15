import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// The one test that runs the generated client: it boots the fixture
/// Serverpod server, generates the TypeScript client for it, and drives
/// every endpoint from Node (`test/live/roundtrip.mjs`).
///
/// Every other test here inspects generated source or type-checks it, and
/// source that type-checks can still fail to import, or put bytes on the
/// wire the server refuses. This is the test that notices.
void main() {
  final packageRoot = Directory.current.path;
  final serverDir = p.join(
    packageRoot,
    'test',
    'fixtures',
    'sample_server',
    'sample_server',
  );

  late Process server;
  late Directory output;
  late int apiPort;
  final serverLog = StringBuffer();

  setUpAll(() async {
    output = Directory.systemTemp.createTempSync('sptb_live_');
    final ports = await _freePorts(3);
    apiPort = ports[0];
    server = await Process.start(
      Platform.executable,
      ['bin/main.dart'],
      workingDirectory: serverDir,
      environment: {
        for (final (name, port) in [
          ('API', ports[0]),
          ('INSIGHTS', ports[1]),
          ('WEB', ports[2]),
        ]) ...{
          'SERVERPOD_${name}_SERVER_PORT': '$port',
          'SERVERPOD_${name}_SERVER_PUBLIC_HOST': 'localhost',
          'SERVERPOD_${name}_SERVER_PUBLIC_PORT': '$port',
          'SERVERPOD_${name}_SERVER_PUBLIC_SCHEME': 'http',
        },
      },
    );
    server.stdout.transform(utf8.decoder).listen(serverLog.write);
    server.stderr.transform(utf8.decoder).listen(serverLog.write);
    await _waitUntilListening(apiPort, server, serverLog);
  });

  tearDownAll(() async {
    server.kill();
    await server.exitCode;
    if (output.existsSync()) output.deleteSync(recursive: true);
  });

  test(
    'the generated client round-trips every fixture endpoint against a '
    'running server',
    () async {
      final clientDir = p.join(output.path, 'sample_typescript_client');
      final generate = await Process.run(
        Platform.executable,
        [
          'run',
          'serverpod_typescript_bridge:serverpod_typescript_bridge',
          'generate',
          '-d',
          serverDir,
          '-o',
          clientDir,
        ],
        workingDirectory: packageRoot,
      );
      expect(
        generate.exitCode,
        0,
        reason: 'generate failed:\n${generate.stdout}\n${generate.stderr}',
      );
      expect(
        File(p.join(clientDir, 'dist', 'index.js')).existsSync(),
        isTrue,
        reason: 'the client did not build:\n${generate.stdout}\n${generate.stderr}',
      );

      final roundtrip = await Process.run('node', [
        p.join(packageRoot, 'test', 'live', 'roundtrip.mjs'),
        p.join(clientDir, 'dist', 'index.js'),
        'http://localhost:$apiPort/',
      ]);
      final report = '${roundtrip.stdout}${roundtrip.stderr}';
      expect(roundtrip.exitCode, 0, reason: report);
      // An exit code of 0 with nothing run would also be "no failures".
      final summary = RegExp(r'^(\d+)/(\d+) passed$', multiLine: true)
          .firstMatch(report);
      expect(summary, isNotNull, reason: 'no summary line in:\n$report');
      expect(summary!.group(1), summary.group(2), reason: report);
      expect(int.parse(summary.group(2)!), greaterThan(70), reason: report);
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}

/// Ports nothing is listening on, found by letting the OS pick. All are
/// held open until every one is chosen, so the same port is not returned
/// twice.
Future<List<int>> _freePorts(int count) async {
  final sockets = [
    for (var i = 0; i < count; i++)
      await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
  ];
  final ports = [for (final s in sockets) s.port];
  for (final s in sockets) {
    await s.close();
  }
  return ports;
}

Future<void> _waitUntilListening(
  int port,
  Process server,
  StringBuffer log,
) async {
  var exited = false;
  unawaited(server.exitCode.then((_) => exited = true));
  final deadline = DateTime.now().add(const Duration(minutes: 3));
  while (DateTime.now().isBefore(deadline)) {
    if (exited) fail('the fixture server exited during start-up:\n$log');
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        port,
        timeout: const Duration(seconds: 1),
      );
      socket.destroy();
      return;
    } on SocketException {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  fail('the fixture server did not start listening on $port:\n$log');
}
