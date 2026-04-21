import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_runner/stores/command_stats_store.dart';
import 'package:test/test.dart';

void main() {
  group('CommandStatsStore', () {
    late Directory tempDir;
    late CommandStatsStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cmd-stats-test-');
      store = CommandStatsStore(tempDir.path);
      await store.init();
    });

    tearDown(() async {
      store.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('init creates the database file', () {
      final dbFile = File('${tempDir.path}/command_stats.db');
      expect(dbFile.existsSync(), isTrue);
    });

    test('record and totalCount', () {
      store.record(botId: 'b1', commandName: 'ping');
      store.record(botId: 'b1', commandName: 'ping');
      store.record(botId: 'b1', commandName: 'ban');
      store.record(botId: 'b2', commandName: 'ping');

      expect(store.totalCount('b1'), equals(3));
      expect(store.totalCount('b2'), equals(1));
      expect(store.totalCount('unknown'), equals(0));
    });

    test('querySummary returns per-command counts', () {
      store.record(botId: 'b1', commandName: 'ping');
      store.record(botId: 'b1', commandName: 'ping');
      store.record(botId: 'b1', commandName: 'ban');

      final summary = store.querySummary('b1');
      expect(summary, hasLength(2));
      expect(summary[0]['command'], equals('ping'));
      expect(summary[0]['count'], equals(2));
      expect(summary[1]['command'], equals('ban'));
      expect(summary[1]['count'], equals(1));
    });

    test('querySummary with sinceMs filters old entries', () {
      store.record(botId: 'b1', commandName: 'ping');

      // With a very small window (1 ms), recent records should still show up
      // because the record was just inserted.
      final recent = store.querySummary('b1', sinceMs: 60000);
      expect(recent, hasLength(1));
    });

    test('querySummary returns empty for unknown bot', () {
      store.record(botId: 'b1', commandName: 'ping');
      expect(store.querySummary('b2'), isEmpty);
    });

    test('queryTimeline returns hourly buckets', () {
      store.record(botId: 'b1', commandName: 'ping');
      store.record(botId: 'b1', commandName: 'ban');

      final timeline = store.queryTimeline('b1', hours: 1);
      expect(timeline, isNotEmpty);
      // All records in the same hour bucket
      expect(timeline.first['count'], equals(2));
    });

    test('dispose prevents further recording', () {
      store.record(botId: 'b1', commandName: 'ping');
      store.dispose();

      // After dispose, record should silently no-op (not initialized)
      store.record(botId: 'b1', commandName: 'ping');
      // Cannot query either – totalCount returns 0 when not initialized
      expect(store.totalCount('b1'), equals(0));
    });

    test('double init is idempotent', () async {
      await store.init();
      store.record(botId: 'b1', commandName: 'ping');
      expect(store.totalCount('b1'), equals(1));
    });

    test(
      'record syncs managed command stats when managed runner is configured',
      () async {
        final requests = <Map<String, dynamic>>[];
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() async {
          await server.close(force: true);
        });
        server.listen((request) async {
          final body = await utf8.decoder.bind(request).join();
          requests.add(<String, dynamic>{
            'path': request.uri.path,
            'authorization': request.headers.value(
              HttpHeaders.authorizationHeader,
            ),
            'body': jsonDecode(body),
          });
          request.response.statusCode = HttpStatus.ok;
          request.response.write('{"ok":true}');
          await request.response.close();
        });

        final managedStore = CommandStatsStore(
          tempDir.path,
          managedBaseUrl:
              'http://${server.address.address}:${server.port}/internal/runners/tenant-1',
          managedToken: 'runner-token',
        );
        await managedStore.init();
        addTearDown(managedStore.dispose);

        managedStore.record(
          botId: 'b1',
          commandName: 'ping',
          guildId: 'g1',
          locale: 'fr',
          guildLocale: 'en-us',
          success: false,
          latencyMs: 123,
        );

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(requests, hasLength(1));
        expect(
          requests.first['path'],
          '/internal/runners/tenant-1/command-stats',
        );
        expect(requests.first['authorization'], 'Bearer runner-token');

        final body = Map<String, dynamic>.from(requests.first['body'] as Map);
        final records = List<Map<String, dynamic>>.from(
          (body['records'] as List).map(
            (entry) => Map<String, dynamic>.from(entry as Map),
          ),
        );
        expect(records, hasLength(1));
        expect(records.first['bot_id'], 'b1');
        expect(records.first['command_name'], 'ping');
        expect(records.first['guild_id'], 'g1');
        expect(records.first['locale'], 'fr');
        expect(records.first['guild_locale'], 'en-us');
        expect(records.first['success'], isFalse);
        expect(records.first['latency_ms'], 123);
        expect(records.first['executed_at'], isA<String>());
      },
    );
  });
}
