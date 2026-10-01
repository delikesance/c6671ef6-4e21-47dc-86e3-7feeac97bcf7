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
