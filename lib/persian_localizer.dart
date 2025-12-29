library persian_localizer;

/// Main entry point for using the tool programmatically
class PersianLocalizer {
  /// Extract strings from a directory
  static Future<void> extract({String directory = 'lib'}) async {
    print('Extracting from $directory...');
    // Your extraction logic
  }
  
  /// Replace strings in source files
  static Future<void> replace() async {
    print('Replacing strings...');
    // Your replacement logic
  }
  
  /// Build ARB files
  static Future<void> build() async {
    print('Building ARB files...');
    // Your ARB generation logic
  }
}