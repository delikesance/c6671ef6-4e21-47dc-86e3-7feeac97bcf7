// La pop-up de démarrage doit dire la VÉRITÉ sur chaque chemin, et ne jamais
// proposer une porte qui échouerait.
//
// Contexte : l'association du bot décidait seule où il démarrait — un bot associé au
// manager repartait sur Bot Creator Server (minutes d'hébergement consommées) sans que
// rien ne le dise ; un bot non associé démarrait en local. Le choix est désormais posé
// à chaque démarrage (aucune mémoire : la décision coûte des minutes).
//
// Ce que ce test verrouille :
//   * l'option LOCALE est toujours proposée et toujours en premier (la pop-up ne peut
//     pas se retrouver vide, et le chemin gratuit reste le premier lu) ;
//   * l'option SERVEUR n'apparaît que si elle est réellement possible, et sa raison
//     d'absence est rendue à part — sans elle, l'utilisateur chercherait où elle est
//     passée ;
//   * les quatre raisons sont DISTINCTES : deux causes différentes ne peuvent pas
//     partager une phrase, sinon le diagnostic est faux.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_ui/src/l10n/app_localizations_fr.dart';
import 'package:bot_creator/features/home/logic/bot_start_target.dart';
import 'package:bot_creator/features/home/presentation/widgets/bot_start_target_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final AppLocalizationsFr _tr = AppLocalizationsFr();

/// Cas nominal : poste de travail, compte connecté, minutes disponibles.
BotStartChoices _choix({
  bool supportsManagerRuntime = true,
  bool hasValidSession = true,
  bool premium = false,
  bool cloudDisabledByServer = false,
  int freeMinutesBalance = 120,
}) => resolveBotStartChoices(
  supportsManagerRuntime: supportsManagerRuntime,
  hasValidSession: hasValidSession,
  premium: premium,
  cloudDisabledByServer: cloudDisabledByServer,
  freeMinutesBalance: freeMinutesBalance,
  tr: _tr,
);

Widget _hote(Widget child) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  group('ce qui est proposé', () {
    test('cas nominal : les deux chemins, local en premier', () {
      final choices = _choix();

      expect(choices.options.map((o) => o.target), <BotStartTarget>[
        BotStartTarget.local,
        BotStartTarget.server,
      ]);
      expect(choices.serverUnavailableReason, isNull);
      expect(choices.offersServer, isTrue);
    });

    test('aucun compte connecté : le serveur disparaît, avec sa raison', () {
      final choices = _choix(hasValidSession: false);

      expect(choices.options.map((o) => o.target), <BotStartTarget>[
        BotStartTarget.local,
      ]);
      expect(
        choices.serverUnavailableReason,
        _tr.bot_start_server_reason_no_account,
      );
    });

    test('plus de minutes et pas de formule : le serveur disparaît', () {
      final choices = _choix(freeMinutesBalance: 0);

      expect(choices.offersServer, isFalse);
      expect(
        choices.serverUnavailableReason,
        _tr.bot_start_server_reason_no_minutes,
      );
    });

    test('une minute restante suffit : le serveur reste proposé', () {
      expect(_choix(freeMinutesBalance: 1).offersServer, isTrue);
    });

    test('formule PREMIUM : les minutes ne comptent plus', () {
      expect(_choix(premium: true, freeMinutesBalance: 0).offersServer, isTrue);
    });

    test(
      'formule PREMIUM mais cloud coupé par le serveur : refus expliqué',
      () {
        final choices = _choix(premium: true, cloudDisabledByServer: true);

        expect(choices.offersServer, isFalse);
        expect(
          choices.serverUnavailableReason,
          _tr.bot_start_server_reason_cloud_disabled,
        );
      },
    );

    test('plateforme sans accès au manager (web) : refus expliqué', () {
      final choices = _choix(supportsManagerRuntime: false);

      expect(choices.offersServer, isFalse);
      expect(
        choices.serverUnavailableReason,
        _tr.bot_start_server_reason_platform,
      );
    });

    test(
      'l\'option locale est toujours là, même quand tout le reste manque',
      () {
        final choices = _choix(
          supportsManagerRuntime: false,
          hasValidSession: false,
          freeMinutesBalance: 0,
        );

        expect(choices.options, hasLength(1));
        expect(choices.options.first.target, BotStartTarget.local);
      },
    );

    test('les quatre raisons sont distinctes', () {
      final raisons = <String>{
        _tr.bot_start_server_reason_platform,
        _tr.bot_start_server_reason_no_account,
        _tr.bot_start_server_reason_cloud_disabled,
        _tr.bot_start_server_reason_no_minutes,
      };

      expect(
        raisons,
        hasLength(4),
        reason:
            'deux causes différentes ne peuvent pas partager la même phrase',
      );
      for (final raison in raisons) {
        expect(raison, isNotEmpty);
      }
    });
  });

  group('la pop-up', () {
    testWidgets('rend les deux chemins et rend le choix de l\'utilisateur', (
      tester,
    ) async {
      BotStartTarget? choisi;
      await tester.pumpWidget(
        _hote(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choisi = await showBotStartTargetDialog(
                  context,
                  botName: 'Bot-Creator',
                  choices: _choix(),
                );
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text(_tr.bot_start_local_title), findsOneWidget);
      expect(find.text(_tr.bot_start_server_title), findsOneWidget);

      await tester.tap(find.text(_tr.bot_start_server_title));
      await tester.pumpAndSettle();

      expect(choisi, BotStartTarget.server);
    });

    testWidgets(
      'n\'affiche pas le serveur quand il est impossible, mais dit pourquoi',
      (tester) async {
        await tester.pumpWidget(
          _hote(
            Builder(
              builder: (context) => TextButton(
                onPressed: () => showBotStartTargetDialog(
                  context,
                  botName: 'Bot-Creator',
                  choices: _choix(freeMinutesBalance: 0),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('ouvrir'));
        await tester.pumpAndSettle();

        expect(find.text(_tr.bot_start_local_title), findsOneWidget);
        expect(
          find.text(_tr.bot_start_server_title),
          findsNothing,
          reason: 'une option impossible n\'est pas proposée',
        );
        expect(
          find.text(_tr.bot_start_server_reason_no_minutes),
          findsOneWidget,
          reason:
              'sans sa raison, l\'utilisateur chercherait où l\'option est passée',
        );
      },
    );

    testWidgets('annuler ne démarre rien', (tester) async {
      var rendu = false;
      BotStartTarget? choisi;
      await tester.pumpWidget(
        _hote(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choisi = await showBotStartTargetDialog(
                  context,
                  botName: 'Bot-Creator',
                  choices: _choix(),
                );
                rendu = true;
              },
              child: const Text('ouvrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_tr.common_cancel));
      await tester.pumpAndSettle();

      expect(rendu, isTrue);
      expect(choisi, isNull);
    });
  });
}
