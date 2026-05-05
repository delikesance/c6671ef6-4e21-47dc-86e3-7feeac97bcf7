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
}
