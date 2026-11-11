import '../../application/localization_service.dart';

class CliRunner {
  Future<void> run(List<String> args) async {
    print('''
╔══════════════════════════════════════════════╗
║    Persian String Localization Tool          ║
╚══════════════════════════════════════════════╝
''');

    if (args.isEmpty || args[0] == 'help' || args[0] == '--help' || args[0] == '-h') {
      _printUsage();
      return;
    }

    final command = args[0];
    String projectPath = '.';
    for (int i = 1; i < args.length; i++) {
      if (args[i] == '--path' && i + 1 < args.length) {
        projectPath = args[i + 1];
        break;
      }
    }

    final service = LocalizationService();

    switch (command) {
      case 'extract':
        await service.runExtraction(projectPath);
        break;
      case 'build':
        service.buildArbFiles();
        break;
      case 'replace':
        service.replaceStringsInSource();
        break;
      case 'analyze':
        service.analyzeResults();
        break;
      case 'append':
        await service.appendToExistingArb(projectPath);
        break;
      case 'all':
        await service.runAll(projectPath);
        break;
      case 'analyze-ui':
        await service.analyzeUiVocabulary(projectPath);
        break;
      case 'help':
        _printUsage();
        break;
      default:
        print('❌ Unknown command: $command');
        print('💡 Use "dart localize_persian.dart help" for usage instructions.');
    }
  }

  void _printUsage() {
    print('''
Usage:
  dart localize_persian.dart extract     - Extract Persian strings from source
  dart localize_persian.dart build       - Build ARB files from extracted strings
  dart localize_persian.dart replace     - Replace strings in source code
  dart localize_persian.dart analyze     - Analyze extraction results
  dart localize_persian.dart analyze-ui  - Dynamically analyze and discover UI vocabulary
  dart localize_persian.dart all         - Run all steps (extract → build → replace)
  dart localize_persian.dart append      - Append new strings to existing ARB files
  dart localize_persian.dart help        - Show this help message

Options:
  --path <path>  - Specify target project path (default: current directory)

Examples:
  dart localize_persian.dart all --path <path>         - Complete workflow on target project
  dart localize_persian.dart extract --path <path>     - Extract strings from target project
  dart localize_persian.dart analyze-ui --path <path>  - Inspect discovered UI vocabulary
  dart localize_persian.dart replace                   - Replace strings in source
  dart localize_persian.dart append --path <path>      - Add new strings without overwriting
''');
  }
}
