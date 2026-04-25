import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/discovery/server_directory_finder.dart';
import 'package:test/test.dart';

/// Helper: creates a fake "Serverpod server" directory on disk by writing a
/// minimal pubspec.yaml that declares the `serverpod` dependency. Mirrors
/// what `isServerDirectory` in `serverpod_cli/util/directory.dart` checks.
Directory _makeFakeServerDir(Directory parent, String name) {
  final dir = Directory(p.join(parent.path, name))..createSync(recursive: true);
  File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
environment:
  sdk: '^3.0.0'
dependencies:
  serverpod: ^3.4.7
''');
  return dir;
}

Directory _makeNonServerDir(Directory parent, String name) {
  final dir = Directory(p.join(parent.path, name))..createSync(recursive: true);
  File(p.join(dir.path, 'pubspec.yaml')).writeAsStringSync('''
name: $name
environment:
  sdk: '^3.0.0'
''');
  return dir;
}

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('sptb_finder_test_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  group('ServerDirectoryFinder.find', () {
    test('returns the directory itself when it is a server', () {
      final server = _makeFakeServerDir(tempRoot, 'my_server');
      final found = ServerDirectoryFinder.find(start: server);
      expect(p.canonicalize(found.path), p.canonicalize(server.path));
    });

    test('walks up the tree until it finds a server', () {
      final server = _makeFakeServerDir(tempRoot, 'my_server');
      final nested = Directory(p.join(server.path, 'lib', 'src', 'deep'))
        ..createSync(recursive: true);
      final found = ServerDirectoryFinder.find(start: nested);
      expect(p.canonicalize(found.path), p.canonicalize(server.path));
    });

    test('throws StateError when no server found up the chain', () {
      final orphan = _makeNonServerDir(tempRoot, 'orphan');
      expect(
        () => ServerDirectoryFinder.find(start: orphan),
        throwsA(isA<StateError>()),
      );
    });

    test('honours an explicit override directory when valid', () {
      final server = _makeFakeServerDir(tempRoot, 'my_server');
      final unrelated = _makeNonServerDir(tempRoot, 'unrelated');
      final found = ServerDirectoryFinder.find(
        start: unrelated,
        override: server.path,
      );
      expect(p.canonicalize(found.path), p.canonicalize(server.path));
    });

    test('throws StateError when override directory is not a server', () {
      final unrelated = _makeNonServerDir(tempRoot, 'unrelated');
      expect(
        () => ServerDirectoryFinder.find(override: unrelated.path),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when override directory does not exist', () {
      expect(
        () => ServerDirectoryFinder.find(
          override: p.join(tempRoot.path, 'does_not_exist'),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
