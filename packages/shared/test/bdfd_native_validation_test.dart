import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:test/test.dart';

void main() {
  test(
    'validation prepares the production registry without calling services',
    () {
      final validator = BdfdEngine.validation();
      const source =
          r'$setVar[x;1]$httpGet[https://example.test]$sendMessage[hello;yes]';
      expect(validator.prepare(source).source, source);
      expect(
        validator.supportedFunctions,
        containsAll(['sendmessage', 'httpget', 'setvar']),
      );
    },
  );
  test(
    'validation keeps opaque unknown arguments while rejecting known unsupported calls',
    () {
      final validator = BdfdEngine.validation();
      expect(
        validator.prepare(r'$unknown[$wait[1s]]').source,
        r'$unknown[$wait[1s]]',
      );
      final minimal = BdfdRuntime(functions: const {});
      expect(
        () => minimal.prepare(r'$wait[1s]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        () => validator.prepare(r'$wait[1;2]'),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'validation services prohibit execution even when a caller uses execute',
    () async {
      final validator = BdfdEngine.validation();
      await expectLater(
        validator.execute(r'$httpGet[https://example.test]'),
        throwsA(
          predicate((e) => '$e'.contains('Validation cannot access HTTP')),
        ),
      );
      await expectLater(
        validator.execute(r'$sendMessage[hello]'),
        throwsA(
          predicate((e) => '$e'.contains('Validation cannot send messages')),
        ),
      );
      await expectLater(
        validator.execute(r'$setVar[x;1]'),
        throwsA(
          predicate((e) => '$e'.contains('Validation cannot access storage')),
        ),
      );
    },
  );
}
