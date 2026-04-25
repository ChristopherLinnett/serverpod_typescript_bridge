import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/emit/generated_file_tracker.dart';
import 'package:test/test.dart';

void main() {
  group('GeneratedFileTracker.sweepOrphans', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('sptb_tracker_test_');
    });

    tearDown(() {
      if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
    });

    File makeFile(String rel, {String contents = '// stub\n'}) {
      final f = File(p.join(tempRoot.path, rel));
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(contents);
      return f;
    }

    test('keeps files that were recorded as written this run', () {
      final kept = makeFile('src/kept.ts');
      final tracker = GeneratedFileTracker([Directory(p.join(tempRoot.path, 'src'))]);
      tracker.recordWrite(kept);
      tracker.sweepOrphans();
      expect(kept.existsSync(), isTrue);
    });

    test('deletes any .ts file under a managed dir that was NOT recorded',
        () {
      final orphan = makeFile('src/orphan.ts');
      final tracker = GeneratedFileTracker([Directory(p.join(tempRoot.path, 'src'))]);
      tracker.sweepOrphans();
      expect(orphan.existsSync(), isFalse);
    });

    test('only sweeps managed directories', () {
      final outsideManaged = makeFile('outside/file.ts');
      final tracker = GeneratedFileTracker([Directory(p.join(tempRoot.path, 'src'))]);
      tracker.sweepOrphans();
      expect(outsideManaged.existsSync(), isTrue);
    });

    test('only sweeps .ts files (leaves package.json etc alone)', () {
      final pkgJson = makeFile('src/package.json', contents: '{}');
      final tracker = GeneratedFileTracker([Directory(p.join(tempRoot.path, 'src'))]);
      tracker.sweepOrphans();
      expect(pkgJson.existsSync(), isTrue);
    });

    test('does nothing if a managed directory does not exist', () {
      final tracker = GeneratedFileTracker([
        Directory(p.join(tempRoot.path, 'never_created')),
      ]);
      // Should not throw.
      expect(() => tracker.sweepOrphans(), returnsNormally);
    });
  });
}
