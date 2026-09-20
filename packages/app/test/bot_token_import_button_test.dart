// Le bouton « Importer le jeton depuis mon compte » doit être utilisable et HONNÊTE.
//
// Ce qu'un test de widget peut prouver ici :
//   * le garde de réentrance : pendant qu'un export est EN VOL, le bouton est verrouillé
//     et un second geste ne produit pas un second export ;
//   * un texte par cause : un `404` de route absente (manager plus ancien) ne doit jamais
//     dire « vérifie ta connexion », et l'absence de compte connecté doit dire quoi faire ;
//   * le relais vers l'écran appelant, uniquement après un import RÉUSSI.
//
// Pourquoi l'exportateur est INJECTÉ plutôt qu'un vrai serveur local ou un vrai client :
// un import réussi ÉCRIT le jeton (base locale + coffre), et une écriture de fichier lancée
// depuis la zone d'horloge simulée d'un test de widget ne rend jamais la main — constaté :
// le bouton restait verrouillé et aucun message n'apparaissait. L'enchaînement complet
// (réglages → client → `POST /gateway/bots/{id}/token` → écriture du jeton) est prouvé là où
// il se laisse exécuter : `bot_token_import_test.dart`. Ici on prouve l'interface, en
// laissant la production traduire elle-même ses issues (`botTokenImportMessage`).
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_token_import_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'turnkey_bot_invite_test_support.dart' show arbFrText;

const String _botId = '1350824555119382678';

/// Exportateur factice : rend l'issue demandée et COMPTE les appels, ce qui est la
/// mesure du garde anti double clic. Aucune entrée/sortie, donc aucune horloge simulée
/// à contourner.
class _FauxImportateur extends BotTokenImporter {
  _FauxImportateur(this.issue, {this.delai = Duration.zero}) : super(client: null);

  final BotTokenImportOutcome issue;
  final Duration delai;

  int appels = 0;

  @override
  Future<BotTokenImportOutcome> importFromUserAction({required String botId}) async {
    appels++;
    if (delai > Duration.zero) {
      await Future<void>.delayed(delai);
    }
    return issue;
  }
}

Widget _wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}

/// Presse le bouton, laisse le message se monter, et rend l'exportateur utilisé.
Future<_FauxImportateur> _presserLeBouton(
  WidgetTester tester,
  BotTokenImportOutcome issue, {
  Duration delai = Duration.zero,
  Future<void> Function()? onImported,
}) async {
  final importateur = _FauxImportateur(issue, delai: delai);
  await tester.pumpWidget(
    _wrap(
      BotTokenImportButton(
        botId: _botId,
        importerFactory: () => importateur,
        onImported: onImported,
      ),
    ),
  );

  await tester.tap(find.byType(OutlinedButton));
  await tester.pump();
  await tester.pump(delai + const Duration(milliseconds: 400));
  return importateur;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  testWidgets('le bouton est présent, actif, et porte le libellé de la clé i18n', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BotTokenImportButton(
          botId: _botId,
          importerFactory: () => _FauxImportateur(BotTokenImportOutcome.imported),
        ),
      ),
    );

    expect(find.text(arbFrText('bot_token_import_btn')), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
      reason: 'le bouton doit être cliquable',
    );
  });

  testWidgets('sans compte connecté : le message dit quoi faire, bouton rendu actif', (
    tester,
  ) async {
    await _presserLeBouton(tester, BotTokenImportOutcome.noAccount);

    expect(find.text(arbFrText('bot_token_import_no_account')), findsOneWidget);
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNotNull,
      reason: 'un échec dû à l\'absence de compte ne doit pas laisser le bouton verrouillé',
    );
  });

  testWidgets('import réussi : message dédié et écran appelant prévenu', (
    tester,
  ) async {
    var rappels = 0;

    final importateur = await _presserLeBouton(
      tester,
      BotTokenImportOutcome.imported,
      onImported: () async => rappels++,
    );

    expect(importateur.appels, 1);
    expect(find.text(arbFrText('bot_token_import_success')), findsOneWidget);
    expect(rappels, 1, reason: 'l\'écran se recharge après un import réussi');
  });

  testWidgets('409 : le compte n\'a aucun jeton enregistré pour ce bot', (
    tester,
  ) async {
    await _presserLeBouton(tester, BotTokenImportOutcome.notStored);

    expect(find.text(arbFrText('bot_token_import_not_stored')), findsOneWidget);
  });

  testWidgets(
    '404 de route absente (manager plus ancien) : jamais un message de connexion',
    (tester) async {
      await _presserLeBouton(tester, BotTokenImportOutcome.serverUnsupported);

      expect(
        find.text(arbFrText('bot_token_import_server_unsupported')),
        findsOneWidget,
      );
      expect(
        find.text(arbFrText('bot_token_import_network')),
        findsNothing,
        reason: 'le serveur est plus ancien : ce n\'est pas une panne de connexion',
      );
    },
  );

  testWidgets('second geste pendant un export en vol : ignoré, bouton verrouillé', (
    tester,
  ) async {
    final importateur = _FauxImportateur(
      BotTokenImportOutcome.imported,
      delai: const Duration(milliseconds: 250),
    );
    await tester.pumpWidget(
      _wrap(
        BotTokenImportButton(botId: _botId, importerFactory: () => importateur),
      ),
    );

    await tester.tap(find.byType(OutlinedButton));
    await tester.pump();

    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
      reason: 'un export en vol doit verrouiller le bouton',
    );

    // Ce second geste ne peut pas partir : le bouton est verrouillé.
    await tester.tap(find.byType(OutlinedButton), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      importateur.appels,
      1,
      reason: 'deux exports du même jeton gaspilleraient le seau du serveur',
    );
  });

  group('résolution du client depuis les réglages du compte', () {
    test('sans compte configuré : aucun client, donc un message plutôt qu\'un échec muet', () async {
      expect(await resolveAccountClientForTokenImport(), isNull);
    });

    test('avec une session valide : le client porte la base du compte', () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://manager-reglages.test'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'session-de-test',
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
      );

      final client = await resolveAccountClientForTokenImport();

      expect(client, isNotNull);
      // Le porteur n'est PAS exposé par le client (c'est voulu) : on vérifie la base,
      // qui prouve que la configuration du compte a bien été lue.
      expect(client?.baseUrl, contains('manager-reglages.test'));
    });

    test('session expirée : aucun client (l\'utilisateur doit se reconnecter)', () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://manager-reglages-expires.test'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'session-perimee',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      );

      expect(await resolveAccountClientForTokenImport(), isNull);
    });
  });
}
