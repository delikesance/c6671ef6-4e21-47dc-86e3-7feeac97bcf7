import 'dart:async';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/user_query_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_user_query_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Queries implements BotUserQueryService {
  final users = <String, BotUser>{
    '20': const BotUser(
      id: '20',
      username: 'rainbow_key',
      globalName: 'RainbowKey',
      avatarUrl: 'https://cdn.discordapp.com/avatars/20/profile.png',
      bannerUrl: 'https://cdn.discordapp.com/banners/20/banner.gif',
      bannerColor: 0x32d167,
    ),
    '21': const BotUser(
      id: '21',
      username: 'BDFD Support',
      avatarUrl: 'default-avatar',
      discriminator: '7678',
      isBot: true,
    ),
    '22': const BotUser(
      id: '22',
      username: 'ordinary',
      avatarUrl: 'default-avatar',
      discriminator: '9',
    ),
  };
  final members = <String, BotUserMember>{
    '20': BotUserMember(
      id: '20',
      nickname: 'server-name',
      joinedAt: DateTime.utc(2022, 8, 16, 8, 39),
      avatarUrl: 'guild-avatar',
    ),
    '21': BotUserMember(id: '21', joinedAt: DateTime.utc(2020, 1)),
    '22': const BotUserMember(id: '22'),
  };
  final requests = <String>[];
  final budgets = <CommandExecutionBudget>[];
  @override
  Future<BotUser?> user(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    requests.add('user:$id');
    budgets.add(budget);
    return users[id];
  }

  @override
  Future<BotUserMember?> member(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    requests.add('member:$id');
    budgets.add(budget);
    return members[id];
  }
}

BdfdEngine _engine(BotUserQueryService service) => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  functions: bdfdUserQueryFunctions(service),
);
BdfdContext _context({
  Map<String, String>? variables,
  CommandExecutionBudget? budget,
}) =>
    BdfdContext(variables: {'author.id': '20', ...?variables}, budget: budget);

class _Asset implements CdnAsset {
  _Asset(String url) : url = Uri.parse(url);
  @override
  final Uri url;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  Snowflake get id => Snowflake(20);
  @override
  String get username => 'fresh';
  @override
  String? get globalName => 'Fresh Display';
  @override
  String get discriminator => '1234';
  @override
  bool get isBot => true;
  @override
  CdnAsset get avatar => _Asset('https://cdn.example/avatar.gif');
  @override
  CdnAsset? get banner => _Asset('https://cdn.example/banner.png');
  @override
  DiscordColor? get accentColor => DiscordColor(0x32d167);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Member implements Member {
  _Member({DateTime? joinedAt})
    : joinedAt = joinedAt ?? DateTime.utc(2022, 8, 16);
  @override
  Snowflake get id => Snowflake(20);
  @override
  String? get nick => 'Fresh Nick';
  @override
  final DateTime joinedAt;
  @override
  CdnAsset? get avatar => _Asset('https://cdn.example/guild-avatar.png');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ApiError implements HttpResponseError {
  _ApiError(this.statusCode, this.errorCode);
  @override
  String toString({bool short = false}) => 'API error $statusCode/$errorCode';
  @override
  final int statusCode;
  @override
  final int errorCode;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserManager {
  User result = _User();
  Object? failure;
  Completer<void>? gate;
  final requests = <Snowflake>[];
  @override
  Future<User> fetch(Snowflake id) async {
    requests.add(id);
    if (gate != null) await gate!.future;
    if (failure != null) throw failure!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected user SDK call ${invocation.memberName}');
}

class _Members implements MemberManager {
  Member result = _Member();
  Object? failure;
  final requests = <Snowflake>[];
  @override
  Future<Member> fetch(Snowflake id) async {
    requests.add(id);
    if (failure != null) throw failure!;
    return result;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected member SDK call ${invocation.memberName}');
}

class _Guild implements PartialGuild {
  _Guild(this.members);
  @override
  final MemberManager members;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Guilds implements GuildManager {
  _Guilds(this.members);
  final _Members members;
  final selected = <Snowflake>[];
  @override
  PartialGuild operator [](Snowflake id) {
    selected.add(id);
    return _Guild(members);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway() {
    guilds = _Guilds(members);
  }
  @override
  final _Users users = _Users();
  final _Members members = _Members();
  @override
  late final _Guilds guilds;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected SDK call ${invocation.memberName}');
}

void main() {
  test(
    'global fields use required IDs and preserve URLs and code-shaped data',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      for (final entry in {
        r'$userExists[20]': 'true',
        r'$userExists[99]': 'false',
        r'$userAvatar[20]': service.users['20']!.avatarUrl,
        r'$userBanner[20]': service.users['20']!.bannerUrl!,
        r'$userBanner[21]': '',
        r'$userBannerColor[20]': '32D167',
        r'$userBannerColor[21]': '',
        r'$displayName[20]': 'RainbowKey',
        r'$displayName[21]': 'BDFD Support',
        r'$username[20]': 'rainbow_key',
      }.entries) {
        expect(await engine.execute(entry.key), entry.value);
      }
      service.users['23'] = const BotUser(
        id: '23',
        username: r'$var[bad;1]',
        avatarUrl: 'url',
      );
      final context = _context();
      expect(
        await engine.execute(r'$displayName[23]', context: context),
        r'$var[bad;1]',
      );
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test(
    'bare avatar displayName username nickname select current author',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(
        await engine.execute(r'$authorAvatar', context: _context()),
        service.users['20']!.avatarUrl,
      );
      expect(
        await engine.execute(r'$displayName', context: _context()),
        'RainbowKey',
      );
      expect(
        await engine.execute(r'$username', context: _context()),
        'rainbow_key',
      );
      expect(
        await engine.execute(r'$nickname', context: _context()),
        'server-name',
      );
      expect(
        await engine.execute(
          r'$authorAvatar',
          context: BdfdContext(variables: {'user.id': '21'}),
        ),
        'default-avatar',
      );
    },
  );
  test(
    'bare username preserves hydrated context and avoids entity reads',
    () async {
      final service = _Queries();
      expect(
        await _engine(service).execute(
          r'$username',
          context: BdfdContext(variables: {'author.username': 'hydrated'}),
        ),
        'hydrated',
      );
      expect(
        await _engine(service).execute(
          r'$username',
          context: BdfdContext(variables: {'user.username': 'user-hydrated'}),
        ),
        'user-hydrated',
      );
      expect(service.requests, isEmpty);
      expect(
        await _engine(service).execute(
          r'$username[20]',
          context: _context(variables: {'author.username': 'stale'}),
        ),
        'rainbow_key',
      );
      expect(service.requests, ['user:20']);
    },
  );
  test(
    'nickname prefers guild nick and falls back to global display then username',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(await engine.execute(r'$nickname[20]'), 'server-name');
      expect(service.requests, ['member:20']);
      service.members['20'] = const BotUserMember(id: '20');
      expect(await engine.execute(r'$nickname[20]'), 'RainbowKey');
      expect(await engine.execute(r'$nickname[21]'), 'BDFD Support');
    },
  );
  test(
    'userServerAvatar prefers member asset and falls back to global avatar',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(await engine.execute(r'$userServerAvatar[20]'), 'guild-avatar');
      expect(service.requests, ['member:20']);
      expect(await engine.execute(r'$userServerAvatar[21]'), 'default-avatar');
      expect(service.requests, ['member:20', 'member:21', 'user:21']);
    },
  );
  test(
    'discriminator implements documented [] author and user 0000 behavior',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(
        await engine.execute(r'$discriminator[]', context: _context()),
        '0000',
      );
      expect(await engine.execute(r'$discriminator[21]'), '7678');
      expect(await engine.execute(r'$discriminator[22]'), '0000');
      service.users['21'] = const BotUser(
        id: '21',
        username: 'bot',
        avatarUrl: '',
        discriminator: '9',
        isBot: true,
      );
      expect(await engine.execute(r'$discriminator[21]'), '0009');
    },
  );
  test(
    'userJoined matches official default and custom Go date examples',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(await engine.execute(r'$userJoined[20]'), '2022-08-16');
      expect(
        await engine.execute(
          r'$userJoined[20;January 2, 2006 at 3:04 PM (MST -07:00)]',
        ),
        'August 16, 2022 at 8:39 AM (UTC +00:00)',
      );
      expect(await engine.execute(r'$userJoined[20;]'), '');
      expect(service.requests, ['member:20', 'member:20', 'member:20']);
    },
  );
  test('userJoined shares timezone without reading clock', () async {
    final service = _Queries();
    var clocks = 0;
    final context = BdfdContext(
      clock: () {
        clocks++;
        return DateTime.utc(2030);
      },
    );
    expect(
      await _engine(service).execute(
        r'$time[Europe/Paris]$userJoined[20;15:04 MST -07:00]',
        context: context,
      ),
      '10:39 CEST +02:00',
    );
    expect(clocks, 0);
  });
  test(
    'missing user/member/joined date are errors except userExists false',
    () async {
      final engine = _engine(_Queries());
      for (final source in [
        r'$userAvatar[99]',
        r'$username[99]',
        r'$nickname[99]',
        r'$userServerAvatar[99]',
        r'$userJoined[99]',
        r'$userJoined[22]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'required empty IDs and malformed IDs do not perform I/O or select author',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      for (final name in [
        'userExists',
        'userJoined',
        'userAvatar',
        'username',
        'displayName',
        'nickname',
        'userBanner',
        'userBannerColor',
        'userServerAvatar',
      ]) {
        for (final invalid in [
          '',
          '0',
          '-1',
          '+20',
          '0x14',
          '20.5',
          '<@20>',
          '9223372036854775808',
        ]) {
          await expectLater(
            engine.execute('\$$name[$invalid]', context: _context()),
            throwsA(isA<BdfdNativeError>()),
            reason: '$name:$invalid',
          );
        }
      }
      expect(service.requests, isEmpty);
    },
  );
  test(
    'invalid arity preflight errors before prior variable effects or requests',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      for (final source in [
        r'$userExists',
        r'$userAvatar',
        r'$userJoined',
        r'$discriminator',
        r'$userBanner',
        r'$userServerAvatar',
        r'$authorAvatar[20]',
        r'$displayName[20;21]',
        r'$nickname[20;21]',
        r'$username[20;21]',
        r'$userJoined[20;2006;extra]',
      ]) {
        final context = _context();
        await expectLater(
          engine.execute(r'$var[bad;1]' + source, context: context),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(context.temporaryVariables['bad'], isNull);
      }
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unknown function preserves argument code without user reads or effects',
    () async {
      final service = _Queries();
      final context = _context();
      const source = r'$unknown[$userExists[$var[bad;1]]]';
      expect(await _engine(service).execute(source, context: context), source);
      expect(service.requests, isEmpty);
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test('bindings propagate the same invocation budget', () async {
    final service = _Queries();
    final budget = CommandExecutionBudget();
    await _engine(service).execute(
      r'$nickname[21]$userAvatar[20]',
      context: _context(budget: budget),
    );
    expect(service.budgets, everyElement(same(budget)));
  });
  test(
    'SDK adapter fetches fresh user and member and maps DTO fields',
    () async {
      final client = _Gateway();
      final budget = CommandExecutionBudget();
      final service = DiscordBotUserQueryService(
        client: client,
        guildId: Snowflake(10),
      );
      final user = (await service.user('20', budget: budget))!;
      expect(user.id, '20');
      expect(user.username, 'fresh');
      expect(user.displayName, 'Fresh Display');
      expect(user.discriminator, '1234');
      expect(user.isBot, true);
      expect(user.avatarUrl, 'https://cdn.example/avatar.gif');
      expect(user.bannerUrl, 'https://cdn.example/banner.png');
      expect(user.bannerColor, 0x32d167);
      final member = (await service.member('20', budget: budget))!;
      expect(member.id, '20');
      expect(member.nickname, 'Fresh Nick');
      expect(member.joinedAt, DateTime.utc(2022, 8, 16));
      expect(member.avatarUrl, 'https://cdn.example/guild-avatar.png');
      expect(client.users.requests, [Snowflake(20)]);
      expect(client.members.requests, [Snowflake(20)]);
      expect(client.guilds.selected, [Snowflake(10)]);
    },
  );
  test('SDK converts only exact not-found API responses to null', () async {
    final client = _Gateway();
    final service = DiscordBotUserQueryService(
      client: client,
      guildId: Snowflake(10),
    );
    client.users.failure = _ApiError(404, 10013);
    client.members.failure = _ApiError(404, 10007);
    expect(await service.user('20', budget: CommandExecutionBudget()), isNull);
    expect(
      await service.member('20', budget: CommandExecutionBudget()),
      isNull,
    );
    for (final error in [
      _ApiError(403, 50001),
      _ApiError(404, 10004),
      _ApiError(500, 0),
      StateError('transport'),
    ]) {
      client.users.failure = error;
      client.members.failure = error;
      await expectLater(
        service.user('20', budget: CommandExecutionBudget()),
        throwsA(same(error)),
      );
      await expectLater(
        service.member('20', budget: CommandExecutionBudget()),
        throwsA(same(error)),
      );
    }
  });
  test(
    'SDK rejects invalid user IDs and absent current guild before fetch',
    () async {
      final client = _Gateway();
      final service = DiscordBotUserQueryService(client: client);
      await expectLater(
        service.member('20', budget: CommandExecutionBudget()),
        throwsStateError,
      );
      for (final id in ['', '0', '+20', '0x14', '-1', 'x']) {
        await expectLater(
          service.user(id, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
        await expectLater(
          service.member(id, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
      }
      expect(client.users.requests, isEmpty);
      expect(client.members.requests, isEmpty);
    },
  );
  test('SDK treats nyxx guest joinedAt sentinel as unavailable', () async {
    final client = _Gateway();
    client.members.result = _Member(
      joinedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
    final service = DiscordBotUserQueryService(
      client: client,
      guildId: Snowflake(10),
    );
    expect(
      (await service.member('20', budget: CommandExecutionBudget()))!.joinedAt,
      isNull,
    );
  });
  test(
    'expired SDK budget blocks reads and slow reads honor deadline',
    () async {
      final client = _Gateway();
      final service = DiscordBotUserQueryService(client: client);
      await expectLater(
        service.user(
          '20',
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(client.users.requests, isEmpty);
      client.users.gate = Completer<void>();
      await expectLater(
        service.user(
          '20',
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      client.users.gate!.complete();
      await Future<void>.delayed(Duration.zero);
      expect(client.users.requests, [Snowflake(20)]);
    },
  );
}
