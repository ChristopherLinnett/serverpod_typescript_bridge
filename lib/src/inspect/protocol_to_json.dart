import 'package:serverpod_cli/analyzer.dart';

import 'endpoint_to_json.dart';
import 'model_to_json.dart';

/// Serialises a [ProtocolDefinition] to a plain JSON-encodable map. This is
/// a debug/inspection format only; round-tripping is not guaranteed.
Map<String, dynamic> protocolToJson(ProtocolDefinition protocol) {
  return <String, dynamic>{
    'endpoints': protocol.endpoints.map(endpointToJson).toList(),
    'models': protocol.models.map(modelToJson).toList(),
  };
}
