import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/variable_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/variable_service.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

MemoryBotDataStore store() => MemoryBotDataStore(
  scopedDefinitions: [
    {'scope': 'guildMember', 'key': 'bc_Money', 'defaultValue': 0},
    {'scope': 'guildMember', 'key': 'MONEY', 'defaultValue': 1},
    {'scope': 'guild', 'key': 'Title', 'defaultValue': ''},
    {'scope': 'channel', 'key': 'Theme', 'defaultValue': ''},
    {'scope': 'user', 'key': 'Bio', 'defaultValue': ''},
    {'scope': 'user', 'key': 'Score', 'defaultValue': 0},
  ],
  globalVariables: {'Global': 0, 'bc_money': 100},
);
BdfdRuntime runtime(MemoryBotDataStore store, {bool legacy = false}) =>
    BdfdRuntime(
      functions: bdfdVariableFunctions(
        VariableService(store, 'bot'),
        legacyUserVariables: legacy,
      ),
    );
void main() {
  test(
    'listVar lists declared names once across scopes and global catalogue',
    () async {
      expect(
        await runtime(store()).execute(r'$listVar'),
        'Money, Title, Theme, Bio, Score, Global',
      );
      expect(
        await runtime(store()).execute(r'$listVar[|]'),
        'Money|Title|Theme|Bio|Score|Global',
      );
      expect(
        await runtime(store()).execute(r'$listVar[]'),
        'MoneyTitleThemeBioScoreGlobal',
      );
    },
  );
  test(
    'counts map BDFD variable types to declarations rather than stored values',
    () async {
      expect(
        await runtime(store()).execute(
          r'$variablesCount[user]|$variablesCount[server]|$variablesCount[channel]|$variablesCount[globaluser]',
        ),
        '1|1|1|2',
      );
      expect(
        await runtime(store(), legacy: true).execute(r'$variablesCount[user]'),
        '2',
      );
      expect(
        await runtime(MemoryBotDataStore()).execute(r'$variablesCount[server]'),
        '0',
      );
    },
  );
  test('existing variable leaves error argument unevaluated', () async {
    final data = store();
    expect(
      await runtime(
        data,
      ).execute(r'$varExistError[Money;$setVar[Seen;yes]]Alive'),
      'Alive',
    );
    expect(data.globalVariables.containsKey('Seen'), false);
  });
  test(
    'missing variable stops execution and replaces draft without rollback',
    () async {
      final data = store();
      expect(
        await runtime(data).execute(
          r'$setVar[Before;yes]draft$varExistError[Missing;warning]after$setVar[After;yes]',
        ),
        'warning',
      );
      expect(data.globalVariables['Before'], 'yes');
      expect(data.globalVariables.containsKey('After'), false);
      expect(
        await runtime(data).execute(r'$varExistError[Missing;]hidden'),
        '',
      );
    },
  );
  test(
    'lists and errors stay literal and unknown calls remain opaque',
    () async {
      final data = MemoryBotDataStore(globalVariables: {r'$setVar[x;bad]': 1});
      expect(await runtime(data).execute(r'$listVar'), r'$setVar[x;bad]');
      expect(
        await runtime(
          data,
        ).execute(r'$unknown[$varExistError[Missing;$setVar[x;bad]]]'),
        r'$unknown[$varExistError[Missing;$setVar[x;bad]]]',
      );
      expect(data.globalVariables.containsKey('x'), false);
    },
  );
  test('invalid types and arities reject before an earlier write', () async {
    final data = store();
    expect(
      runtime(data).execute(r'$variablesCount[global]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(
      runtime(data).execute(r'$setVar[x;bad]$varExistError[Money]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(data.globalVariables.containsKey('x'), false);
  });
  test('catalogue service checks deadline before storage access', () async {
    final budget = CommandExecutionBudget(limit: Duration.zero);
    expect(
      VariableService(store(), 'bot').declaredNames(checkBudget: budget.check),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(
      VariableService(
        store(),
        'bot',
      ).exists('Money', checkBudget: budget.check),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test('catalogue counts normalize stored scope metadata', () async {
    final data = MemoryBotDataStore(
      scopedDefinitions: [
        {'scope': ' Guild ', 'key': 'bc_Title', 'defaultValue': ''},
      ],
    );
    expect(await runtime(data).execute(r'$variablesCount[server]'), '1');
  });
  test(
    'existence lookup checks cancellation while traversing declarations',
    () async {
      final data = store();
      var checks = 0;
      expect(
        VariableService(data, 'bot').exists(
          'Global',
          checkBudget: () {
            if (++checks == 4) throw StateError('cancelled');
          },
        ),
        throwsStateError,
      );
      expect(data.scopedVariables, isEmpty);
    },
  );
  test('production sandbox guard replaces pending catalogue response', () async {
    final result = await testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'definitions': [
        {'scope': 'guild', 'key': 'bc_Title', 'defaultValue': 'A'},
      ],
      'script':
          r'$listVar$variablesCount[server]$varExistError[Missing;Add it]after',
    });
    expect(result['success'], true, reason: '$result');
    expect(result['responses'].single['payload']['content'], 'Add it');
    expect(result['storage_after'], result['storage_before']);
  });
}
