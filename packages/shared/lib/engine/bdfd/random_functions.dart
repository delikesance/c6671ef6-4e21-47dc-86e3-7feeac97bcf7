import '../../utils/bdfd_ast.dart';
import '../../services/random_operations.dart';
import '../../services/math_operations.dart';
import '../../services/text_utility_operations.dart' show bdfdFiniteDecimal;
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdRandomFunctions() => {
  'random': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 2,
    allowedArgumentCounts: {0, 2},
    handler: (call) async {
      if (call.argumentCount == 0) {
        return call.context.decimalsEnabled
            ? bdfdNumberText(randomDecimal(call.context.random, 0, 10))
            : '${call.context.random.nextInt(10)}';
      }
      if (call.argumentCount != 2) {
        throw BdfdNativeError(
          'Random requires zero or two arguments.',
          call.location,
        );
      }
      final lower = bdfdFiniteDecimal(await call.argument(0));
      final upper = bdfdFiniteDecimal(await call.argument(1));
      if (lower == null ||
          upper == null ||
          !lower.isFinite ||
          !upper.isFinite ||
          upper <= lower) {
        throw BdfdNativeError(
          'Random requires increasing finite bounds.',
          call.location,
        );
      }
      if (!call.context.decimalsEnabled) {
        final minimum = lower is int
            ? BigInt.from(lower)
            : BigInt.from(lower.ceilToDouble());
        final maximum = upper is int
            ? BigInt.from(upper)
            : BigInt.from(upper.ceilToDouble());
        if (maximum <= minimum) {
          throw BdfdNativeError(
            'Random range contains no integer while decimals are disabled.',
            call.location,
          );
        }
        return randomBigInteger(
          call.context.random,
          minimum,
          maximum,
          call.context.budget,
        ).toString();
      }
      if (upper.toDouble() <= lower.toDouble()) {
        throw BdfdNativeError(
          'Random bounds are indistinguishable at decimal precision.',
          call.location,
        );
      }
      final value = randomDecimal(
        call.context.random,
        lower.toDouble(),
        upper.toDouble(),
      );
      return bdfdNumberText(value);
    },
  ),
  'randomtext': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1 << 30,
    handler: (call) async {
      final expands = call.node.arguments.any(
        (argument) => argument.any(
          (part) =>
              part is BdfdFunctionCallAst && part.normalizedName == 'unescape',
        ),
      );
      if (expands) {
        final options = await call.expandedArguments();
        return options[call.context.random.nextInt(options.length)];
      }
      return call.argument(call.context.random.nextInt(call.argumentCount));
    },
  ),
  'randomstring': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async {
      final length = int.tryParse((await call.argument(0)).trim());
      if (length == null || length < 1 || length > 10) {
        throw BdfdNativeError(
          'Random string length must be an integer from 1 to 10.',
          call.location,
        );
      }
      const alphabet =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      return String.fromCharCodes(
        List.generate(
          length,
          (_) =>
              alphabet.codeUnitAt(call.context.random.nextInt(alphabet.length)),
        ),
      );
    },
  ),
};
