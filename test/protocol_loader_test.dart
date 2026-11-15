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

  group('ProtocolLoader.synthesizeModuleConfig (against sample_module)', () {
    final moduleDir = Directory('test/fixtures/sample_module/testmod_server');

    test('names the project as Serverpod does: the package without _server',
        () {
      final config = ProtocolLoader.synthesizeModuleConfig(moduleDir);

      // The name is what a module's class names are prefixed with on the
      // wire (`testmod.ModuleClass`), so it has to match the name
      // `GeneratorConfig.load` gives the same package.
      expect(config.name, 'testmod');
      expect(config.serverPackage, 'testmod_server');
      expect(config.dartClientPackage, 'testmod_client');
      expect(config.type, PackageType.module);
    });

    test('agrees with GeneratorConfig.load on the project name', () async {
      final loaded = await GeneratorConfig.load(
        serverRootDir: moduleDir.path,
        interactive: false,
      );

      expect(ProtocolLoader.synthesizeModuleConfig(moduleDir).name, loaded.name);
    });
  });
}
