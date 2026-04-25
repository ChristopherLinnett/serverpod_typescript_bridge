// ignore_for_file: implementation_imports
import 'package:serverpod_cli/analyzer.dart';
import 'package:serverpod_cli/src/analyzer/models/definitions.dart'
    show
        InheritanceDefinition,
        ResolvedInheritanceDefinition,
        UnresolvedInheritanceDefinition;

import 'endpoint_to_json.dart' show typeToJson;

Map<String, dynamic> modelToJson(SerializableModelDefinition model) {
  if (model is ModelClassDefinition) return _classToJson(model);
  if (model is ExceptionClassDefinition) return _exceptionToJson(model);
  if (model is EnumDefinition) return _enumToJson(model);
  return <String, dynamic>{
    'kind': 'unknown',
    'className': model.className,
  };
}

Map<String, dynamic> _classToJson(ModelClassDefinition model) {
  return <String, dynamic>{
    'kind': 'class',
    'className': model.className,
    'documentation': model.documentation,
    'sealed': model.isSealed,
    'extends': _extendsName(model.extendsClass),
    'fields': model.fields.map(_fieldToJson).toList(),
  };
}

Map<String, dynamic> _exceptionToJson(ExceptionClassDefinition model) {
  return <String, dynamic>{
    'kind': 'exception',
    'className': model.className,
    'documentation': model.documentation,
    'fields': model.fields.map(_fieldToJson).toList(),
  };
}

Map<String, dynamic> _enumToJson(EnumDefinition model) {
  // EnumDefinition.serialized is an enum from serverpod_service_client.
  // Reading its `.name` getter ('byIndex' | 'byName') avoids importing
  // that package transitively just to hold a constant.
  return <String, dynamic>{
    'kind': 'enum',
    'className': model.className,
    'documentation': model.documentation,
    'serialized': model.serialized.name,
    'values': model.values
        .map((v) => <String, dynamic>{
              'name': v.name,
              'documentation': v.documentation,
            })
        .toList(),
  };
}

Map<String, dynamic> _fieldToJson(SerializableModelFieldDefinition field) {
  return <String, dynamic>{
    'name': field.name,
    'type': typeToJson(field.type),
    'documentation': field.documentation,
  };
}

String? _extendsName(InheritanceDefinition? inheritance) {
  if (inheritance is UnresolvedInheritanceDefinition) {
    return inheritance.className;
  }
  if (inheritance is ResolvedInheritanceDefinition) {
    return inheritance.classDefinition.className;
  }
  return null;
}
