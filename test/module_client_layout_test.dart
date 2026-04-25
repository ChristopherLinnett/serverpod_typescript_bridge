import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/discovery/module_client_layout.dart';
import 'package:test/test.dart';

import 'protocol_loader_test_helper.dart';

void main() {
  group('ModuleLayoutResolver', () {
    late Directory tempAppClientOut;

    setUp(() {
      tempAppClientOut =
          Directory.systemTemp.createTempSync('sptb_layout_app_');
    });

    tearDown(() {
      if (tempAppClientOut.existsSync()) {
        tempAppClientOut.deleteSync(recursive: true);
      }
    });

    test(
      'default: <module>_server → sibling dir <module>_typescript_client',
      () async {
        final config = await loadFixtureConfig();
        final resolver = ModuleLayoutResolver(
          appClientOutputDir: tempAppClientOut,
          config: config,
        );
        final layout = resolver.resolve('serverpod_auth_idp_server');
        expect(
          p.basename(layout.outputDir.path),
          'serverpod_auth_idp_typescript_client',
        );
        expect(
          p.equals(
            layout.outputDir.parent.path,
            tempAppClientOut.parent.path,
          ),
          isTrue,
          reason: 'module client should sit next to the app client',
        );
        expect(layout.npmPackageName, 'serverpod_auth_idp_typescript_client');
        expect(
          layout.relativeFromAppClient,
          '../serverpod_auth_idp_typescript_client',
        );
      },
    );

    test(
      'pkg names without _server suffix are appended directly',
      () async {
        final config = await loadFixtureConfig();
        final resolver = ModuleLayoutResolver(
          appClientOutputDir: tempAppClientOut,
          config: config,
        );
        final layout = resolver.resolve('weird_module_name');
        expect(
          p.basename(layout.outputDir.path),
          'weird_module_name_typescript_client',
        );
      },
    );
  });
}
