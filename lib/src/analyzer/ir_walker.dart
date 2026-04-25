// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart'
    show EndpointDefinition;

/// Pure walks over the Serverpod IR — extracted so emitters and the
/// generation pipeline don't each re-implement the same parameter /
/// generic descent. Every helper is read-only and side-effect-free.
class IrWalker {
  IrWalker._();

  /// Yields every [TypeDefinition] referenced by [ep] across return
  /// types and parameters (required-positional, optional-positional,
  /// and named). Callers wanting deeper recursion through generics
  /// should compose this with [walkType].
  static Iterable<TypeDefinition> endpointTypeRefs(
    EndpointDefinition ep,
  ) sync* {
    for (final m in ep.methods) {
      yield m.returnType;
      for (final pm in m.parameters) {
        yield pm.type;
      }
      for (final pm in m.parametersPositional) {
        yield pm.type;
      }
      for (final pm in m.parametersNamed) {
        yield pm.type;
      }
    }
  }

  /// Returns every className referenced anywhere in [ir] — model
  /// fields, exception fields, and endpoint params/returns — descending
  /// into generics. Used to scope cross-package emission to only the
  /// types the project actually pulls from.
  static Set<String> allReferencedClassNames(ProtocolDefinition ir) {
    final out = <String>{};
    for (final model in ir.models) {
      if (model is ClassDefinition) {
        for (final f in model.fields) {
          walkType(f.type, out);
        }
      }
    }
    for (final ep in ir.endpoints) {
      for (final t in endpointTypeRefs(ep)) {
        walkType(t, out);
      }
    }
    return out;
  }

  /// Adds [t]'s className plus every nested generic className to [out].
  static void walkType(TypeDefinition t, Set<String> out) {
    out.add(t.className);
    for (final g in t.generics) {
      walkType(g, out);
    }
  }
}
