// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart';

import '../analyzer/ir_walker.dart';
import 'generated_file_tracker.dart';
import 'module_import_lines.dart';
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

  late final ModuleImportLines _moduleImports =
      ModuleImportLines(mapper.moduleIndex);

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
    // A barrel with zero exports is a script in TS's eyes and the
    // `import * as r from './endpoints/index.js'` consumer fails with
    // `File '…' is not a module`. The empty `export {}` is the
    // canonical opt-in to module status.
    if (filenames.isEmpty) w.writeln('export {};');
    _writeFile('index.ts', w.toString());
  }

  String _emitEndpoint(EndpointDefinition ep) {
    final w = TsWriter()
      ..writeRaw(_generatedHeader)
      ..writeln("import * as r from '../runtime/index.js';")
      ..writeln("import * as p from '../protocol/index.js';");
    final moduleImports =
        _moduleImports.forTypes(IrWalker.endpointTypeRefs(ep));
    for (final line in moduleImports) {
      w.writeln(line);
    }
    w.blankLine();

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

    final hasStreamReturn = method.returnType.className == 'Stream';
    final inputStreamParams = _inputStreamParams(method);
    final hasStreamParam = inputStreamParams.isNotEmpty;

    if (hasStreamParam && !hasStreamReturn) {
      // Per Serverpod's analyzer rules, a Stream<T> input parameter
      // requires a Future or Stream return — we treat the call shape
      // as a streaming one. Tag it as output-stream so signature
      // building emits AsyncIterable<T>.
      // (In practice all fixture+real-world cases pair input streams
      // with output streams; this branch is defensive.)
    }

    final signature = _buildSignature(
      method,
      isOutputStream: hasStreamReturn || hasStreamParam,
      inputStreamParams: inputStreamParams,
    );

    if (hasStreamReturn || hasStreamParam) {
      // Streaming methods (output-only or bidirectional) return
      // AsyncIterable<T> directly (not Promise).
      w.writeln(
        '${method.name}(${signature.params}): ${signature.returnType} {',
      );
      w.indent(() {
        _emitStreamingMethodBody(w, ep, method, signature, inputStreamParams);
      });
      w.writeln('}');
      w.blankLine();
      return;
    }

    w.writeln(
      'async ${method.name}(${signature.params}): ${signature.returnType} {',
    );
    w.indent(() {
      _emitMethodBody(w, ep, method, signature);
    });
    w.writeln('}');
    w.blankLine();
  }

  /// Returns every parameter (across required-positional, optional-
  /// positional, and named) whose type is `Stream<T>`.
  List<ParameterDefinition> _inputStreamParams(MethodDefinition method) {
    return [
      ...method.parameters,
      ...method.parametersPositional,
      ...method.parametersNamed,
    ].where((p) => p.type.className == 'Stream').toList();
  }

  void _emitStreamingMethodBody(
    TsWriter w,
    EndpointDefinition ep,
    MethodDefinition method,
    _Signature signature,
    List<ParameterDefinition> inputStreamParams,
  ) {
    final args = _argsObjectExpression(method, excludingNames: {
      for (final p in inputStreamParams) p.name,
    });
    final inner = signature.tsReturnInner;
    final decode =
        '(raw: unknown) => ${mapper.map(signature.returnInner).fromJsonExpr('raw')}';

    w.writeln('return this.caller.callStreamingServerEndpoint<$inner>(');
    w.indent(() {
      w.writeln("'${ep.name}',");
      w.writeln("'${method.name}',");
      w.writeln('$args,');
      if (inputStreamParams.isEmpty) {
        w.writeln('$decode,');
      } else {
        w.writeln('$decode,');
        // Build the inputStreams record. Each entry has the user's
        // AsyncIterable plus an encoder that wraps each value in the
        // `{ className, data }` envelope the server expects.
        w.writeln('{');
        w.indent(() {
          for (final p in inputStreamParams) {
            final innerType = p.type.generics.first;
            final wireClassName = _wireClassName(innerType);
            final encodeExpr = _streamValueEncodeExpr(innerType);
            w.writeln(
              "'${p.name}': { iterable: streams.${_safe(p.name)}, "
              "encode: (v) => ({ className: '$wireClassName', "
              'data: $encodeExpr }) },',
            );
          }
        });
        w.writeln('},');
      }
    });
    w.writeln(') as unknown as AsyncIterable<$inner>;');
  }

  /// Returns the wire-form `className` we tag input-stream values with.
  /// For project models/exceptions the IR carries the bare className;
  /// for primitives we use the Dart type name directly.
  String _wireClassName(TypeDefinition type) => type.className;

  /// Builds a TS expression that encodes a single input-stream value
  /// `v` to the `data` field of the wire envelope.
  String _streamValueEncodeExpr(TypeDefinition innerType) {
    // Reuse the type mapper's toJson expression. For primitives this is
    // just `v`; for models it's `v.toJson()`; for collections it walks.
    final ref = mapper.map(innerType);
    final expr = ref.toJsonExpr('v');
    // The data field expects Record<string,unknown>; primitives need
    // wrapping. The simplest contract: always wrap in `{ value: <expr> }`
    // for primitives so the server can recognise it. But Serverpod's own
    // wire format for primitives is implementation-private; for v0.1.1
    // we send the raw value and trust the runtime cast — known caveat,
    // documented in the README streaming section.
    if (_isPrimitive(innerType)) return '{ value: $expr } as Record<string, unknown>';
    return '$expr as Record<string, unknown>';
  }

  bool _isPrimitive(TypeDefinition type) {
    const primitives = {
      'int', 'double', 'num', 'String', 'bool',
      'DateTime', 'Duration', 'BigInt', 'UuidValue', 'Uri',
      'ByteData', 'Uint8List',
    };
    return primitives.contains(type.className);
  }

  _Signature _buildSignature(
    MethodDefinition method, {
    bool isOutputStream = false,
    List<ParameterDefinition> inputStreamParams = const [],
  }) {
    final inputStreamNames = {for (final p in inputStreamParams) p.name};
    final params = <String>[];
    for (final p in method.parameters) {
      if (inputStreamNames.contains(p.name)) continue;
      params.add('${_safe(p.name)}: ${mapper.map(p.type).tsType}');
    }
    for (final p in method.parametersPositional) {
      if (inputStreamNames.contains(p.name)) continue;
      params.add('${_safe(p.name)}?: ${mapper.map(p.type).tsType}');
    }
    final namedNonStream =
        method.parametersNamed.where((p) => !inputStreamNames.contains(p.name)).toList();
    if (namedNonStream.isNotEmpty) {
      final allOptional = namedNonStream.every((p) => !p.required);
      final inner = namedNonStream
          .map((p) {
            final tsType = mapper.map(p.type).tsType;
            return p.required
                ? '${_safe(p.name)}: $tsType'
                : '${_safe(p.name)}?: $tsType';
          })
          .join('; ');
      // When every named param is optional, the `named` object itself
      // can be omitted at the call site too.
      params.add(allOptional ? 'named?: { $inner }' : 'named: { $inner }');
    }
    if (inputStreamParams.isNotEmpty) {
      // Input streams collected into a separate `streams: { ... }`
      // object so the regular params list stays clean.
      final inner = inputStreamParams
          .map((p) {
            final innerType = mapper.map(p.type.generics.first).tsType;
            return '${_safe(p.name)}: AsyncIterable<$innerType>';
          })
          .join('; ');
      params.add('streams: { $inner }');
    }

    final returnInner = _futureInner(method.returnType);
    final tsReturn = mapper.map(returnInner).tsType;
    final String wrapped;
    if (isOutputStream) {
      wrapped = 'AsyncIterable<$tsReturn>';
    } else if (tsReturn == 'void') {
      wrapped = 'Promise<void>';
    } else {
      wrapped = 'Promise<$tsReturn>';
    }

    return _Signature(
      params: params.join(', '),
      returnType: wrapped,
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
    final args = _argsObjectExpression(method, excludingNames: const {});

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
      w.writeln('$args,');
      w.writeln('$decode$optionsArg,');
    });
    w.writeln(');');
  }

  /// Builds the args object expression for the call site.
  ///
  /// Wire keys ALWAYS use the original Dart parameter name (so a Dart
  /// param named `class` stays `class:` on the wire even if the local
  /// TS variable name had to be escaped to `class_`). Optional params
  /// are spread guarded so omitting the arg sends nothing instead of
  /// an explicit null. Input-stream parameters are skipped — they're
  /// passed through the `streams` object instead.
  String _argsObjectExpression(
    MethodDefinition method, {
    required Set<String> excludingNames,
  }) {
    final entries = <String>[];
    for (final p in method.parameters) {
      if (excludingNames.contains(p.name)) continue;
      entries.add("'${p.name}': ${_safe(p.name)}");
    }
    for (final p in method.parametersPositional) {
      if (excludingNames.contains(p.name)) continue;
      entries.add(
        "...(${_safe(p.name)} !== undefined && { '${p.name}': ${_safe(p.name)} })",
      );
    }
    for (final p in method.parametersNamed) {
      if (excludingNames.contains(p.name)) continue;
      final access = 'named?.${_safe(p.name)}';
      if (p.required) {
        entries.add("'${p.name}': named.${_safe(p.name)}");
      } else {
        entries.add(
          "...($access !== undefined && { '${p.name}': $access })",
        );
      }
    }
    if (entries.isEmpty) return '{}';
    return '{ ${entries.join(', ')} }';
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
