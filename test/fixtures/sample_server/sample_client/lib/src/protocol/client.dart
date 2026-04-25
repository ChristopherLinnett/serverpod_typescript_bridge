/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:sample_client/src/protocol/protocol.dart' as _i3;
import 'package:sample_client/src/protocol/user_profile.dart' as _i4;
import 'package:sample_client/src/protocol/admin_profile.dart' as _i5;
import 'package:sample_client/src/protocol/animal.dart' as _i6;
import 'dart:typed_data' as _i7;
import 'protocol.dart' as _i8;

/// Endpoint whose every method requires an authenticated session.
///
/// Overriding `requireLogin` flips the auth gate at the server. The generated
/// TS client should still expose the methods normally; auth enforcement is the
/// runtime's job.
/// {@category Endpoint}
class EndpointAuth extends _i1.EndpointRef {
  EndpointAuth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Echo the authenticated user's identifier.
  ///
  /// The `'anonymous'` fallback is unreachable in production (the
  /// `requireLogin` gate already rejects unauthenticated calls), but keeps
  /// this fixture self-contained: tests that pass a non-authenticated
  /// session via `serverpod_test` still get a deterministic response
  /// instead of a null-deref crash.
  _i2.Future<String> whoAmI() => caller.callServerEndpoint<String>(
    'auth',
    'whoAmI',
    {},
  );

  /// Echo a string only authenticated callers can reach.
  _i2.Future<String> secret() => caller.callServerEndpoint<String>(
    'auth',
    'secret',
    {},
  );
}

/// Endpoint with both an input `Stream<String>` and an output `Stream<String>`.
///
/// Exercises the bidirectional streaming path: client emits messages on an
/// `AsyncIterable`, server echoes each one back (uppercased).
/// {@category Endpoint}
class EndpointChat extends _i1.EndpointRef {
  EndpointChat(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Echo each inbound message back, uppercased.
  _i2.Stream<String> echoStream(_i2.Stream<String> messages) =>
      caller.callStreamingServerEndpoint<_i2.Stream<String>, String>(
        'chat',
        'echoStream',
        {},
        {'messages': messages},
      );
}

/// Endpoint that exercises every collection shape the wire format supports.
///
/// Includes `Map<int, _>` to exercise the non-string-key wire form
/// (serialized as a list of `{k, v}` pairs).
/// {@category Endpoint}
class EndpointCollections extends _i1.EndpointRef {
  EndpointCollections(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'collections';

  /// Round-trip a `List<int>`.
  _i2.Future<List<int>> echoIntList(List<int> values) =>
      caller.callServerEndpoint<List<int>>(
        'collections',
        'echoIntList',
        {'values': values},
      );

  /// Round-trip a `Set<String>` (serialized as a JSON array).
  _i2.Future<Set<String>> echoStringSet(Set<String> values) =>
      caller.callServerEndpoint<Set<String>>(
        'collections',
        'echoStringSet',
        {'values': values},
      );

  /// Round-trip a `Map<String, int>` (serialized as a JSON object).
  _i2.Future<Map<String, int>> echoStringIntMap(Map<String, int> entries) =>
      caller.callServerEndpoint<Map<String, int>>(
        'collections',
        'echoStringIntMap',
        {'entries': entries},
      );

  /// Round-trip a `Map<int, String>` — non-string keys serialize as a list
  /// of `{k, v}` pairs.
  _i2.Future<Map<int, String>> echoIntStringMap(Map<int, String> entries) =>
      caller.callServerEndpoint<Map<int, String>>(
        'collections',
        'echoIntStringMap',
        {'entries': _i3.Protocol().mapContainerToJson(entries)},
      );
}

/// Endpoint that retains a `@Deprecated` method for backwards compatibility.
///
/// The deprecation annotation must propagate to the generated TS client as a
/// JSDoc `@deprecated` tag.
/// {@category Endpoint}
class EndpointLegacy extends _i1.EndpointRef {
  EndpointLegacy(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'legacy';

  /// The current way to greet a user.
  _i2.Future<String> greet(String name) => caller.callServerEndpoint<String>(
    'legacy',
    'greet',
    {'name': name},
  );

  /// Old-style greeting.
  @Deprecated('Use `greet` instead.')
  _i2.Future<String> sayHi(String name) => caller.callServerEndpoint<String>(
    'legacy',
    'sayHi',
    {'name': name},
  );
}

/// Endpoint that exchanges custom serializable models in both directions.
///
/// Exercises `fromJson` / `toJson` round-tripping for nested models, including
/// non-sealed inheritance ([UserProfile] / [AdminProfile]) and the sealed
/// [Animal] hierarchy.
/// {@category Endpoint}
class EndpointModels extends _i1.EndpointRef {
  EndpointModels(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'models';

  /// Echo a [UserProfile] back to the caller.
  _i2.Future<_i4.UserProfile> echoProfile(_i4.UserProfile profile) =>
      caller.callServerEndpoint<_i4.UserProfile>(
        'models',
        'echoProfile',
        {'profile': profile},
      );

  /// Promote a [UserProfile] to an [AdminProfile] with the given scope.
  ///
  /// Exercises non-sealed inheritance on the return type.
  _i2.Future<_i5.AdminProfile> promoteToAdmin(
    _i4.UserProfile profile,
    String scope,
  ) => caller.callServerEndpoint<_i5.AdminProfile>(
    'models',
    'promoteToAdmin',
    {
      'profile': profile,
      'scope': scope,
    },
  );

  /// Echo a sealed [Animal] back to the caller. Exercises polymorphism via
  /// `__className__` dispatch.
  _i2.Future<_i6.Animal> echoAnimal(_i6.Animal animal) =>
      caller.callServerEndpoint<_i6.Animal>(
        'models',
        'echoAnimal',
        {'animal': animal},
      );

  /// Throws a typed [NotFoundException] so the runtime's typed-exception
  /// decoder can be exercised.
  _i2.Future<_i4.UserProfile> findOrThrow(int id) =>
      caller.callServerEndpoint<_i4.UserProfile>(
        'models',
        'findOrThrow',
        {'id': id},
      );
}

/// Endpoint where every parameter and return is nullable. Exercises the
/// `omit-on-null` `toJson` shape and the optional-arg generator path.
/// {@category Endpoint}
class EndpointNullables extends _i1.EndpointRef {
  EndpointNullables(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'nullables';

  /// All-nullable primitive round-trip.
  _i2.Future<int?> nullableInt(int? value) => caller.callServerEndpoint<int?>(
    'nullables',
    'nullableInt',
    {'value': value},
  );

  /// All-nullable string round-trip.
  _i2.Future<String?> nullableString(String? value) =>
      caller.callServerEndpoint<String?>(
        'nullables',
        'nullableString',
        {'value': value},
      );

  /// Nullable model round-trip.
  _i2.Future<_i4.UserProfile?> nullableProfile(_i4.UserProfile? profile) =>
      caller.callServerEndpoint<_i4.UserProfile?>(
        'nullables',
        'nullableProfile',
        {'profile': profile},
      );

  /// Nullable list round-trip.
  _i2.Future<List<int>?> nullableList(List<int>? values) =>
      caller.callServerEndpoint<List<int>?>(
        'nullables',
        'nullableList',
        {'values': values},
      );
}

/// Endpoint that exercises every primitive type the v0.1 generator must
/// support.
///

/// Used by the doc-comment passthrough tests — Dart-doc templates and macros
/// must survive the analyzer round-trip.
/// {@category Endpoint}
class EndpointPrimitives extends _i1.EndpointRef {
  EndpointPrimitives(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'primitives';

  /// Round-trip an `int`.
  ///
  /// Used by the doc-comment passthrough tests — Dart-doc templates and macros
  /// must survive the analyzer round-trip.
  _i2.Future<int> echoInt(int value) => caller.callServerEndpoint<int>(
    'primitives',
    'echoInt',
    {'value': value},
  );

  /// Round-trip a `double`.
  _i2.Future<double> echoDouble(double value) =>
      caller.callServerEndpoint<double>(
        'primitives',
        'echoDouble',
        {'value': value},
      );

  /// Round-trip a `String`.
  ///
  /// Inline code: `String` maps to TypeScript `string`.
  _i2.Future<String> echoString(String value) =>
      caller.callServerEndpoint<String>(
        'primitives',
        'echoString',
        {'value': value},
      );

  /// Round-trip a `bool`.
  _i2.Future<bool> echoBool(bool value) => caller.callServerEndpoint<bool>(
    'primitives',
    'echoBool',
    {'value': value},
  );

  /// Round-trip a `DateTime` (always UTC on the wire).
  _i2.Future<DateTime> echoDateTime(DateTime value) =>
      caller.callServerEndpoint<DateTime>(
        'primitives',
        'echoDateTime',
        {'value': value},
      );

  /// Round-trip a `Duration` (encoded as integer milliseconds).
  _i2.Future<Duration> echoDuration(Duration value) =>
      caller.callServerEndpoint<Duration>(
        'primitives',
        'echoDuration',
        {'value': value},
      );

  /// Round-trip a `BigInt` (encoded as a string).
  _i2.Future<BigInt> echoBigInt(BigInt value) =>
      caller.callServerEndpoint<BigInt>(
        'primitives',
        'echoBigInt',
        {'value': value},
      );

  /// Round-trip a `UuidValue` (encoded as a string).
  _i2.Future<_i1.UuidValue> echoUuid(_i1.UuidValue value) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'primitives',
        'echoUuid',
        {'value': value},
      );

  /// Round-trip a chunk of binary data.
  ///
  /// `ByteData` is base64-encoded on the wire and decoded back to a
  /// `Uint8Array` in TypeScript.
  _i2.Future<_i7.ByteData> echoBytes(_i7.ByteData value) =>
      caller.callServerEndpoint<_i7.ByteData>(
        'primitives',
        'echoBytes',
        {'value': value},
      );
}

/// Endpoint that exposes both an explicitly-public method (via
/// `@unauthenticatedClientCall`) and an implicitly-public method (no
/// annotation, no `requireLogin` override).
///
/// The generator must surface `authenticated: false` for the annotated
/// method and `authenticated: true` (default) for the rest.
/// {@category Endpoint}
class EndpointPublic extends _i1.EndpointRef {
  EndpointPublic(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'public';

  /// Health-check ping. Explicitly public — `@unauthenticatedClientCall`
  /// flips this to `authenticated: false` in the generated client even
  /// when the class otherwise requires login.
  _i2.Future<String> ping() => caller.callServerEndpoint<String>(
    'public',
    'ping',
    {},
    authenticated: false,
  );

  /// Echo a name back. Implicitly public: this class does not override
  /// `requireLogin`, so the default (no auth required) applies. Kept as
  /// the contrast surface against [ping].
  _i2.Future<String> hello(String name) => caller.callServerEndpoint<String>(
    'public',
    'hello',
    {'name': name},
  );
}

/// Endpoint with an output-only stream — exercises the WebSocket return path.
/// {@category Endpoint}
class EndpointStreaming extends _i1.EndpointRef {
  EndpointStreaming(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'streaming';

  /// Yield `count` integer values, in order, separated by 10 ms.
  ///
  /// Used by the streaming runtime tests.
  _i2.Stream<int> countTo(int count) =>
      caller.callStreamingServerEndpoint<_i2.Stream<int>, int>(
        'streaming',
        'countTo',
        {'count': count},
        {},
      );
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i8.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    auth = EndpointAuth(this);
    chat = EndpointChat(this);
    collections = EndpointCollections(this);
    legacy = EndpointLegacy(this);
    models = EndpointModels(this);
    nullables = EndpointNullables(this);
    primitives = EndpointPrimitives(this);
    public = EndpointPublic(this);
    streaming = EndpointStreaming(this);
  }

  late final EndpointAuth auth;

  late final EndpointChat chat;

  late final EndpointCollections collections;

  late final EndpointLegacy legacy;

  late final EndpointModels models;

  late final EndpointNullables nullables;

  late final EndpointPrimitives primitives;

  late final EndpointPublic public;

  late final EndpointStreaming streaming;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'chat': chat,
    'collections': collections,
    'legacy': legacy,
    'models': models,
    'nullables': nullables,
    'primitives': primitives,
    'public': public,
    'streaming': streaming,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {};
}
