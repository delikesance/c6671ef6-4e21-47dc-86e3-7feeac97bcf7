import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'in-flight GET resumes silently without approval or duplicate execution',
    (tester) async {
      final read = {
        'call_id': 'read',
        'request_key': 'first',
        'state': 'executing',
        'call': {
          'id': 'read',
          'type': 'function',
          'function': {'name': 'remote_list_bots', 'arguments': '{}'},
        },
      };
      final chat = _chat()
        ..['actions'] = [read]
        ..['messages'] = [
          {'role': 'user', 'content': 'Check status'},
          {
            'role': 'assistant',
            'content': '',
            'tool_calls': [read['call']],
          },
        ];
      var fetches = 0, continuations = 0;
      final api = _api(chat, (request) async {
        if (request.url.path == '/gateway/ai/conversations/c') {
          fetches++;
          if (fetches == 3) {
            read['state'] = 'succeeded';
            (chat['messages'] as List).add({
              'role': 'tool',
              'content': '{}',
              'tool_call_id': 'read',
            });
          }
          return _json(chat);
        }
        if (request.url.path.endsWith('/turns')) {
          continuations++;
          expect((jsonDecode(request.body) as Map)['prompt'], '');
          (chat['messages'] as List).add({
            'role': 'assistant',
            'content': 'Status checked',
          });
          return _json({'request_key': 'continued'});
        }
        if (request.url.path.endsWith('/events')) {
          return _events('event: completed\ndata: {}\n\n');
        }
        if (request.url.path.contains('/actions/')) {
          fail('An in-flight GET must not be claimed or executed again');
        }
        return null;
      });
      await _mount(tester, api, initialConversationId: 'c');
      expect(find.text('Inspect bot'), findsNothing);
      expect(find.text('Technical details'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await _settle(tester);
      expect(continuations, 1);
      expect(find.text('Status checked'), findsOneWidget);
      expect(find.text('Inspect bot'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final readState in ['pending', 'uncertain']) {
    testWidgets(
      'GET actions stay invisible and resume automatically on reopen ($readState)',
      (tester) async {
        final read = {
          'call_id': 'read',
          'request_key': 'first',
          'state': readState,
          'call': {
            'id': 'read',
            'type': 'function',
            'function': {'name': 'remote_list_bots', 'arguments': '{}'},
          },
        };
        final mutation = {
          'call_id': 'stop',
          'request_key': 'second',
          'state': 'pending',
          'call': {
            'id': 'stop',
            'type': 'function',
            'function': {
              'name': 'remote_stop_bot',
              'arguments': '{"bot_id":"123456789012345"}',
            },
          },
        };
        final chat = _chat()
          ..['messages'] = [
            {'role': 'user', 'content': 'Check the bot'},
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [read['call']],
            },
            {
              'role': 'assistant',
              'content': '',
              'tool_calls': [mutation['call']],
            },
          ]
          ..['actions'] = [read, mutation];
        final accepted = Completer<http.Response>();
        var reads = 0;
        final api = _api(chat, (request) async {
          if (request.url.path.endsWith('/actions/read')) {
            reads++;
            expect(
              jsonDecode(request.body),
              readState == 'pending'
                  ? {'approve': true}
                  : {
                      'state': 'failed',
                      'result': {
                        'isError': true,
                        'message': 'Read interrupted.',
                      },
                    },
            );
            if (readState == 'pending') read['state'] = 'executing';
            return accepted.future;
          }
          return null;
        });
        await _mount(
          tester,
          api,
          initialConversationId: 'c',
          size: const Size(320, 800),
          textScale: 1.5,
        );
        expect(reads, 1);
        expect(find.text('Inspect bot'), findsNothing);
        expect(find.text('Technical details'), findsNothing);
        expect(find.text('Copilot'), findsNothing);
        expect(find.text('Stop bot'), findsOneWidget);
        expect(find.text('Approval required'), findsOneWidget);

        read['state'] = readState == 'pending' ? 'succeeded' : 'failed';
        read['result'] = {
          'content': [
            {'text': 'private tool result'},
          ],
        };
        accepted.complete(_json({'state': 'succeeded'}));
        await _settle(tester);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('action-stop')),
          150,
          scrollable: find
              .descendant(
                of: find.byType(ListView).first,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(reads, 1);
        expect(find.text('Inspect bot'), findsNothing);
        expect(find.text('private tool result'), findsNothing);
        expect(find.text('Technical details'), findsNothing);
        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Decline'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'wallet amounts remain complete on one line at 320px enlarged text',
    (tester) async {
      final api = _api(_chat(), (request) async {
        if (request.url.path.endsWith('/wallet')) {
          return _json({
            'available': 9709575,
            'reserved': 290425,
            'balance': 10000000,
          });
        }
        return null;
      });
      await _mount(tester, api, size: const Size(320, 900), textScale: 1.5);

      for (final amount in ['9,710']) {
        final found = find.text(amount);
        expect(found, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(found);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: amount.length),
        );
        expect(boxes, hasLength(1), reason: '$amount must remain on one line');
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          boxes.single.right,
          lessThanOrEqualTo(paragraph.size.width + .1),
          reason: '$amount must not be clipped',
        );
        expect(paragraph.textScaler.scale(10), 15);
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final height in [900.0, 640.0]) {
    testWidgets('conversation credits wrap at 320x$height with enlarged text', (
      tester,
    ) async {
      final chat = _chat()..['consumed_tokens'] = 987654321;
      await _mount(
        tester,
        _api(chat, (_) async => null),
        initialConversationId: 'c',
        size: Size(320, height),
        textScale: 1.5,
        keyboardInset: height == 640 ? 200 : 0,
      );
      await _settle(tester);

      expect(find.textContaining('credits left'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('summary retries original prompt while preserving next draft', (
    tester,
  ) async {
    final summarized = Completer<http.Response>();
    final chat = _chat();
    final prompts = <String>[];
    final api = _api(chat, (request) async {
      if (request.url.path.endsWith('/turns')) {
        prompts.add((jsonDecode(request.body) as Map)['prompt'] as String);
        if (prompts.length == 1) {
          return http.Response('{"code":"ai_context_limit"}', 400);
        }
        return _json({'request_key': 'turn'});
      }
      if (request.url.path.endsWith('/summarize')) return summarized.future;
      if (request.url.path.endsWith('/events')) {
        return _events('event: completed\ndata: {}\n\n');
      }
      return null;
    });
    await _mount(tester, api);
    await _send(tester, 'Original work');
    await tester.enterText(find.byType(TextField).first, 'Next draft');
    chat['revision'] = 2;
    summarized.complete(_json({'request_key': 'summary'}));
    await _settle(tester);

    expect(prompts, ['Original work', 'Original work']);
    expect(_draft(tester), 'Next draft');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unknown acceptance retries same key and preserves edited draft',
    (tester) async {
      final chat = _chat();
      final requests = <Map>[];
      final api = _api(chat, (request) async {
        if (request.url.path.endsWith('/turns')) {
          requests.add(jsonDecode(request.body) as Map);
          if (requests.length == 1) return http.Response('{}', 500);
          return _json({'request_key': requests.last['idempotency_key']});
        }
        if (request.url.path.endsWith('/events')) {
          return _events('event: completed\ndata: {}\n\n');
        }
        return null;
      });
      await _mount(tester, api);
      await _send(tester, 'Original work');
      await tester.enterText(find.byType(TextField).first, 'Next draft');
      await tester.pump();
      expect(find.byTooltip('Retry pending request'), findsOneWidget);
      expect(find.byIcon(Icons.send), findsNothing);
      await tester.tap(find.byIcon(Icons.replay_rounded));
      await _settle(tester);

      expect(requests, hasLength(2));
      expect(requests[1], requests[0]);
      expect(_draft(tester), 'Next draft');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revision conflict refreshes pending revision before explicit retry',
    (tester) async {
      final chat = _chat();
      final requests = <Map>[];
      final api = _api(chat, (request) async {
        if (request.url.path.endsWith('/turns')) {
          requests.add(jsonDecode(request.body) as Map);
          if (requests.length == 1) {
            chat['revision'] = 5;
            return http.Response('{"code":"ai_revision_conflict"}', 409);
          }
          return _json({'request_key': requests.last['idempotency_key']});
        }
        if (request.url.path.endsWith('/events')) {
          return _events('event: completed\ndata: {}\n\n');
        }
        return null;
      });
      await _mount(tester, api);
      await _send(tester, 'Original work');
      await tester.tap(find.byIcon(Icons.send));
      await _settle(tester);

      expect(requests, hasLength(2));
      expect(requests[1]['revision'], 5);
      expect(
        requests[1]['idempotency_key'],
        isNot(requests[0]['idempotency_key']),
      );
      expect(requests[1]['prompt'], 'Original work');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('automatic summary stops after one attempt and preserves draft', (
    tester,
  ) async {
    final chat = _chat();
    var turns = 0, summaries = 0;
    final api = _api(chat, (request) async {
      if (request.url.path.endsWith('/turns')) {
        turns++;
        return http.Response('{"code":"ai_context_limit"}', 400);
      }
      if (request.url.path.endsWith('/summarize')) {
        summaries++;
        chat['revision'] = 2;
        return _json({'request_key': 'summary'});
      }
      if (request.url.path.endsWith('/events')) {
        return _events('event: completed\ndata: {}\n\n');
      }
      return null;
    });
    await _mount(tester, api);
    await _send(tester, 'Keep my work');

    expect(turns, 2);
    expect(summaries, 1);
    expect(find.byType(AlertDialog), findsNothing);
    expect(_draft(tester), 'Keep my work');
    expect(find.textContaining('Context too long'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'server compaction keeps one turn and restores durable completion',
    (tester) async {
      final chat = _chat();
      var turns = 0, summaries = 0;
      final api = _api(chat, (request) async {
        if (request.url.path.endsWith('/turns')) {
          turns++;
          chat['last_request_key'] =
              (jsonDecode(request.body) as Map)['idempotency_key'];
          chat['last_request_status'] = 'completed';
          chat['context_summary'] = 'The earlier bot configuration';
          chat['revision'] = 2;
          chat['messages'] = [
            {'role': 'user', 'content': 'Continue my work'},
            {'role': 'assistant', 'content': 'Configuration retained'},
          ];
          return _json({'request_key': chat['last_request_key']});
        }
        if (request.url.path.endsWith('/summarize')) summaries++;
        if (request.url.path.endsWith('/events')) {
          // Simulate recovery after the final SSE event was lost. The persisted
          // request is completed, so no second generation should be started.
          return _events(
            'id: 1\nevent: summarizing\ndata: {"phase":"started"}\n\n'
            'id: 2\nevent: summarizing\ndata: {"phase":"completed"}\n\n'
            'id: 3\nevent: delta\ndata: {"text":"Configuration retained"}\n\n',
          );
        }
        return null;
      });
      await _mount(tester, api);
      await _send(tester, 'Continue my work');

      expect(turns, 1);
      expect(summaries, 0);
      expect(find.text('Configuration retained'), findsOneWidget);
      // The summary is model-only context: it is never shown to the user.
      expect(find.text('Summarized context'), findsNothing);
      expect(_draft(tester), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accepted turn after disposal does not touch disposed controllers',
    (tester) async {
      final accepted = Completer<http.Response>();
      var turns = 0;
      final api = _api(_chat(), (request) async {
        if (request.url.path.endsWith('/turns')) {
          turns++;
          return accepted.future;
        }
        return null;
      });
      await _mount(tester, api);
      await _send(tester, 'Persist this draft');
      expect(turns, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      accepted.complete(_json({'request_key': 'turn'}));
      await _settle(tester);

      expect(tester.takeException(), isNull);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().any(
          (key) => prefs.getString(key) == 'Persist this draft',
        ),
        isTrue,
      );
    },
  );

  testWidgets('late opened conversation cannot replace a new global context', (
    tester,
  ) async {
    final opened = Completer<http.Response>();
    final chat = _chat()
      ..['messages'] = [
        {'role': 'assistant', 'content': 'Stale bot context'},
      ];
    var reads = 0;
    final api = _api(chat, (request) async {
      if (request.url.path == '/gateway/ai/conversations/c') {
        reads++;
        return opened.future;
      }
      return null;
    });
    await _mount(tester, api, initialConversationId: 'c');
    expect(reads, 1);
    await tester.tap(find.byIcon(Icons.edit_square));
    await _settle(tester);
    opened.complete(_json(chat));
    await _settle(tester);

    expect(find.text('Stale bot context'), findsNothing);
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).enabled,
      isTrue,
    );
  });

  testWidgets('history can close while archive filter response is pending', (
    tester,
  ) async {
    final filtered = Completer<http.Response>();
    var reads = 0;
    final api = _api(_chat(), (request) async {
      if (request.url.path == '/gateway/ai/conversations' &&
          request.method == 'GET') {
        reads++;
        if (reads > 1) return filtered.future;
      }
      return null;
    });
    await _mount(tester, api);
    await tester.tap(find.byIcon(Icons.history_rounded));
    await _settle(tester);
    await tester.tap(find.byType(SwitchListTile));
    await _settle(tester);
    Navigator.of(tester.element(find.byType(SwitchListTile))).pop();
    await _settle(tester);
    filtered.complete(_json({'conversations': []}));
    await _settle(tester);

    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _chat() => {
  'id': 'c',
  'title': 'Test',
  'bot_id': '',
  'location': 'global',
  'revision': 0,
  'active_key': '',
  'archived': false,
  'messages': <dynamic>[],
  'actions': <dynamic>[],
  'consumed_tokens': 0,
};

MainApiClient _api(
  Map<String, dynamic> chat,
  Future<http.Response?> Function(http.Request) handler,
) => MainApiClient(
  baseUrl: 'http://localhost',
  accessToken: 'test',
  httpClient: MockClient((request) async {
    final custom = await handler(request);
    if (custom != null) return custom;
    return switch (request.url.path) {
      '/gateway/ai/copilot/tools' => _json({'tools': []}),
      '/gateway/bots' => _json({'bots': []}),
      '/gateway/ai/wallet' => _json({
        'balance': 10000,
        'reserved': 0,
        'available': 10000,
      }),
      '/gateway/ai/conversations' =>
        request.method == 'POST' ? _json(chat) : _json({'conversations': []}),
      '/gateway/ai/conversations/c' => _json(chat),
      _ => throw StateError('Unexpected ${request.url.path}'),
    };
  }),
);

http.Response _json(Object value) => http.Response(
  jsonEncode(value),
  200,
  headers: {'content-type': 'application/json'},
);
http.Response _events(String value) =>
    http.Response(value, 200, headers: {'content-type': 'text/event-stream'});

Future<void> _mount(
  WidgetTester tester,
  MainApiClient api, {
  String? initialConversationId,
  Size size = const Size(900, 1000),
  double textScale = 1,
  double keyboardInset = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboardInset);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({});
  rootBundle.evict('assets/copilot/tools.json');
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: CopilotPage(api: api, initialConversationId: initialConversationId),
    ),
  );
  await _settle(tester);
  for (
    var i = 0;
    i < 100 &&
        tester.widget<TextField>(find.byType(TextField).first).enabled != true;
    i++
  ) {
    await _settle(tester);
  }
  expect(
    tester.widget<TextField>(find.byType(TextField).first).enabled,
    isTrue,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .join(' | '),
  );
}

String _draft(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField).first).controller!.text;
Future<void> _send(WidgetTester tester, String prompt) async {
  await tester.enterText(find.byType(TextField).first, prompt);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
}
