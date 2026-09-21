// La version de l'application et les mises à jour appartiennent aux réglages GÉNÉRAUX,
// pas aux réglages d'un bot.
//
// Constat : les deux cartes (« Version » : version applicative + version du runner ;
// « Mises à jour » : version installée + vérification) étaient rendues dans les réglages
// d'un bot (`bot_sub_pages/settings.dart`). Or elles ne parlent pas du bot : on y arrivait
// par un bot, et le même contenu réapparaissait pour chaque bot, alors qu'il décrit
// l'APPLICATION.
//
// Ce que ce garde verrouille :
//   * les réglages d'un bot ne portent plus ni version ni mise à jour (ni la donnée, ni la
//     machinerie de vérification) ;
//   * les réglages généraux utilisent la brique partagée ;
//   * il n'existe qu'UN SEUL endroit qui rend ces cartes — sans quoi les textes et les
//     comportements divergeraient de nouveau, ce qui est exactement ce qui s'était produit.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _reglagesDuBot =
    'lib/features/bot_editor/presentation/screens/bot_sub_pages/settings.dart';
const String _reglagesGeneraux =
    'lib/features/settings/presentation/settings_page.dart';
const String _briquePartagee =
    'lib/features/settings/presentation/widgets/app_version_and_updates_card.dart';

void main() {
  test('les réglages d\'un bot ne portent plus la version ni les mises à jour', () {
    final source = File(_reglagesDuBot).readAsStringSync();

    for (final marqueur in <String>[
      'settings_version_title',
      'settings_app_update_title',
      'settings_app_update_installed_version',
      'PackageInfo',
      'AppUpdateService',
    ]) {
      expect(
        source.contains(marqueur),
        isFalse,
        reason:
            '$_reglagesDuBot parle encore d\'une information GLOBALE (« $marqueur ») : la version '
            'de l\'application et la recherche de mise à jour décrivent le poste, pas le bot',
      );
    }
  });

  test('les réglages généraux montent la brique partagée', () {
    final source = File(_reglagesGeneraux).readAsStringSync();

    expect(
      source.contains('AppVersionAndUpdatesCard'),
      isTrue,
      reason: '$_reglagesGeneraux doit afficher la version de l\'application et les mises à jour',
    );
  });

  test('un seul endroit rend ces cartes', () {
    final rendus = <String>[];
    for (final entite in Directory('lib').listSync(recursive: true)) {
      if (entite is! File || !entite.path.endsWith('.dart')) continue;
      if (entite.path.contains('/core/i18n/l10n/')) continue; // traductions générées
      if (entite.readAsStringSync().contains('settings_app_update_title')) {
        rendus.add(entite.path);
      }
    }

    expect(
      rendus,
      <String>[_briquePartagee],
      reason:
          'les cartes de version et de mise à jour doivent avoir UN propriétaire : ailleurs, les '
          'textes et les comportements divergeraient (c\'est ce qui s\'était produit)',
    );
  });
}
