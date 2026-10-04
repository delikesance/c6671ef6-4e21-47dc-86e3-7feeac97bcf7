import 'dart:async';
import 'dart:convert';
import 'package:bot_creator_shared/engine/bdfd/emoji_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_emoji_service.dart';
import 'package:bot_creator_shared/services/bot_permission_query_service.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

const _png = [137, 80, 78, 71, 13, 10, 26, 10];
const _static = BotEmoji(
  id: '123',
  name: 'wave',
  guildId: '10',
  creatorId: '99',
);
const _animated = BotEmoji(
  id: '124',
  name: 'dance',
  guildId: '10',
  animated: true,
);

class _Service implements BotEmojiService {
  final writes = <String>[];
  final queries = <String>[];
  List<BotEmoji> rows = [_static, _animated];
  @override
  Future<BotEmoji?> emoji(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    queries.add(id);
    return rows.where((e) => e.id == id).firstOrNull;
  }

  @override
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  }) async {
    queries.add(name);
    return rows.where((e) => e.name == name).firstOrNull;
  }

  @override
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    queries.add(guildId ?? 'current');
    return rows;
  }

  @override
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    writes.add('create:${request.name}');
    return _static;
  }

  @override
  Future<void> deleteEmoji(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    writes.add('delete:$id');
  }
}

class _Http extends http.BaseClient {
  _Http(this.response);
  final FutureOr<http.StreamedResponse> Function(http.BaseRequest) response;
  int requests = 0;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests++;
    return response(request);
  }

  @override
  void close() {
    closed = true;
  }
}

class _Permissions implements BotPermissionQueryService {
  int mask = 0;
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async => BotMemberPermissions(mask);
  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => mask;
}

class _Gateway implements NyxxGateway {
  _Gateway(this.fixture);
  final EntityFixtureGateway fixture;
  @override
  GuildManager get guilds => fixture.guilds;
  @override
  User get user => _User();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  Snowflake get id => Snowflake(99);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Writes implements GuildEmojiManager {
  int creates = 0;
  int deletes = 0;
  EmojiBuilder? builder;
  bool fail = false;
  @override
  Snowflake get guildId => Snowflake(10);
  GuildEmoji get value => GuildEmoji(
    id: Snowflake(123),
    manager: this,
    name: 'new',
    roleIds: [],
    user: _User(),
    requiresColons: true,
    isManaged: false,
    isAnimated: false,
    isAvailable: true,
  );
  @override
  Future<GuildEmoji> fetch(Snowflake id) async => value;
  @override
  Future<GuildEmoji> create(
    EmojiBuilder builder, {
    String? auditLogReason,
  }) async {
    creates++;
    this.builder = builder;
    if (fail) throw StateError('write failed');
    return value;
  }

  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    deletes++;
    if (fail) throw StateError('write failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Partial implements PartialGuild {
  _Partial(this.emojis);
  @override
  final GuildEmojiManager emojis;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WriteGuilds implements GuildManager {
  _WriteGuilds(this.fixture, this.writes);
  final EntityFixtureGateway fixture;
  final _Writes writes;
  @override
  PartialGuild operator [](Snowflake id) => _Partial(writes);
  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) =>
      fixture.guilds.fetch(id, withCounts: withCounts);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _WriteGateway extends _Gateway {
  _WriteGateway(super.fixture);
  final writes = _Writes();
  @override
  GuildManager get guilds => _WriteGuilds(fixture, writes);
}

class _Images implements BotEmojiImageLoader {
  Duration delay = Duration.zero;
  int reads = 0;
  @override
  Future<BotEmojiImage> load(
    String url, {
    required CommandExecutionBudget budget,
  }) async {
    reads++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return BotEmojiImage(_png, 'png');
  }
}

Map<String, dynamic> _fixtures() => {
  'guilds': {
    '10': {
      'name': 'test',
      'owner_id': '99',
      'emojis': [
        {'id': '123', 'name': 'wave', 'creator_id': '99'},
        {'id': '124', 'name': 'dance', 'animated': true, 'creator_id': '20'},
      ],
    },
  },
  'users': {
    '99': {'username': 'bot'},
  },
};
Future<Map<String, dynamic>> _sandbox(
  String script, {
  List<Map<String, dynamic>> httpFixtures = const [],
}) => testCommandInSandbox({
  'script': script,
  'bdfdBackend': 'native-v1',
  'variables': {'guild.id': '10', 'bot.id': '99'},
  'entities': _fixtures(),
  'http': httpFixtures,
});
void main() {
  Future<String> run(_Service service, String code) =>
      BdfdRuntime(functions: bdfdEmojiFunctions(service)).execute(code);
  test(
    'official names return static/animated mentions, names, booleans and count',
    () async {
      final s = _Service();
      expect(
        await run(
          s,
          r'$customEmoji[wave]|$emojiName[0124]|$isEmojiAnimated[124]|$emojiExists[123]|$emoteCount',
        ),
        '<:wave:123>|dance|true|true|2',
      );
      expect(
        await run(s, r'$serverEmojis[10; / ]'),
        '<:wave:123> / <a:dance:124>',
      );
      expect(await run(s, r'$serverEmojis[10;]'), '<:wave:123><a:dance:124>');
    },
  );
  test('invalid exists examples return false without query', () async {
    final s = _Service();
    for (final id in ['doge', 'idhoshkxbidho', '0x7b', '+123', '0', '-1']) {
      expect(await run(s, '\$emojiExists[$id]'), 'false');
    }
    expect(s.queries, isEmpty);
  });
  test(
    'name is exact and ID is not an undocumented customEmoji alias',
    () async {
      final s = _Service();
      expect(await run(s, r'$customEmoji[Wave]|$customEmoji[123]'), '|');
    },
  );
  test('add return flag controls output, remove canonical numeric ID', () async {
    final s = _Service();
    expect(
      await run(
        s,
        r'$addEmoji[wave;https://image.test/a;yes]$addEmoji[wave;https://image.test/a;no]$removeEmoji[00123]',
      ),
      '<:wave:123>',
    );
    expect(s.writes, ['create:wave', 'create:wave', 'delete:123']);
  });
  test('invalid arity and arguments precede effects', () async {
    for (final code in [
      r'$addEmoji[x;https://x.test/a]',
      r'$addEmoji[x;https://x.test/a;maybe]',
      r'$addEmoji[x;file:///x;yes]',
      r'$removeEmoji[wave]',
      r'$serverEmojis[10]',
      r'$emoteCount[10]',
    ]) {
      final s = _Service();
      await expectLater(run(s, code), throwsA(isA<BdfdNativeError>()));
      expect(s.writes, isEmpty);
    }
  });
  test('missing required emoji throws a catchable native error', () async {
    await expectLater(
      run(_Service(), r'$emojiName[999]'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'returned names are literal and unknown function arguments stay opaque',
    () async {
      final s = _Service()
        ..rows = [
          const BotEmoji(id: '123', name: r'$removeEmoji[123]', guildId: '10'),
        ];
      expect(await run(s, r'$emojiName[123]'), r'$removeEmoji[123]');
      expect(
        await run(s, r'$notAnEmojiFunction[$removeEmoji[123]]'),
        r'$notAnEmojiFunction[$removeEmoji[123]]',
      );
      expect(s.writes, isEmpty);
    },
  );
  test('expired budget stops before service mutation', () async {
    final s = _Service();
    await expectLater(
      BdfdRuntime(functions: bdfdEmojiFunctions(s)).execute(
        r'$removeEmoji[123]',
        context: BdfdContext(
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(s.writes, isEmpty);
  });
  test(
    'HTTP detects bytes, streams bounded data and preserves caller ownership',
    () async {
      final client = _Http(
        (r) => http.StreamedResponse(
          Stream.fromIterable([_png.take(3).toList(), _png.skip(3).toList()]),
          200,
        ),
      );
      final image = await HttpBotEmojiImageLoader(
        client: client,
      ).load('https://image.test/a', budget: CommandExecutionBudget());
      expect(image.format, 'png');
      expect(image.bytes, _png);
      expect(client.requests, 1);
      expect(client.closed, false);
      expect(() => image.bytes[0] = 0, throwsUnsupportedError);
    },
  );
  test('HTTP factory transport closes on success and errors', () async {
    for (final status in [200, 503]) {
      final client = _Http(
        (r) => http.StreamedResponse(Stream.value(_png), status),
      );
      final future = HttpBotEmojiImageLoader(
        clientFactory: () => client,
      ).load('https://image.test/a', budget: CommandExecutionBudget());
      if (status == 200) {
        await future;
      } else {
        await expectLater(future, throwsStateError);
      }
      expect(client.closed, true);
      expect(client.requests, 1);
    }
  });
  test('HTTP header and streamed overflow reject 256 KiB limit', () async {
    for (final header in [true, false]) {
      final client = _Http(
        (r) => http.StreamedResponse(
          Stream.value(List.filled(HttpBotEmojiImageLoader.maxBytes + 1, 0)),
          200,
          contentLength: header ? HttpBotEmojiImageLoader.maxBytes + 1 : null,
        ),
      );
      await expectLater(
        HttpBotEmojiImageLoader(
          client: client,
        ).load('https://image.test/a', budget: CommandExecutionBudget()),
        throwsArgumentError,
      );
      expect(client.requests, 1);
    }
  });
  test('HTTP invalid URL avoids transport; HTML is rejected', () async {
    final client = _Http(
      (r) => http.StreamedResponse(Stream.value('<html>'.codeUnits), 200),
    );
    await expectLater(
      HttpBotEmojiImageLoader(
        client: client,
      ).load('file:///a', budget: CommandExecutionBudget()),
      throwsArgumentError,
    );
    expect(client.requests, 0);
    await expectLater(
      HttpBotEmojiImageLoader(
        client: client,
      ).load('https://image.test/a', budget: CommandExecutionBudget()),
      throwsArgumentError,
    );
  });
  test('HTTP deadline bounds hanging image stream', () async {
    final client = _Http(
      (r) => http.StreamedResponse(
        Stream.fromFuture(
          Future.delayed(const Duration(milliseconds: 40), () => _png),
        ),
        200,
      ),
    );
    await expectLater(
      HttpBotEmojiImageLoader(client: client).load(
        'https://image.test/a',
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 5)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(client.requests, 1);
  });
  test(
    'SDK reads fresh lists and preserves creator ID, immutable snapshots',
    () async {
      final fixtures = _fixtures();
      final gateway = EntityFixtureGateway(fixtures);
      final service = DiscordBotEmojiService(
        client: gateway,
        guildId: Snowflake(10),
      );
      final rows = await service.emojis(budget: CommandExecutionBudget());
      expect(rows.first.creatorId, '99');
      expect(rows.last.mention, '<a:dance:124>');
      expect(() => rows.clear(), throwsUnsupportedError);
      ((fixtures['guilds'] as Map)['10']['emojis'] as List).removeLast();
      expect(
        (await service.emojis(budget: CommandExecutionBudget())).length,
        1,
      );
      expect(
        gateway.requests.where((r) => r['operation'] == 'guild.emojis').length,
        2,
      );
    },
  );
  test(
    'read-only preparation distinguishes create vs manage and own deletion',
    () async {
      final fixture = EntityFixtureGateway(_fixtures());
      final gateway = _Gateway(fixture);
      final p = _Permissions();
      const request = BotEmojiCreateRequest(
        name: 'new',
        imageUrl: 'https://image.test/a',
      );
      p.mask = Permissions.manageGuildExpressions.value;
      await expectLater(
        prepareBotEmojiCreate(
          gateway,
          Snowflake(10),
          request,
          budget: CommandExecutionBudget(),
          permissions: p,
        ),
        throwsStateError,
      );
      p.mask = Permissions.createGuildExpressions.value;
      await prepareBotEmojiCreate(
        gateway,
        Snowflake(10),
        request,
        budget: CommandExecutionBudget(),
        permissions: p,
      );
      await prepareBotEmojiDelete(
        gateway,
        Snowflake(10),
        '123',
        budget: CommandExecutionBudget(),
        permissions: p,
      );
      await expectLater(
        prepareBotEmojiDelete(
          gateway,
          Snowflake(10),
          '124',
          budget: CommandExecutionBudget(),
          permissions: p,
        ),
        throwsStateError,
      );
      p.mask = Permissions.manageGuildExpressions.value;
      await prepareBotEmojiDelete(
        gateway,
        Snowflake(10),
        '124',
        budget: CommandExecutionBudget(),
        permissions: p,
      );
    },
  );
  test(
    'SDK create sends image builder and empty roles; delete uses requested ID',
    () async {
      final gateway = _WriteGateway(EntityFixtureGateway(_fixtures()));
      final images = _Images();
      final service = DiscordBotEmojiService(
        client: gateway,
        guildId: Snowflake(10),
        images: images,
      );
      final value = await service.createEmoji(
        const BotEmojiCreateRequest(
          name: ' new ',
          imageUrl: 'https://image.test/a',
        ),
        budget: CommandExecutionBudget(),
      );
      expect(value.mention, '<:new:123>');
      expect(images.reads, 1);
      expect(gateway.writes.builder!.name, 'new');
      expect(gateway.writes.builder!.roles, isEmpty);
      expect(
        gateway.writes.builder!.build()['image'],
        startsWith('data:image/png;base64,'),
      );
      await service.deleteEmoji('123', budget: CommandExecutionBudget());
      expect(gateway.writes.creates, 1);
      expect(gateway.writes.deletes, 1);
    },
  );
  test('SDK mutation failure is not retried or rolled back', () async {
    final gateway = _WriteGateway(EntityFixtureGateway(_fixtures()))
      ..writes.fail = true;
    final service = DiscordBotEmojiService(
      client: gateway,
      guildId: Snowflake(10),
      images: _Images(),
    );
    await expectLater(
      service.createEmoji(
        const BotEmojiCreateRequest(
          name: 'new',
          imageUrl: 'https://image.test/a',
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsStateError,
    );
    await expectLater(
      service.deleteEmoji('123', budget: CommandExecutionBudget()),
      throwsStateError,
    );
    expect(gateway.writes.creates, 1);
    expect(gateway.writes.deletes, 1);
  });
  test('expired image download budget blocks SDK upload', () async {
    final gateway = _WriteGateway(EntityFixtureGateway(_fixtures()));
    final images = _Images()..delay = const Duration(milliseconds: 40);
    await expectLater(
      DiscordBotEmojiService(
        client: gateway,
        guildId: Snowflake(10),
        images: images,
      ).createEmoji(
        const BotEmojiCreateRequest(
          name: 'new',
          imageUrl: 'https://image.test/a',
        ),
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(gateway.writes.creates, 0);
  });
  test('Sandbox mutations and queries share updated emoji fixtures', () async {
    final result = await _sandbox(
      r'$addEmoji[new;https://image.test/a;yes]|$emoteCount|$emojiName[300000]|$removeEmoji[300000]$emoteCount',
      httpFixtures: [
        {'url': 'https://image.test/a', 'bodyBase64': base64Encode(_png)},
      ],
    );
    expect(result['success'], true, reason: '$result');
    expect(
      result['responses'][0]['payload']['content'],
      '<:new:300000>|3|new|2',
    );
    final effects = (result['effects'] as List).whereType<Map>();
    expect(effects.where((e) => e['type'] == 'createEmoji').length, 1);
    expect(effects.where((e) => e['type'] == 'deleteEmoji').length, 1);
  });
  test(
    'Sandbox image failure produces no emoji write and no implicit retry',
    () async {
      final result = await _sandbox(
        r'$addEmoji[new;https://image.test/a;yes]',
        httpFixtures: [
          {'url': 'https://image.test/a', 'status': 503},
        ],
      );
      expect(result['success'], false);
      final effects = (result['effects'] as List).whereType<Map>();
      expect(effects.where((e) => e['type'] == 'httpRequest').length, 1);
      expect(effects.where((e) => e['type'] == 'createEmoji'), isEmpty);
    },
  );
}
