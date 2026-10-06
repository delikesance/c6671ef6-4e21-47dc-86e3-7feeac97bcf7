import 'package:bot_creator_shared/engine/bdfd/context_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:test/test.dart';

void main() {
  test('slash mode reads invocation flags and defaults false', () async {
    final engine = BdfdRuntime(functions: bdfdContextFunctions());
    expect(await engine.execute(r'$isSlash'), 'false');
    expect(
      await engine.execute(
        r'$isSlash',
        context: BdfdContext(variables: {'interaction.isSlash': 'true'}),
      ),
      'true',
    );
  });
  test('modal values remain data including empty and whitespace', () async {
    final engine = BdfdRuntime(functions: bdfdContextFunctions());
    expect(
      await engine.execute(
        r'$input[name]|$input[empty]',
        context: BdfdContext(
          variables: {
            'modal.name': r'  $sendMessage[hidden]  ',
            'modal.empty': '',
          },
        ),
      ),
      r'  $sendMessage[hidden]  |',
    );
  });
  test('missing input does not read slash options', () async {
    expect(
      BdfdRuntime(functions: bdfdContextFunctions()).execute(
        r'$input[name]',
        context: BdfdContext(variables: {'opts.name': 'wrong source'}),
      ),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'unknown outer calls keep input unevaluated and arities preflight',
    () async {
      final engine = BdfdRuntime(functions: bdfdContextFunctions());
      expect(
        await engine.execute(r'$unknown[$input[missing]]'),
        r'$unknown[$input[missing]]',
      );
      expect(
        () => BdfdEngine.validation().prepare(r'$isSlash[yes]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        () => BdfdEngine.validation().prepare(r'$input'),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
}
