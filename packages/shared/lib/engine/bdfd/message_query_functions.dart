import '../../services/time_operations.dart' show unixTimestamp;
import '../../services/go_time_format.dart' show discordSnowflakeCreation;
import '../../services/bot_message_query_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdMessageQueryFunctions(
  BotMessageQueryService service,
) {
  Future<String> guarded(
    BdfdInvocation call,
    Future<String> Function() op,
  ) async {
    try {
      return await op();
    } on ArgumentError catch (e) {
      throw BdfdNativeError(e.message.toString(), call.location);
    } on StateError catch (e) {
      throw BdfdNativeError(e.message, call.location);
    }
  }

  Future<BotMessageSnapshot> message(BdfdInvocation call) async {
    final channel = await call.argument(0), id = await call.argument(1);
    messageQuerySnowflake(channel);
    messageQuerySnowflake(id);
    return service.message(
      channelId: channel,
      messageId: id,
      budget: call.context.budget,
    );
  }

  Future<BotMessageSnapshot> currentMessage(BdfdInvocation call) {
    final channel = call.context.variables['channel.id'] ?? '',
        id = call.context.variables['message.id'] ?? '';
    messageQuerySnowflake(channel);
    messageQuerySnowflake(id);
    return service.message(
      channelId: channel,
      messageId: id,
      budget: call.context.budget,
    );
  }

  Future<BotMessageChannelSnapshot> currentChannel(BdfdInvocation call) {
    final channel = call.context.variables['channel.id'] ?? '';
    messageQuerySnowflake(channel);
    return service.messageChannel(channel, budget: call.context.budget);
  }

  return {
    'lastmessageid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => guarded(
        call,
        () async => (await currentChannel(call)).lastMessageId ?? '',
      ),
    ),
    'lastpintimestamp': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => guarded(call, () async {
        final date = (await currentChannel(call)).lastPinTimestamp;
        return date == null ? '' : unixTimestamp(date, 's');
      }),
    ),
    'ismessageedited': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) => guarded(
        call,
        () async => ((await message(call)).editedTimestamp != null).toString(),
      ),
    ),
    'messageeditedtimestamp': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) => guarded(call, () async {
        final date = (await message(call)).editedTimestamp;
        return date == null ? '' : unixTimestamp(date, 's');
      }),
    ),
    'repliedmessageid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => guarded(
        call,
        () async => (await currentMessage(call)).repliedMessageId ?? '',
      ),
    ),
    'editmessage': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 7,
      handler: (call) => guarded(call, () async {
        final channel = await call.argument(0),
            id = await call.argument(1),
            content = await call.argument(2);
        Future<String?> optional(int i) async =>
            call.argumentCount > i ? await call.argument(i) : null;
        final title = await optional(3),
            description = await optional(4),
            rawColor = await optional(5),
            footer = await optional(6);
        int? color;
        if (rawColor != null && rawColor.trim().isNotEmpty) {
          final raw = rawColor.trim();
          color = raw.startsWith('#')
              ? (RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(raw)
                    ? int.tryParse(raw.substring(1), radix: 16)
                    : null)
              : int.tryParse(raw);
          color ??= RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(raw)
              ? int.tryParse(raw, radix: 16)
              : null;
          if (color == null) throw ArgumentError('Invalid embed color.');
        }
        final change = MessageMutation(
          kind: MessageMutationKind.edit,
          channelId: channel,
          messageId: id,
          edit: MessageEdit(
            content: content,
            title: title,
            description: description,
            color: color,
            footer: footer,
            replaceEmbed: call.argumentCount > 3,
          ),
        );
        change.validate();
        await service.mutateMessage(change, budget: call.context.budget);
        return '';
      }),
    ),
    'pinmessage': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) {
        final output = call.context.output;
        if (output is! BotDeferredMessageOutput) {
          throw BdfdNativeError(
            'Output does not support deferred pinning.',
            call.location,
          );
        }
        (output as BotDeferredMessageOutput).deferPin();
        return '';
      },
    ),
    'getmessage': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 3,
      handler: (call) => guarded(call, () async {
        final property = call.argumentCount > 2
            ? (await call.argument(2)).trim()
            : 'content';
        if (!const [
          'content',
          'authorID',
          'username',
          'avatar',
        ].contains(property)) {
          throw ArgumentError('Unknown message property.');
        }
        final result = await message(call);
        return switch (property) {
          'content' => result.content,
          'authorID' => result.authorId,
          'username' => result.username,
          _ => result.avatarUrl,
        };
      }),
    ),
    'authorofmessage': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) =>
          guarded(call, () async => (await message(call)).authorId),
    ),
    'getattachments': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) => guarded(call, () async {
        final index = int.tryParse((await call.argument(0)).trim());
        if (index == null || index < 0) {
          throw ArgumentError('Attachment index must be zero or positive.');
        }
        final channel = call.context.variables['channel.id'] ?? '',
            id = call.context.variables['message.id'] ?? '';
        messageQuerySnowflake(channel);
        messageQuerySnowflake(id);
        final result = await service.message(
          channelId: channel,
          messageId: id,
          budget: call.context.budget,
        );
        if (index >= result.attachmentUrls.length) {
          throw ArgumentError('Attachment index is out of range.');
        }
        return result.attachmentUrls[index];
      }),
    ),
    'getembeddata': BdfdNativeFunction(
      minArguments: 4,
      maxArguments: 4,
      handler: (call) => guarded(call, () async {
        final index = int.tryParse((await call.argument(2)).trim()),
            property = (await call.argument(3)).trim();
        if (index == null || index < 1) {
          throw ArgumentError('Embed index must be positive.');
        }
        if (!const [
          'title',
          'description',
          'footer',
          'color',
          'image',
          'timestamp',
        ].contains(property)) {
          throw ArgumentError('Unknown embed property.');
        }
        final result = await message(call);
        if (index > result.embeds.length) {
          throw ArgumentError('Embed index is out of range.');
        }
        final embed = result.embeds[index - 1];
        return switch (property) {
          'title' => embed.title ?? '',
          'description' => embed.description ?? '',
          'footer' => embed.footer ?? '',
          'color' => embed.colorHex ?? '',
          'image' => embed.image ?? '',
          _ => embed.timestamp ?? '',
        };
      }),
    ),
    for (final entry in {
      'deletemessage': MessageMutationKind.delete,
      'unpinmessage': MessageMutationKind.unpin,
      'publishmessage': MessageMutationKind.publish,
    }.entries)
      entry.key: BdfdNativeFunction(
        minArguments: 2,
        maxArguments: 2,
        handler: (call) => guarded(call, () async {
          final change = MessageMutation(
            kind: entry.value,
            channelId: await call.argument(0),
            messageId: await call.argument(1),
          );
          change.validate();
          await service.mutateMessage(change, budget: call.context.budget);
          return '';
        }),
      ),
    'messagetimestamp': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) => guarded(call, () async {
        if (call.argumentCount == 0) {
          return call.context.variables['message.timestamp'] ?? '';
        }
        final msg = await message(call);
        return unixTimestamp(discordSnowflakeCreation(msg.id), 's');
      }),
    ),
    'messagetype': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) => guarded(
        call,
        () async => call.context.variables['message.type'] ?? '0',
      ),
    ),
    'messageurl': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) => guarded(call, () async {
        if (call.argumentCount == 2) {
          final ch = await call.argument(0), m = await call.argument(1);
          final g = call.context.variables['guild.id'] ?? '@me';
          return 'https://discord.com/channels/$g/$ch/$m';
        }
        return call.context.variables['message.url'] ?? '';
      }),
    ),
    'nomentionmessage': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => guarded(call, () async {
        final raw =
            call.context.variables['message.cleanContent'] ??
            call.context.variables['message.content'] ??
            '';
        return raw
            .replaceAll(RegExp(r'<@[!&]?\d+>'), '')
            .replaceAll(RegExp(r'<#\d+>'), '');
      }),
    ),
    'mentions': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) => guarded(
        call,
        () async => call.context.variables['message.mentions'] ?? '',
      ),
    ),
  };
}
