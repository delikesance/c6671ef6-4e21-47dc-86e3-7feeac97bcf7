// Le verrou premium doit dire la VRAIE cause, partout, et une seule fois.
//
// Contexte mesure (20/09/2026) : les quatre pages qui verrouillent une capacite premium
// (Scheduler, Inbound webhooks, analytique du tableau de bord, rejeu de debug) affichaient,
// des que la boutique native etait absente — donc sur un poste de travail — la phrase
// « Not available on this platform. » (`subscription_unavailable_platform`). Or la cause du
// verrou est la FORMULE DU COMPTE (verite serveur), pas la plateforme : un poste de travail
// lisait « le scheduler n'existe pas ici » alors que son compte est simplement en formule
// gratuite, et deux de ces pages ne proposaient plus AUCUNE action.
//
// Deux verrous ici, parce que les deux peuvent casser :
//   * le texte lui-meme (widget partage) — il doit exister, dans la langue de l'appareil,
//     et ne jamais etre la phrase de plateforme ;
//   * les quatre SITES — un seul reverte a la main suffirait a ramener le mensonge, donc un
//     test de source verifie qu'aucune de ces pages n'utilise plus la phrase fautive et que
//     chacune passe par la brique partagee.
import 'dart:io';

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'turnkey_bot_invite_test_support.dart' show arbFrText;

/// Les quatre pages qui verrouillent une capacite premium.
const List<String> _pagesVerrouillees = <String>[
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/scheduler.page.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/inbound_webhooks.page.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/command_dashboard.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart',
];

void main() {
  testWidgets('le message dit la formule du compte et ou l\'abonnement s\'active', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: PremiumLockedHint())),
      ),
    );

    final attendu = arbFrText('premium_locked_hint');
    expect(attendu, isNotEmpty, reason: 'la cle doit exister dans l\'ARB francais');
    expect(find.text(attendu), findsOneWidget);
    expect(
      find.byIcon(Icons.lock_outline_rounded),
      findsOneWidget,
      reason: 'le cadenas est la convention premium de l\'app',
    );
  });

  testWidgets('le message ne parle JAMAIS de plateforme', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: PremiumLockedHint())),
      ),
    );

    expect(
      find.text(arbFrText('subscription_unavailable_platform')),
      findsNothing,
      reason:
          'un compte en formule gratuite n\'est pas une plateforme incapable : confondre les '
          'deux envoie l\'utilisateur chercher une limite qui n\'existe pas',
    );
  });

  test('les quatre pages verrouillees utilisent la brique partagee, aucune la phrase fautive', () {
    for (final chemin in _pagesVerrouillees) {
      final source = File(chemin).readAsStringSync();

      expect(
        source.contains('PremiumLockedHint'),
        isTrue,
        reason: '$chemin doit passer par la brique partagee (sinon les textes divergent)',
      );
      expect(
        source.contains('subscription_unavailable_platform'),
        isFalse,
        reason:
            '$chemin affiche encore la phrase de plateforme : la cause du verrou est la formule '
            'du compte (verite serveur), pas la plateforme',
      );
    }
  });
}
