import 'package:serverpod/serverpod.dart';

/// Endpoint that retains a `@Deprecated` method for backwards compatibility.
///
/// The deprecation annotation must propagate to the generated TS client as a
/// JSDoc `@deprecated` tag.
class LegacyEndpoint extends Endpoint {
  /// The current way to greet a user.
  Future<String> greet(Session session, String name) async => 'Hi, $name';

  /// Old-style greeting.
  @Deprecated('Use `greet` instead.')
  Future<String> sayHi(Session session, String name) async => 'Hi, $name';
}
