import '../../services/bot_guild_query_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdGuildQueryFunctions(
  BotGuildQueryService service,
) {
  String? id(String raw) {
    final text = raw.trim();
    final value = RegExp(r'^[0-9]+$').hasMatch(text)
        ? int.tryParse(text)
        : null;
    return value == null || value <= 0 ? null : '$value';
  }

  Future<BotGuild> guild(BdfdInvocation call, {bool requiredId = false}) async {
    String? selected;
    if (call.argumentCount > 0) {
      final raw = (await call.argument(0)).trim();
      if (raw.isNotEmpty || requiredId) {
        selected = id(raw);
        if (selected == null) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
      }
    }
    final value = await call.context.budget.run(
      () => service.guild(guildId: selected, budget: call.context.budget),
    );
    if (value == null) throw BdfdNativeError('Guild not found.', call.location);
    return value;
  }

  BdfdNativeFunction field(
    String Function(BotGuild guild, BdfdInvocation call) read, {
    int minArguments = 0,
    int maxArguments = 0,
  }) => BdfdNativeFunction(
    minArguments: minArguments,
    maxArguments: maxArguments,
    handler: (call) async =>
        read(await guild(call, requiredId: minArguments == 1), call),
  );

  String requiredField(Object? value, String label, BdfdInvocation call) {
    if (value == null) {
      throw BdfdNativeError('Guild $label is unavailable.', call.location);
    }
    return '$value';
  }

  Future<List<BotGuild>> guilds(BdfdInvocation call) => call.context.budget.run(
    () => service.guilds(budget: call.context.budget),
  );

  return {
    'guildexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final selected = id(await call.argument(0));
        if (selected == null) return 'false';
        final value = await call.context.budget.run(
          () => service.guild(guildId: selected, budget: call.context.budget),
        );
        return '${value != null}';
      },
    ),
    'servercount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async => '${(await guilds(call)).length}',
    ),
    'servernames': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        final values = await guilds(call);
        final names = <String>[];
        for (final value in values.take(10)) {
          call.context.budget.check();
          names.add(value.name);
        }
        return names.join(', ');
      },
    ),
    'serverowner': field(
      (guild, call) => requiredField(guild.ownerId, 'owner', call),
    ),
    'serverdescription': field((guild, _) => guild.description ?? ''),
    'serververificationlvl': field((guild, call) {
      final level = guild.verificationLevel;
      const labels = ['None', 'Low', 'Medium', 'High', 'Very High'];
      if (level == null || level < 0 || level >= labels.length) {
        throw BdfdNativeError(
          'Guild verification level is unavailable.',
          call.location,
        );
      }
      return labels[level];
    }),
    'servericon': field((guild, _) => guild.iconUrl ?? ''),
    'guildbanner': field(
      (guild, _) => guild.bannerUrl ?? '',
      minArguments: 1,
      maxArguments: 1,
    ),
    'boostcount': field(
      (guild, call) => requiredField(guild.boostCount, 'boost count', call),
    ),
    'boostlevel': field(
      (guild, call) => requiredField(guild.boostLevel, 'boost level', call),
    ),
    'afktimeout': field(
      (guild, call) =>
          requiredField(guild.afkTimeoutSeconds, 'AFK timeout', call),
      maxArguments: 1,
    ),
  };
}

Map<String, BdfdNativeFunction> bdfdGuildQueryAliases([
  BotGuildQueryService? service,
]) {
  String? id(String raw) {
    final text = raw.trim();
    final value = RegExp(r'^[0-9]+$').hasMatch(text)
        ? int.tryParse(text)
        : null;
    return value == null || value <= 0 ? null : '$value';
  }

  Future<BotGuild?> guild(
    BdfdInvocation call, {
    bool requiredId = false,
  }) async {
    if (service == null) return null;
    String? selected;
    if (call.argumentCount > 0) {
      final raw = (await call.argument(0)).trim();
      if (raw.isNotEmpty || requiredId) {
        selected = id(raw);
        if (selected == null) {
          throw BdfdNativeError('Invalid guild ID.', call.location);
        }
      }
    }
    return await call.context.budget.run(
      () => service.guild(guildId: selected, budget: call.context.budget),
    );
  }

  return {
    'serverexists': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final selected = id(await call.argument(0));
        if (selected == null) return 'false';
        if (service == null) return 'false';
        final value = await call.context.budget.run(
          () => service.guild(guildId: selected, budget: call.context.budget),
        );
        return '${value != null}';
      },
    ),
    'guildcount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        if (service != null) {
          final list = await call.context.budget.run(
            () => service.guilds(budget: call.context.budget),
          );
          return '${list.length}';
        }
        return call.context.variables['bot.guildCount'] ?? '1';
      },
    ),
    // Wiki: $serverName[Guild ID]. Without an ID the hydrated current guild
    // name is used.
    for (final name in const ['servername', 'guildname'])
      name: BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 1,
        handler: (call) async {
          if (call.argumentCount == 0) {
            final hydrated = call.context.variables['guild.name'];
            if (hydrated != null) return hydrated;
          }
          final g = await guild(call, requiredId: call.argumentCount == 1);
          if (g == null) {
            throw BdfdNativeError('Guild not found.', call.location);
          }
          return g.name;
        },
      ),
    'guildicon': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final g = await guild(call);
        return g?.iconUrl ?? call.context.variables['guild.icon'] ?? '';
      },
    ),
    'serverbanner': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final g = await guild(call);
        return g?.bannerUrl ?? call.context.variables['guild.banner'] ?? '';
      },
    ),
    'serverboostcount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final g = await guild(call);
        if (g?.boostCount != null) return '${g!.boostCount}';
        return call.context.variables['guild.boostCount'] ?? '0';
      },
    ),
    'serververificationlevel': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final g = await guild(call);
        final level = g?.verificationLevel;
        const labels = ['None', 'Low', 'Medium', 'High', 'Very High'];
        if (level != null && level >= 0 && level < labels.length) {
          return labels[level];
        }
        return call.context.variables['guild.verificationLevel'] ?? 'None';
      },
    ),
    'serverfeatures': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => call.context.variables['guild.features'] ?? '',
    ),
    'serverinfo': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async => call.context.variables['guild.info'] ?? '',
    ),
    'serverregion': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => call.context.variables['guild.region'] ?? '',
    ),
    'serversplash': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => call.context.variables['guild.splash'] ?? '',
    ),
    'servervanityurl': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async =>
          call.context.variables['guild.vanityUrlCode'] ?? '',
    ),
    'randomguildid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async {
        if (service != null) {
          final list = await call.context.budget.run(
            () => service.guilds(budget: call.context.budget),
          );
          if (list.isNotEmpty) {
            return list[call.context.random.nextInt(list.length)].id;
          }
        }
        return call.context.variables['guild.id'] ?? '';
      },
    ),
    'getserverinvite': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async => call.context.variables['guild.invite'] ?? '',
    ),
  };
}
