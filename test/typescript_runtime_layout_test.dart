// Smoke test for the TypeScript runtime under lib/runtime/typescript/.
// The Dart-side generator (lands in issue #4) copies these files verbatim
// into each generated client, so their presence is part of the package's
// public contract.
import 'dart:io';

import 'package:test/test.dart';

const _runtimeRoot = 'lib/runtime/typescript';

File _file(String relPath) => File('$_runtimeRoot/$relPath');

void main() {
  group('TypeScript runtime — required project files', () {
    for (final path in const [
      'package.json',
      'tsconfig.json',
      'README.md',
      'vitest.config.ts',
    ]) {
      test('$path exists', () {
        expect(_file(path).existsSync(), isTrue,
            reason: 'missing ${_file(path).absolute.path}');
      });
    }
  });

  group('TypeScript runtime — required source modules', () {
    for (final path in const [
      'src/index.ts',
      'src/types.ts',
      'src/exceptions.ts',
      'src/serialization.ts',
      'src/http_transport.ts',
      'src/endpoint.ts',
      'src/client.ts',
    ]) {
      test('$path exists', () {
        expect(_file(path).existsSync(), isTrue,
            reason: 'missing ${_file(path).absolute.path}');
      });
    }
  });

  test('package.json declares the expected scripts', () async {
    final src = await _file('package.json').readAsString();
    expect(src, contains('"build"'));
    expect(src, contains('"typecheck"'));
    expect(src, contains('"test"'));
  });

  test('tsconfig is strict', () async {
    final src = await _file('tsconfig.json').readAsString();
    expect(src, contains('"strict": true'));
  });

  test('index.ts re-exports every public module', () async {
    final src = await _file('src/index.ts').readAsString();
    for (final mod in const [
      'types',
      'exceptions',
      'serialization',
      'http_transport',
      'endpoint',
      'client',
    ]) {
      expect(src, contains("'./$mod.js'"),
          reason: 'expected re-export of $mod');
    }
  });
}
