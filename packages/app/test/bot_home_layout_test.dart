import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests de mise en page de la home d'un bot :
/// - en-tête de la carte « Logs du bot » sans débordement à 320 dp ;
/// - mise en page desktop qui exploite la hauteur réelle de la fenêtre
///   (la console de logs s'étire) tout en retombant sur la mise en page
///   scrollable historique quand la fenêtre est courte.
///
/// `AppHomePage` exige un `NyxxRest` non injectable : on monte donc les
/// sous-widgets réellement utilisés par la page
/// (`BotHomeDesktopOverview` + `BotHomeLiveConsoleCard`).

const _botId = '123456789012345678';

Widget _hostApp(Widget child, {Locale locale = const Locale('fr')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

BotHomeLiveConsoleCard _consoleCard({
  Key? key,
  String botId = _botId,
  bool isLive = true,
  bool fillHeight = false,
}) {
  return BotHomeLiveConsoleCard(
    key: key,
    botId: botId,
    isLive: isLive,
    fillHeight: fillHeight,
    onOpenLogs: () {},
  );
}

class _Block extends StatelessWidget {
  const _Block({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

void main() {
  testWidgets(
    'carte Logs du bot : en-tête sans débordement à 320 dp (mobile, FR)',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _hostApp(
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [_consoleCard()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Aucune exception de layout (débordement) ne doit être levée.
      expect(tester.takeException(), isNull);
      // Le titre reste rendu.
      expect(find.text('Logs du bot'), findsOneWidget);
      // Sous le seuil, l'action est réduite à une icône + tooltip.
      expect(find.text('Voir les logs du bot'), findsNothing);
      expect(find.byTooltip('Voir les logs du bot'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    },
  );

  testWidgets('carte Logs du bot : AUCUN débordement sur la plage de bascule '
      '(balayage au pas de 2 px)', (tester) async {
    // Balayage FIN (pas de 2 px) sur la zone de bascule de l'en-tête.
    // Attention au récit : le débordement de 7 px venait de la MISE EN PAGE de
    // l'en-tête (titre non flexible), pas du seuil ; le seuil de 400 px n'est
    // qu'une marge de sécurité. Ce balayage garantit qu'aucune largeur de la
    // plage ne déborde (sonde de contrôle : seuil forcé à 0 ⇒ 2 rouges).
    for (var width = 380.0; width <= 480.0; width += 2) {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _hostApp(
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [_consoleCard()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'l\'en-tête « Logs du bot » déborde à ${width.round()} px',
      );
    }

    // Bornes basses et hautes, toujours sans débordement.
    for (final width in <double>[320, 560, 1600]) {
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _hostApp(
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [_consoleCard()],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: 'débordement à $width px');
    }
  });

  testWidgets(
    'carte Logs du bot : action complète conservée sur fenêtre large',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _hostApp(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 900, child: _consoleCard()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Voir les logs du bot'), findsOneWidget);
    },
  );

  testWidgets(
    'home desktop 1600x1000 : les colonnes remplissent la fenêtre et la console grandit',
    (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const consoleKey = Key('logs-console');
      const leftKey = Key('left-column-block');
      const dangerKey = Key('danger-zone-block');

      await tester.pumpWidget(
        _hostApp(
          BotHomeDesktopOverview(
            leftBuilder: (context, fillViewport) => const [
              // Plus haut que la fenêtre : la colonne de gauche doit défiler
              // seule en mode pleine hauteur (sans débordement).
              SizedBox(key: leftKey, height: 1400, child: _Block(height: 1400)),
            ],
            rightBuilder: (context, fillViewport) => [
              if (fillViewport)
                Expanded(child: _consoleCard(key: consoleKey, fillHeight: true))
              else
                _consoleCard(key: consoleKey),
              const SizedBox(height: 16),
              const _Block(height: 140),
              const SizedBox(height: 20),
              const SizedBox(
                key: dangerKey,
                height: 56,
                child: _Block(height: 56),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final console = tester.getRect(find.byKey(consoleKey));
      // 1000 - 16 (haut) - 32 (bas) - 16 - 140 - 20 - 56 = 720 px accordés à
      // la console (au lieu des 160 px max historiques).
      expect(console.height, greaterThan(600));
      expect(console.top, 16);
      // La dernière carte descend jusqu'au bas de la zone de contenu : plus de
      // grand vide en bas de page.
      expect(tester.getRect(find.byKey(dangerKey)).bottom, closeTo(968, 1));
      // Le bloc de gauche est bien présent (et donc défilable, sinon le test
      // aurait levé une exception de layout).
      expect(find.byKey(leftKey), findsOneWidget);
    },
  );

  testWidgets(
    'home desktop juste au-dessus du seuil : mode pleine hauteur sans débordement',
    (tester) async {
      // 620 ≥ kBotHomeDesktopFillMinHeight (560) : mode pleine hauteur, avec
      // une colonne de droite de hauteurs réalistes (console + surveillance
      // ~130 + suppression 56).
      tester.view.physicalSize = const Size(900, 620);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const consoleKey = Key('logs-console');

      await tester.pumpWidget(
        _hostApp(
          BotHomeDesktopOverview(
            leftBuilder: (context, fillViewport) => [
              const _Block(height: 220),
              const SizedBox(height: 16),
              const _Block(height: 180),
              const SizedBox(height: 16),
              const _Block(height: 200),
            ],
            rightBuilder: (context, fillViewport) => [
              if (fillViewport)
                Expanded(child: _consoleCard(key: consoleKey, fillHeight: true))
              else
                _consoleCard(key: consoleKey),
              const SizedBox(height: 16),
              const _Block(height: 130),
              const SizedBox(height: 20),
              const _Block(height: 56),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final console = tester.getRect(find.byKey(consoleKey));
      // 620 - 16 - 32 - 16 - 130 - 20 - 56 = 350 px pour la console.
      expect(console.height, greaterThan(300));
    },
  );

  testWidgets(
    'home desktop fenêtre courte : retour à la mise en page scrollable (≤ 160 px de console)',
    (tester) async {
      // 550 < kBotHomeDesktopFillMinHeight (560) : mise en page historique.
      tester.view.physicalSize = const Size(900, 550);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const consoleKey = Key('logs-console');

      await tester.pumpWidget(
        _hostApp(
          BotHomeDesktopOverview(
            leftBuilder: (context, fillViewport) => const [
              _Block(height: 320),
              SizedBox(height: 16),
              _Block(height: 320),
            ],
            rightBuilder: (context, fillViewport) => [
              if (fillViewport)
                Expanded(child: _consoleCard(key: consoleKey, fillHeight: true))
              else
                _consoleCard(key: consoleKey),
              const SizedBox(height: 16),
              const _Block(height: 140),
              const SizedBox(height: 20),
              const _Block(height: 56),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final console = tester.getRect(find.byKey(consoleKey));
      // Mise en page historique conservée : en-tête + console bornée.
      expect(console.height, greaterThan(110));
      expect(console.height, lessThan(300));
    },
  );

  testWidgets(
    'console étirée : les dernières lignes restent collées en bas de la carte',
    (tester) async {
      const botId = '999000111222333444';
      for (var i = 1; i <= 3; i++) {
        appendBotLog('line $i', botId: botId);
      }
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const consoleKey = Key('logs-console');

      await tester.pumpWidget(
        _hostApp(
          BotHomeDesktopOverview(
            leftBuilder: (context, fillViewport) => const [],
            rightBuilder: (context, fillViewport) => [
              if (fillViewport)
                Expanded(
                  child: _consoleCard(
                    key: consoleKey,
                    botId: botId,
                    fillHeight: true,
                  ),
                )
              else
                _consoleCard(key: consoleKey, botId: botId),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('line 3'), findsOneWidget);

      final card = tester.getRect(find.byKey(consoleKey));
      final lastLine = tester.getRect(find.textContaining('line 3'));
      // Console étirée : la dernière ligne reste au bas de la zone de logs
      // (padding 12) et non collée en haut d'un grand vide noir.
      expect(lastLine.bottom, greaterThan(card.bottom - 40));
      expect(lastLine.bottom, lessThanOrEqualTo(card.bottom - 12 + 1));
    },
  );

  testWidgets(
    'sensibilité du test : l\'ancien en-tête (non flexible) débordait à 320 dp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _hostApp(
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: _LegacyLogsHeaderReplica(),
          ),
        ),
      );
      await tester.pump();

      // Preuve que ce test détecte bien le bug d'origine : la réplique de
      // l'en-tête non flexible lève une exception de débordement.
      expect(tester.takeException(), isNotNull);
    },
  );
}

/// Réplique minimale de l'en-tête historique de la carte logs (titre et action
/// non flexibles) — sert uniquement de contrôle de sensibilité du test.
class _LegacyLogsHeaderReplica extends StatelessWidget {
  const _LegacyLogsHeaderReplica();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.terminal_rounded, size: 18),
        const SizedBox(width: 8),
        const Text('Logs du bot'),
        const SizedBox(width: 8),
        const SizedBox(width: 55, height: 18),
        const Spacer(),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.open_in_new_rounded, size: 14),
          label: const Text(
            'Voir les logs du bot',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
