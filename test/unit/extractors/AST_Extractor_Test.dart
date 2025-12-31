import 'dart:io';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:test/test.dart';


void main() {
  setUp(() {
    // Reset global state before each test
    globals.extractedStrings.clear();
    globals.stringLocations.clear();
    globals.dynamicStrings.clear();
    globals.counter = 0;
  });

  test('should extract simple Persian string literals', () {
    final testFile = File('test_fixtures/simple_string.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('سلام دنیا');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('سلام دنیا'));
    expect(globals.extractedStrings.keys.first, startsWith('fa_'));
  });

  test('should extract multiple Persian strings', () {
    final testFile = File('test_fixtures/multiple_strings.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('سلام'),
        Text('خوش آمدید'),
        Text('خداحافظ'),
      ],
    );
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(3));
    expect(globals.extractedStrings.values, contains('سلام'));
    expect(globals.extractedStrings.values, contains('خوش آمدید'));
    expect(globals.extractedStrings.values, contains('خداحافظ'));
  });

  test('should extract Persian strings from TextField hintText', () {
    final testFile = File('test_fixtures/textfield.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'نام خود را وارد کنید',
        labelText: 'نام',
      ),
    );
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(2));
    expect(globals.extractedStrings.values, contains('نام خود را وارد کنید'));
    expect(globals.extractedStrings.values, contains('نام'));
  });

  test('should extract Persian strings from AppBar', () {
    final testFile = File('test_fixtures/appbar.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('صفحه اصلی'),
      ),
      body: Container(),
    );
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('صفحه اصلی'));
  });

  test('should extract Persian strings from string interpolation', () {
    final testFile = File('test_fixtures/interpolation.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  final String name = 'علی';
  
  @override
  Widget build(BuildContext context) {
    return Text('سلام \$name');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('سلام '));
  });

  test('should extract Persian strings from concatenation', () {
    final testFile = File('test_fixtures/concatenation.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('سلام' + ' ' + 'دنیا');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('سلام دنیا'));
  });

  test('should handle mixed concatenation with variables', () {
    final testFile = File('test_fixtures/mixed_concatenation.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  final String userName = 'علی';
  
  @override
  Widget build(BuildContext context) {
    return Text('سلام ' + userName + '! خوش آمدید.');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(2));
    expect(globals.extractedStrings.values, contains('سلام '));
    expect(globals.extractedStrings.values, contains('! خوش آمدید.'));
    expect(globals.dynamicStrings.length, greaterThan(0));
  });

  test('should not extract non-Persian strings', () {
    final testFile = File('test_fixtures/english_strings.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Hello'),
        Text('Welcome'),
        Text('Goodbye'),
      ],
    );
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(0));
  });

  test('should handle empty strings', () {
    final testFile = File('test_fixtures/empty_strings.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(0));
  });

  test('should handle escaped characters', () {
    final testFile = File('test_fixtures/escaped_chars.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text('سلام\\nدنیا');
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('سلام\nدنیا'));
  });

  test('should handle Text.rich constructor', () {
    final testFile = File('test_fixtures/text_rich.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'سلام ',
        children: [
          TextSpan(text: 'دنیا'),
        ],
      ),
    );
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(2));
    expect(globals.extractedStrings.values, contains('سلام '));
    expect(globals.extractedStrings.values, contains('دنیا'));
  });

  test('should handle variable declarations with Persian strings', () {
    final testFile = File('test_fixtures/variable_declaration.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  final String greeting = 'سلام دنیا';
  static const String farewell = 'خداحافظ';
  
  @override
  Widget build(BuildContext context) {
    return Text(greeting);
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(2));
    expect(globals.extractedStrings.values, contains('سلام دنیا'));
    expect(globals.extractedStrings.values, contains('خداحافظ'));
  });

  test('should handle return statements with Persian strings', () {
    final testFile = File('test_fixtures/return_statement.dart');
    final content = '''
import 'package:flutter/material.dart';

class TestWidget extends StatelessWidget {
  String getGreeting() {
    return 'سلام دنیا';
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(getGreeting());
  }
}
''';

    testFile.writeAsStringSync(content);
    
    extractStringsWithAST(testFile, content);
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('سلام دنیا'));
  });

  tearDown(() {
    // Clean up test files
    final testDir = Directory('test_fixtures');
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });
}