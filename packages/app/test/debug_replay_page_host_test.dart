import 'dart:async';

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hôte « mémoire locale » : aucun runner configuré (`fetchReplays` rend null),
/// ce que l'app fait quand le bot tourne sur l'appareil.
class _LocalHost extends ui.DebugReplayHost {
  _LocalHost({this.capable = true});

  final bool capable;
  final stream = StreamController<List<ui.DebugReplayRecord>>.broadcast();
  final capture = <bool>[];
  var cleared = 0;

  final record = ui.DebugReplayRecord(
    commandLabel: 'ping',
    triggeredAt: DateTime.utc(2026, 10, 3),
    botId: 'b1',
    totalMs: 5,
    frames: const [
      ui.DebugActionFrame(
        actionType: 'sendMessage',
        startMs: 0,
        durationMs: 5,
        result: 'ok',
      ),
    ],
  );

  @override
  bool hasCapability(String? botId) => capable;

  @override
  Widget buildUpgradeAction(BuildContext context) =>
      const Text('upgrade-action');

  @override
  Future<ui.DebugReplaySnapshot?> fetchReplays(
    String botId, {
    int limit = 30,
  }) async => null;

  @override
  Future<void> clearReplays(String botId) async => fail('remote not expected');

  @override
  Future<bool> setCapturing(String botId, bool enabled) async =>
      fail('remote not expected');

  @override
  bool get hasLocalSource => true;

  @override
  List<ui.DebugReplayRecord> get localReplays => [record];

  @override
  Stream<List<ui.DebugReplayRecord>> get localReplaysStream => stream.stream;

  @override
  void setLocalCapturing(bool enabled) => capture.add(enabled);

  @override
  void clearLocalReplays() => cleared++;
}

Future<void> _pump(WidgetTester tester, _LocalHost host) => tester.pumpWidget(
  MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: DebugReplayPage(botId: 'b1', host: host),
  ),
);

void main() {
  testWidgets('l\'ancien écran de l\'app lit la mémoire locale quand il n\'y a '
      'pas de runner', (tester) async {
    final host = _LocalHost();
    await _pump(tester, host);
    await tester.pumpAndSettle();
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text('/ping'), findsOneWidget);

    await tester.tap(find.byTooltip(en.debug_replay_start_capture));
    await tester.pump();
    expect(host.capture, [true]);

    await tester.tap(find.byTooltip(en.debug_replay_clear));
    await tester.pumpAndSettle();
    await tester.tap(find.text(en.delete));
    await tester.pumpAndSettle();
    expect(host.cleared, 1);

    // Un rejeu poussé par le moteur local apparaît sans rechargement.
    host.stream.add([
      host.record,
      ui.DebugReplayRecord(
        commandLabel: 'pong',
        triggeredAt: DateTime.utc(2026, 10, 4),
        botId: 'b1',
        totalMs: 1,
        frames: const [],
      ),
      ui.DebugReplayRecord(
        commandLabel: 'other-bot',
        triggeredAt: DateTime.utc(2026, 10, 4),
        botId: 'b2',
        totalMs: 1,
        frames: const [],
      ),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('/pong'), findsOneWidget);
    expect(find.text('/other-bot'), findsNothing);
    await host.stream.close();
  });

  testWidgets('sans la capacité : offre premium, détail et capture fermés', (
    tester,
  ) async {
    final host = _LocalHost(capable: false);
    await _pump(tester, host);
    await tester.pumpAndSettle();
    final en = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text(en.debug_replay_premium_title), findsOneWidget);
    expect(find.text('upgrade-action'), findsOneWidget);
    expect(find.byTooltip(en.debug_replay_start_capture), findsNothing);
    // La ligne reste visible mais ne s'ouvre pas.
    await tester.tap(find.text('/ping'));
    await tester.pumpAndSettle();
    expect(find.text(en.debug_replay_overview), findsNothing);
    await host.stream.close();
  });
}
