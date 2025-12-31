import 'dart:convert';

/// Checks if text contains Persian/Arabic characters
bool hasPersianArabicCharacters(String text) {
  return RegExp(
          r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]')
      .hasMatch(text);
}

/// Truncates text for display
String truncateText(String text, [int maxLength = 60]) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 3)}...';
}

/// Escapes JSON strings
String escapeJson(String s) {
  return s
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll('\t', r'\t');
}

/// Escapes Dart strings
String escapeDartString(String text) {
  return text
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}

/// Converts key to method name
String keyToMethodName(String key) {
  return key.replaceAll('_', '');
}