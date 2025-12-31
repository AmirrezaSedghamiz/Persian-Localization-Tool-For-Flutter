import 'dart:io';
import 'dart:convert';

import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:persian_localizer/src/utils/TextUtils.dart';


/// Analyzes extraction results
void analyzeExtractionResults() {
  print('📊 Analyzing extraction results...');

  final faArbFile = File('l10n/intl_fa.arb');
  if (!faArbFile.existsSync()) {
    print('❌ No ARB file found. Run extraction first.');
    return;
  }

  final faContent = faArbFile.readAsStringSync();
  final faMap = json.decode(faContent) as Map<String, dynamic>;

  print('📈 Statistics:');
  print('   Total extracted strings: ${faMap.length}');

  int totalChars = 0;
  int maxLength = 0;
  String longestString = '';

  for (final entry in faMap.entries) {
    final length = (entry.value as String).length;
    totalChars += length;

    if (length > maxLength) {
      maxLength = length;
      longestString = entry.value;
    }
  }

  final avgLength = faMap.isEmpty ? 0 : totalChars / faMap.length;

  print('   Average string length: ${avgLength.toStringAsFixed(1)} characters');
  print('   Longest string: $maxLength characters');
  print('   Longest text: "${truncateText(longestString, 50)}"');

  print('\n🎯 Sample of extracted strings (first 5):');
  final sampleKeys = faMap.keys.take(5).toList();
  for (final key in sampleKeys) {
    final value = faMap[key] as String;
    print('   • $key: "${truncateText(value, 30)}"');
  }

  final locationsFile = File('l10n/string_locations.json');
  if (locationsFile.existsSync()) {
    final locationsContent = locationsFile.readAsStringSync();
    final locationsData = json.decode(locationsContent) as Map<String, dynamic>;

    int totalLocations = 0;
    for (final entry in locationsData.entries) {
      final data = entry.value as Map<String, dynamic>;
      final locations = data['locations'] as List<dynamic>;
      totalLocations += locations.length;
    }

    print('\n📍 Location data:');
    print('   Total string locations: $totalLocations');
    final avgLocations = faMap.isEmpty ? 0 : totalLocations / faMap.length;
    print(
        '   Average locations per string: ${avgLocations.toStringAsFixed(2)}');
  }

  // Analyze concatenation patterns
  _analyzeConcatenationPatterns();
}

/// Analyzes concatenation patterns
void _analyzeConcatenationPatterns() {
  print('\n🔗 Concatenation Analysis:');

  int simpleConcatenations = 0;
  int complexConcatenations = 0;
  final patternExamples = <String>[];

  for (final dynamicString in globals.dynamicStrings) {
    if (dynamicString.contains('COMPLEX EDGE CASE')) {
      complexConcatenations++;

      // Extract example pattern
      final lines = dynamicString.split('\n');
      for (final line in lines) {
        if (line.contains('Expression:')) {
          final expr = line.replaceAll('Expression:', '').trim();
          if (expr.length < 100) {
            // Avoid very long expressions
            patternExamples.add(expr);
          }
          break;
        }
      }
    } else if (dynamicString.contains('MIXED CONCATENATION')) {
      simpleConcatenations++;
    }
  }

  print('   Simple mixed concatenations: $simpleConcatenations');
  print('   Complex edge cases: $complexConcatenations');

  if (patternExamples.isNotEmpty) {
    print('\n   Example edge cases found:');
    for (int i = 0; i < _min(3, patternExamples.length); i++) {
      print('     • ${patternExamples[i]}');
    }
    print(
        '\n   💡 These edge cases need manual refactoring for proper localization');
  }
}

int _min(int a, int b) => a < b ? a : b;