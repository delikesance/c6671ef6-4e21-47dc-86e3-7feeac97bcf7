import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    MainApiSettingsStore.invalidateSessionCache();
    await MainApiSettingsStore.clearSession();
    await MainApiSettingsStore.clearConfig();
  });

  test('resolveMainApiClientForBot uses cached session without restore flag',
      () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'cached-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
        refreshToken: 'refresh-token',
        authMethod: MainApiAuthMethod.discordOauth,
      ),
    );

    final helper = MainApiOwnerSyncHelper(
      resolveRuntime: ({getTimeout = const Duration(seconds: 30), postTimeout = const Duration(seconds: 90)}) async {
        throw UnimplementedError();
      },
      loadLocalBotById: (botId) async => const {},
      log: (_) {},
    );

    final client = await helper.resolveMainApiClientForBot(
      botId: '123',
      attemptSessionRestore: false,
    );

    expect(client, isNotNull);
  });

  test('resolveMainApiClientForBot skips network when restore disabled and no session',
      () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );

    final helper = MainApiOwnerSyncHelper(
      resolveRuntime: ({getTimeout = const Duration(seconds: 30), postTimeout = const Duration(seconds: 90)}) async {
        throw UnimplementedError();
      },
      loadLocalBotById: (botId) async => {'token': 'bot-token'},
      log: (_) {},
    );

    final client = await helper.resolveMainApiClientForBot(
      botId: '123',
      attemptSessionRestore: false,
    );

    expect(client, isNull);
  });
}
