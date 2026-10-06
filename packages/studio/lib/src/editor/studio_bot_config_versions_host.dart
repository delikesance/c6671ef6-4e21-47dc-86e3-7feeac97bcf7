import 'package:bot_creator_ui/bot_creator_ui.dart';

import '../api/studio_api.dart';

/// Code applicatif du refus d'une version trop pauvre à la restauration
/// (`409 bot_config_version_too_small`), comme dans l'app.
const String _tooSmallCode = 'bot_config_version_too_small';

/// Les versions d'un bot telles que le Studio les lit : par l'API du Manager.
/// L'écran (`BotConfigVersionsPage`) est celui de l'app. Le Studio n'a pas de
/// copie locale : le serveur est la source de vérité, rien à réappliquer.
class StudioBotConfigVersionsHost implements BotConfigVersionsHost {
  StudioBotConfigVersionsHost(this.api);

  final StudioApi api;

  @override
  Future<List<BotConfigVersionEntry>> list(String botId) async => [
    for (final v in await api.botConfigVersions(botId))
      BotConfigVersionEntry.fromWire(v),
  ];

  @override
  Future<Map<String, dynamic>> preview(String botId, String key) =>
      api.previewBotConfigVersion(botId, key);

  @override
  Future<void> delete(String botId, String key) =>
      api.deleteBotConfigVersion(botId, key);

  // Le contenu vient du Manager (`/versions/content`) et non du lien public de
  // l'objet : un navigateur ne peut pas le télécharger sans CORS.
  @override
  Future<List<String>> commandNames(String botId, String key) async {
    final content = await api.previewBotConfigVersion(botId, key);
    return botConfigCommandNames(content['commands']);
  }

  @override
  Future<int?> currentCommandCount(String botId) async =>
      (await api.listCommands(botId)).length;

  @override
  Future<BotConfigRestoreResult> restore(
    String botId,
    String key, {
    bool confirmOvershrink = false,
  }) async {
    try {
      final ok = await api.restoreBotConfigVersion(
        botId,
        key,
        confirmOvershrink: confirmOvershrink,
      );
      return BotConfigRestoreResult(
        ok
            ? BotConfigRestoreStatus.restored
            : BotConfigRestoreStatus.notConfirmed,
      );
    } on StudioApiException catch (e) {
      if (e.statusCode == 409 &&
          ((e.code ?? '').trim().toLowerCase() == _tooSmallCode ||
              e.message.toLowerCase().contains(_tooSmallCode))) {
        return const BotConfigRestoreResult(
          BotConfigRestoreStatus.floorRefused,
        );
      }
      return BotConfigRestoreResult(
        BotConfigRestoreStatus.failed,
        reason: describeError(e),
      );
    } catch (e) {
      return BotConfigRestoreResult(
        BotConfigRestoreStatus.failed,
        reason: describeError(e),
      );
    }
  }

  @override
  Future<void> applyRestoredLocally(String botId) async {}

  /// Même forme que l'app : statut, code applicatif, message.
  @override
  String describeError(Object error) {
    if (error is StudioApiException) {
      return [
        if (error.statusCode != null) 'HTTP ${error.statusCode}',
        if ((error.code ?? '').isNotEmpty) error.code!,
        error.message,
      ].join(' — ');
    }
    return '$error';
  }
}
