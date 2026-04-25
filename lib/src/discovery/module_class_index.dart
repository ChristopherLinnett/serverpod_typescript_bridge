// ignore_for_file: implementation_imports
import 'dart:io';

import 'package:meta/meta.dart';
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

    for (final mod in discovered) {
      final layout = layoutResolver.resolve(mod.dartPkgName);
      final ir = await ProtocolLoader.load(mod.serverPkgDir);
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

  bool get isEmpty => _classToLayout.isEmpty;

  /// Returns the layout for [className] if it's defined in any module,
  /// or null if it's local / unknown.
  ModuleClientLayout? layoutFor(String className) =>
      _classToLayout[className];

  bool isSealed(String className) => _sealedClassNames.contains(className);
  bool isEnum(String className) => _enumClassNames.contains(className);

  /// All className → npmPackageName entries, deduplicated by package.
  /// Used by the scaffold emitter to write the right `file:..` deps
  /// into the consuming package's `package.json`.
  Map<String, String> referencedPackages({
    required Iterable<String> referencedClassNames,
    required Directory appClientDir,
  }) {
    final out = <String, String>{};
    for (final name in referencedClassNames) {
      final layout = _classToLayout[name];
      if (layout == null) continue;
      out[layout.npmPackageName] = 'file:${layout.relativeFromAppClient}';
    }
    return out;
  }
}
