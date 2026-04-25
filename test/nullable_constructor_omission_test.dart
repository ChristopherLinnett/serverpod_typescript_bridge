// Regression coverage for the v0.2.4 ergonomics fix: nullable model
// and exception fields should be OMITTABLE on the constructor's
// `init: {...}` bag (callers can write `new Foo({ name: 'x' })`
// instead of having to pad every nullable field with `null`).
// Non-nullable fields stay required; the runtime field type stays
// honest at `T | null` because the body defaults omitted to `null`.
//
// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_typescript_bridge/src/discovery/module_class_index.dart';
import 'package:serverpod_typescript_bridge/src/emit/generated_file_tracker.dart';
import 'package:serverpod_typescript_bridge/src/emit/model_emitter.dart';
import 'package:serverpod_typescript_bridge/src/emit/ts_type_mapper.dart';
import 'package:test/test.dart';

void main() {
  late Directory outputDir;

  setUp(() {
    outputDir = Directory.systemTemp.createTempSync('sptb_nullable_ctor_');
  });

  tearDown(() {
    if (outputDir.existsSync()) outputDir.deleteSync(recursive: true);
  });

  GeneratedFileTracker freshTracker() {
    return GeneratedFileTracker([
      Directory(p.join(outputDir.path, 'src', 'protocol')),
    ]);
  }

  TsTypeMapper bareMapper(Set<String> projectClassNames) {
    return TsTypeMapper(
      moduleIndex: ModuleClassIndex.empty,
      projectClassNames: projectClassNames,
    );
  }

  SerializableModelFieldDefinition field(
    String name,
    String className, {
    bool nullable = false,
  }) {
    return SerializableModelFieldDefinition(
      name: name,
      type: TypeDefinition(className: className, nullable: nullable),
      scope: ModelFieldScopeDefinition.all,
      shouldPersist: false,
    );
  }

  TypeDefinition selfType(String className) =>
      TypeDefinition(className: className, nullable: false);

  group('ModelEmitter — nullable fields in constructor init', () {
    test(
        'mixed nullable + non-nullable model: nullable becomes optional, '
        'non-nullable stays required, body defaults nullable to null', () {
      final model = ModelClassDefinition(
        fileName: 'get_joined_dives_request',
        sourceFileName: 'get_joined_dives_request.spy.yaml',
        className: 'GetJoinedDivesRequest',
        type: selfType('GetJoinedDivesRequest'),
        serverOnly: false,
        manageMigration: false,
        isSealed: false,
        isImmutable: false,
        fields: [
          field('isCompleted', 'bool'),
          field('count', 'int'),
          field('offset', 'int'),
          field('startDate', 'DateTime', nullable: true),
          field('endDate', 'DateTime', nullable: true),
          field('diveType', 'String', nullable: true),
        ],
      );

      ModelEmitter(
        outputDir: outputDir,
        tracker: freshTracker(),
        mapper: bareMapper({'GetJoinedDivesRequest'}),
      ).emitAll([model]);

      final src = File(p.join(
        outputDir.path,
        'src',
        'protocol',
        'get_joined_dives_request.ts',
      )).readAsStringSync();

      // Required scalars stay `name: T;` in the init bag.
      expect(src, contains('isCompleted: boolean;'));
      expect(src, contains('count: number;'));
      expect(src, contains('offset: number;'));
      // Nullable scalars become `name?: T | null;` in the init bag.
      expect(src, contains('startDate?: Date | null;'));
      expect(src, contains('endDate?: Date | null;'));
      expect(src, contains('diveType?: string | null;'));
      // Constructor body: nullable fields default to null on omission.
      expect(src, contains('this.startDate = init.startDate ?? null;'));
      expect(src, contains('this.endDate = init.endDate ?? null;'));
      expect(src, contains('this.diveType = init.diveType ?? null;'));
      // Non-nullable assignments stay direct.
      expect(src, contains('this.isCompleted = init.isCompleted;'));
      expect(src, contains('this.count = init.count;'));
      expect(src, isNot(contains('this.isCompleted = init.isCompleted ?? null')),
          reason: 'non-nullable fields must not get the null fallback');
    });

    test(
        'declared field types stay `T | null` post-construction so the runtime '
        'shape matches the declared shape', () {
      final model = ModelClassDefinition(
        fileName: 'profile',
        sourceFileName: 'profile.spy.yaml',
        className: 'Profile',
        type: selfType('Profile'),
        serverOnly: false,
        manageMigration: false,
        isSealed: false,
        isImmutable: false,
        fields: [field('avatar', 'String', nullable: true)],
      );

      ModelEmitter(
        outputDir: outputDir,
        tracker: freshTracker(),
        mapper: bareMapper({'Profile'}),
      ).emitAll([model]);

      final src = File(p.join(
        outputDir.path, 'src', 'protocol', 'profile.ts',
      )).readAsStringSync();

      // The CLASS field declaration remains `T | null` (NOT `T | null | undefined`).
      // Only the `init:` bag relaxes to optional.
      expect(src, contains('avatar: string | null;'));
      expect(src, contains('avatar?: string | null;'),
          reason: 'init bag should make the nullable optional');
    });
  });

  group('ModelEmitter — exception classes get the same treatment', () {
    test(
        'nullable exception fields are optional on init; required ones stay',
        () {
      final ex = ExceptionClassDefinition(
        fileName: 'not_found_exception',
        sourceFileName: 'not_found_exception.spy.yaml',
        className: 'NotFoundException',
        type: selfType('NotFoundException'),
        serverOnly: false,
        fields: [
          field('message', 'String'),
          field('resourceId', 'String', nullable: true),
        ],
      );

      ModelEmitter(
        outputDir: outputDir,
        tracker: freshTracker(),
        mapper: bareMapper({'NotFoundException'}),
      ).emitAll([ex]);

      final src = File(p.join(
        outputDir.path,
        'src',
        'protocol',
        'not_found_exception.ts',
      )).readAsStringSync();

      expect(src, contains('message: string;'),
          reason: 'required field stays required in init bag');
      expect(src, contains('resourceId?: string | null;'),
          reason: 'nullable field becomes optional in init bag');
      expect(src, contains('this.resourceId = init.resourceId ?? null;'),
          reason: 'omitted nullable defaults to null at construction');
      expect(src, contains('this.message = init.message;'),
          reason: 'required field is assigned directly');
    });
  });
}
