import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart';

bool isUnknownDiscordApplicationCommandError(Object error) {
  final message = error.toString();
  return message.contains('10063') ||
      message.contains('Unknown application command');
}

/// Deletes every global application command registered on Discord for [botId].
///
/// Returns the number of commands successfully deleted. No-ops when the bot
/// token is missing or [botId] is empty.
Future<int> deleteAllDiscordApplicationCommands(String botId) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return 0;
  }

  final app = await AppManager().getApp(trimmedBotId);
  final token = (app['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    debugPrint(
      '[DiscordCommands] Skipping delete: no token for bot $trimmedBotId.',
    );
    return 0;
  }

  try {
    final rest = await Nyxx.connectRest(token);
    try {
      final remoteCommands = await rest.commands.list();
      var deletedCount = 0;
      for (final command in remoteCommands) {
        try {
          await rest.commands.delete(command.id);
          deletedCount++;
        } catch (error) {
          if (!isUnknownDiscordApplicationCommandError(error)) {
            rethrow;
          }
        }
      }
      debugPrint(
        '[DiscordCommands] Deleted $deletedCount command(s) for bot $trimmedBotId.',
      );
      return deletedCount;
    } finally {
      rest.close();
    }
  } on Object catch (error) {
    debugPrint(
      '[DiscordCommands] Failed to delete commands for bot $trimmedBotId: $error',
    );
    return 0;
  }
}
