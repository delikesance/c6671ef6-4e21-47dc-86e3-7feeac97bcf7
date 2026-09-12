// Garde-fou BLOQUANT de l'i18n. Contrairement au test historique (qui alimente
// l'outil avec des fichiers factices), ce test scanne pour de vrai `lib/` et
// échoue dès qu'une chaîne d'UI codée en dur apparaît hors allow-list validée
// ou hors dette connue — c'est ce scan qui aurait attrapé le « Discard »
// anglais affiché dans une UI française.
//
// Trois verrous :
//   1. scan réel de `lib/` : `allowListedPatterns` ∪ `knownUiLeaks` doit tout
//      couvrir (sinon échec avec les lignes fautives, max 20) ;
//   2. parité i18n : les 6 .arb partagent exactement les mêmes clés et aucune
//      valeur vide (une clé absente retombe silencieusement sur l'anglais) ;
//   3. anti-régression ciblée : plus aucun littéral sur `confirmLabel:` /
//      `cancelLabel:` de command.create.dart, et `common_discard` y est utilisé.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tools/hardcoded_string_guard.dart';

const List<String> _locales = <String>['en', 'fr', 'de', 'ja', 'pt', 'tr'];

const String _arbDir = 'lib/core/i18n/l10n';

const String _commandCreatePath =
    'lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart';

/// Repère tout littéral placé après `confirmLabel:` / `cancelLabel:`
/// (c'est la forme exacte de la fuite « Discard »).
final RegExp _dialogLabelLiteral = RegExp(
  r"""(?:confirmLabel|cancelLabel)\s*:\s*(?:const\s+)?['"]""",
);

/// Repère les paramètres du dialogue d'abandon, quel que soit le reste de la
/// ligne (sert à filtrer les findings du scan).
final RegExp _dialogLabelParam = RegExp(r'\b(?:confirmLabel|cancelLabel)\s*:');

void main() {
  test('scan réel de lib/ : aucune chaîne hors allow-list ni dette connue', () {
    final findings = findHardcodedStringFindings(rootPath: 'lib');

    expect(
      findings,
      isNotEmpty,
      reason: 'Scan vide : « lib/ » est introuvable ou le garde-fou est cassé.',
    );

    final allowListed = findings
        .where(isAllowListedFinding)
        .toList(growable: false);
    final known = findings
        .where(
          (finding) =>
              !isAllowListedFinding(finding) && isKnownUiLeakPath(finding.path),
        )
        .toList(growable: false);
    final uncovered = findings
        .where(
          (finding) =>
              !isAllowListedFinding(finding) &&
              !isKnownUiLeakPath(finding.path),
        )
        .toList(growable: false);

    final knownPerFile = <String, int>{};
    for (final finding in known) {
      knownPerFile.update(
        finding.path,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    final debtLines =
        (knownPerFile.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .map(
              (entry) => '  ${entry.value.toString().padLeft(3)}  ${entry.key}',
            )
            .join('\n');
    // ignore: avoid_print
    print(
      'Garde-fou i18n : ${findings.length} findings — allow-list '
      '${allowListed.length}, dettes connues ${known.length}, hors couverture '
      '${uncovered.length}\nDette restante par fichier :\n$debtLines',
    );

    expect(
      uncovered,
      isEmpty,
      reason:
          'Chaînes d\'UI hors allow-list ET hors knownUiLeaks (max 20) :\n'
          '${uncovered.take(20).map((finding) => '${finding.path}:${finding.line}: ${finding.content}').join('\n')}',
    );
  });

  test('parité i18n : les 6 .arb ont les mêmes clés et aucune valeur vide', () {
    final keysByLocale = <String, Set<String>>{};
    final emptyValues = <String, List<String>>{};

    for (final locale in _locales) {
      final data =
          jsonDecode(File('$_arbDir/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      final keys = <String>{};
      final empties = <String>[];
      for (final entry in data.entries) {
        // Ignore les métadonnées (`@clé`, `@@locale`) : seules les entrées
        // qui portent réellement une traduction comptent.
        if (entry.key.startsWith('@')) continue;
        keys.add(entry.key);
        final value = entry.value;
        if (value is! String || value.trim().isEmpty) {
          empties.add(entry.key);
        }
      }
      keysByLocale[locale] = keys;
      emptyValues[locale] = empties;
    }

    final reference = keysByLocale['en']!;
    expect(
      reference.length,
      greaterThan(2000),
      reason:
          'app_en.arb semble tronqué ou illisible '
          '(${reference.length} clés trouvées).',
    );

    for (final locale in _locales) {
      expect(
        emptyValues[locale],
        isEmpty,
        reason:
            'Valeurs vides dans app_$locale.arb : '
            '${emptyValues[locale]!.take(20).join(', ')}',
      );
    }

    for (final locale in _locales.where((l) => l != 'en')) {
      final keys = keysByLocale[locale]!;
      final missing = reference.difference(keys).toList()..sort();
      final extra = keys.difference(reference).toList()..sort();
      expect(
        missing,
        isEmpty,
        reason:
            'Clés absentes de app_$locale.arb (fallback anglais '
            'silencieux) : ${missing.take(20).join(', ')}',
      );
      expect(
        extra,
        isEmpty,
        reason:
            'Clés en trop dans app_$locale.arb : '
            '${extra.take(20).join(', ')}',
      );
    }

    // ignore: avoid_print
    print(
      'Parité i18n OK : ${reference.length} clés identiques dans les '
      '${_locales.length} locales.',
    );
  });

  test('verrou « Discard » : command.create.dart n\'a plus de littéral sur '
      'confirmLabel:/cancelLabel:', () {
    final offenders = findHardcodedStringFindings(rootPath: 'lib')
        .where(
          (finding) =>
              finding.path.endsWith(_commandCreatePath) &&
              _dialogLabelParam.hasMatch(finding.content),
        )
        .toList(growable: false);

    expect(
      offenders,
      isEmpty,
      reason:
          'Un littéral est réapparu sur le dialogue d\'abandon :\n'
          '${offenders.map((finding) => '${finding.path}:${finding.line}: ${finding.content}').join('\n')}',
    );

    final source = File(_commandCreatePath).readAsStringSync();
    expect(
      source.contains('confirmLabel: context.tr.common_discard'),
      isTrue,
      reason:
          'command.create.dart doit passer la clé localisée common_discard '
          '(présente dans les 6 locales) au dialogue d\'abandon.',
    );
    expect(
      _dialogLabelLiteral.hasMatch(source),
      isFalse,
      reason:
          'Un littéral est réapparu après confirmLabel:/cancelLabel: dans '
          'command.create.dart — c\'est exactement la fuite « Discard ».',
    );
  });
}
