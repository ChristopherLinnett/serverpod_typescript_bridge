import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/discovery/module_discoverer.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('sptb_module_disc_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  /// Builds a synthetic Serverpod-shaped workspace:
  ///   <tempRoot>/
  ///     .dart_tool/package_config.json   (entries for `app_server` + every module)
  ///     app_server/                       (the user's app server)
  ///     <each-module>/
  ///       config/generator.yaml          (with type + nickname)
  void scaffoldWorkspace({
    required List<({String name, String type, String? nickname})> packages,
  }) {
    final entries = StringBuffer('[');
    for (var i = 0; i < packages.length; i++) {
      final pkg = packages[i];
      final pkgDir = Directory(p.join(tempRoot.path, pkg.name));
      pkgDir.createSync(recursive: true);
      if (pkg.type == 'module' || pkg.type == 'server') {
        final yaml = StringBuffer()
          ..writeln('type: ${pkg.type}');
        if (pkg.nickname != null) yaml.writeln('nickname: ${pkg.nickname}');
        File(p.join(pkgDir.path, 'config', 'generator.yaml'))
          ..parent.createSync(recursive: true)
          ..writeAsStringSync(yaml.toString());
      }
      entries.write(
        '{"name": "${pkg.name}", '
        '"rootUri": "file://${pkgDir.path}", '
        '"packageUri": "lib/", '
        '"languageVersion": "3.0"}',
      );
      if (i + 1 < packages.length) entries.write(',');
    }
    entries.write(']');
    final configDir = Directory(p.join(tempRoot.path, '.dart_tool'))
      ..createSync(recursive: true);
    File(p.join(configDir.path, 'package_config.json')).writeAsStringSync(
      '{"configVersion": 2, "packages": $entries}',
    );
  }

  test('returns empty list when project has no module deps', () {
    scaffoldWorkspace(packages: [
      (name: 'app_server', type: 'server', nickname: null),
      (name: 'plain_dep', type: 'none', nickname: null),
    ]);
    final modules = ModuleDiscoverer.discover(
      Directory(p.join(tempRoot.path, 'app_server')),
    );
    expect(modules, isEmpty);
  });

  test('detects module-type packages and skips non-module packages', () {
    scaffoldWorkspace(packages: [
      (name: 'app_server', type: 'server', nickname: null),
      (name: 'serverpod_auth_idp_server', type: 'module', nickname: 'auth'),
      (name: 'serverpod_chat_server', type: 'module', nickname: 'chat'),
      (name: 'random_pub_dep', type: 'none', nickname: null),
    ]);
    final modules = ModuleDiscoverer.discover(
      Directory(p.join(tempRoot.path, 'app_server')),
    );
    expect(modules.length, 2);
    expect(modules.map((m) => m.dartPkgName), [
      'serverpod_auth_idp_server',
      'serverpod_chat_server',
    ]);
    expect(modules.map((m) => m.nickname), ['auth', 'chat']);
  });

  test('returns modules sorted by dart-pkg name (deterministic output)', () {
    scaffoldWorkspace(packages: [
      (name: 'app_server', type: 'server', nickname: null),
      (name: 'zebra_module', type: 'module', nickname: 'zeb'),
      (name: 'apple_module', type: 'module', nickname: 'app'),
      (name: 'mango_module', type: 'module', nickname: 'man'),
    ]);
    final modules = ModuleDiscoverer.discover(
      Directory(p.join(tempRoot.path, 'app_server')),
    );
    expect(
      modules.map((m) => m.dartPkgName),
      ['apple_module', 'mango_module', 'zebra_module'],
    );
  });

  test('walks up to find the workspace package_config from a nested dir', () {
    scaffoldWorkspace(packages: [
      (name: 'app_server', type: 'server', nickname: null),
      (name: 'auth', type: 'module', nickname: 'auth'),
    ]);
    // Pretend the user invoked from a nested working directory.
    final nested = Directory(p.join(tempRoot.path, 'app_server', 'lib', 'src'))
      ..createSync(recursive: true);
    final modules = ModuleDiscoverer.discover(nested);
    expect(modules.length, 1);
    expect(modules.single.nickname, 'auth');
  });

  test('throws StateError when package_config.json is missing', () {
    final orphan = Directory(p.join(tempRoot.path, 'orphan'))
      ..createSync(recursive: true);
    expect(
      () => ModuleDiscoverer.discover(orphan),
      throwsA(isA<StateError>()),
    );
  });

  test('skips modules whose generator.yaml lacks a nickname', () {
    scaffoldWorkspace(packages: [
      (name: 'app_server', type: 'server', nickname: null),
      // Module with no nickname — invalid Serverpod module config.
      (name: 'broken_module', type: 'module', nickname: null),
      (name: 'good_module', type: 'module', nickname: 'good'),
    ]);
    final modules = ModuleDiscoverer.discover(
      Directory(p.join(tempRoot.path, 'app_server')),
    );
    expect(modules.length, 1);
    expect(modules.single.dartPkgName, 'good_module');
  });
}
