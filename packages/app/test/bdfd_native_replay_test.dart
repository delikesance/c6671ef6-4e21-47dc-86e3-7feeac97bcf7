import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native replay metadata survives serialization with error status', () {
    final frame = DebugActionFrame.fromJson({
      'actionType': r'$sendMessage',
      'startMs': 1,
      'durationMs': 2,
      'backend': 'native-v1',
      'nativeKind': 'function',
      'nativeStatus': 'error',
      'line': 2,
      'column': 4,
      'scriptDepth': 1,
      'functionDepth': 1,
      'result': 'A transport failure',
      'valueTruncated': true,
    });
    expect(frame.isNative, true);
    expect(frame.isError, true);
    expect(frame.displayName, r'$sendMessage');
    final restored = DebugActionFrame.fromJson(frame.toJson());
    expect(restored.nativeMetadata, frame.nativeMetadata);
    expect(restored.result, frame.result);
    expect(restored.isError, true);
  });

  test('legacy replay formatting and error detection remain compatible', () {
    final frame = DebugActionFrame.fromJson({
      'actionType': 'sendMessage',
      'result': 'Error: failed',
    });
    expect(frame.displayName, 'Send Message');
    expect(frame.isNative, false);
    expect(frame.isError, true);
    expect(frame.toJson().containsKey('backend'), false);
  });

  testWidgets(
    'replay displays exact function name and native source position',
    (tester) async {
      final record = DebugReplayRecord(
        commandLabel: '/native',
        triggeredAt: DateTime(2026),
        botId: 'bot',
        totalMs: 2,
        frames: [
          DebugActionFrame.fromJson({
            'actionType': r'$sendMessage',
            'startMs': 0,
            'durationMs': 2,
            'backend': 'native-v1',
            'nativeStatus': 'returned',
            'line': 2,
            'column': 4,
            'scriptDepth': 1,
            'result': '123',
          }),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DebugReplayDetailPage(replay: record),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(r'$sendMessage'), findsWidgets);
      await tester.tap(find.text(r'$sendMessage').first);
      await tester.pumpAndSettle();
      expect(find.textContaining('L2:4'), findsOneWidget);
      expect(find.textContaining('Returned'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'dense native replay renders its bounded events without timeline overflow',
    (tester) async {
      final record = DebugReplayRecord(
        commandLabel: '/dense',
        triggeredAt: DateTime(2026),
        botId: 'bot',
        totalMs: 1,
        frames: List.generate(
          1001,
          (_) => DebugActionFrame.fromJson({
            'actionType': r'$var',
            'backend': 'native-v1',
            'nativeStatus': 'start',
          }),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DebugReplayDetailPage(replay: record),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
