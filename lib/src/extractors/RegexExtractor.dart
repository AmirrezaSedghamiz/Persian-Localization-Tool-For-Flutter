import 'dart:io';

import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:persian_localizer/src/utils/TextUtils.dart';

/// Fallback extraction using regex patterns
void extractStringsWithRegex(String content, String filePath) {
  final regex = RegExp(
      r'''['"]([^'"\n]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+[^'"\n]*)['"]''');
  final matches = regex.allMatches(content);

  for (final match in matches) {
    if (match.groupCount > 0) {
      final value = match.group(1) ?? '';
      if (value.trim().isNotEmpty) {
        final key = 'fa_${++globals.counter}';
        if (!globals.extractedStrings.containsKey(key)) {
          globals.extractedStrings[key] = value;
          print('   ✅ Fallback extracted: "${truncateText(value)}"');
        }
      }
    }
  }
}