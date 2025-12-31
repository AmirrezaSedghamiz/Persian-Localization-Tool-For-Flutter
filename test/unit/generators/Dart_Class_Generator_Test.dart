import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:test/test.dart';

void main() {
  final testGeneratedDir = Directory('test_generated');

  setUp(() {
    if (testGeneratedDir.existsSync()) {
      testGeneratedDir.deleteSync(recursive: true);
    }
    
    // Create test directory structure
    Directory('test_l10n').createSync(recursive: true);
    
    // Create test ARB files
    final faArb = {
      'fa_1': 'سلام دنیا',
      'fa_2': 'خوش آمدید',
      'fa_3': 'خداحافظ',
    };
    
    final enArb = {
      'fa_1': 'Hello World',
      'fa_2': 'Welcome',
      'fa_3': 'Goodbye',
    };
    
    File('test_l10n/intl_fa.arb').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(faArb)
    );
    
    File('test_l10n/intl_en.arb').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(enArb)
    );
  });

  tearDown(() {
    if (testGeneratedDir.existsSync()) {
      testGeneratedDir.deleteSync(recursive: true);
    }
    
    final l10nDir = Directory('test_l10n');
    if (l10nDir.existsSync()) {
      l10nDir.deleteSync(recursive: true);
    }
  });

  test('should generate Dart localization class', () {
    // Temporarily change directory for test
    final originalDir = Directory.current;
    Directory.current = Directory.current.path;

    try {
      // Copy ARB files to expected location
      File('l10n/intl_fa.arb').writeAsStringSync(
        File('test_l10n/intl_fa.arb').readAsStringSync()
      );
      File('l10n/intl_en.arb').writeAsStringSync(
        File('test_l10n/intl_en.arb').readAsStringSync()
      );

      final keys = ['fa_1', 'fa_2', 'fa_3'];
      generateLocalizationClass(keys);
      
      final outputFile = File('lib/generated/localizations.dart');
      expect(outputFile.existsSync(), isTrue);
      
      final content = outputFile.readAsStringSync();
      
      // Check class structure
      expect(content, contains('class AppLocalizations'));
      expect(content, contains('static AppLocalizations of(BuildContext context)'));
      expect(content, contains('const _AppLocalizationsDelegate()'));
      
      // Check translation maps
      expect(content, contains("'fa_1': 'Hello World'"));
      expect(content, contains("'fa_2': 'Welcome'"));
      expect(content, contains("'fa_3': 'Goodbye'"));
      expect(content, contains("'fa_1': 'سلام دنیا'"));
      expect(content, contains("'fa_2': 'خوش آمدید'"));
      expect(content, contains("'fa_3': 'خداحافظ'"));
      
      // Check getter methods
      expect(content, contains('String get fa1 => _getText(\'fa_1\')'));
      expect(content, contains('String get fa2 => _getText(\'fa_2\')'));
      expect(content, contains('String get fa3 => _getText(\'fa_3\')'));
      
      // Check delegate
      expect(content, contains('class _AppLocalizationsDelegate'));
      expect(content, contains('bool isSupported(Locale locale)'));
      expect(content, contains('[\'en\', \'fa\'].contains(locale.languageCode)'));
    } finally {
      Directory.current = originalDir.path;
      
      // Clean up
      final libDir = Directory('lib/generated');
      if (libDir.existsSync()) {
        libDir.deleteSync(recursive: true);
      }
      
      final l10nDir = Directory('l10n');
      if (l10nDir.existsSync()) {
        l10nDir.deleteSync(recursive: true);
      }
    }
  });

  test('should handle missing English translations', () {
    final originalDir = Directory.current;
    Directory.current = Directory.current.path;

    try {
      // Create only Persian ARB
      final faArb = {
        'fa_1': 'سلام دنیا',
        'fa_2': 'خوش آمدید',
      };
      
      Directory('l10n').createSync(recursive: true);
      File('l10n/intl_fa.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(faArb)
      );

      final keys = ['fa_1', 'fa_2'];
      generateLocalizationClass(keys);
      
      final outputFile = File('lib/generated/localizations.dart');
      final content = outputFile.readAsStringSync();
      
      expect(content, contains("'fa_1': 'fa_1', // TODO: Translate to English"));
      expect(content, contains("'fa_2': 'fa_2', // TODO: Translate to English"));
    } finally {
      Directory.current = originalDir.path;
      
      // Clean up
      final libDir = Directory('lib/generated');
      if (libDir.existsSync()) {
        libDir.deleteSync(recursive: true);
      }
      
      final l10nDir = Directory('l10n');
      if (l10nDir.existsSync()) {
        l10nDir.deleteSync(recursive: true);
      }
    }
  });

  test('should escape special characters in Dart strings', () {
    final originalDir = Directory.current;
    Directory.current = Directory.current.path;

    try {
      final faArb = {
        'fa_1': 'سلام "دنیا" با \'نقل قول\'',
        'fa_2': 'خط جدید\nو تب\t',
      };
      
      Directory('l10n').createSync(recursive: true);
      File('l10n/intl_fa.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(faArb)
      );

      final keys = ['fa_1', 'fa_2'];
      generateLocalizationClass(keys);
      
      final outputFile = File('lib/generated/localizations.dart');
      final content = outputFile.readAsStringSync();
      
      // Check proper escaping
      expect(content, contains("\'fa_1\': \'سلام \"دنیا\" با \\\'نقل قول\\\'\'"));
      expect(content, contains(r"\'fa_2\': \'خط جدید\\nو تب\\t\'"));
    } finally {
      Directory.current = originalDir.path;
      
      // Clean up
      final libDir = Directory('lib/generated');
      if (libDir.existsSync()) {
        libDir.deleteSync(recursive: true);
      }
      
      final l10nDir = Directory('l10n');
      if (l10nDir.existsSync()) {
        l10nDir.deleteSync(recursive: true);
      }
    }
  });
}