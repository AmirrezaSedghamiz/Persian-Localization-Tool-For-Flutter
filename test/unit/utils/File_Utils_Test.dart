import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:test/test.dart';

void main() {
  final testDir = Directory('test_file_utils');

  setUp(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('createL10nDirectory', () {
    test('should create l10n directory', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        createL10nDirectory();
        
        final l10nDir = Directory('l10n');
        expect(l10nDir.existsSync(), isTrue);
      } finally {
        Directory.current = originalDir.path;
      }
    });

    test('should not error if directory already exists', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        // Create directory first
        Directory('l10n').createSync(recursive: true);
        
        // Should not throw
        expect(() => createL10nDirectory(), returnsNormally);
        
        final l10nDir = Directory('l10n');
        expect(l10nDir.existsSync(), isTrue);
      } finally {
        Directory.current = originalDir.path;
      }
    });
  });

  group('writeStringLocationsReport', () {
    test('should write string locations report', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        createL10nDirectory();
        
        final extractedStrings = {
          'fa_1': 'سلام دنیا',
          'fa_2': 'خوش آمدید',
        };
        
        final stringLocations = {
          'fa_1': [
            StringLocation(
              filePath: 'lib/main.dart',
              offset: 100,
              end: 108,
              originalText: "'سلام دنیا'",
              context: 'Text widget',
            ),
          ],
          'fa_2': [
            StringLocation(
              filePath: 'lib/home.dart',
              offset: 50,
              end: 62,
              originalText: "'خوش آمدید'",
              context: 'AppBar title',
            ),
          ],
        };
        
        writeStringLocationsReport(extractedStrings, stringLocations);
        
        // Check JSON file
        final jsonFile = File('l10n/string_locations.json');
        expect(jsonFile.existsSync(), isTrue);
        
        final jsonData = json.decode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
        expect(jsonData.length, equals(2));
        expect(jsonData['fa_1']?['text'], equals('سلام دنیا'));
        expect(jsonData['fa_2']?['text'], equals('خوش آمدید'));
        
        // Check text file
        final textFile = File('l10n/string_locations.txt');
        expect(textFile.existsSync(), isTrue);
        
        final textContent = textFile.readAsStringSync();
        expect(textContent, contains('STRING LOCATIONS REPORT'));
        expect(textContent, contains('fa_1'));
        expect(textContent, contains('fa_2'));
        expect(textContent, contains('سلام دنیا'));
        expect(textContent, contains('خوش آمدید'));
      } finally {
        Directory.current = originalDir.path;
      }
    });
  });

  group('writeDynamicStringsReport', () {
    test('should write dynamic strings report', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        createL10nDirectory();
        
        final dynamicStrings = [
          'Dynamic string 1: variable + "سلام"',
          'Dynamic string 2: "خوش آمدید" + userName',
          'Complex concatenation: formatCurrency(amount) + " تومان"',
        ];
        
        writeDynamicStringsReport(dynamicStrings);
        
        final reportFile = File('l10n/dynamic_strings.txt');
        expect(reportFile.existsSync(), isTrue);
        
        final content = reportFile.readAsStringSync();
        expect(content, contains('DYNAMIC STRINGS REPORT'));
        expect(content, contains('Dynamic string 1'));
        expect(content, contains('Dynamic string 2'));
        expect(content, contains('Complex concatenation'));
      } finally {
        Directory.current = originalDir.path;
      }
    });

    test('should handle empty dynamic strings', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        createL10nDirectory();
        
        writeDynamicStringsReport([]);
        
        // Should create file even if empty
        final reportFile = File('l10n/dynamic_strings.txt');
        expect(reportFile.existsSync(), isTrue);
      } finally {
        Directory.current = originalDir.path;
      }
    });
  });

  group('writeProcessingReportFile', () {
    test('should write processing report', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        createL10nDirectory();
        
        final processedFiles = [
          'lib/main.dart',
          'lib/home.dart',
          'lib/widgets/button.dart',
        ];
        
        final skippedFiles = [
          'lib/utils/math.dart',
          'lib/models/user.dart',
        ];
        
        writeProcessingReportFile(processedFiles, skippedFiles);
        
        final reportFile = File('l10n/processing_report.txt');
        expect(reportFile.existsSync(), isTrue);
        
        final content = reportFile.readAsStringSync();
        expect(content, contains('PROCESSING REPORT'));
        expect(content, contains('PROCESSED FILES (3):'));
        expect(content, contains('SKIPPED FILES (2):'));
        expect(content, contains('lib/main.dart'));
        expect(content, contains('lib/home.dart'));
        expect(content, contains('lib/widgets/button.dart'));
        expect(content, contains('lib/utils/math.dart'));
        expect(content, contains('lib/models/user.dart'));
      } finally {
        Directory.current = originalDir.path;
      }
    });
  });

  group('cleanGeneratedFiles', () {
    test('should clean generated files', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        // Create test files
        Directory('l10n').createSync(recursive: true);
        Directory('lib/generated').createSync(recursive: true);
        
        File('l10n/intl_fa.arb').writeAsStringSync('{}');
        File('l10n/intl_en.arb').writeAsStringSync('{}');
        File('l10n/string_locations.json').writeAsStringSync('{}');
        File('l10n/string_locations.txt').writeAsStringSync('');
        File('l10n/dynamic_strings.txt').writeAsStringSync('');
        File('l10n/processing_report.txt').writeAsStringSync('');
        File('lib/generated/localizations.dart').writeAsStringSync('');
        
        // Also create some other files that should not be deleted
        File('l10n/keep_this.arb').writeAsStringSync('{}');
        File('lib/generated/keep_this.dart').writeAsStringSync('');
        
        cleanGeneratedFiles();
        
        // Check files were deleted
        expect(File('l10n/intl_fa.arb').existsSync(), isFalse);
        expect(File('l10n/intl_en.arb').existsSync(), isFalse);
        expect(File('l10n/string_locations.json').existsSync(), isFalse);
        expect(File('l10n/string_locations.txt').existsSync(), isFalse);
        expect(File('l10n/dynamic_strings.txt').existsSync(), isFalse);
        expect(File('l10n/processing_report.txt').existsSync(), isFalse);
        expect(File('lib/generated/localizations.dart').existsSync(), isFalse);
        
        // Check other files still exist
        expect(File('l10n/keep_this.arb').existsSync(), isTrue);
        expect(File('lib/generated/keep_this.dart').existsSync(), isTrue);
      } finally {
        Directory.current = originalDir.path;
      }
    });

    test('should handle missing files gracefully', () {
      final originalDir = Directory.current;
      Directory.current = testDir.path;

      try {
        // Should not throw when files don't exist
        expect(() => cleanGeneratedFiles(), returnsNormally);
      } finally {
        Directory.current = originalDir.path;
      }
    });
  });
}