import 'dart:convert';
import 'dart:io';

class StringLocator {
  final RegExp _faRegex = RegExp(
    r'['
    r'\u0600-\u06FF'
    r'\u0750-\u077F'
    r'\u08A0-\u08FF'
    r'\uFB50-\uFDFF'
    r'\uFE70-\uFEFF'
    r']+',
  );

  bool _isExcludedPath(String path) {
    final p = path.replaceAll('\\', '/');
    return p.contains('/gen/') || p.contains('/generated/');
  }

  bool _isTagListFile(String path) {
    final p = path.replaceAll('\\', '/');
    return p.endsWith('/TagList.dart');
  }

  String _csvEscape(String s) {
    final needsQuotes =
        s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r');
    if (!needsQuotes) return s;
    return '"${s.replaceAll('"', '""')}"';
  }

  bool _matchIsCommentedOut(String line, int matchStartIndex) {
    final commentIndex = line.indexOf('//');
    if (commentIndex == -1) return false;
    return commentIndex <= matchStartIndex;
  }

  Future<void> runLocator() async {
    final libDir = Directory('lib');
    if (!await libDir.exists()) {
      stderr.writeln('❌ Could not find ./lib directory. Run this from project root.');
      exitCode = 2;
      return;
    }

    final csvOut = File('persian_strings_report.csv');
    final txtOut = File('persian_strings_report.txt');

    final csvSink = csvOut.openWrite();
    final txtSink = txtOut.openWrite();

    csvSink.writeln('file,line,column,match,line_text');

    int filesScanned = 0;
    int hits = 0;
    int skippedCommentHits = 0;
    int skippedTagListFiles = 0;

    await for (final entity in libDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;

      final path = entity.path;

      if (!path.endsWith('.dart')) continue;
      if (_isExcludedPath(path)) continue;

      if (_isTagListFile(path)) {
        skippedTagListFiles++;
        continue;
      }

      filesScanned++;

      late final List<String> lines;
      try {
        final content = await entity.readAsString(encoding: utf8);
        lines = const LineSplitter().convert(content);
      } catch (e) {
        stderr.writeln('⚠️ Failed to read $path: $e');
        continue;
      }

      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];

        final matches = _faRegex.allMatches(line);
        if (matches.isEmpty) continue;

        for (final m in matches) {
          final matchText = m.group(0) ?? '';
          final lineNumber = i + 1;
          final columnNumber = m.start + 1;

          if (_matchIsCommentedOut(line, m.start)) {
            skippedCommentHits++;
            continue;
          }

          hits++;

          txtSink.writeln('FILE: $path');
          txtSink.writeln('  Line $lineNumber, Col $columnNumber');
          txtSink.writeln('  Match: $matchText');
          txtSink.writeln('  Text : $line');
          txtSink.writeln('');

          csvSink.writeln(
            '${_csvEscape(path)},'
            '$lineNumber,'
            '$columnNumber,'
            '${_csvEscape(matchText)},'
            '${_csvEscape(line)}',
          );
        }
      }
    }

    await csvSink.flush();
    await csvSink.close();

    await txtSink.flush();
    await txtSink.close();

    stdout.writeln('✅ Done.');
    stdout.writeln('   Files scanned: $filesScanned');
    stdout.writeln('   Matches found: $hits');
    stdout.writeln('   Skipped TagList.dart files: $skippedTagListFiles');
    stdout.writeln('   Skipped commented matches (// before match): $skippedCommentHits');
    stdout.writeln('   Output: persian_strings_report.csv, persian_strings_report.txt');
  }
}
