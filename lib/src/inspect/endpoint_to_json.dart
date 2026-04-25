// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/dart/definitions.dart';

Map<String, dynamic> endpointToJson(EndpointDefinition endpoint) {
  return <String, dynamic>{
    'name': endpoint.name,
    'className': endpoint.className,
    'documentation': endpoint.documentationComment,
    'methods': endpoint.methods.map(_methodToJson).toList(),
  };
}

Map<String, dynamic> _methodToJson(MethodDefinition method) {
  return <String, dynamic>{
    'name': method.name,
    'documentation': method.documentationComment,
    'returnType': typeToJson(method.returnType),
    'parameters': [
      ...method.parameters.map((p) => _parameterToJson(p, kind: 'required')),
      ...method.parametersPositional
          .map((p) => _parameterToJson(p, kind: 'positional')),
      ...method.parametersNamed
          .map((p) => _parameterToJson(p, kind: 'named')),
    ],
    'unauthenticated':
        method.annotations.any((a) => a.name == 'unauthenticatedClientCall'),
    'streaming': method is MethodStreamDefinition,
  };
}

Map<String, dynamic> _parameterToJson(
  ParameterDefinition parameter, {
  required String kind,
}) {
  return <String, dynamic>{
    'name': parameter.name,
    'kind': kind,
    'type': typeToJson(parameter.type),
    'required': parameter.required,
  };
}

Map<String, dynamic> typeToJson(TypeDefinition type) {
  return <String, dynamic>{
    'className': type.className,
    'nullable': type.nullable,
    'generics': type.generics.map(typeToJson).toList(),
  };
}
