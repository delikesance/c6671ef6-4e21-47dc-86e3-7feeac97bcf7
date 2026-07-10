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
}
