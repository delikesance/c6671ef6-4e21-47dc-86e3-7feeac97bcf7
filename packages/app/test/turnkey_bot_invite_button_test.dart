// BRANCHEMENT du bouton « Inviter le bot » sur la carte d'accueil d'un conteneur
// clé en main.
//
// La carte est montée telle quelle : elle ne fait AUCUN appel réseau ni ne pose
// de minuterie, contrairement à la page de détail (dont le canal temps réel
// ouvre un vrai WebSocket — elle n'est donc pas montée en test).
//
// Ce qui est vérifié ici est le contrat visible par l'utilisateur : le libellé
// vient de la clé i18n, la carte relaie le tap, et pendant l'invitation le
// bouton est désactivé avec son indicateur — donc aucun second envoi.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/presentation/home_turnkey_container_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'turnkey_bot_invite_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Polices embarquées uniquement : toute famille non embarquée échoue au
    // lieu de partir en requête réseau silencieuse.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets(
    'la carte offre « Inviter le bot » et se verrouille pendant l\'invitation',
    (tester) async {
      var taps = 0;
      var busy = false;
      late StateSetter setHostState;

      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return HomeTurnkeyContainerCard(
                container: turnkeyContainer(),
                actions: HomeContainerActions(
                  onStart: () {},
                  onStop: () {},
                  onLogs: () {},
                  onDetail: () {},
                  onInvite: () => taps++,
                  inviteBusy: busy,
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Le libellé vient de la clé i18n, pas d'un littéral d'écran.
      final idleLabel = arbFrText('container_invite_btn');
      expect(find.text(idleLabel), findsOneWidget);

      await tester.tap(find.text(idleLabel));
      await tester.pump();
      expect(taps, 1, reason: 'le tap doit atteindre l\'action d\'invitation');

      // Invitation en cours : libellé d'occupation + indicateur, et le tap ne
      // repart plus (aucun second envoi possible depuis la carte).
      setHostState(() => busy = true);
      await tester.pump();
      expect(find.text(idleLabel), findsNothing);
      expect(
        find.text(arbFrText('container_invite_busy')),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(
        find.text(arbFrText('container_invite_busy')),
        warnIfMissed: false,
      );
      await tester.pump();
      expect(taps, 1, reason: 'un second tap pendant l\'invitation est ignoré');
      expect(tester.takeException(), isNull);
    },
  );
}
