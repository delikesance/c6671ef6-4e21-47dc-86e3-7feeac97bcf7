import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/commands/command_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> _command() => {
  'id': 'c1',
  'name': 'ban',
  'description': 'Bannir un membre',
  'type': 'chatInput',
  'folder': 'Moderation',
  'futureField': {'keep': true},
  'data': {
    'triggerType': 'slash',
    'executionMode': 'workflow',
    'options': [
      {'name': 'membre'},
    ],
    'actions': [
      {
        'id': 'a1',
        'type': 'banUser',
        'payload': {'userId': '((option.membre))'},
      },
      {
        'id': 'a2',
        'type': 'respondWithMessage',
        'payload': {'content': 'Banni.'},
      },
    ],
  },
};

void main() {
  group('CommandDraft', () {
    test('intact tant qu\'on ne touche à rien', () {
      final d = CommandDraft(_command());
      expect(d.dirty, isFalse);
      expect(d.optionCount, 1);
      expect(d.actions.length, 2);
    });

    test('les champs inconnus survivent à une édition', () {
      final d = CommandDraft(_command())..description = 'Nouveau';
      expect(d.dirty, isTrue);
      final raw = d.toRaw();
      expect(raw['futureField'], {'keep': true});
      expect(raw['folder'], 'Moderation');
      expect(raw['description'], 'Nouveau');
    });

    test('déplacer, désactiver, supprimer des blocs', () {
      final d = CommandDraft(_command())..moveAction(0, 1);
      expect(d.actions.map((a) => a['id']), ['a2', 'a1']);
      d.moveAction(0, -1); // hors bornes : sans effet
      expect(d.actions.map((a) => a['id']), ['a2', 'a1']);
      d.toggleAction(0);
      expect(d.actions[0]['enabled'], false);
      d.toggleAction(0);
      expect(d.actions[0]['enabled'], true);
      d.removeAction(1);
      expect(d.actions.length, 1);
    });

    test('validation slash : nom et description', () {
      final d = CommandDraft(_command());
      expect(d.validate(), isNull);
      d.name = 'Ban Membre';
      expect(d.validate(), contains('Nom invalide'));
      d.name = 'ban';
      d.description = '';
      expect(d.validate(), contains('description'));
      d.description = 'x' * 101;
      expect(d.validate(), contains('100'));
    });
  });

  group('API commandes', () {
    StudioApi api(MockClient c) =>
        StudioApi(baseUrl: 'https://api.test', client: c)
          ..accessToken = ({bool force = false}) async => 'tok';

    test('la liste porte de quoi dessiner la carte de l\'app', () async {
      final a = api(
        MockClient(
          (r) async => http.Response(
            '{"commands":[{"id":"c1","name":"ban","trigger":"/ban","type":"chatInput","folder":"mod","option_count":2,"action_count":3,"legacy_mode":true,"legacy_aliases":["b"]}]}',
            200,
          ),
        ),
      );
      final list = await a.listCommands('1');
      final card = list.single.card;
      expect(card['folder'], 'mod');
      final data = card['data'] as Map;
      expect((data['options'] as List).length, 2);
      expect((data['actions'] as List).length, 3);
      expect(data['legacyModeEnabled'], true);
      expect(data['legacyAliases'], ['b']);
    });

    test('get lit la commande et la révision', () async {
      final a = api(
        MockClient((r) async {
          expect(r.url.path, '/api/v2/bots/b1/commands/c1');
          return http.Response(
            jsonEncode({'command': _command(), 'revision': 'r7'}),
            200,
          );
        }),
      );
      final d = await a.getCommand('b1', 'c1');
      expect(d.revision, 'r7');
      expect(d.raw['name'], 'ban');
    });

    test('save : PATCH, If-Match entre guillemets, corps enveloppé', () async {
      late http.Request seen;
      final a = api(
        MockClient((r) async {
          seen = r;
          return http.Response('{"revision":"r8"}', 200);
        }),
      );
      final rev = await a.saveCommand('b1', 'c1', _command(), revision: 'r7');
      expect(rev, 'r8');
      expect(seen.method, 'PATCH');
      expect(seen.headers['if-match'], '"r7"');
      expect((jsonDecode(seen.body) as Map).keys, ['command']);
    });

    test('save : un 409 de révision n\'est pas rejoué', () async {
      var calls = 0;
      final a = api(
        MockClient((_) async {
          calls++;
          return http.Response(
            '{"error":"is at revision \\"r9\\"","code":"bot_config_revision_conflict"}',
            409,
          );
        }),
      );
      await expectLater(
        a.saveCommand('b1', 'c1', _command(), revision: 'r7'),
        throwsA(
          isA<StudioApiException>().having((e) => e.statusCode, 'status', 409),
        ),
      );
      expect(calls, 1);
    });

    test('delete : POST commands/delete', () async {
      late http.Request seen;
      final a = api(
        MockClient((r) async {
          seen = r;
          return http.Response('{}', 200);
        }),
      );
      await a.deleteCommand('b1', 'c1', botName: 'Bot');
      expect(seen.url.path, '/gateway/bots/b1/commands/delete');
      expect(jsonDecode(seen.body), {
        'botId': 'b1',
        'botName': 'Bot',
        'commandId': 'c1',
      });
    });
  });
}
