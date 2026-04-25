// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart';

import 'generated_file_tracker.dart';
import 'ts_type_mapper.dart';
import 'ts_writer.dart';

const _generatedHeader = '''
// AUTOMATICALLY GENERATED — DO NOT EDIT BY HAND
// To regenerate, run: dart run serverpod_typescript_bridge generate
''';

/// Emits one TS file per Serverpod endpoint, plus an `endpoints/index.ts`
/// barrel re-exporting them all. Streaming methods emit a stub that
/// throws — real streaming support is added in issue #10.
class EndpointEmitter {
  EndpointEmitter({
    required this.outputDir,
    required this.tracker,
    required this.mapper,
  });

  final Directory outputDir;
  final GeneratedFileTracker tracker;
  final TsTypeMapper mapper;

  /// Emits every concrete endpoint in [endpoints]. Returns the list of
  /// emitted basenames (without the `.ts` suffix), in alphabetical order.
  List<String> emitAll(List<EndpointDefinition> endpoints) {
    final emitted = <String>[];
    for (final ep in endpoints) {
      if (ep.isAbstract) continue;
      emitted.add(_emitEndpoint(ep));
    }
    emitted.sort();
    _emitBarrel(emitted);
    return emitted;
  }

  void _emitBarrel(List<String> filenames) {
    final w = TsWriter()..writeRaw(_generatedHeader);
    for (final f in filenames) {
      final stem = f.replaceAll(RegExp(r'\.ts$'), '');
      w.writeln("export * from './$stem.js';");
    }
    _writeFile('index.ts', w.toString());
  }

  String _emitEndpoint(EndpointDefinition ep) {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';")
      ..writeln("import * as p from '../protocol/index.js';")
      ..blankLine();

    final className = 'Endpoint${_pascalCase(ep.name)}';

    w.docComment(ep.documentationComment);
    w.writeln('export class $className extends r.EndpointRef {');
    w.indent(() {
      w.writeln("override get name(): string { return '${ep.name}'; }");
      w.blankLine();

      for (final method in ep.methods) {
        _emitMethod(w, ep, method);
      }
    });
    w.writeln('}');

    return _writeFile('endpoint_${_filenameStem(ep.name)}.ts', w.toString());
  }

  void _emitMethod(TsWriter w, EndpointDefinition ep, MethodDefinition method) {
    w.docComment(method.documentationComment);
    final isDeprecated =
        method.annotations.any((a) => a.name == 'Deprecated' || a.name == 'deprecated');
    if (isDeprecated) w.writeln('/** @deprecated */');

    final isStreaming = method is MethodStreamDefinition ||
        method.parameters.any((p) => p.type.className == 'Stream') ||
        method.parametersPositional.any((p) => p.type.className == 'Stream') ||
        method.parametersNamed.any((p) => p.type.className == 'Stream');

    final signature = _buildSignature(method);
    w.writeln('async ${method.name}(${signature.params}): ${signature.returnType} {');
    w.indent(() {
      if (isStreaming) {
        w.writeln(
          "throw new Error('Streaming endpoint methods are not supported in v0.1 — see issue #10.');",
        );
        return;
      }
      _emitMethodBody(w, ep, method, signature);
    });
    w.writeln('}');
    w.blankLine();
  }

  _Signature _buildSignature(MethodDefinition method) {
    final params = <String>[];
    for (final p in method.parameters) {
      params.add('${_safe(p.name)}: ${mapper.map(p.type).tsType}');
    }
    for (final p in method.parametersPositional) {
      params.add('${_safe(p.name)}?: ${mapper.map(p.type).tsType}');
    }
    if (method.parametersNamed.isNotEmpty) {
      final inner = method.parametersNamed
          .map((p) {
            final tsType = mapper.map(p.type).tsType;
            return p.required
                ? '${_safe(p.name)}: $tsType'
                : '${_safe(p.name)}?: $tsType';
          })
          .join('; ');
      params.add('named: { $inner }');
    }

    final returnInner = _futureInner(method.returnType);
    final tsReturn = mapper.map(returnInner).tsType;
    final asyncReturn = tsReturn == 'void' ? 'Promise<void>' : 'Promise<$tsReturn>';

    return _Signature(
      params: params.join(', '),
      returnType: asyncReturn,
      returnInner: returnInner,
      tsReturnInner: tsReturn,
    );
  }

  void _emitMethodBody(
    TsWriter w,
    EndpointDefinition ep,
    MethodDefinition method,
    _Signature signature,
  ) {
    final argEntries = <String>[];
    for (final p in method.parameters) {
      argEntries.add('${_safe(p.name)}: ${_safe(p.name)}');
    }
    for (final p in method.parametersPositional) {
      argEntries.add('${_safe(p.name)}: ${_safe(p.name)}');
    }
    for (final p in method.parametersNamed) {
      argEntries.add('${_safe(p.name)}: named.${_safe(p.name)}');
    }

    final isVoid = signature.tsReturnInner == 'void';
    final decode = isVoid
        ? '() => undefined as void'
        : '(raw: unknown) => ${mapper.map(signature.returnInner).fromJsonExpr('raw')}';

    final isUnauth = method.annotations
        .any((a) => a.name == 'unauthenticatedClientCall');
    final optionsArg = isUnauth ? ', { authenticated: false }' : '';

    w.writeln(
      "return this.caller.callServerEndpoint<${signature.tsReturnInner}>(",
    );
    w.indent(() {
      w.writeln("'${ep.name}',");
      w.writeln("'${method.name}',");
      if (argEntries.isEmpty) {
        w.writeln('{},');
      } else {
        w.writeln('{ ${argEntries.join(', ')} },');
      }
      w.writeln('$decode$optionsArg,');
    });
    w.writeln(');');
  }

  TypeDefinition _futureInner(TypeDefinition t) {
    if ((t.className == 'Future' || t.className == 'Stream') &&
        t.generics.isNotEmpty) {
      return t.generics.first;
    }
    return t;
  }

  String _safe(String name) {
    const reserved = {
      'class', 'default', 'enum', 'interface', 'extends', 'super',
      'package', 'private', 'protected', 'public', 'static',
      'await', 'yield', 'function', 'return', 'this', 'new',
    };
    return reserved.contains(name) ? '${name}_' : name;
  }

  String _pascalCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _filenameStem(String name) {
    return name.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m[0]!.toLowerCase()}',
    );
  }

  String _writeFile(String filename, String content) {
    final destDir = Directory(p.join(outputDir.path, 'src', 'endpoints'));
    destDir.createSync(recursive: true);
    final file = File(p.join(destDir.path, filename));
    file.writeAsStringSync(content);
    tracker.recordWrite(file);
    return filename;
  }
}

class _Signature {
  _Signature({
    required this.params,
    required this.returnType,
    required this.returnInner,
    required this.tsReturnInner,
  });

  final String params;
  final String returnType;
  final TypeDefinition returnInner;
  final String tsReturnInner;
}
