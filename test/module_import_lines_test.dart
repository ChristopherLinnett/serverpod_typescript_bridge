// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_typescript_bridge/src/discovery/module_class_index.dart';
import 'package:serverpod_typescript_bridge/src/discovery/module_client_layout.dart';
import 'package:serverpod_typescript_bridge/src/emit/module_import_lines.dart';
import 'package:test/test.dart';

void main() {
  ModuleClientLayout layoutFor(String dartPkg, String npmName) {
    return ModuleClientLayout(
      dartPkgName: dartPkg,
      outputDir: Directory('/tmp/$npmName'),
      npmPackageName: npmName,
    );
  }

  TypeDefinition simple(String className, {bool nullable = false}) {
    return TypeDefinition(className: className, nullable: nullable);
  }

  TypeDefinition listOf(TypeDefinition elem) {
    return TypeDefinition(
      className: 'List',
      generics: [elem],
      nullable: false,
    );
  }

  TypeDefinition mapOf(TypeDefinition key, TypeDefinition value) {
    return TypeDefinition(
      className: 'Map',
      generics: [key, value],
      nullable: false,
    );
  }

  test('returns no import lines when no module types appear', () {
    final index = ModuleClassIndex.forTesting(classToLayout: const {});
    final lines = ModuleImportLines(index).forTypes([
      simple('String'),
      simple('int'),
      listOf(simple('SomeLocalType')),
    ]);
    expect(lines, isEmpty);
  });

  test('emits one import per module package, alphabetised', () {
    final auth = layoutFor('auth_server', 'auth_typescript_client');
    final chat = layoutFor('chat_server', 'chat_typescript_client');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {'AuthSuccess': auth, 'ChatMessage': chat},
    );

    final lines = ModuleImportLines(index).forTypes([
      simple('AuthSuccess'),
      simple('ChatMessage'),
    ]);

    expect(lines, [
      "import { AuthSuccess } from 'auth_typescript_client';",
      "import { ChatMessage } from 'chat_typescript_client';",
    ]);
  });

  test('collapses multiple references to the same module into one line', () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {
        'AuthSuccess': auth,
        'AuthFailure': auth,
        'AuthChallenge': auth,
      },
    );

    final lines = ModuleImportLines(index).forTypes([
      simple('AuthSuccess'),
      simple('AuthChallenge'),
      simple('AuthFailure'),
    ]);

    expect(lines, [
      "import { AuthChallenge, AuthFailure, AuthSuccess } from 'auth_ts';",
    ]);
  });

  test('walks generics — List<ModuleType> brings in the inner module class',
      () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {'AuthUser': auth},
    );

    final lines = ModuleImportLines(index).forTypes([
      listOf(simple('AuthUser')),
      mapOf(simple('String'), listOf(simple('AuthUser'))),
    ]);

    expect(lines, ["import { AuthUser } from 'auth_ts';"]);
  });

  test('enums also bring in their Codec sibling', () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {'Role': auth},
      enumClassNames: {'Role'},
    );

    final lines = ModuleImportLines(index).forTypes([simple('Role')]);

    expect(lines, ["import { Role, RoleCodec } from 'auth_ts';"]);
  });

  test('sealed bases also bring in their Base dispatcher sibling', () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {'Animal': auth},
      sealedClassNames: {'Animal'},
    );

    final lines = ModuleImportLines(index).forTypes([simple('Animal')]);

    expect(lines, ["import { Animal, AnimalBase } from 'auth_ts';"]);
  });

  test('mix of plain, sealed, and enum module classes from one package', () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {
        'AuthSuccess': auth,
        'Animal': auth,
        'Role': auth,
      },
      sealedClassNames: {'Animal'},
      enumClassNames: {'Role'},
    );

    final lines = ModuleImportLines(index).forTypes([
      simple('AuthSuccess'),
      simple('Animal'),
      simple('Role'),
    ]);

    expect(lines, [
      "import { Animal, AnimalBase, AuthSuccess, Role, RoleCodec } "
          "from 'auth_ts';",
    ]);
  });

  test('ignores non-module class names entirely', () {
    final auth = layoutFor('auth_server', 'auth_ts');
    final index = ModuleClassIndex.forTesting(
      classToLayout: {'AuthUser': auth},
    );

    final lines = ModuleImportLines(index).forTypes([
      simple('SomeLocalType'),
      simple('AnotherUnknownType'),
    ]);

    expect(lines, isEmpty);
  });
}
