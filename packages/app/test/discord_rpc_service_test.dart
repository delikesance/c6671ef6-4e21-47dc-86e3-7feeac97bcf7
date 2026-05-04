import 'dart:async';

import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_client.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test(
    'uses built-in application ID and sends SET_ACTIVITY without OAuth',
    () async {
      final fakeClient = _FakeDiscordRpcClient();
      final service = DiscordRpcService.test(clientFactory: () => fakeClient);

      await service.updateConfig(
        enabled: true,
        clientId: '999999999999999999',
        clientSecret: 'legacy-secret',
        brokerUrl: 'https://legacy.example.com',
      );

      final snapshot = await service.connectIfPossible();

      expect(snapshot.runtimeState, DiscordRpcRuntimeState.connected);
      expect(snapshot.session, isNull);
      expect(snapshot.config.clientId, discordRpcFixedApplicationId);
      expect(fakeClient.connectedClientId, discordRpcFixedApplicationId);
      expect(fakeClient.authorizeCalls, 0);
      expect(fakeClient.authenticateCalls, 0);
      expect(fakeClient.activityPid, isNotNull);
      expect(fakeClient.activity, isNotNull);
      expect(fakeClient.activity!['details'], 'Bot Creator open');
      expect(fakeClient.activity!['state'], 'Desktop ready');

      await service.disconnect(clearSession: false);
    },
  );
}

class _FakeDiscordRpcClient extends DiscordRpcClient {
  _FakeDiscordRpcClient();

  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  bool _isConnected = false;
  bool _isClosed = false;

  String? connectedClientId;
  int authorizeCalls = 0;
  int authenticateCalls = 0;
  int? activityPid;
  Map<String, dynamic>? activity;

  @override
  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  @override
  bool get isConnected => _isConnected;

  @override
  String? get connectedEndpoint => '/tmp/discord-ipc-0';

  @override
  Future<void> connect({required String clientId}) async {
    connectedClientId = clientId;
    _isConnected = true;
  }

  @override
  Future<Map<String, dynamic>> authorize({
    required String clientId,
    required List<String> scopes,
    String? rpcToken,
    String? username,
    String? responseType,
    String? state,
    String? prompt,
    String? codeChallenge,
    String? codeChallengeMethod,
  }) async {
    authorizeCalls += 1;
    return <String, dynamic>{
      'cmd': 'AUTHORIZE',
      'nonce': 'nonce-1',
      'data': <String, dynamic>{'code': 'unused'},
    };
  }

  @override
  Future<Map<String, dynamic>> authenticate(String accessToken) async {
    authenticateCalls += 1;
    return <String, dynamic>{
      'cmd': 'AUTHENTICATE',
      'nonce': 'nonce-2',
      'data': <String, dynamic>{},
    };
  }

  @override
  Future<Map<String, dynamic>> setActivity({
    required int pid,
    required Map<String, dynamic> activity,
  }) async {
    activityPid = pid;
    this.activity = Map<String, dynamic>.from(activity);
    return <String, dynamic>{
      'cmd': 'SET_ACTIVITY',
      'nonce': 'nonce-3',
      'data': null,
    };
  }

  @override
  Future<void> close() async {
    _isConnected = false;
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    await _eventsController.close();
  }
}
