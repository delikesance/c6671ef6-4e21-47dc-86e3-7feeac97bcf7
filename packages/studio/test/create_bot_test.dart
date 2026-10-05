import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/bots/new_bot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

StudioApi _api(MockClient c) =>
    StudioApi(baseUrl: 'https://api.test', client: c)
      ..accessToken = ({bool force = false}) async => 'tok';

void main() {
  test('identifiant du bot lu dans le jeton', () {
    final token = '${base64.encode(utf8.encode('123456789012345678'))}.abc.def';
    expect(botIdFromToken(token), '123456789012345678');
    expect(botIdFromToken('pas-un-jeton'), isNull);
    expect(botIdFromToken(''), isNull);
  });

  test('config : jamais de jeton, jamais dégénérée', () {
    final config = newBotConfig(username: 'MonBot');
    expect(config.containsKey('token'), isFalse);
    expect(config['username'], 'MonBot');
    expect((config['commands'] as List).length, 1);
    final ping = (config['commands'] as List).single as Map;
    expect(ping['name'], 'ping');
    expect(
      ((ping['data'] as Map)['actions'] as List).single['payload']['content'],
      'Pong!',
    );
    expect(
      (newBotConfig(username: '', withSamplePing: false)['commands'] as List),
      isEmpty,
    );
    expect(newBotConfig(username: '').containsKey('username'), isFalse);
  });

  test('validation : route publique, identité lue', () async {
    late http.Request seen;
    final api = _api(
      MockClient((r) async {
        seen = r;
        return http.Response('{"id":"42","username":"Bot"}', 200);
      }),
    );
    final id = await api.validateBotToken(' secret ');
    expect(seen.url.path, '/gateway/turnkey/validate-token');
    expect(seen.headers.containsKey('authorization'), isFalse);
    expect(jsonDecode(seen.body), {'bot_token': 'secret'});
    expect((id.id, id.name), ('42', 'Bot'));
  });

  test('création : un seul POST, jeton à part de la config', () async {
    var calls = 0;
    late Map body;
    final api = _api(
      MockClient((r) async {
        calls++;
        body = jsonDecode(r.body) as Map;
        expect(r.url.path, '/gateway/bots/discord/save');
        return http.Response('{}', 200);
      }),
    );
    await api.createBot(
      botId: '42',
      botToken: 'secret',
      config: newBotConfig(username: 'Bot'),
    );
    expect(calls, 1);
    expect(body['bot_token'], 'secret');
    expect((body['config'] as Map).containsKey('token'), isFalse);
  });

  test('création : 409 en cours n\'est pas rejoué', () async {
    var calls = 0;
    final api = _api(
      MockClient((_) async {
        calls++;
        return http.Response(
          '{"error":"busy","code":"bot_sync_in_progress"}',
          409,
        );
      }),
    );
    await expectLater(
      api.createBot(botId: '42', botToken: 't', config: const {}),
      throwsA(
        isA<StudioApiException>().having(
          (e) => e.code,
          'code',
          'bot_sync_in_progress',
        ),
      ),
    );
    expect(calls, 1);
  });
}
