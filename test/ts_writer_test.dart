import 'package:serverpod_typescript_bridge/src/emit/ts_writer.dart';
import 'package:test/test.dart';

void main() {
  group('TsWriter', () {
    test('writeln writes content with the current indent and a newline', () {
      final w = TsWriter()..writeln('hello');
      expect(w.toString(), 'hello\n');
    });

    test('blankLine emits exactly one newline with no indent', () {
      final w = TsWriter()..blankLine();
      expect(w.toString(), '\n');
    });

    test('indent body is indented two spaces per level', () {
      final w = TsWriter()..writeln('outer');
      w.indent(() => w.writeln('inner'));
      expect(w.toString(), 'outer\n  inner\n');
    });

    test('indent restores depth even after exception in body', () {
      final w = TsWriter();
      expect(
        () => w.indent(() => throw StateError('boom')),
        throwsA(isA<StateError>()),
      );
      w.writeln('after');
      expect(w.toString(), 'after\n',
          reason: 'depth should have been restored to 0');
    });

    test('docComment emits a single-line TSDoc for one line of input', () {
      final w = TsWriter()..docComment('A brief doc.');
      expect(w.toString(), '/** A brief doc. */\n');
    });

    test(
        'docComment strips Dart `///` prefixes and emits a multi-line block',
        () {
      final w = TsWriter()..docComment('/// First line.\n/// Second line.');
      expect(w.toString(), '/**\n * First line.\n * Second line.\n */\n');
    });

    test('docComment is a no-op for null and empty input', () {
      final empty = TsWriter()..docComment(null);
      expect(empty.toString(), '');
      final blank = TsWriter()..docComment('   ');
      expect(blank.toString(), '');
    });
  });
}
