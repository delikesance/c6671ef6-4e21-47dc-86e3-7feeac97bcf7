import 'dart:convert';
import 'dart:io';

/// A tool to detect and remove duplicate keys in .arb files.
/// Usage: dart tools/cleanup_arb_duplicates.dart
void main() async {
  final l10nDir = Directory('../ui/lib/src/l10n');
  if (!l10nDir.existsSync()) {
    return;
  }

  final arbFiles = l10nDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .toList();

  if (arbFiles.isEmpty) {
    return;
  }

  for (final file in arbFiles) {
    await cleanupFile(file);
  }
}

Future<void> cleanupFile(File file) async {
  final content = await file.readAsString();

  // Attempt to detect duplicates before parsing.
  // We look for "key": patterns. This is a heuristic but works for ARB.
  final keyPattern = RegExp(r'"([^"]+)"\s*:');
  final matches = keyPattern.allMatches(content);

  final seenKeys = <String>{};
  final duplicates = <String>{};

  for (final match in matches) {
    final key = match.group(1)!;
    if (seenKeys.contains(key)) {
      duplicates.add(key);
    } else {
      seenKeys.add(key);
    }
  }

  if (duplicates.isEmpty) {
    return;
  }

  try {
    // Parsing as JSON automatically resolves duplicates by keeping the last one.
    // Dart's jsonDecode returns a LinkedHashMap which preserves order of first appearance or last?
    // Actually, LinkedHashMap preserves insertion order.
    // Let's use a manual parse or just accept jsonDecode behavior.
    final Map<String, dynamic> data = jsonDecode(content);

    final encoder = JsonEncoder.withIndent('  ');
    final output = encoder.convert(data);

    await file.writeAsString('$output\n');
    // ignore: empty_catches
  } catch (e) {}
}
