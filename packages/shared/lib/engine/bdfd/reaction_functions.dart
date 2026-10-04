import '../../services/bot_reaction_service.dart';
import 'program.dart';
import 'runtime.dart';

/// The response sink queues these for its future, actually sent message.
abstract interface class BotDeferredReactionOutput {
  void deferReactions(List<String> emojis);
}

Map<String, BdfdNativeFunction> bdfdReactionFunctions(
  BotReactionService service,
) {
  Future<BotReactionTarget> target(
    BdfdInvocation call, {
    bool command = false,
  }) async {
    final value = BotReactionTarget(
      channelId: command
          ? call.context.variables['channel.id'] ?? ''
          : await call.argument(0),
      messageId: command
          ? call.context.variables['message.id'] ?? ''
          : await call.argument(1),
    );
    value.validate();
    return value;
  }

  Future<List<String>> emojis(BdfdInvocation call, int offset) async {
    final values = <String>[];
    for (var i = offset; i < call.argumentCount; i++) {
      call.context.budget.check();
      values.add(normalizeBotReactionEmoji(await call.argument(i)));
    }
    return List.unmodifiable(values);
  }

  BdfdNativeFunction add({bool command = false}) => BdfdNativeFunction(
    minArguments: command ? 1 : 3,
    maxArguments: 1 << 30,
    handler: (call) async {
      final selected = await target(call, command: command);
      final values = await emojis(call, command ? 0 : 2);
      await call.context.budget.run(
        () => service.addReactions(
          BotReactionAddRequest(target: selected, emojis: values),
          budget: call.context.budget,
        ),
      );
      return '';
    },
  );
  return {
    'addreactions': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1 << 30,
      handler: (call) async {
        final sink = call.context.output;
        if (sink is! BotDeferredReactionOutput) {
          throw BdfdNativeError(
            'No deferred reaction output configured.',
            call.location,
          );
        }
        (sink as BotDeferredReactionOutput).deferReactions(
          await emojis(call, 0),
        );
        return '';
      },
    ),
    'addcmdreactions': add(command: true),
    'addmessagereactions': add(),
    'clearreactions': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) async {
        final selected = await target(call);
        final raw = (await call.argument(2)).trim();
        final emoji = raw == '!all' ? null : normalizeBotReactionEmoji(raw);
        await call.context.budget.run(
          () => service.clearReactions(
            BotReactionClearRequest(target: selected, emoji: emoji),
            budget: call.context.budget,
          ),
        );
        return '';
      },
    ),
    'removereaction': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) async {
        final selected = await target(call);
        final rawEmoji = call.argumentCount == 4
            ? await call.argument(3)
            : await call.argument(2);
        final emoji = normalizeBotReactionEmoji(rawEmoji);
        await call.context.budget.run(
          () => service.clearReactions(
            BotReactionClearRequest(target: selected, emoji: emoji),
            budget: call.context.budget,
          ),
        );
        return '';
      },
    ),
    'getreactions': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) async {
        final selected = await target(call);
        final separator = await call.argument(2);
        final emoji = normalizeBotReactionEmoji(await call.argument(3));
        final users = await call.context.budget.run(
          () => service.reactionUsers(
            BotReactionQuery(target: selected, emoji: emoji),
            budget: call.context.budget,
          ),
        );
        final tags = <String>[];
        for (final user in users) {
          call.context.budget.check();
          tags.add(user.tag);
        }
        return tags.join(separator);
      },
    ),
    'userreacted': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) async {
        final selected = await target(call);
        final user = (await call.argument(2)).trim();
        final parsed = RegExp(r'^[0-9]+$').hasMatch(user)
            ? int.tryParse(user)
            : null;
        if (parsed == null || parsed <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final emoji = normalizeBotReactionEmoji(await call.argument(3));
        final users = await call.context.budget.run(
          () => service.reactionUsers(
            BotReactionQuery(target: selected, emoji: emoji),
            budget: call.context.budget,
          ),
        );
        for (final candidate in users) {
          call.context.budget.check();
          if (candidate.id == '$parsed') return 'true';
        }
        return 'false';
      },
    ),
  };
}
