import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await MainApiSettingsStore.clearSession();
    await MainApiSettingsStore.clearConfig();
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
