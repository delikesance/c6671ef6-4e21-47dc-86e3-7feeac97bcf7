import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';

class BotConfigMergeDiff {
  const BotConfigMergeDiff({
    required this.newCommands,
    required this.updatedCommands,
    required this.unchangedCount,
    required this.localOnlyCount,
  });

  final List<Map<String, dynamic>> newCommands;
  final List<Map<String, dynamic>> updatedCommands;
  final int unchangedCount;
  final int localOnlyCount;

  bool get hasChanges => newCommands.isNotEmpty || updatedCommands.isNotEmpty;
}

DateTime? parseBotConfigTimestamp(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}

String formatBotConfigTimestamp(Map<String, dynamic> config) {
  final commands = extractCommandListFromConfig(config['commands']);
  DateTime? latest;
  for (final cmd in commands) {
    final t = parseBotConfigTimestamp(cmd['updatedAt']);
    if (t != null && (latest == null || t.isAfter(latest))) {
      latest = t;
    }
  }
  if (latest != null) {
    return latest.toLocal().toString().substring(0, 19);
  }
  final configTs = parseBotConfigTimestamp(
    config['updatedAt'] ?? config['savedAt'],
  );
  if (configTs != null) {
    return configTs.toLocal().toString().substring(0, 19);
  }
  return 'Unknown';
}

Future<String> formatLocalBotConfigTimestamp(
  AppManager appManager,
  String botId,
) async {
  final commands = await appManager.listAppCommands(botId, forceRefresh: true);
  DateTime? latest;
  for (final cmd in commands) {
    final t = parseBotConfigTimestamp(cmd['updatedAt']);
    if (t != null && (latest == null || t.isAfter(latest))) {
      latest = t;
    }
  }
  if (latest != null) {
    return latest.toLocal().toString().substring(0, 19);
  }
  return 'Unknown';
}

BotConfigMergeDiff computeBotConfigMergeDiff(
  List<Map<String, dynamic>> localCommands,
  List<Map<String, dynamic>> remoteCommands,
) {
  final localById = <String, Map<String, dynamic>>{};
  for (final cmd in localCommands) {
    final id = (cmd['id'] ?? cmd['name'] ?? '').toString();
    if (id.isNotEmpty) localById[id] = cmd;
  }

  final newCommands = <Map<String, dynamic>>[];
  final updatedCommands = <Map<String, dynamic>>[];
  var unchangedCount = 0;

  for (final remoteCmd in remoteCommands) {
    final id = (remoteCmd['id'] ?? remoteCmd['name'] ?? '').toString();
    if (id.isEmpty) continue;

    final localCmd = localById[id];
    if (localCmd == null) {
      newCommands.add(remoteCmd);
    } else {
      final remoteUpdated = parseBotConfigTimestamp(remoteCmd['updatedAt']);
      final localUpdated = parseBotConfigTimestamp(localCmd['updatedAt']);
      if (remoteUpdated != null &&
          localUpdated != null &&
          remoteUpdated.isAfter(localUpdated)) {
        updatedCommands.add(remoteCmd);
      } else {
        unchangedCount++;
      }
      localById.remove(id);
    }
  }

  return BotConfigMergeDiff(
    newCommands: newCommands,
    updatedCommands: updatedCommands,
    unchangedCount: unchangedCount,
    localOnlyCount: localById.length,
  );
}

bool botConfigLocalHasNewerEdits(
  List<Map<String, dynamic>> localCommands,
  List<Map<String, dynamic>> remoteCommands,
) {
  final remoteById = <String, Map<String, dynamic>>{};
  for (final cmd in remoteCommands) {
    final id = (cmd['id'] ?? cmd['name'] ?? '').toString();
    if (id.isNotEmpty) remoteById[id] = cmd;
  }

  for (final localCmd in localCommands) {
    final id = (localCmd['id'] ?? localCmd['name'] ?? '').toString();
    if (id.isEmpty) continue;
    final remoteCmd = remoteById[id];
    if (remoteCmd == null) continue;

    final localUpdated = parseBotConfigTimestamp(localCmd['updatedAt']);
    final remoteUpdated = parseBotConfigTimestamp(remoteCmd['updatedAt']);
    if (localUpdated != null &&
        (remoteUpdated == null || localUpdated.isAfter(remoteUpdated))) {
      return true;
    }
  }
  return false;
}
