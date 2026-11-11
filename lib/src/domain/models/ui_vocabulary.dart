class UiVocabulary {
  final Set<String> textParameters;
  final Set<String> textWidgets;
  final Set<String> uiIndicators;

  const UiVocabulary({
    required this.textParameters,
    required this.textWidgets,
    required this.uiIndicators,
  });

  factory UiVocabulary.empty() {
    return const UiVocabulary(
      textParameters: {},
      textWidgets: {},
      uiIndicators: {},
    );
  }
}
