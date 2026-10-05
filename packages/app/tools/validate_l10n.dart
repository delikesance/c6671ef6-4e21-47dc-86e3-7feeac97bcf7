import 'dart:convert';
import 'dart:io';

void main() {
  final templateFile = File('../ui/lib/src/l10n/app_en.arb');
  if (!templateFile.existsSync()) {
    stdout.writeln('Template not found');
    return;
  }

  final templateData =
      jsonDecode(templateFile.readAsStringSync()) as Map<String, dynamic>;
  final templateKeys = templateData.keys
      .where((k) => !k.startsWith('@') && k != '@@locale')
      .toList();

  final dir = Directory('../ui/lib/src/l10n');
  final arbFiles = dir.listSync().whereType<File>().where(
    (f) => f.path.endsWith('.arb') && !f.path.contains('app_en.arb'),
  );

  for (final file in arbFiles) {
    stdout.writeln('Checking ${file.path}...');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    for (final key in templateKeys) {
      if (!data.containsKey(key)) {
        stdout.writeln('  ❌ Missing key: $key');
        continue;
      }

      final templateMessage = templateData[key] as String;
      final message = data[key] as String;

      // Find placeholders in template
      final templatePlaceholders = RegExp(
        r'\{(\w+)\}',
      ).allMatches(templateMessage).map((m) => m.group(1)).toSet();
      final placeholders = RegExp(
        r'\{(\w+)\}',
      ).allMatches(message).map((m) => m.group(1)).toSet();

      if (templatePlaceholders.length != placeholders.length ||
          !templatePlaceholders.containsAll(placeholders)) {
        stdout.writeln(
          '  ⚠️ Placeholder mismatch for $key: expected $templatePlaceholders, got $placeholders',
        );
      }

      // Check metadata block if present in template
      final metadataKey = '@$key';
      if (templateData.containsKey(metadataKey)) {
        if (!data.containsKey(metadataKey)) {
          stdout.writeln('  ℹ️ Missing metadata block: $metadataKey');
        } else {
          // Check if placeholder names in metadata match the message
          final metadata = data[metadataKey] as Map<String, dynamic>;
          if (metadata.containsKey('placeholders')) {
            final metaPlaceholders =
                (metadata['placeholders'] as Map<String, dynamic>).keys.toSet();
            if (!placeholders.containsAll(metaPlaceholders)) {
              stdout.writeln(
                '  🔥 Metadata placeholder mismatch for $key: message has $placeholders, meta has $metaPlaceholders',
              );
            }
            if (!metaPlaceholders.containsAll(placeholders)) {
              stdout.writeln(
                '  🔥 Message placeholder mismatch for $key: message has $placeholders, meta has $metaPlaceholders',
              );
            }
          }
        }
      }
    }
  }
}
