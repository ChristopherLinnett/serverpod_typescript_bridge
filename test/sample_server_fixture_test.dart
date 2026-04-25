// Smoke test that asserts the sample-server fixture exists and exposes
// every Serverpod feature the v0.1 generator must support. Other test
// suites use this fixture as their parity oracle, so its surface is
// load-bearing.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _fixtureRoot = 'test/fixtures/sample_server';
const _serverPkg = '$_fixtureRoot/sample_server';

File _serverFile(String relPath) => File(p.join(_serverPkg, relPath));
File _fixtureFile(String relPath) => File(p.join('test/fixtures', relPath));

File _requireServerFile(String relPath) {
  final f = _serverFile(relPath);
  expect(
    f.existsSync(),
    isTrue,
    reason: 'missing fixture file: ${f.absolute.path}',
  );
  return f;
}

Future<String> _readServerFile(String relPath) =>
    _requireServerFile(relPath).readAsString();

void main() {
  group('sample_server fixture — top-level layout', () {
    test('server package directory exists', () {
      final dir = Directory(_serverPkg);
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'fixture server package not found at ${dir.absolute.path}',
      );
    });

    test('pubspec declares serverpod dependency', () async {
      final pubspec = await _readServerFile('pubspec.yaml');
      expect(pubspec, contains('serverpod:'));
    });

    test('fixtures README documents the fixture', () {
      // Issue #1 acceptance criteria: README at the fixtures root, not the
      // sample_server root — describes all fixtures (only one for now, but
      // others land with later issues e.g. module support).
      final readme = _fixtureFile('README.md');
      expect(
        readme.existsSync(),
        isTrue,
        reason: 'expected ${readme.absolute.path}',
      );
    });
  });

  group('sample_server fixture — endpoint coverage', () {
    test('primitives endpoint exists and uses every supported primitive',
        () async {
      final src = await _readServerFile('lib/src/endpoints/primitives_endpoint.dart');
      for (final type in const [
        'int', 'double', 'String', 'bool',
        'DateTime', 'Duration', 'BigInt', 'UuidValue',
      ]) {
        expect(src, contains(type), reason: 'expected primitive type: $type');
      }
    });

    test('models endpoint exchanges a custom model both directions', () async {
      final src = await _readServerFile('lib/src/endpoints/models_endpoint.dart');
      expect(src, contains('UserProfile'));
    });

    test('collections endpoint covers List, Set, Map<String,_> and Map<int,_>',
        () async {
      final src = await _readServerFile('lib/src/endpoints/collections_endpoint.dart');
      expect(src, contains('List<'));
      expect(src, contains('Set<'));
      expect(src, contains('Map<String,'));
      expect(src, contains('Map<int,'));
    });

    test('nullables endpoint takes and returns all-nullable surface', () async {
      final src = await _readServerFile('lib/src/endpoints/nullables_endpoint.dart');
      // Every parameter except `Session session` is nullable.
      expect(src, contains('?'));
    });

    test('auth endpoint requires login', () async {
      final src = await _readServerFile('lib/src/endpoints/auth_endpoint.dart');
      expect(src, contains('requireLogin'));
    });

    test('public endpoint marks a method @unauthenticatedClientCall',
        () async {
      final src = await _readServerFile('lib/src/endpoints/public_endpoint.dart');
      expect(src, contains('@unauthenticatedClientCall'));
    });

    test('legacy endpoint includes a @deprecated method', () async {
      final src = await _readServerFile('lib/src/endpoints/legacy_endpoint.dart');
      expect(src, contains('@Deprecated'));
    });

    test('streaming endpoint exposes a Stream<T> return', () async {
      final src = await _readServerFile('lib/src/endpoints/streaming_endpoint.dart');
      expect(src, contains('Stream<'));
      expect(src, contains('async*'));
    });

    test('chat endpoint exposes both an input Stream<T> and an output Stream<T>',
        () async {
      final src = await _readServerFile('lib/src/endpoints/chat_endpoint.dart');
      // Input stream parameter and output stream return.
      expect(src, contains('Stream<'));
      // crude check for two distinct Stream<...> uses
      final streamCount = 'Stream<'.allMatches(src).length;
      expect(streamCount, greaterThanOrEqualTo(2),
          reason: 'expected both an input Stream<T> and an output Stream<T>');
    });
  });

  group('sample_server fixture — model coverage', () {
    test('user_profile.spy.yaml is a simple class with primitives + nullables',
        () async {
      final src = await _readServerFile('lib/src/models/user_profile.spy.yaml');
      expect(src, contains('class: UserProfile'));
    });

    test('admin_profile.spy.yaml extends user_profile non-sealed', () async {
      final src = await _readServerFile('lib/src/models/admin_profile.spy.yaml');
      expect(src, contains('class: AdminProfile'));
      expect(src, contains('extends: UserProfile'));
    });

    test('animal sealed hierarchy has at least two concrete subclasses',
        () async {
      final base = await _readServerFile('lib/src/models/animal.spy.yaml');
      expect(base, contains('class: Animal'));
      expect(base, contains('sealed: true'));
      _requireServerFile('lib/src/models/dog.spy.yaml');
      _requireServerFile('lib/src/models/cat.spy.yaml');
    });

    test('priority enum opts into byIndex serialization', () async {
      final src = await _readServerFile('lib/src/models/priority.spy.yaml');
      expect(src, contains('enum: Priority'));
      expect(src, contains('serialized: byIndex'),
          reason: 'priority.spy.yaml is the byIndex variant');
    });

    test('colour enum opts into byName serialization', () async {
      final src = await _readServerFile('lib/src/models/colour.spy.yaml');
      expect(src, contains('enum: Colour'));
      expect(src, contains('serialized: byName'));
    });

    test('not_found_exception declares a SerializableException', () async {
      final src = await _readServerFile('lib/src/models/not_found_exception.spy.yaml');
      expect(src, contains('exception: NotFoundException'));
    });
  });

  group('sample_server fixture — doc-comment coverage', () {
    test('models include single-line and multi-line doc comments', () async {
      final src = await _readServerFile('lib/src/models/user_profile.spy.yaml');
      // Serverpod YAML doc-comment syntax uses `###` lines.
      final docLines =
          src.split('\n').where((l) => l.trimLeft().startsWith('###')).toList();
      expect(docLines.length, greaterThanOrEqualTo(3));
    });

    test('endpoints include {@template} / {@macro} doc comments somewhere',
        () async {
      final src = await _readServerFile('lib/src/endpoints/primitives_endpoint.dart');
      expect(src, anyOf(contains('{@template'), contains('{@macro')));
    });
  });

  group('sample_server fixture — generated artifacts', () {
    test('generated server protocol.dart is committed for reference', () {
      _requireServerFile('lib/src/generated/protocol.dart');
    });

    test('generated dart client package is committed for reference', () {
      final dir = Directory('$_fixtureRoot/sample_client/lib/src/protocol');
      expect(
        dir.existsSync(),
        isTrue,
        reason: 'commit serverpod-generated dart client at ${dir.absolute.path}'
            ' as the parity oracle',
      );
    });
  });
}
