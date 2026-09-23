import 'package:bot_creator/core/network/main_api_session_restore.dart';
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

  test('cached session is returned without refresh when still valid', () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'valid-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
        refreshToken: 'refresh-token',
        authMethod: MainApiAuthMethod.discordOauth,
      ),
    );

    final loaded = await loadMainApiSession();
    final ensured = await loadMainApiSession();

    expect(loaded?.accessToken, 'valid-token');
    expect(ensured?.accessToken, 'valid-token');
  });

  test('expired session without refresh token is cleared on restore', () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'expired-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        authMethod: MainApiAuthMethod.discordOauth,
      ),
    );

    final restored = await restoreMainApiSessionIfNeeded();

    expect(restored, isNull);
    expect(await MainApiSettingsStore.loadSession(), isNull);
  });

  test(
    'transient network failure during refresh preserves stored session without clearing',
    () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://127.0.0.1:54321'),
      );
      final expiredSession = MainApiSession(
        accessToken: 'expired-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        refreshToken: 'persistent-refresh-token',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(expiredSession);

      // restore attempts to connect to 127.0.0.1:54321, fails with connection error
      final restored = await restoreMainApiSessionIfNeeded(
        timeout: const Duration(milliseconds: 200),
      );

      // Session is NOT wiped! Preserved for offline editing and draft retention
      expect(restored, isNotNull);
      expect(restored?.refreshToken, 'persistent-refresh-token');
      expect(await MainApiSettingsStore.loadSession(), isNotNull);
    },
  );
}
