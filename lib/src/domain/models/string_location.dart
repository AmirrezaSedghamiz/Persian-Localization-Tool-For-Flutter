class StringLocation {
  final String filePath;
  final int offset;
  final int end;
  final String originalText;
  final String context;

  StringLocation({
    required this.filePath,
    required this.offset,
    required this.end,
    required this.originalText,
    required this.context,
  });

  @override
  String toString() {
    return '$filePath:$offset-$end ($context)';
  }
}
