import 'dart:convert';
import 'dart:io';

void main() async {
  final l10nDir = Directory('lib/core/i18n/l10n');
  final templateFile = File('lib/core/i18n/l10n/app_en.arb');
  
  stdout.writeln('📖 Loading English template as the master reference...');
  final templateData = jsonDecode(await templateFile.readAsString()) as Map<String, dynamic>;

  // 1. Build the Master Registry from app_en.arb
  final masterKeys = templateData.keys.where((k) => !k.startsWith('@') && k != '@@locale').toList()..sort();
  final Map<String, dynamic> masterMetadata = {};
  final Map<String, String> masterStrings = {};

  for (final key in masterKeys) {
    masterStrings[key] = templateData[key];
    final metaKey = '@$key';
    final meta = templateData.containsKey(metaKey) ? Map<String, dynamic>.from(templateData[metaKey]) : {};
    
    // Ensure description is present (fallback to English text)
    meta['description'] ??= templateData[key];
    
    // Ensure placeholders are typed
    final placeholders = RegExp(r'\{(\w+)\}').allMatches(templateData[key]).map((m) => m.group(1)!).toList();
    if (placeholders.isNotEmpty) {
      final Map<String, dynamic> pMap = meta['placeholders'] ?? {};
      for (final p in placeholders) {
        pMap[p] ??= {'type': 'String'};
      }
      meta['placeholders'] = pMap;
    }
    masterMetadata[key] = meta;
  }

  // 2. Sync all files in the directory
  final arbFiles = l10nDir.listSync().whereType<File>().where((f) => f.path.endsWith('.arb'));

  for (final file in arbFiles) {
    final fileName = file.path.split('/').last;
    stdout.writeln('🔄 Synchronizing $fileName...');

    final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final Map<String, dynamic> newData = {};
    
    // Preserve locale if it exists
    if (data.containsKey('@@locale')) {
      newData['@@locale'] = data['@@locale'];
    }

    int addedKeys = 0;

    for (final key in masterKeys) {
      // Use existing translation, or fallback to English if missing
      if (data.containsKey(key)) {
        newData[key] = data[key];
      } else {
        newData[key] = masterStrings[key];
        addedKeys++;
      }

      // Always use the master metadata structure to ensure linter happiness
      newData['@$key'] = masterMetadata[key];
    }

    final encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString('${encoder.convert(newData)}\n');
    
    if (addedKeys > 0) {
      stdout.writeln('   ✅ Added $addedKeys missing keys from English template.');
    }
  }

  stdout.writeln('\n🚀 ALL LOCALES ARE NOW 100% SYNCHRONIZED!');
  stdout.writeln('Every file has the same keys, same order, and full metadata.');
}
