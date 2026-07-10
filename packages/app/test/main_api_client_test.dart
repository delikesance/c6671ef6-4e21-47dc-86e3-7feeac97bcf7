import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'manager command stats uses the gateway command-stats endpoint',
    () async {
      final requestedUris = <Uri>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          requestedUris.add(request.url);
          return http.Response(
            '''
          {
            "botId":"bot-1",
            "hours":168,
            "totalAllTime":4,
            "commands":[],
            "timeline":[],
            "locales":[],
            "health":{
              "total":0,
              "failed":0,
              "errorRatePct":0,
              "p50LatencyMs":0,
              "p95LatencyMs":0
            }
          }
          ''',
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      final stats = await client.getCommandStats('bot-1', hours: 168);

      expect(requestedUris, hasLength(1));
      expect(requestedUris.single.path, '/gateway/bots/bot-1/command-stats');
      expect(requestedUris.single.queryParameters['hours'], '168');
      expect(stats['botId'], 'bot-1');
      expect(stats['hours'], 168);
      expect(stats['totalAllTime'], 4);
    },
  );

  test(
    'getStatus uses runner proxy status instead of funding session',
    () async {
      final requestedUris = <Uri>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          requestedUris.add(request.url);
          if (request.url.path.endsWith('/status')) {
            return http.Response(
              '{"apiVersion":2,"bot":{"botId":"bot-1","state":"running"}}',
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 404);
        }),
      );

      final status = await client.getStatus(botId: 'bot-1');

      expect(requestedUris, hasLength(1));
      expect(requestedUris.single.path, '/gateway/bots/bot-1/status');
      expect(status.isBotRunning('bot-1'), isTrue);
    },
  );

  test(
    'getStatus returns stopped when runner proxy status is unavailable',
    () async {
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          return http.Response('not found', 404);
        }),
      );

      final status = await client.getStatus(botId: 'bot-1');

      expect(status.isBotRunning('bot-1'), isFalse);
    },
  );

  test('refreshSession parses manager auth payload', () async {
    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/auth/refresh');
        return http.Response(
          '''
          {
            "token": "new-access-token",
            "refresh_token": "new-refresh-token",
            "expires_at": "2030-01-01T00:00:00Z",
            "owner_id": "owner-1",
            "user": {
              "id": "owner-1",
              "username": "owner-one"
            }
          }
          ''',
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    final session = await client.refreshSession(refreshToken: 'old-refresh-token');

    expect(session.accessToken, 'new-access-token');
    expect(session.refreshToken, 'new-refresh-token');
    expect(session.userId, 'owner-1');
    expect(session.username, 'owner-one');
    expect(session.expiresAt, DateTime.utc(2030, 1, 1));
  });
}
