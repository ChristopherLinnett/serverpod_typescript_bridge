import 'dart:io';

import 'package:args/command_runner.dart';

/// `generate` — produce the TypeScript client package for a Serverpod
/// project. Stub for now; the real implementation lands in issue #4 and
/// is fleshed out by issues #5–#10.
class GenerateCommand extends Command<int> {
  @override
  String get name => 'generate';

  @override
  String get description =>
      'Generate the TypeScript client package next to the current Serverpod project.';

  @override
  Future<int> run() async {
    stderr.writeln(
      'serverpod_typescript_bridge generate: not implemented yet.\n'
      'See https://github.com/ChristopherLinnett/serverpod_typescript_bridge for status.',
    );
    return 70;
  }
}
