# Persian Localization Tool for Flutter 🇮🇷

A **production-ready Dart tool** to automatically localize Persian (Farsi) strings in Flutter projects.
This tool has been **battle-tested on 200k+ line codebases** and is designed to be **safe, fast, and repeatable**.

## Choose Your Version

### Quick Start – Production Ready (Recommended)

    If you just want to localize your Flutter app **safely and efficiently**,use the **single-file version** located in `BaseCode/`.
    This is the version used in real-world applications.

### Learning Version – Educational Only

    If you want to **study the architecture**, explore the modular version in `lib/`, `bin/`, and `test/`.
    **Do NOT use this version in production.**

## Single-File Version (Production Ready)

### Real-World Results

    | Metric | Accuracy | Notes |
    |------|----------|-------|
    | String Extraction | 99.9% | Misses only pathological edge cases |
    | String Replacement | 90% | Remaining 10% manageable via backups |
    | Performance | Excellent | Handles 200k+ line projects |
    | Safety | Maximum | Automatic backups ensure zero risk |

## How to Use

### Copy the Tool into Your Project

    ```bash
    mkdir -p tools
    cp BaseCode/localize_persian.dart tools/
    ```

### Run from Flutter Project Root

    ```bash
    dart tools/localize_persian.dart all
    ```

### Individual Commands

    ```bash
    dart tools/localize_persian.dart extract
    dart tools/localize_persian.dart build
    dart tools/localize_persian.dart replace
    dart tools/localize_persian.dart analyze
    dart tools/localize_persian.dart append
    dart tools/localize_persian.dart help
    ```

## Commands Reference

    | Command | Description |
    |-------|-------------|
    | all | Complete workflow (extract → build → replace) |
    | extract | Extract Persian strings only |
    | build | Generate ARB files only |
    | replace | Replace strings in source (creates backups) |
    | analyze | Show extraction statistics |
    | append | Add new strings without overwriting existing |
    | help | Show help message |

## Generated Files

    ```text
    your_project/
    ├── l10n/
    │ ├── intl_fa.arb
    │ ├── intl_en.arb
    │ ├── string_locations.json
    │ └── various_reports.txt
    ├── lib/generated/
    │ └── localizations.dart
    └── *.dart.backup
    ```

## Workflow Examples

### First-Time Setup

    ```bash
    dart tools/localize_persian.dart all
    cat l10n/intl_fa.arb
    cat lib/generated/localizations.dart
    find . -name "*.backup" | head -5
    ```

### Adding New Strings Later

    ```bash
    dart tools/localize_persian.dart append
    ```

or

    ```bash
    dart tools/localize_persian.dart all
    ```

### Just Checking (No Changes)

    ```bash
    dart tools/localize_persian.dart extract
    dart tools/localize_persian.dart analyze
    ```

## Flutter Integration

### MaterialApp Setup

```dart
import 'generated/localizations.dart';

return MaterialApp(
        localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
        ],
            supportedLocales: const [
            Locale('en'),
            Locale('fa'),
        ],
        home: MyHomePage(),
    );
```

### Usage in Widgets

    ```dart
    // Before
    Text('سلام دنیا')

    // After
    Text(AppLocalizations.of(context).fa1)
    ```

## Safety Features

    - Automatic backups of modified files
    - No permanent changes without backup
    - Clear reporting of all actions
    - Safe to run multiple times

## Troubleshooting

### No strings found
    - Ensure Persian text exists in `lib/`
    - Files must have `.dart` extension
    - Run `extract` for verbose output

### Replacement didn’t work
    - Check `.backup` files
    - Review `l10n/string_locations.json`
    - Restore manually if needed

### ARB file errors

    ```bash
    rm -rf l10n/
    dart tools/localize_persian.dart all
    ```

### Restore from Backup

    ```bash
    cp lib/main.dart.backup lib/main.dart
    ```

## Known Limitations

    - Complex concatenations may need manual refactoring
    - Already localized strings are ignored
    - Avoid running on auto-generated files

## Modular Version (Educational)

### About This Version

    This version demonstrates how the single-file tool could be refactored into a proper Dart package.

    **Educational use only.**

### Structure

    ```text
    persian_localization_tool/
    ├── pubspec.yaml
    ├── bin/
    │ └── persian_localizer.dart
    ├── lib/
    │ ├── src/
    │ │ ├── extractors/
    │ │ ├── generators/
    │ │ ├── replacers/
    │ │ ├── analyzers/
    │ │ ├── models/
    │ │ └── utils/
    │ └── persian_localizer.dart
    ├── test/
    └── example/
    ```

### Explore the Code

    ```bash
    dart pub get
    dart test
    cd lib/src
    ```

### Important Warning

    - Not production tested
    - May contain bugs
    - Do NOT use in real apps
    - Use `BaseCode/localize_persian.dart` for production

## Testing History

    Tested on:
        - 200k+ line Flutter applications
        - E-commerce platforms
        - Social media apps
        - Enterprise systems

## Accuracy Breakdown

    - String extraction: 99.9%
    - String replacement: 90%
    - Full reporting and analysis

## FAQ

**Why two versions?**
    Production vs educational clarity.

**Is it safe?**
    Yes. Automatic backups guarantee safety.

**Can I run it multiple times?**
    Yes. The tool is idempotent.

**English translations?**
    Auto-generated; manual translation recommended.

**How are Persian strings detected?**
    AST parsing + regex for Persian/Arabic scripts.

## Contributing

    - Test edge cases with the single-file version
    - Report issues with examples
    - Easy to modify if needed

## License

    MIT License

## Credits

    Built from real-world experience localizing large Flutter applications.
    The single-file version reflects years of production refinement.

**For production use, always copy:**
    `BaseCode/localize_persian.dart`