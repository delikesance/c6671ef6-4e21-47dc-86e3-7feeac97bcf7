import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_golden.dart';
import 'helpers/fake_role_gateway.dart';
import 'helpers/variables_test_helpers.dart';

/// Parity of addRole / removeRole between the historical executor
/// (`ActionTranslator.none()`) and the native engine (`bc_addRole`,
/// `bc_removeRole`): the same actions run through both paths over the same
/// simulated Discord gateway, then recorded effects, `results`, final
/// variables and errors are compared.

class _Spy extends ActionTranslator {
  _Spy() : super();
  int native = 0;
  @override
  BdfdActionProgram translate(
    List<Action> actions, {
    int firstIndex = 0,
    bool topLevelErrorModes = true,
  }) {
    native++;
    return super.translate(
      actions,
      firstIndex: firstIndex,
      topLevelErrorModes: topLevelErrorModes,
    );
  }
}

class _NoHydration implements ActionExecutionPolicy {
  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() {}
  @override
  void record(Map<String, dynamic> frame) {}
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async => false;
}

class _Outcome {
  _Outcome(this.gateway, this.results, this.variables, this.error, this.native);
  final FakeGateway gateway;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;

  Map<String, Object?> get effects => {
    'roleChanges': gateway.guild.memberManager.roleChanges,
    'updates': gateway.guild.memberManager.updates,
    'guildLookups': gateway.guild.lookups,
  };
  Object? get errorText => error == null
      ? null
      : '${error.runtimeType}: ${error is CommandExecutionTimeout ? 'timeout' : error}';
}

Action _role(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic>? payload,
  Map<String, String> error = const {},
  bool enabled = true,
}) => Action(
  type: type,
  key: key,
  enabled: enabled,
  payload: {'userId': '222', 'roleId': '64', ...?payload},
)..error.addAll(error);

Future<_Outcome> _execute(
  List<Action> actions, {
  required bool native,
  void Function(FakeGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  Duration? limit,
}) async {
  final gateway = FakeGateway()
    ..guild.permissions = Permissions.manageRoles.value;
  setup?.call(gateway);
  final values = <String, String>{'guild.id': '10', ...?variables};
  final spy = _Spy();
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      gateway,
      null,
      actions: actions,
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: values,
      fallbackGuildId: guild ? Snowflake(10) : null,
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      executionPolicy: policy,
      throwOnError: throwOnError,
      executionBudget: limit == null
          ? null
          : CommandExecutionBudget(limit: limit),
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return _Outcome(gateway, results, values, error, spy.native);
}

/// Runs both paths and compares everything observable.
Future<_Outcome> _parity(
  List<Action> actions, {
  void Function(FakeGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  Duration? limit,
  bool expectNative = true,

  /// Programs translated natively. For a block kept historical, only its
  /// supported children (executed by the nested historical loop) are.
  int? nativePrograms,
}) async {
  Future<_Outcome> run(bool native) => _execute(
    // Action objects are rebuilt from JSON: no state shared between the runs.
    actions.map((a) => Action.fromJson(a.toJson())).toList(),
    native: native,
    setup: setup,
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    policy: policy,
    limit: limit,
  );
  // The historical run goes first: the native outcome is compared as soon as
  // it is back (a delayed lookup keeps writing into its variables).
  final historical = parityWithHistorical ? await run(false) : null;
  final native = await run(true);
  if (nativePrograms != null) {
    expect(native.native, nativePrograms);
  } else if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  // Explicit expectations of the native path alone (test/golden).
  // A timed-out run keeps writing its error variables on its own schedule, so
  // under a time limit they are left out of every comparison (both runs race
  // the clock independently and may or may not have written them yet).
  Map<String, String> settled(Map<String, String> variables) => {
    for (final e in variables.entries)
      if (limit == null || !e.key.startsWith('error.')) e.key: e.value,
  };
  _golden.expectSnapshot({
    'effects': native.effects,
    'results': native.results,
    'variables': settled(native.variables),
    'error': native.errorText,
  });
  if (historical == null) return native;
  expect(historical.native, 0);
  expect(native.effects, historical.effects, reason: 'effects');
  expect(native.results, historical.results, reason: 'results');
  expect(
    settled(native.variables),
    settled(historical.variables),
    reason: 'variables',
  );
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}

Map<String, String> _conditionOn(String variable, String value) => {
  'variable': variable,
  'operator': 'equals',
  'value': value,
};

final _golden = GoldenFile('visual_role_actions');

void main() {
  for (final type in [
    BotCreatorActionType.addRole,
    BotCreatorActionType.removeRole,
  ]) {
    final add = type == BotCreatorActionType.addRole;
    group('${type.name} parity', () {
      test('grants with an explicit reason', () async {
        final outcome = await _parity([
          _role(type, key: 'role', payload: {'reason': 'Because'}),
        ]);
        expect(outcome.results, {'role': '222'});
        expect(outcome.gateway.guild.memberManager.roleChanges, [
          {
            'operation': add ? 'add' : 'remove',
            'user': '222',
            'role': '64',
            'reason': 'Because',
          },
        ]);
        // Numeric results are "the last message" for the historical trace.
        expect(outcome.variables['lastSentMessageId'], '222');
      });

      test('keeps the historical default audit reason', () async {
        final outcome = await _parity([_role(type)]);
        expect(outcome.results, {'action_0': '222'});
        expect(
          outcome.gateway.guild.memberManager.roleChanges.single['reason'],
          add
              ? 'Add role via BotCreator action'
              : 'Remove role via BotCreator action',
        );
      });

      test('falls back to memberId and resolves placeholders', () async {
        final outcome = await _parity(
          [
            _role(
              type,
              payload: {
                'userId': 'nope',
                'memberId': '((target))',
                'roleId': '((role.id))',
              },
            ),
          ],
          variables: {'target': '333', 'role.id': '64'},
        );
        expect(
          outcome.gateway.guild.memberManager.roleChanges.single['user'],
          '333',
        );
      });

      test('later actions read earlier results of the same list', () async {
        final outcome = await _parity([
          _role(type, key: 'first'),
          _role(
            type,
            key: 'second',
            payload: {
              'userId': '((first))',
              'roleId': '64',
              'reason': '((action.first)) done',
            },
          ),
        ]);
        expect(outcome.results, {'first': '222', 'second': '222'});
        expect(
          outcome.gateway.guild.memberManager.roleChanges.last['reason'],
          '222 done',
        );
      });

      test('disabled actions are skipped', () async {
        final outcome = await _parity([
          _role(type, key: 'off', enabled: false),
          _role(type, key: 'on'),
        ]);
        expect(outcome.results, {'on': '222'});
      });

      for (final entry in {
        'missing ids': {'userId': '', 'roleId': ''},
        'invalid role': {'roleId': 'abc'},
      }.entries) {
        test('reports ${entry.key} as the same failure', () async {
          final outcome = await _parity([
            _role(type, key: 'bad', payload: entry.value),
          ]);
          expect(outcome.error, isA<Exception>());
          expect(
            outcome.error.toString(),
            'Exception: Missing or invalid userId/roleId',
          );
          expect(outcome.variables['error.message'], outcome.error.toString());
          expect(outcome.variables['error.command'], type.name);
        });
      }

      test('requires a guild', () async {
        final outcome = await _parity([_role(type)], guild: false);
        expect(
          outcome.error.toString(),
          'Exception: User action requires a guild context',
        );
      });

      test('reports a missing bot permission', () async {
        final outcome = await _parity([
          _role(type),
        ], setup: (g) => g.guild.permissions = 0);
        expect(outcome.error, isA<Exception>());
        expect(outcome.gateway.guild.memberManager.roleChanges, isEmpty);
      });

      test('reports a Discord refusal', () async {
        final outcome = await _parity([
          _role(type),
        ], setup: (g) => g.guild.memberManager.failRole = true);
        expect(outcome.error.toString(), contains('Discord refused role'));
      });

      test(
        'continue mode records the error and runs the next action',
        () async {
          final outcome = await _parity([
            _role(
              type,
              key: 'bad',
              error: {'mode': 'continue'},
              payload: {'roleId': ''},
            ),
            _role(type, key: 'good'),
          ]);
          expect(outcome.error, isNull);
          expect(outcome.results!['bad'], startsWith('Error: Exception: '));
          expect(outcome.results!['good'], '222');
        },
      );

      test('skip mode skips the following actions', () async {
        final outcome = await _parity([
          _role(
            type,
            key: 'bad',
            error: {'mode': 'skip', 'skipCount': '2'},
            payload: {'roleId': ''},
          ),
          _role(type, key: 'skipped1'),
          _role(type, key: 'skipped2', enabled: false),
          _role(type, key: 'last'),
        ]);
        expect(outcome.results!.keys, ['bad', 'last']);
      });

      test('skip mode with no count behaves like continue', () async {
        final outcome = await _parity([
          _role(
            type,
            key: 'bad',
            error: {'mode': 'skip'},
            payload: {'roleId': ''},
          ),
          _role(type, key: 'next'),
        ]);
        expect(outcome.results!.keys, ['bad', 'next']);
      });

      test('jump mode continues at the named later action', () async {
        final outcome = await _parity([
          _role(
            type,
            key: 'bad',
            error: {'mode': 'jump', 'jumpToActionId': 'target'},
            payload: {'roleId': ''},
          ),
          _role(type, key: 'skipped'),
          _role(type, key: 'target'),
        ]);
        expect(outcome.results!.keys, ['bad', 'target']);
      });

      test(
        'jump mode to an earlier or unknown action fails like stop',
        () async {
          for (final target in ['before', 'missing']) {
            final outcome = await _parity([
              _role(type, key: 'before'),
              _role(
                type,
                key: 'bad',
                error: {'mode': 'jump', 'jumpToActionId': target},
                payload: {'roleId': ''},
              ),
            ]);
            expect(outcome.error, isA<Exception>());
          }
        },
      );

      test('stop mode (default) ends the execution', () async {
        final outcome = await _parity([
          _role(type, key: 'bad', payload: {'roleId': ''}),
          _role(type, key: 'never'),
        ]);
        expect(outcome.error, isA<Exception>());
        expect(outcome.gateway.guild.memberManager.roleChanges, isEmpty);
      });

      test('protected executions ignore the error mode', () async {
        final outcome = await _parity([
          _role(type, error: {'mode': 'continue'}, payload: {'roleId': ''}),
        ], throwOnError: true);
        expect(outcome.error, isA<Exception>());
      });

      test(
        'the shared budget stops a delayed lookup before any effect',
        () async {
          final outcome = await _parity(
            [_role(type)],
            setup: (g) =>
                g.guild.memberManager.delay = const Duration(milliseconds: 80),
            limit: const Duration(milliseconds: 30),
            throwOnError: false,
          );
          expect(outcome.error, isA<CommandExecutionTimeout>());
          await Future<void>.delayed(const Duration(milliseconds: 120));
          expect(outcome.gateway.guild.memberManager.roleChanges, isEmpty);
        },
      );

      test('a policy that does not intercept still runs it natively', () async {
        final outcome = await _parity([
          _role(type, key: 'role'),
        ], policy: _NoHydration());
        expect(outcome.results, {'role': '222'});
      });

      test('role definitions run natively too', () async {
        final outcome = await _parity([
          Action(
            type: type,
            key: 'def',
            payload: {
              if (add) 'createNew': true else 'deleteRole': true,
              'roleId': '64',
              'name': 'Staff',
              'color': '#ff0000',
            },
          ),
        ]);
        expect(outcome.native, greaterThan(0));
      });
    });
  }

  group('addRole replacement parity', () {
    test('replaces roles with the historical default reason', () async {
      final outcome = await _parity([
        _role(
          BotCreatorActionType.addRole,
          key: 'set',
          payload: {
            'setRoles': ['64'],
          },
        ),
      ]);
      expect(outcome.results, {'set': '222'});
      expect(
        outcome.gateway.guild.memberManager.updates.single['reason'],
        'Set roles via BotCreator action',
      );
    });

    test('an empty list clears the roles', () async {
      final outcome = await _parity([
        _role(BotCreatorActionType.addRole, payload: {'setRoles': []}),
      ]);
      expect(
        outcome.gateway.guild.memberManager.updates.single['roles'],
        isEmpty,
      );
    });

    test('rejects a setRoles that is not a list', () async {
      final outcome = await _parity([
        _role(BotCreatorActionType.addRole, payload: {'setRoles': 'x'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: setRoles must be a list of role IDs',
      );
    });

    test('rejects an invalid role id', () async {
      final outcome = await _parity([
        _role(
          BotCreatorActionType.addRole,
          payload: {
            'setRoles': ['abc'],
          },
        ),
      ]);
      expect(outcome.error, isA<Exception>());
    });
  });

  group('ifBlock parity', () {
    Action ifBlock({
      String? key,
      Map<String, dynamic>? condition,
      List<Action> then = const [],
      List<Action> otherwise = const [],
      List<dynamic> elseIf = const [],
      Map<String, String> error = const {},
      Map<String, dynamic>? extra,
    }) => Action(
      type: BotCreatorActionType.ifBlock,
      key: key,
      payload: {
        ...(condition ?? _conditionOn('flag', 'yes')),
        'thenActions': then.map((a) => a.toJson()).toList(),
        'elseActions': otherwise.map((a) => a.toJson()).toList(),
        if (elseIf.isNotEmpty) 'elseIfConditions': elseIf,
        ...?extra,
      },
    )..error.addAll(error);

    Action add(
      String key, {
      Map<String, dynamic>? payload,
      Map<String, String> error = const {},
    }) => _role(
      BotCreatorActionType.addRole,
      key: key,
      payload: payload,
      error: error,
    );
    Action remove(String key) =>
        _role(BotCreatorActionType.removeRole, key: key);

    test(
      'runs the then branch and publishes its results under the block',
      () async {
        final outcome = await _parity(
          [
            ifBlock(
              key: 'gate',
              then: [add('a'), remove('b')],
              otherwise: [add('x')],
            ),
            add('after', payload: {'userId': '((gate.a))'}),
          ],
          variables: {'flag': 'yes'},
        );
        expect(outcome.results, {
          'gate': 'IF_TRUE',
          'gate.a': '222',
          'gate.b': '222',
          'after': '222',
        });
        expect(outcome.gateway.guild.memberManager.roleChanges.length, 3);
      },
    );

    test('runs the else branch', () async {
      final outcome = await _parity(
        [
          ifBlock(key: 'gate', then: [add('a')], otherwise: [remove('x')]),
        ],
        variables: {'flag': 'no'},
      );
      expect(outcome.results, {'gate': 'IF_FALSE', 'gate.x': '222'});
    });

    test('selects the matching else-if', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            then: [add('a')],
            elseIf: <dynamic>[
              {
                ..._conditionOn('flag', 'maybe'),
                'actions': [add('m').toJson()],
              },
              'not a map',
              {
                ..._conditionOn('flag', 'later'),
                'actions': [remove('l').toJson()],
              },
            ],
            otherwise: [add('x')],
          ),
        ],
        variables: {'flag': 'later'},
      );
      expect(outcome.results, {'gate': 'ELSE_IF_3', 'gate.l': '222'});
    });

    test('children read the results of their own list only', () async {
      final outcome = await _parity(
        [
          add('outer'),
          ifBlock(
            key: 'gate',
            then: [
              add('a'),
              add(
                'b',
                payload: {'userId': '((a))', 'reason': '((outer)) ((gate))'},
              ),
            ],
          ),
        ],
        variables: {'flag': 'yes'},
      );
      // ((outer)) and ((gate)) are not results of the branch: the template
      // resolver blanks them, so only the default reason remains.
      expect(
        outcome.gateway.guild.memberManager.roleChanges.last['reason'],
        'Add role via BotCreator action',
      );
    });

    test('empty branches only leave the label', () async {
      final outcome = await _parity(
        [ifBlock(key: 'gate')],
        variables: {'flag': 'yes'},
      );
      expect(outcome.results, {'gate': 'IF_TRUE'});
    });

    test('nested blocks publish results with their full path', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'outer',
            then: [
              add('first'),
              ifBlock(key: 'inner', then: [remove('leaf')]),
            ],
          ),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.results, {
        'outer': 'IF_TRUE',
        'outer.first': '222',
        'outer.inner': 'IF_TRUE',
        'outer.inner.leaf': '222',
      });
    });

    test('supports condition groups and negation', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            condition: {
              'condition.group': 'or',
              'condition.negate': true,
              'condition.conditions': [
                _conditionOn('a', '1'),
                _conditionOn('b', '2'),
              ],
            },
            then: [add('hit')],
            otherwise: [remove('miss')],
          ),
        ],
        variables: {'a': '0', 'b': '0'},
      );
      expect(outcome.results, {'gate': 'IF_TRUE', 'gate.hit': '222'});
    });

    test('disabled children keep their place but do not run', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            then: [
              _role(BotCreatorActionType.addRole, key: 'off', enabled: false),
              add('on'),
            ],
          ),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.results, {'gate': 'IF_TRUE', 'gate.on': '222'});
    });

    test('a failing child in continue mode keeps the branch going', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            then: [
              add('bad', payload: {'roleId': ''}, error: {'mode': 'continue'}),
              add('good'),
            ],
          ),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.results!['gate.bad'], startsWith('Error: Exception: '));
      expect(outcome.results!['gate.good'], '222');
    });

    test('skip and jump inside a branch count the branch actions', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            then: [
              add(
                'bad',
                payload: {'roleId': ''},
                error: {'mode': 'skip', 'skipCount': '1'},
              ),
              add('skipped'),
              add(
                'bad2',
                payload: {'roleId': ''},
                error: {'mode': 'jump', 'jumpToActionId': 'end'},
              ),
              add('skipped2'),
              add('end'),
            ],
          ),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.results!.keys, [
        'gate',
        'gate.bad',
        'gate.bad2',
        'gate.end',
      ]);
    });

    test('a failing child stops the block and the execution', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            then: [
              add('bad', payload: {'roleId': ''}),
              add('never'),
            ],
          ),
          add('after'),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.error, isA<Exception>());
      expect(outcome.variables['error.command'], 'ifBlock');
    });

    test('the block error mode continue discards the branch results', () async {
      final outcome = await _parity(
        [
          ifBlock(
            key: 'gate',
            error: {'mode': 'continue'},
            then: [
              add('ok'),
              add('bad', payload: {'roleId': ''}),
            ],
          ),
          add('after'),
        ],
        variables: {'flag': 'yes'},
      );
      expect(outcome.error, isNull);
      expect(outcome.results!.keys, ['gate', 'after']);
      expect(outcome.results!['gate'], startsWith('Error: Exception: '));
    });

    test(
      'a block with an unsupported child stays entirely historical',
      () async {
        final outcome = await _parity(
          [
            ifBlock(
              key: 'gate',
              then: [
                add('a'),
                Action(
                  type: BotCreatorActionType.setTemporaryVariable,
                  key: 'v',
                  payload: {'key': 'x', 'value': '1'},
                ),
              ],
            ),
          ],
          variables: {'flag': 'yes'},
          nativePrograms: 1, // only the supported child `a`
        );
        expect(outcome.results!['gate.a'], '222');
      },
    );

    test('tryCatch, suppressErrors and jump modes run natively', () async {
      // Wave 1: see visual_control_flow_parity_test.dart for the full parity.
      for (final block in [
        ifBlock(key: 'g', then: [add('a')], extra: {'tryCatch': true}),
        ifBlock(key: 'g', then: [add('a')], extra: {'suppressErrors': true}),
        ifBlock(
          key: 'g',
          then: [add('a')],
          error: {'mode': 'jump', 'jumpToActionId': 'z'},
        ),
      ]) {
        await _parity([block], variables: {'flag': 'yes'}, nativePrograms: 1);
      }
    });

    test(
      'a policy keeps blocks on the historical path (same outcome)',
      () async {
        final outcome = await _parity(
          [
            ifBlock(key: 'gate', then: [add('a')]),
          ],
          variables: {'flag': 'yes'},
          policy: _NoHydration(),
        );
        expect(outcome.results, {'gate': 'IF_TRUE', 'gate.a': '222'});
      },
    );
  });
}
