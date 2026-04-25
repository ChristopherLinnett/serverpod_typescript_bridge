import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Asserts that bidirectional streaming endpoints (input `Stream<T>`
/// parameter + output `Stream<T>` return) emit a real call body —
/// not a "not supported in v0.1" stub — and route input streams
/// through the runtime's `inputStreams` channel.
void main() {
  final packageRoot = Directory.current.path;

  test(
    'chat endpoint (Stream<String> in, Stream<String> out) emits a real bidi body',
    () async {
      final tempOutput =
          Directory.systemTemp.createTempSync('sptb_bidi_e2e_');
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
        expect(result.exitCode, 0,
            reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}');

        final chatFile =
            File(p.join(tempOutput.path, 'src', 'endpoints', 'endpoint_chat.ts'));
        expect(chatFile.existsSync(), isTrue,
            reason: 'expected ${chatFile.absolute.path}');
        final src = await chatFile.readAsString();

        // No stub-throw should remain.
        expect(
          src,
          isNot(contains('not supported in v0.1')),
          reason: 'bidirectional streaming should be implemented, not stubbed',
        );

        // Real call shape:
        // - signature takes `streams: { messages: AsyncIterable<string> }`
        // - body delegates to callStreamingServerEndpoint with an
        //   inputStreams record
        expect(src, contains('streams: { messages: AsyncIterable<string>'));
        expect(src, contains('callStreamingServerEndpoint'));
        expect(src, contains("'messages'"),
            reason: 'inputStreams record must key on the wire param name');
        expect(src, contains('iterable: streams.messages'));
        expect(src, contains('encode:'));
      } finally {
        if (tempOutput.existsSync()) tempOutput.deleteSync(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
