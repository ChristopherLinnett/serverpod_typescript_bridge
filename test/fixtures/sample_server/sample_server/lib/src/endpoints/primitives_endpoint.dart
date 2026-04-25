import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

/// Endpoint that exercises every primitive type the v0.1 generator must
/// support.
///
/// {@template primitives_doc}
/// Used by the doc-comment passthrough tests — Dart-doc templates and macros
/// must survive the analyzer round-trip.
/// {@endtemplate}
class PrimitivesEndpoint extends Endpoint {
  /// Round-trip an `int`.
  ///
  /// {@macro primitives_doc}
  Future<int> echoInt(Session session, int value) async => value;

  /// Round-trip a `double`.
  Future<double> echoDouble(Session session, double value) async => value;

  /// Round-trip a `String`.
  ///
  /// Inline code: `String` maps to TypeScript `string`.
  Future<String> echoString(Session session, String value) async => value;

  /// Round-trip a `bool`.
  Future<bool> echoBool(Session session, bool value) async => value;

  /// Round-trip a `DateTime` (always UTC on the wire).
  Future<DateTime> echoDateTime(Session session, DateTime value) async => value;

  /// Round-trip a `Duration` (encoded as integer milliseconds).
  Future<Duration> echoDuration(Session session, Duration value) async => value;

  /// Round-trip a `BigInt` (encoded as a string).
  Future<BigInt> echoBigInt(Session session, BigInt value) async => value;

  /// Round-trip a `UuidValue` (encoded as a string).
  Future<UuidValue> echoUuid(Session session, UuidValue value) async => value;

  /// Round-trip a chunk of binary data.
  ///
  /// `ByteData` is base64-encoded on the wire and decoded back to a
  /// `Uint8Array` in TypeScript.
  Future<ByteData> echoBytes(Session session, ByteData value) async => value;
}
