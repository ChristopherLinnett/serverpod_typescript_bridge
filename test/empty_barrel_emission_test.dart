// Regression coverage for the v0.2.3 empty-barrel fix: when a project
// (typically a Serverpod *module* like `serverpod_auth_core` that
// exposes only models / exceptions, no concrete endpoints) emits an
// empty `endpoints/index.ts` or `protocol/index.ts`, the file must
// still be a TS module — otherwise the consuming top-level barrel's
// `export * from './endpoints/index.js'` fails with `is not a module`.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_typescript_bridge/src/discovery/module_class_index.dart';
import 'package:serverpod_typescript_bridge/src/emit/endpoint_emitter.dart';
import 'package:serverpod_typescript_bridge/src/emit/generated_file_tracker.dart';
import 'package:serverpod_typescript_bridge/src/emit/model_emitter.dart';
import 'package:serverpod_typescript_bridge/src/emit/ts_type_mapper.dart';
import 'package:test/test.dart';

void main() {
  late Directory outputDir;

  setUp(() {
    outputDir = Directory.systemTemp.createTempSync('sptb_empty_barrel_');
  });

  tearDown(() {
    if (outputDir.existsSync()) outputDir.deleteSync(recursive: true);
  });

  GeneratedFileTracker freshTracker() {
    return GeneratedFileTracker([
      Directory(p.join(outputDir.path, 'src', 'protocol')),
      Directory(p.join(outputDir.path, 'src', 'endpoints')),
    ]);
  }

  TsTypeMapper bareMapper() {
    return TsTypeMapper(moduleIndex: ModuleClassIndex.empty);
  }

  test('EndpointEmitter writes `export {};` when there are zero endpoints',
      () {
    EndpointEmitter(
      outputDir: outputDir,
      tracker: freshTracker(),
      mapper: bareMapper(),
    ).emitAll(const []);

    final barrel =
        File(p.join(outputDir.path, 'src', 'endpoints', 'index.ts'));
    expect(barrel.existsSync(), isTrue,
        reason: 'endpoint barrel must exist even when no endpoints emit');
    final src = barrel.readAsStringSync();
    expect(src, contains('export {};'),
        reason:
            'TS treats a file with no top-level imports/exports as a script;'
            ' an explicit `export {};` is the canonical opt-in to module status');
    expect(src, isNot(contains("export * from")),
        reason: 'no per-endpoint re-exports should appear when none emitted');
  });

  test('ModelEmitter writes `export {};` when there are zero models', () {
    ModelEmitter(
      outputDir: outputDir,
      tracker: freshTracker(),
      mapper: bareMapper(),
    ).emitAll(const []);

    final barrel =
        File(p.join(outputDir.path, 'src', 'protocol', 'index.ts'));
    expect(barrel.existsSync(), isTrue,
        reason: 'protocol barrel must exist even when no models emit');
    final src = barrel.readAsStringSync();
    expect(src, contains('export {};'));
    expect(src, isNot(contains("export * from")),
        reason: 'no per-model re-exports should appear when none emitted');
  });
}
