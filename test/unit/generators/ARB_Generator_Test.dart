import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:test/test.dart';


void main() {
  final testL10nDir = Directory('test_l10n');

  setUp(() {
    if (testL10nDir.existsSync()) {
      testL10nDir.deleteSync(recursive: true);
    }
    
    // Create test directory structure
    Directory('test_l10n').createSync(recursive: true);
    
    // Set up test data
    globals.extractedStrings.clear();
    globals.extractedStrings['fa_1'] = 'سلام دنیا';
    globals.extractedStrings['fa_2'] = 'خوش آمدید';
    globals.extractedStrings['fa_3'] = 'خداحافظ';
  });

  tearDown(() {
    if (testL10nDir.existsSync()) {
      testL10nDir.deleteSync(recursive: true);
    }
  });

  test('should generate Persian ARB file', () {
    // Temporarily change directory for test
    final originalDir = Directory.current;
    Directory.current = testL10nDir.parent.path;

    try {
      globals.generatePersianArbFile(globals.extractedStrings);
      
      final arbFile = File('l10n/intl_fa.arb');
      expect(arbFile.existsSync(), isTrue);
      
      final content = arbFile.readAsStringSync();
      final jsonData = json.decode(content) as Map<String, dynamic>;
      
      expect(jsonData.length, equals(3));
      expect(jsonData['fa_1'], equals('سلام دنیا'));
      expect(jsonData['fa_2'], equals('خوش آمدید'));
      expect(jsonData['fa_3'], equals('خداحافظ'));
      
      // Test proper JSON escaping
      expect(content, contains(r'\"سلام دنیا\"'));
      expect(content, contains(r'\"خوش آمدید\"'));
      expect(content, contains(r'\"خداحافظ\"'));
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should generate ARB files with existing English file', () {
    final originalDir = Directory.current;
    Directory.current = testL10nDir.parent.path;

    try {
      // Create existing English ARB
      final existingEnglish = {
        'fa_1': 'Hello World',
        'fa_4': 'Existing translation',
      };
      
      Directory('l10n').createSync(recursive: true);
      File('l10n/intl_en.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(existingEnglish)
      );
      
      // Generate ARB files
      globals.generateArbFiles();
      
      // Check English ARB was updated
      final enArbFile = File('l10n/intl_en.arb');
      expect(enArbFile.existsSync(), isTrue);
      
      final enContent = json.decode(enArbFile.readAsStringSync()) as Map<String, dynamic>;
      expect(enContent.length, equals(4));
      expect(enContent['fa_1'], equals('Hello World')); // Should keep existing
      expect(enContent['fa_2'], equals('خوش آمدید')); // Should add new
      expect(enContent['fa_3'], equals('خداحافظ')); // Should add new
      expect(enContent['fa_4'], equals('Existing translation')); // Should keep
      
      // Check Persian ARB was created
      final faArbFile = File('l10n/intl_fa.arb');
      expect(faArbFile.existsSync(), isTrue);
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should generate ARB files without existing English file', () {
    final originalDir = Directory.current;
    Directory.current = testL10nDir.parent.path;

    try {
      globals.generateArbFiles();
      
      final enArbFile = File('l10n/intl_en.arb');
      expect(enArbFile.existsSync(), isTrue);
      
      final enContent = json.decode(enArbFile.readAsStringSync()) as Map<String, dynamic>;
      expect(enContent.length, equals(3));
      expect(enContent['fa_1'], equals('سلام دنیا'));
      expect(enContent['fa_2'], equals('خوش آمدید'));
      expect(enContent['fa_3'], equals('خداحافظ'));
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle special characters in ARB generation', () {
    final originalDir = Directory.current;
    Directory.current = testL10nDir.parent.path;

    try {
      globals.extractedStrings.clear();
      globals.extractedStrings['fa_1'] = 'سلام "دنیا" با \'نقل قول\'';
      globals.extractedStrings['fa_2'] = 'خط جدید\nو تب\tو بازگشت\r';
      
      globals.generatePersianArbFile(globals.extractedStrings);
      
      final arbFile = File('l10n/intl_fa.arb');
      final content = arbFile.readAsStringSync();
      
      // Check proper escaping
      expect(content, contains("\"سلام \"دنیا\" با \'نقل قول\'\""));
      expect(content, contains(r'\"خط جدید\nو تب\tو بازگشت\r\"'));
    } finally {
      Directory.current = originalDir.path;
    }
  });
}