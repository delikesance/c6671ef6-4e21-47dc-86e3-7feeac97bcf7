import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_permission_query_service.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';
import 'helpers/variables_test_helpers.dart';

class _Permissions implements BotPermissionQueryService {
  _Permissions(this.mask);
  final int mask;
  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => mask;
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async => BotMemberPermissions(mask);
}

void main() {
  test('guard helpers compile without diagnostics', () {
    final result = BdfdCompiler().compile(
      r'$onlyIf[((score))>=5;Need at least five points]'
      r'$onlyForUsers[Nicky;Jeremy;Not authorized]'
      r'$onlyForChannels[333;Wrong channel]'
      r"$ignoreChannels[444;555;That command can't be used in this channel!]"
      r'$onlyNSFW[NSFW channel only]'
      r'$onlyPerms[manageMessages;kickMembers;Missing perms]'
      r'$onlyBotPerms[manageRoles;Bot missing perms]'
      r'$onlyAdmin[Admins only]'
      r'$checkUserPerms[1234567890;banMembers;Denied]'
      r'$onlyForRoles[Moderator;Role required]'
      r'$onlyForIDs[111;Denied ID]'
      r'$onlyForRoleIDs[222;Denied role id]'
      r'$onlyForServers[333;Wrong server]'
      r'$onlyForCategories[444;Wrong category]'
      r'$onlyBotChannelPerms[$channelID;manageMessages;Bot missing perms]'
      r'$onlyIfMessageContains[$message;Hello;Hi;Missing text]',
    );
    expect(result.hasErrors, isFalse);
    expect(result.diagnostics, isEmpty);
  });

  group('conditional guards answer with their error message', () {
    Future<String?> run(
      String script, {
      Map<String, dynamic>? variables,
    }) async => contentOf(await runScript(script, variables: variables));

    test('onlyIf compares numbers', () async {
      expect(
        await run(
          r'$var[score;3]$onlyIf[$var[score]>=5;Need at least five points]ok',
        ),
        'Need at least five points',
      );
      expect(
        await run(
          r'$var[score;5]$onlyIf[$var[score]>=5;Need at least five points]ok',
        ),
        'ok',
      );
    });

    test('onlyForUsers accepts the author name or id', () async {
      expect(
        await run(r'$onlyForUsers[Nicky;Jeremy;Not authorized]ok'),
        'Not authorized',
      );
      expect(
        await run(r'$onlyForUsers[Nicky;Test user;Not authorized]ok'),
        'ok',
      );
      expect(await run(r'$onlyForIDs[111;Denied ID]ok'), 'Denied ID');
      expect(await run(r'$onlyForIDs[111;20;Denied ID]ok'), 'ok');
    });

    test('channel and server guards', () async {
      expect(
        await run(r'$onlyForChannels[333;Wrong channel]ok'),
        'Wrong channel',
      );
      expect(await run(r'$onlyForChannels[333;30;Wrong channel]ok'), 'ok');
      expect(
        await run(r"$ignoreChannels[30;555;Not in this channel!]ok"),
        'Not in this channel!',
      );
      expect(await run(r'$ignoreChannels[444;555;Not here]ok'), 'ok');
      expect(await run(r'$onlyForServers[333;Wrong server]ok'), 'Wrong server');
      expect(await run(r'$onlyForServers[10;Wrong server]ok'), 'ok');
    });

    test('onlyIfMessageContains requires every word', () async {
      const script =
          r'$onlyIfMessageContains[$message;Hello;Hi;Missing text]ok';
      expect(
        await run(script, variables: {'message.content': 'Hello Hi'}),
        'ok',
      );
      expect(
        await run(script, variables: {'message.content': 'Hello'}),
        'Missing text',
      );
    });
  });

  test('for loops repeat their body', () async {
    final result = await runScript(
      r'$for[2]$channelSendMessage[30;Loop]$endfor',
    );
    expectOk(result);
    expect(payloads(result).map((p) => p['content']), ['Loop', 'Loop']);
  });

  test('checkUserPerms accepts BDFD wiki permission names', () async {
    // Administrator (8) | BanMembers (4) | UseApplicationCommands (1 << 31)
    final full = _Permissions(8 | 4 | (1 << 31));
    final engine = BdfdEngine(
      store: MemoryBotDataStore(),
      botId: 'bot',
      permissionQueries: full,
    );
    expect(
      await engine.execute(r'$checkUserPerms[20;admin;ban;slashcommands]'),
      'true',
    );
    expect(
      await engine.execute(r'$checkUserPerms[20;administrator;banmembers]'),
      'true',
    );
    final none = BdfdEngine(
      store: MemoryBotDataStore(),
      botId: 'bot',
      permissionQueries: _Permissions(1 << 10),
    );
    expect(await none.execute(r'$checkUserPerms[20;admin;ban]'), 'false');
  });
}
