// « ANNONCE VUE » N'EST PAS « RÉCOMPENSE CRÉDITÉE ».
//
// Le défaut : le flux d'annonce récompensée affichait son message de succès À
// L'INSTANT où la publicité se terminait, alors que le crédit des minutes est
// validé APRÈS, côté manager (callback SSV), et pouvait ne jamais arriver. Le
// message de l'appelant peut annoncer « minutes ajoutées » : l'afficher sans
// attendre faisait dire à l'écran quelque chose qui n'était pas encore vrai, et
// l'échec du crédit ne laissait qu'une ligne de journal.
//
// POURQUOI CE TEST LIT LA SOURCE : le flux vit dans `_maybeOfferRewardedAd`,
// méthode privée d'un `State` de 3 000 lignes qui dépend d'annonces réelles, du
// client Manager et de la navigation — il n'existe aucun harnais capable de le
// dérouler, et un test de widget écrit pour ça serait long et instable. Ce qui
// compte ici est un ORDRE d'instructions, et cet ordre se vérifie sur le texte
// (même approche que l'anti-régression ciblée du garde-fou i18n).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _homePagePath = 'lib/features/home/presentation/home_page.dart';
const String _arbDir = 'lib/core/i18n/l10n';
const List<String> _locales = <String>['en', 'fr', 'de', 'ja', 'pt', 'tr'];

const List<String> _creditKeys = <String>[
  'rewarded_start_credit_pending',
  'rewarded_start_credit_confirmed',
  'rewarded_start_credit_unconfirmed',
];

/// Le corps de `_maybeOfferRewardedAd`, de sa signature à la méthode suivante.
String _rewardedAdMethod() {
  final source = File(_homePagePath).readAsStringSync();
  final start = source.indexOf('Future<bool> _maybeOfferRewardedAd(');
  expect(start, isNonNegative, reason: 'La méthode a été renommée ou déplacée.');
  final end = source.indexOf('\n  Future<', start + 1);
  expect(end, greaterThan(start), reason: 'Fin de méthode introuvable.');
  return source.substring(start, end);
}

void main() {
  test('l\'attente du crédit est ANNONCÉE avant d\'être lancée', () {
    final body = _rewardedAdMethod();
    final pendingIndex = body.indexOf('rewarded_start_credit_pending');
    final waitIndex = body.indexOf('_waitForMainApiRewardCredit(');

    expect(pendingIndex, isNonNegative, reason: 'Le message d\'attente a disparu.');
    expect(waitIndex, isNonNegative);
    expect(
      pendingIndex,
      lessThan(waitIndex),
      reason:
          'Le message d\'attente doit être affiché AVANT de lancer la vérification du crédit',
    );
  });

  test('le message de succès n\'est affiché QUE si le crédit est constaté', () {
    final body = _rewardedAdMethod();
    final waitIndex = body.indexOf('_waitForMainApiRewardCredit(');
    // `lastIndexOf` : la première occurrence de `successMessage` est le PARAMÈTRE
    // de la méthode ; c'est la dernière — dans la clôture — qui décide.
    final successIndex = body.lastIndexOf('successMessage');
    final creditedBranch = RegExp(r'rewardCredited\s*\?\s*\(?successMessage');

    expect(
      successIndex,
      greaterThan(waitIndex),
      reason:
          'Le message de succès ne doit jamais être affiché indépendamment du crédit',
    );
    expect(
      creditedBranch.hasMatch(body),
      isTrue,
      reason:
          'Le message de succès doit être conditionné par `rewardCredited` '
          '(« annonce vue » n\'est pas « récompense créditée »)',
    );
  });

  test('le crédit non constaté est DIT à l\'écran, pas seulement journalisé', () {
    final body = _rewardedAdMethod();

    expect(
      body.contains('rewarded_start_credit_unconfirmed'),
      isTrue,
      reason:
          'Un crédit qui n\'arrive pas doit être dit à l\'utilisateur, pas seulement journalisé',
    );
    expect(
      body.contains("appendBotDebugLog"),
      isTrue,
      reason: 'Le journal reste nécessaire pour diagnostiquer côté support',
    );
  });

  test('les trois messages existent dans les six langues', () {
    for (final locale in _locales) {
      final data =
          jsonDecode(File('$_arbDir/app_$locale.arb').readAsStringSync())
              as Map<String, dynamic>;
      for (final key in _creditKeys) {
        expect(
          (data[key] ?? '').toString().trim(),
          isNotEmpty,
          reason: '$key manquant ou vide dans app_$locale.arb',
        );
      }
    }
  });
}
