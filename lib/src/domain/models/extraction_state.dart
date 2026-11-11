import 'string_location.dart';

class ExtractionState {
  final Map<String, String> extractedStrings = {};
  final Map<String, List<StringLocation>> stringLocations = {};
  final List<String> dynamicStrings = [];
  final List<String> processedFiles = [];
  final List<String> skippedFiles = [];
  int counter = 0;

  void addDynamicString(String source) {
    dynamicStrings.add(source);
  }
}
