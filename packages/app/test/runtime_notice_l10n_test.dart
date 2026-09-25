// POURQUOI ce test existe — et ce qu'il empêche de revenir :
//
// `remote_runtime.dart` et `runner_settings.dart` assemblaient leurs messages
// « impossibles de démarrer » eux-mêmes, en choisissant entre DEUX textes écrits
// en dur (`fr:` / `en:`) selon `PlatformDispatcher.locale` — la langue de
// l'APPAREIL. Deux conséquences, toutes les deux invisibles à la relecture :
//
//   1. l'allemand, le japonais, le portugais et le turc — quatre des six langues
//      livrées — recevaient de l'ANGLAIS au milieu d'une interface traduite ;
//   2. changer de langue DANS l'application ne changeait rien à ces messages,
//      puisque la langue était relue sur l'appareil et non sur le choix de
//      l'utilisateur.
//
// Le correctif n'est pas « ajouter des traductions » : c'est une RAISON typée
// (`RuntimeNotice`) que l'écran, qui a les localisations, traduit. Ce test
// verrouille la conséquence observable : aucune des six langues ne reçoit le
// texte d'une autre.
//
// NON-VACUITÉ : faire rendre à `resolveRuntimeNotice` la valeur anglaise pour
// toutes les langues (le bug d'origine) fait échouer le test.
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/network/runtime_notice.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const locales = <String>['fr', 'en', 'de', 'ja', 'pt', 'tr'];

  Future<Map<String, AppLocalizations>> loadAll() async {
    final result = <String, AppLocalizations>{};
    for (final locale in locales) {
      result[locale] = await AppLocalizations.delegate.load(Locale(locale));
    }
    return result;
  }

  const raisons = <RuntimeNoticeMessage>[
    RuntimeNoticeMessage(RuntimeNotice.localUnsupportedIosSignIn),
    RuntimeNoticeMessage(RuntimeNotice.signInRequired),
    RuntimeNoticeMessage(RuntimeNotice.sessionExpired),
    RuntimeNoticeMessage(RuntimeNotice.localUnsupportedIosConfigure),
    RuntimeNoticeMessage(RuntimeNotice.planLimit),
    RuntimeNoticeMessage(RuntimeNotice.invalidBotId, error: 'boom'),
    RuntimeNoticeMessage(RuntimeNotice.invalidBotIdDetails, detail: 'details'),
    RuntimeNoticeMessage(RuntimeNotice.serversNotReady, error: 'boom'),
    RuntimeNoticeMessage(
      RuntimeNotice.startupInProgress,
      status: 'QUEUED',
      error: 'boom',
    ),
    RuntimeNoticeMessage(RuntimeNotice.startupFailed, error: 'boom'),
    RuntimeNoticeMessage(
      RuntimeNotice.startupFailedWithDetail,
      detail: 'details',
      error: 'boom',
    ),
    RuntimeNoticeMessage(RuntimeNotice.unreachable, error: 'boom'),
    RuntimeNoticeMessage(RuntimeNotice.requestFailed, error: 'boom'),
    RuntimeNoticeMessage(RuntimeNotice.runnerEmbeddedDesync),
  ];

  test(
    'chaque raison de démarrage existe dans les SIX langues, et aucune ne '
    'reçoit le texte d\'une autre',
    () async {
      final l10n = await loadAll();
      final anglais = <RuntimeNotice, String>{};

      for (final message in raisons) {
        final en = resolveRuntimeNotice(l10n['en']!, message);
        expect(
          en.trim(),
          isNotEmpty,
          reason: 'anglais vide pour ${message.notice}',
        );
        anglais[message.notice] = en;

        // Le bug d'origine, exactement : ces quatre langues affichaient l'anglais.
        for (final locale in <String>['de', 'ja', 'pt', 'tr']) {
          final text = resolveRuntimeNotice(l10n[locale]!, message);
          expect(
            text.trim(),
            isNotEmpty,
            reason: '$locale vide pour ${message.notice}',
          );
          expect(
            text,
            isNot(en),
            reason: '$locale reçoit l\'anglais pour ${message.notice}',
          );
        }
      }

      // Chaque raison a son PROPRE texte : deux raisons qui partagent une phrase
      // rendraient le message inutile (l'utilisateur ne saurait pas quoi faire).
      final parTexte = <String, RuntimeNotice>{};
      for (final entry in anglais.entries) {
        final deja = parTexte[entry.value];
        expect(
          deja,
          isNull,
          reason: '${entry.key} et $deja partagent le même message anglais',
        );
        parTexte[entry.value] = entry.key;
      }
    },
  );

  test('les valeurs intercalées apparaissent dans le message affiché', () async {
    final l10n = await loadAll();
    for (final locale in locales) {
      final status = resolveRuntimeNotice(
        l10n[locale]!,
        const RuntimeNoticeMessage(
          RuntimeNotice.startupInProgress,
          status: 'QUEUED',
          error: 'discord_unreachable',
        ),
      );
      expect(status, contains('QUEUED'), reason: '$locale perd le statut');
      expect(
        status,
        contains('discord_unreachable'),
        reason: '$locale perd l\'erreur initiale',
      );
    }
  });

  test(
    'une erreur BRUTE du runner n\'est pas déguisée en phrase traduite',
    () async {
      final l10n = await loadAll();
      const brut = 'ECONNREFUSED 127.0.0.1:3000';
      for (final locale in locales) {
        expect(
          resolveRuntimeNotice(
            l10n[locale]!,
            const RuntimeNoticeMessage(
              RuntimeNotice.runnerEmbeddedRawError,
              error: brut,
            ),
          ),
          brut,
          reason: '$locale réécrit une donnée technique',
        );
      }
    },
  );
}
