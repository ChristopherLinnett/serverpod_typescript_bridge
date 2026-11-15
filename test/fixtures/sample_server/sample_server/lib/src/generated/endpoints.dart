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
import 'dart:typed_data' as _idt;
import 'package:sample_server/src/generated/admin_profile.dart' as _i5xo2253;
import 'package:sample_server/src/generated/animal.dart' as _i0fip8qp;
import 'package:sample_server/src/generated/colour.dart' as _i45zc97h;
import 'package:sample_server/src/generated/embedding.dart' as _ilfzvnzj;
import 'package:sample_server/src/generated/priority.dart' as _i6c81z3f;
import 'package:sample_server/src/generated/protocol.dart' as _ihzje0n3;
import 'package:sample_server/src/generated/settings.dart' as _iz7hiou6;
import 'package:sample_server/src/generated/user_profile.dart' as _ih6x7256;
import 'package:serverpod/serverpod.dart' as _is;
import '../endpoints/auth_endpoint.dart' as _iyggisn2;
import '../endpoints/chat_endpoint.dart' as _ihc7hrsa;
import '../endpoints/collections_endpoint.dart' as _ihprpcuc;
import '../endpoints/enums_endpoint.dart' as _ina4wexy;
import '../endpoints/legacy_endpoint.dart' as _izucs9c5;
import '../endpoints/models_endpoint.dart' as _i786o3s0;
import '../endpoints/nullables_endpoint.dart' as _iu6vbvwm;
import '../endpoints/params_endpoint.dart' as _ihjq15zl;
import '../endpoints/primitives_endpoint.dart' as _i7rq4rrd;
import '../endpoints/public_endpoint.dart' as _i4hkjnk3;
import '../endpoints/streaming_endpoint.dart' as _imcmdcu0;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    initializeOwnEndpoints(server);
  }

  @override
  void initializeOwnEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'auth': _iyggisn2.AuthEndpoint()
        ..initialize(
          server,
          'auth',
          null,
        ),
      'chat': _ihc7hrsa.ChatEndpoint()
        ..initialize(
          server,
          'chat',
          null,
        ),
      'collections': _ihprpcuc.CollectionsEndpoint()
        ..initialize(
          server,
          'collections',
          null,
        ),
      'enums': _ina4wexy.EnumsEndpoint()
        ..initialize(
          server,
          'enums',
          null,
        ),
      'legacy': _izucs9c5.LegacyEndpoint()
        ..initialize(
          server,
          'legacy',
          null,
        ),
      'models': _i786o3s0.ModelsEndpoint()
        ..initialize(
          server,
          'models',
          null,
        ),
      'nullables': _iu6vbvwm.NullablesEndpoint()
        ..initialize(
          server,
          'nullables',
          null,
        ),
      'params': _ihjq15zl.ParamsEndpoint()
        ..initialize(
          server,
          'params',
          null,
        ),
      'primitives': _i7rq4rrd.PrimitivesEndpoint()
        ..initialize(
          server,
          'primitives',
          null,
        ),
      'public': _i4hkjnk3.PublicEndpoint()
        ..initialize(
          server,
          'public',
          null,
        ),
      'streaming': _imcmdcu0.StreamingEndpoint()
        ..initialize(
          server,
          'streaming',
          null,
        ),
    };
    connectors['auth'] = _is.EndpointConnector(
      name: 'auth',
      endpoint: endpoints['auth']!,
      methodConnectors: {
        'whoAmI': _is.MethodConnector(
          name: 'whoAmI',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _iyggisn2.AuthEndpoint).whoAmI(session),
        ),
        'secret': _is.MethodConnector(
          name: 'secret',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['auth'] as _iyggisn2.AuthEndpoint).secret(session),
        ),
        'whoAmIStream': _is.MethodStreamConnector(
          name: 'whoAmIStream',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['auth'] as _iyggisn2.AuthEndpoint).whoAmIStream(
                session,
              ),
        ),
      },
    );
    connectors['chat'] = _is.EndpointConnector(
      name: 'chat',
      endpoint: endpoints['chat']!,
      methodConnectors: {
        'echoStream': _is.MethodStreamConnector(
          name: 'echoStream',
          params: {},
          streamParams: {
            'messages': _is.StreamParameterDescription<String>(
              name: 'messages',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['chat'] as _ihc7hrsa.ChatEndpoint).echoStream(
                session,
                streamParams['messages']!.cast<String>(),
              ),
        ),
      },
    );
    connectors['collections'] = _is.EndpointConnector(
      name: 'collections',
      endpoint: endpoints['collections']!,
      methodConnectors: {
        'echoIntList': _is.MethodConnector(
          name: 'echoIntList',
          params: {
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<List<int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['collections'] as _ihprpcuc.CollectionsEndpoint)
                      .echoIntList(
                        session,
                        params['values'],
                      ),
        ),
        'echoStringSet': _is.MethodConnector(
          name: 'echoStringSet',
          params: {
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<Set<String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['collections'] as _ihprpcuc.CollectionsEndpoint)
                      .echoStringSet(
                        session,
                        params['values'],
                      ),
        ),
        'echoStringIntMap': _is.MethodConnector(
          name: 'echoStringIntMap',
          params: {
            'entries': _is.ParameterDescription(
              name: 'entries',
              type: _is.getType<Map<String, int>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['collections'] as _ihprpcuc.CollectionsEndpoint)
                      .echoStringIntMap(
                        session,
                        params['entries'],
                      ),
        ),
        'echoIntStringMap': _is.MethodConnector(
          name: 'echoIntStringMap',
          params: {
            'entries': _is.ParameterDescription(
              name: 'entries',
              type: _is.getType<Map<int, String>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['collections'] as _ihprpcuc.CollectionsEndpoint)
                      .echoIntStringMap(
                        session,
                        params['entries'],
                      )
                      .then(
                        (container) =>
                            _ihzje0n3.Protocol().mapContainerToJson(container),
                      ),
        ),
      },
    );
    connectors['enums'] = _is.EndpointConnector(
      name: 'enums',
      endpoint: endpoints['enums']!,
      methodConnectors: {
        'echoPriority': _is.MethodConnector(
          name: 'echoPriority',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_i6c81z3f.Priority>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['enums'] as _ina4wexy.EnumsEndpoint).echoPriority(
                    session,
                    params['value'],
                  ),
        ),
        'echoColour': _is.MethodConnector(
          name: 'echoColour',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_i45zc97h.Colour>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['enums'] as _ina4wexy.EnumsEndpoint).echoColour(
                    session,
                    params['value'],
                  ),
        ),
        'echoNullablePriority': _is.MethodConnector(
          name: 'echoNullablePriority',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_i6c81z3f.Priority?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['enums'] as _ina4wexy.EnumsEndpoint)
                  .echoNullablePriority(
                    session,
                    params['value'],
                  ),
        ),
        'echoPriorities': _is.MethodConnector(
          name: 'echoPriorities',
          params: {
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<List<_i6c81z3f.Priority>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['enums'] as _ina4wexy.EnumsEndpoint)
                  .echoPriorities(
                    session,
                    params['values'],
                  ),
        ),
        'echoColourMap': _is.MethodConnector(
          name: 'echoColourMap',
          params: {
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<Map<String, _i45zc97h.Colour>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['enums'] as _ina4wexy.EnumsEndpoint).echoColourMap(
                    session,
                    params['values'],
                  ),
        ),
      },
    );
    connectors['legacy'] = _is.EndpointConnector(
      name: 'legacy',
      endpoint: endpoints['legacy']!,
      methodConnectors: {
        'greet': _is.MethodConnector(
          name: 'greet',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['legacy'] as _izucs9c5.LegacyEndpoint).greet(
                    session,
                    params['name'],
                  ),
        ),
        'sayHi': _is.MethodConnector(
          name: 'sayHi',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['legacy'] as _izucs9c5.LegacyEndpoint).sayHi(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    connectors['models'] = _is.EndpointConnector(
      name: 'models',
      endpoint: endpoints['models']!,
      methodConnectors: {
        'echoProfile': _is.MethodConnector(
          name: 'echoProfile',
          params: {
            'profile': _is.ParameterDescription(
              name: 'profile',
              type: _is.getType<_ih6x7256.UserProfile>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i786o3s0.ModelsEndpoint).echoProfile(
                    session,
                    params['profile'],
                  ),
        ),
        'promoteToAdmin': _is.MethodConnector(
          name: 'promoteToAdmin',
          params: {
            'profile': _is.ParameterDescription(
              name: 'profile',
              type: _is.getType<_ih6x7256.UserProfile>(),
              nullable: false,
            ),
            'scope': _is.ParameterDescription(
              name: 'scope',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['models'] as _i786o3s0.ModelsEndpoint)
                  .promoteToAdmin(
                    session,
                    params['profile'],
                    params['scope'],
                  ),
        ),
        'echoAnimal': _is.MethodConnector(
          name: 'echoAnimal',
          params: {
            'animal': _is.ParameterDescription(
              name: 'animal',
              type: _is.getType<_i0fip8qp.Animal>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i786o3s0.ModelsEndpoint).echoAnimal(
                    session,
                    params['animal'],
                  ),
        ),
        'findOrThrow': _is.MethodConnector(
          name: 'findOrThrow',
          params: {
            'id': _is.ParameterDescription(
              name: 'id',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['models'] as _i786o3s0.ModelsEndpoint).findOrThrow(
                    session,
                    params['id'],
                  ),
        ),
      },
    );
    connectors['nullables'] = _is.EndpointConnector(
      name: 'nullables',
      endpoint: endpoints['nullables']!,
      methodConnectors: {
        'nullableInt': _is.MethodConnector(
          name: 'nullableInt',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _iu6vbvwm.NullablesEndpoint)
                  .nullableInt(
                    session,
                    params['value'],
                  ),
        ),
        'nullableString': _is.MethodConnector(
          name: 'nullableString',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _iu6vbvwm.NullablesEndpoint)
                  .nullableString(
                    session,
                    params['value'],
                  ),
        ),
        'nullableProfile': _is.MethodConnector(
          name: 'nullableProfile',
          params: {
            'profile': _is.ParameterDescription(
              name: 'profile',
              type: _is.getType<_ih6x7256.UserProfile?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _iu6vbvwm.NullablesEndpoint)
                  .nullableProfile(
                    session,
                    params['profile'],
                  ),
        ),
        'nullableList': _is.MethodConnector(
          name: 'nullableList',
          params: {
            'values': _is.ParameterDescription(
              name: 'values',
              type: _is.getType<List<int>?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['nullables'] as _iu6vbvwm.NullablesEndpoint)
                  .nullableList(
                    session,
                    params['values'],
                  ),
        ),
      },
    );
    connectors['params'] = _is.EndpointConnector(
      name: 'params',
      endpoint: endpoints['params']!,
      methodConnectors: {
        'named': _is.MethodConnector(
          name: 'named',
          params: {
            'a': _is.ParameterDescription(
              name: 'a',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'b': _is.ParameterDescription(
              name: 'b',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'c': _is.ParameterDescription(
              name: 'c',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['params'] as _ihjq15zl.ParamsEndpoint).named(
                    session,
                    params['a'],
                    b: params['b'],
                    c: params['c'],
                  ),
        ),
        'optional': _is.MethodConnector(
          name: 'optional',
          params: {
            'a': _is.ParameterDescription(
              name: 'a',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'b': _is.ParameterDescription(
              name: 'b',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['params'] as _ihjq15zl.ParamsEndpoint).optional(
                    session,
                    params['a'],
                    params['b'],
                  ),
        ),
        'typed': _is.MethodConnector(
          name: 'typed',
          params: {
            'at': _is.ParameterDescription(
              name: 'at',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
            'length': _is.ParameterDescription(
              name: 'length',
              type: _is.getType<Duration>(),
              nullable: false,
            ),
            'big': _is.ParameterDescription(
              name: 'big',
              type: _is.getType<BigInt>(),
              nullable: false,
            ),
            'ids': _is.ParameterDescription(
              name: 'ids',
              type: _is.getType<Set<int>>(),
              nullable: false,
            ),
            'labels': _is.ParameterDescription(
              name: 'labels',
              type: _is.getType<Map<int, String>>(),
              nullable: false,
            ),
            'profiles': _is.ParameterDescription(
              name: 'profiles',
              type: _is.getType<List<_ih6x7256.UserProfile>>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['params'] as _ihjq15zl.ParamsEndpoint).typed(
                    session,
                    params['at'],
                    params['length'],
                    params['big'],
                    params['ids'],
                    params['labels'],
                    params['profiles'],
                  ),
        ),
        'echoSettings': _is.MethodConnector(
          name: 'echoSettings',
          params: {
            'settings': _is.ParameterDescription(
              name: 'settings',
              type: _is.getType<_iz7hiou6.Settings>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['params'] as _ihjq15zl.ParamsEndpoint)
                  .echoSettings(
                    session,
                    params['settings'],
                  ),
        ),
        'defaultSettings': _is.MethodConnector(
          name: 'defaultSettings',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['params'] as _ihjq15zl.ParamsEndpoint)
                  .defaultSettings(session),
        ),
        'echoEmbedding': _is.MethodConnector(
          name: 'echoEmbedding',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_ilfzvnzj.Embedding>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['params'] as _ihjq15zl.ParamsEndpoint)
                  .echoEmbedding(
                    session,
                    params['value'],
                  ),
        ),
        'throwQuota': _is.MethodConnector(
          name: 'throwQuota',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['params'] as _ihjq15zl.ParamsEndpoint)
                  .throwQuota(session),
        ),
        'asParent': _is.MethodConnector(
          name: 'asParent',
          params: {
            'admin': _is.ParameterDescription(
              name: 'admin',
              type: _is.getType<_i5xo2253.AdminProfile>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['params'] as _ihjq15zl.ParamsEndpoint).asParent(
                    session,
                    params['admin'],
                  ),
        ),
        'echoUri': _is.MethodConnector(
          name: 'echoUri',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<Uri>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['params'] as _ihjq15zl.ParamsEndpoint).echoUri(
                    session,
                    params['value'],
                  ),
        ),
      },
    );
    connectors['primitives'] = _is.EndpointConnector(
      name: 'primitives',
      endpoint: endpoints['primitives']!,
      methodConnectors: {
        'echoInt': _is.MethodConnector(
          name: 'echoInt',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoInt(
                        session,
                        params['value'],
                      ),
        ),
        'echoDouble': _is.MethodConnector(
          name: 'echoDouble',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<double>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoDouble(
                        session,
                        params['value'],
                      ),
        ),
        'echoString': _is.MethodConnector(
          name: 'echoString',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoString(
                        session,
                        params['value'],
                      ),
        ),
        'echoBool': _is.MethodConnector(
          name: 'echoBool',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<bool>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoBool(
                        session,
                        params['value'],
                      ),
        ),
        'echoDateTime': _is.MethodConnector(
          name: 'echoDateTime',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<DateTime>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoDateTime(
                        session,
                        params['value'],
                      ),
        ),
        'echoDuration': _is.MethodConnector(
          name: 'echoDuration',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<Duration>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoDuration(
                        session,
                        params['value'],
                      ),
        ),
        'echoBigInt': _is.MethodConnector(
          name: 'echoBigInt',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<BigInt>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoBigInt(
                        session,
                        params['value'],
                      ),
        ),
        'echoUuid': _is.MethodConnector(
          name: 'echoUuid',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoUuid(
                        session,
                        params['value'],
                      ),
        ),
        'echoBytes': _is.MethodConnector(
          name: 'echoBytes',
          params: {
            'value': _is.ParameterDescription(
              name: 'value',
              type: _is.getType<_idt.ByteData>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['primitives'] as _i7rq4rrd.PrimitivesEndpoint)
                      .echoBytes(
                        session,
                        params['value'],
                      ),
        ),
      },
    );
    connectors['public'] = _is.EndpointConnector(
      name: 'public',
      endpoint: endpoints['public']!,
      methodConnectors: {
        'ping': _is.MethodConnector(
          name: 'ping',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['public'] as _i4hkjnk3.PublicEndpoint).ping(
                session,
              ),
        ),
        'hello': _is.MethodConnector(
          name: 'hello',
          params: {
            'name': _is.ParameterDescription(
              name: 'name',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['public'] as _i4hkjnk3.PublicEndpoint).hello(
                    session,
                    params['name'],
                  ),
        ),
      },
    );
    connectors['streaming'] = _is.EndpointConnector(
      name: 'streaming',
      endpoint: endpoints['streaming']!,
      methodConnectors: {
        'countTo': _is.MethodStreamConnector(
          name: 'countTo',
          params: {
            'count': _is.ParameterDescription(
              name: 'count',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .countTo(
                    session,
                    params['count'],
                  ),
        ),
        'endless': _is.MethodStreamConnector(
          name: 'endless',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .endless(session),
        ),
        'profiles': _is.MethodStreamConnector(
          name: 'profiles',
          params: {
            'seed': _is.ParameterDescription(
              name: 'seed',
              type: _is.getType<_ih6x7256.UserProfile>(),
              nullable: false,
            ),
            'count': _is.ParameterDescription(
              name: 'count',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .profiles(
                    session,
                    params['seed'],
                    params['count'],
                  ),
        ),
        'animals': _is.MethodStreamConnector(
          name: 'animals',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .animals(session),
        ),
        'priorities': _is.MethodStreamConnector(
          name: 'priorities',
          params: {},
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .priorities(session),
        ),
        'chunks': _is.MethodStreamConnector(
          name: 'chunks',
          params: {
            'count': _is.ParameterDescription(
              name: 'count',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .chunks(
                    session,
                    params['count'],
                  ),
        ),
        'failAfter': _is.MethodStreamConnector(
          name: 'failAfter',
          params: {
            'count': _is.ParameterDescription(
              name: 'count',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          streamParams: {},
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .failAfter(
                    session,
                    params['count'],
                  ),
        ),
        'sum': _is.MethodStreamConnector(
          name: 'sum',
          params: {},
          streamParams: {
            'values': _is.StreamParameterDescription<int>(
              name: 'values',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.futureType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint).sum(
                session,
                streamParams['values']!.cast<int>(),
              ),
        ),
        'drain': _is.MethodStreamConnector(
          name: 'drain',
          params: {},
          streamParams: {
            'values': _is.StreamParameterDescription<String>(
              name: 'values',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.voidType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) =>
                  (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint).drain(
                    session,
                    streamParams['values']!.cast<String>(),
                  ),
        ),
        'echoAnimals': _is.MethodStreamConnector(
          name: 'echoAnimals',
          params: {},
          streamParams: {
            'animals': _is.StreamParameterDescription<_i0fip8qp.Animal>(
              name: 'animals',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .echoAnimals(
                    session,
                    streamParams['animals']!.cast<_i0fip8qp.Animal>(),
                  ),
        ),
        'describeLists': _is.MethodStreamConnector(
          name: 'describeLists',
          params: {},
          streamParams: {
            'lists': _is.StreamParameterDescription<List<int>>(
              name: 'lists',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .describeLists(
                    session,
                    streamParams['lists']!.cast<List<int>>(),
                  ),
        ),
        'describePriorities': _is.MethodStreamConnector(
          name: 'describePriorities',
          params: {},
          streamParams: {
            'priorities': _is.StreamParameterDescription<_i6c81z3f.Priority>(
              name: 'priorities',
              nullable: false,
            ),
          },
          returnType: _is.MethodStreamReturnType.streamType,
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
                Map<String, Stream> streamParams,
              ) => (endpoints['streaming'] as _imcmdcu0.StreamingEndpoint)
                  .describePriorities(
                    session,
                    streamParams['priorities']!.cast<_i6c81z3f.Priority>(),
                  ),
        ),
      },
    );
  }
}
