import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:test/test.dart';

void main() {
  test('contracts reject missing fields and distinguish null from absent', () {
    final result = <String, dynamic>{
      'success': true,
      'responses': [],
      'value': null,
      'a/b': {
        '~key': [1, 2],
      },
    };
    expect(
      evaluateSandboxContract(
        result,
        expectedValues: {'/value': null},
      )['passed'],
      true,
    );
    expect(
      evaluateSandboxContract(
        result,
        expectedValues: {'/missing': null},
      )['passed'],
      false,
    );
    expect(
      evaluateSandboxContract(
        result,
        expectedValues: {
          '/a~1b/~0key': [1, 2],
        },
      )['passed'],
      true,
    );
    expect(
      evaluateSandboxContract(
        result,
        expectedValues: {'/a~1b/~0key/2': null},
      )['passed'],
      false,
    );
    expect(
      evaluateSandboxContract(
        result,
        expectedValues: {'/a~1b/~0key/0': 2},
      )['passed'],
      false,
    );
    expect(evaluateSandboxContract(result)['passed'], false);
  });
  test('contracts treat an integer embed color and its hex form as equal', () {
    final result = <String, dynamic>{
      'success': true,
      'color': '#5865F2',
      'n': 5793266,
    };
    bool passes(Map<String, dynamic> expected) =>
        evaluateSandboxContract(result, expectedValues: expected)['passed']
            as bool;
    expect(passes({'/color': 5793266}), true);
    expect(passes({'/n': '#5865f2'}), true);
    expect(passes({'/color': 5793267}), false);
    expect(passes({'/color': '#5865F2'}), true);
  });
  test(
    'contracts accept pointers without the leading slash and explain misses',
    () {
      final result = <String, dynamic>{
        'success': true,
        'responses': [
          {
            'payload': {
              'content': 'hi',
              'embeds': [
                {'description': 'ok'},
              ],
            },
          },
        ],
      };
      Map<String, dynamic> check(String path, Object? expected) =>
          (evaluateSandboxContract(
                    result,
                    expectedValues: {path: expected},
                  )['checks']
                  as List)
              .single;
      // Same pointer, with and without the slash.
      expect(
        check('responses/0/payload/embeds/0/description', 'ok')['passed'],
        true,
      );
      expect(
        check('/responses/0/payload/embeds/0/description', 'ok')['passed'],
        true,
      );
      expect(
        check('responses/0/payload/embeds/0/description', 'ok')['path'],
        startsWith('/'),
      );
      // The mistake seen in a real session: `embed` instead of `embeds/0`.
      final miss = check('/responses/0/payload/embed/description', 'ok');
      expect(miss['found'], false);
      expect(
        miss['hint'],
        allOf(contains("no 'embed'"), contains('available: content, embeds')),
      );
      expect(check('/responses/3/payload', 'x')['hint'], contains('length 1'));
      expect(
        check('/success/x', 'x')['hint'],
        contains('not an object or a list'),
      );
    },
  );
  test(
    'context.author sets the invoking user for every user function',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$authorID|$userID',
        'bdfdBackend': 'native-v1',
        'context': {
          'author': {'id': '333', 'username': 'Modo'},
        },
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '333|333');
    },
  );
  test(
    'catalog tracks all registered functions without claiming uncovered success',
    () {
      final catalog = sandboxFunctionCatalog();
      expect(catalog, hasLength(allBdfdFunctions.length));
      expect(
        sandboxFunctionCases
            .map((sample) => sample.function)
            .toSet()
            .difference(allBdfdFunctions),
        isEmpty,
      );
      expect(
        catalog.where((c) => c['covered'] == true),
        hasLength(
          sandboxFunctionCases.map((sample) => sample.function).toSet().length,
        ),
      );
    },
  );
  for (final sample in sandboxFunctionCases) {
    test('runtime contract: ${sample.function} ${sample.label}', () async {
      final result = await sample.run();
      expect(
        result['passed'],
        true,
        reason:
            '${result['error']} expected=${result['expected']} actual=${result['actual']} checks=${result['checks']}',
      );
    });
  }
}
