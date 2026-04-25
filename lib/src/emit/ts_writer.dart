/// Indent-aware string buffer for emitting TypeScript files.
///
/// Deliberately minimal — just enough for our emitter to stay readable
/// without pulling in a full AST library.
class TsWriter {
  final StringBuffer _buf = StringBuffer();
  int _depth = 0;
  static const _indentUnit = '  ';

  /// Writes [text] at the current indent, followed by a newline.
  void writeln([String text = '']) {
    if (text.isEmpty) {
      _buf.writeln();
      return;
    }
    _buf
      ..write(_indentUnit * _depth)
      ..writeln(text);
  }

  /// Writes [text] *raw* — no indent prefix, no trailing newline.
  void writeRaw(String text) {
    _buf.write(text);
  }

  /// Writes a blank line.
  void blankLine() {
    _buf.writeln();
  }

  /// Indents one level for the duration of [body].
  void indent(void Function() body) {
    _depth += 1;
    try {
      body();
    } finally {
      _depth -= 1;
    }
  }

  /// Writes [docComment] as a TSDoc block (`/** … */`) above the next
  /// declaration. No-op for null/empty docs.
  void docComment(String? docComment) {
    if (docComment == null || docComment.trim().isEmpty) return;
    final lines = docComment
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^/// ?'), ''))
        .toList();
    if (lines.length == 1) {
      writeln('/** ${lines.single} */');
      return;
    }
    writeln('/**');
    for (final line in lines) {
      if (line.isEmpty) {
        writeln(' *');
      } else {
        writeln(' * $line');
      }
    }
    writeln(' */');
  }

  @override
  String toString() => _buf.toString();
}
