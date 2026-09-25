// Preuve du maillon qui manquait côté app : l'identifiant sous lequel l'APP
// connaît un bot doit atteindre le manager AVEC la sauvegarde de configuration.
//
// POURQUOI ce test existe : le manager identifie un bot par son jeton Discord
// (`/applications/@me`) et le range donc sous l'identifiant que Discord lui
// rend. Un bot dont l'app connaît un identifiant local (import de configuration,
// bot reconstruit hors ligne) arrivait sous un identifiant que le manager
// n'avait jamais stocké : le callback SSV de l'annonce regardée pour ce bot
// était refusé (« no owner candidate accepted the claim »), la publicité était
// vue et les minutes n'étaient jamais créditées. Porter `bot_id` dans la poussée
// est ce qui permet au manager d'enregistrer la correspondance — et au bouton de
// réconciliation de rendre le temps perdu.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Une configuration NON dégénérée : la garde anti-config-vide refuserait une
/// charge sans aucune famille d'automatisation, et le test ne prouverait alors
/// rien sur l'appel réseau.
Map<String, dynamic> _validPayload() => <String, dynamic>{
  'runtimeEngine': 'javascript',
  'commands': <dynamic>[
    <String, dynamic>{'id': 'cmd-1', 'name': 'ping'},
  ],
  'events': <dynamic>[],
};

/// Un client dont la couche HTTP enregistre toute requête émise : c'est la seule
/// façon de prouver ce qui PART réellement, plutôt que ce qu'on croit envoyer.
MainApiClient _recordingClient(List<http.Request> sink) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    return http.Response('{}', 200);
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    documentsDir = await Directory.systemTemp.createTemp('ssv_bot_identity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('saveDiscordBotSnapshot transporte bot_id avec la configuration', () async {
    final requests = <http.Request>[];
    final client = _recordingClient(requests);

    await client.saveDiscordBotSnapshot(
      botId: 'local-bot-42',
      botToken: 'bot-token',
      config: _validPayload(),
    );

    expect(requests, hasLength(1));
    final request = requests.single;
    expect(request.url.path, '/gateway/bots/discord/save');

    final body = jsonDecode(request.body) as Map<String, dynamic>;
    expect(
      body['bot_id'],
      'local-bot-42',
      reason:
          "sans bot_id, le manager ne peut pas rattacher l'identifiant local de "
          "l'app au bot géré : le callback SSV de l'annonce reste orphelin et la "
          'récompense est perdue',
    );
    expect(body['bot_token'], 'bot-token');
    expect(
      (body['config'] as Map<String, dynamic>)['commands'],
      isA<List<dynamic>>(),
    );
  });
}
