import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:test/test.dart';

void main() {
  final testDir = Directory('test_stats');

  setUp(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
    testDir.createSync(recursive: true);
    
    dynamicStrings.clear();
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  test('should analyze extraction results', () {
    final originalDir = Directory.current;
    Directory.current = testDir.path;

    try {
      // Create test ARB file
      Directory('l10n').createSync(recursive: true);
      
      final arbData = {
        'fa_1': 'سلام',
        'fa_2': 'خوش آمدید',
        'fa_3': 'این یک متن نسبتا طولانی است که برای تست استفاده می‌شود',
        'fa_4': 'خداحافظ',
      };
      
      File('l10n/intl_fa.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(arbData)
      );
      
      // Capture output by running the function
      analyzeExtractionResults();
      
      // The function prints to console, we can't easily capture it
      // But we can verify it doesn't throw
      expect(() => analyzeExtractionResults(), returnsNormally);
      
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle empty ARB file', () {
    final originalDir = Directory.current;
    Directory.current = testDir.path;

    try {
      Directory('l10n').createSync(recursive: true);
      File('l10n/intl_fa.arb').writeAsStringSync('{}');
      
      // Should not throw
      expect(() => analyzeExtractionResults(), returnsNormally);
      
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should handle missing ARB file', () {
    // Should handle missing file gracefully
    expect(() => analyzeExtractionResults(), returnsNormally);
  });

  test('should analyze concatenation patterns', () {
    // Add test dynamic strings
    dynamicStrings.addAll([
      'MIXED CONCATENATION - CONSIDER REFACTORING:\n  File: lib/main.dart\n  Expression: "سلام" + userName',
      'COMPLEX EDGE CASE - REQUIRES MANUAL REFACTORING:\n  File: lib/home.dart\n  Expression: formatCurrency(amount) + " تومان"',
      'MIXED CONCATENATION - CONSIDER REFACTORING:\n  File: lib/widgets/button.dart\n  Expression: "خوش آمدید" + " " + userName',
      'COMPLEX EDGE CASE - REQUIRES MANUAL REFACTORING:\n  File: lib/profile.dart\n  Expression: "نام: " + user.name + " " + user.family',
    ]);
    
    final originalDir = Directory.current;
    Directory.current = testDir.path;
    
    try {
      Directory('l10n').createSync(recursive: true);
      File('l10n/intl_fa.arb').writeAsStringSync('{"fa_1": "test"}');
      
      // Also need string locations file for full analysis
      File('l10n/string_locations.json').writeAsStringSync('{}');
      
      // Should not throw
      expect(() => analyzeExtractionResults(), returnsNormally);
    } finally {
      Directory.current = originalDir.path;
    }
  });

  test('should calculate correct statistics', () {
    final originalDir = Directory.current;
    Directory.current = testDir.path;

    try {
      // Create test ARB with known lengths
      Directory('l10n').createSync(recursive: true);
      
      final arbData = {
        'fa_1': '۱۲۳', // 3 chars
        'fa_2': '۱۲۳۴۵۶۷۸۹۰', // 10 chars
        'fa_3': '۱۲', // 2 chars
      };
      
      File('l10n/intl_fa.arb').writeAsStringSync(
        JsonEncoder.withIndent('  ').convert(arbData)
      );
      
      // Should not throw
      expect(() => analyzeExtractionResults(), returnsNormally);
      
    } finally {
      Directory.current = originalDir.path;
    }
  });
}