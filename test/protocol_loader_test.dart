import 'dart:io';

import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_typescript_bridge/src/analyzer/protocol_loader.dart';
import 'package:test/test.dart';

/// Loads the IR from the v0.1 fixture once and asserts the surface
/// counts and contents match what the fixture should expose.
void main() {
  group('ProtocolLoader.load (against sample_server fixture)', () {
    final fixtureServer = Directory(
      'test/fixtures/sample_server/sample_server',
    );
    late ProtocolDefinition ir;

    setUpAll(() async {
      expect(
        fixtureServer.existsSync(),
        isTrue,
        reason: 'fixture server package missing — run `dart test '
            'test/sample_server_fixture_test.dart` to diagnose',
      );
      ir = await ProtocolLoader.load(fixtureServer);
    });

    test('returns a non-empty ProtocolDefinition', () {
      expect(ir.endpoints, isNotEmpty);
      expect(ir.models, isNotEmpty);
    });

    test('endpoints include every endpoint class authored in the fixture', () {
      final endpointNames = ir.endpoints.map((e) => e.name).toSet();
      expect(
        endpointNames,
        containsAll(<String>[
          'primitives',
          'models',
          'collections',
          'nullables',
          'auth',
          'public',
          'legacy',
          'streaming',
          'chat',
        ]),
      );
    });

    test('models include every YAML model authored in the fixture', () {
      final modelNames = ir.models.map((m) => m.className).toSet();
      expect(
        modelNames,
        containsAll(<String>[
          'UserProfile',
          'AdminProfile',
          'Animal',
          'Dog',
          'Cat',
          'Priority',
          'Colour',
          'NotFoundException',
        ]),
      );
    });

    test('preserves at least one method on the primitives endpoint', () {
      final primitives = ir.endpoints.firstWhere((e) => e.name == 'primitives');
      expect(primitives.methods, isNotEmpty);
    });
  });
}
