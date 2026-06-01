/// Utility for sanitizing text to prevent UTF-16 encoding errors in TextSpan.
class TextSanitizer {
  /// Sanitizes text to ensure it's valid UTF-16.
  /// Replaces invalid UTF-16 characters with the Unicode replacement character.
  static String sanitize(String input) {
    try {
      // Try to encode and decode to catch UTF-16 errors
      final units = input.codeUnits;
      final buffer = StringBuffer();

      for (int i = 0; i < units.length; i++) {
        final codeUnit = units[i];

        // Check for valid UTF-16 encoding
        if (codeUnit < 0xD800 || codeUnit > 0xDFFF) {
          // Single code unit (BMP character)
          buffer.writeCharCode(codeUnit);
        } else if (codeUnit >= 0xD800 && codeUnit <= 0xDBFF) {
          // High surrogate - need low surrogate
          if (i + 1 < units.length) {
            final nextCodeUnit = units[i + 1];
            if (nextCodeUnit >= 0xDC00 && nextCodeUnit <= 0xDFFF) {
              // Valid surrogate pair
              buffer.writeCharCode(codeUnit);
              buffer.writeCharCode(nextCodeUnit);
              i++; // Skip the low surrogate
            } else {
              // Invalid surrogate pair - use replacement character
              buffer.write('\uFFFD');
            }
          } else {
            // Orphan high surrogate - use replacement character
            buffer.write('\uFFFD');
          }
        } else {
          // Orphan low surrogate - use replacement character
          buffer.write('\uFFFD');
        }
      }

      return buffer.toString();
    } catch (e) {
      // If sanitization fails, return empty string to prevent crashes
      return '';
    }
  }
}