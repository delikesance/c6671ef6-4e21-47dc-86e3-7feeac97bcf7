// La modale d'historique d'une commande vit dans `bot_creator_ui` (le Studio
// affiche la même). Ce fichier n'en garde que l'adaptateur de l'app : le dépôt
// granulaire (`BotDataRepository`) qui répond aux questions de la modale.
//
// Les règles (un 409 est un conflit et non une panne, l'historique vide est un
// état légitime, « v2 non armée » dit pourquoi) sont documentées dans la
// modale partagée.
library;

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/storage/granular_data_layer.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

export 'package:bot_creator_ui/bot_creator_ui.dart'
    show CommandHistoryPhase, commandHistoryVersionLimit;

/// Ouvre la modale d'historique d'une commande.
///
/// `repository` est un point d'injection (les tests montent la modale sans
/// couche globale) ; sans lui, c'est la couche granulaire de l'application qui
/// décide — et son absence est un ÉTAT, pas une erreur.
Future<void> showCommandHistorySheet(
  BuildContext context, {
  required String botId,
  required String commandId,
  BotDataRepository? repository,
}) {
  final resolved = repository ?? granularDataRepository;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => CommandHistorySheet(
      botId: botId,
      commandId: commandId,
      repository: resolved,
    ),
  );
}

/// La modale d'historique d'une commande, autonome et montable seule.
class CommandHistorySheet extends StatelessWidget {
  const CommandHistorySheet({
    super.key,
    required this.botId,
    required this.commandId,
    this.repository,
  });

  final String botId;
  final String commandId;

  /// Le dépôt granulaire, ou `null` quand l'application n'en a aucun (aucune
  /// session) : la modale dit alors que l'historique n'est pas disponible.
  final BotDataRepository? repository;

  @override
  Widget build(BuildContext context) {
    final repo = repository;
    return ui.CommandHistorySheet(
      botId: botId,
      commandId: commandId,
      host: repo == null ? null : AppCommandHistoryHost(repo),
    );
  }
}

/// L'historique d'une commande tel que l'app le lit : par son dépôt granulaire.
class AppCommandHistoryHost implements ui.CommandHistoryHost {
  AppCommandHistoryHost(this.repository);

  final BotDataRepository repository;

  @override
  Future<bool> isAvailable() async {
    if (!repository.isGranularEnabled && !repository.hasProbed) {
      // La couche granulaire n'a peut-être pas ENCORE sondé (démarrage). Une
      // sonde qui échoue laisse la v2 désarmée : résultat attendu.
      try {
        await repository.probe();
      } catch (_) {}
    }
    return repository.isGranularEnabled;
  }

  @override
  Future<List<ui.CommandHistoryEntry>> list(
    String botId,
    String commandId, {
    int? limit,
  }) async {
    final versions = await repository.listCommandHistory(
      botId,
      commandId,
      limit: limit,
    );
    return [
      for (final v in versions)
        ui.CommandHistoryEntry(
          historyId: v.historyId,
          createdAt: v.createdAt,
          authorOwnerId: v.authorOwnerId,
          sizeBytes: v.sizeBytes,
        ),
    ];
  }

  @override
  Future<Map<String, dynamic>> preview(
    String botId,
    String commandId,
    String historyId,
  ) => repository.previewCommandVersion(botId, commandId, historyId);

  @override
  Future<void> delete(String botId, String commandId, String historyId) =>
      repository.deleteCommandVersion(botId, commandId, historyId);

  @override
  Future<ui.CommandRestoreResult> restore(
    String botId,
    String commandId,
    String historyId, {
    bool confirmOvershrink = false,
  }) async {
    final info =
        'botId=$botId commandId=$commandId historyId=$historyId '
        'forced=$confirmOvershrink';
    try {
      final outcome = await repository.restoreCommandVersion(
        botId,
        commandId,
        historyId,
        confirmOvershrink: confirmOvershrink,
      );
      switch (outcome) {
        case SavedGranular() || SavedLegacy():
          return const ui.CommandRestoreResult(
            ui.CommandRestoreStatus.restored,
          );
        case ConflictStale():
          return const ui.CommandRestoreResult(
            ui.CommandRestoreStatus.conflict,
          );
        // Une restauration ne part jamais en file : la dire « en attente »
        // laisserait croire qu'elle se fera toute seule.
        case QueuedOffline():
          return const ui.CommandRestoreResult(ui.CommandRestoreStatus.failed);
      }
    } on MainApiClientException catch (error) {
      if (isBotConfigVersionFloorRefusal(error)) {
        AppDiagnostics.logError(
          'Command version restore refused: version below the floor',
          error,
          StackTrace.current,
          fatal: false,
          information: '$info code=${error.code}',
        );
        return const ui.CommandRestoreResult(
          ui.CommandRestoreStatus.floorRefused,
        );
      }
      if (error.statusCode == 409) {
        return const ui.CommandRestoreResult(ui.CommandRestoreStatus.conflict);
      }
      return _failed(error, info);
    } catch (error) {
      return _failed(error, info);
    }
  }

  ui.CommandRestoreResult _failed(Object error, String info) {
    AppDiagnostics.logError(
      'Command version restore failed',
      error,
      StackTrace.current,
      fatal: false,
      information: info,
    );
    return ui.CommandRestoreResult(
      ui.CommandRestoreStatus.failed,
      reason: describeApiFailure(error),
    );
  }

  @override
  Future<void> reload(String botId, String commandId) async {
    await repository.getCommand(botId, commandId);
  }

  @override
  String describeError(Object error) => describeApiFailure(error);
}
