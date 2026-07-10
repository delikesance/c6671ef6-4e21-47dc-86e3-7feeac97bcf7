import 'dart:convert';

import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

const _membersLimited = 1 << 14;
const _presenceLimited = 1 << 12;
const _messageContentLimited = 1 << 18;
const _verifiedBot = 1 << 16;

void main() {
  group('fetchPortalIntentsWithOutcome', () {
    test('returns autoEnabled when privileged intents are patched', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/applications/@me')) {
          return http.Response(jsonEncode({'flags': 0}), 200);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/users/@me')) {
          return http.Response(jsonEncode({'flags': 0}), 200);
        }
        if (request.method == 'PATCH') {
          return http.Response(
            jsonEncode({
              'flags':
                  _membersLimited | _presenceLimited | _messageContentLimited,
            }),
            200,
          );
        }
        return http.Response('not found', 404);
      });

      final outcome = await fetchPortalEnabledPrivilegedIntents(
        'token',
        client: client,
      ).then(
        (result) => PortalIntentFetchOutcome(
          intents: buildPortalIntentsMapFromPrivileged(result.enabled),
          autoEnabled: result.didAutoEnable,
        ),
      );

      expect(outcome.autoEnabled, isTrue);
      expect(hasAllPrivilegedIntents(outcome.intents), isTrue);
    });

    test('maps verified bot auto-enable failure to manual outcome', () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/applications/@me')) {
          return http.Response(jsonEncode({'flags': 0}), 200);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/users/@me')) {
          return http.Response(jsonEncode({'flags': _verifiedBot}), 200);
        }
        return http.Response('not found', 404);
      });

      Future<PortalIntentFetchOutcome> loadOutcome() async {
        try {
          final result = await fetchPortalEnabledPrivilegedIntents(
            'token',
            client: client,
          );
          return PortalIntentFetchOutcome(
            intents: buildPortalIntentsMapFromPrivileged(result.enabled),
            autoEnabled: result.didAutoEnable,
          );
        } on PortalIntentAutoEnableError {
          final privileged = await readPortalEnabledPrivilegedIntents(
            'token',
            client: client,
          );
          return PortalIntentFetchOutcome(
            intents: buildPortalIntentsMapFromPrivileged(privileged),
            verifiedBotManualRequired: true,
          );
        }
      }

      final outcome = await loadOutcome();

      expect(outcome.verifiedBotManualRequired, isTrue);
      expect(outcome.intents['Message Content'], isFalse);
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
