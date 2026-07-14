import 'dart:convert';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/utils/application_intent_sync.dart';
import 'package:bot_creator_shared/utils/discord_auth_errors.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

const _membersLimited = 1 << 14;
const _presenceLimited = 1 << 12;
const _messageContentLimited = 1 << 18;

void main() {
  group('portalEnabledPrivilegedIntentsFromFlags', () {
    test('returns empty set when no privileged flags are set', () {
      expect(portalEnabledPrivilegedIntentsFromFlags(0), isEmpty);
    });

    test('detects limited and full privileged flags', () {
      final enabled = portalEnabledPrivilegedIntentsFromFlags(
        _membersLimited | (1 << 13) | (1 << 19),
      );

      expect(enabled, {
        'Guild Members',
        'Guild Presence',
        'Message Content',
      });
    });
  });

  group('buildPortalIntentsMapFromPrivileged', () {
    test('enables Guilds baseline and privileged keys from portal set', () {
      final map = buildPortalIntentsMapFromPrivileged({'Message Content'});

      expect(map['Guilds'], isTrue);
      expect(map['Message Content'], isTrue);
      expect(map['Guild Members'], isNull);
      expect(map['Guild Messages'], isNull);
    });
  });

  group('fetchPortalEnabledPrivilegedIntents', () {
    test('reads portal flags without PATCHing', () async {
      var patchCalled = false;
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/applications/@me')) {
          return http.Response(jsonEncode({'flags': _membersLimited}), 200);
        }
        if (request.method == 'PATCH') {
          patchCalled = true;
        }
        return http.Response('not found', 404);
      });

      final result = await fetchPortalEnabledPrivilegedIntents(
        'token',
        client: client,
      );

      expect(patchCalled, isFalse);
      expect(result.enabled, {'Guild Members'});
      expect(result.didAutoEnable, isFalse);
    });

    test('throws DiscordTokenUnauthorizedException on unauthorized application fetch',
        () async {
      final client = MockClient((request) async {
        return http.Response('unauthorized', 401);
      });

      expect(
        () => fetchPortalEnabledPrivilegedIntents('token', client: client),
        throwsA(isA<DiscordTokenUnauthorizedException>()),
      );
    });
  });

  group('buildEffectiveIntentsMap', () {
    test('enables only Guilds when no workflows require more intents', () {
      final config = BotConfig.fromJson({
        'builtInLegacyHelpEnabled': false,
      });
      final effective = buildEffectiveIntentsMap(
        config: config,
        portalEnabledPrivileged: const {},
      );

      expect(effective['Guilds'], isTrue);
      expect(effective['Guild Messages'], isFalse);
    });
  });

  group('buildGatewayIntents', () {
    test('builds bitmask from effective map instead of allUnprivileged', () {
      final intents = buildGatewayIntents({
        'Guilds': true,
        'Guild Messages': true,
      });

      expect(intents.has(GatewayIntents.guilds), isTrue);
      expect(intents.has(GatewayIntents.guildMessages), isTrue);
      expect(intents.has(GatewayIntents.guildMessageTyping), isFalse);
    });
  });
}
