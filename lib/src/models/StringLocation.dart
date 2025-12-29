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

  Map<String, dynamic> toJson() => {
    'file': filePath,
    'offset': offset,
    'end': end,
    'original': originalText,
    'context': context,
  };
}