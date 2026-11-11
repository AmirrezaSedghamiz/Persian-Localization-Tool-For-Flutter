import 'dart:io';
import 'package:analyzer/dart/analysis/utilities.dart';
import '../domain/models/extraction_state.dart';
import '../domain/models/ui_vocabulary.dart';
import '../utils/string_utils.dart';
import 'ast_visitor.dart';

class Extractor {
  final ExtractionState state;
  final UiVocabulary vocabulary;

  Extractor(this.state, this.vocabulary);

  void extractFromFile(File file) {
    final content = file.readAsStringSync();
    final shouldProcess = _shouldProcessFile(content, file.path);

    if (!shouldProcess) {
      print('   ⏭️ Skipping - no relevant content found');
      state.skippedFiles.add(file.path);
      return;
    }

    try {
      final result = parseString(content: content, path: file.path);
      result.unit.visitChildren(PersianStringVisitor(file.path, state, vocabulary));
      state.processedFiles.add(file.path);
    } catch (e) {
      print('   ⚠️ Parser error, trying fallback: $e');
      extractWithFallback(file);
      state.processedFiles.add(file.path);
    }
  }

  void extractWithFallback(File file) {
    final content = file.readAsStringSync();
    print('   🔍 Using fallback regex extraction for ${file.path}');

    final regex = RegExp(
        r'''['"]([^'"\n]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+[^'"\n]*)['"]''');
    final matches = regex.allMatches(content);

    for (final match in matches) {
      if (match.groupCount > 0) {
        final value = match.group(1) ?? '';
        if (value.trim().isNotEmpty) {
          final key = 'fa_${++state.counter}';
          if (!state.extractedStrings.containsKey(key)) {
            state.extractedStrings[key] = value;
            print('   ✅ Fallback extracted: "${truncateText(value)}"');
          }
        }
      }
    }
  }

  bool _shouldProcessFile(String content, String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.contains('screen') ||
        lowerPath.contains('page') ||
        lowerPath.contains('view') ||
        lowerPath.contains('widget')) {
      return true;
    }

    final hasPersianText = RegExp(
            r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]')
        .hasMatch(content);

    bool hasUI = false;
    for (final indicator in vocabulary.uiIndicators) {
      if (content.contains(' $indicator') ||
          content.contains('$indicator(') ||
          content.contains('extends $indicator') ||
          content.contains('class.*$indicator')) {
        hasUI = true;
        break;
      }
    }

    return hasPersianText || hasUI;
  }
}
