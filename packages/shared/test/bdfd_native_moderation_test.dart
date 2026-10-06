import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Moderation implements BotModerationService {
  final requests = <BotModerationRequest>[];
  final budgets = <CommandExecutionBudget>[];
  bool failNext = false;
  @override
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    budgets.add(budget);
    requests.add(request);
    if (failNext) {
      failNext = false;
      throw StateError('Permission denied');
    }
    return request.userId;
  }
}

class _Store extends MemoryBotDataStore {
  _Store([this.source = r'$kick[$var[target];workflow]']);
  final String source;
  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => {
    'name': name,
    'executionMode': 'bdfd_script',
    'bdfdBackend': 'native-v1',
    'bdfdScriptContent': source,
  };
}

BdfdEngine _engine(_Moderation service) =>
    BdfdEngine(store: _Store(), botId: 'bot', moderation: service);

void main() {
  test(
    'setUserRoles uses explicit target and evaluated IDs without action conversion',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        variables: {'author.id': '999', 'message.mentions': '333'},
      );
      expect(
        await _engine(service).execute(
          r'$var[target;222]$setUserRoles[$var[target];64;65;64]done',
          context: context,
        ),
        'done',
      );
      final request = service.requests.single;
      expect(request.operation, BotModerationOperation.setUserRoles);
      expect(request.userId, '222');
      expect(request.roleReplacement!.roleIds, ['64', '65']);
      expect(request.useDefaultReason, false);
      expect(service.budgets.single, same(context.budget));
    },
  );
  test(
    'setUserRoles requires at least one role and rejects all invalid arguments before effect',
    () async {
      final service = _Moderation();
      final engine = _engine(service);
      for (final source in [
        r'$setUserRoles[222]',
        r'$setUserRoles[222;]',
        r'$setUserRoles[;64]',
        r'$setUserRoles[222;64;bad]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.requests, isEmpty);
      }
      const source = r'$unknown[$setUserRoles[222;64]]';
      expect(await engine.execute(source), source);
      expect(service.requests, isEmpty);
    },
  );

  test(
    'native role definitions evaluate once and return no role ID text',
    () async {
      final service = _Moderation();
      final context = BdfdContext(variables: {'message.roleMentions': '64,65'});
      expect(
        await _engine(service).execute(
          r'$createRole[Staff;123456;yes;]$modifyRole[64;!unchanged;#00ff00;no;yes]$modifyRolePerms[10;kick;ban]$colorRole[255]$deleteRole[65]done',
          context: context,
        ),
        'done',
      );
      final requests = service.requests;
      expect(requests.map((r) => r.operation.name), [
        'createRole',
        'updateRole',
        'updateRole',
        'updateRole',
        'deleteRole',
      ]);
      expect(requests[0].roleDefinition!.color, 123456);
      expect(requests[0].roleDefinition!.hoist, true);
      expect(requests[0].roleDefinition!.mentionable, false);
      expect(requests[1].roleDefinition!.name, isNull);
      expect(requests[1].roleDefinition!.color, 0x00ff00);
      expect(requests[1].roleDefinition!.hoist, false);
      expect(requests[2].roleId, '10');
      expect(requests[2].roleDefinition!.togglePermissions, [2, 4]);
      expect(requests[3].roleId, '64');
      expect(requests[4].roleId, '65');
      expect(service.budgets, everyElement(same(context.budget)));
    },
  );
  test('role definition bad arguments are rejected before transport', () async {
    final service = _Moderation();
    final engine = _engine(service);
    for (final source in [
      r'$createRole[;255]',
      r'$createRole[Staff;garbage]',
      r'$createRole[Staff;255;maybe]',
      r'$modifyRole[64;Staff;#FFFFFF;bad]',
      r'$modifyRolePerms[64;kick;unknown]',
      r'$deleteRole[0]',
      r'$colorRole[255]',
      r'$modifyRole[64;!unchanged;!unchanged;!unchanged;!unchanged;-1]',
    ]) {
      await expectLater(
        engine.execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.requests, isEmpty);
    }
    const opaque = r'$unknown[$createRole[Staff;255]$deleteRole[64]]';
    expect(await engine.execute(opaque), opaque);
    expect(service.requests, isEmpty);
  });

  test(
    'native role signatures preserve order, all mentions and shared budget',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        variables: {'author.id': '999', 'message.mentions': '222,333,222'},
      );
      final engine = _engine(service);
      final source =
          r'$giveRole[64]$takeRole[222;65]$roleGrant[333;+66;-64]done';
      final program = engine.prepare(source);
      expect(service.requests, isEmpty);
      expect(await engine.executeProgram(program, context: context), 'done');
      expect(
        service.requests.map(
          (r) => '${r.operation.name}:${r.userId}:${r.roleId}',
        ),
        [
          'addRole:222:64',
          'addRole:333:64',
          'removeRole:222:65',
          'addRole:333:66',
          'removeRole:333:64',
        ],
      );
      expect(service.budgets, everyElement(same(context.budget)));
      expect(
        service.requests.map((r) => r.useDefaultReason),
        everyElement(false),
      );
    },
  );
  test(
    'invalid role signatures and unknown wrappers produce no grants',
    () async {
      final service = _Moderation();
      final engine = _engine(service);
      for (final source in [
        r'$giveRole[64]',
        r'$giveRole[;64]',
        r'$takeRole[222;0]',
        r'$roleGrant[222;+64;bad]',
        r'$roleGrant[222;64]',
      ]) {
        await expectLater(
          engine.execute(
            source,
            context: BdfdContext(variables: {'author.id': '999'}),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.requests, isEmpty);
      }
      const source = r'$unknown[$giveRole[222;64]]';
      expect(await engine.execute(source), source);
      expect(service.requests, isEmpty);
      await expectLater(
        engine.execute(
          r'$giveRole[64]',
          context: BdfdContext(variables: {'message.mentions': '222,bad'}),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.requests, isEmpty);
    },
  );

  test(
    'bare kick targets author while explicit kick evaluates ID and reason once',
    () async {
      final service = _Moderation();
      final context = BdfdContext(variables: {'author.id': '999'});
      final engine = _engine(service);
      final source = r'$kick$var[id;222]$kick[$var[id];Reason $sum[2;3]]';
      final program = engine.prepare(source);
      expect(service.requests, isEmpty);
      expect(await engine.executeProgram(program, context: context), '');
      expect(service.requests.map((r) => r.userId), ['999', '222']);
      expect(service.requests.map((r) => r.reason), ['', 'Reason 5']);
      expect(
        service.requests.map((r) => r.operation),
        everyElement(BotModerationOperation.kick),
      );
      expect(service.budgets, everyElement(same(context.budget)));
      expect(
        service.requests.map((r) => r.useDefaultReason),
        everyElement(false),
      );
    },
  );
  test('empty explicit kick never selects author', () async {
    final service = _Moderation();
    final engine = _engine(service);
    for (final source in [
      r'$kick[]',
      r'$kick[;reason]',
      r'$kick[ ;reason]',
      r'$kick[$var[missing]]',
    ]) {
      await expectLater(
        engine.execute(
          source,
          context: BdfdContext(variables: {'author.id': '999'}),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(service.requests, isEmpty);
  });
  test(
    'ban targets first mention and interprets its sole argument as reason',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        variables: {
          'author.id': '999',
          'message.mentions[0]': '222',
          'message.mentions[1]': '333',
        },
      );
      await _engine(service).execute(r'$ban$ban[123]$ban[]', context: context);
      expect(service.requests.map((r) => r.userId), ['222', '222', '222']);
      expect(service.requests.map((r) => r.reason), ['', '123', '']);
      expect(
        service.requests.map((r) => r.operation),
        everyElement(BotModerationOperation.ban),
      );
    },
  );
  test(
    'ban supports encoded mentions but never defaults to the author',
    () async {
      final service = _Moderation();
      final engine = _engine(service);
      await engine.execute(
        r'$ban[Spam]',
        context: BdfdContext(
          variables: {'message.mentions': '222,333', 'author.id': '999'},
        ),
      );
      expect(service.requests.single.userId, '222');
      for (final variables in [
        {'author.id': '999'},
        {
          'author.id': '999',
          'message.mentions': '',
          'message.mentions[0]': '222',
        },
      ]) {
        await expectLater(
          engine.execute(
            r'$ban[Spam]',
            context: BdfdContext(variables: variables),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, hasLength(1));
    },
  );
  test(
    'banID reason precedes optional ID and vacancies select last message argument',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        variables: {
          'author.id': '999',
          'message.args.last': '333',
          'message.content': 'Spam 444',
        },
      );
      await _engine(service).execute(
        r'$banID$banID[Spam]$banID[;222]$banID[Spam;]',
        context: context,
      );
      expect(service.requests.map((r) => r.userId), [
        '333',
        '333',
        '222',
        '333',
      ]);
      expect(service.requests.map((r) => r.reason), ['', 'Spam', '', 'Spam']);
    },
  );
  test('invalid targets and reasons fail before service effects', () async {
    final service = _Moderation();
    final engine = _engine(service);
    for (final source in [
      r'$kick[0]',
      r'$kick[-1]',
      r'$banID[reason;abc]',
      '\$banID[${'x' * 513};222]',
      r'$banID',
    ]) {
      await expectLater(
        engine.execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(service.requests, isEmpty);
    await engine.execute('\$banID[${'x' * 512};222]');
    expect(service.requests.single.reason.length, 512);
  });
  test(
    'unknown wrappers never execute moderation inside their arguments',
    () async {
      final service = _Moderation();
      const source = r'$notAFunction[$kick[222];$banID[Spam;333]]';
      expect(await _engine(service).execute(source), source);
      expect(service.requests, isEmpty);
    },
  );
  test('evaluated reason remains data', () async {
    final service = _Moderation();
    final context = BdfdContext(
      temporaryVariables: {'reason': r'$kick[333] ((temp.target)) [x;y]'},
    );
    await _engine(
      service,
    ).execute(r'$banID[$var[reason];222]', context: context);
    expect(service.requests, hasLength(1));
    expect(
      service.requests.single.reason,
      context.temporaryVariables['reason'],
    );
  });
  test('preflight validates all branches before moderation', () async {
    final service = _Moderation();
    await expectLater(
      _engine(service).execute(r'$kick[222]$if[false]$ban[Spam;333]$endif'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(service.requests, isEmpty);
  });
  test(
    'selected branches, loops, guards and nested workflow use the same service and budget',
    () async {
      final service = _Moderation();
      final context = BdfdContext();
      final engine = _engine(service);
      await engine.execute(
        r'$if[false]$kick[999]$endif$for[2]$kick[222;loop $i]$endfor$var[target;333]$callWorkflow[child]$onlyIf[false;stop]$kick[999]',
        context: context,
      );
      expect(service.requests.map((r) => r.userId), ['222', '222', '333']);
      expect(service.requests.map((r) => r.reason), [
        'loop 0',
        'loop 1',
        'workflow',
      ]);
      expect(service.budgets, everyElement(same(context.budget)));
      expect(context.stopped, true);
    },
  );
  test(
    'catch exposes source-located permission error and never retries a mutation',
    () async {
      final service = _Moderation()..failNext = true;
      final context = BdfdContext();
      await _engine(service).execute(
        r'$try$kick[222]$catch$var[error;$error]$endtry$kick[333]',
        context: context,
      );
      expect(
        context.temporaryVariables['error'],
        contains('Permission denied'),
      );
      expect(service.requests.map((r) => r.userId), ['222', '333']);
    },
  );
  test(
    'entry-point selection passes moderation adapter and cannot fall back',
    () async {
      final service = _Moderation();
      var legacy = false;
      final execution = BdfdScriptExecution(
        store: _Store(),
        botId: 'bot',
        variables: {},
        moderation: service,
      );
      await execution.execute(r'$kick[222]', backend: 'native-v1');
      expect(legacy, false);
      expect(service.requests.single.userId, '222');
    },
  );
  test(
    'validation includes signatures but cannot execute moderation',
    () async {
      final validator = BdfdEngine.validation();
      expect(
        validator
            .prepare(r'$kick[222]$ban[Spam]$banID[;333]$unban$unbanID[222]')
            .source,
        r'$kick[222]$ban[Spam]$banID[;333]$unban$unbanID[222]',
      );
      await expectLater(
        validator.execute(r'$kick[222]'),
        throwsA(
          predicate((e) => '$e'.contains('Validation cannot moderate users')),
        ),
      );
    },
  );
  test('native unban sends the author message as an opaque username', () async {
    final service = _Moderation();
    final context = BdfdContext(
      variables: {'message.content': r' User $kick[222] ((temp.never)) '},
    );
    expect(await _engine(service).execute(r'$unban', context: context), '');
    final request = service.requests.single;
    expect(request.operation, BotModerationOperation.unban);
    expect(request.username, r'User $kick[222] ((temp.never))');
    expect(request.userId, '');
    expect(request.useDefaultReason, false);
  });
  test(
    'native unbanID distinguishes bare last argument and explicit ID',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        variables: {'message.args.last': '333', 'author.id': '999'},
      );
      await _engine(
        service,
      ).execute(r'$unbanID$unbanID[222]', context: context);
      expect(service.requests.map((r) => r.userId), ['333', '222']);
      expect(
        service.requests.map((r) => r.operation),
        everyElement(BotModerationOperation.unban),
      );
    },
  );
  test(
    'native unbanID empty explicit targets never fall back to message or author',
    () async {
      final service = _Moderation();
      for (final source in [
        r'$unbanID[]',
        r'$unbanID[ ]',
        r'$unbanID[0]',
        r'$unbanID[-1]',
        r'$unbanID[$var[missing]]',
      ]) {
        await expectLater(
          _engine(service).execute(
            source,
            context: BdfdContext(
              variables: {'message.args.last': '333', 'author.id': '999'},
            ),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unban signatures and missing implicit targets reject before service calls',
    () async {
      final service = _Moderation();
      for (final source in [
        r'$unban',
        r'$unbanID',
        r'$kick[222]$unban[user]',
        r'$kick[222]$unbanID[222;reason]',
      ]) {
        await expectLater(
          _engine(service).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unknown unban bodies remain literal and do not execute arguments',
    () async {
      final service = _Moderation();
      const source = r'$unknown[$unbanID[222];$unban]';
      expect(await _engine(service).execute(source), source);
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unban in a native child workflow shares its adapter and budget',
    () async {
      final service = _Moderation();
      final context = BdfdContext();
      await BdfdEngine(
        store: _Store(r'$unbanID[$var[target]]'),
        botId: 'bot',
        moderation: service,
      ).execute(r'$var[target;222]$callWorkflow[child]', context: context);
      expect(service.requests.single.operation, BotModerationOperation.unban);
      expect(service.requests.single.userId, '222');
      expect(service.budgets.single, same(context.budget));
    },
  );
  test(
    'timeout evaluates duration and explicit ID and untimeout clears that ID',
    () async {
      final service = _Moderation();
      final context = BdfdContext(
        temporaryVariables: {'duration': '1h30m', 'target': '222'},
      );
      await _engine(service).execute(
        r'$timeout[$var[duration];$var[target]]$untimeout[$var[target]]',
        context: context,
      );
      expect(service.requests.map((r) => r.operation), [
        BotModerationOperation.timeout,
        BotModerationOperation.untimeout,
      ]);
      expect(service.requests.first.duration, const Duration(minutes: 90));
      expect(service.requests.first.clampTimeout, false);
      expect(service.requests.map((r) => r.userId), ['222', '222']);
    },
  );
  test(
    'vacant timeout targets cover all mentions once without author fallback',
    () async {
      final service = _Moderation();
      await _engine(service).execute(
        r'$timeout[1m;]$untimeout[]',
        context: BdfdContext(
          variables: {'author.id': '999', 'message.mentions': '222,333,222'},
        ),
      );
      expect(service.requests.map((r) => r.userId), [
        '222',
        '333',
        '222',
        '333',
      ]);
      final missing = _Moderation();
      await expectLater(
        _engine(missing).execute(
          r'$timeout[1m]',
          context: BdfdContext(variables: {'author.id': '999'}),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(missing.requests, isEmpty);
    },
  );
  test(
    'invalid or excessive durations never fall back to the visual default',
    () async {
      final service = _Moderation();
      for (final duration in [
        '',
        'bad',
        '0s',
        '-1m',
        '28d1s',
        '99999999999999999999999999999999y',
      ]) {
        await expectLater(
          _engine(service).execute('\$timeout[$duration;222]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, isEmpty);
      await _engine(service).execute(r'$timeout[28d;222]');
      expect(service.requests.single.duration, const Duration(days: 28));
    },
  );
  test(
    'all mentioned IDs are validated before the first timeout effect',
    () async {
      final service = _Moderation();
      await expectLater(
        _engine(service).execute(
          r'$timeout[1m]',
          context: BdfdContext(
            variables: {
              'message.mentions[0]': '222',
              'message.mentions[1]': 'invalid',
            },
          ),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unknown wrappers preserve timeout arguments without execution',
    () async {
      final service = _Moderation();
      const source = r'$unknown[$timeout[1m;222];$untimeout[333]]';
      expect(await _engine(service).execute(source), source);
      expect(service.requests, isEmpty);
    },
  );
  test(
    'kickMention targets only first mention and requests author permission',
    () async {
      final service = _Moderation();
      await _engine(service).execute(
        r'$kickMention[Reason $sum[2;3]]',
        context: BdfdContext(
          variables: {'author.id': '999', 'message.mentions': '222,333'},
        ),
      );
      final request = service.requests.single;
      expect(request.userId, '222');
      expect(request.kickPermissionActorId, '999');
      expect(request.reason, 'Reason 5');
      expect(request.operation, BotModerationOperation.kick);
    },
  );
  test(
    'kickMention cannot substitute author for missing mention or missing actor',
    () async {
      final service = _Moderation();
      for (final variables in [
        {'author.id': '999'},
        {'message.mentions[0]': '222'},
        {'author.id': '', 'message.mentions[0]': '222'},
      ]) {
        await expectLater(
          _engine(service).execute(
            r'$kickMention[]',
            context: BdfdContext(variables: variables),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, isEmpty);
    },
  );
  test(
    'kickMention reason is required but emptiable and unknown wrappers are opaque',
    () async {
      final service = _Moderation();
      await expectLater(
        _engine(service).execute(r'$kick[222]$kickMention'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.requests, isEmpty);
      const source = r'$unknown[$kickMention[$kick[222]]]';
      expect(await _engine(service).execute(source), source);
      expect(service.requests, isEmpty);
      await _engine(service).execute(
        r'$kickMention[]',
        context: BdfdContext(
          variables: {'author.id': '999', 'message.mentions[0]': '222'},
        ),
      );
      expect(service.requests.single.reason, '');
    },
  );
}
