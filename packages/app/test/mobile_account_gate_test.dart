import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await MainApiSettingsStore.clearSession();
  });

  test('bot-token session does not satisfy mobile discord requirement', () async {
    await MainApiSettingsStore.saveBotTokenSession(
      MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '123',
        authMethod: MainApiAuthMethod.botToken,
      ),
    );

    expect(MobileAccountGate.isDiscordOAuthSession(await MainApiSettingsStore.loadSession()), isFalse);
  });

  test('discord oauth session satisfies mobile discord requirement', () async {
    await MainApiSettingsStore.saveDiscordOAuthSession(
      MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '123',
      ),
    );

    expect(MobileAccountGate.isDiscordOAuthSession(await MainApiSettingsStore.loadSession()), isTrue);
  });
}
