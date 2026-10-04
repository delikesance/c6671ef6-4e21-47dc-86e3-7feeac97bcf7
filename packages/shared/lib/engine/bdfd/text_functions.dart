import '../../services/text_operations.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdTextFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  void add(String name, int min, int max, BdfdFunctionHandler handler) {
    functions[name] = BdfdNativeFunction(
      minArguments: min,
      maxArguments: max,
      handler: handler,
    );
  }

  Future<int> integer(BdfdInvocation call, int index) async {
    final value = int.tryParse((await call.argument(index)).trim());
    if (value == null) {
      throw BdfdNativeError(
        'Expected an integer in argument ${index + 1}.',
        call.location,
      );
    }
    return value;
  }

  add('replacetext', 3, 4, (call) async {
    final text = await call.argument(0);
    final sample = await call.argument(1);
    final replacement = await call.argument(2);
    final amount = call.argumentCount > 3 ? await integer(call, 3) : 1;
    if (amount < -1) {
      throw BdfdNativeError(
        'Replacement amount must be -1 or non-negative.',
        call.location,
      );
    }
    return replaceTextOccurrences(text, sample, replacement, amount: amount);
  });
  add('textsplit', 2, 2, (call) async {
    final text = await call.argument(0);
    final separator = await call.argument(1);
    call.context.textSplit.split(text, separator);
    return '';
  });
  add('splittext', 1, 1, (call) async {
    final selector = (await call.argument(0)).trim();
    if (selector != '<' && selector != '>' && int.tryParse(selector) == null) {
      throw BdfdNativeError(
        'Split index must be an integer, < or >.',
        call.location,
      );
    }
    return call.context.textSplit.at(selector);
  });
  add('gettextsplitlength', 0, 0, (call) => '${call.context.textSplit.length}');
  add(
    'gettextsplitindex',
    1,
    1,
    (call) async => '${call.context.textSplit.indexOf(await call.argument(0))}',
  );
  add(
    'joinsplittext',
    1,
    1,
    (call) async => call.context.textSplit.join(await call.argument(0)),
  );
  add('editsplittext', 2, 2, (call) async {
    final index = await integer(call, 0);
    final value = await call.argument(1);
    if (!call.context.textSplit.edit(index, value)) {
      throw BdfdNativeError('Split index out of range.', call.location);
    }
    return '';
  });
  add('removesplittextelement', 1, 1, (call) async {
    if (!call.context.textSplit.remove(await integer(call, 0))) {
      throw BdfdNativeError('Split index out of range.', call.location);
    }
    return '';
  });
  add('checkcontains', 2, 100, (call) async {
    final text = await call.argument(0);
    // All supplied phrases are ordinary eager function arguments. Only control
    // flow functions grant lazy evaluation to alternative code branches.
    final phrases = <String>[];
    for (var i = 1; i < call.argumentCount; i++) {
      phrases.add(await call.argument(i));
    }
    return '${phrases.any(text.contains)}';
  });
  add('repeatmessage', 2, 2, (call) async {
    final amount = await integer(call, 0);
    if (amount < 0 || amount > 10) {
      throw BdfdNativeError(
        'Repeat amount must be between 0 and 10.',
        call.location,
      );
    }
    return (await call.argument(1)) * amount;
  });
  add('trimcontent', 1, 1, (call) async => (await call.argument(0)).trim());
  add(
    'totitlecase',
    1,
    1,
    (call) async => (await call.argument(0))
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? ''
              : word[0].toUpperCase() + word.substring(1).toLowerCase(),
        )
        .join(' '),
  );
  return functions;
}
