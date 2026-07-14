import 'dart:convert';

import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _membersLimited = 1 << 14;

void main() {
  group('fetchPortalIntentsWithOutcome', () {
    test('returns portal intents without auto-enabling', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/applications/@me')) {
          return http.Response(jsonEncode({'flags': _membersLimited}), 200);
        }
        if (request.method == 'PATCH') {
          fail('PATCH should not be called');
        }
        return http.Response('not found', 404);
      });

      final outcome = await fetchPortalIntentsWithOutcome(
        'token',
        client: client,
      );

      expect(outcome.intents['Guilds'], isTrue);
      expect(outcome.intents['Guild Members'], isTrue);
      expect(outcome.missingPrivilegedIntents, {
        'Guild Presence',
        'Message Content',
      });
    });
  });

  group('intentsMapsEqual', () {
    test('compares intent maps by key', () {
      expect(
        intentsMapsEqual({'Guilds': true}, {'Guilds': true}),
        isTrue,
      );
      expect(
        intentsMapsEqual(
          {'Guilds': true, 'Message Content': false},
          {'Guilds': true, 'Message Content': true},
        ),
        isFalse,
      );
    });
  });
}
