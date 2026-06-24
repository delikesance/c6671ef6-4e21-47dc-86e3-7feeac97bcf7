/// Sanitizes Dart strings that may contain invalid UTF-16 surrogate pairs.
///
/// Dart's String type is UTF-16 based, and the Flutter text rendering engine
/// validates UTF-16 well-formedness at the TextSpan level. Strings from external
/// sources (Discord API, JSON deserialization, databases) can contain lone
/// (unpaired) surrogates, which cause an immediate crash:
///   "Invalid argument(s): string is not well-formed UTF-16"
///
/// Use `.sanitizedUtf16` on any string that enters the application from an
/// external boundary before passing it to a Text widget.
extension StringSanitizer on String {
  /// Returns a copy of this string with lone surrogates (unpaired UTF-16
  /// high/low surrogates) replaced by the Unicode replacement character U+FFFD.
  ///
  /// Proper surrogate pairs (high + low) are left untouched.
  ///
  /// This is idempotent — sanitizing an already-clean string returns itself.
  String get sanitizedUtf16 => replaceAllMapped(
        // Match either:
        //   - A high surrogate NOT followed by a low surrogate (lone high)
        //   - A low surrogate NOT preceded by a high surrogate (lone low)
        RegExp(r'[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?<![\uD800-\uDBFF])[\uDC00-\uDFFF]'),
        (_) => '\uFFFD',
      );
}
