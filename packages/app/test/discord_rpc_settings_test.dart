import 'package:bot_creator/utils/discord_rpc_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  group('DiscordRpcConfig', () {
    test('roundtrips through JSON with fixed application ID', () {
      const config = DiscordRpcConfig(
        enabled: true,
        clientId: '123456789012345678',
        clientSecret: 'super-secret',
        brokerUrl: 'https://auth.example.com',
      );

      final restored = DiscordRpcConfig.fromJson(config.toJson());
      expect(restored.enabled, isTrue);
      expect(restored.clientId, discordRpcFixedApplicationId);
      expect(restored.clientSecret, isEmpty);
      expect(restored.brokerUrl, isEmpty);
    });

    test('stores the built-in application ID', () {
      const config = DiscordRpcConfig(enabled: false);
      final json = config.toJson();

      expect(json['clientId'], discordRpcFixedApplicationId);
      expect(json.containsKey('clientSecret'), isFalse);
      expect(json.containsKey('brokerUrl'), isFalse);
    });
  });

  group('DiscordRpcSession', () {
    test('expiresSoon uses UTC timestamps', () {
      final session = DiscordRpcSession(
        accessToken: 'access',
        sessionToken: 'session',
        expiresAt: DateTime.now().toUtc().add(const Duration(minutes: 1)),
      );

      expect(session.expiresSoon(), isTrue);
      expect(session.isExpired, isFalse);
    });
  });

  group('DiscordRpcSettingsStore', () {
    test('returns empty defaults when nothing is stored', () async {
      final config = await DiscordRpcSettingsStore.loadConfig();
      expect(config.enabled, isFalse);
      expect(config.clientId, discordRpcFixedApplicationId);
      expect(config.clientSecret, isEmpty);
      expect(config.brokerUrl, isEmpty);
      expect(await DiscordRpcSettingsStore.loadSession(), isNull);
    });

    test('persists and restores config with built-in application ID', () async {
      const config = DiscordRpcConfig(
        enabled: true,
        clientId: 'abc',
        clientSecret: 'secret-123',
        brokerUrl: 'https://broker.example.com',
      );

      await DiscordRpcSettingsStore.saveConfig(config);
      final restored = await DiscordRpcSettingsStore.loadConfig();

      expect(restored.enabled, isTrue);
      expect(restored.clientId, discordRpcFixedApplicationId);
      expect(restored.clientSecret, isEmpty);
      expect(restored.brokerUrl, isEmpty);
    });

    test('persists and restores session', () async {
      final session = DiscordRpcSession(
        accessToken: 'access-token',
        sessionToken: 'opaque-session',
        expiresAt: DateTime.utc(2030, 1, 1),
        scopes: const <String>['rpc', 'identify'],
        userId: '42',
        username: 'Tester',
      );

      await DiscordRpcSettingsStore.saveSession(session);
      final restored = await DiscordRpcSettingsStore.loadSession();

      expect(restored, isNotNull);
      expect(restored!.accessToken, 'access-token');
      expect(restored.sessionToken, 'opaque-session');
      expect(restored.scopes, containsAll(const <String>['rpc', 'identify']));
      expect(restored.userId, '42');
      expect(restored.username, 'Tester');
    });

    test('clearAll removes both config and session', () async {
      await DiscordRpcSettingsStore.saveConfig(
        const DiscordRpcConfig(enabled: true, clientId: 'abc'),
      );
      await DiscordRpcSettingsStore.saveSession(
        DiscordRpcSession(
          accessToken: 'access',
          sessionToken: 'session',
          expiresAt: DateTime.utc(2030, 1, 1),
        ),
      );

      await DiscordRpcSettingsStore.clearAll();

      final config = await DiscordRpcSettingsStore.loadConfig();
      expect(config.enabled, isFalse);
      expect(config.clientId, discordRpcFixedApplicationId);
      expect(config.clientSecret, isEmpty);
      expect(config.brokerUrl, isEmpty);
      expect(await DiscordRpcSettingsStore.loadSession(), isNull);
    });
  });
}
