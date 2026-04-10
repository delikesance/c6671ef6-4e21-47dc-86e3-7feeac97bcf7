import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/utils/trad/en.dart';
import 'package:bot_creator/utils/trad/fr.dart';

void main() {
  final enArb = toArb(appStringsEn, 'en', isTemplate: true);
  final frArb = toArb(appStringsFr, 'fr', isTemplate: false);

  Directory('lib/l10n').createSync(recursive: true);
  File(
    'lib/l10n/app_en.arb',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(enArb)}\n');
  File(
    'lib/l10n/app_fr.arb',
  ).writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(frArb)}\n');

}

Map<String, dynamic> toArb(
  Map<String, String> translations,
  String locale, {
  required bool isTemplate,
}) {
  final arb = <String, dynamic>{'@@locale': locale};

  for (final entry in translations.entries) {
    arb[entry.key] = entry.value;

    if (isTemplate) {
      final placeholders =
          RegExp(
            r'\{(\w+)\}',
          ).allMatches(entry.value).map((m) => m.group(1)!).toSet();
      if (placeholders.isNotEmpty) {
        arb['@${entry.key}'] = {
          'placeholders': {
            for (final name in placeholders) name: {'type': 'String'},
          },
        };
      }
    }
  }

  return arb;
}
