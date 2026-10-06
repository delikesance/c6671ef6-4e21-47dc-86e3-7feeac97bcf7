import 'package:bot_creator_ui/bot_creator_ui.dart';

import '../api/studio_api.dart';

/// L'historique d'une commande tel que le Studio le lit : par l'API v2 du
/// Manager. La modale (`CommandHistorySheet`) est celle de l'app.
class StudioCommandHistoryHost implements CommandHistoryHost {
  StudioCommandHistoryHost(this.api, {this.revision});

  final StudioApi api;

  /// Révision attendue par le serveur pour la prochaine écriture.
  String? revision;

  /// Vrai dès qu'une version a été restaurée : l'éditeur doit alors relire la
  /// commande.
  bool restored = false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<CommandHistoryEntry>> list(
    String botId,
    String commandId, {
    int? limit,
  }) async {
    final versions = await api.commandHistory(botId, commandId, limit: limit);
    return [
      for (final v in versions)
        CommandHistoryEntry(
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
  ) => api.previewCommandVersion(botId, commandId, historyId);

  @override
  Future<void> delete(String botId, String commandId, String historyId) =>
      api.deleteCommandVersion(botId, commandId, historyId);

  @override
  Future<CommandRestoreResult> restore(
    String botId,
    String commandId,
    String historyId, {
    bool confirmOvershrink = false,
  }) async {
    try {
      revision =
          await api.restoreCommandVersion(
            botId,
            commandId,
            historyId,
            revision: revision,
          ) ??
          revision;
      restored = true;
      return const CommandRestoreResult(CommandRestoreStatus.restored);
    } on StudioApiException catch (e) {
      if (e.statusCode == 409) {
        return const CommandRestoreResult(CommandRestoreStatus.conflict);
      }
      return CommandRestoreResult(
        CommandRestoreStatus.failed,
        reason: e.message,
      );
    }
  }

  @override
  Future<void> reload(String botId, String commandId) async {
    final detail = await api.getCommand(botId, commandId);
    revision = detail.revision;
  }

  @override
  String describeError(Object error) =>
      error is StudioApiException ? error.message : '$error';
}
