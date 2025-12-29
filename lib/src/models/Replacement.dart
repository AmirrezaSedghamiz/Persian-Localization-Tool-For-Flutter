class Replacement {
  final String key;
  final int offset;
  final int end;
  final String original;
  final String replacement;
  final String context;

  Replacement({
    required this.key,
    required this.offset,
    required this.end,
    required this.original,
    required this.replacement,
    required this.context,
  });
}