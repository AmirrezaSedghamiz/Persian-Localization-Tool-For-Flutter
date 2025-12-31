import 'dart:io';
import 'dart:convert';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:test/test.dart';

void main() {
  final testDir = Directory('test_replace');

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

  test('should replace simple Persian strings in source code', () {
    // Create test string locations file
    final locationsData = {
      'fa_1': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/simple.dart',
            'offset': 100,
            'end': 108,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          }
        ],
      },
    };

    Directory('l10n').createSync(recursive: true);
    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(locationsData)
    );

    // Create test source file
    final sourceContent = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('سلام دنیا');
  }
}
''';

    // Adjust offset based on actual content
    final adjustedData = {
      'fa_1': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/simple.dart',
            'offset': sourceContent.indexOf("'سلام دنیا'"),
            'end': sourceContent.indexOf("'سلام دنیا'") + "'سلام دنیا'".length,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          }
        ],
      },
    };

    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(adjustedData)
    );

    File('test_replace/simple.dart').writeAsStringSync(sourceContent);

    replaceStrings();

    final updatedContent = File('test_replace/simple.dart').readAsStringSync();
    
    expect(updatedContent, contains("AppLocalizations.of(context).fa1"));
    expect(updatedContent, isNot(contains("'سلام دنیا'")));
    
    // Check backup was created
    final backupFile = File('test_replace/simple.dart.backup');
    expect(backupFile.existsSync(), isTrue);
    expect(backupFile.readAsStringSync(), equals(sourceContent));
  });

  test('should replace multiple occurrences', () {
    final locationsData = {
      'fa_1': {
        'text': 'سلام',
        'locations': [
          {
            'file': 'test_replace/multiple.dart',
            'offset': 100,
            'end': 106,
            'original': "'سلام'",
            'context': 'string literal',
          },
          {
            'file': 'test_replace/multiple.dart',
            'offset': 150,
            'end': 156,
            'original': "'سلام'",
            'context': 'string literal',
          },
        ],
      },
      'fa_2': {
        'text': 'خداحافظ',
        'locations': [
          {
            'file': 'test_replace/multiple.dart',
            'offset': 200,
            'end': 211,
            'original': "'خداحافظ'",
            'context': 'string literal',
          },
        ],
      },
    };

    Directory('l10n').createSync(recursive: true);
    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(locationsData)
    );

    final sourceContent = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('سلام'),
        Text('سلام'),
        Text('خداحافظ'),
      ],
    );
  }
}
''';

    // Adjust offsets
    final adjustedData = {
      'fa_1': {
        'text': 'سلام',
        'locations': [
          {
            'file': 'test_replace/multiple.dart',
            'offset': sourceContent.indexOf("'سلام'", sourceContent.indexOf("Text('سلام')")),
            'end': sourceContent.indexOf("'سلام'", sourceContent.indexOf("Text('سلام')")) + "'سلام'".length,
            'original': "'سلام'",
            'context': 'string literal',
          },
          {
            'file': 'test_replace/multiple.dart',
            'offset': sourceContent.lastIndexOf("'سلام'"),
            'end': sourceContent.lastIndexOf("'سلام'") + "'سلام'".length,
            'original': "'سلام'",
            'context': 'string literal',
          },
        ],
      },
      'fa_2': {
        'text': 'خداحافظ',
        'locations': [
          {
            'file': 'test_replace/multiple.dart',
            'offset': sourceContent.indexOf("'خداحافظ'"),
            'end': sourceContent.indexOf("'خداحافظ'") + "'خداحافظ'".length,
            'original': "'خداحافظ'",
            'context': 'string literal',
          },
        ],
      },
    };

    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(adjustedData)
    );

    File('test_replace/multiple.dart').writeAsStringSync(sourceContent);

    replaceStrings();

    final updatedContent = File('test_replace/multiple.dart').readAsStringSync();
    
    expect(updatedContent, contains("AppLocalizations.of(context).fa1"));
    expect(updatedContent, contains("AppLocalizations.of(context).fa2"));
    expect(updatedContent, isNot(contains("'سلام'")));
    expect(updatedContent, isNot(contains("'خداحافظ'")));
    
    // Count occurrences
    final fa1Count = RegExp(r'AppLocalizations\.of\(context\)\.fa1').allMatches(updatedContent).length;
    expect(fa1Count, equals(2));
  });

  test('should handle text mismatch gracefully', () {
    final locationsData = {
      'fa_1': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/mismatch.dart',
            'offset': 100,
            'end': 108,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          },
        ],
      },
    };

    Directory('l10n').createSync(recursive: true);
    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(locationsData)
    );

    // Create source with different text at that position
    final sourceContent = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('متفاوت');
  }
}
''';

    File('test_replace/mismatch.dart').writeAsStringSync(sourceContent);

    // Should not crash, just print warning
    expect(() => replaceStrings(), returnsNormally);
  });

  test('should handle missing files gracefully', () {
    final locationsData = {
      'fa_1': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/nonexistent.dart',
            'offset': 100,
            'end': 108,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          },
        ],
      },
    };

    Directory('l10n').createSync(recursive: true);
    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(locationsData)
    );

    // Should not crash
    expect(() => replaceStrings(), returnsNormally);
  });

  test('should handle complex replacements with proper ordering', () {
    final locationsData = {
      'fa_1': {
        'text': 'سلام',
        'locations': [
          {
            'file': 'test_replace/ordering.dart',
            'offset': 50,
            'end': 56,
            'original': "'سلام'",
            'context': 'string literal',
          },
        ],
      },
      'fa_2': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/ordering.dart',
            'offset': 100,
            'end': 112,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          },
        ],
      },
    };

    Directory('l10n').createSync(recursive: true);
    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(locationsData)
    );

    final sourceContent = '''
Text('سلام')
Text('سلام دنیا')
''';

    // Adjust offsets
    final firstIndex = sourceContent.indexOf("'سلام'");
    final secondIndex = sourceContent.indexOf("'سلام دنیا'");
    
    final adjustedData = {
      'fa_1': {
        'text': 'سلام',
        'locations': [
          {
            'file': 'test_replace/ordering.dart',
            'offset': firstIndex,
            'end': firstIndex + "'سلام'".length,
            'original': "'سلام'",
            'context': 'string literal',
          },
        ],
      },
      'fa_2': {
        'text': 'سلام دنیا',
        'locations': [
          {
            'file': 'test_replace/ordering.dart',
            'offset': secondIndex,
            'end': secondIndex + "'سلام دنیا'".length,
            'original': "'سلام دنیا'",
            'context': 'string literal',
          },
        ],
      },
    };

    File('l10n/string_locations.json').writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(adjustedData)
    );

    File('test_replace/ordering.dart').writeAsStringSync(sourceContent);

    replaceStrings();

    final updatedContent = File('test_replace/ordering.dart').readAsStringSync();
    
    // Both should be replaced
    expect(updatedContent, contains("AppLocalizations.of(context).fa1"));
    expect(updatedContent, contains("AppLocalizations.of(context).fa2"));
  });
}