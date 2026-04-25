import 'package:serverpod/serverpod.dart';

/// Endpoint whose every method requires an authenticated session.
///
/// Overriding `requireLogin` flips the auth gate at the server. The generated
/// TS client should still expose the methods normally; auth enforcement is the
/// runtime's job.
class AuthEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Echo the authenticated user's identifier.
  ///
  /// The `'anonymous'` fallback is unreachable in production (the
  /// `requireLogin` gate already rejects unauthenticated calls), but keeps
  /// this fixture self-contained: tests that pass a non-authenticated
  /// session via `serverpod_test` still get a deterministic response
  /// instead of a null-deref crash.
  Future<String> whoAmI(Session session) async =>
      session.authenticated?.userIdentifier ?? 'anonymous';

  /// Echo a string only authenticated callers can reach.
  Future<String> secret(Session session) async => 'shhh';
}
