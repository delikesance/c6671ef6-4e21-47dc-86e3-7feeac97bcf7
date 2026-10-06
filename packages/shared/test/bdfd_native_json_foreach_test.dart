import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/json_document.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

void main() {
  BdfdEngine engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');
  test(
    'native JSON foreach iterates object keys and typed values in order',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument({
        'a': 1,
        'b': true,
        'c': null,
        'd': {'x': 2},
      });
      expect(
        await engine().execute(
          r'$jsonForEach[]$jsonKey=$jsonValue:$jsonIndex;$endJsonForEach',
          context: context,
        ),
        'a=1:0;b=true:1;c=:2;d={"x":2}:3;',
      );
    },
  );
  test(
    'arrays expose zero-based keys and dynamic paths are evaluated once',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument({
        'items': ['a', 'b'],
      });
      context.temporaryVariables['path'] = 'items';
      expect(
        await engine().execute(
          r'$jsonForEach[$var[path]]$jsonKey/$jsonValue/$i;$var[path;changed]$endJsonForEach',
          context: context,
        ),
        '0/a/0;1/b/1;',
      );
    },
  );
  test('nested JSON loops restore outer bindings', () async {
    final context = BdfdContext();
    context.json = JsonDocument({
      'outer': {'one': 'x'},
      'inner': [1, 2],
    });
    expect(
      await engine().execute(
        r'$jsonForEach[outer]$jsonKey:$jsonValue($jsonForEach[inner]$jsonValue$endJsonForEach)$jsonKey:$jsonValue$endJsonForEach|$jsonKey|$jsonIndex',
        context: context,
      ),
      'one:x(12)one:x||',
    );
  });
  test(
    'JSON values are data and preserve unknown source without executing it',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument([
        r'$var[x;forbidden]',
        r'$unknown[$var[x;forbidden]]',
      ]);
      expect(
        await engine().execute(
          r'$jsonForEach[]$jsonValue$endJsonForEach',
          context: context,
        ),
        r'$var[x;forbidden]$unknown[$var[x;forbidden]]',
      );
      expect(context.temporaryVariables, isEmpty);
    },
  );
  test(
    'mutation changes the document while iteration keeps its initial snapshot',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument(['a', 'b']);
      expect(
        await engine().execute(
          r'$jsonForEach[]$jsonValue$jsonArrayAppend[;new]$endJsonForEach',
          context: context,
        ),
        'ab',
      );
      expect(context.json.value, ['a', 'b', 'new', 'new']);
    },
  );
  test('continue and break operate on the closest JSON loop', () async {
    final context = BdfdContext();
    context.json = JsonDocument([0, 1, 2, 3]);
    expect(
      await engine().execute(
        r'$jsonForEach[]$if[$jsonIndex==0]$continue$endif$jsonValue$if[$jsonIndex==2]$break$endif$endJsonForEach',
        context: context,
      ),
      '12',
    );
    expect(
      await engine().execute(r'$jsonKey|$jsonIndex', context: context),
      '|',
    );
  });
  test(
    'JSON loop preflight catches errors in empty collections before effects',
    () {
      expect(
        () =>
            engine().prepare(r'$jsonForEach[missing]$kick[20]$endJsonForEach'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        () => engine().prepare(r'$jsonForEach[]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        () => engine().prepare(r'$endJsonForEach'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        engine().prepare(r'$unknown[$jsonForEach[]]').source,
        r'$unknown[$jsonForEach[]]',
      );
    },
  );
  test('loop bindings are restored after a caught body error', () async {
    final context = BdfdContext();
    context.json = JsonDocument([1]);
    expect(
      await engine().execute(
        r'$try$jsonForEach[]$calculate[invalid]$endJsonForEach$catch$jsonKey|$jsonIndex$endTry',
        context: context,
      ),
      '|',
    );
  });
  test(
    'jsonValue reads a path outside loops while absent loops emit no body',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument({'a': 'value'});
      expect(
        await engine().execute(
          r'$jsonValue[a]$jsonForEach[a]forbidden$endJsonForEach$jsonForEach[missing]forbidden$endJsonForEach',
          context: context,
        ),
        'value',
      );
    },
  );
  test(
    'native foreach shares sandbox transport and propagates a guard stop',
    () async {
      final result = await testCommandInSandbox({
        'bdfdBackend': 'native-v1',
        'script':
            r'$jsonParse[{"a":1,"b":2}]$jsonForEach[]$sendMessage[$jsonKey]$onlyIf[$jsonIndex==0;Denied]$endJsonForEach$sendMessage[forbidden]',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['stopped'], true);
      expect(
        (result['responses'] as List).map((r) => r['payload']['content']),
        ['a', 'b', 'Denied'],
      );
      expect(
        (result['trace'] as List).any(
          (event) => event['type'] == 'bdfdJsonLoop',
        ),
        true,
      );
    },
  );
  test('native and legacy foreach agree for simple objects', () async {
    const source =
        r'$jsonParse[{"a":1,"b":true}]$jsonForEach[]$sendMessage[$jsonKey=$jsonValue]$endJsonForEach';
    final legacy = await testCommandInSandbox({'script': source});
    final native = await testCommandInSandbox({
      'script': source,
      'bdfdBackend': 'native-v1',
    });
    expect(legacy['success'], true, reason: '$legacy');
    expect(native['success'], true, reason: '$native');
    expect(
      (native['responses'] as List).map((r) => r['payload']['content']),
      (legacy['responses'] as List).map((r) => r['payload']['content']),
    );
  });
  test('foreach checks the shared step budget inside its body', () async {
    final context = BdfdContext(maxSteps: 10, budget: CommandExecutionBudget());
    context.json = JsonDocument(List.generate(100, (i) => i));
    await expectLater(
      engine().execute(
        r'$jsonForEach[]$jsonValue$endJsonForEach',
        context: context,
      ),
      throwsA(predicate((e) => '$e'.contains('Execution step limit exceeded'))),
    );
  });
  test(
    'jsonValue arguments remain unevaluated when the current iteration supplies its value',
    () async {
      final context = BdfdContext();
      context.json = JsonDocument(['value']);
      expect(
        await engine().execute(
          r'$jsonForEach[]$jsonValue[$var[x;forbidden]]$endJsonForEach',
          context: context,
        ),
        'value',
      );
      expect(context.temporaryVariables, isEmpty);
    },
  );
  test('mixed counted and JSON loops restore each outer index', () async {
    final context = BdfdContext();
    context.json = JsonDocument(['x', 'y']);
    expect(
      await engine().execute(
        r'$for[2]$i($jsonForEach[]$i:$jsonIndex;$endJsonForEach)$i;$endFor',
        context: context,
      ),
      '0(0:0;1:1;)0;1(0:0;1:1;)1;',
    );
  });
}
