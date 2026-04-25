// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/config/experimental_feature.dart';

/// Loads the v0.1 fixture's `GeneratorConfig`. Used by emit-side tests
/// that need a `GeneratorConfig` without going through the full
/// IR-loading pipeline.
Future<GeneratorConfig> loadFixtureConfig() async {
  try {
    CommandLineExperimentalFeatures.instance;
  } catch (_) {
    CommandLineExperimentalFeatures.initialize(const []);
  }
  return GeneratorConfig.load(
    serverRootDir: 'test/fixtures/sample_server/sample_server',
    interactive: false,
  );
}
