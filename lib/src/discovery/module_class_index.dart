// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';

import '../analyzer/protocol_loader.dart';
import 'module_client_layout.dart';
import 'module_discoverer.dart';

/// Records which classes (models, exceptions, enums) are emitted by
/// each Serverpod module the project depends on. Built once per
/// generation run by analyzing each module's IR.
///
/// The type mapper consults this when emitting model fields + endpoint
/// signatures: if a referenced className lives in a module, the emitter
/// imports it from that module's TS client package instead of treating
/// it as a local protocol-barrel reference (or the v0.1.x `unknown`
/// fallback).
class ModuleClassIndex {
  ModuleClassIndex._(
    Map<String, ModuleClientLayout> classToLayout,
    Set<String> sealedClassNames,
    Set<String> enumClassNames,
  )   : _classToLayout = Map.unmodifiable(classToLayout),
        _sealedClassNames = Set.unmodifiable(sealedClassNames),
        _enumClassNames = Set.unmodifiable(enumClassNames);

  final Map<String, ModuleClientLayout> _classToLayout;
  final Set<String> _sealedClassNames;
  final Set<String> _enumClassNames;

  static final ModuleClassIndex empty =
      ModuleClassIndex._(const {}, const {}, const {});

  /// Constructs an index directly from already-resolved maps. Intended
  /// for unit tests that need a controlled index without spinning up a
  /// real Serverpod fixture; production code should always go through
  /// [build] which derives the contents from each module's IR.
  @visibleForTesting
  static ModuleClassIndex forTesting({
    required Map<String, ModuleClientLayout> classToLayout,
    Set<String> sealedClassNames = const {},
    Set<String> enumClassNames = const {},
  }) {
    return ModuleClassIndex._(classToLayout, sealedClassNames, enumClassNames);
  }

  /// Walks every [discovered] module, loads its IR, and builds a
  /// `className → layout` index. Sealed/enum class names are tracked
  /// separately so the emitter knows which import-symbol set to bring
  /// in (`Name + NameBase` for sealed, `Name + NameCodec` for enum).
  static Future<ModuleClassIndex> build({
    required List<DiscoveredModule> discovered,
    required ModuleLayoutResolver layoutResolver,
  }) async {
    final classToLayout = <String, ModuleClientLayout>{};
    final sealedClassNames = <String>{};
    final enumClassNames = <String>{};

    final knownModules = [
      for (final m in discovered)
        ModuleDependency(
          dartPkgName: m.dartPkgName,
          nickname: m.nickname,
          serverPkgPath: m.serverPkgDir.path,
        ),
    ];

    for (final mod in discovered) {
      final layout = layoutResolver.resolve(mod.dartPkgName);
      // Modules typically live under the user's pub-cache, where the
      // sibling dart client package isn't present — `loadForModule`
      // synthesises a config that bypasses that validation. We pass
      // the full discovered set so the synthesised config can resolve
      // cross-module references (e.g. auth_idp's `module:auth:...`
      // pointing at auth_core).
      final ir = await ProtocolLoader.loadForModule(
        mod.serverPkgDir,
        knownModules: knownModules,
      );
      for (final m in ir.models) {
        classToLayout[m.className] = layout;
        if (m is ModelClassDefinition && m.isSealed) {
          sealedClassNames.add(m.className);
        } else if (m is EnumDefinition) {
          enumClassNames.add(m.className);
        }
      }
    }

    return ModuleClassIndex._(classToLayout, sealedClassNames,
        enumClassNames);
  }

  /// Returns a copy of this index with every name in [classNames]
  /// removed. Used by [GenerationPipeline] to scope the index for the
  /// project currently being generated — the project's own classes
  /// belong in its local protocol barrel, NOT as cross-package imports
  /// pointing back at itself.
  ///
  /// The `ModuleClassIndex.build` pass walks every discovered module
  /// (including the one we're emitting), so without this filter the
  /// per-emit `ModuleImportLines` would treat the project's own
  /// classes as foreign module classes and produce both a local
  /// cross-file import AND a self-referential cross-package import.
  ModuleClassIndex excluding(Set<String> classNames) {
    if (classNames.isEmpty) return this;
    final filteredLayout = <String, ModuleClientLayout>{
      for (final entry in _classToLayout.entries)
        if (!classNames.contains(entry.key)) entry.key: entry.value,
    };
    final filteredSealed = <String>{
      for (final n in _sealedClassNames)
        if (!classNames.contains(n)) n,
    };
    final filteredEnum = <String>{
      for (final n in _enumClassNames)
        if (!classNames.contains(n)) n,
    };
    return ModuleClassIndex._(filteredLayout, filteredSealed, filteredEnum);
  }

  bool get isEmpty => _classToLayout.isEmpty;

  /// Returns the layout for [className] if it's defined in any module,
  /// or null if it's local / unknown.
  ModuleClientLayout? layoutFor(String className) =>
      _classToLayout[className];

  bool isSealed(String className) => _sealedClassNames.contains(className);
  bool isEnum(String className) => _enumClassNames.contains(className);

  /// All `npmPackageName → "file:<relative-path>"` entries the
  /// consuming package needs to declare in its `package.json`,
  /// deduplicated by package.
  ///
  /// The relative path is computed fresh from [consumerDir] →
  /// the module's `outputDir` and forced to posix slashes — npm
  /// expects forward slashes in `file:` deps even on Windows. This
  /// also lets module clients depend on each other (consumer is the
  /// generating module's own output dir, not the app's).
  Map<String, String> referencedPackages({
    required Iterable<String> referencedClassNames,
    required Directory consumerDir,
  }) {
    final out = <String, String>{};
    for (final name in referencedClassNames) {
      final layout = _classToLayout[name];
      if (layout == null) continue;
      out[layout.npmPackageName] = 'file:${_posixRelative(
        from: consumerDir.path,
        to: layout.outputDir.path,
      )}';
    }
    return out;
  }

  /// Relative path from [from] → [to] using forward slashes,
  /// regardless of host platform. We canonicalise both ends before
  /// asking the path package so symlinks and `..` segments don't
  /// produce surprising results.
  static String _posixRelative({required String from, required String to}) {
    final platformRel = p.relative(p.canonicalize(to), from: p.canonicalize(from));
    return p.split(platformRel).join('/');
  }
}
