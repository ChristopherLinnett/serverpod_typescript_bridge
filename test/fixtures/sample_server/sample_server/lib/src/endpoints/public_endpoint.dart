import 'package:serverpod/serverpod.dart';

/// Endpoint that exposes both an explicitly-public method (via
/// `@unauthenticatedClientCall`) and an implicitly-public method (no
/// annotation, no `requireLogin` override).
///
/// The generator must surface `authenticated: false` for the annotated
/// method and `authenticated: true` (default) for the rest.
class PublicEndpoint extends Endpoint {
  /// Health-check ping. Explicitly public — `@unauthenticatedClientCall`
  /// flips this to `authenticated: false` in the generated client even
  /// when the class otherwise requires login.
  @unauthenticatedClientCall
  Future<String> ping(Session session) async => 'pong';

  /// Echo a name back. Implicitly public: this class does not override
  /// `requireLogin`, so the default (no auth required) applies. Kept as
  /// the contrast surface against [ping].
  Future<String> hello(Session session, String name) async => 'Hello, $name';
}
