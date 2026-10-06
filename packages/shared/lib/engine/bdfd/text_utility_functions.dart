import '../../services/text_utility_operations.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdTextUtilityFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  void add(String name, int min, int max, BdfdFunctionHandler handler) {
    functions[name] = BdfdNativeFunction(
      minArguments: min,
      maxArguments: max,
      handler: handler,
    );
  }

  add(
    'bytecount',
    1,
    1,
    (call) async =>
        '${bdfdUtf8ByteCount(await call.argument(0), checkBudget: call.context.budget.check)}',
  );
  add('linescount', 1, 1, (call) async {
    final text = await call.argument(0);
    if (text.isEmpty) {
      throw BdfdNativeError('Text must not be empty.', call.location);
    }
    return '${bdfdLineCount(text, checkBudget: call.context.budget.check)}';
  });
  add('croptext', 3, 3, (call) async {
    final text = await call.argument(0);
    final maximum = bdfdDecimalInteger(await call.argument(1));
    final ending = await call.argument(2);
    if (maximum == null || maximum.isNegative) {
      throw BdfdNativeError(
        'Maximum characters must be a non-negative integer.',
        call.location,
      );
    }
    return bdfdCropText(
      text,
      maximum >= BigInt.from(text.length) ? text.length : maximum.toInt(),
      ending,
      checkBudget: call.context.budget.check,
    );
  });
  add('numberseparator', 1, 2, (call) async {
    final value = bdfdDecimalInteger(await call.argument(0));
    final separator = call.argumentCount > 1 ? await call.argument(1) : ',';
    if (value == null) {
      throw BdfdNativeError('Number must be an integer.', call.location);
    }
    return bdfdNumberSeparator(
      value,
      separator.isEmpty ? ',' : separator,
      checkBudget: call.context.budget.check,
    );
  });
  add(
    'isnumber',
    1,
    1,
    (call) async => '${bdfdIsNumber(await call.argument(0))}',
  );
  add(
    'isboolean',
    1,
    1,
    (call) async => '${bdfdBooleanWords.contains(await call.argument(0))}',
  );
  add(
    'isvalidhex',
    1,
    1,
    (call) async => '${bdfdIsValidHex(await call.argument(0))}',
  );
  add('sort', 4, 1 << 30, (call) async {
    final numbers = <({String text, int index})>[];
    for (var i = 0; i < call.argumentCount - 3; i++) {
      call.context.budget.check();
      final text = (await call.argument(i)).trim();
      final value = bdfdFiniteDecimal(text);
      if (value == null) {
        throw BdfdNativeError('Sort requires finite numbers.', call.location);
      }
      numbers.add((text: text, index: i));
    }
    final direction = (await call.argument(call.argumentCount - 3)).trim();
    final amount = bdfdDecimalInteger(
      await call.argument(call.argumentCount - 2),
    );
    final separator = await call.argument(call.argumentCount - 1);
    if (direction != 'asc' && direction != 'desc') {
      throw BdfdNativeError(
        'Sort direction must be asc or desc.',
        call.location,
      );
    }
    if (amount == null || amount < BigInt.from(-1) || separator.isEmpty) {
      throw BdfdNativeError(
        'Sort requires amount -1 or non-negative and a non-empty separator.',
        call.location,
      );
    }
    numbers.sort((a, b) {
      call.context.budget.check();
      final order =
          bdfdCompareDecimals(
            a.text,
            b.text,
            checkBudget: call.context.budget.check,
          ) *
          (direction == 'asc' ? 1 : -1);
      return order == 0 ? a.index.compareTo(b.index) : order;
    });
    final count =
        amount == BigInt.from(-1) || amount >= BigInt.from(numbers.length)
        ? numbers.length
        : amount.toInt();
    call.context.budget.check();
    return numbers.take(count).map((number) => number.text).join(separator);
  });
  return functions;
}
