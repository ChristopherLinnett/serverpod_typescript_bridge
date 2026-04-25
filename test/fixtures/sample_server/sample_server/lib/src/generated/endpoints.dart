/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: deprecated_member_use_from_same_package

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../endpoints/auth_endpoint.dart' as _i2;
import '../endpoints/chat_endpoint.dart' as _i3;
import '../endpoints/collections_endpoint.dart' as _i4;
import '../endpoints/legacy_endpoint.dart' as _i5;
import '../endpoints/models_endpoint.dart' as _i6;
import '../endpoints/nullables_endpoint.dart' as _i7;
import '../endpoints/primitives_endpoint.dart' as _i8;
import '../endpoints/public_endpoint.dart' as _i9;
import '../endpoints/streaming_endpoint.dart' as _i10;
import 'package:sample_server/src/generated/protocol.dart' as _i11;
import 'package:sample_server/src/generated/user_profile.dart' as _i12;
import 'package:sample_server/src/generated/animal.dart' as _i13;
import 'dart:typed_data' as _i14;

class Endpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'auth': _i2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'chat': _i3.ChatEndpoint()
        ..initialize(
          server,
          'chat',
          null,
        ),
      'collections': _i4.CollectionsEndpoint()
        ..initialize(
          server,
          'collections',
          null,
        ),
      'legacy': _i5.LegacyEndpoint()
        ..initialize(
          server,
          'legacy',
          null,
        ),
      'models': _i6.ModelsEndpoint()
        ..initialize(
          server,
          'models',
          null,
        ),
      'nullables': _i7.NullablesEndpoint()
        ..initialize(
          server,
          'nullables',
          null,
        ),
      'primitives': _i8.PrimitivesEndpoint()
        ..initialize(
          server,
          'primitives',
          null,
        ),
      'public': _i9.PublicEndpoint()
        ..initialize(
          server,
          'public',
          null,
        ),
      'streaming': _i10.StreamingEndpoint()
        ..initialize(
          server,
          'streaming',
          null,
        ),
    };
    connectors['auth'] = _i1.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'whoAmI': _i1.MethodConnector(
          name: 'whoAmI',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).whoAmI(session),
        ),
        'secret': _i1.MethodConnector(
          name: 'secret',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _i2.AuthEndpoint).secret(session),
        ),
      },
    );
    connectors['chat'] = _i1.EndpointConnector(
      name: 'chat',
      endpoint: endpoints['chat']!,
      methodConnectors: {
        'echoStream': _i1.MethodStreamConnector(
          name: 'echoStream',
          params: {},
          streamParams: {
            'messages': _i1.StreamParameterDescription<String>(
              name: 'messages',
              nullable: false,
            ),
          },
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['chat'] as _i3.ChatEndpoint).echoStream(
                session,
                streamParams['messages']!.cast<String>(),
              ),
        ),
      },
    );
    connectors['collections'] = _i1.EndpointConnector(
      name: 'collections',
      endpoint: endpoints['collections']!,
      methodConnectors: {
        'echoIntList': _i1.MethodConnector(
          name: 'echoIntList',
          params: {
            'values': _i1.ParameterDescription(
              name: 'values',
              type: _i1.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['collections'] as _i4.CollectionsEndpoint)
                  .echoIntList(
                    session,
                    params['values'],
                  ),
        ),
        'echoStringSet': _i1.MethodConnector(
          name: 'echoStringSet',
          params: {
            'values': _i1.ParameterDescription(
              name: 'values',
              type: _i1.getType<Set<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['collections'] as _i4.CollectionsEndpoint)
                  .echoStringSet(
                    session,
                    params['values'],
                  ),
        ),
        'echoStringIntMap': _i1.MethodConnector(
          name: 'echoStringIntMap',
          params: {
            'entries': _i1.ParameterDescription(
              name: 'entries',
              type: _i1.getType<Map<String, int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['collections'] as _i4.CollectionsEndpoint)
                  .echoStringIntMap(
                    session,
                    params['entries'],
                  ),
        ),
        'echoIntStringMap': _i1.MethodConnector(
          name: 'echoIntStringMap',
          params: {
            'entries': _i1.ParameterDescription(
              name: 'entries',
              type: _i1.getType<Map<int, String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['collections'] as _i4.CollectionsEndpoint)
                  .echoIntStringMap(
                    session,
                    params['entries'],
                  )
                  .then(
                    (container) =>
                        _i11.Protocol().mapContainerToJson(container),
                  ),
        ),
      },
    );
    connectors['legacy'] = _i1.EndpointConnector(
      name: 'legacy',
      endpoint: endpoints['legacy']!,
      methodConnectors: {
        'greet': _i1.MethodConnector(
          name: 'greet',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['legacy'] as _i5.LegacyEndpoint).greet(
                session,
                params['name'],
              ),
        ),
        'sayHi': _i1.MethodConnector(
          name: 'sayHi',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['legacy'] as _i5.LegacyEndpoint).sayHi(
                session,
                params['name'],
              ),
        ),
      },
    );
    connectors['models'] = _i1.EndpointConnector(
      name: 'models',
      endpoint: endpoints['models']!,
      methodConnectors: {
        'echoProfile': _i1.MethodConnector(
          name: 'echoProfile',
          params: {
            'profile': _i1.ParameterDescription(
              name: 'profile',
              type: _i1.getType<_i12.UserProfile>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i6.ModelsEndpoint).echoProfile(
                    session,
                    params['profile'],
                  ),
        ),
        'promoteToAdmin': _i1.MethodConnector(
          name: 'promoteToAdmin',
          params: {
            'profile': _i1.ParameterDescription(
              name: 'profile',
              type: _i1.getType<_i12.UserProfile>(),
              nullable: false,
            ),
            'scope': _i1.ParameterDescription(
              name: 'scope',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i6.ModelsEndpoint).promoteToAdmin(
                    session,
                    params['profile'],
                    params['scope'],
                  ),
        ),
        'echoAnimal': _i1.MethodConnector(
          name: 'echoAnimal',
          params: {
            'animal': _i1.ParameterDescription(
              name: 'animal',
              type: _i1.getType<_i13.Animal>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['models'] as _i6.ModelsEndpoint).echoAnimal(
                session,
                params['animal'],
              ),
        ),
        'findOrThrow': _i1.MethodConnector(
          name: 'findOrThrow',
          params: {
            'id': _i1.ParameterDescription(
              name: 'id',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i6.ModelsEndpoint).findOrThrow(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['nullables'] = _i1.EndpointConnector(
      name: 'nullables',
      endpoint: endpoints['nullables']!,
      methodConnectors: {
        'nullableInt': _i1.MethodConnector(
          name: 'nullableInt',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['nullables'] as _i7.NullablesEndpoint).nullableInt(
                    session,
                    params['value'],
                  ),
        ),
        'nullableString': _i1.MethodConnector(
          name: 'nullableString',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _i7.NullablesEndpoint)
                  .nullableString(
                    session,
                    params['value'],
                  ),
        ),
        'nullableProfile': _i1.MethodConnector(
          name: 'nullableProfile',
          params: {
            'profile': _i1.ParameterDescription(
              name: 'profile',
              type: _i1.getType<_i12.UserProfile?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _i7.NullablesEndpoint)
                  .nullableProfile(
                    session,
                    params['profile'],
                  ),
        ),
        'nullableList': _i1.MethodConnector(
          name: 'nullableList',
          params: {
            'values': _i1.ParameterDescription(
              name: 'values',
              type: _i1.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _i7.NullablesEndpoint)
                  .nullableList(
                    session,
                    params['values'],
                  ),
        ),
      },
    );
    connectors['primitives'] = _i1.EndpointConnector(
      name: 'primitives',
      endpoint: endpoints['primitives']!,
      methodConnectors: {
        'echoInt': _i1.MethodConnector(
          name: 'echoInt',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i8.PrimitivesEndpoint).echoInt(
                    session,
                    params['value'],
                  ),
        ),
        'echoDouble': _i1.MethodConnector(
          name: 'echoDouble',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['primitives'] as _i8.PrimitivesEndpoint)
                  .echoDouble(
                    session,
                    params['value'],
                  ),
        ),
        'echoString': _i1.MethodConnector(
          name: 'echoString',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['primitives'] as _i8.PrimitivesEndpoint)
                  .echoString(
                    session,
                    params['value'],
                  ),
        ),
        'echoBool': _i1.MethodConnector(
          name: 'echoBool',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i8.PrimitivesEndpoint).echoBool(
                    session,
                    params['value'],
                  ),
        ),
        'echoDateTime': _i1.MethodConnector(
          name: 'echoDateTime',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['primitives'] as _i8.PrimitivesEndpoint)
                  .echoDateTime(
                    session,
                    params['value'],
                  ),
        ),
        'echoDuration': _i1.MethodConnector(
          name: 'echoDuration',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<Duration>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['primitives'] as _i8.PrimitivesEndpoint)
                  .echoDuration(
                    session,
                    params['value'],
                  ),
        ),
        'echoBigInt': _i1.MethodConnector(
          name: 'echoBigInt',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<BigInt>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['primitives'] as _i8.PrimitivesEndpoint)
                  .echoBigInt(
                    session,
                    params['value'],
                  ),
        ),
        'echoUuid': _i1.MethodConnector(
          name: 'echoUuid',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<_i1.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i8.PrimitivesEndpoint).echoUuid(
                    session,
                    params['value'],
                  ),
        ),
        'echoBytes': _i1.MethodConnector(
          name: 'echoBytes',
          params: {
            'value': _i1.ParameterDescription(
              name: 'value',
              type: _i1.getType<_i14.ByteData>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i8.PrimitivesEndpoint).echoBytes(
                    session,
                    params['value'],
                  ),
        ),
      },
    );
    connectors['public'] = _i1.EndpointConnector(
      name: 'public',
      endpoint: endpoints['public']!,
      methodConnectors: {
        'ping': _i1.MethodConnector(
          name: 'ping',
          params: {},
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['public'] as _i9.PublicEndpoint).ping(session),
        ),
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['public'] as _i9.PublicEndpoint).hello(
                session,
                params['name'],
              ),
        ),
      },
    );
    connectors['streaming'] = _i1.EndpointConnector(
      name: 'streaming',
      endpoint: endpoints['streaming']!,
      methodConnectors: {
        'countTo': _i1.MethodStreamConnector(
          name: 'countTo',
          params: {
            'count': _i1.ParameterDescription(
              name: 'count',
              type: _i1.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _i1.MethodStreamReturnType.streamType,
          call:
              (
                _i1.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _i10.StreamingEndpoint).countTo(
                session,
                params['count'],
              ),
        ),
      },
    );
  }
}
