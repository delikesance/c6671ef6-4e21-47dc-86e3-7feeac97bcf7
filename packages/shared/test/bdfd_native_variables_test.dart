import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/variable_functions.dart';
import 'package:bot_creator_shared/services/variable_service.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('$invocation');
}

void main() {
  BdfdRuntime native(MemoryBotDataStore store, {bool legacy = false}) =>
      BdfdRuntime(
        functions: bdfdVariableFunctions(
          VariableService(store, 'bot'),
          legacyUserVariables: legacy,
        ),
      );
  BdfdContext context({String guild = '10', String user = '20'}) => BdfdContext(
    variables: {
      'guild.id': guild,
      'author.id': user,
      'channel.id': '30',
      'message.id': '40',
    },
  );

  test('current user variables are isolated by server and member', () async {
    final store = MemoryBotDataStore(
      scopedDefinitions: [
        {'scope': 'guildMember', 'key': 'xp', 'defaultValue': 0},
      ],
    );
    final runtime = native(store);
    await runtime.execute(r'$setUserVar[xp;5]', context: context());
    await runtime.execute(r'$setUserVar[xp;9;21]', context: context());
    expect(await runtime.execute(r'$getUserVar[xp]', context: context()), '5');
    expect(
      await runtime.execute(r'$getUserVar[xp;21]', context: context()),
      '9',
    );
    expect(
      await runtime.execute(r'$getUserVar[xp]', context: context(guild: '11')),
      '0',
    );
    expect(store.scopedVariables['guildMember']!['10:20']!['xp'], '5');
    expect(store.scopedVariables['guildMember']!['10:21']!['xp'], '9');
  });

  test(
    'legacy user variables stay global unless a guild is explicit',
    () async {
      final store = MemoryBotDataStore();
      final runtime = native(store, legacy: true);
      await runtime.execute(
        r'$setUserVar[xp;5]$setUserVar[xp;9;20;10]',
        context: context(),
      );
      expect(
        await runtime.execute(r'$getUserVar[xp]', context: context()),
        '5',
      );
      expect(
        await runtime.execute(r'$getUserVar[xp;20;10]', context: context()),
        '9',
      );
      expect(store.scopedVariables['user']!['20']!['xp'], '5');
    },
  );

  test(
    'global, user, guild, channel and message bindings use their canonical IDs',
    () async {
      final store = MemoryBotDataStore();
      final result = await native(store).execute(
        r'$setVar[a;global]$setVar[a;user;20]$setServerVar[a;guild]'
        r'$setChannelVar[a;channel]$setMessageVar[a;message]'
        r'$getVar[a]/$getVar[a;20]/$getServerVar[a]/$getChannelVar[a]/$getMessageVar[a]',
        context: context(),
      );
      expect(result, 'global/user/guild/channel/message');
    },
  );

  test(
    'reads normalize keys, migrate legacy keys and persist declared defaults',
    () async {
      final store = MemoryBotDataStore(
        scopedVariables: {
          'guild': {
            '10': {'bc_old': 7},
          },
        },
        scopedDefinitions: [
          {'scope': 'guild', 'key': 'bc_xp', 'defaultValue': 0},
        ],
      );
      expect(
        await native(store).execute(
          r'$getServerVar[old]:$getServerVar[bc_xp]',
          context: context(),
        ),
        '7:0',
      );
      expect(store.scopedVariables['guild']!['10']!['old'], 7);
      expect(store.scopedVariables['guild']!['10']!['xp'], 0);
    },
  );

  test('missing server context fails before writing member data', () async {
    final store = MemoryBotDataStore();
    await expectLater(
      native(store).execute(r'$setUserVar[xp;9]', context: context(guild: '')),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(store.scopedVariables, isEmpty);
  });

  test(
    'native and existing handler persist the same scoped values and definitions',
    () async {
      const source =
          r'$setServerVar[count;0]$for[3]'
          r'$var[n;$getServerVar[count]]$setServerVar[count;$sum[$var[n];1]]'
          r'$endfor$setUserVar[score;$getServerVar[count];21]';
      final oldStore = MemoryBotDataStore();
      final nativeStore = MemoryBotDataStore();
      final variables = context().variables;
      final compiled = BdfdCompiler().compile(source);
      expect(compiled.hasErrors, isFalse);
      final result = await handleActions(
        _NoDiscord(),
        null,
        actions: compiled.actions,
        store: oldStore,
        botId: 'bot',
        variables: variables,
        fallbackGuildId: Snowflake(10),
        resolveTemplate: (text) => resolveTemplatePlaceholders(text, variables),
      );
      expect(result['error'], isNull, reason: '$result');
      await native(nativeStore).execute(source, context: context());
      expect(nativeStore.scopedVariables, oldStore.scopedVariables);
      expect(nativeStore.scopedDefinitions, oldStore.scopedDefinitions);
    },
  );
}
