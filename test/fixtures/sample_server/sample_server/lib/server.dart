import 'package:serverpod/serverpod.dart';

import 'src/generated/protocol.dart';
import 'src/generated/endpoints.dart';

/// The token the fixture server accepts.
const fixtureAuthToken = 'valid-token';

/// The starting point of the Serverpod server.
void run(List<String> args) async {
  // Initialize Serverpod and connect it with your generated code.
  final pod = Serverpod(
    args,
    Protocol(),
    Endpoints(),
    // One fixed token: enough to prove a client's credentials reach the
    // server on both transports.
    authenticationHandler: (session, token) async => token == fixtureAuthToken
        ? AuthenticationInfo('user-1', {}, authId: 'fixture')
        : null,
  );

  // Start the server.
  await pod.start();
}
