import 'dart:convert';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final allow in [false, true]) {
    testWidgets(
      'remote action ${allow ? 'runs after approval' : 'does not run after cancellation'}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        rootBundle.evict('assets/copilot/tools.json');
        var replies = 0;
        var stops = 0;
        final api = MainApiClient(
          baseUrl: 'https://manager.example',
          accessToken: 'signed-user',
          httpClient: MockClient((request) async {
            Object result;
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
              case '/gateway/ai/wallet':
                result = {'balance': 100000, 'available': 100000};
              case '/gateway/ai/copilot/reply':
                final body = jsonDecode(request.body) as Map;
                replies++;
                if (replies == 1) {
                  result = {
                    'idempotency_key': body['idempotency_key'],
                    'message': {
                      'role': 'assistant',
                      'content': '',
                      'tool_calls': [
                        {
                          'id': 'stop-call',
                          'type': 'function',
                          'function': {
                            'name': 'remote_stop_bot',
                            'arguments': jsonEncode({
                              'bot_id': '123456789012345',
                            }),
                          },
                        },
                      ],
                    },
                  };
                } else {
                  final messages = body['messages'] as List;
                  expect(messages.last['role'], 'tool');
                  if (!allow) {
                    expect(messages.last['content'], contains('cancelled'));
                  }
                  result = {
                    'message': {
                      'role': 'assistant',
                      'content': allow ? 'Bot stopped' : 'Action cancelled',
                    },
                  };
                }
              case '/gateway/bots/123456789012345/stop':
                stops++;
                result = {'ok': true};
              default:
                throw StateError('Unexpected ${request.url.path}');
            }
            return http.Response(jsonEncode(result), 200);
          }),
        );
        await tester.pumpWidget(MaterialApp(home: CopilotPage(api: api)));
        for (
          var i = 0;
          i < 30 &&
              tester.widget<TextField>(find.byType(TextField)).enabled != true;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          tester.widget<TextField>(find.byType(TextField)).enabled,
          isTrue,
        );
        expect(find.textContaining('100000'), findsOneWidget);
        expect(
          find.byIcon(Icons.token),
          findsNothing,
        ); // Desktop: no reward/purchase entry.
        await tester.enterText(find.byType(TextField), 'Stop my remote bot');
        await tester.tap(find.byIcon(Icons.send));
        for (
          var i = 0;
          i < 30 && find.byType(AlertDialog).evaluate().isEmpty;
          i++
        ) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(stops, 0);
        await tester.tap(find.text(allow ? 'Execute' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(stops, allow ? 1 : 0);
        expect(replies, 2);
        expect(
          find.text(allow ? 'Bot stopped' : 'Action cancelled'),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
