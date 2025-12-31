import 'dart:io';
import 'dart:convert';

import 'package:persian_localizer/persian_localizer.dart';

/// Text parameter sets for widget detection
final textParameters = {
  'text',
  'label',
  'labelText',
  'hintText',
  'title',
  'content',
  'message',
  'buttonText',
  'tooltip',
  'subtitle',
  'heading',
  'description',
  'caption',
  'errorText',
  'helperText',
  'prefixText',
  'suffixText',
  'counterText',
  'semanticLabel',
  'header',
  'footer',
  'placeholder',
  'leading',
  'trailing',
  'actions',
  'child',
  'applicationName',
  'applicationVersion',
  'icon',
  'onPressed',
};

/// Text widgets that contain text
final textWidgets = {
  'Text',
  'TextSpan',
  'InputDecoration',
  'AppBar',
  'SnackBar',
  'AlertDialog',
  'SimpleDialog',
  'ListTile',
  'CheckboxListTile',
  'RadioListTile',
  'SwitchListTile',
  'FloatingActionButton',
  'ElevatedButton',
  'TextButton',
  'OutlinedButton',
  'IconButton',
  'PopupMenuItem',
  'DropdownMenuItem',
  'Tooltip',
  'DataColumn',
  'Card',
  'ExpansionTile',
  'Chip',
  'FilterChip',
  'ChoiceChip',
  'ActionChip',
  'NavigationRailDestination',
  'NavigationDrawerDestination',
  'BottomNavigationBarItem',
  'Tab',
  'Step',
  'AboutListTile',
  'RichText',
  'Drawer',
  'BottomSheet',
  'CupertinoAlertDialog',
  'CupertinoActionSheet',
  'MaterialBanner',
  'AboutDialog',
  'LicensePage',
  'PageView',
  'TabBarView',
  'GridView',
  'ListView',
  'Column',
  'Row',
  'Stack',
  'Wrap',
  'Flow',
  'Table',
  'DataTable',
  'PaginatedDataTable',
  'Scrollbar',
  'SingleChildScrollView',
  'NestedScrollView',
  'CustomScrollView',
  'SliverAppBar',
  'SliverList',
  'SliverGrid',
  'SliverToBoxAdapter',
  'SliverFillRemaining',
  'SliverFillViewport',
  'SliverFixedExtentList',
  'SliverOpacity',
  'SliverPadding',
  'SliverPersistentHeader',
  'SliverPrototypeExtentList',
  'SliverSafeArea',
  'SliverAnimatedOpacity',
  'TextField',
  'CupertinoDialogAction',
  'SnackBarAction',
  'MaterialBanner',
  'AboutDialog',
  'SimpleDialogOption',
  'CupertinoButton',
  'CupertinoTabBar',
  'Icon',
  'InputDecoration',
  'AnimatedCrossFade',
  'BottomNavigationBar',
  'TabBar',
};

/// UI indicators that suggest a file might contain text
final uiIndicators = {
  'Widget',
  'BuildContext',
  'StatefulWidget',
  'StatelessWidget',
  'MaterialApp',
  'CupertinoApp',
  'Scaffold',
  'Container',
  'Padding',
  'Margin',
  'Center',
  'Align',
  'Positioned',
  'Expanded',
  'Flexible',
  'Spacer',
  'SizedBox',
  'AspectRatio',
  'ConstrainedBox',
  'LimitedBox',
  'FractionallySizedBox',
  'IntrinsicHeight',
  'IntrinsicWidth',
  'OverflowBox',
  'SizedOverflowBox',
  'Transform',
  'RotatedBox',
  'Opacity',
  'Offstage',
  'Visibility',
  'IgnorePointer',
  'AbsorbPointer',
  'MouseRegion',
  'Listener',
  'GestureDetector',
  'RawGestureDetector',
  'Dismissible',
  'Draggable',
  'LongPressDraggable',
  'DragTarget',
  'AnimatedBuilder',
  'AnimatedContainer',
  'AnimatedCrossFade',
  'AnimatedDefaultTextStyle',
  'AnimatedOpacity',
  'AnimatedPhysicalModel',
  'AnimatedPositioned',
  'AnimatedSize',
  'AnimatedSwitcher',
  'DecoratedBox',
  'DecoratedBoxTransition',
  'FractionalTranslation',
  'RelativePositionedTransition',
  'RotationTransition',
  'ScaleTransition',
  'SizeTransition',
  'SlideTransition',
  'PositionedTransition',
  'FadeTransition',
  'AlignTransition',
  'DefaultTextStyleTransition',
  'AnimatedModalBarrier',
  'ModalBarrier',
  'BackdropFilter',
  'ClipRect',
  'ClipRRect',
  'ClipOval',
  'ClipPath',
  'CustomPaint',
  'CustomSingleChildLayout',
  'CustomMultiChildLayout',
  'LayoutBuilder',
  'Builder',
  'StatefulBuilder',
  'StreamBuilder',
  'FutureBuilder',
  'ValueListenableBuilder',
  'AnimatedBuilder',
};

/// Creates l10n directory
void createL10nDirectory() {
  Directory('l10n').createSync(recursive: true);
}

/// Writes string locations report
void writeStringLocationsReport(
    Map<String, String> extractedStrings,
    Map<String, List<StringLocation>> stringLocations) {
  final buffer = StringBuffer();
  buffer.writeln('STRING LOCATIONS REPORT');
  buffer.writeln('=' * 50);

  for (final entry in stringLocations.entries) {
    final key = entry.key;
    final value = extractedStrings[key] ?? '';
    final locations = entry.value;

    buffer.writeln('\n🔑 Key: $key');
    buffer.writeln('📝 Text: "$value"');
    buffer.writeln('📍 Locations (${locations.length}):');

    for (final location in locations) {
      buffer.writeln(
          '  • ${location.filePath}:${location.offset} (${location.context})');
      buffer.writeln('    Original: ${location.originalText}');
    }
  }

  final jsonData = <String, dynamic>{};
  for (final entry in stringLocations.entries) {
    jsonData[entry.key] = {
      'text': extractedStrings[entry.key],
      'locations': entry.value
          .map((loc) => {
                'file': loc.filePath,
                'offset': loc.offset,
                'end': loc.end,
                'original': loc.originalText,
                'context': loc.context,
              })
          .toList(),
    };
  }

  final jsonFile = File('l10n/string_locations.json');
  jsonFile.writeAsStringSync(JsonEncoder.withIndent('  ').convert(jsonData));

  File('l10n/string_locations.txt').writeAsStringSync(buffer.toString());
}

/// Writes dynamic strings report
void writeDynamicStringsReport(List<String> dynamicStrings) {
  if (dynamicStrings.isEmpty) {
    print('   📊 No dynamic strings found');
    return;
  }

  final buffer = StringBuffer();
  buffer.writeln('DYNAMIC STRINGS REPORT');
  buffer.writeln('=' * 50);
  buffer.writeln(
      '\nFound ${dynamicStrings.length} dynamic/complex string expressions:\n');

  for (int i = 0; i < dynamicStrings.length; i++) {
    buffer.writeln('${i + 1}. ${dynamicStrings[i]}');
    buffer.writeln('─' * 40);
  }

  File('l10n/dynamic_strings.txt').writeAsStringSync(buffer.toString());
  print('   📊 Wrote dynamic strings report: l10n/dynamic_strings.txt');
}

/// Writes processing report
void writeProcessingReportFile(
    List<String> processedFiles, List<String> skippedFiles) {
  final report = StringBuffer();
  report.writeln('PROCESSING REPORT');
  report.writeln('=' * 50);
  report.writeln('\nPROCESSED FILES (${processedFiles.length}):');
  for (final file in processedFiles) {
    report.writeln('  • $file');
  }

  report.writeln('\nSKIPPED FILES (${skippedFiles.length}):');
  for (final file in skippedFiles) {
    report.writeln('  • $file');
  }

  File('l10n/processing_report.txt').writeAsStringSync(report.toString());
}

/// Cleans up generated files
void cleanGeneratedFiles() {
  print('🧹 Cleaning up generated files...');

  final filesToClean = [
    'l10n/intl_fa.arb',
    'l10n/intl_en.arb',
    'l10n/string_locations.json',
    'l10n/string_locations.txt',
    'l10n/dynamic_strings.txt',
    'l10n/processing_report.txt',
    'lib/generated/localizations.dart',
  ];

  int removedCount = 0;

  for (final filePath in filesToClean) {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
      removedCount++;
      print('   🗑️  Removed: $filePath');
    }
  }

  print('✅ Removed $removedCount files');
}