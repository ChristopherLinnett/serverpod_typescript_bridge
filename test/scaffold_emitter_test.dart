import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/emit/generated_file_tracker.dart';
import 'package:serverpod_typescript_bridge/src/emit/output_paths.dart';
import 'package:serverpod_typescript_bridge/src/emit/scaffold_emitter.dart';
import 'package:test/test.dart';

import 'protocol_loader_test_helper.dart';

void main() {
  group('ScaffoldEmitter.emit', () {
    late Directory tempOutput;

    setUp(() {
      tempOutput =
          Directory.systemTemp.createTempSync('sptb_scaffold_test_');
    });

    tearDown(() {
      if (tempOutput.existsSync()) tempOutput.deleteSync(recursive: true);
    });

    Future<void> emit() async {
      final config = await loadFixtureConfig();
      final paths = OutputPaths.resolve(
        config,
        explicitOutput: tempOutput.path,
      );
      final tracker = GeneratedFileTracker([
        Directory(p.join(paths.outputDir.path, 'src')),
      ]);
      final scaffold = ScaffoldEmitter(outputPaths: paths, tracker: tracker);
      await scaffold.emit();
    }

    File outFile(String rel) => File(p.join(tempOutput.path, rel));

    test('writes package.json with the resolved package name', () async {
      await emit();
      final pkg = outFile('package.json');
      expect(pkg.existsSync(), isTrue);
      final src = await pkg.readAsString();
      expect(src, contains('"name": "sample_typescript_client"'));
      expect(src, contains('"type": "module"'));
      expect(src, contains('"main": "./dist/index.js"'));
    });

    test('writes a strict tsconfig.json', () async {
      await emit();
      final src = await outFile('tsconfig.json').readAsString();
      expect(src, contains('"strict": true'));
      expect(src, contains('"target": "ES2022"'));
      expect(src, contains('"module": "ESNext"'));
    });

    test('writes .gitignore covering node_modules and dist', () async {
      await emit();
      final src = await outFile('.gitignore').readAsString();
      expect(src, contains('node_modules/'));
      expect(src, contains('dist/'));
    });

    test('writes a barrel src/index.ts that re-exports the runtime',
        () async {
      await emit();
      final src = await outFile('src/index.ts').readAsString();
      expect(src, contains("export * from './runtime/index.js'"));
    });

    test('copies every runtime source module into src/runtime/', () async {
      await emit();
      for (final mod in const [
        'index.ts',
        'types.ts',
        'exceptions.ts',
        'serialization.ts',
        'http_transport.ts',
        'endpoint.ts',
        'client.ts',
      ]) {
        final f = outFile('src/runtime/$mod');
        expect(f.existsSync(), isTrue,
            reason: 'expected ${f.absolute.path}');
      }
    });

    test('does NOT copy vitest test files into the generated package',
        () async {
      await emit();
      final dir = Directory(p.join(tempOutput.path, 'src', 'runtime'));
      final hasTests = dir
          .listSync(recursive: true)
          .whereType<File>()
          .any((f) => f.path.endsWith('.test.ts'));
      expect(hasTests, isFalse);
    });
  });
}
