import 'dart:convert';
import 'dart:io';

/// Generates lib/utils/trad/en.dart and fr.dart from the ARB source files.
///
/// Run after editing any ARB file:
///   dart run tools/generate_trad_from_arb.dart
void main() {
  _generate('lib/l10n/app_en.arb', 'lib/utils/trad/en.dart', 'appStringsEn');
  _generate('lib/l10n/app_fr.arb', 'lib/utils/trad/fr.dart', 'appStringsFr');
}

void _generate(String arbPath, String dartPath, String varName) {
  final arb =
      jsonDecode(File(arbPath).readAsStringSync()) as Map<String, dynamic>;
  final entries = arb.entries.where((e) => !e.key.startsWith('@')).toList();

  final buf = StringBuffer();
  buf.writeln(
    '// GENERATED FROM ${arbPath.split('/').last} — DO NOT EDIT BY HAND',
  );
  buf.writeln('// Run: dart run tools/generate_trad_from_arb.dart');
  buf.writeln();
  buf.writeln('const Map<String, String> $varName = {');

  for (final e in entries) {
    final value = e.value as String;
    // Escape for Dart single-quoted string literals
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t')
        .replaceAll(r'$', r'\$');
    buf.writeln("  '${e.key}': '$escaped',");
  }

  buf.writeln('};');

  File(dartPath).writeAsStringSync(buf.toString());
}
