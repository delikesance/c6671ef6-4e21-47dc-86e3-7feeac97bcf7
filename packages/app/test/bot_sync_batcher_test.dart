import 'dart:async';
import 'package:bot_creator/features/bot_editor/logic/bot_sync_batcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('coalesces in-flight edits and runs only the latest follow-up', (
    tester,
  ) async {
    final batcher = BotSyncBatcher();
    final first = Completer<void>();
    final calls = <String>[];
    batcher.requestSync('bot', (_) {
      calls.add('first');
      return first.future;
    }, immediate: true);
    batcher.requestSync('bot', (_) async {
      calls.add('outdated');
    });
    batcher.requestSync('bot', (_) async {
      calls.add('latest');
    }, immediate: true);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, ['first']);
    first.complete();
    await tester.pump();
    expect(calls, ['first', 'latest']);
    await tester.pump(const Duration(seconds: 30));
    expect(calls, ['first', 'latest']);
  });
  testWidgets('another bot can sync while the first is waiting', (
    tester,
  ) async {
    final batcher = BotSyncBatcher();
    final first = Completer<void>();
    final calls = <String>[];
    batcher.requestSync('first', (bot) {
      calls.add(bot);
      return first.future;
    }, immediate: true);
    batcher.requestSync('second', (bot) async {
      calls.add(bot);
    }, immediate: true);
    await tester.pump();
    expect(calls, ['first', 'second']);
    first.complete();
    await tester.pump();
  });
  testWidgets(
    'a failed sync releases the slot and preserves the pending edit',
    (tester) async {
      final batcher = BotSyncBatcher();
      final first = Completer<void>();
      var followUps = 0;
      batcher.requestSync('bot', (_) => first.future, immediate: true);
      batcher.requestSync('bot', (_) async {
        followUps++;
      });
      first.completeError(StateError('network failed'));
      await tester.pump();
      expect(followUps, 1);
    },
  );
  testWidgets('idle edits still debounce for three seconds', (tester) async {
    final batcher = BotSyncBatcher();
    var calls = 0;
    batcher.requestSync('bot', (_) async {
      calls++;
    });
    await tester.pump(const Duration(seconds: 2));
    batcher.requestSync('bot', (_) async {
      calls++;
    });
    await tester.pump(const Duration(seconds: 2));
    expect(calls, 0);
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
  });
}
