import 'evidence_models.dart';

class ProjectRegistry {
  final Map<String, IdentifierEvidence> identifiers = {};
  final Map<String, ParameterEvidence> parameters = {};

  IdentifierEvidence getIdentifier(String name) {
    // Strip generics if present
    final baseName = name.split('<').first.trim();
    return identifiers.putIfAbsent(
        baseName, () => IdentifierEvidence(baseName));
  }

  ParameterEvidence getParameter(String name) {
    return parameters.putIfAbsent(name, () => ParameterEvidence(name));
  }

  void recordEntityKind(String name, EntityKind kind) {
    getIdentifier(name).kind = kind;
  }

  void recordInstantiation(
      String name, bool inUiContext, bool takesPositionalString) {
    final ev = getIdentifier(name);
    ev.widgetConstructionOccurrences++;
    if (inUiContext) ev.uiContextOccurrences++;
    if (takesPositionalString) ev.positionalStringArguments++;
  }

  void recordParameterUsage(String name,
      {required bool isStringType,
      required bool isStringLiteral,
      required bool isNonString,
      required bool inUiContext}) {
    final ev = getParameter(name);
    if (isStringType) ev.stringTypeUsages++;
    if (isStringLiteral) ev.stringLiteralUsages++;
    if (isNonString) ev.nonStringUsages++;
    if (inUiContext) ev.uiContextUsages++;
  }
}
