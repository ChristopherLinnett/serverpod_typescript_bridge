import 'dart:io';

import 'package:serverpod_typescript_bridge/src/analyzer/protocol_loader.dart';
import 'package:serverpod_typescript_bridge/src/inspect/protocol_to_json.dart';
import 'package:test/test.dart';

/// Asserts that the IR JSON serialization is lossless and structured as
/// downstream tools expect.
void main() {
  group('protocolToJson', () {
    late Map<String, dynamic> json;

    setUpAll(() async {
      final ir = await ProtocolLoader.load(
        Directory('test/fixtures/sample_server/sample_server'),
      );
      json = protocolToJson(ir);
    });

    test('top-level shape contains endpoints and models arrays', () {
      expect(json.containsKey('endpoints'), isTrue);
      expect(json.containsKey('models'), isTrue);
      expect(json['endpoints'], isA<List<dynamic>>());
      expect(json['models'], isA<List<dynamic>>());
    });

    test('endpoint JSON includes name and method names', () {
      final endpoints = (json['endpoints'] as List).cast<Map<String, dynamic>>();
      final primitives = endpoints.firstWhere((e) => e['name'] == 'primitives');
      expect(primitives['methods'], isA<List<dynamic>>());
      expect((primitives['methods'] as List), isNotEmpty);
      final firstMethod = (primitives['methods'] as List).first as Map<String, dynamic>;
      expect(firstMethod['name'], isA<String>());
    });

    test('endpoint JSON preserves the @unauthenticatedClientCall flag', () {
      final endpoints = (json['endpoints'] as List).cast<Map<String, dynamic>>();
      final public = endpoints.firstWhere((e) => e['name'] == 'public');
      final ping = (public['methods'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((m) => m['name'] == 'ping');
      expect(ping['unauthenticated'], isTrue);
    });

    test('model JSON includes className and a fields array for classes', () {
      final models = (json['models'] as List).cast<Map<String, dynamic>>();
      final userProfile = models.firstWhere((m) => m['className'] == 'UserProfile');
      expect(userProfile['kind'], 'class');
      expect(userProfile['fields'], isA<List<dynamic>>());
      expect((userProfile['fields'] as List), isNotEmpty);
    });

    test('enum models record their serialization mode', () {
      final models = (json['models'] as List).cast<Map<String, dynamic>>();
      final priority = models.firstWhere((m) => m['className'] == 'Priority');
      final colour = models.firstWhere((m) => m['className'] == 'Colour');
      expect(priority['kind'], 'enum');
      expect(priority['serialized'], 'byIndex');
      expect(colour['kind'], 'enum');
      expect(colour['serialized'], 'byName');
    });

    test('exception models are tagged kind=exception', () {
      final models = (json['models'] as List).cast<Map<String, dynamic>>();
      final exc = models.firstWhere((m) => m['className'] == 'NotFoundException');
      expect(exc['kind'], 'exception');
    });

    test('sealed class is flagged sealed=true', () {
      final models = (json['models'] as List).cast<Map<String, dynamic>>();
      final animal = models.firstWhere((m) => m['className'] == 'Animal');
      expect(animal['sealed'], isTrue);
    });
  });
}
