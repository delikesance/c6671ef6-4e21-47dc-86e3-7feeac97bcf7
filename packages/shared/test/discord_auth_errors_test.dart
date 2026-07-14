import 'package:bot_creator_shared/utils/discord_auth_errors.dart';
import 'package:test/test.dart';

void main() {
  group('isDiscordGatewayDisallowedIntents', () {
    test('detects 4014 in disconnect reason', () {
      expect(
        isDiscordGatewayDisallowedIntents(
          null,
          'Shard 0 disconnected (code=4014)',
        ),
        isTrue,
      );
    });

    test('detects disallowed intent message', () {
      expect(
        isDiscordGatewayDisallowedIntents(null, 'Used disallowed intents'),
        isTrue,
      );
    });
  });

  group('formatGatewayDisconnectMessage', () {
    test('returns actionable message for 4014', () {
      expect(
        formatGatewayDisconnectMessage('code=4014 disallowed'),
        contains('Disallowed intents (4014)'),
      );
    });
  });

  group('isDiscordTokenUnauthorized', () {
    test('does not treat 4014 as token unauthorized', () {
      expect(
        isDiscordTokenUnauthorized(
          Exception('Shard disconnected code=4014 disallowed intents'),
        ),
        isFalse,
      );
    });

    test('still treats authentication failures as unauthorized', () {
      expect(
        isDiscordTokenUnauthorized(
          Exception('Gateway disconnected code=4004 authentication failed'),
        ),
        isTrue,
      );
    });
  });
}
