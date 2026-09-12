import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bug utilisateur : « Les logs ne s'affichent pas dans le panneau console de la
/// home d'un bot (alors quand on clique dedans [BotLogsPage] on les voit bien). »
///
/// Cause : le panneau lisait toujours le bucket `local::<botId>` alors que la
/// page lit le bucket de la source de runtime résolue (`runner::` / `manager::`).
/// Ces tests verrouillent l'alignement des deux lecteurs sur le même bucket.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Panneau console intégré : même source que BotLogsPage', () {
    test('affiche les logs d\'un runtime runner (et non le bucket local)', () {
      const botId = 'panel-remote-runner';
      startBotLogSession(botId: botId, source: RemoteRuntimeSource.runner);
      appendBotLog(
        'remote runner line',
        botId: botId,
        source: RemoteRuntimeSource.runner,
      );

      expect(
        resolveBotLogsSourceForBot(botId),
        RemoteRuntimeSource.runner,
        reason: 'la source résolue doit suivre la session de logs en cours',
      );

      final panelLogs = getBotLogsSnapshotForBot(botId);
      expect(
        panelLogs.any((line) => line.contains('remote runner line')),
        isTrue,
        reason: 'panneau vide alors que la page affiche ces lignes: $panelLogs',
      );

      final pageLogs = getBotLogsSnapshotForBotFromSource(
        botId,
        source: RemoteRuntimeSource.runner,
      );
      expect(
        panelLogs.length,
        pageLogs.length,
        reason:
            'panneau et page doivent lire exactement le même bucket '
            '(panneau=${panelLogs.length}, page=${pageLogs.length})',
      );
    });

    test('affiche les logs du runtime manager (mobile / serveurs)', () {
      const botId = 'panel-remote-manager';
      startBotLogSession(botId: botId, source: RemoteRuntimeSource.manager);
      appendBotLog(
        'manager line',
        botId: botId,
        source: RemoteRuntimeSource.manager,
      );

      final panelLogs = getBotLogsSnapshotForBot(botId);
      expect(
        panelLogs.any((line) => line.contains('manager line')),
        isTrue,
        reason: 'panneau vide malgré les lignes manager: $panelLogs',
      );
    });

    test(
      'le flux du panneau publie les nouvelles lignes distantes (StreamBuilder)',
      () async {
        const botId = 'panel-stream-live';
        startBotLogSession(botId: botId, source: RemoteRuntimeSource.manager);
        appendBotLog(
          'first remote line',
          botId: botId,
          source: RemoteRuntimeSource.manager,
        );

        final emitted = <List<String>>[];
        final subscription = getBotLogsStreamForBot(botId).listen(emitted.add);
        await Future<void>.delayed(Duration.zero);

        appendBotLog(
          'second remote line',
          botId: botId,
          source: RemoteRuntimeSource.manager,
        );
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(
          emitted,
          isNotEmpty,
          reason: 'le flux du panneau n\'a jamais émis',
        );
        expect(
          emitted.last.any((line) => line.contains('second remote line')),
          isTrue,
          reason: 'dernier état publié: ${emitted.last}',
        );
      },
    );

    test('suit le changement de source local -> manager', () async {
      const botId = 'panel-source-switch';
      appendBotLog('local only line', botId: botId);
      expect(
        getBotLogsSnapshotForBot(
          botId,
        ).any((line) => line.contains('local only line')),
        isTrue,
      );

      // La page vient de résoudre le runtime manager pour ce bot.
      setBotLogsSourceForBot(botId, RemoteRuntimeSource.manager);
      appendBotLog(
        'manager takeover line',
        botId: botId,
        source: RemoteRuntimeSource.manager,
      );

      final panelLogs = getBotLogsSnapshotForBot(botId);
      expect(
        panelLogs.any((line) => line.contains('manager takeover line')),
        isTrue,
        reason: 'le panneau n\'a pas suivi la bascule de source: $panelLogs',
      );
      expect(
        panelLogs.any((line) => line.contains('local only line')),
        isFalse,
        reason: 'le panneau montre encore l\'ancien bucket local: $panelLogs',
      );
    });

    test('sans runtime distant, les logs locaux restent visibles', () {
      const botId = 'panel-local-regression';
      startBotLogSession(botId: botId);
      appendBotLog('local engine line', botId: botId);

      expect(resolveBotLogsSourceForBot(botId), RemoteRuntimeSource.local);
      expect(
        getBotLogsSnapshotForBot(
          botId,
        ).any((line) => line.contains('local engine line')),
        isTrue,
      );
    });

    test('le flag debug n\'influence pas la visibilité des logs', () {
      const botId = 'panel-debug-flag';
      addTearDown(() => setBotDebugLogsEnabled(false));
      setBotDebugLogsEnabled(true);

      appendBotLog(
        'remote line with debug flag',
        botId: botId,
        source: RemoteRuntimeSource.manager,
      );

      expect(
        getBotLogsSnapshotForBot(
          botId,
        ).any((line) => line.contains('remote line with debug flag')),
        isTrue,
      );
    });
  });
}
