import 'dart:convert';

import 'package:nyxx/nyxx.dart' show Snowflake;

import '../../../services/bot_emoji_block_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Guild emoji blocks on the native engine: createEmoji, updateEmoji and
/// deleteEmoji. Parity with the historical loop: the effect is
/// [BotEmojiBlockService] (permission pre-check, image download, audit reason),
/// `results[key]` is the JSON of the service result and every field is also
/// published as `results['<key>.<field>']`.
///
/// Like the historical `switch`, these blocks trace (and with it the numeric
/// "last message" bookkeeping) only under a debug profile / replay capture.
final Map<BotCreatorActionType, ActionHandler> emojiActionHandlers = {
  BotCreatorActionType.createEmoji: (call) => _emoji(
    call,
    (s, guild) =>
        s.create(guildId: guild, payload: call.payload, resolve: call.resolve),
  ),
  BotCreatorActionType.updateEmoji: (call) => _emoji(
    call,
    (s, guild) =>
        s.update(guildId: guild, payload: call.payload, resolve: call.resolve),
  ),
  BotCreatorActionType.deleteEmoji: (call) => _emoji(
    call,
    (s, guild) =>
        s.delete(guildId: guild, payload: call.payload, resolve: call.resolve),
  ),
};

const Set<BotCreatorActionType> emojiProfilingOnlyTraceTypes = {
  BotCreatorActionType.createEmoji,
  BotCreatorActionType.updateEmoji,
  BotCreatorActionType.deleteEmoji,
};

bool _always(Action action) => true;

final Map<BotCreatorActionType, bool Function(Action)> emojiLeafPredicates = {
  for (final type in emojiActionHandlers.keys) type: _always,
};

Future<String?> _emoji(
  ActionCall call,
  Future<Map<String, String>> Function(BotEmojiBlockService, Snowflake?) run,
) async {
  final client = call.env.client;
  if (client == null) {
    throw StateError('A Discord client is required for ${call.type.name}.');
  }
  final result = await run(
    DiscordBotEmojiBlockService(client),
    call.env.guildSnowflake,
  );
  if (result['error'] != null) throw Exception(result['error']);
  for (final entry in result.entries) {
    call.sink.set(call.path, '${call.key}.${entry.key}', entry.value);
  }
  return jsonEncode(result);
}
