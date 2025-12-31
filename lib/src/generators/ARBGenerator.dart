import 'dart:io';
import 'dart:convert';

import 'package:persian_localizer/src/generators/DartClassGenerator.dart';
import 'package:persian_localizer/src/utils/TextUtils.dart';

/// Generates Persian ARB file
void generatePersianArbFile(Map<String, String> extractedStrings) {
  final buffer = StringBuffer('{\n');
  final entries = extractedStrings.entries.toList();

  for (int i = 0; i < entries.length; i++) {
    final entry = entries[i];
    buffer.write('  "${entry.key}": "${escapeJson(entry.value)}"');
    if (i < entries.length - 1) buffer.write(',');
    buffer.writeln();
  }
  buffer.write('}');

  File('l10n/intl_fa.arb').writeAsStringSync(buffer.toString());
}

/// Generates ARB files (both Persian and English)
void generateArbFiles() {
  print('🏗️  Building ARB files and localization class...');

  final faArbFile = File('l10n/intl_fa.arb');
  if (!faArbFile.existsSync()) {
    print('❌ Error: l10n/intl_fa.arb not found. Run extraction first.');
    return;
  }

  final faContent = faArbFile.readAsStringSync();
  final faMap = json.decode(faContent) as Map<String, dynamic>;

  // Load existing English ARB if it exists
  final enArbFile = File('l10n/intl_en.arb');
  Map<String, dynamic> enArb = {};

  if (enArbFile.existsSync()) {
    try {
      final enContent = enArbFile.readAsStringSync();
      enArb = json.decode(enContent) as Map<String, dynamic>;
      print('📂 Loaded existing English ARB with ${enArb.length} entries');
    } catch (e) {
      print('⚠️ Could not load existing English ARB: $e');
    }
  }

  // Update English ARB with new keys
  for (final key in faMap.keys) {
    if (!enArb.containsKey(key)) {
      enArb[key] = faMap[key];
    }
  }

  // Write English ARB
  enArbFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(enArb));

  print('✅ Created/Updated:');
  print('   - l10n/intl_fa.arb (${faMap.length} entries)');
  print('   - l10n/intl_en.arb (${enArb.length} entries)');

  // Generate Dart localization class
  generateLocalizationClass(faMap.keys.toList());
}