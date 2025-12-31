import 'dart:io';
import 'package:persian_localizer/persian_localizer.dart';
import 'package:persian_localizer/persian_localizer.dart' as globals;
import 'package:test/test.dart';


void main() {
  setUp(() {
    globals.extractedStrings.clear();
    globals.counter = 0;
  });

  test('should extract Persian strings using regex', () {
    final content = '''
class Test {
  String greeting = 'سلام دنیا';
  String farewell = "خداحافظ";
  String mixed = 'Hello سلام World';
}
''';

    extractStringsWithRegex(content, 'test.dart');
    
    expect(globals.extractedStrings.length, equals(3));
    expect(globals.extractedStrings.values, contains('سلام دنیا'));
    expect(globals.extractedStrings.values, contains('خداحافظ'));
    expect(globals.extractedStrings.values, contains('Hello سلام World'));
  });

  test('should handle escaped quotes in regex extraction', () {
    final content = '''
class Test {
  String text = 'It\\'s \\"سلام\\" world';
}
''';

    extractStringsWithRegex(content, 'test.dart');
    
    expect(globals.extractedStrings.length, equals(1));
  });

  test('should not extract English-only strings', () {
    final content = '''
class Test {
  String english1 = 'Hello World';
  String english2 = "Welcome";
  String number = '123';
}
''';

    extractStringsWithRegex(content, 'test.dart');
    
    expect(globals.extractedStrings.length, equals(0));
  });

  test('should handle newlines in strings', () {
    final content = '''
class Test {
  String multiLine = 'سلام\\nدنیا\\nخوش آمدید';
}
''';

    extractStringsWithRegex(content, 'test.dart');
    
    expect(globals.extractedStrings.length, equals(1));
  });

  test('should handle complex mixed strings', () {
    final content = '''
class Test {
  String complex = 'Hello 123 سلام 456 World خداحافظ';
}
''';

    extractStringsWithRegex(content, 'test.dart');
    
    expect(globals.extractedStrings.length, equals(1));
    expect(globals.extractedStrings.values.first, equals('Hello 123 سلام 456 World خداحافظ'));
  });
}