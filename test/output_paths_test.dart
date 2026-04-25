import 'package:path/path.dart' as p;
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_typescript_bridge/src/emit/output_paths.dart';
import 'package:test/test.dart';

import 'protocol_loader_test_helper.dart';

void main() {
  group('OutputPaths.resolve', () {
    late GeneratorConfig config;

    setUpAll(() async {
      config = await loadFixtureConfig();
    });

    test('defaults to <server>/../<name>_typescript_client/', () {
      final paths = OutputPaths.resolve(config);
      expect(paths.packageName, 'sample_typescript_client');
      // The fixture's server is at test/fixtures/sample_server/sample_server,
      // so the default sibling is test/fixtures/sample_server/sample_typescript_client.
      expect(
        p.basename(paths.outputDir.path),
        'sample_typescript_client',
      );
      expect(
        p.normalize(paths.outputDir.path),
        endsWith(p.join('sample_server', 'sample_typescript_client')),
      );
    });

    test('honours an explicit output override', () {
      final paths = OutputPaths.resolve(
        config,
        explicitOutput: '/tmp/custom_ts_client',
      );
      expect(paths.outputDir.path, '/tmp/custom_ts_client');
    });
  });
}
