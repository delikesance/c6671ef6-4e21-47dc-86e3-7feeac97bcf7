import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/screens/variables_page.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

StudioApi _api(MockClient c) =>
    StudioApi(baseUrl: 'https://api.test', client: c)
      ..accessToken = ({bool force = false}) async => 'tok';

void main() {
  test('journaux : lignes texte ou objets', () async {
    final api = _api(
      MockClient((r) async {
        expect(r.url.path, '/gateway/bots/b/logs');
        expect(r.url.queryParameters['limit'], '200');
        return http.Response('{"lines":["a",{"message":"b"},{"x":1}]}', 200);
      }),
    );
    expect(await api.botLogs('b'), ['a', 'b', '{"x":1}']);
  });

  test('valeur de variable : le type JSON est conservé', () {
    expect(parseVariableValue('12'), 12);
    expect(parseVariableValue('true'), true);
    expect(parseVariableValue('{"a":1}'), {'a': 1});
    expect(parseVariableValue('bonjour'), 'bonjour');
    expect(
      parseVariableValue('"12"'),
      '"12"',
    ); // une chaîne JSON reste du texte brut
    expect(formatVariableValue('x'), 'x');
    expect(formatVariableValue(3), '3');
  });

  test('variables globales : lecture, écriture, renommage', () async {
    final seen = <String>[];
    final api = _api(
      MockClient((r) async {
        seen.add('${r.method} ${r.url.path} ${r.body}');
        return r.method == 'GET'
            ? http.Response('{"values":{"score":3}}', 200)
            : http.Response('{}', 200);
      }),
    );
    expect(await api.globalVariables('b'), {'score': 3});
    await api.setGlobalVariable('b', ' score ', 4);
    await api.renameGlobalVariable('b', 'a', 'c');
    expect(seen[1], contains('/variables/global/set'));
    expect(jsonDecode(seen[1].split(' ').skip(2).join(' ')), {
      'key': 'score',
      'value': 4,
    });
    expect(seen[2], contains('"oldKey":"a"'));
  });

  test('équipe : collaborateurs et mes droits', () async {
    final api = _api(
      MockClient(
        (_) async => http.Response('''
{"collaborators":[{"user_id":"1","display_name":"Ana","is_owner":true,"role":"owner","permissions":{}},
 {"user_id":"2","display_name":"Bob","permissions":{"can_start_stop":true}}],
 "my_permissions":{"can_invite":true,"can_view_chat":false}}''', 200),
      ),
    );
    final team = await api.team('b');
    expect(team.collaborators.length, 2);
    expect(team.collaborators[0].isOwner, isTrue);
    expect(team.collaborators[1].permissions['can_start_stop'], isTrue);
    expect(team.mine['can_view_chat'], isFalse);
  });

  test('équipe : retirer = DELETE, tchat = POST', () async {
    final seen = <String>[];
    final api = _api(
      MockClient((r) async {
        seen.add('${r.method} ${r.url.path}');
        return http.Response('{}', 200);
      }),
    );
    await api.removeCollaborator('b', '2');
    await api.sendTeamChat('b', 'salut');
    expect(seen, [
      'DELETE /gateway/bots/b/team/collaborators/2',
      'POST /gateway/bots/b/team/chat',
    ]);
  });
}
