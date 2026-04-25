import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:serverpod_typescript_bridge/src/cli/generate_command.dart';
import 'package:serverpod_typescript_bridge/src/cli/inspect_command.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner<int>(
    'serverpod_typescript_bridge',
    'Generate a TypeScript client for a Serverpod project.',
  )
    ..addCommand(InspectCommand())
    ..addCommand(GenerateCommand());

  try {
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    stderr.writeln(e);
    exit(64);
  }
}
