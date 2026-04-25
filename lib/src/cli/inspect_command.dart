import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:serverpod_cli/analyzer.dart';

import '../analyzer/protocol_loader.dart';
import '../discovery/server_directory_finder.dart';
import '../inspect/protocol_to_json.dart';

/// `inspect` — load a server's IR and print it as pretty JSON.
///
/// Useful for debugging the analyzer pipeline and for downstream tooling
/// that wants a machine-readable description of a Serverpod project.
class InspectCommand extends Command<int> {
  InspectCommand() {
    argParser.addOption(
      'directory',
      abbr: 'd',
      help: 'Path to the Serverpod server package. '
          'Auto-detected (walking up from cwd) if omitted.',
    );
  }

  @override
  String get name => 'inspect';

  @override
  String get description =>
      'Print the parsed protocol IR as JSON (for debugging).';

  @override
  Future<int> run() async {
    final override = argResults!['directory'] as String?;

    final Directory serverDir;
    try {
      serverDir = ServerDirectoryFinder.find(override: override);
    } on StateError catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    final ProtocolDefinition ir;
    try {
      ir = await ProtocolLoader.load(serverDir);
    } on ProtocolLoaderException catch (e) {
      stderr.writeln(e.message);
      return 70;
    }

    stdout.writeln(_pretty(protocolToJson(ir)));
    return 0;
  }

  String _pretty(Object json) =>
      const JsonEncoder.withIndent('  ').convert(json);
}
