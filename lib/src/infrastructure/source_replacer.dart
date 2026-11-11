import 'dart:io';
import 'dart:convert';
import '../domain/models/replacement.dart';
import '../utils/string_utils.dart';

class SourceReplacer {
  void replaceStringsInSource() {
    print('🔧 Replacing Persian strings in source code...');

    final locationsFile = File('l10n/string_locations.json');
    if (!locationsFile.existsSync()) {
      print(
          '❌ Error: l10n/string_locations.json not found. Run extraction first.');
      return;
    }

    final locationsContent = locationsFile.readAsStringSync();
    final locationsData = json.decode(locationsContent) as Map<String, dynamic>;

    final filesToProcess = <String, List<Replacement>>{};

    for (final entry in locationsData.entries) {
      final key = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final locations = data['locations'] as List<dynamic>;

      for (final loc in locations) {
        final location = loc as Map<String, dynamic>;
        final file = location['file'] as String;
        final offset = location['offset'] as int;
        final end = location['end'] as int;
        final original = location['original'] as String;
        final context = location['context'] as String;

        filesToProcess.putIfAbsent(file, () => []).add(
              Replacement(
                key: key,
                offset: offset,
                end: end,
                original: original,
                replacement:
                    "AppLocalizations.of(context).${keyToMethodName(key)}",
                context: context,
              ),
            );
      }
    }

    int totalReplacements = 0;
    int totalFiles = 0;
    final List<String> modifiedFiles = [];

    for (final entry in filesToProcess.entries) {
      final filePath = entry.key;
      final replacements = entry.value;

      replacements.sort((a, b) => b.offset.compareTo(a.offset));

      try {
        final file = File(filePath);
        if (!file.existsSync()) {
          print('⚠️  File not found: $filePath');
          continue;
        }

        var content = file.readAsStringSync();
        bool fileModified = false;

        for (final replacement in replacements) {
          final before = content.substring(0, replacement.offset);
          final after = content.substring(replacement.end);

          final currentText =
              content.substring(replacement.offset, replacement.end);
          if (currentText != replacement.original) {
            print('⚠️  Text mismatch in $filePath at ${replacement.offset}');
            print('   Expected: ${replacement.original}');
            print('   Found: $currentText');
            continue;
          }

          content = before + replacement.replacement + after;
          fileModified = true;
          totalReplacements++;

          print('   ✅ Replaced: ${replacement.context} → ${replacement.key}');
        }

        if (fileModified) {
          final backupFile = File('$filePath.backup');
          if (!backupFile.existsSync()) {
            file.copySync(backupFile.path);
          }

          file.writeAsStringSync(content);
          totalFiles++;
          modifiedFiles.add(filePath);

          print('📄 Updated: $filePath (${replacements.length} replacements)');
        }
      } catch (e) {
        print('❌ Error processing $filePath: $e');
      }
    }

    print('\n📊 REPLACEMENT SUMMARY:');
    print('   Total files modified: $totalFiles');
    print('   Total replacements: $totalReplacements');

    if (modifiedFiles.isNotEmpty) {
      print('\n📝 Modified files:');
      for (final file in modifiedFiles) {
        print('   • $file');
      }
    }

    print('\n💡 Note: Original files are backed up with .backup extension');
    print('🔄 To revert changes, restore from backup files');
  }
}
