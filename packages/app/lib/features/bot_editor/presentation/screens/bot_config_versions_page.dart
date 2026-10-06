// L'écran des versions de la configuration d'un bot vit dans `bot_creator_ui`
// (le Studio affiche le même). Ce fichier n'en garde que l'adaptateur de l'app :
// `MainApiClient` pour le serveur, et la copie locale (`appManager`) que la
// restauration doit réaligner sur la version restaurée.
//
// Les règles (restauration forcée proposée quand le serveur juge la version
// « trop petite », raison réelle de l'échec affichée, serveur restauré mais
// copie locale en échec dit tel quel) sont documentées dans l'écran partagé.
library;

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/main.dart' show appManager;
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class BotConfigVersionsPage extends StatelessWidget {
  final String botId;
  final String botToken;
  final Future<MainApiClient?> Function(String botId, String token)
  resolveClient;

  const BotConfigVersionsPage({
    super.key,
    required this.botId,
    required this.botToken,
    required this.resolveClient,
  });

  @override
  Widget build(BuildContext context) => ui.BotConfigVersionsPage(
    botId: botId,
    host: AppBotConfigVersionsHost(
      botToken: botToken,
      resolveClient: resolveClient,
    ),
  );
}

/// Les versions d'un bot telles que l'app les lit : par `MainApiClient`, puis
/// réappliquées dans la base locale après une restauration.
class AppBotConfigVersionsHost implements ui.BotConfigVersionsHost {
  AppBotConfigVersionsHost({
    required this.botToken,
    required this.resolveClient,
  });

  final String botToken;
  final Future<MainApiClient?> Function(String botId, String token)
  resolveClient;

  Future<MainApiClient> _client(String botId, {String? failure}) async {
    final client = await resolveClient(botId, botToken);
    if (client == null) {
      throw MainApiClientException(failure ?? 'API client unavailable');
    }
    return client;
  }

  @override
  Future<List<ui.BotConfigVersionEntry>> list(String botId) async {
    final client = await _client(
      botId,
      failure: 'Failed to resolve API client',
    );
    final versions = await client.getBotConfigVersions(botId);
    return [for (final v in versions) ui.BotConfigVersionEntry.fromWire(v)];
  }

  @override
  Future<Map<String, dynamic>> preview(String botId, String key) async =>
      (await _client(botId)).previewBotConfigVersion(botId, key);

  @override
  Future<void> delete(String botId, String key) async =>
      (await _client(botId)).deleteBotConfigVersion(botId, key);

  @override
  Future<List<String>> commandNames(String botId, String key) async {
    final config = await (await _client(botId)).getBotConfigVersion(botId, key);
    return ui.botConfigCommandNames(config['commands']);
  }

  @override
  Future<int?> currentCommandCount(String botId) async =>
      (await appManager.listAppCommands(botId)).length;

  @override
  Future<ui.BotConfigRestoreResult> restore(
    String botId,
    String key, {
    bool confirmOvershrink = false,
  }) async {
    try {
      final client = await _client(
        botId,
        failure: 'API client could not be resolved',
      );
      final bool success;
      try {
        success = await client.restoreBotConfigVersion(
          botId,
          key,
          confirmOvershrink: confirmOvershrink,
        );
      } on MainApiClientException catch (error, stack) {
        AppDiagnostics.logError(
          'Bot config version restore refused by server',
          error,
          stack,
          fatal: false,
          information:
              'botId=$botId version=$key '
              'status=${error.statusCode} code=${error.code} '
              'forced=$confirmOvershrink',
        );
        if (isBotConfigVersionFloorRefusal(error)) {
          return const ui.BotConfigRestoreResult(
            ui.BotConfigRestoreStatus.floorRefused,
          );
        }
        return ui.BotConfigRestoreResult(
          ui.BotConfigRestoreStatus.failed,
          reason: describeApiFailure(error),
        );
      }
      if (!success) {
        AppDiagnostics.logError(
          'Bot config version restore not confirmed by server',
          'restoreBotConfigVersion returned false',
          StackTrace.current,
          fatal: false,
          information: 'botId=$botId version=$key',
        );
        return const ui.BotConfigRestoreResult(
          ui.BotConfigRestoreStatus.notConfirmed,
        );
      }
      return const ui.BotConfigRestoreResult(
        ui.BotConfigRestoreStatus.restored,
      );
    } catch (error, stack) {
      AppDiagnostics.logError(
        'Bot config version restore failed',
        error,
        stack,
        fatal: false,
        information: 'botId=$botId version=$key',
      );
      return ui.BotConfigRestoreResult(
        ui.BotConfigRestoreStatus.failed,
        reason: describeApiFailure(error),
      );
    }
  }

  @override
  Future<void> applyRestoredLocally(String botId) async {
    try {
      final client = await _client(botId);
      final remoteConfig = await client.getBotConfig(botId);
      if (remoteConfig['inboundWebhooks'] is bool) {
        remoteConfig.remove('inboundWebhooks');
      }
      final localApp = await appManager.getApp(botId);
      if (localApp['avatar'] != null && remoteConfig['avatar'] == null) {
        remoteConfig['avatar'] = localApp['avatar'];
      }
      if (localApp['name'] != null && remoteConfig['name'] == null) {
        remoteConfig['name'] = localApp['name'];
      }
      final token = (localApp['token'] ?? botToken).toString().trim();
      if (token.isNotEmpty) {
        remoteConfig['token'] = token;
      }
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remoteConfig,
        // Une RESTAURATION n'est pas une synchro : le bot doit revenir à CET
        // état, pas fusionner avec l'état courant. Sans cette suppression, une
        // commande créée APRÈS la version restaurée survit localement — d'où
        // deux « eval » après restauration d'une version qui n'en avait qu'un —
        // et la prochaine synchro la renvoie au serveur, ce qui annule la
        // restauration en silence.
        deleteMissingLocalCommands: true,
      );
    } catch (error, stack) {
      AppDiagnostics.logError(
        'Bot config version restored but not applied locally',
        error,
        stack,
        fatal: false,
        information: 'botId=$botId',
      );
      rethrow;
    }
  }

  @override
  String describeError(Object error) => describeApiFailure(error);
}
