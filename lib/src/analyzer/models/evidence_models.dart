enum EntityKind {
  widgetClass,
  stateClass,
  otherClass,
  method,
  function,
  unknown
}

class IdentifierEvidence {
  final String name;

  EntityKind kind = EntityKind.unknown;

  int widgetConstructionOccurrences = 0;
  int uiContextOccurrences = 0;

  int positionalStringArguments = 0;
  int textDataFlowOccurrences = 0;

  String? superclassName;

  bool declaresStructuralParameters = false;

  IdentifierEvidence(this.name);

  bool get isWidget =>
      kind == EntityKind.widgetClass ||
      (kind == EntityKind.unknown &&
          widgetConstructionOccurrences > 0 &&
          uiContextOccurrences > 0);

  bool get isUiIndicator {
    if (!isWidget) return false;

    if (declaresStructuralParameters) return true;

    // If it's heavily constructed as a child/descendant inside other UI components.
    if (uiContextOccurrences > 2) return true;

    return false;
  }

  bool get isTextWidget {
    // Explicit inclusion for core text components that might not meet dynamic heuristics
    // (e.g. TextSpan is not a Widget, RichText uses named arguments instead of positional)
    if (name == 'TextSpan' ||
        name == 'InlineSpan' ||
        name == 'RichText' ||
        name == 'SelectableText' ||
        name == 'TextField' ||
        name == 'TextFormField') {
      return true;
    }

    if (!isWidget) return false;

    // The user strictly wants leaf-node textual framework primitives (Text, TextSpan, etc).
    // Custom wrapper pages/widgets should NOT be in this list just because they pass data to Text.
    // We identify textual framework primitives dynamically by checking if they are
    // external/framework widgets (kind == unknown) that accept positional string arguments.
    if (kind == EntityKind.unknown && positionalStringArguments > 0)
      return true;

    return false;
  }
}

class ParameterEvidence {
  final String name;

  int stringTypeUsages = 0;
  int stringLiteralUsages = 0;
  int nonStringUsages = 0;
  int uiContextUsages = 0;
  int definitionSiteTextUsages = 0;

  ParameterEvidence(this.name);

  bool get isTextParameter {
    if (definitionSiteTextUsages > 0) return true;

    int score = 0;

    // Positive structural evidence (Capped to prevent runaway scores from sheer volume)
    score += (stringLiteralUsages * 10).clamp(0, 30);
    score += (stringTypeUsages * 1).clamp(0, 10);
    score += (uiContextUsages * 1).clamp(0, 10);

    // Negative structural evidence
    score -= (nonStringUsages * 15).clamp(0, 50);

    // Heuristic evidence
    final lower = name.toLowerCase();
    if (lower.contains('title') ||
        lower.contains('label') ||
        lower.contains('text') ||
        lower.contains('message') ||
        lower.contains('caption') ||
        lower.contains('hint') ||
        lower.contains('description')) {
      score +=
          15; // Increased heuristic weight to help valid textual names cross the 15 point threshold
    }

    // Strong negative heuristic exclusions (URLs, paths, IDs, etc)
    if (lower.contains('url') ||
        lower.contains('path') ||
        lower.contains('file') ||
        lower.contains('id') ||
        lower.contains('key') ||
        lower.contains('token') ||
        lower.contains('logo') ||
        lower.contains('img') ||
        lower.contains('avatar') ||
        lower.contains('color') ||
        lower.contains('style') ||
        lower.contains('controller') ||
        lower.contains('node')) {
      score -= 50;
    }

    return score >= 15;
  }
}
