import 'dart:convert';
import 'dart:io';
import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/role_function_cases.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _CaptureEffects extends ActionExecutionPolicy {
  _CaptureEffects(this.gateway, {this.failRole = false});
  final EntityFixtureGateway gateway;
  final bool failRole;
  final events = <String>[];
  final roles = <Map<String, String>>[];
  final replies = <String>[];
  @override
  bool get allowDiscordHydration => true;
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
  }) async {
    if (action.type == BotCreatorActionType.deferInteraction) {
      expect(
        gateway.requests,
        isEmpty,
        reason: 'Acknowledge before entity lookup',
      );
      events.add('ack');
      results[resultKey] = 'deferred';
      return true;
    }
    if (action.type == BotCreatorActionType.addRole) {
      events.add('role');
      if (failRole) {
        throw StateError('Simulated missing Manage Roles permission');
      }
      roles.add({
        'role': resolveValue(action.payload['roleId']),
        'user': resolveValue(action.payload['userId']),
      });
      results[resultKey] = 'applied';
      return true;
    }
    if (action.type == BotCreatorActionType.respondWithMessage) {
      events.add('reply');
      replies.add(resolveValue(action.payload['content']));
      results[resultKey] = 'responded';
      return true;
    }
    return false;
  }
}

List<Action> _callbacks([String filename = 'scolor.fixed.json']) {
  final command = jsonDecode(
    File('../../tools/fixtures/$filename').readAsStringSync(),
  );
  final callbacks =
      command['data']['actions'][1]['payload']['components']['components'][0]['components'][0]['actions']
          as List;
  return callbacks
      .map((raw) => Action.fromJson(Map<String, dynamic>.from(raw)))
      .toList();
}

Future<Map<String, String>> _run(
  EntityFixtureGateway gateway,
  _CaptureEffects policy,
  String selection,
) {
  final variables = {
    'guild.id': '10',
    'author.id': '20',
    'interaction.select_colors.value': selection,
  };
  return handleActions(
    gateway,
    null,
    actions: _callbacks(),
    store: MemoryBotDataStore(),
    botId: 'test',
    variables: variables,
    resolveTemplate: (s) => resolveTemplatePlaceholders(s, variables),
    executionPolicy: policy,
  );
}

void main() {
  test(
    'original export continues after a failed role action as configured',
    () async {
      final gateway = EntityFixtureGateway(roleEntityFixture);
      final policy = _CaptureEffects(gateway, failRole: true);
      final variables = {
        'guild.id': '10',
        'author.id': '20',
        'interaction.select_colors.value': 'cor preta',
      };
      final result = await handleActions(
        gateway,
        null,
        actions: _callbacks('scolor.original.json'),
        store: MemoryBotDataStore(),
        botId: 'test',
        variables: variables,
        resolveTemplate: (s) => resolveTemplatePlaceholders(s, variables),
        executionPolicy: policy,
      );
      expect(policy.events, ['role', 'reply']);
      expect(policy.replies, ['nada']);
      expect(variables['error.command'], 'addRole');
      expect(
        result.values.any((value) => value.contains('Manage Roles')),
        true,
      );
    },
  );

  for (final color in [('cor branca', '60'), ('cor preta', '61')]) {
    test(
      'scolor resolves ${color.$1} dynamically and confirms after success',
      () async {
        final gateway = EntityFixtureGateway(roleEntityFixture);
        final policy = _CaptureEffects(gateway);
        await _run(gateway, policy, color.$1);
        expect(policy.events, ['ack', 'role', 'reply']);
        expect(policy.roles, [
          {'role': color.$2, 'user': '20'},
        ]);
        expect(policy.replies, ['Cor atualizada com sucesso.']);
      },
    );
  }
  test('scolor reports a missing role without granting anything', () async {
    final gateway = EntityFixtureGateway({
      'guilds': {
        '10': {'roles': []},
      },
    });
    final policy = _CaptureEffects(gateway);
    await _run(gateway, policy, 'cor branca');
    expect(policy.roles, isEmpty);
    expect(policy.events, ['ack', 'reply']);
    expect(policy.replies.single, contains('Cor Branca'));
  });
  test('scolor rejects an unknown menu value', () async {
    final gateway = EntityFixtureGateway(roleEntityFixture);
    final policy = _CaptureEffects(gateway);
    await _run(gateway, policy, 'administrator');
    expect(policy.roles, isEmpty);
    expect(policy.replies, ['Seleção de cor inválida.']);
  });
  test('scolor does not announce success when role assignment fails', () async {
    final gateway = EntityFixtureGateway(roleEntityFixture);
    final policy = _CaptureEffects(gateway, failRole: true);
    await expectLater(_run(gateway, policy, 'cor preta'), throwsStateError);
    expect(policy.replies, isEmpty);
    expect(policy.events, ['ack', 'role']);
  });
}
