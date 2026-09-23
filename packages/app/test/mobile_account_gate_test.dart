import 'package:bot_creator/core/auth/mobile_account_gate.dart';
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

  test(
    'bot-token session does not satisfy mobile managed account requirement',
    () {
      final session = MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '123',
        authMethod: MainApiAuthMethod.botToken,
      );

      expect(MobileAccountGate.isManagedAccountSession(session), isFalse);
    },
  );

  test(
    'discord oauth session satisfies mobile managed account requirement',
    () {
      final session = MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '123',
        authMethod: MainApiAuthMethod.discordOauth,
      );

      expect(MobileAccountGate.isManagedAccountSession(session), isTrue);
    },
  );

  test(
    'email password session satisfies mobile managed account requirement',
    () {
      final session = MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        userId: '123',
        authMethod: MainApiAuthMethod.emailPassword,
        username: 'Reviewer',
      );

      expect(MobileAccountGate.isEmailPasswordSession(session), isTrue);
      expect(MobileAccountGate.isManagedAccountSession(session), isTrue);
    },
  );

  test('expired email password session is not managed account', () {
    final session = MainApiSession(
      accessToken: 'token',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      userId: '123',
      authMethod: MainApiAuthMethod.emailPassword,
    );

    expect(MobileAccountGate.isEmailPasswordSession(session), isFalse);
    expect(MobileAccountGate.isManagedAccountSession(session), isFalse);
  });

  test('expired discord oauth session with refresh token is refreshable', () {
    final session = MainApiSession(
      accessToken: 'token',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      refreshToken: 'refresh-token',
      userId: '123',
      authMethod: MainApiAuthMethod.discordOauth,
    );

    expect(MobileAccountGate.isDiscordOAuthSession(session), isFalse);
    expect(MobileAccountGate.isRefreshableDiscordOAuthSession(session), isTrue);
    expect(
      MobileAccountGate.isRefreshableManagedAccountSession(session),
      isTrue,
    );
  });

  tearDown(() {
    MobileAccountGate.debugOverrideIsRequired = null;
  });

  test(
    'hasRequiredAccount keeps session satisfied during offline periods if refreshable',
    () async {
      MobileAccountGate.debugOverrideIsRequired = true;
      final session = MainApiSession(
        accessToken: 'expired-access-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        refreshToken: 'persistent-refresh-token',
        userId: '456',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(session);

      final isSatisfied = await MobileAccountGate.hasRequiredAccount();
      // Refreshable session survives offline without prematurely ejecting user
      expect(isSatisfied, isTrue);

      final stored = await MainApiSettingsStore.loadSession();
      expect(stored, isNotNull);
      expect(stored?.refreshToken, 'persistent-refresh-token');
    },
  );

  test(
    'hasRequiredAccount returns false when session is empty on mobile',
    () async {
      MobileAccountGate.debugOverrideIsRequired = true;
      await MainApiSettingsStore.clearSession();

      final isSatisfied = await MobileAccountGate.hasRequiredAccount();
      expect(isSatisfied, isFalse);
    },
  );

  test(
    'hasRequiredAccount returns false when expired session lacks refresh token',
    () async {
      MobileAccountGate.debugOverrideIsRequired = true;
      final session = MainApiSession(
        accessToken: 'expired-access-token',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        userId: '456',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(session);

      final isSatisfied = await MobileAccountGate.hasRequiredAccount();
      expect(isSatisfied, isFalse);
    },
  );
}
