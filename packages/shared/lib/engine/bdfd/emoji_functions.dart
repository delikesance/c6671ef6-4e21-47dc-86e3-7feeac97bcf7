import '../../services/bot_emoji_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdEmojiFunctions(BotEmojiService service) {
  String? id(String raw) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    return parsed == null || parsed <= 0 ? null : '$parsed';
  }

  Future<BotEmoji> selected(BdfdInvocation call) async {
    final value = id(await call.argument(0));
    if (value == null) {
      throw BdfdNativeError('Invalid emoji ID.', call.location);
    }
    final emoji = await call.context.budget.run(
      () => service.emoji(value, budget: call.context.budget),
    );
    if (emoji == null) throw BdfdNativeError('Emoji not found.', call.location);
    return emoji;
  }

  BdfdNativeFunction field(String Function(BotEmoji) read) =>
      BdfdNativeFunction(
        minArguments: 1,
        maxArguments: 1,
        handler: (call) async => read(await selected(call)),
      );
  return {
    'customemoji': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final name = (await call.argument(0)).trim();
        if (name.isEmpty) {
          throw BdfdNativeError('Emoji name is required.', call.location);
        }
        final emoji = await call.context.budget.run(
          () => service.emojiByName(name, budget: call.context.budget),
        );
        return emoji?.mention ?? '';
      },
    ),
    'emojiexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final value = id(await call.argument(0));
        if (value == null) return 'false';
        final emoji = await call.context.budget.run(
          () => service.emoji(value, budget: call.context.budget),
        );
        return '${emoji != null}';
      },
    ),
    'emojiname': field((emoji) => emoji.name),
    'isemojianimated': field((emoji) => '${emoji.animated}'),
    'emotecount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          '${(await call.context.budget.run(() => service.emojis(budget: call.context.budget))).length}',
    ),
    'emojicount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        String? guildId;
        if (call.argumentCount == 1) {
          final raw = (await call.argument(0)).trim();
          if (raw.isNotEmpty) {
            guildId = id(raw);
            if (guildId == null) {
              throw BdfdNativeError('Invalid guild ID.', call.location);
            }
          }
        }
        final emojis = await call.context.budget.run(
          () => service.emojis(guildId: guildId, budget: call.context.budget),
        );
        return '${emojis.length}';
      },
    ),
    'stickercount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          call.context.variables['guild.stickerCount'] ?? '0',
    ),
    'serveremojis': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async {
        final guildId = id(await call.argument(0));
        if (guildId == null) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
        final separator = await call.argument(1);
        final emojis = await call.context.budget.run(
          () => service.emojis(guildId: guildId, budget: call.context.budget),
        );
        final values = <String>[];
        for (final emoji in emojis) {
          call.context.budget.check();
          values.add(emoji.mention);
        }
        return values.join(separator);
      },
    ),
    'addemoji': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) async {
        final name = await call.argument(0);
        final url = await call.argument(1);
        final flag = (await call.argument(2)).trim().toLowerCase();
        if (!['yes', 'no'].contains(flag)) {
          throw BdfdNativeError(
            'Return emoji must be yes or no.',
            call.location,
          );
        }
        final request = BotEmojiCreateRequest(name: name, imageUrl: url);
        request.validate();
        final emoji = await call.context.budget.run(
          () => service.createEmoji(request, budget: call.context.budget),
        );
        return flag == 'yes' ? emoji.mention : '';
      },
    ),
    'removeemoji': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final value = id(await call.argument(0));
        if (value == null) {
          throw BdfdNativeError('Invalid emoji ID.', call.location);
        }
        await call.context.budget.run(
          () => service.deleteEmoji(value, budget: call.context.budget),
        );
        return '';
      },
    ),
  };
}
