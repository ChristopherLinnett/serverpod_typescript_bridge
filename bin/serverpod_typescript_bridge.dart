import 'dart:io';

import 'package:args/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'serverpod_typescript_bridge',
    'Generate a TypeScript client for a Serverpod project.',
  )..addCommand(_GenerateCommand());

  try {
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}

class _GenerateCommand extends Command<int> {
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
