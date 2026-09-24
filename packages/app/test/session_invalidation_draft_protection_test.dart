import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/analytics/user_identity.dart';
import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/auth/presentation/mobile_account_gate_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildTestHost(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: child,
  );
}

class _DraftEditorWidget extends StatefulWidget {
  const _DraftEditorWidget();

  @override
  State<_DraftEditorWidget> createState() => _DraftEditorWidgetState();
}

class _DraftEditorWidgetState extends State<_DraftEditorWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Active Bot Script Draft'),
            Text('Draft value: ${_controller.text}'),
            TextField(
              controller: _controller,
              key: const ValueKey('draft_editor_input'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('session_invalidation_test');
    SecureStorageService.setMockInstance(
      SecureStorageService.createInMemory(storageDir: tempDir.path),
    );
  });

  tearDownAll(() {
    SecureStorageService.setMockInstance(null);
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() async {
    UserIdentity.debugSetSinks(
      UserIdentitySinks(
        setAnalyticsUserId: (_) async {},
        setCrashlyticsUserIdentifier: (_) async {},
        setPosthogUser: (_) async {},
      ),
    );
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    MainApiSettingsStore.invalidateSessionCache();
    await MainApiSettingsStore.clearSession();
    await MainApiSettingsStore.clearConfig();
    MobileAccountGate.debugOverrideIsRequired = true;
  });

  tearDown(() {
    UserIdentity.debugResetForTests();
    MobileAccountGate.debugOverrideIsRequired = null;
  });

  testWidgets(
    'MobileAccountGateShell preserves active editing draft and unmounts nothing when session is revoked',
    (tester) async {
      final validSession = MainApiSession(
        accessToken: 'initial-access-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        refreshToken: 'valid-refresh-token',
        userId: 'user-100',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(validSession);
      await MobileAccountSession.instance.recheck();

      // 2. Launch gate shell with active draft editor
      await tester.pumpWidget(
        _buildTestHost(
          const MobileAccountGateShell(child: _DraftEditorWidget()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the child draft editor is visible
      expect(find.text('Active Bot Script Draft'), findsOneWidget);

      // User types important code into the draft
      await tester.enterText(
        find.byKey(const ValueKey('draft_editor_input')),
        'console.log("critical unsaved automation code");',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 3. Simulate session invalidation (e.g. 401 token revocation from server)
      await MainApiSettingsStore.clearSession();
      await MobileAccountSession.instance.recheck();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The child draft editor is NOT destroyed! It is preserved in the tree.
      // Re-authentication prompt overlay is displayed over the preserved child.
      expect(find.text('Active Bot Script Draft'), findsOneWidget);
      expect(
        find.text(
          'Draft value: console.log("critical unsaved automation code");',
        ),
        findsOneWidget,
      );
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('draft_editor_input')))
            .controller
            ?.text,
        'console.log("critical unsaved automation code");',
      );

      // Re-auth prompt is present
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);

      // 4. User dismisses re-auth overlay to inspect or save draft locally
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Draft remains fully accessible and editable
      expect(
        find.text(
          'Draft value: console.log("critical unsaved automation code");',
        ),
        findsOneWidget,
      );

      // Top reconnect banner is shown
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // 5. User reconnects
      final reconnectedSession = MainApiSession(
        accessToken: 'new-access-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
        refreshToken: 'new-refresh-token',
        userId: 'user-100',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(reconnectedSession);
      await MobileAccountSession.instance.recheck();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Top banner is gone, user is still right in their editor with text intact!
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
      expect(
        find.text(
          'Draft value: console.log("critical unsaved automation code");',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('draft_editor_input')))
            .controller
            ?.text,
        'console.log("critical unsaved automation code");',
      );
    },
  );

  test(
    'MainApiClient proactively restores expiring session before request dispatch',
    () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://manager.test'),
      );

      // Expiring soon (expires in 30 seconds, less than 2 min threshold)
      final expiringSession = MainApiSession(
        accessToken: 'almost-expired-token',
        expiresAt: DateTime.now().toUtc().add(const Duration(seconds: 30)),
        refreshToken: 'valid-refresh-token',
        userId: 'user-200',
        authMethod: MainApiAuthMethod.discordOauth,
      );
      await MainApiSettingsStore.saveSession(expiringSession);

      var refreshCalled = false;
      var botsEndpointCalled = false;
      String? authHeaderUsed;

      final mockHttp = MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          refreshCalled = true;
          return http.Response(
            jsonEncode(<String, dynamic>{
              'token': 'brand-new-fresh-token',
              'refresh_token': 'new-rotated-refresh-token',
              'expires_at': DateTime.now()
                  .toUtc()
                  .add(const Duration(hours: 1))
                  .toIso8601String(),
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path == '/gateway/bots') {
          botsEndpointCalled = true;
          authHeaderUsed = request.headers['authorization'];
          return http.Response(
            jsonEncode(<String, dynamic>{'bots': <dynamic>[]}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('not found', 404);
      });

      final client = MainApiClient(
        baseUrl: 'https://manager.test',
        accessToken: 'almost-expired-token',
        httpClient: mockHttp,
      );

      // Call listBots which requires authentication
      await client.listBots();

      // Verify proactive refresh occurred before calling the endpoint
      expect(refreshCalled, isTrue);
      expect(botsEndpointCalled, isTrue);
      expect(authHeaderUsed, 'Bearer brand-new-fresh-token');
    },
  );
}
