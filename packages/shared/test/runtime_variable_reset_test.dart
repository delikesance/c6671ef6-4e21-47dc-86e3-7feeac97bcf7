import 'dart:convert';
import 'package:bot_creator_shared/engine/bdfd/visual/variable_logic.dart';
import 'package:bot_creator_shared/sandbox/sandbox_store.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

Future<void> remove(
  SandboxStore store,
  Map<String, String> vars, {
  bool reset = true,
  String contextId = '20',
}) => executeVariableAction(
  type: BotCreatorActionType.removeScopedVariable,
  store: store,
  botId: 'bot',
  payload: {
    'scope': 'user',
    'key': 'score',
    'contextId': contextId,
    if (reset) 'resetToDefault': true,
  },
  resultKey: 'reset',
  results: {},
  variables: vars,
  resolveValue: (input) => resolveTemplatePlaceholders(input, vars),
  guildId: null,
  fallbackChannelId: null,
  interaction: null,
).then((_) {});

void main() {
  for (final value in <dynamic>[
    0,
    false,
    '',
    ['a', 'b'],
    {'value': 1},
    null,
  ]) {
    test(
      'reset restores typed default ${jsonEncode(value)} without changing its definition',
      () async {
        final store = SandboxStore(
          scopedDefinitions: [
            {'scope': 'user', 'key': 'score', 'defaultValue': value},
          ],
          scopedVariables: {
            'user': {
              '20': {'score': 9, 'bc_score': 8},
              '21': {'score': 80},
            },
          },
        );
        final vars = {
          'author.id': '20',
          'user.bc_score': '9',
          'user.score': '9',
          'user[20].bc_score': '9',
        };
        await remove(store, vars);
        expect(store.scopedVariables['user']!['20'], {'score': value});
        expect(store.scopedVariables['user']!['21'], {'score': 80});
        expect(store.scopedDefinitions.single['defaultValue'], value);
        final text = value == null
            ? ''
            : value is List || value is Map
            ? jsonEncode(value)
            : value.toString();
        expect(resolveTemplatePlaceholders('((user.bc_score))', vars), text);
        expect(
          resolveTemplatePlaceholders('((user[20].bc_score))', vars),
          text,
        );
      },
    );
  }
  test(
    'ordinary remove remains a deletion even when a default exists',
    () async {
      final store = SandboxStore(
        scopedDefinitions: [
          {'scope': 'user', 'key': 'score', 'defaultValue': 7},
        ],
        scopedVariables: {
          'user': {
            '20': {'score': 9},
          },
        },
      );
      final vars = {
        'author.id': '20',
        'user.bc_score': '9',
        'user[20].bc_score': '9',
      };
      await remove(store, vars, reset: false);
      expect(store.scopedVariables['user']!['20'], isEmpty);
      expect(
        resolveTemplatePlaceholders(
          '((user.bc_score))|((user[20].bc_score))',
          vars,
        ),
        '|',
      );
      expect(
        resolveTemplatePlaceholders('((variablesCount[user]))', vars),
        '0',
      );
    },
  );
  test('removing a foreign target clears only that target cache', () async {
    final store = SandboxStore(
      scopedVariables: {
        'user': {
          '20': {'score': 9},
          '21': {'score': 80},
        },
      },
    );
    final vars = {
      'author.id': '20',
      'user.bc_score': '9',
      'user[20].bc_score': '9',
      'user[21].bc_score': '80',
    };
    await remove(store, vars, contextId: '21');
    expect(store.scopedVariables['user']!['20'], {'score': 9});
    expect(store.scopedVariables['user']!['21'], isEmpty);
    expect(
      resolveTemplatePlaceholders(
        '((user[21].bc_score))|((user.bc_score))',
        vars,
      ),
      '|9',
    );
  });
}
