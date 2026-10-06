import 'dart:math';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/member_query_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_member_query_service.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Queries implements BotMemberQueryService {
  List<BotGuildMember> values = [
    const BotGuildMember(
      id: '20',
      username: 'rainbow_key',
      nickname: 'RainbowKey',
    ),
    const BotGuildMember(id: '21', username: 'BDFD Support', isBot: true),
    BotGuildMember(
      id: '22',
      username: 'numeric',
      premiumSince: DateTime.utc(2020),
      communicationDisabledUntil: DateTime.utc(2030),
    ),
  ];
  final requests = <String>[];
  final budgets = <CommandExecutionBudget>[];
  Object? failure;
  @override
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    requests.add('list:${guildId ?? "current"}');
    budgets.add(budget);
    if (failure != null) throw failure!;
    return values;
  }

  @override
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    requests.add('member:$userId:${guildId ?? "current"}');
    budgets.add(budget);
    if (failure != null) throw failure!;
    return values.where((value) => value.id == userId).firstOrNull;
  }

  @override
  Future<int> allGuildMembersCount({
    required CommandExecutionBudget budget,
  }) async {
    requests.add('all-count');
    budgets.add(budget);
    return 20560;
  }
}

BdfdEngine _engine(BotMemberQueryService service) => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  functions: bdfdMemberQueryFunctions(service),
);
BdfdContext _context({
  Random? random,
  DateTime Function()? clock,
  CommandExecutionBudget? budget,
}) => BdfdContext(
  variables: {'author.id': '20'},
  random: random,
  clock: clock,
  budget: budget,
);

class _Random implements Random {
  _Random(this.index);
  final int index;
  final limits = <int>[];
  @override
  int nextInt(int max) {
    limits.add(max);
    return index;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(this.id);
  @override
  final Snowflake id;
  @override
  String get username => 'user-$id';
  @override
  bool get isBot => id.value.isEven;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Member implements Member {
  _Member(int id, {this.hasUser = true}) : id = Snowflake(id);
  final bool hasUser;
  @override
  final Snowflake id;
  @override
  User? get user => hasUser ? _User(id) : null;
  @override
  String? get nick => 'nick-$id';
  @override
  List<Snowflake> get roleIds => [Snowflake(60), Snowflake(61)];
  @override
  DateTime? get premiumSince => DateTime.utc(2020);
  @override
  DateTime? get communicationDisabledUntil => DateTime.utc(2030);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Error implements HttpResponseError {
  _Error(this.statusCode, this.errorCode);
  @override
  final int statusCode;
  @override
  final int errorCode;
  @override
  String toString({bool short = false}) => 'API error';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Members implements MemberManager {
  _Members({Map<int, List<Member>>? pages})
    : pages =
          pages ??
          {
            0: [_Member(20)],
          };
  final Map<int, List<Member>> pages;
  Object? failure;
  Duration delay = Duration.zero;
  Member result = _Member(20);
  final requests = <({int? limit, Snowflake? after})>[];
  final fetches = <Snowflake>[];
  @override
  Future<List<Member>> list({int? limit, Snowflake? after}) async {
    requests.add((limit: limit, after: after));
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (failure != null) throw failure!;
    return pages[after?.value ?? 0] ?? [];
  }

  @override
  Future<Member> fetch(Snowflake id) async {
    fetches.add(id);
    if (failure != null) throw failure!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected member operation ${invocation.memberName}');
}

class _Guild implements PartialGuild {
  _Guild(this.members);
  @override
  final MemberManager members;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Guilds implements GuildManager {
  final managers = <Snowflake, _Members>{};
  final selected = <Snowflake>[];
  @override
  PartialGuild operator [](Snowflake id) {
    selected.add(id);
    return _Guild(managers.putIfAbsent(id, () => _Members()));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UserGuild implements UserGuild {
  _UserGuild(int id) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserManager {
  final pages = <int, List<UserGuild>>{};
  final requests = <({int? limit, Snowflake? after})>[];
  final fetches = <Snowflake>[];
  @override
  Future<List<UserGuild>> listCurrentUserGuilds({
    Snowflake? after,
    Snowflake? before,
    int? limit,
    bool? withCounts,
  }) async {
    requests.add((limit: limit, after: after));
    return pages[after?.value ?? 0] ?? [];
  }

  @override
  Future<User> fetch(Snowflake id) async {
    fetches.add(id);
    return _User(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected user operation ${invocation.memberName}');
}

class _Gateway implements NyxxGateway {
  @override
  final _Guilds guilds = _Guilds();
  @override
  final _Users users = _Users();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected SDK operation ${invocation.memberName}');
}

void main() {
  test(
    'production sandbox delegates guild member queries to fixtures without writes',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$membersCount|$allMembersCount|$findUser[BDFD Support]|$isBooster[20;11]|$isTimedOut[21]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'author.id': '20'},
        'entities': {
          'users': {
            '20': {'username': 'ordinary'},
            '21': {'username': 'BDFD Support', 'bot': true},
          },
          'guilds': {
            '10': {
              'members': {
                '20': <String, dynamic>{},
                '21': {'communication_disabled_until': '2099-01-01T00:00:00Z'},
              },
            },
            '11': {
              'members': {
                '20': {'premium_since': '2020-01-01T00:00:00Z'},
              },
            },
          },
        },
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '2|3|21|true|true');
      expect(result['effects'], isEmpty);
      final requests = result['entity_requests'] as List;
      expect(
        requests.any((request) => request['operation'] == 'users.guilds'),
        true,
      );
      expect(
        requests.any((request) => request['operation'] == 'members.list'),
        true,
      );
    },
  );
  test(
    'sandbox absent member differs from present member with absent user data',
    () async {
      for (final entry in {
        r'$findUser[<@99>;no]': true,
        r'$findUser[20;no]': false,
      }.entries) {
        final result = await testCommandInSandbox({
          'script': entry.key,
          'bdfdBackend': 'native-v1',
          'variables': {'guild.id': '10'},
          'entities': {
            'users': <String, dynamic>{},
            'guilds': {
              '10': {
                'members': {'20': <String, dynamic>{}},
              },
            },
          },
        });
        expect(result['success'], entry.value, reason: '$result');
        expect(result['effects'], isEmpty);
      }
    },
  );
  test(
    'sandbox incomplete or malformed member population errors instead of reporting zero',
    () async {
      for (final guild in [
        {'name': 'no-members'},
        {
          'members': {'invalid-id': <String, dynamic>{}},
        },
      ]) {
        final result = await testCommandInSandbox({
          'script': r'$membersCount',
          'bdfdBackend': 'native-v1',
          'variables': {'guild.id': '10'},
          'entities': {
            'guilds': {'10': guild},
          },
        });
        expect(result['success'], false, reason: '$result');
        expect(result['effects'], isEmpty);
      }
    },
  );
  test(
    'findUser searches username ID and both Discord mention forms in current guild',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      for (final source in [
        r'$findUser[BDFD Support]',
        r'$findUser[21]',
        r'$findUser[<@21>]',
        r'$findUser[<@!21>]',
      ]) {
        expect(await engine.execute(source, context: _context()), '21');
      }
      expect(queries.requests, [
        'list:current',
        'member:21:current',
        'member:21:current',
        'member:21:current',
      ]);
      queries.values.add(const BotGuildMember(id: '23', username: '99'));
      expect(await engine.execute(r'$findUser[99]', context: _context()), '23');
    },
  );
  test(
    'findUser documented author fallback and false fallback handle missing or empty text',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      for (final source in [
        r'$findUser[]',
        r'$findUser[missing]',
        r'$findUser[<@99>]',
      ]) {
        expect(await engine.execute(source, context: _context()), '20');
      }
      expect(await engine.execute(r'$findUser[missing;no]'), '');
      expect(await engine.execute(r'$findUser[;false]'), '');
      expect(await engine.execute(r'$findUser[rainbow_key;no]'), '20');
      await expectLater(
        engine.execute(r'$findUser[missing;invalid]', context: _context()),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'findUser does not substitute nickname global name or fuzzy case matching',
    () async {
      final engine = _engine(_Queries());
      expect(await engine.execute(r'$findUser[RainbowKey;no]'), '');
      expect(await engine.execute(r'$findUser[RAINBOW_KEY;no]'), '');
      expect(await engine.execute(r'$findUser[rainbow;no]'), '');
    },
  );
  test(
    'random functions use entire current-guild population including bot',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      final random = _Random(1);
      expect(
        await engine.execute(
          r'$randomUserID',
          context: _context(random: random),
        ),
        '21',
      );
      expect(
        await engine.execute(r'$randomUser', context: _context(random: random)),
        'BDFD Support',
      );
      expect(
        await engine.execute(
          r'$randomMention',
          context: _context(random: random),
        ),
        '<@21>',
      );
      expect(random.limits, [3, 3, 3]);
      expect(queries.requests, [
        'list:current',
        'list:current',
        'list:current',
      ]);
    },
  );
  test(
    'empty random population returns empty without selecting random index',
    () async {
      final queries = _Queries()..values = [];
      final random = _Random(0);
      for (final source in [
        r'$randomUserID',
        r'$randomUser',
        r'$randomMention',
      ]) {
        expect(
          await _engine(
            queries,
          ).execute(source, context: _context(random: random)),
          '',
        );
      }
      expect(random.limits, isEmpty);
    },
  );
  test(
    'membersCount and allMembersCount use distinct service scopes',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      expect(await engine.execute(r'$membersCount'), '3');
      expect(await engine.execute(r'$allMembersCount'), '20560');
      expect(queries.requests, ['list:current', 'all-count']);
    },
  );
  test(
    'isBooster supports documented empty author and optional guild scope',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      expect(
        await engine.execute(r'$isBooster[]', context: _context()),
        'false',
      );
      expect(await engine.execute(r'$isBooster', context: _context()), 'false');
      expect(await engine.execute(r'$isBooster[22]'), 'true');
      expect(await engine.execute(r'$isBooster[22;11]'), 'true');
      expect(
        await engine.execute(r'$isBooster[;11]', context: _context()),
        'false',
      );
      expect(await engine.execute(r'$isBooster[22;]'), 'true');
      expect(queries.requests, [
        'member:20:current',
        'member:20:current',
        'member:22:current',
        'member:22:11',
        'member:20:11',
        'member:22:current',
      ]);
    },
  );
  test(
    'isTimedOut checks expiration against invocation clock including equality boundary',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      expect(
        await engine.execute(
          r'$isTimedOut[22]',
          context: _context(clock: () => DateTime.utc(2029)),
        ),
        'true',
      );
      expect(
        await engine.execute(
          r'$isTimedOut[22]',
          context: _context(clock: () => DateTime.utc(2030)),
        ),
        'false',
      );
      expect(
        await engine.execute(
          r'$isTimedOut[22]',
          context: _context(clock: () => DateTime.utc(2031)),
        ),
        'false',
      );
      expect(await engine.execute(r'$isTimedOut[20]'), 'false');
    },
  );
  test(
    'missing member and required invalid ID errors do not silently return false',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      for (final source in [r'$isTimedOut[99]', r'$isBooster[99]']) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      queries.requests.clear();
      for (final source in [
        r'$isTimedOut[]',
        r'$isTimedOut[0]',
        r'$isTimedOut[<@20>]',
        r'$isBooster[-1]',
        r'$isBooster[20;bad]',
        r'$isTimedOut[0x14]',
      ]) {
        await expectLater(
          engine.execute(source, context: _context()),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(queries.requests, isEmpty);
    },
  );
  test(
    'bad arity and unsupported presence form fail preflight before effects',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      for (final source in [
        r'$findUser',
        r'$findUser[x;yes;extra]',
        r'$randomUserID[20]',
        r'$randomUser[20]',
        r'$randomMention[20]',
        r'$membersCount[online]',
        r'$allMembersCount[online]',
        r'$isTimedOut',
        r'$isTimedOut[20;10]',
        r'$isBooster[20;10;extra]',
      ]) {
        final context = _context();
        await expectLater(
          engine.execute(r'$var[bad;1]' + source, context: context),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(context.temporaryVariables['bad'], isNull);
      }
      expect(queries.requests, isEmpty);
    },
  );
  test(
    'unknown functions are opaque and result data is not reparsed',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      final context = _context();
      const source = r'$unknown[$randomUserID;$var[bad;1]]';
      expect(await engine.execute(source, context: context), source);
      expect(queries.requests, isEmpty);
      expect(context.temporaryVariables['bad'], isNull);
      queries.values = [
        const BotGuildMember(id: '20', username: r'$var[bad;1]'),
      ];
      expect(
        await engine.execute(r'$randomUser', context: context),
        r'$var[bad;1]',
      );
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test(
    'SDK reads all member pages and deduplicates overlap with advancing cursor',
    () async {
      final client = _Gateway();
      final manager = _Members(
        pages: {
          0: List.generate(1000, (i) => _Member(i + 1)),
          1000: [_Member(1000), _Member(1001)],
        },
      );
      client.guilds.managers[Snowflake(10)] = manager;
      final service = DiscordBotMemberQueryService(
        client: client,
        guildId: Snowflake(10),
      );
      final members = await service.guildMembers(
        budget: CommandExecutionBudget(),
      );
      expect(members.length, 1001);
      expect(members.last.id, '1001');
      expect(manager.requests, [
        (limit: 1000, after: null),
        (limit: 1000, after: Snowflake(1000)),
      ]);
      expect(members.first.username, 'user-1');
      expect(members.first.nickname, 'nick-1');
      expect(members.first.isBot, false);
      expect(members.first.roleIds, ['60', '61']);
      expect(members.first.premiumSince, DateTime.utc(2020));
      expect(members.first.communicationDisabledUntil, DateTime.utc(2030));
      expect(() => members.add(members.first), throwsUnsupportedError);
      expect(() => members.first.roleIds.add('62'), throwsUnsupportedError);
    },
  );
  test(
    'SDK single member uses explicit guild and fetches absent embedded user',
    () async {
      final client = _Gateway();
      final manager = _Members()..result = _Member(20, hasUser: false);
      client.guilds.managers[Snowflake(11)] = manager;
      final service = DiscordBotMemberQueryService(
        client: client,
        guildId: Snowflake(10),
      );
      final value = await service.guildMember(
        '20',
        guildId: '11',
        budget: CommandExecutionBudget(),
      );
      expect(value!.username, 'user-20');
      expect(client.users.fetches, [Snowflake(20)]);
      expect(manager.fetches, [Snowflake(20)]);
      expect(client.guilds.selected, [Snowflake(11)]);
    },
  );
  test(
    'SDK member missing returns null only for exact Unknown Member404',
    () async {
      final client = _Gateway();
      final manager = _Members();
      client.guilds.managers[Snowflake(10)] = manager;
      final service = DiscordBotMemberQueryService(
        client: client,
        guildId: Snowflake(10),
      );
      manager.failure = _Error(404, 10007);
      expect(
        await service.guildMember('20', budget: CommandExecutionBudget()),
        isNull,
      );
      for (final error in [
        _Error(404, 10004),
        _Error(403, 50001),
        StateError('transport'),
      ]) {
        manager.failure = error;
        await expectLater(
          service.guildMember('20', budget: CommandExecutionBudget()),
          throwsA(same(error)),
        );
        await expectLater(
          service.guildMembers(budget: CommandExecutionBudget()),
          throwsA(same(error)),
        );
      }
    },
  );
  test(
    'SDK enumeration rejects pages that fail to advance instead of looping or reporting partial counts',
    () async {
      final client = _Gateway();
      final manager = _Members(
        pages: {
          0: List.generate(1000, (i) => _Member(i + 1)),
          1000: [_Member(1000)],
        },
      );
      client.guilds.managers[Snowflake(10)] = manager;
      await expectLater(
        DiscordBotMemberQueryService(
          client: client,
          guildId: Snowflake(10),
        ).guildMembers(budget: CommandExecutionBudget()),
        throwsStateError,
      );
      expect(manager.requests.length, 2);
    },
  );
  test(
    'SDK allMembersCount enumerates bot guild pages and sums memberships per guild',
    () async {
      final client = _Gateway();
      client.users.pages[0] = List.generate(200, (i) => _UserGuild(i + 1));
      client.users.pages[200] = [_UserGuild(200), _UserGuild(201)];
      final service = DiscordBotMemberQueryService(client: client);
      expect(
        await service.allGuildMembersCount(budget: CommandExecutionBudget()),
        201,
      );
      expect(client.users.requests, [
        (limit: 200, after: null),
        (limit: 200, after: Snowflake(200)),
      ]);
      expect(client.guilds.selected.toSet().length, 201);
      expect(
        client.guilds.managers.values.every(
          (manager) => manager.requests.length == 1,
        ),
        true,
      );
    },
  );
  test('SDK allMembersCount rejects nonadvancing guild pages', () async {
    final client = _Gateway();
    client.users.pages[0] = List.generate(200, (i) => _UserGuild(i + 1));
    client.users.pages[200] = [_UserGuild(200)];
    await expectLater(
      DiscordBotMemberQueryService(
        client: client,
      ).allGuildMembersCount(budget: CommandExecutionBudget()),
      throwsStateError,
    );
    expect(client.guilds.selected, isEmpty);
  });
  test(
    'SDK validates guild and user IDs and current guild requirement before reads',
    () async {
      final client = _Gateway();
      final service = DiscordBotMemberQueryService(client: client);
      await expectLater(
        service.guildMembers(budget: CommandExecutionBudget()),
        throwsStateError,
      );
      await expectLater(
        service.guildMember('20', budget: CommandExecutionBudget()),
        throwsStateError,
      );
      for (final value in ['', '0', '-1', '0x14', '+20', '20.5']) {
        await expectLater(
          service.guildMembers(
            guildId: value,
            budget: CommandExecutionBudget(),
          ),
          throwsArgumentError,
        );
        await expectLater(
          service.guildMember(
            value,
            guildId: '10',
            budget: CommandExecutionBudget(),
          ),
          throwsArgumentError,
        );
      }
      expect(client.guilds.selected, isEmpty);
    },
  );
  test(
    'bindings share budget and SDK slow or expired page does not produce partial count',
    () async {
      final queries = _Queries();
      final budget = CommandExecutionBudget();
      await _engine(queries).execute(
        r'$findUser[BDFD Support]$isBooster[20]$membersCount$allMembersCount',
        context: _context(budget: budget),
      );
      expect(queries.budgets, everyElement(same(budget)));
      final client = _Gateway();
      final manager = _Members()..delay = const Duration(milliseconds: 50);
      client.guilds.managers[Snowflake(10)] = manager;
      final service = DiscordBotMemberQueryService(
        client: client,
        guildId: Snowflake(10),
      );
      await expectLater(
        service.guildMembers(
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(manager.requests, isEmpty);
      await expectLater(
        service.guildMembers(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(manager.requests.length, 1);
      await Future<void>.delayed(const Duration(milliseconds: 60));
    },
  );
}
