import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await MainApiSettingsStore.clearSession();
  });

  test('managed session is detected from auth method', () {
    expect(
      MainApiSession(
        accessToken: 'token',
        expiresAt: _fixedExpiry,
        authMethod: MainApiAuthMethod.discordOauth,
      ).isManagedAccount,
      isTrue,
    );
    expect(
      MainApiSession(
        accessToken: 'token',
        expiresAt: _fixedExpiry,
        authMethod: MainApiAuthMethod.botToken,
      ).isManagedAccount,
      isFalse,
    );
  });

  test('trySaveBotTokenSession does not overwrite managed session', () async {
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'managed-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(days: 1)),
        refreshToken: 'refresh-token',
        authMethod: MainApiAuthMethod.discordOauth,
      ),
    );

    final saved = await MainApiSettingsStore.trySaveBotTokenSession(
      MainApiSession(
        accessToken: 'bot-token-session',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 12)),
        userId: 'owner-1',
      ),
    );

    expect(saved, isFalse);
    final stored = await MainApiSettingsStore.loadSession();
    expect(stored?.accessToken, 'managed-token');
    expect(stored?.authMethod, MainApiAuthMethod.discordOauth);
  });

  test('trySaveBotTokenSession persists when no managed session exists', () async {
    final saved = await MainApiSettingsStore.trySaveBotTokenSession(
      MainApiSession(
        accessToken: 'bot-token-session',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 12)),
        userId: 'owner-1',
      ),
    );

    expect(saved, isTrue);
    final stored = await MainApiSettingsStore.loadSession();
    expect(stored?.accessToken, 'bot-token-session');
    expect(stored?.authMethod, MainApiAuthMethod.botToken);
  });
}

final DateTime _fixedExpiry = DateTime.utc(2030, 1, 1);
