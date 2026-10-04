import 'package:bot_creator_shared/engine/bdfd/guild_query_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/discord_entity_fetcher.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_guild_query_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

const _guild = BotGuild(
  id: '10',
  name: 'BDFD',
  ownerId: '20',
  description: 'Community',
  verificationLevel: 4,
  iconUrl: 'https://cdn/icon.png',
  bannerUrl: 'https://cdn/banner.png',
  boostCount: 14,
  boostLevel: 3,
  afkTimeoutSeconds: 300,
);

class _Queries implements BotGuildQueryService {
  BotGuild? value = _guild;
  List<BotGuild> values = [_guild];
  final selected = <String?>[];
  final budgets = <CommandExecutionBudget>[];
  Object? error;
  Duration delay = Duration.zero;
  int listReads = 0;
  @override
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    selected.add(guildId);
    budgets.add(budget);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<List<BotGuild>> guilds({
    required CommandExecutionBudget budget,
  }) async {
    listReads++;
    budgets.add(budget);
    if (error != null) throw error!;
    return values;
  }
}

BdfdRuntime _runtime(BotGuildQueryService q) =>
    BdfdRuntime(functions: bdfdGuildQueryFunctions(q));

class _SdkGuild implements Guild {
  _SdkGuild({
    this.iconHash,
    this.bannerHash,
    this.premiumSubscriptionCount = 14,
  });
  @override
  Snowflake get id => Snowflake(10);
  @override
  String get name => 'BDFD';
  @override
  Snowflake get ownerId => Snowflake(20);
  @override
  String? get description => 'Community';
  @override
  VerificationLevel get verificationLevel => VerificationLevel.veryHigh;
  @override
  final String? iconHash;
  @override
  final String? bannerHash;
  @override
  final int? premiumSubscriptionCount;
  @override
  PremiumTier get premiumTier => PremiumTier.three;
  @override
  Duration get afkTimeout => const Duration(seconds: 300);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserGuild implements UserGuild {
  _UserGuild(int id, this.name) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Guilds implements GuildManager {
  final reads = <Snowflake>[];
  Guild value = _SdkGuild();
  Object? error;
  Duration delay = Duration.zero;
  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) async {
    reads.add(id);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (error != null) throw error!;
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserManager {
  List<List<UserGuild>> pages = [[]];
  final cursors = <Snowflake?>[];
  final limits = <int?>[];
  Object? error;
  @override
  Future<List<UserGuild>> listCurrentUserGuilds({
    Snowflake? after,
    Snowflake? before,
    int? limit,
    bool? withCounts,
  }) async {
    cursors.add(after);
    limits.add(limit);
    if (error != null) throw error!;
    return pages[(cursors.length - 1).clamp(0, pages.length - 1)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  @override
  final _Guilds guilds = _Guilds();
  @override
  final _Users users = _Users();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DiscordError implements HttpResponseError {
  _DiscordError(this.statusCode, this.errorCode);
  @override
  final int statusCode;
  @override
  final int errorCode;
  @override
  String toString({bool short = false}) => 'Discord error $errorCode';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final fields = {
    'serverOwner': '20',
    'serverDescription': 'Community',
    'serverVerificationLvl': 'Very High',
    'serverIcon': 'https://cdn/icon.png',
    'boostCount': '14',
    'boostLevel': '3',
    'afkTimeout': '300',
  };
  for (final entry in fields.entries) {
    test(
      '${entry.key} reads current server freshly with shared budget',
      () async {
        final q = _Queries();
        final context = BdfdContext();
        expect(
          await _runtime(
            q,
          ).execute('\$${entry.key}|\$${entry.key}', context: context),
          '${entry.value}|${entry.value}',
        );
        expect(q.selected, [null, null]);
        expect(q.budgets.every((b) => identical(b, context.budget)), true);
      },
    );
  }
  test('verification levels map all five official labels', () async {
    final q = _Queries();
    final names = ['None', 'Low', 'Medium', 'High', 'Very High'];
    for (var i = 0; i < names.length; i++) {
      q.value = BotGuild(id: '10', name: 'BDFD', verificationLevel: i);
      expect(await _runtime(q).execute(r'$serverVerificationLvl'), names[i]);
    }
    q.value = const BotGuild(id: '10', name: 'BDFD', verificationLevel: 5);
    await expectLater(
      _runtime(q).execute(r'$serverVerificationLvl'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test('guildBanner requires explicit ID and passes it once', () async {
    final q = _Queries();
    expect(
      await _runtime(q).execute(r'$guildBanner[ 10 ]'),
      'https://cdn/banner.png',
    );
    expect(q.selected, ['10']);
    for (final source in [r'$guildBanner', r'$guildBanner[10;yes]']) {
      expect(
        () => _runtime(q).prepare(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    await expectLater(
      _runtime(q).execute(r'$guildBanner[]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(q.selected, ['10']);
  });
  test('AFK timeout supports absent, empty and explicit guild ID', () async {
    final q = _Queries();
    expect(
      await _runtime(q).execute(r'$afkTimeout|$afkTimeout[]|$afkTimeout[11]'),
      '300|300|300',
    );
    expect(q.selected, [null, null, '11']);
    await expectLater(
      _runtime(q).execute(r'$afkTimeout[bad]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(q.selected.length, 3);
  });
  test('empty description and missing media return empty text', () async {
    final q = _Queries()..value = const BotGuild(id: '10', name: 'BDFD');
    expect(
      await _runtime(
        q,
      ).execute(r'[$serverDescription]|[$serverIcon]|[$guildBanner[10]]'),
      '[]|[]|[]',
    );
  });
  test('unavailable numeric metadata is not fabricated as zero', () async {
    final q = _Queries()..value = const BotGuild(id: '10', name: 'BDFD');
    for (final name in [
      'serverOwner',
      'serverVerificationLvl',
      'boostCount',
      'boostLevel',
      'afkTimeout',
    ]) {
      await expectLater(
        _runtime(q).execute('\$$name'),
        throwsA(isA<BdfdNativeError>()),
      );
    }
  });
  test('missing guild makes exists false and field reads fail', () async {
    final q = _Queries()..value = null;
    expect(await _runtime(q).execute(r'$guildExists[10]'), 'false');
    await expectLater(
      _runtime(q).execute(r'$serverOwner'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'guildExists rejects non IDs and empty before reading service',
    () async {
      final q = _Queries();
      expect(
        await _runtime(q).execute(
          r'$guildExists[]|$guildExists[bad]|$guildExists[0]|$guildExists[-1]',
        ),
        'false|false|false|false',
      );
      expect(q.selected, isEmpty);
      expect(await _runtime(q).execute(r'$guildExists[ 10 ]'), 'true');
      expect(q.selected, ['10']);
    },
  );
  test(
    'serverCount counts all servers; serverNames returns ten with official delimiter',
    () async {
      final q = _Queries()
        ..values = List.generate(
          12,
          (i) => BotGuild(id: '${i + 1}', name: 'Guild ${i + 1}'),
        );
      expect(await _runtime(q).execute(r'$serverCount'), '12');
      expect(
        await _runtime(q).execute(r'$serverNames'),
        List.generate(10, (i) => 'Guild ${i + 1}').join(', '),
      );
      expect(q.listReads, 2);
      q.values = [];
      expect(await _runtime(q).execute(r'$serverCount|$serverNames'), '0|');
    },
  );
  test(
    'guild strings remain data and unknown calls keep arguments opaque',
    () async {
      final q = _Queries()
        ..value = const BotGuild(
          id: '10',
          name: 'BDFD',
          description: r'$var[effect;yes]',
        );
      final context = BdfdContext();
      expect(
        await _runtime(q).execute(
          r'$serverDescription|$futureGuild[$guildExists[10]]',
          context: context,
        ),
        r'$var[effect;yes]|$futureGuild[$guildExists[10]]',
      );
      expect(q.selected, [null]);
      expect(context.temporaryVariables, isEmpty);
    },
  );
  test('unconfirmed aliases remain catalogue unsupported at preflight', () {
    final runtime = _runtime(_Queries());
    for (final name in [
      'serverExists',
      'guildCount',
      'serverVerificationLevel',
      'serverFeatures',
      'guildIcon',
      'serverBanner',
      'serverSplash',
      'serverVanityURL',
      'serverBoostCount',
    ]) {
      expect(() => runtime.prepare('\$$name'), throwsA(isA<BdfdNativeError>()));
    }
  });
  test(
    'native read errors remain catchable and are not converted to existence false',
    () async {
      final q = _Queries()..error = StateError('Read denied');
      await expectLater(
        _runtime(q).execute(r'$guildExists[10]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        await _runtime(q).execute(
          r'$try'
          '\n'
          r'$guildExists[10]'
          '\n'
          r'$catch'
          '\n'
          'Caught'
          '\n'
          r'$endtry',
        ),
        contains('Caught'),
      );
    },
  );
  test('slow service shares native deadline', () async {
    final q = _Queries()..delay = const Duration(milliseconds: 50);
    await expectLater(
      _runtime(q).execute(
        r'$serverOwner',
        context: BdfdContext(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test(
    'SDK fresh reads map all fields and animated CDN hashes without downloading',
    () async {
      final gateway = _Gateway();
      gateway.guilds.value = _SdkGuild(
        iconHash: 'a_icon',
        bannerHash: 'banner',
      );
      final service = DiscordBotGuildQueryService(
        client: gateway,
        guildId: Snowflake(10),
      );
      final budget = CommandExecutionBudget();
      final value = (await service.guild(budget: budget))!;
      expect(value.ownerId, '20');
      expect(value.description, 'Community');
      expect(value.verificationLevel, 4);
      expect(value.boostCount, 14);
      expect(value.boostLevel, 3);
      expect(value.afkTimeoutSeconds, 300);
      expect(value.iconUrl, 'https://cdn.discordapp.com/icons/10/a_icon.gif');
      expect(
        value.bannerUrl,
        'https://cdn.discordapp.com/banners/10/banner.png',
      );
      await service.guild(guildId: '11', budget: budget);
      expect(gateway.guilds.reads.map((v) => '$v'), ['10', '11']);
    },
  );
  test(
    'SDK missing guild and missing access return null, unrelated errors propagate',
    () async {
      final gateway = _Gateway();
      final service = DiscordBotGuildQueryService(
        client: gateway,
        guildId: Snowflake(10),
      );
      for (final error in [
        const DiscordEntityNotFound(),
        _DiscordError(404, 10004),
        _DiscordError(403, 50001),
      ]) {
        gateway.guilds.error = error;
        expect(await service.guild(budget: CommandExecutionBudget()), isNull);
      }
      for (final error in [
        _DiscordError(403, 50013),
        _DiscordError(500, 0),
        StateError('Bad fixture'),
      ]) {
        gateway.guilds.error = error;
        await expectLater(
          service.guild(budget: CommandExecutionBudget()),
          throwsA(same(error)),
        );
      }
    },
  );
  test(
    'SDK no invoking guild and invalid explicit ID fail before HTTP',
    () async {
      final gateway = _Gateway();
      final service = DiscordBotGuildQueryService(client: gateway);
      await expectLater(
        service.guild(budget: CommandExecutionBudget()),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        service.guild(guildId: 'bad', budget: CommandExecutionBudget()),
        throwsA(isA<ArgumentError>()),
      );
      expect(gateway.guilds.reads, isEmpty);
    },
  );
  test('SDK missing optional boost count remains unavailable', () async {
    final gateway = _Gateway();
    gateway.guilds.value = _SdkGuild(premiumSubscriptionCount: null);
    final value = await DiscordBotGuildQueryService(
      client: gateway,
      guildId: Snowflake(10),
    ).guild(budget: CommandExecutionBudget());
    expect(value!.boostCount, isNull);
    expect(value.iconUrl, isNull);
    expect(value.bannerUrl, isNull);
  });
  test(
    'documented zero-argument fields reject arguments before service reads',
    () {
      final q = _Queries();
      final runtime = _runtime(q);
      for (final name in [
        'serverOwner',
        'serverDescription',
        'serverVerificationLvl',
        'serverIcon',
        'boostCount',
        'boostLevel',
        'serverCount',
        'serverNames',
      ]) {
        expect(
          () => runtime.prepare('\$$name[10]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(q.selected, isEmpty);
      expect(q.listReads, 0);
    },
  );
  test('SDK guild list paginates past 200 and deduplicates IDs', () async {
    final gateway = _Gateway();
    gateway.users.pages = [
      List.generate(200, (i) => _UserGuild(i + 1, 'Guild ${i + 1}')),
      [_UserGuild(200, 'Guild 200'), _UserGuild(201, 'Guild 201')],
    ];
    final values = await DiscordBotGuildQueryService(
      client: gateway,
    ).guilds(budget: CommandExecutionBudget());
    expect(values.length, 201);
    expect(values.first.id, '1');
    expect(values.last.id, '201');
    expect(gateway.users.cursors.map((v) => v?.toString()), [null, '200']);
    expect(gateway.users.limits, [200, 200]);
    expect(gateway.guilds.reads, isEmpty);
  });
  test(
    'SDK full page with stagnant cursor fails rather than looping forever',
    () async {
      final gateway = _Gateway();
      gateway.users.pages = [
        List.generate(200, (i) => _UserGuild(i + 1, 'Guild')),
      ];
      await expectLater(
        DiscordBotGuildQueryService(
          client: gateway,
        ).guilds(budget: CommandExecutionBudget()),
        throwsA(isA<StateError>()),
      );
      expect(gateway.users.cursors.length, 2);
    },
  );
  test('SDK list errors and expired budgets propagate', () async {
    final gateway = _Gateway();
    final error = StateError('List denied');
    gateway.users.error = error;
    await expectLater(
      DiscordBotGuildQueryService(
        client: gateway,
      ).guilds(budget: CommandExecutionBudget()),
      throwsA(same(error)),
    );
    await expectLater(
      DiscordBotGuildQueryService(
        client: gateway,
      ).guilds(budget: CommandExecutionBudget(limit: Duration.zero)),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(gateway.users.cursors.length, 1);
  });
  test('SDK late guild response cannot bypass shared deadline', () async {
    final gateway = _Gateway();
    gateway.guilds.delay = const Duration(milliseconds: 50);
    await expectLater(
      DiscordBotGuildQueryService(
        client: gateway,
        guildId: Snowflake(10),
      ).guild(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
}
