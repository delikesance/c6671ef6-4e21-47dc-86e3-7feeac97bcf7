import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_execution.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/runtime_cooldowns.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';
import 'helpers/visual_discord_gateway.dart';
import 'helpers/visual_message_gateway.dart';

/// `BdfdActionRunner.runList`: a whole action list on the native engine with no
/// historical loop behind it (root stop/skip/jump, error modes, nested lists,
/// hydration, replay, policy, `debugProfile`, acknowledgement, `cooldown`).
/// Expectations are explicit values; where the historical loop still exists the
/// same list is also run through it (`parityWithHistorical`) and compared.

const bool parityWithHistorical = true;

class _Store extends MemoryBotDataStore {
  _Store([this.workflows = const {}]);
  final Map<String, Map<String, dynamic>> workflows;
  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => workflows[name];
}

class _Run {
  _Run(
    this.gateway,
    this.interaction,
    this.results,
    this.variables,
    this.error,
    this.logs,
    this.frames,
  );
  final MessageGateway gateway;
  final FakeInteraction? interaction;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final List<String> logs;
  final List<Map<String, dynamic>> frames;

  List<Map<String, Object?>> get sends => [
    for (final write in gateway.writes)
      if (write['operation'] == 'send') write,
  ];

  /// The embeds sent to the channel, in order.
  List<Map<String, dynamic>> get embeds => [
    for (final send in sends)
      for (final embed
          in (send['payload'] as Map)['embeds'] as List? ?? const [])
        Map<String, dynamic>.from(embed as Map),
  ];
}

Future<_Run> _go(
  List<Action> actions, {
  bool runList = true,
  Map<String, String>? variables,
  Map<String, Map<String, dynamic>> workflows = const {},
  BotDataStore? store,
  FakeInteraction? interaction,
  Snowflake? fallbackChannelId,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  VisualAcknowledgement? acknowledgement,
  CommandExecutionBudget? budget,
  int Function() Function()? clock,
  bool captureReplay = false,
}) async {
  final gateway = MessageGateway(data: visualFixtures());
  final values = <String, String>{
    'guild.id': '10',
    'bot.id': '500',
    ...?variables,
  };
  final logs = <String>[];
  final frames = <Map<String, dynamic>>[];
  Map<String, String>? results;
  Object? error;
  handleActionsForwardsToRunList = runList;
  try {
    results = await handleActions(
      gateway,
      interaction,
      actions: actions.map((a) => Action.fromJson(a.toJson())).toList(),
      store: store ?? _Store(workflows),
      botId: 'bot',
      variables: values,
      fallbackGuildId: Snowflake(10),
      fallbackChannelId: fallbackChannelId,
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      onLog: logs.add,
      executionPolicy: policy,
      throwOnError: throwOnError,
      executionBudget: budget,
      acknowledgement: acknowledgement,
      startProfileClock: clock,
      onReplayCaptured: captureReplay
          ? (captured, _) => frames.addAll(captured)
          : null,
      actionTranslator: runList
          ? const ActionTranslator()
          : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  } finally {
    handleActionsForwardsToRunList = false;
  }
  values.remove('execution.time');
  return _Run(gateway, interaction, results, values, error, logs, frames);
}

Action _a(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic> payload = const {},
  Map<String, String> error = const {},
  bool enabled = true,
}) =>
    Action(type: type, key: key, enabled: enabled, payload: payload)
      ..error.addAll(error);

Action _log(String key, String message) =>
    _a(BotCreatorActionType.log, key: key, payload: {'message': message});
Action _stop(String key) => _a(BotCreatorActionType.stop, key: key);
Action _skip(String key, int count) => _a(
  BotCreatorActionType.skipActions,
  key: key,
  payload: {'count': '$count'},
);
Action _jump(String key, String target) => _a(
  BotCreatorActionType.jumpToAction,
  key: key,
  payload: {'targetKey': target},
);
Action _profile({Map<String, dynamic> payload = const {}}) =>
    _a(BotCreatorActionType.debugProfile, key: 'prof', payload: payload);
Action _failing(String key, {Map<String, String> error = const {}}) => _a(
  BotCreatorActionType.addRole,
  key: key,
  error: error,
  payload: {'userId': '', 'roleId': ''},
);
Action _loop(String key, int times, List<Action> body) => _a(
  BotCreatorActionType.forLoop,
  key: key,
  payload: {
    'mode': 'simple',
    'iterations': '$times',
    'bodyActions': body.map((a) => a.toJson()).toList(),
  },
);
Action _if(String key, List<Action> then) => _a(
  BotCreatorActionType.ifBlock,
  key: key,
  payload: {
    'variable': 'flag',
    'operator': 'equals',
    'value': 'yes',
    'thenActions': then.map((a) => a.toJson()).toList(),
  },
);

/// Both engines over the same list; the native outcome is returned and its
/// observable parts equal the historical loop's.
Future<_Run> _both(
  List<Action> actions, {
  Map<String, String>? variables,
  Snowflake? fallbackChannelId,
}) async {
  final native = await _go(
    actions,
    variables: variables,
    fallbackChannelId: fallbackChannelId,
  );
  if (parityWithHistorical) {
    final historical = await _go(
      actions,
      runList: false,
      variables: variables,
      fallbackChannelId: fallbackChannelId,
    );
    expect(native.results, historical.results, reason: 'results');
    expect(native.variables, historical.variables, reason: 'variables');
    expect('${native.error}', '${historical.error}', reason: 'error');
    expect(native.logs, historical.logs, reason: 'logs');
    expect(native.sends, historical.sends, reason: 'effects');
  }
  return native;
}

/// Wall-clock figures of the historical embed are masked.
String _masked(Map<String, dynamic> embed) => '$embed'
    .replaceAll(RegExp(r'\+\d+ms \(\d+ms\)'), '+Nms (Nms)')
    .replaceAll(RegExp(r'Total: \d+ms'), 'Total: Nms');

void main() {
  tearDown(() {
    handleActionsForwardsToRunList = false;
    RuntimeCooldowns.expirations.clear();
  });

  group('root flow', () {
    test('stop ends the list', () async {
      final run = await _both([_log('a', 'one'), _stop('s'), _log('b', 'two')]);
      expect(run.results, {
        'a': 'LOGGED',
        's': 'STOPPED',
        '__stopped__': 'true',
      });
      expect(run.logs, ['one']);
    });

    test('stopUnless stops on a failed condition only', () async {
      Action gate(String value) => _a(
        BotCreatorActionType.stopUnless,
        key: 'gate',
        payload: {'variable': 'flag', 'operator': 'equals', 'value': value},
      );
      final stopped = await _both(
        [gate('no'), _log('after', 'x')],
        variables: {'flag': 'yes'},
      );
      expect(stopped.results, {'gate': 'STOPPED', '__stopped__': 'true'});
      final passed = await _both(
        [gate('yes'), _log('after', 'x')],
        variables: {'flag': 'yes'},
      );
      expect(passed.results, {'gate': 'PASSED', 'after': 'LOGGED'});
    });

    test('skipActions skips the following actions', () async {
      final run = await _both([
        _log('a', 'a'),
        _skip('s', 2),
        _log('b', 'b'),
        _log('c', 'c'),
        _log('d', 'd'),
      ]);
      expect(run.logs, ['a', 'd']);
      expect(run.results, {'a': 'LOGGED', 's': 'SKIPPED_2', 'd': 'LOGGED'});
    });

    test('jumpToAction goes forward by key, id or position', () async {
      final byKey = await _both([
        _jump('j', 'target'),
        _log('skipped', 'no'),
        _log('target', 'yes'),
      ]);
      expect(byKey.logs, ['yes']);
      expect(byKey.results, {'j': 'JUMP_TO_target', 'target': 'LOGGED'});
      final byPosition = await _both([
        _jump('j', '3'),
        _log('skipped', 'no'),
        _log('target', 'yes'),
      ]);
      expect(byPosition.logs, ['yes']);
      final unknown = await _both([_jump('j', 'nowhere'), _log('next', 'n')]);
      expect(unknown.logs, ['n']);
    });

    test('a numeric jump backwards at the root really jumps back', () async {
      // n = 0; loop: n = n + 1, log n, continue while n < 3 (jump to #2).
      final run = await _both([
        _a(
          BotCreatorActionType.setTemporaryVariable,
          key: 'init',
          payload: {'key': 'n', 'value': '0'},
        ),
        _a(
          BotCreatorActionType.calculate,
          key: 'calc',
          payload: {'expression': '((temp.n))+1'},
        ),
        _a(
          BotCreatorActionType.setTemporaryVariable,
          key: 'store',
          payload: {'key': 'n', 'value': '((calc))'},
        ),
        _log('show', 'n=((temp.n))'),
        _a(
          BotCreatorActionType.stopUnless,
          key: 'more',
          payload: {'variable': 'temp.n', 'operator': 'lessThan', 'value': '3'},
        ),
        _jump('back', '2'),
      ]);
      expect(run.logs, ['n=1', 'n=2', 'n=3']);
      expect(run.results!['more'], 'STOPPED');
      expect(run.results!['__stopped__'], 'true');
    });

    test('a runaway backward jump ends with the execution budget', () async {
      final run = await _go(
        [_log('tick', 't'), _jump('again', '1')],
        budget: CommandExecutionBudget(
          limit: const Duration(milliseconds: 300),
        ),
      );
      expect(run.error, isA<CommandExecutionTimeout>());
      expect(run.logs.length, greaterThan(3));
    });
  });

  group('error modes at the root', () {
    test('stop (default) rethrows after recording the failure', () async {
      final run = await _both([
        _log('a', 'a'),
        _failing('bad'),
        _log('b', 'b'),
      ]);
      expect(run.error, isA<Exception>());
      // The list failed: its results are lost with the rethrown exception.
      expect(run.results, isNull);
      expect(run.variables['error.message'], contains('Missing or invalid'));
      expect(run.variables['error.command'], 'addRole');
      expect(run.logs, ['a']);
    });

    test('continue, skip and jump keep the list going', () async {
      final cont = await _both([
        _failing('bad', error: {'mode': 'continue'}),
        _log('b', 'b'),
      ]);
      expect(cont.error, isNull);
      expect(cont.results!['b'], 'LOGGED');
      final skip = await _both([
        _failing('bad', error: {'mode': 'skip', 'skipCount': '1'}),
        _log('skipped', 'no'),
        _log('c', 'c'),
      ]);
      expect(skip.logs, ['c']);
      final jump = await _both([
        _failing('bad', error: {'mode': 'jump', 'jumpToActionId': 'there'}),
        _log('skipped', 'no'),
        _log('there', 'there'),
      ]);
      expect(jump.logs, ['there']);
    });

    test('a protected execution ignores error modes', () async {
      final run = await _go([
        _failing('bad', error: {'mode': 'continue'}),
        _log('b', 'b'),
      ], throwOnError: true);
      expect(run.error, isA<Exception>());
      expect(run.logs, isEmpty);
    });
  });

  group('nested lists and entities', () {
    test(
      'a runWorkflow runs the stored list and publishes its results',
      () async {
        final run = await _both([
          _a(
            BotCreatorActionType.runWorkflow,
            key: 'wf',
            payload: {'workflowName': 'inner'},
          ),
        ]);
        expect(run.error, isA<Exception>());
        expect('${run.error}', 'Exception: Workflow not found: inner');
        expect(run.variables['error.command'], 'runWorkflow');
        final found = await _go(
          [
            _a(
              BotCreatorActionType.runWorkflow,
              key: 'wf',
              payload: {'workflowName': 'inner'},
            ),
          ],
          workflows: {
            'inner': {
              'actions': [_log('l', 'inside').toJson(), _stop('s').toJson()],
            },
          },
        );
        expect(found.error, isNull);
        expect(found.results, {
          'wf.l': 'LOGGED',
          'wf.s': 'STOPPED',
          'wf.__stopped__': 'true',
          '__stopped__': 'true',
          'wf': 'WORKFLOW_OK:main',
        });
        expect(found.logs, ['inside']);
        expect(found.variables['workflow.response.l'], 'LOGGED');
      },
    );

    test(
      'placeholders naming an entity are hydrated before every action',
      () async {
        final actions = [
          _log('root', 'root=((channel[31].name))'),
          _if('gate', [_log('nested', 'nested=((channel[31].name))')]),
        ];
        final run = await _go(
          actions,
          variables: {'flag': 'yes'},
          policy: _Hydrating(),
        );
        expect(run.error, isNull);
        expect(run.logs, ['root=category', 'nested=category']);
        expect(run.results, {
          'root': 'LOGGED',
          'gate': 'IF_TRUE',
          'gate.nested': 'LOGGED',
        });
      },
    );

    test('execution.time is refreshed before each root action', () async {
      final run = await _go([
        _a(BotCreatorActionType.wait, key: 'w', payload: {'duration': '40ms'}),
        _log('l', '((execution.time))'),
      ]);
      final ms = int.parse(run.logs.single.replaceAll('ms', ''));
      expect(ms, greaterThanOrEqualTo(35));
    });

    test('a numeric result becomes the last sent message', () async {
      final run = await _go([
        _a(
          BotCreatorActionType.calculate,
          key: 'calc',
          payload: {'expression': '40+2'},
        ),
      ]);
      expect(run.results, {'calc': '42'});
      expect(run.variables['lastSentMessageId'], '42');
    });

    test('a replay is captured with one frame per native call', () async {
      final run = await _go(
        [
          _log('a', 'a'),
          _if('gate', [_log('b', 'b')]),
        ],
        variables: {'flag': 'yes'},
        captureReplay: true,
      );
      final keys = [
        for (final frame in run.frames)
          if (frame['nativeStatus'] == 'returned' &&
              frame['visualActionType'] == 'log')
            frame['actionKey'],
      ];
      expect(keys, ['a', 'b']);
      final frame = run.frames.firstWhere(
        (f) => f['actionKey'] == 'a' && f['nativeStatus'] == 'returned',
      );
      expect(frame['visualActionType'], 'log');
      expect(frame['variablesBefore'], isA<Map>());
      expect(frame['variablesAfter'], isA<Map>());
    });
  });

  group('execution policy', () {
    test('every action is checked, intercepted and recorded', () async {
      final policy = _Policy(simulate: {BotCreatorActionType.addRole});
      final run = await _go(
        [
          _a(
            BotCreatorActionType.addRole,
            key: 'role',
            payload: {'userId': '5', 'roleId': '6'},
          ),
          _log('l', 'x'),
          _if('gate', [_log('inner', 'y')]),
        ],
        policy: policy,
        variables: {'flag': 'yes'},
      );
      expect(run.error, isNull);
      expect(run.results, {
        'role': 'simulated',
        'l': 'LOGGED',
        'gate': 'IF_TRUE',
        'gate.inner': 'LOGGED',
      });
      // Every leaf (role, l, inner) is offered to the policy, with its list's
      // results; blocks are never intercepted but still get their frame, after
      // their children.
      expect(policy.intercepted, ['addRole', 'log', 'log']);
      expect(policy.recorded.map((f) => f['actionType']), [
        'addRole',
        'log',
        'log',
        'ifBlock',
      ]);
      expect(policy.recorded.map((f) => f['result']), [
        'simulated',
        'LOGGED',
        'LOGGED',
        'IF_TRUE',
      ]);
      expect(policy.budgetChecks, greaterThanOrEqualTo(3));
    });

    test('a failing action records its error frame', () async {
      final policy = _Policy();
      final run = await _go([_failing('bad')], policy: policy);
      expect(run.error, isA<Exception>());
      // The action's own frame, then the enclosing handler's (as before).
      expect(policy.recorded.map((f) => f['actionType']), [
        'addRole',
        'addRole',
      ]);
      expect(policy.recorded.map((f) => f['result']), [
        'Error: Exception: Missing or invalid userId/roleId',
        'Error: Exception: Missing or invalid userId/roleId',
      ]);
    });
  });

  group('acknowledgement', () {
    Future<(VisualAcknowledgement, List<bool>)> ack(
      List<Action> actions, {
      bool enabled = true,
      bool ephemeral = false,
      bool failing = false,
      bool runList = true,
    }) async {
      final calls = <bool>[];
      final acknowledgement = VisualAcknowledgement(
        enabled: enabled,
        ephemeral: ephemeral,
        acknowledge: ({required bool ephemeral}) async {
          calls.add(ephemeral);
          if (failing) throw StateError('already acknowledged');
        },
      );
      await _go(actions, acknowledgement: acknowledgement, runList: runList);
      return (acknowledgement, calls);
    }

    for (final runList in [true, false]) {
      final label = runList ? 'runList' : 'historical loop';
      test('defers before the first action ($label)', () async {
        final (state, calls) = await ack([_log('a', 'a')], runList: runList);
        expect(calls, [false]);
        expect(state.didDefer, isTrue);
      });

      test(
        'an ephemeral workflow or message defers ephemeral ($label)',
        () async {
          final (_, byWorkflow) = await ack(
            [_log('a', 'a')],
            ephemeral: true,
            runList: runList,
          );
          expect(byWorkflow, [true]);
          final (_, byMessage) = await ack([
            _a(
              BotCreatorActionType.respondWithMessage,
              key: 'r',
              payload: {'content': 'hi', 'ephemeral': true},
            ),
          ], runList: runList);
          expect(byMessage, [true]);
        },
      );

      test(
        'a deferInteraction, a modal or autoDefer off do not defer ($label)',
        () async {
          final (_, withDefer) = await ack([
            _a(BotCreatorActionType.deferInteraction, key: 'd'),
          ], runList: runList);
          expect(withDefer, isEmpty);
          final (_, withModal) = await ack([
            _a(
              BotCreatorActionType.respondWithModal,
              key: 'm',
              payload: {
                'modal': {'title': 't', 'customId': 'c', 'components': []},
              },
            ),
          ], runList: runList);
          expect(withModal, isEmpty);
          final (disabled, none) = await ack(
            [_log('a', 'a')],
            enabled: false,
            runList: runList,
          );
          expect(none, isEmpty);
          expect(disabled.didDefer, isFalse);
          final (_, empty) = await ack(const [], runList: runList);
          expect(empty, isEmpty);
        },
      );

      test(
        'a failing acknowledgement leaves didDefer false ($label)',
        () async {
          final (state, calls) = await ack(
            [_log('a', 'a')],
            failing: true,
            runList: runList,
          );
          expect(calls, [false]);
          expect(state.didDefer, isFalse);
        },
      );
    }

    test('nested lists never acknowledge', () async {
      final calls = <bool>[];
      await _go(
        [
          _a(
            BotCreatorActionType.runWorkflow,
            key: 'wf',
            payload: {'workflowName': 'inner'},
          ),
        ],
        workflows: {
          'inner': {
            'actions': [_log('l', 'x').toJson()],
          },
        },
        acknowledgement: VisualAcknowledgement(
          acknowledge: ({required bool ephemeral}) async =>
              calls.add(ephemeral),
        ),
      );
      expect(calls, [false]);
    });

    test('the acknowledgement reaches the interaction', () async {
      final interaction = FakeInteraction();
      await _go(
        [_log('a', 'a')],
        interaction: interaction,
        acknowledgement: VisualAcknowledgement(
          acknowledge: ({required bool ephemeral}) =>
              interaction.acknowledge(isEphemeral: ephemeral),
        ),
      );
      expect(interaction.calls.first, {
        'op': 'acknowledge',
        'ephemeral': false,
      });
    });
  });

  group('debugProfile', () {
    int Function() Function() ticking() => () {
      var now = 0;
      return () => now += 10;
    };

    test('sends the trace embed at the end of the list', () async {
      final run = await _go(
        [
          _log('before', 'ignored by the trace'),
          _profile(
            payload: {
              'compilationMs': 3,
              'sourceLength': 120,
              'actionCount': 2,
            },
          ),
          _log('a', 'a'),
          _failing('bad', error: {'mode': 'continue'}),
          _log('c', 'c'),
        ],
        fallbackChannelId: Snowflake(30),
        clock: ticking(),
      );
      expect(run.error, isNull);
      expect(run.embeds, hasLength(1));
      final embed = run.embeds.single;
      expect(embed['title'], '\u{1F50D} Debug Trace');
      expect(embed['color'], 0xFF9800);
      expect(
        embed['description'],
        [
          '`1.` \u2705 **log** \u2014 +10ms (10ms)',
          '`2.` \u274c **addRole** \u2014 +30ms (10ms)',
          '`3.` \u2705 **log** \u2014 +50ms (10ms)',
        ].join('\n'),
      );
      expect(embed['footer'], {'text': 'Total: 70ms \u2022 3 action(s)'});
      expect(embed['fields'], [
        {
          'name': '\u2699\ufe0f Compilation',
          'value': '3ms \u2022 120 chars \u2022 2 actions',
          'inline': false,
        },
      ]);
      // The trace is not a result: no entry for the profile action itself.
      expect(run.results!.containsKey('prof'), isFalse);
    });

    test('the historical loop and the runner send the same embed', () async {
      final actions = [
        _profile(),
        _log('a', 'a'),
        _failing('bad', error: {'mode': 'continue'}),
        _loop('loop', 2, [_log('in', 'in')]),
      ];
      final native = await _go(actions, fallbackChannelId: Snowflake(30));
      final historical = await _go(
        actions,
        runList: false,
        fallbackChannelId: Snowflake(30),
      );
      expect(native.embeds, hasLength(1));
      expect(historical.embeds, hasLength(1));
      expect(_masked(native.embeds.single), _masked(historical.embeds.single));
      expect(native.results, historical.results);
    });

    test('an empty trace says so, without compilation metadata', () async {
      final run = await _go(
        [_profile()],
        fallbackChannelId: Snowflake(30),
        clock: ticking(),
      );
      final embed = run.embeds.single;
      expect(embed['description'], '_No actions executed after \$debug._');
      expect(embed['footer'], {'text': 'Total: 10ms \u2022 0 action(s)'});
      expect(embed.containsKey('fields'), isFalse);
    });

    test('loop depth and iteration come from the payload', () async {
      Action looped(String key, int iteration) => _a(
        BotCreatorActionType.log,
        key: key,
        payload: {
          'message': key,
          '_debugLoopDepth': 1,
          '_debugLoopIteration': iteration,
        },
      );
      final run = await _go(
        [
          _profile(),
          _log('a', 'a'),
          looped('x', 0),
          looped('y', 0),
          looped('z', 1),
          _log('b', 'b'),
        ],
        fallbackChannelId: Snowflake(30),
        clock: ticking(),
      );
      expect((run.embeds.single['description'] as String).split('\n'), [
        '`1.` \u2705 **log** \u2014 +10ms (10ms)',
        '\u2500 **\$for** iteration 0',
        '\u2003`2.` \u2705 **log** \u2014 +30ms (10ms)',
        '\u2003`3.` \u2705 **log** \u2014 +50ms (10ms)',
        '\u2500 **\$for** iteration 1',
        '\u2003`4.` \u2705 **log** \u2014 +70ms (10ms)',
        '`5.` \u2705 **log** \u2014 +90ms (10ms)',
      ]);
    });

    test('a stop or a failure sends nothing', () async {
      final stopped = await _go([
        _profile(),
        _log('a', 'a'),
        _stop('s'),
      ], fallbackChannelId: Snowflake(30));
      expect(stopped.embeds, isEmpty);
      final failed = await _go([
        _profile(),
        _failing('bad'),
      ], fallbackChannelId: Snowflake(30));
      expect(failed.error, isA<Exception>());
      expect(failed.embeds, isEmpty);
    });

    test('no channel, no embed; a disabled profile is no profile', () async {
      final noChannel = await _go([_profile(), _log('a', 'a')]);
      expect(noChannel.sends, isEmpty);
      final disabled = await _go([
        _a(BotCreatorActionType.debugProfile, key: 'p', enabled: false),
        _log('a', 'a'),
      ], fallbackChannelId: Snowflake(30));
      expect(disabled.sends, isEmpty);
    });

    test(
      'a block body owns its own profile: one embed per iteration',
      () async {
        final actions = [
          _loop('loop', 2, [_profile(), _log('in', 'in')]),
          _log('after', 'after'),
        ];
        final native = await _go(actions, fallbackChannelId: Snowflake(30));
        final historical = await _go(
          actions,
          runList: false,
          fallbackChannelId: Snowflake(30),
        );
        expect(native.embeds, hasLength(2));
        expect(
          native.embeds.map(_masked).toList(),
          historical.embeds.map(_masked).toList(),
        );
        // The root list has no profile of its own: nothing else was sent.
        expect(native.sends, hasLength(2));
        for (final embed in native.embeds) {
          expect(embed['footer'], isA<Map>());
          expect((embed['description'] as String), contains('**log**'));
        }
      },
    );

    test('a second debugProfile restarts the trace', () async {
      final run = await _go(
        [_profile(), _log('a', 'a'), _profile(), _log('b', 'b')],
        fallbackChannelId: Snowflake(30),
        clock: ticking(),
      );
      expect(run.embeds, hasLength(1));
      expect(run.embeds.single['footer'], {
        'text': 'Total: 30ms \u2022 1 action(s)',
      });
    });
  });

  group('cooldown', () {
    Action cooldown(String key, Map<String, dynamic> payload) =>
        _a(BotCreatorActionType.cooldown, key: key, payload: payload);

    test('sets, then blocks and tells the user', () async {
      final payload = {
        'scope': 'global',
        'key': 'run-list-test',
        'duration': '1h',
        'errorMessage': 'wait %time%',
      };
      final first = await _go([
        cooldown('cd', payload),
        _log('go', 'go'),
      ], fallbackChannelId: Snowflake(30));
      expect(first.results, {'cd': 'SET', 'go': 'LOGGED'});
      final second = await _go([
        cooldown('cd', payload),
        _log('go', 'go'),
      ], fallbackChannelId: Snowflake(30));
      expect(second.results!['cd'], 'ACTIVE');
      expect(second.results!['__stopped__'], 'true');
      expect(second.results!.containsKey('go'), isFalse);
      expect(second.results!['cooldown.error'], matches(r'^wait <t:\d+:R>$'));
      expect(second.variables['cooldown.time'], matches(r'^<t:\d+:R>$'));
      expect(second.logs, ['go'].take(0).toList());
      expect(second.sends, hasLength(1));
      expect(
        (second.sends.single['payload'] as Map)['content'],
        second.results!['cooldown.error'],
      );
    });

    test('the historical block behaves the same', () async {
      final payload = {'scope': 'global', 'key': 'hist', 'duration': '1h'};
      final native = await _go([cooldown('cd', payload)]);
      RuntimeCooldowns.expirations.clear();
      final historical = await _go([cooldown('cd', payload)], runList: false);
      expect(native.results, historical.results);
      expect(native.results, {'cd': 'SET'});
    });

    test('change only touches an existing cooldown', () async {
      final set = {'scope': 'global', 'key': 'chg', 'duration': '1h'};
      final change = {...set, 'operation': 'change', 'duration': '0s'};
      expect((await _go([cooldown('cd', change)])).results, {'cd': 'CHANGED'});
      await _go([cooldown('cd', set)]);
      await _go([cooldown('cd', change)]);
      // Changed to zero: the cooldown is gone.
      expect((await _go([cooldown('cd', set)])).results, {'cd': 'SET'});
    });

    test('an invalid duration fails like the historical block', () async {
      final run = await _go([
        cooldown('cd', {'scope': 'global', 'key': 'bad', 'duration': 'soon'}),
      ]);
      expect(run.error, isA<FormatException>());
      expect(
        '${run.error}',
        'FormatException: Invalid cooldown duration: soon',
      );
      expect(run.variables['error.command'], 'cooldown');
    });
  });
}

class _Hydrating extends _Policy {
  @override
  bool get allowDiscordHydration => true;
}

class _Policy implements ActionExecutionPolicy {
  _Policy({this.simulate = const {}});
  final Set<BotCreatorActionType> simulate;
  final intercepted = <String>[];
  final recorded = <Map<String, dynamic>>[];
  int budgetChecks = 0;

  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() => budgetChecks++;
  @override
  void record(Map<String, dynamic> frame) => recorded.add(frame);
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async {
    intercepted.add(action.type.name);
    if (!simulate.contains(action.type)) return false;
    results[resultKey] = 'simulated';
    return true;
  }
}
