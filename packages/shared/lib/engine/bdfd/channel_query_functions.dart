import '../../services/bot_channel_query_service.dart';
import 'program.dart';
import 'context_functions.dart' show bdfdCurrentChannelId;
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdChannelQueryFunctions(
  BotChannelQueryService service,
) {
  String? id(String raw) {
    final parsed = int.tryParse(raw.trim());
    return parsed == null || parsed <= 0 ? null : '$parsed';
  }

  Future<BotChannel> channel(BdfdInvocation call, String raw) async {
    final parsed = id(raw);
    if (parsed == null) {
      throw BdfdNativeError('Invalid channel ID.', call.location);
    }
    final value = await call.context.budget.run(
      () => service.channel(parsed, budget: call.context.budget),
    );
    if (value == null) {
      throw BdfdNativeError('Channel not found.', call.location);
    }
    return value;
  }

  BdfdNativeFunction field(String Function(BotChannel) read) =>
      BdfdNativeFunction(
        minArguments: 1,
        maxArguments: 1,
        handler: (call) async =>
            read(await channel(call, await call.argument(0))),
      );
  Future<String> byName(
    BdfdInvocation call, {
    bool categoryOnly = false,
  }) async {
    final name = (await call.argument(0)).trim();
    if (name.isEmpty) {
      throw BdfdNativeError('Channel name is required.', call.location);
    }
    final values = await call.context.budget.run(
      () => service.channels(
        includeActiveThreads: !categoryOnly,
        budget: call.context.budget,
      ),
    );
    return values
            .where(
              (c) => c.name == name && (!categoryOnly || c.type == 'category'),
            )
            .firstOrNull
            ?.id ??
        '';
  }

  Future<String?> optionalGuild(BdfdInvocation call) async {
    if (call.argumentCount == 0) return null;
    final raw = (await call.argument(0)).trim();
    if (raw.isEmpty) return null;
    final parsed = id(raw);
    if (parsed == null) {
      throw BdfdNativeError('Invalid guild ID.', call.location);
    }
    return parsed;
  }

  BdfdNativeFunction setting(
    String label,
    String? Function(BotGuildChannelSettings) read, {
    bool optionalServer = false,
  }) => BdfdNativeFunction(
    minArguments: 0,
    maxArguments: optionalServer ? 1 : 0,
    handler: (call) async {
      final selected = await optionalGuild(call);
      final snapshot = await call.context.budget.run(
        () => service.guildChannelSettings(
          guildId: selected,
          budget: call.context.budget,
        ),
      );
      final value = read(snapshot);
      if (value == null) {
        throw BdfdNativeError(
          'No $label channel set in this server.',
          call.location,
        );
      }
      return value;
    },
  );

  return {
    'afkchannelid': setting('AFK', (settings) => settings.afkId),
    'ruleschannelid': setting(
      'rules',
      (settings) => settings.rulesId,
      optionalServer: true,
    ),
    'systemchannelid': setting('system', (settings) => settings.systemId),
    'randomcategoryid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final guild = await optionalGuild(call);
        final values = await call.context.budget.run(
          () => service.channels(guildId: guild, budget: call.context.budget),
        );
        final categories = values.where((c) => c.type == 'category').toList();
        return categories.isEmpty
            ? ''
            : categories[call.context.random.nextInt(categories.length)].id;
      },
    ),
    'randomchannelid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        final all = await call.context.budget.run(
          () => service.channels(budget: call.context.budget),
        );
        return all.isEmpty
            ? ''
            : all[call.context.random.nextInt(all.length)].id;
      },
    ),
    'getslowmode': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          '${(await channel(call, call.argumentCount == 1 ? await call.argument(0) : call.context.variables['channel.id'] ?? '')).slowmodeSeconds}',
    ),
    'serverchannelexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final query = (await call.argument(0)).trim();
        if (query.isEmpty) return 'false';
        final channelId = id(query);
        final values = await call.context.budget.run(
          () => service.channels(
            includeActiveThreads: true,
            budget: call.context.budget,
          ),
        );
        return '${values.any((c) => channelId != null ? c.id == channelId : c.name == query)}';
      },
    ),

    'channelposition': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final selected = await channel(
          call,
          call.argumentCount == 1
              ? await call.argument(0)
              : call.context.variables['channel.id'] ?? '',
        );
        return selected.position?.toString() ?? '';
      },
    ),

    'categorychannels': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 3,
      handler: (call) async {
        final categoryId = id(await call.argument(0));
        final separator = await call.argument(1);
        final option = call.argumentCount == 3
            ? (await call.argument(2)).trim().toLowerCase()
            : 'name';
        if (categoryId == null) {
          throw BdfdNativeError('Invalid category ID.', call.location);
        }
        if (!const ['name', 'id', 'mention', 'count'].contains(option)) {
          throw BdfdNativeError(
            'Invalid category channel option.',
            call.location,
          );
        }
        final category = await channel(call, categoryId);
        if (category.type != 'category' || category.guildId == null) {
          throw BdfdNativeError(
            'Channel is not a guild category.',
            call.location,
          );
        }
        final values = await call.context.budget.run(
          () => service.channels(
            guildId: category.guildId,
            budget: call.context.budget,
          ),
        );
        final children = values
            .where((c) => c.parentId == categoryId && c.type != 'category')
            .toList();
        if (option == 'count') return '${children.length}';
        return children
            .map(
              (c) => switch (option) {
                'id' => c.id,
                'mention' => '<#${c.id}>',
                _ => c.name,
              },
            )
            .join(separator);
      },
    ),
    'channelid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) => call.argumentCount == 0
          ? bdfdCurrentChannelId(call.context.variables)
          : byName(call),
    ),
    'categoryid': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) => byName(call, categoryOnly: true),
    ),
    'parentid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          (await channel(
            call,
            call.argumentCount == 1
                ? await call.argument(0)
                : call.context.variables['channel.id'] ?? '',
          )).parentId ??
          '',
    ),
    'findchannel': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final query = (await call.argument(0)).trim();
        if (query.isEmpty) return '';
        final mention = RegExp(r'^<#(\d+)>$').firstMatch(query);
        final channelId = id(mention?.group(1) ?? query);
        final values = await call.context.budget.run(
          () => service.channels(
            includeActiveThreads: true,
            budget: call.context.budget,
          ),
        );
        if (channelId != null) {
          return values.where((c) => c.id == channelId).firstOrNull?.id ?? '';
        }
        final lower = query.toLowerCase();
        return values
                .where((c) => c.name.toLowerCase() == lower)
                .firstOrNull
                ?.id ??
            values
                .where((c) => c.name.toLowerCase().contains(lower))
                .firstOrNull
                ?.id ??
            '';
      },
    ),

    'channelcount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          '${await call.context.budget.run(() => service.countChannels(budget: call.context.budget))}',
    ),
    'categorycount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final guild = call.argumentCount == 1
            ? id(await call.argument(0))
            : null;
        if (call.argumentCount == 1 && guild == null) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
        final values = await call.context.budget.run(
          () => service.channels(guildId: guild, budget: call.context.budget),
        );
        return '${values.where((c) => c.type == 'category').length}';
      },
    ),
    'channelname': field((c) => c.name),
    'channeltype': field((c) => c.type),
    'isnsfw': field((c) => '${c.isNsfw}'),
    'channeltopic': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => (await channel(
        call,
        call.context.variables['channel.id'] ?? '',
      )).topic,
    ),
    'channelexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final parsed = id(await call.argument(0));
        if (parsed == null) return 'false';
        final value = await call.context.budget.run(
          () => service.channel(parsed, budget: call.context.budget),
        );
        return '${value != null}';
      },
    ),
    'channelnames': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final separator = await call.argument(0);
        final guild = call.argumentCount == 2
            ? id(await call.argument(1))
            : null;
        if (call.argumentCount == 2 && guild == null) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
        final values = await call.context.budget.run(
          () => service.channels(guildId: guild, budget: call.context.budget),
        );
        return values.map((c) => c.name).join(separator);
      },
    ),
    'channelcategoryid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          (await channel(
            call,
            call.argumentCount == 1
                ? await call.argument(0)
                : call.context.variables['channel.id'] ?? '',
          )).parentId ??
          '',
    ),
    'channelidfromname': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) => byName(call),
    ),
    'channelnsfw': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          '${(await channel(call, call.argumentCount == 1 ? await call.argument(0) : call.context.variables['channel.id'] ?? '')).isNsfw}',
    ),
    'voiceuserlimit': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        await channel(
          call,
          call.argumentCount == 1
              ? await call.argument(0)
              : call.context.variables['channel.id'] ?? '',
        );
        return call.context.variables['channel.userLimit'] ?? '0';
      },
    ),
  };
}
