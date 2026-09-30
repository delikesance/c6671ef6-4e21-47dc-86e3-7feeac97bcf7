/// Resolves an interaction without making Discord's ID the storage identity.
/// Backups may contain stale Discord IDs; only an unambiguous name/type match
/// is safe in that case. Local-only and prefix commands are never candidates.
Map<String, dynamic>? findApplicationCommand(
  List<Map<String, dynamic>> commands, {
  required String discordId,
  required String name,
  required String type,
}) {
  final candidates = commands.where((command) {
    final data = command['data'];
    if (data is Map &&
        (data['legacyModeEnabled'] == true ||
            data['legacyLocalOnly'] == true ||
            data['localOnly'] == true)) {
      return false;
    }
    return (command['type'] ?? 'chatInput') == type;
  }).toList();
  final byId = candidates.where(
    (command) =>
        (command['discordId'] ?? command['id'] ?? '').toString() == discordId,
  );
  if (byId.length == 1) return byId.single;
  if (byId.length > 1) return null;
  final byName = candidates.where(
    (command) =>
        (command['name'] ?? '').toString().trim().toLowerCase() ==
        name.trim().toLowerCase(),
  );
  return byName.length == 1 ? byName.single : null;
}

/// Keeps the history/storage key while updating the Discord registration.
Map<String, dynamic> withDiscordCommandId(
  Map<String, dynamic> command,
  String storageId,
  String discordId,
) => <String, dynamic>{...command, 'id': storageId, 'discordId': discordId};
