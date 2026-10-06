import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/editor/studio_team_chat_host.dart';
import 'package:bot_creator_studio/src/platform/event_socket.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _message(int id, String author, String content, int at) =>
    {
      'id': id,
      'author_user_id': '10$id',
      'author_display_name': author,
      'content': content,
      'created_at': DateTime.utc(2026, 10, 3, 10, at).toIso8601String(),
    };

/// Un Manager simulé : équipe, droits du lecteur, fil du tchat.
class _Manager {
  _Manager({this.canInvite = true, this.canViewChat = true});

  final bool canInvite;
  final bool canViewChat;
  final seen = <http.Request>[];
  final posted = <String>[];

  http.Client get client => MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p.endsWith('/team/collaborators') && r.method == 'GET') {
      return _json({
        'collaborators': [
          {
            'user_id': '1',
            'role': 'owner',
            'display_name': 'Ana',
            'is_owner': true,
            'permissions': {},
          },
          {
            'user_id': '2',
            'role': 'collaborator',
            'display_name': 'Bob',
            'permissions': {'can_start_stop': true},
          },
        ],
        'my_permissions': {
          'can_invite': canInvite,
          'can_view_chat': canViewChat,
        },
        'is_owner': canInvite,
      });
    }
    if (p.endsWith('/team/chat') && r.method == 'GET') {
      if (!canViewChat) return _json({'error': 'forbidden'}, 403);
      return _json({
        'messages': [
          _message(2, 'Bob', 'deuxième', 5),
          _message(1, 'Ana', 'premier', 1),
        ],
      });
    }
    if (p.endsWith('/team/chat') && r.method == 'POST') {
      final content = (jsonDecode(r.body) as Map)['content'] as String;
      posted.add(content);
      return _json({'message': _message(3, 'Ana', content, 9)});
    }
    return _json({'ok': true});
  });

  StudioApi get api =>
      StudioApi(baseUrl: 'https://api.test', client: client)
        ..accessToken = ({bool force = false}) async => 'tok';
}

/// Faux canal temps réel : le test pousse les messages du serveur.
class _FakeSocket extends EventSocket {
  _FakeSocket({
    required super.url,
    required super.token,
    required super.onMessage,
    required super.onClosed,
    super.onData,
  });

  @override
  Future<void> connect() async {}

  @override
  void close() {}

  void push(Map<String, dynamic> frame) {
    onMessage();
    onData?.call(jsonEncode(frame));
  }
}

void main() {
  group('hôte du tchat d\'équipe : format des appels', () {
    test(
      'collaborateurs, fil et droits sont décodés comme dans l\'app',
      () async {
        final manager = _Manager();
        final host = StudioTeamChatHost(manager.api);

        final team = await host.collaborators('b1');
        expect(team.map((c) => c.userId), ['1', '2']);
        expect(team.first.isOwner, isTrue);
        expect(team.last.permissions.canStartStop, isTrue);
        expect(team.last.permissions.canInvite, isFalse);

        final messages = await host.messages('b1');
        expect(messages.map((m) => m.content), ['deuxième', 'premier']);
        expect(messages.first.authorDisplayName, 'Bob');

        final mine = await host.myPermissions('b1');
        expect(mine!.canInvite, isTrue);

        expect(
          manager.seen.map(
            (r) =>
                '${r.method} ${r.url.path}${r.url.query.isEmpty ? '' : '?${r.url.query}'}',
          ),
          [
            'GET /gateway/bots/b1/team/collaborators',
            'GET /gateway/bots/b1/team/chat?limit=50',
            'GET /gateway/bots/b1/team/collaborators',
          ],
        );
      },
    );

    test('sans bloc my_permissions les droits sont inconnus (null)', () async {
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient((_) async => _json({'collaborators': []})),
      )..accessToken = ({bool force = false}) async => 'tok';
      expect(await StudioTeamChatHost(api).myPermissions('b1'), isNull);
    });

    test('publier = POST {content}, le message créé est rendu', () async {
      final manager = _Manager();
      final created = await StudioTeamChatHost(
        manager.api,
      ).postMessage('b1', 'salut');
      expect(manager.posted, ['salut']);
      expect(created!.id, 3);
      expect(created.content, 'salut');
      final post = manager.seen.single;
      expect(post.method, 'POST');
      expect(post.url.path, '/gateway/bots/b1/team/chat');
      expect(post.headers['authorization'], 'Bearer tok');
    });

    test(
      'ajouter = POST user_id + les cinq droits, retirer = DELETE',
      () async {
        final manager = _Manager();
        final host = StudioTeamChatHost(manager.api);
        await host.upsertCollaborator(
          'b1',
          '42',
          const BotPermissions(canEditCommands: true),
        );
        await host.removeCollaborator('b1', '42');
        final add = manager.seen[0];
        expect(add.method, 'POST');
        expect(add.url.path, '/gateway/bots/b1/team/collaborators');
        expect(jsonDecode(add.body), {
          'user_id': '42',
          'permissions': {
            'can_edit_commands': true,
            'can_start_stop': false,
            'can_claim_ads': false,
            'can_invite': false,
            'can_view_chat': true,
          },
        });
        expect(manager.seen[1].method, 'DELETE');
        expect(
          manager.seen[1].url.path,
          '/gateway/bots/b1/team/collaborators/42',
        );
      },
    );

    test(
      'pas d\'équipe du portail ni de recherche Discord côté Studio',
      () async {
        final host = StudioTeamChatHost(_Manager().api, userName: 'Ana');
        expect(await host.prepare('b1'), isTrue);
        expect(await host.currentUserName(), 'Ana');
        expect(await host.portalTeam('b1'), isNull);
        expect(await host.lookupUser('b1', '1'), isNull);
      },
    );
  });

  group('hôte du tchat d\'équipe : temps réel', () {
    test(
      'les événements d\'équipe du canal sont décodés, le reste ignoré',
      () async {
        final sockets = <_FakeSocket>[];
        final host = StudioTeamChatHost(
          _Manager().api,
          socketFactory:
              ({
                required url,
                required token,
                required onMessage,
                required onData,
                required onClosed,
              }) {
                final s = _FakeSocket(
                  url: url,
                  token: token,
                  onMessage: onMessage,
                  onData: onData,
                  onClosed: onClosed,
                );
                sockets.add(s);
                return s;
              },
        );
        final events = <TeamChatEvent>[];
        final sub = host.events('b1').listen(events.add);

        expect(sockets.single.url, 'wss://api.test/gateway/bots/events');
        sockets.single
          ..push({'type': 'ping'})
          ..push({'type': 'snapshot', 'bots': []})
          ..push({
            'type': 'team.chat.message',
            'team_message': {
              'id': 7,
              'bot_id': 'b1',
              'author_user_id': '2',
              'content': 'en direct',
              'created_at': DateTime.utc(2026, 10, 3).toIso8601String(),
            },
          })
          ..push({
            'type': 'team.members.updated',
            'team_members': {'bot_id': 'b2'},
          });
        await pumpEventQueue();

        expect(events, hasLength(2));
        final message = events[0] as TeamChatMessageEvent;
        expect(message.message.botId, 'b1');
        expect(message.message.content, 'en direct');
        expect((events[1] as TeamMembersChangedEvent).botId, 'b2');
        await sub.cancel();
      },
    );

    test(
      'hors navigateur (canal indisponible) : relecture périodique',
      () async {
        final host = StudioTeamChatHost(
          _Manager().api,
          pollInterval: const Duration(milliseconds: 20),
        );
        final first = await host.events('b1').first;
        expect(first, isA<TeamChatResyncEvent>());
      },
    );
  });

  group('écran partagé monté sur le Manager', () {
    Future<void> pump(WidgetTester tester, _Manager manager) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: AppTheme.darkTheme(),
          home: TeamChatPage(
            botId: 'b1',
            host: StudioTeamChatHost(manager.api, userName: 'Ana'),
            reserveNavBarClearance: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('liste l\'équipe et le fil, publie un message', (tester) async {
      final manager = _Manager();
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pump(tester, manager);

      expect(find.text('Ana'), findsWidgets);
      expect(find.text('Bob'), findsWidgets);
      expect(find.text('premier'), findsOneWidget);
      expect(find.text('deuxième'), findsOneWidget);
      // Du plus ancien au plus récent, même si le Manager rend l'inverse.
      expect(
        tester.getTopLeft(find.text('premier')).dy,
        lessThan(tester.getTopLeft(find.text('deuxième')).dy),
      );
      // `can_invite` : le contrôle d'ajout est offert.
      expect(find.text(fr.team_add_by_discord_id), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'bonjour équipe');
      await tester.tap(find.byTooltip(fr.team_chat_send));
      await tester.pumpAndSettle();

      expect(manager.posted, ['bonjour équipe']);
      expect(find.text('bonjour équipe'), findsOneWidget);
      await close(tester);
    });

    testWidgets('sans can_invite : aucun contrôle de gestion', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pump(tester, _Manager(canInvite: false));
      expect(find.text(fr.team_add_by_discord_id), findsNothing);
      expect(find.byTooltip(fr.team_remove), findsNothing);
      await close(tester);
    });

    testWidgets(
      'sans can_view_chat : le refus du fil n\'est pas une panne, pas de saisie',
      (tester) async {
        final manager = _Manager(canViewChat: false);
        final fr = await AppLocalizations.delegate.load(const Locale('fr'));
        await pump(tester, manager);

        expect(find.text(fr.team_chat_no_access), findsOneWidget);
        expect(find.byType(TextField), findsNothing);
        // L'équipe reste affichée : seule la conversation est fermée.
        expect(find.text('Bob'), findsWidgets);
        await close(tester);
      },
    );
  });
}
