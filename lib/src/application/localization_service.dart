import 'dart:io';
import 'dart:convert';
import '../domain/models/extraction_state.dart';
import '../domain/models/ui_vocabulary.dart';
import '../infrastructure/extractor.dart';
import '../infrastructure/file_generator.dart';
import '../infrastructure/source_replacer.dart';
import '../analyzer/ui_vocabulary_analyzer.dart';
import '../utils/string_utils.dart';

class LocalizationService {
  final ExtractionState state;
  final FileGenerator fileGenerator;
  final SourceReplacer sourceReplacer;
  UiVocabulary? _vocabulary;

  LocalizationService._internal(this.state, this.fileGenerator, this.sourceReplacer);

  factory LocalizationService() {
    final state = ExtractionState();
    return LocalizationService._internal(
      state,
      FileGenerator(state),
      SourceReplacer(),
    );
  }

  LocalizationService.withState(this.state)
      : fileGenerator = FileGenerator(state),
        sourceReplacer = SourceReplacer();
        
  Future<void> analyzeUiVocabulary(String projectPath) async {
    final analyzer = UiVocabularyAnalyzer();
    _vocabulary = await analyzer.analyze(projectPath);
    
    print('\n--- Analysis Results ---');
    print('\nUI Indicators:');
    print(_vocabulary!.uiIndicators.toList()..sort());
    
    print('\nText Widgets:');
    print(_vocabulary!.textWidgets.toList()..sort());
    
    print('\nText Parameters:');
    print(_vocabulary!.textParameters.toList()..sort());
    print('\n------------------------\n');
  }

  Future<void> runExtraction(String projectPath) async {
    print('📦 Step 1: Extracting Persian strings from source code...');

    if (_vocabulary == null) {
      await analyzeUiVocabulary(projectPath);
    }
    
    final extractor = Extractor(state, _vocabulary!);

    final libDir = Directory('$projectPath/lib');
    if (!libDir.existsSync()) {
      print('📁 No lib/ directory found at $projectPath/lib, skipping extraction from files.');
    } else {
      final files = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      print('📁 Found ${files.length} Dart files in lib/');

      _loadExistingArb();

      for (final file in files) {
        try {
          print('\n🔍 Processing: ${file.path}');
          extractor.extractFromFile(file);
        } catch (e) {
          print('❌ Error processing ${file.path}: $e');
          try {
            print('🔄 Trying fallback method for ${file.path}');
            extractor.extractWithFallback(file);
          } catch (e2) {
            print('❌ Fallback also failed for ${file.path}: $e2');
          }
        }
      }
    }

    fileGenerator.writeFaArb();
    fileGenerator.writeStringLocations();
    fileGenerator.writeDynamicReport();
    fileGenerator.writeProcessingReport();

    print('\n' + '=' * 50);
    print('📊 EXTRACTION SUMMARY:');
    print('✅ Processed ${state.processedFiles.length} files');
    print('⏭️ Skipped ${state.skippedFiles.length} files');
    print('✅ Extracted ${state.extractedStrings.length} Persian strings');
    print('📍 Recorded ${state.stringLocations.length} string locations');
    print('⚠️ Found ${state.dynamicStrings.length} dynamic strings');
  }

  void _loadExistingArb() {
    final arbFile = File('l10n/intl_fa.arb');
    if (arbFile.existsSync()) {
      try {
        final content = arbFile.readAsStringSync();
        final existingArb = json.decode(content) as Map<String, dynamic>;

        for (final entry in existingArb.entries) {
          state.extractedStrings[entry.key] = entry.value.toString();
        }

        for (final key in existingArb.keys) {
          if (key.startsWith('fa_')) {
            try {
              final num = int.parse(key.substring(3));
              if (num > state.counter) state.counter = num;
            } catch (e) {
              // Skip non-numeric keys
            }
          }
        }

        print('📂 Loaded ${existingArb.length} existing strings from ARB file');
      } catch (e) {
        print('⚠️ Could not load existing ARB file: $e');
      }
    }
  }

  void buildArbFiles() {
    fileGenerator.buildArbFiles();
  }

  void replaceStringsInSource() {
    sourceReplacer.replaceStringsInSource();
  }

  Future<void> appendToExistingArb(String projectPath) async {
    print('➕ Appending new strings to existing ARB files...');
    await runExtraction(projectPath);
    print('\n📊 APPEND SUMMARY:');
    print('   Added ${state.extractedStrings.length} strings to ARB files');
  }

  void analyzeResults() {
    print('📊 Analyzing extraction results...');

    final faArbFile = File('l10n/intl_fa.arb');
    if (!faArbFile.existsSync()) {
      print('❌ No ARB file found. Run extraction first.');
      return;
    }

    final faContent = faArbFile.readAsStringSync();
    final faMap = json.decode(faContent) as Map<String, dynamic>;

    print('📈 Statistics:');
    print('   Total extracted strings: ${faMap.length}');

    int totalChars = 0;
    int maxLength = 0;
    String longestString = '';

    for (final entry in faMap.entries) {
      final length = (entry.value as String).length;
      totalChars += length;

      if (length > maxLength) {
        maxLength = length;
        longestString = entry.value;
      }
    }

    final avgLength = faMap.isEmpty ? 0 : totalChars / faMap.length;

    print('   Average string length: ${avgLength.toStringAsFixed(1)} characters');
    print('   Longest string: $maxLength characters');
    print('   Longest text: "${truncateText(longestString, 50)}"');

    print('\n🎯 Sample of extracted strings (first 5):');
    final sampleKeys = faMap.keys.take(5).toList();
    for (final key in sampleKeys) {
      final value = faMap[key] as String;
      print('   • $key: "${truncateText(value, 30)}"');
    }

    final locationsFile = File('l10n/string_locations.json');
    if (locationsFile.existsSync()) {
      final locationsContent = locationsFile.readAsStringSync();
      final locationsData = json.decode(locationsContent) as Map<String, dynamic>;

      int totalLocations = 0;
      for (final entry in locationsData.entries) {
        final data = entry.value as Map<String, dynamic>;
        final locations = data['locations'] as List<dynamic>;
        totalLocations += locations.length;
      }

      print('\n📍 Location data:');
      print('   Total string locations: $totalLocations');
      final avgLocations = faMap.isEmpty ? 0 : totalLocations / faMap.length;
      print('   Average locations per string: ${avgLocations.toStringAsFixed(2)}');
    }

    _analyzeConcatenationPatterns();
  }

  void _analyzeConcatenationPatterns() {
    print('\n🔗 Concatenation Analysis:');

    int simpleConcatenations = 0;
    int complexConcatenations = 0;
    final patternExamples = <String>[];

    for (final dynamicString in state.dynamicStrings) {
      if (dynamicString.contains('COMPLEX EDGE CASE')) {
        complexConcatenations++;

        final lines = dynamicString.split('\n');
        for (final line in lines) {
          if (line.contains('Expression:')) {
            final expr = line.replaceAll('Expression:', '').trim();
            if (expr.length < 100) {
              patternExamples.add(expr);
            }
            break;
          }
        }
      } else if (dynamicString.contains('MIXED CONCATENATION')) {
        simpleConcatenations++;
      }
    }

    print('   Simple mixed concatenations: $simpleConcatenations');
    print('   Complex edge cases: $complexConcatenations');

    if (patternExamples.isNotEmpty) {
      print('\n   Example edge cases found:');
      for (int i = 0; i < (3 < patternExamples.length ? 3 : patternExamples.length); i++) {
        print('     • ${patternExamples[i]}');
      }
      print('\n   💡 These edge cases need manual refactoring for proper localization');
    }
  }

  Future<void> runAll(String projectPath) async {
    print('🚀 Running complete workflow...\n');
    await runExtraction(projectPath);
    print('\n' + '=' * 50 + '\n');
    analyzeResults();
    print('\n' + '=' * 50 + '\n');
    buildArbFiles();
    print('\n' + '=' * 50 + '\n');
    replaceStringsInSource();
    print('\n' + '=' * 50);
    print('✅ Complete workflow finished!');
  }
}
