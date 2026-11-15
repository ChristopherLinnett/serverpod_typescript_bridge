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
import 'dart:async' as _ida;
import 'dart:typed_data' as _idt;
import 'package:http/http.dart' as _i85jenna;
import 'package:sample_client/src/protocol/admin_profile.dart' as _i87ypfn1;
import 'package:sample_client/src/protocol/animal.dart' as _ieml1ztw;
import 'package:sample_client/src/protocol/colour.dart' as _is36gx7z;
import 'package:sample_client/src/protocol/embedding.dart' as _idmfqfuv;
import 'package:sample_client/src/protocol/priority.dart' as _iy4p1hnt;
import 'package:sample_client/src/protocol/protocol.dart' as _isi7l7qn;
import 'package:sample_client/src/protocol/settings.dart' as _ihx4g6a3;
import 'package:sample_client/src/protocol/user_profile.dart' as _iye2z13d;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// Endpoint whose every method requires an authenticated session.
///
/// Overriding `requireLogin` flips the auth gate at the server. The generated
/// TS client should still expose the methods normally; auth enforcement is the
/// runtime's job.
/// {@category Endpoint}
class EndpointAuth extends _isc.EndpointRef {
  EndpointAuth(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'auth';

  /// Echo the authenticated user's identifier.
  ///
  /// The `'anonymous'` fallback is unreachable in production (the
  /// `requireLogin` gate already rejects unauthenticated calls), but keeps
  /// this fixture self-contained: tests that pass a non-authenticated
  /// session via `serverpod_test` still get a deterministic response
  /// instead of a null-deref crash.
  _ida.Future<String> whoAmI() => caller.callServerEndpoint<String>(
    'auth',
    'whoAmI',
    {},
  );

  /// Echo a string only authenticated callers can reach.
  _ida.Future<String> secret() => caller.callServerEndpoint<String>(
    'auth',
    'secret',
    {},
  );

  /// The same gate on the stream transport.
  _ida.Stream<String> whoAmIStream() =>
      caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
        'auth',
        'whoAmIStream',
        {},
        {},
      );
}

/// Endpoint with both an input `Stream<String>` and an output `Stream<String>`.
///
/// Exercises the bidirectional streaming path: client emits messages on an
/// `AsyncIterable`, server echoes each one back (uppercased).
/// {@category Endpoint}
class EndpointChat extends _isc.EndpointRef {
  EndpointChat(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'chat';

  /// Echo each inbound message back, uppercased.
  _ida.Stream<String> echoStream(_ida.Stream<String> messages) =>
      caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
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
class EndpointCollections extends _isc.EndpointRef {
  EndpointCollections(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'collections';

  /// Round-trip a `List<int>`.
  _ida.Future<List<int>> echoIntList(List<int> values) =>
      caller.callServerEndpoint<List<int>>(
        'collections',
        'echoIntList',
        {'values': values},
      );

  /// Round-trip a `Set<String>` (serialized as a JSON array).
  _ida.Future<Set<String>> echoStringSet(Set<String> values) =>
      caller.callServerEndpoint<Set<String>>(
        'collections',
        'echoStringSet',
        {'values': values},
      );

  /// Round-trip a `Map<String, int>` (serialized as a JSON object).
  _ida.Future<Map<String, int>> echoStringIntMap(Map<String, int> entries) =>
      caller.callServerEndpoint<Map<String, int>>(
        'collections',
        'echoStringIntMap',
        {'entries': entries},
      );

  /// Round-trip a `Map<int, String>` — non-string keys serialize as a list
  /// of `{k, v}` pairs.
  _ida.Future<Map<int, String>> echoIntStringMap(Map<int, String> entries) =>
      caller.callServerEndpoint<Map<int, String>>(
        'collections',
        'echoIntStringMap',
        {'entries': _isi7l7qn.Protocol().mapContainerToJson(entries)},
      );
}

/// Enum arguments and returns — an enum sent by index and one sent by name
/// are both plain values to a TypeScript caller, so the generated code has
/// to encode each by its declared type.
/// {@category Endpoint}
class EndpointEnums extends _isc.EndpointRef {
  EndpointEnums(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'enums';

  /// Echo a `byIndex` enum.
  _ida.Future<_iy4p1hnt.Priority> echoPriority(_iy4p1hnt.Priority value) =>
      caller.callServerEndpoint<_iy4p1hnt.Priority>(
        'enums',
        'echoPriority',
        {'value': value},
      );

  /// Echo a `byName` enum.
  _ida.Future<_is36gx7z.Colour> echoColour(_is36gx7z.Colour value) =>
      caller.callServerEndpoint<_is36gx7z.Colour>(
        'enums',
        'echoColour',
        {'value': value},
      );

  /// Echo a nullable enum.
  _ida.Future<_iy4p1hnt.Priority?> echoNullablePriority(
    _iy4p1hnt.Priority? value,
  ) => caller.callServerEndpoint<_iy4p1hnt.Priority?>(
    'enums',
    'echoNullablePriority',
    {'value': value},
  );

  /// Echo a list of enums.
  _ida.Future<List<_iy4p1hnt.Priority>> echoPriorities(
    List<_iy4p1hnt.Priority> values,
  ) => caller.callServerEndpoint<List<_iy4p1hnt.Priority>>(
    'enums',
    'echoPriorities',
    {'values': values},
  );

  /// Echo a map with enum values.
  _ida.Future<Map<String, _is36gx7z.Colour>> echoColourMap(
    Map<String, _is36gx7z.Colour> values,
  ) => caller.callServerEndpoint<Map<String, _is36gx7z.Colour>>(
    'enums',
    'echoColourMap',
    {'values': values},
  );
}

/// Endpoint that retains a `@Deprecated` method for backwards compatibility.
///
/// The deprecation annotation must propagate to the generated TS client as a
/// JSDoc `@deprecated` tag.
/// {@category Endpoint}
class EndpointLegacy extends _isc.EndpointRef {
  EndpointLegacy(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'legacy';

  /// The current way to greet a user.
  _ida.Future<String> greet(String name) => caller.callServerEndpoint<String>(
    'legacy',
    'greet',
    {'name': name},
  );

  /// Old-style greeting.
  @Deprecated('Use `greet` instead.')
  _ida.Future<String> sayHi(String name) => caller.callServerEndpoint<String>(
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
class EndpointModels extends _isc.EndpointRef {
  EndpointModels(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'models';

  /// Echo a [UserProfile] back to the caller.
  _ida.Future<_iye2z13d.UserProfile> echoProfile(
    _iye2z13d.UserProfile profile,
  ) => caller.callServerEndpoint<_iye2z13d.UserProfile>(
    'models',
    'echoProfile',
    {'profile': profile},
  );

  /// Promote a [UserProfile] to an [AdminProfile] with the given scope.
  ///
  /// Exercises non-sealed inheritance on the return type.
  _ida.Future<_i87ypfn1.AdminProfile> promoteToAdmin(
    _iye2z13d.UserProfile profile,
    String scope,
  ) => caller.callServerEndpoint<_i87ypfn1.AdminProfile>(
    'models',
    'promoteToAdmin',
    {
      'profile': profile,
      'scope': scope,
    },
  );

  /// Echo a sealed [Animal] back to the caller. Exercises polymorphism via
  /// `__className__` dispatch.
  _ida.Future<_ieml1ztw.Animal> echoAnimal(_ieml1ztw.Animal animal) =>
      caller.callServerEndpoint<_ieml1ztw.Animal>(
        'models',
        'echoAnimal',
        {'animal': animal},
      );

  /// Throws a typed [NotFoundException] so the runtime's typed-exception
  /// decoder can be exercised.
  _ida.Future<_iye2z13d.UserProfile> findOrThrow(int id) =>
      caller.callServerEndpoint<_iye2z13d.UserProfile>(
        'models',
        'findOrThrow',
        {'id': id},
      );
}

/// Endpoint where every parameter and return is nullable. Exercises the
/// `omit-on-null` `toJson` shape and the optional-arg generator path.
/// {@category Endpoint}
class EndpointNullables extends _isc.EndpointRef {
  EndpointNullables(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'nullables';

  /// All-nullable primitive round-trip.
  _ida.Future<int?> nullableInt(int? value) => caller.callServerEndpoint<int?>(
    'nullables',
    'nullableInt',
    {'value': value},
  );

  /// All-nullable string round-trip.
  _ida.Future<String?> nullableString(String? value) =>
      caller.callServerEndpoint<String?>(
        'nullables',
        'nullableString',
        {'value': value},
      );

  /// Nullable model round-trip.
  _ida.Future<_iye2z13d.UserProfile?> nullableProfile(
    _iye2z13d.UserProfile? profile,
  ) => caller.callServerEndpoint<_iye2z13d.UserProfile?>(
    'nullables',
    'nullableProfile',
    {'profile': profile},
  );

  /// Nullable list round-trip.
  _ida.Future<List<int>?> nullableList(List<int>? values) =>
      caller.callServerEndpoint<List<int>?>(
        'nullables',
        'nullableList',
        {'values': values},
      );
}

/// Parameter shapes: named, optional positional, and typed arguments that
/// need encoding on the way in.
/// {@category Endpoint}
class EndpointParams extends _isc.EndpointRef {
  EndpointParams(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'params';

  /// Required and optional named parameters.
  _ida.Future<String> named(
    String a, {
    required int b,
    String? c,
  }) => caller.callServerEndpoint<String>(
    'params',
    'named',
    {
      'a': a,
      'b': b,
      'c': c,
    },
  );

  /// Optional positional parameter.
  _ida.Future<String> optional(
    String a, [
    int? b,
  ]) => caller.callServerEndpoint<String>(
    'params',
    'optional',
    {
      'a': a,
      'b': b,
    },
  );

  /// Typed arguments: each needs its own wire encoding.
  _ida.Future<String> typed(
    DateTime at,
    Duration length,
    BigInt big,
    Set<int> ids,
    Map<int, String> labels,
    List<_iye2z13d.UserProfile> profiles,
  ) => caller.callServerEndpoint<String>(
    'params',
    'typed',
    {
      'at': at,
      'length': length,
      'big': big,
      'ids': ids,
      'labels': _isi7l7qn.Protocol().mapContainerToJson(labels),
      'profiles': profiles,
    },
  );

  /// A model that carries defaults; the server fills what the caller omits.
  _ida.Future<_ihx4g6a3.Settings> echoSettings(_ihx4g6a3.Settings settings) =>
      caller.callServerEndpoint<_ihx4g6a3.Settings>(
        'params',
        'echoSettings',
        {'settings': settings},
      );

  /// A model built by the server from its defaults alone.
  _ida.Future<_ihx4g6a3.Settings> defaultSettings() =>
      caller.callServerEndpoint<_ihx4g6a3.Settings>(
        'params',
        'defaultSettings',
        {},
      );

  /// Vector and geography values.
  _ida.Future<_idmfqfuv.Embedding> echoEmbedding(_idmfqfuv.Embedding value) =>
      caller.callServerEndpoint<_idmfqfuv.Embedding>(
        'params',
        'echoEmbedding',
        {'value': value},
      );

  /// Throws an exception that extends another.
  _ida.Future<void> throwQuota() => caller.callServerEndpoint<void>(
    'params',
    'throwQuota',
    {},
  );

  /// Returns a subclass where its parent is declared.
  _ida.Future<_iye2z13d.UserProfile> asParent(_i87ypfn1.AdminProfile admin) =>
      caller.callServerEndpoint<_iye2z13d.UserProfile>(
        'params',
        'asParent',
        {'admin': admin},
      );

  /// Echo a `Uri`.
  _ida.Future<Uri> echoUri(Uri value) => caller.callServerEndpoint<Uri>(
    'params',
    'echoUri',
    {'value': value},
  );
}

/// Endpoint that exercises every primitive type the v0.1 generator must
/// support.
///

/// Used by the doc-comment passthrough tests — Dart-doc templates and macros
/// must survive the analyzer round-trip.
/// {@category Endpoint}
class EndpointPrimitives extends _isc.EndpointRef {
  EndpointPrimitives(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'primitives';

  /// Round-trip an `int`.
  ///
  /// Used by the doc-comment passthrough tests — Dart-doc templates and macros
  /// must survive the analyzer round-trip.
  _ida.Future<int> echoInt(int value) => caller.callServerEndpoint<int>(
    'primitives',
    'echoInt',
    {'value': value},
  );

  /// Round-trip a `double`.
  _ida.Future<double> echoDouble(double value) =>
      caller.callServerEndpoint<double>(
        'primitives',
        'echoDouble',
        {'value': value},
      );

  /// Round-trip a `String`.
  ///
  /// Inline code: `String` maps to TypeScript `string`.
  _ida.Future<String> echoString(String value) =>
      caller.callServerEndpoint<String>(
        'primitives',
        'echoString',
        {'value': value},
      );

  /// Round-trip a `bool`.
  _ida.Future<bool> echoBool(bool value) => caller.callServerEndpoint<bool>(
    'primitives',
    'echoBool',
    {'value': value},
  );

  /// Round-trip a `DateTime` (always UTC on the wire).
  _ida.Future<DateTime> echoDateTime(DateTime value) =>
      caller.callServerEndpoint<DateTime>(
        'primitives',
        'echoDateTime',
        {'value': value},
      );

  /// Round-trip a `Duration` (encoded as integer milliseconds).
  _ida.Future<Duration> echoDuration(Duration value) =>
      caller.callServerEndpoint<Duration>(
        'primitives',
        'echoDuration',
        {'value': value},
      );

  /// Round-trip a `BigInt` (encoded as a string).
  _ida.Future<BigInt> echoBigInt(BigInt value) =>
      caller.callServerEndpoint<BigInt>(
        'primitives',
        'echoBigInt',
        {'value': value},
      );

  /// Round-trip a `UuidValue` (encoded as a string).
  _ida.Future<_isc.UuidValue> echoUuid(_isc.UuidValue value) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'primitives',
        'echoUuid',
        {'value': value},
      );

  /// Round-trip a chunk of binary data.
  ///
  /// `ByteData` is base64-encoded on the wire and decoded back to a
  /// `Uint8Array` in TypeScript.
  _ida.Future<_idt.ByteData> echoBytes(_idt.ByteData value) =>
      caller.callServerEndpoint<_idt.ByteData>(
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
class EndpointPublic extends _isc.EndpointRef {
  EndpointPublic(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'public';

  /// Health-check ping. Explicitly public — `@unauthenticatedClientCall`
  /// flips this to `authenticated: false` in the generated client even
  /// when the class otherwise requires login.
  _ida.Future<String> ping() => caller.callServerEndpoint<String>(
    'public',
    'ping',
    {},
    authenticated: false,
  );

  /// Echo a name back. Implicitly public: this class does not override
  /// `requireLogin`, so the default (no auth required) applies. Kept as
  /// the contrast surface against [ping].
  _ida.Future<String> hello(String name) => caller.callServerEndpoint<String>(
    'public',
    'hello',
    {'name': name},
  );
}

/// Streaming methods — exercises the WebSocket transport in both directions.
/// {@category Endpoint}
class EndpointStreaming extends _isc.EndpointRef {
  EndpointStreaming(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'streaming';

  /// Yield `count` integer values, in order, separated by 10 ms.
  ///
  /// Used by the streaming runtime tests.
  _ida.Stream<int> countTo(int count) =>
      caller.callStreamingServerEndpoint<_ida.Stream<int>, int>(
        'streaming',
        'countTo',
        {'count': count},
        {},
      );

  /// Never ends on its own; the caller has to stop listening.
  _ida.Stream<int> endless() =>
      caller.callStreamingServerEndpoint<_ida.Stream<int>, int>(
        'streaming',
        'endless',
        {},
        {},
      );

  /// A stream of models.
  _ida.Stream<_iye2z13d.UserProfile> profiles(
    _iye2z13d.UserProfile seed,
    int count,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_iye2z13d.UserProfile>,
        _iye2z13d.UserProfile
      >(
        'streaming',
        'profiles',
        {
          'seed': seed,
          'count': count,
        },
        {},
      );

  /// A stream of a sealed type; each value is one of its subclasses.
  _ida.Stream<_ieml1ztw.Animal> animals() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ieml1ztw.Animal>,
        _ieml1ztw.Animal
      >(
        'streaming',
        'animals',
        {},
        {},
      );

  /// A stream of enums.
  _ida.Stream<_iy4p1hnt.Priority> priorities() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_iy4p1hnt.Priority>,
        _iy4p1hnt.Priority
      >(
        'streaming',
        'priorities',
        {},
        {},
      );

  /// A stream of lists.
  _ida.Stream<List<int>> chunks(int count) =>
      caller.callStreamingServerEndpoint<_ida.Stream<List<int>>, List<int>>(
        'streaming',
        'chunks',
        {'count': count},
        {},
      );

  /// Yields `count` values, then fails with a typed exception.
  _ida.Stream<int> failAfter(int count) =>
      caller.callStreamingServerEndpoint<_ida.Stream<int>, int>(
        'streaming',
        'failAfter',
        {'count': count},
        {},
      );

  /// Input stream with a single `Future` result.
  _ida.Future<int> sum(_ida.Stream<int> values) =>
      caller.callStreamingServerEndpoint<_ida.Future<int>, int>(
        'streaming',
        'sum',
        {},
        {'values': values},
      );

  /// Input stream with no result at all.
  _ida.Future<void> drain(_ida.Stream<String> values) =>
      caller.callStreamingServerEndpoint<_ida.Future<void>, void>(
        'streaming',
        'drain',
        {},
        {'values': values},
      );

  /// Models in, models out.
  _ida.Stream<_ieml1ztw.Animal> echoAnimals(
    _ida.Stream<_ieml1ztw.Animal> animals,
  ) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ieml1ztw.Animal>,
        _ieml1ztw.Animal
      >(
        'streaming',
        'echoAnimals',
        {},
        {'animals': animals},
      );

  /// Lists as input stream values.
  _ida.Stream<String> describeLists(_ida.Stream<List<int>> lists) =>
      caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
        'streaming',
        'describeLists',
        {},
        {'lists': lists},
      );

  /// Enums as input stream values.
  _ida.Stream<String> describePriorities(
    _ida.Stream<_iy4p1hnt.Priority> priorities,
  ) => caller.callStreamingServerEndpoint<_ida.Stream<String>, String>(
    'streaming',
    'describePriorities',
    {},
    {'priorities': priorities},
  );
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    auth = EndpointAuth(this);
    chat = EndpointChat(this);
    collections = EndpointCollections(this);
    enums = EndpointEnums(this);
    legacy = EndpointLegacy(this);
    models = EndpointModels(this);
    nullables = EndpointNullables(this);
    params = EndpointParams(this);
    primitives = EndpointPrimitives(this);
    public = EndpointPublic(this);
    streaming = EndpointStreaming(this);
  }

  late final EndpointAuth auth;

  late final EndpointChat chat;

  late final EndpointCollections collections;

  late final EndpointEnums enums;

  late final EndpointLegacy legacy;

  late final EndpointModels models;

  late final EndpointNullables nullables;

  late final EndpointParams params;

  late final EndpointPrimitives primitives;

  late final EndpointPublic public;

  late final EndpointStreaming streaming;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'auth': auth,
    'chat': chat,
    'collections': collections,
    'enums': enums,
    'legacy': legacy,
    'models': models,
    'nullables': nullables,
    'params': params,
    'primitives': primitives,
    'public': public,
    'streaming': streaming,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {};
}
