import 'dart:convert';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'context summary asks before charging and retries the draft in place',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      var turns = 0, summaries = 0;
      String? summaryKey;
      final chat = <String, dynamic>{
        'id': 'c',
        'title': 'Long discussion',
        'bot_id': '',
        'location': 'global',
        'revision': 0,
        'active_key': '',
        'archived': false,
        'messages': <dynamic>[],
        'actions': <dynamic>[],
        'consumed_tokens': 0,
      };
      final api = MainApiClient(
        baseUrl: 'http://localhost',
        accessToken: 'test',
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path == '/gateway/ai/copilot/tools')
            return http.Response('{"tools":[]}', 200);
          if (path == '/gateway/ai/wallet')
            return http.Response(
              '{"balance":10000,"reserved":0,"available":10000}',
              200,
            );
          if (path == '/gateway/ai/conversations')
            return http.Response(
              request.method == 'POST'
                  ? jsonEncode(chat)
                  : '{"conversations":[]}',
              200,
            );
          if (path == '/gateway/ai/conversations/c')
            return http.Response(jsonEncode(chat), 200);
          if (path == '/gateway/ai/conversations/c/turns') {
            turns++;
            expect(
              (jsonDecode(request.body) as Map)['prompt'],
              turns <= 2 ? 'Keep this draft' : 'Second draft',
            );
            if (turns == 1 || turns == 3)
              return http.Response('{"code":"ai_context_limit"}', 400);
            (chat['messages'] as List).addAll([
              {'role': 'user', 'content': 'Keep this draft'},
              {'role': 'assistant', 'content': 'Done'},
            ]);
            chat['revision'] = 4;
            return http.Response('{"request_key":"turn"}', 202);
          }
          if (path == '/gateway/ai/conversations/c/summarize') {
            summaries++;
            summaryKey =
                (jsonDecode(request.body) as Map)['idempotency_key'] as String;
            chat['revision'] = summaries == 1 ? 2 : 6;
            if (summaries == 1) chat['context_summary'] = 'Earlier turns';
            return http.Response(jsonEncode({'request_key': summaryKey}), 202);
          }
          if (path.endsWith('/events'))
            return http.Response(
              summaries == 2 && path.contains(summaryKey!)
                  ? 'id: 1\nevent: error\ndata: {"code":"ai_provider_failure"}\n\n'
                  : 'id: 1\nevent: completed\ndata: {"consumed_tokens":20}\n\n',
              200,
              headers: {'content-type': 'text/event-stream'},
            );
          throw StateError('Unexpected $path');
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CopilotPage(api: api),
        ),
      );
      await settle(tester);
      for (
        var i = 0;
        i < 100 &&
            tester.widget<TextField>(find.byType(TextField).first).enabled !=
                true;
        i++
      ) {
        await settle(tester);
      }
      expect(
        tester.widget<TextField>(find.byType(TextField).first).enabled,
        true,
      );
      await tester.enterText(find.byType(TextField).first, 'Keep this draft');
      await tester.pump();
      expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byIcon(Icons.send));
      await settle(tester);
      expect(
        find.text('Summarize this conversation?'),
        findsOneWidget,
        reason:
            'turns=$turns; UI=${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | ')}',
      );
      expect(summaries, 0);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Keep this draft',
      );
      await tester.tap(find.text('Summarize and send'));
      await settle(tester);
      expect(summaries, 1);
      expect(turns, 2);
      expect(chat['context_summary'], 'Earlier turns');
      expect(find.text('Done'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'Second draft');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send));
      await settle(tester);
      expect(find.text('Summarize this conversation?'), findsOneWidget);
      await tester.tap(find.text('Summarize and send'));
      await settle(tester);
      expect(summaries, 2);
      expect(turns, 3);
      expect(chat['context_summary'], 'Earlier turns');
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Second draft',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final allow in [false, true]) {
    testWidgets(
      'persistent copilot ${allow ? 'approves' : 'declines'} a remote action once',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        rootBundle.evict('assets/copilot/tools.json');
        SharedPreferences.setMockInitialValues({});
        var rounds = 0, stops = 0;
        String key = '';
        Map<String, dynamic>? conversation;
        final action = {
          'call_id': 'stop-call',
          'request_key': 'first',
          'state': 'pending',
          'call': {
            'id': 'stop-call',
            'type': 'function',
            'function': {
              'name': 'remote_stop_bot',
              'arguments': jsonEncode({'bot_id': '123456789012345'}),
            },
          },
        };
        final api = MainApiClient(
          baseUrl: 'http://localhost',
          accessToken: 'test',
          httpClient: MockClient((request) async {
            dynamic result;
            switch (request.url.path) {
              case '/gateway/ai/copilot/tools':
                result = {
                  'tools': [
                    {
                      'name': 'remote_stop_bot',
                      'mutating': true,
                      'inputSchema': {
                        'type': 'object',
                        'properties': {
                          'bot_id': {
                            'type': 'string',
                            'minLength': 1,
                            'maxLength': 200,
                          },
                        },
                        'required': ['bot_id'],
                        'additionalProperties': false,
                      },
                    },
                  ],
                };
              case '/gateway/bots':
                result = {'bots': []};
              case '/gateway/ai/wallet':
                result = {
                  'balance': 100000,
                  'reserved': 0,
                  'available': 100000,
                };
              case '/gateway/ai/conversations':
                if (request.method == 'GET') {
                  result = {'conversations': []};
                } else {
                  conversation = {
                    'id': 'c',
                    'title': 'Test',
                    'bot_id': '',
                    'location': 'global',
                    'archived': false,
                    'revision': 0,
                    'active_key': '',
                    'messages': <dynamic>[],
                    'actions': <dynamic>[],
                    'consumed_tokens': 0,
                  };
                  result = conversation;
                }
              case '/gateway/ai/conversations/c':
                result = conversation;
              case '/gateway/ai/conversations/c/turns':
                rounds++;
                final body = jsonDecode(request.body) as Map;
                key = body['idempotency_key'] as String;
                conversation!['revision'] = rounds * 2;
                conversation!['active_key'] = '';
                if (rounds == 1) {
                  conversation!['messages'] = [
                    {'role': 'user', 'content': body['prompt']},
                    {
                      'role': 'assistant',
                      'content': '**Proposition**',
                      'tool_calls': [action['call']],
                    },
                  ];
                  conversation!['actions'] = [action];
                } else {
                  (conversation!['messages'] as List).add({
                    'role': 'assistant',
                    'content': allow ? 'Bot stopped' : 'Action cancelled',
                  });
                }
                result = {'request_key': key};
              case '/gateway/ai/conversations/c/actions/stop-call':
                final body = jsonDecode(request.body) as Map;
                if (body['approve'] == true) {
                  stops++;
                  action['state'] = 'succeeded';
                } else {
                  action['state'] = 'declined';
                }
                (conversation!['messages'] as List).add({
                  'role': 'tool',
                  'tool_call_id': 'stop-call',
                  'content': 'confirmed',
                });
                result = {'state': action['state']};
              default:
                if (request.url.path.endsWith('/events')) {
                  return http.Response(
                    'id: 1\nevent: delta\ndata: {"text":"**Proposition**"}\n\nid: 2\nevent: completed\ndata: {"consumed_tokens":30}\n\n',
                    200,
                    headers: {'content-type': 'text/event-stream'},
                  );
                }
                throw StateError('Unexpected ${request.url.path}');
            }
            return http.Response(
              jsonEncode(result),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CopilotPage(api: api),
          ),
        );
        await settle(tester);
        for (
          var i = 0;
          i < 100 &&
              tester.widget<TextField>(find.byType(TextField).first).enabled !=
                  true;
          i++
        ) {
          await settle(tester);
        }
        expect(
          tester.widget<TextField>(find.byType(TextField).first).enabled,
          true,
          reason: tester
              .widgetList<Text>(find.byType(Text))
              .map((t) => t.data)
              .join(' | '),
        );
        expect(
          tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
              .onPressed,
          isNull,
        );
        await tester.enterText(find.byType(TextField).first, 'Stop the bot');
        await tester.pump();
        expect(
          tester
              .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
              .onPressed,
          isNotNull,
        );
        await tester.tap(find.byIcon(Icons.send));
        await settle(tester);
        expect(
          find.text('Validation requise'),
          findsNothing,
        ); // English locale uses the localized approval state.
        expect(find.text('Approval required'), findsOneWidget);
        await tester.ensureVisible(find.text(allow ? 'Approve' : 'Decline'));
        await settle(tester);
        await tester.tap(find.text(allow ? 'Approve' : 'Decline'));
        await settle(tester);
        if (allow) {
          expect(find.text('Approve copilot action'), findsOneWidget);
          await tester.tap(find.text('Execute'));
          await settle(tester);
        }
        expect(stops, allow ? 1 : 0);
        expect(rounds, 2);
        expect(
          find.text(allow ? 'Bot stopped' : 'Action cancelled'),
          findsOneWidget,
        );
        List<String> visibleOrder() {
          final list = tester.widget<ListView>(find.byType(ListView).first);
          return (list.childrenDelegate as SliverChildListDelegate).children
              .map((child) => child.key?.toString() ?? '')
              .toList();
        }

        var order = visibleOrder();
        expect(
          order.indexOf("[<'message-1'>]"),
          lessThan(order.indexOf("[<'action-stop-call'>]")),
        );
        expect(
          order.indexOf("[<'action-stop-call'>]"),
          lessThan(order.indexOf("[<'message-3'>]")),
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CopilotPage(api: api, initialConversationId: 'c'),
          ),
        );
        await settle(tester);
        order = visibleOrder();
        expect(
          order.indexOf("[<'message-1'>]"),
          lessThan(order.indexOf("[<'action-stop-call'>]")),
        );
        expect(
          order.indexOf("[<'action-stop-call'>]"),
          lessThan(order.indexOf("[<'message-3'>]")),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Markdown renders formatted text and wide code at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: CopilotMarkdown(
              content:
                  '# Title\n\n**Bold**\n\n| A | B |\n|---|---|\n| 1 | 2 |\n\n```dart\nfinal longVariable = "very long line that needs horizontal scrolling without overflowing the screen";\n```',
            ),
          ),
        ),
      ),
    );
    expect(find.text('# Title'), findsNothing);
    expect(find.text('Title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}
