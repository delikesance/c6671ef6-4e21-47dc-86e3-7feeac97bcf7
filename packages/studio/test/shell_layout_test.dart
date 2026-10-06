import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/auth/auth_controller.dart';
import 'package:bot_creator_studio/src/auth/studio_session.dart';
import 'package:bot_creator_studio/src/locale_controller.dart';
import 'package:bot_creator_studio/src/studio_app.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _command = '''
{"command":{"id":"c1","name":"ban","description":"Bannir un membre","type":"chatInput",
 "data":{"triggerType":"slash","executionMode":"workflow","options":[{"name":"membre"}],
 "actions":[{"id":"a1","type":"banUser","payload":{"userId":"((option.membre))"}},
            {"id":"a2","type":"respondWithMessage","payload":{"content":"Banni."}}]}},
 "revision":"r1"}''';

http.Response _route(http.Request r) {
  final p = r.url.path;
  String body;
  if (p == '/gateway/runtime') {
    body = '{"plan":"FREE"}';
  } else if (p == '/gateway/bots') {
    body =
        '{"bots":[{"bot_id":"1","bot_name":"Modération","runtime_state":"running"}]}';
  } else if (p == '/gateway/bots/1/runtime') {
    body = '{"funding_mode":"free","free_minutes_balance":90}';
  } else if (p == '/gateway/bots/1/logs') {
    body = '{"lines":["bot connecté","commande ban exécutée"]}';
  } else if (p == '/api/v2/bots/1/commands') {
    body =
        '{"commands":[{"id":"c1","name":"ban","trigger":"/ban"},{"id":"c2","name":"ping"}]}';
  } else if (p == '/api/v2/bots/1/commands/c1') {
    body = _command;
  } else if (p == '/gateway/bots/1/variables/global') {
    body = '{"values":{"score":3}}';
  } else if (p == '/gateway/bots/1/team/collaborators') {
    body =
        '{"collaborators":[{"user_id":"u","display_name":"Ana","is_owner":true}],"my_permissions":{"can_view_chat":true}}';
  } else if (p == '/gateway/bots/1/command-stats') {
    body =
        '{"hours":24,"totalAllTime":10,"commands":[{"command":"ping","count":4}],"timeline":[],"locales":[],"health":{"total":4}}';
  } else {
    body = '{}';
  }
  // Le vrai serveur répond en UTF-8 : `http.Response(String)` encoderait en
  // latin-1 et casserait les accents.
  return http.Response.bytes(
    utf8.encode(body),
    200,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

Future<AuthController> _signedIn() async {
  SharedPreferences.setMockInitialValues({});
  await SessionStore().save(
    StudioSession(
      accessToken: 'tok',
      refreshToken: 'ref',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      username: 'ana',
    ),
  );
  return AuthController(
    api: StudioApi(
      baseUrl: 'https://api.test',
      client: MockClient((r) async => _route(r)),
    ),
  );
}

Future<LocaleController> _french() async {
  final controller = LocaleController();
  await controller.set(const Locale('fr'));
  return controller;
}

Future<void> _pumpApp(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    StudioApp(auth: await _signedIn(), locale: await _french()),
  );
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Démonte l'arbre : annule les minuteries (relecture, reconnexion).
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('réglages : carte Apparence de l\'app, sans choix de mode', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1280, 800));
    await tester.tap(find.text('Paramètres'));
    await _settle(tester);
    expect(find.byType(AppearanceSettingsSection), findsOneWidget);
    expect(find.byKey(AppearanceSettingsSection.modeSelectorKey), findsNothing);
    expect(find.byType(TextScaleSettingsSection), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  const phone = Size(390, 844);
  const desktop = Size(1280, 800);

  testWidgets('téléphone : barre du bas, pas de rail, aucun débordement', (
    tester,
  ) async {
    await _pumpApp(tester, phone);
    expect(find.text('Documentation'), findsOneWidget); // barre du bas
    expect(find.text('Mes bots'), findsWidgets);
    expect(find.text('Modération'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('téléphone : parcours d\'un bot sans débordement', (
    tester,
  ) async {
    await _pumpApp(tester, phone);

    await tester.tap(find.text('Gérer'));
    await _settle(tester);
    expect(find.text('JOURNAUX'), findsOneWidget);
    expect(find.text('bot connecté'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Cmd'));
    await _settle(tester);
    expect(find.text('ban'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('ban'));
    await _settle(tester);
    expect(find.text('Métadonnées'), findsOneWidget);
    expect(find.text('Point de départ (Déclencheur)'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Retour à la liste, puis la page Modules.
    await tester.tap(find.byTooltip('Retour').last);
    await _settle(tester);
    await tester.tap(find.text('Modules'));
    await _settle(tester);
    expect(find.text('CRÉATION'), findsOneWidget);
    expect(find.text('AUTOMATISATION'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Variables'));
    await _settle(tester);
    expect(find.text('score'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(
      find.text('Modules').first,
    ); // « ‹ Modules » : retour liste
    await _settle(tester);
    expect(find.text('CRÉATION'), findsOneWidget);

    // La ligne est sous le pli de l'écran : on la fait défiler avant de la toucher.
    await tester.ensureVisible(find.text('Tableau de bord'));
    await _settle(tester);
    await tester.tap(find.text('Tableau de bord'));
    await _settle(tester);
    expect(find.text('Analytics Premium'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('téléphone : mode débutant masque la liste des modules', (
    tester,
  ) async {
    await _pumpApp(tester, phone);
    await tester.tap(find.text('Gérer'));
    await _settle(tester);
    await tester.tap(find.text('Modules'));
    await _settle(tester);
    expect(find.text('CRÉATION'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await _settle(tester);
    expect(find.text('CRÉATION'), findsNothing);
    expect(
      find.text('Affichage des onglets essentiels uniquement'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('grand écran : rail, et le mode débutant masque les onglets', (
    tester,
  ) async {
    await _pumpApp(tester, desktop);
    await tester.tap(find.text('Gérer'));
    await _settle(tester);

    expect(find.text('Commandes'), findsOneWidget); // rail
    expect(find.text('Vars'), findsOneWidget);
    expect(find.text('Planif'), findsOneWidget);
    expect(find.text('Cmd'), findsNothing); // pas de barre du bas

    await tester.tap(find.text('Mode débutant'));
    await _settle(tester);
    expect(find.text('Vars'), findsNothing);
    expect(find.text('Planif'), findsNothing);
    expect(find.text('Équipe'), findsNothing);
    expect(find.text('Commandes'), findsOneWidget);
    expect(find.text('Copilote IA'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Mode débutant'));
    await _settle(tester);
    expect(find.text('Vars'), findsOneWidget);
    await _dispose(tester);
  });

  testWidgets('grand écran : sortir du mode débutant depuis un onglet masqué', (
    tester,
  ) async {
    await _pumpApp(tester, desktop);
    await tester.tap(find.text('Gérer'));
    await _settle(tester);
    await tester.tap(find.text('Vars'));
    await _settle(tester);
    expect(find.text('score'), findsOneWidget);

    await tester.tap(find.text('Mode débutant'));
    await _settle(tester);
    // On ne reste pas sur un onglet que le mode débutant masque.
    expect(find.text('score'), findsNothing);
    expect(find.text('JOURNAUX'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });

  testWidgets('grand écran : le rejeu du débogueur est un onglet du bot, '
      'verrouillé sur un compte gratuit', (tester) async {
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    // Rail haut : les entrées du bas sont construites paresseusement.
    await _pumpApp(tester, const Size(1280, 1600));
    await tester.tap(find.text('Gérer'));
    await _settle(tester);

    await tester.tap(find.text(fr.debug_replay_title));
    await _settle(tester);
    expect(find.text(fr.debug_replay_premium_title), findsOneWidget);
    expect(find.text(fr.debug_replay_start_capture), findsNothing);
    expect(tester.takeException(), isNull);
    await _dispose(tester);
  });
}
