import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/screens/create_bot_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('créer un bot : la page de l\'app, moteur et jeton, puis /ping', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final fr = lookupAppLocalizations(const Locale('fr'));
    http.Request? created;
    final api = StudioApi(
      baseUrl: 'https://api.test',
      client: MockClient((r) async {
        if (r.url.path.endsWith('/validate-token')) {
          return _json({
            'bot': {'id': '123456789012345678', 'username': 'MonBot'},
          });
        }
        if (r.url.path.endsWith('/discord/save')) created = r;
        return _json({});
      }),
    )..accessToken = ({bool force = false}) async => 'tok';

    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: [
          ...AppLocalizations.localizationsDelegates,
          ...StudioLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        theme: AppTheme.darkTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => CreateBotPage(api: api)),
                  ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();

    // Le formulaire de l'app : titre, choix du moteur, jeton, ressources.
    expect(find.text(fr.bot_create_title), findsOneWidget);
    expect(find.text(fr.bot_create_visual_title), findsOneWidget);
    expect(find.text(fr.app_open_discord_portal), findsOneWidget);
    // Pas de jeton : pas d'envoi.
    final save = find.widgetWithText(FilledButton, fr.app_save_bot);
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.tap(find.text(fr.cmd_execution_mode_javascript));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tok.en.secret');
    await tester.pumpAndSettle();
    await tester.tap(save);
    // Le bouton affiche un indicateur qui tourne tant que ça travaille :
    // `pumpAndSettle` n'en verrait jamais la fin.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Comme l'app : on propose la commande d'exemple.
    expect(find.text(fr.app_create_sample_title), findsOneWidget);
    await tester.tap(find.text(fr.app_create_sample_skip));
    await tester.pumpAndSettle();

    final body = jsonDecode(created!.body) as Map<String, dynamic>;
    expect(body['bot_id'], '123456789012345678');
    expect(body['bot_token'], 'tok.en.secret');
    final config = body['config'] as Map<String, dynamic>;
    expect(config['runtimeEngine'], 'javascript');
    expect(config['commands'], isEmpty);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });
}
