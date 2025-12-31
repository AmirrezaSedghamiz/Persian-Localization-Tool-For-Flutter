import 'package:persian_localizer/persian_localizer.dart';
import 'package:test/test.dart';

void main() {
  group('hasPersianArabicCharacters', () {
    test('should detect Persian text', () {
      expect(hasPersianArabicCharacters('سلام'), isTrue);
      expect(hasPersianArabicCharacters('سلام دنیا'), isTrue);
      expect(hasPersianArabicCharacters('متن فارسی'), isTrue);
    });

    test('should detect Arabic text', () {
      expect(hasPersianArabicCharacters('السلام'), isTrue);
      expect(hasPersianArabicCharacters('مرحبا'), isTrue);
    });

    test('should detect mixed text', () {
      expect(hasPersianArabicCharacters('Hello سلام'), isTrue);
      expect(hasPersianArabicCharacters('123 فارسی 456'), isTrue);
      expect(hasPersianArabicCharacters('Text with فارسی inside'), isTrue);
    });

    test('should not detect non-Persian text', () {
      expect(hasPersianArabicCharacters('Hello World'), isFalse);
      expect(hasPersianArabicCharacters('123456'), isFalse);
      expect(hasPersianArabicCharacters(''), isFalse);
      expect(hasPersianArabicCharacters('   '), isFalse);
      expect(hasPersianArabicCharacters('!@#\$%^&*()'), isFalse);
    });
  });

  group('truncateText', () {
    test('should not truncate short text', () {
      expect(truncateText('سلام', 10), equals('سلام'));
      expect(truncateText('Hello World', 20), equals('Hello World'));
    });

    test('should truncate long text', () {
      const longText = 'این یک متن بسیار طولانی است که باید خلاصه شود';
      expect(truncateText(longText, 20), equals('این یک متن بسیار طو...'));
      expect(truncateText(longText, 30), equals('این یک متن بسیار طولانی است که با...'));
    });

    test('should handle edge cases', () {
      expect(truncateText('', 10), equals(''));
      expect(truncateText('a', 1), equals('a'));
      expect(truncateText('ab', 1), equals('...'));
    });
  });

  group('escapeJson', () {
    test('should escape JSON special characters', () {
      expect(escapeJson('سلام "دنیا"'), equals('سلام \\"دنیا\\"'));
      expect(escapeJson('خط جدید\nو تب\t'), equals('خط جدید\\nو تب\\t'));
      expect(escapeJson('بک‌اسلش\\'), equals('بک‌اسلش\\\\'));
      expect(escapeJson('بازگشت\r'), equals('بازگشت\\r'));
    });

    test('should handle empty string', () {
      expect(escapeJson(''), equals(''));
    });

    test('should handle string without special characters', () {
      expect(escapeJson('سلام دنیا'), equals('سلام دنیا'));
    });
  });

  group('escapeDartString', () {
    test('should escape Dart string special characters', () {
      expect(escapeDartString("سلام 'دنیا'"), equals("سلام \\'دنیا\\'"));
      expect(escapeDartString('خط جدید\nو تب\t'), equals('خط جدید\\nو تب\\t'));
      expect(escapeDartString('بک‌اسلش\\'), equals('بک‌اسلش\\\\'));
      expect(escapeDartString('بازگشت\r'), equals('بازگشت\\r'));
    });

    test('should handle empty string', () {
      expect(escapeDartString(''), equals(''));
    });
  });

  group('keyToMethodName', () {
    test('should convert key to method name', () {
      expect(keyToMethodName('fa_1'), equals('fa1'));
      expect(keyToMethodName('fa_123'), equals('fa123'));
      expect(keyToMethodName('fa_hello_world'), equals('fahelloworld'));
    });

    test('should handle edge cases', () {
      expect(keyToMethodName(''), equals(''));
      expect(keyToMethodName('fa'), equals('fa'));
      expect(keyToMethodName('_'), equals(''));
    });
  });
}