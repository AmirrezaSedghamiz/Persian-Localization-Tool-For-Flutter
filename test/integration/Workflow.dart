import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:test/test.dart';

void main() {
  final testProjectDir = Directory('test_integration_project');

  setUp(() {
    if (testProjectDir.existsSync()) {
      testProjectDir.deleteSync(recursive: true);
    }
    testProjectDir.createSync(recursive: true);
    
    // Reset global state
    globals.extractedStrings.clear();
    globals.stringLocations.clear();
    globals.dynamicStrings.clear();
    globals.processedFiles.clear();
    globals.skippedFiles.clear();
    globals.counter = 0;
    
    // Create test project structure
    Directory('${testProjectDir.path}/lib').createSync(recursive: true);
    Directory('${testProjectDir.path}/lib/screens').createSync(recursive: true);
    Directory('${testProjectDir.path}/lib/widgets').createSync(recursive: true);
  });

  tearDown(() {
    if (testProjectDir.existsSync()) {
      testProjectDir.deleteSync(recursive: true);
    }
  });

  test('full workflow: extract → build → replace', () {
    final originalDir = Directory.current;
    Directory.current = testProjectDir.path;

    try {
      // Create test Dart files with Persian strings
      final mainDart = '''
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
''';

      final homeScreenDart = '''
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحه اصلی'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('سلام دنیا'),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: 'نام خود را وارد کنید',
                labelText: 'نام',
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text('ورود'),
            ),
          ],
        ),
      ),
    );
  }
}
''';

      final widgetDart = '''
import 'package:flutter/material.dart';

class GreetingWidget extends StatelessWidget {
  final String userName;
  
  GreetingWidget({required this.userName});
  
  @override
  Widget build(BuildContext context) {
    return Text('سلام ' + userName + '! خوش آمدید.');
  }
}

class FarewellWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('خداحافظ و موفق باشید.');
  }
}
''';

      // Write test files
      File('lib/main.dart').writeAsStringSync(mainDart);
      File('lib/screens/home_screen.dart').writeAsStringSync(homeScreenDart);
      File('lib/widgets/greeting_widget.dart').writeAsStringSync(widgetDart);

      // Step 1: Extract strings
      globals.runExtraction();
      
      // Verify extraction
      expect(globals.extractedStrings.length, greaterThan(0));
      expect(globals.extractedStrings.values, contains('صفحه اصلی'));
      expect(globals.extractedStrings.values, contains('سلام دنیا'));
      expect(globals.extractedStrings.values, contains('نام خود را وارد کنید'));
      expect(globals.extractedStrings.values, contains('نام'));
      expect(globals.extractedStrings.values, contains('ورود'));
      expect(globals.extractedStrings.values, contains('خداحافظ و موفق باشید.'));
      
      // Check for mixed concatenation (should be in dynamicStrings)
      expect(globals.dynamicStrings.length, greaterThan(0));
      
      // Check files were processed
      expect(globals.processedFiles.length, greaterThanOrEqualTo(3));
      
      // Step 2: Build ARB files
      globals.buildArbFiles();
      
      // Verify ARB files were created
      expect(File('l10n/intl_fa.arb').existsSync(), isTrue);
      expect(File('l10n/intl_en.arb').existsSync(), isTrue);
      
      final faArb = json.decode(File('l10n/intl_fa.arb').readAsStringSync()) as Map<String, dynamic>;
      final enArb = json.decode(File('l10n/intl_en.arb').readAsStringSync()) as Map<String, dynamic>;
      
      expect(faArb.length, equals(globals.extractedStrings.length));
      expect(enArb.length, equals(globals.extractedStrings.length));
      
      // Verify all extracted strings are in ARB files
      for (final key in globals.extractedStrings.keys) {
        expect(faArb[key], equals(globals.extractedStrings[key]));
        expect(enArb[key], equals(globals.extractedStrings[key]));
      }
      
      // Step 3: Generate Dart class
      // (This is called within buildArbFiles)
      expect(File('lib/generated/localizations.dart').existsSync(), isTrue);
      
      final localizationContent = File('lib/generated/localizations.dart').readAsStringSync();
      expect(localizationContent, contains('class AppLocalizations'));
      
      // Check that all keys have getter methods
      for (final key in globals.extractedStrings.keys) {
        final methodName = key.replaceAll('_', '');
        expect(localizationContent, contains('String get $methodName =>'));
      }
      
      // Step 4: Replace strings in source
      globals.replaceStringsInSource();
      
      // Verify replacements were made
      final updatedHomeScreen = File('lib/screens/home_screen.dart').readAsStringSync();
      expect(updatedHomeScreen, contains('AppLocalizations.of(context)'));
      expect(updatedHomeScreen, isNot(contains("'صفحه اصلی'")));
      expect(updatedHomeScreen, isNot(contains("'سلام دنیا'")));
      expect(updatedHomeScreen, isNot(contains("'نام خود را وارد کنید'")));
      expect(updatedHomeScreen, isNot(contains("'نام'")));
      expect(updatedHomeScreen, isNot(contains("'ورود'")));
      
      final updatedWidget = File('lib/widgets/greeting_widget.dart').readAsStringSync();
      expect(updatedWidget, contains('AppLocalizations.of(context)'));
      
      // Check backup files were created
      expect(File('lib/screens/home_screen.dart.backup').existsSync(), isTrue);
      expect(File('lib/widgets/greeting_widget.dart.backup').existsSync(), isTrue);
      
      // Step 5: Analyze results
      globals.analyzeResults();
      // (This just prints output, but we can verify it doesn't crash)
      
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle append to existing ARB', () {
    final originalDir = Directory.current;
    Directory.current = testProjectDir.path;

    try {
      // Create existing ARB files
      Directory('l10n').createSync(recursive: true);
      
      final existingFaArb = {
        'fa_1': 'سلام دنیا',
        'fa_2': 'خوش آمدید',
      };
      
      final existingEnArb = {
        'fa_1': 'Hello World',
        'fa_2': 'Welcome',
      };
      
      File('l10n/intl_fa.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(existingFaArb)
      );
      
      File('l10n/intl_en.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(existingEnArb)
      );

      // Set counter to match existing keys
      globals.counter = 2;
      
      // Create new test file with additional strings
      final newDart = '''
import 'package:flutter/material.dart';

class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('صفحه جدید'),
        Text('متن آزمایشی'),
      ],
    );
  }
}
''';

      File('lib/new_screen.dart').writeAsStringSync(newDart);

      // Run append
      globals.appendToExistingArb();
      
      // Verify ARB files were updated
      final updatedFaArb = json.decode(File('l10n/intl_fa.arb').readAsStringSync()) as Map<String, dynamic>;
      final updatedEnArb = json.decode(File('l10n/intl_en.arb').readAsStringSync()) as Map<String, dynamic>;
      
      // Should have 4 strings now (2 existing + 2 new)
      expect(updatedFaArb.length, equals(4));
      expect(updatedEnArb.length, equals(4));
      
      // Verify existing strings are preserved
      expect(updatedFaArb['fa_1'], equals('سلام دنیا'));
      expect(updatedFaArb['fa_2'], equals('خوش آمدید'));
      expect(updatedEnArb['fa_1'], equals('Hello World'));
      expect(updatedEnArb['fa_2'], equals('Welcome'));
      
      // Verify new strings were added
      expect(updatedFaArb.values, contains('صفحه جدید'));
      expect(updatedFaArb.values, contains('متن آزمایشی'));
      expect(updatedEnArb.values, contains('صفحه جدید'));
      expect(updatedEnArb.values, contains('متن آزمایشی'));
      
      // Check that new keys follow the pattern (fa_3, fa_4)
      expect(updatedFaArb.keys, contains('fa_3'));
      expect(updatedFaArb.keys, contains('fa_4'));
      
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle all command (complete workflow)', () {
    final originalDir = Directory.current;
    Directory.current = testProjectDir.path;

    try {
      // Create minimal test project
      final testDart = '''
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('تست کامل'),
      ),
    ),
  ));
}
''';

      File('lib/main.dart').writeAsStringSync(testDart);

      // Run complete workflow
      globals.runPersianLocalizer(['all']);
      
      // Verify results
      expect(File('l10n/intl_fa.arb').existsSync(), isTrue);
      expect(File('l10n/intl_en.arb').existsSync(), isTrue);
      expect(File('lib/generated/localizations.dart').existsSync(), isTrue);
      
      final faArb = json.decode(File('l10n/intl_fa.arb').readAsStringSync()) as Map<String, dynamic>;
      expect(faArb.length, equals(1));
      expect(faArb.values.first, equals('تست کامل'));
      
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle edge cases and errors gracefully', () {
    final originalDir = Directory.current;
    Directory.current = testProjectDir.path;

    try {
      // Test 1: No lib directory
      Directory('lib').deleteSync(recursive: true);
      
      globals.runExtraction();
      expect(globals.extractedStrings.length, equals(0));
      
      // Test 2: Empty lib directory
      Directory('lib').createSync();
      
      globals.runExtraction();
      expect(globals.extractedStrings.length, equals(0));
      
      // Test 3: Non-Dart files in lib
      File('lib/test.txt').writeAsStringSync('سلام');
      
      globals.runExtraction();
      expect(globals.extractedStrings.length, equals(0));
      
      // Test 4: Dart file with syntax errors (should use regex fallback)
      File('lib/broken.dart').writeAsStringSync('''
class Broken {
  String text = 'سلام
}
''');
      
      globals.runExtraction();
      // Should not crash
      
      // Test 5: Build without extraction first
      globals.buildArbFiles();
      // Should print error but not crash
      
    } finally {
      Directory.current = originalDir.path;
    }
  });
}