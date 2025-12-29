class ConcatenationAnalysis {
  final List<String> staticParts = [];
  final List<String> dynamicParts = [];
  bool isAllStatic = true;
  bool hasPersianStaticParts = false;

  @override
  String toString() {
    return 'ConcatenationAnalysis(staticParts: $staticParts, dynamicParts: $dynamicParts, hasPersian: $hasPersianStaticParts)';
  }
}