import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:path/path.dart' as p;

import '../domain/models/ui_vocabulary.dart';
import 'models/evidence_models.dart';
import 'models/project_registry.dart';
import 'passes/analyzer_passes.dart';

class UiVocabularyAnalyzer {
  Future<UiVocabulary> analyze(String projectPath) async {
    final normalizedPath = p.normalize(p.absolute(projectPath));
    final dir = Directory(normalizedPath);
    if (!await dir.exists()) {
      print('Project path does not exist: $normalizedPath');
      return UiVocabulary.empty();
    }

    print('Initializing Dart Analyzer for type resolution...');
    final collection =
        AnalysisContextCollection(includedPaths: [normalizedPath]);
    print('Found ${collection.contexts.length} analysis contexts.');

    final registry = ProjectRegistry();
    final visitor = TypedEvidenceVisitor(registry);

    for (final context in collection.contexts) {
      for (final filePath in context.contextRoot.analyzedFiles()) {
        if (filePath.endsWith('.dart') &&
            !filePath.contains('/.dart_tool/') &&
            !filePath.contains('\\.dart_tool\\') &&
            !filePath.contains('/test/') &&
            !filePath.contains('\\test\\') &&
            !filePath.contains('/integration_test/') &&
            !filePath.contains('\\integration_test\\')) {
          try {
            final result =
                await context.currentSession.getResolvedUnit(filePath);
            if (result is ResolvedUnitResult) {
              result.unit.visitChildren(visitor);
            }
          } catch (e) {
            // Ignore files that can't be resolved
          }
        }
      }
    }

    // Propagate widget status through project-local inheritance tree
    bool changed = true;
    while (changed) {
      changed = false;
      for (final entry in registry.identifiers.entries) {
        final ev = entry.value;
        if (ev.kind == EntityKind.unknown || ev.kind == EntityKind.otherClass) {
          final parentName = ev.superclassName;
          if (parentName != null) {
            final parent = registry.identifiers[parentName];
            if (parent != null && parent.isWidget) {
              ev.kind = EntityKind.widgetClass;
              changed = true;
            }
          }
        }
      }
    }

    final uiIndicators = <String>{};
    final textWidgets = <String>{};
    final textParameters = <String>{};

    for (final entry in registry.identifiers.entries) {
      final ev = entry.value;
      if (ev.isUiIndicator) {
        uiIndicators.add(ev.name);
      }
      if (ev.isTextWidget) {
        textWidgets.add(ev.name);
      }
    }

    for (final entry in registry.parameters.entries) {
      final ev = entry.value;
      if (ev.isTextParameter) {
        textParameters.add(ev.name);
      }
    }

    // Baseline fallbacks for standard extraction, if not discovered
    if (uiIndicators.isEmpty) {
      uiIndicators.addAll({'Widget', 'Text', 'Column', 'Row', 'Container'});
    }

    print('Analysis complete.');
    print('   Discovered UI Indicators: ${uiIndicators.length}');
    print('   Discovered Text Widgets: ${textWidgets.length}');
    print('   Discovered Text Parameters: ${textParameters.length}');

    return UiVocabulary(
      textParameters: textParameters,
      textWidgets: textWidgets,
      uiIndicators: uiIndicators,
    );
  }
}
