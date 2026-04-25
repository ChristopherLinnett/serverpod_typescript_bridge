// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';

import '../discovery/module_class_index.dart';

/// Builds the cross-PACKAGE `import { ... } from '<pkg>';` lines a
/// generated TS file needs in order to reach module-defined types.
///
/// The [TsTypeMapper] emits bare TS names for module-defined classes
/// (no `p.` prefix); this helper walks a set of type definitions,
/// groups every referenced module class by its npm package, and
/// produces one alphabetised import line per package — collapsing
/// multiple references to a single module into a single statement.
class ModuleImportLines {
  ModuleImportLines(this._index);

  final ModuleClassIndex _index;

  /// Returns one import line per module package referenced by [types]
  /// (recursively through generics). Lines are sorted by package name;
  /// symbols within each line are sorted by class name.
  List<String> forTypes(Iterable<TypeDefinition> types) {
    final referenced = <String>{};
    for (final t in types) {
      _collect(t, referenced);
    }
    return forClassNames(referenced);
  }

  /// Returns one import line per module package referenced by
  /// [classNames] — same grouping/sorting rules as [forTypes], but
  /// skips the type-definition walk for callers that already hold a
  /// flat name set (e.g. the protocol-switch emitter).
  List<String> forClassNames(Iterable<String> classNames) {
    final byPackage = <String, Set<String>>{};
    for (final name in classNames) {
      final layout = _index.layoutFor(name);
      if (layout == null) continue;
      byPackage
          .putIfAbsent(layout.npmPackageName, () => <String>{})
          .add(name);
    }

    final packages = byPackage.keys.toList()..sort();
    return [
      for (final pkg in packages)
        "import { ${symbolsFor(byPackage[pkg]!).join(', ')} } from '$pkg';",
    ];
  }

  /// The TS symbols a generated file must import for every name in
  /// [classNames]. Mirrors what [TsTypeMapper] references at the use
  /// site:
  ///   plain class    → `Name`
  ///   exception      → `Name`
  ///   sealed base    → `Name` (the union alias) + `NameBase` (dispatcher)
  ///   enum           → `Name` + `NameCodec`
  ///
  /// Names that aren't in the underlying [ModuleClassIndex] are
  /// silently skipped — callers should pre-filter, but this lets the
  /// helper double as a defensive boundary.
  List<String> symbolsFor(Iterable<String> classNames) {
    final sorted = classNames.toList()..sort();
    final out = <String>[];
    for (final name in sorted) {
      if (_index.layoutFor(name) == null) continue;
      if (_index.isEnum(name)) {
        out
          ..add(name)
          ..add('${name}Codec');
      } else if (_index.isSealed(name)) {
        out
          ..add(name)
          ..add('${name}Base');
      } else {
        out.add(name);
      }
    }
    return out;
  }

  void _collect(TypeDefinition type, Set<String> out) {
    if (_index.layoutFor(type.className) != null) out.add(type.className);
    for (final g in type.generics) {
      _collect(g, out);
    }
  }
}
