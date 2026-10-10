// Une pub de roulette qui ne s'affiche pas doit rendre son ticket au Manager,
// sinon elle garde l'une des 3 pubs du jour pendant 15 minutes.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('cancelAIRewardTicket envoie DELETE sur le ticket', () async {
    final sent = <http.Request>[];
    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      httpClient: MockClient((request) async {
        sent.add(request);
        return http.Response('', 204);
      }),
    );

    await client.cancelAIRewardTicket('abc/123');

    expect(sent, hasLength(1));
    expect(sent.single.method, 'DELETE');
    expect(sent.single.url.path, '/gateway/ai/rewards/tickets/abc%2F123');
  });
}
