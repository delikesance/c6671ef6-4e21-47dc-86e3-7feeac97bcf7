import 'dart:async';

import 'package:bot_creator/features/bot_editor/logic/bot_sync_batcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a bot is busy from the request until its sync has finished', () async {
    final batcher = BotSyncBatcher();
    final release = Completer<void>();
    expect(batcher.isBusy('1'), isFalse);

    batcher.requestSync('1', (_) => release.future, immediate: true);
    expect(batcher.isBusy('1'), isTrue);

    release.complete();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(batcher.isBusy('1'), isFalse);
  });

  test('a debounced request counts as busy before it starts', () {
    final batcher = BotSyncBatcher();
    batcher.requestSync('2', (_) async {});
    expect(batcher.isBusy('2'), isTrue);
  });
}
