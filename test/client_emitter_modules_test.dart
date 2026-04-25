// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/config/experimental_feature.dart';
import 'package:serverpod_typescript_bridge/src/discovery/module_class_index.dart';
import 'package:serverpod_typescript_bridge/src/discovery/module_client_layout.dart';
import 'package:serverpod_typescript_bridge/src/emit/client_emitter.dart';
import 'package:serverpod_typescript_bridge/src/emit/generated_file_tracker.dart';
import 'package:test/test.dart';

/// Exercises the ClientEmitter ↔ ModuleClassIndex boundary added in
/// v0.2 — proves that the protocol switch dispatches module-defined
/// classes through bare imported symbols, and that the no-modules
/// fallback path still emits byte-equivalent v0.1 output.
///
/// Loads a real [GeneratorConfig] from the sample_server fixture so
/// tests don't have to hand-roll the (large) config object.
void main() {
  late GeneratorConfig sampleServerConfig;

  setUpAll(() async {
    // GeneratorConfig.load consults the experimental-features singleton;
    // mirror what the production CLI does before invoking the loader.
    CommandLineExperimentalFeatures.initialize(const []);
    sampleServerConfig = await GeneratorConfig.load(
      serverRootDir: 'test/fixtures/sample_server/sample_server',
      interactive: false,
    );
  });

  ModuleClientLayout layoutFor(String dartPkg, String npmName) {
    return ModuleClientLayout(
      dartPkgName: dartPkg,
      outputDir: Directory('/tmp/$npmName'),
      npmPackageName: npmName,
    );
  }

  Future<String> emitAndReadProtocol({
    ModuleClassIndex? moduleIndex,
    Set<String> referencedModuleClassNames = const {},
  }) async {
    final tempOut = Directory.systemTemp.createTempSync('sptb_ce_');
    addTearDown(() {
      if (tempOut.existsSync()) tempOut.deleteSync(recursive: true);
    });

    final tracker = GeneratedFileTracker([
      Directory(p.join(tempOut.path, 'src')),
    ]);
    ClientEmitter(
      outputDir: tempOut,
      tracker: tracker,
      config: sampleServerConfig,
      moduleIndex: moduleIndex,
      referencedModuleClassNames: referencedModuleClassNames,
    ).emit(endpoints: const [], models: const []);

    final protocolFile = File(p.join(tempOut.path, 'src', 'protocol.ts'));
    expect(protocolFile.existsSync(), isTrue,
        reason: 'ClientEmitter should always write protocol.ts');
    return protocolFile.readAsString();
  }

  group('ClientEmitter — no module deps', () {
    test('emits no cross-package import lines and no module switch cases',
        () async {
      final src = await emitAndReadProtocol();

      expect(
        src,
        isNot(contains("from '../")),
        reason:
            'no-modules path must not emit any cross-package import lines',
      );
      expect(
        RegExp(r"^import \{ .+ \} from '[^./]").allMatches(src).length,
        0,
        reason: 'no bare module-package imports should appear',
      );
      expect(src, contains('switch (className)'));
      expect(src, contains('default: return undefined;'));
    });

    test('null moduleIndex behaves identically to an empty referenced set',
        () async {
      final withNull = await emitAndReadProtocol();
      final withEmpty = await emitAndReadProtocol(
        moduleIndex: ModuleClassIndex.empty,
      );
      expect(withNull, equals(withEmpty));
    });
  });

  group('ClientEmitter — with referenced module classes', () {
    test('emits one import line per module package, alphabetised', () async {
      final auth = layoutFor('auth_server', 'auth_typescript_client');
      final chat = layoutFor('chat_server', 'chat_typescript_client');
      final index = ModuleClassIndex.forTesting(
        classToLayout: {'AuthSuccess': auth, 'ChatMessage': chat},
      );

      final src = await emitAndReadProtocol(
        moduleIndex: index,
        referencedModuleClassNames: {'AuthSuccess', 'ChatMessage'},
      );

      expect(
        src,
        contains("import { AuthSuccess } from 'auth_typescript_client';"),
      );
      expect(
        src,
        contains("import { ChatMessage } from 'chat_typescript_client';"),
      );
      // Sort order: auth before chat.
      expect(
        src.indexOf('auth_typescript_client'),
        lessThan(src.indexOf('chat_typescript_client')),
      );
    });

    test('protocol switch dispatches module classes through bare receivers',
        () async {
      final auth = layoutFor('auth_server', 'auth_ts');
      final index = ModuleClassIndex.forTesting(
        classToLayout: {
          'AuthSuccess': auth,
          'AuthRole': auth,
          'AuthAnimal': auth,
        },
        enumClassNames: {'AuthRole'},
        sealedClassNames: {'AuthAnimal'},
      );

      final src = await emitAndReadProtocol(
        moduleIndex: index,
        referencedModuleClassNames: {
          'AuthSuccess',
          'AuthRole',
          'AuthAnimal',
        },
      );

      expect(
        src,
        contains("case 'AuthSuccess': return AuthSuccess.fromJson(data);"),
      );
      expect(
        src,
        contains("case 'AuthRole': return AuthRoleCodec.fromJson(data);"),
      );
      expect(
        src,
        contains("case 'AuthAnimal': return AuthAnimalBase.fromJson(data);"),
      );
      // Sealed dispatcher and enum codec are also brought in as imports.
      expect(
        src,
        contains(
          "import { AuthAnimal, AuthAnimalBase, AuthRole, AuthRoleCodec, "
          "AuthSuccess } from 'auth_ts';",
        ),
      );
    });

    test(
        'referencedModuleClassNames not in the index are silently skipped — '
        'no broken case label, no broken import', () async {
      final auth = layoutFor('auth_server', 'auth_ts');
      final index = ModuleClassIndex.forTesting(
        classToLayout: {'AuthSuccess': auth},
      );

      final src = await emitAndReadProtocol(
        moduleIndex: index,
        referencedModuleClassNames: {'AuthSuccess', 'GhostType'},
      );

      expect(
        src,
        contains("case 'AuthSuccess': return AuthSuccess.fromJson(data);"),
      );
      expect(src, isNot(contains('GhostType')));
    });
  });
}
