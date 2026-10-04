// A deletion made on this device must reach the cloud, and a stale cloud copy must never bring the
// deleted bot or command back. Before: a failed cloud deletion was swallowed (the bot returned at
// the next login), and a command whose push failed (offline, expired session, overshrink refusal)
// came back at the next pull.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

MainApiClient _client(
  List<http.Request> sink, {
  bool failing = false,
  Set<String> failingPaths = const {},
}) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    if (failing || failingPaths.any(request.url.path.contains)) {
      return http.Response('{"code":"unavailable"}', 503);
    }
    return http.Response('{}', 200);
  }),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    root = await Directory.systemTemp.createTemp('deletion_queue_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _pathProviderChannel,
          (call) async => root.path,
        );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    try {
      await root.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() => SharedPreferences.setMockInitialValues(const <String, Object>{}));

  test(
    'a bot deletion that fails stays queued and is replayed until it succeeds',
    () async {
      final manager = AppManager();
      await manager.addPendingRemoteBotDeletion('111');
      await manager.addPendingRemoteBotDeletion('222');
      expect(await manager.pendingRemoteBotDeletions(), {'111', '222'});

      final calls = <http.Request>[];
      final stillPending = await manager.retryPendingRemoteBotDeletions(
        _client(calls, failing: true),
      );
      expect(stillPending, {
        '111',
        '222',
      }, reason: 'a failing server keeps both queued');
      expect(await manager.pendingRemoteBotDeletions(), {'111', '222'});

      final ok = await manager.retryPendingRemoteBotDeletions(_client(calls));
      expect(ok, isEmpty);
      expect(await manager.pendingRemoteBotDeletions(), isEmpty);
      expect(
        calls.where((r) => r.method == 'DELETE').map((r) => r.url.path),
        containsAll(['/gateway/bots/111', '/gateway/bots/222']),
      );
    },
  );

  test(
    'replay is partial: only the confirmed deletions leave the queue',
    () async {
      final manager = AppManager();
      await manager.addPendingRemoteBotDeletion('333');
      await manager.addPendingRemoteBotDeletion('444');
      final remaining = await manager.retryPendingRemoteBotDeletions(
        _client([], failingPaths: {'/gateway/bots/444'}),
      );
      expect(remaining, {'444'});
      expect(await manager.pendingRemoteBotDeletions(), {'444'});
      await manager.clearPendingRemoteBotDeletion('444');
    },
  );

  test(
    'a deleted command is filtered out of the cloud copy until the cloud confirms',
    () async {
      final manager = AppManager();
      await manager.recordPendingCommandDeletion('555', 'cmd-a', name: 'warn');
      await manager.recordPendingCommandDeletion('555', 'cmd-b');
      expect(await manager.pendingCommandDeletions('555'), {
        'cmd-a': 'warn',
        'cmd-b': '',
      });

      final remote = <dynamic>[
        {'id': 'cmd-a', 'name': 'warn'},
        {'id': 'cmd-b', 'name': 'ping'},
        {'id': 'cmd-c', 'name': 'help'},
        'not-a-map',
      ];
      final filtered = AppManager.withoutPendingCommandDeletions(
        remote,
        (await manager.pendingCommandDeletions('555')).keys,
      );
      expect(filtered.whereType<Map>().map((c) => c['id']), ['cmd-c']);
      expect(
        filtered,
        contains('not-a-map'),
        reason: 'non-command entries are not touched',
      );
      expect(
        AppManager.withoutPendingCommandDeletions(remote, const []),
        same(remote),
      );

      // A confirmed push clears only what it carried, not a deletion made meanwhile.
      await manager.clearPendingCommandDeletions('555', ids: ['cmd-a']);
      expect(await manager.pendingCommandDeletions('555'), {'cmd-b': ''});
      await manager.clearPendingCommandDeletions('555');
      expect(await manager.pendingCommandDeletions('555'), isEmpty);
    },
  );

  test(
    'command deletions are replayed through the manager and cleared one by one',
    () async {
      final manager = AppManager();
      await manager.recordPendingCommandDeletion('666', 'ok-1');
      await manager.recordPendingCommandDeletion('666', 'bad-2');
      final calls = <http.Request>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          calls.add(request);
          final body = jsonDecode(request.body) as Map;
          return body['commandId'] == 'bad-2'
              ? http.Response('{}', 500)
              : http.Response('{}', 200);
        }),
      );
      final remaining = await manager.retryPendingCommandDeletions(
        '666',
        client,
      );
      expect(remaining, {'bad-2'});
      expect(await manager.pendingCommandDeletions('666'), {'bad-2': ''});
      expect(calls.map((r) => r.url.path).toSet(), {
        '/gateway/bots/666/commands/delete',
      });
      await manager.clearPendingCommandDeletions('666');
    },
  );
}
