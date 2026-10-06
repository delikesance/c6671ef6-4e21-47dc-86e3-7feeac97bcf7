import '../../services/time_operations.dart';
import '../../services/go_time_format.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdTimeFunctions() {
  BdfdNativeFunction field(String Function(DateTime) read) =>
      BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 0,
        handler: (call) => read(call.context.time.current),
      );
  final creationDate = BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async {
      final raw = await call.argument(0);
      DateTime instant;
      try {
        instant = discordSnowflakeCreation(raw);
      } on FormatException catch (error) {
        throw BdfdNativeError(error.message, call.location);
      }
      final layout = call.argumentCount == 2
          ? await call.argument(1)
          : '2006-01-02';
      return formatGoTime(
        call.context.time.inTimezone(instant),
        layout,
        checkBudget: call.context.budget.check,
      );
    },
  );
  return {
    'creationdate': creationDate,
    'userjoineddiscord': creationDate,
    'date': field(formatCalendarDate),
    'day': field((date) => '${date.day}'),
    'hour': field((date) => '${date.hour}'),
    'minute': field((date) => '${date.minute}'),
    'second': field((date) => '${date.second}'),
    'month': field((date) => englishMonthNames[date.month - 1]),
    'year': field((date) => '${date.year}'),
    'time': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final name = (await call.argument(0)).trim();
        if (name.isEmpty) {
          throw BdfdNativeError('Timezone is required.', call.location);
        }
        try {
          call.context.time.setTimezone(name);
        } on FormatException {
          throw BdfdNativeError(
            'Unknown TZ database timezone: $name.',
            call.location,
          );
        }
        return '';
      },
    ),
    'gettimestamp': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final unit = call.argumentCount == 0 ? 's' : await call.argument(0);
        if (!const ['s', 'ms', 'ns'].contains(unit)) {
          throw BdfdNativeError(
            'Timestamp unit must be s, ms or ns.',
            call.location,
          );
        }
        final instant = call.context.time.instant;
        return unixTimestamp(instant, unit);
      },
    ),
    'gettimestampms': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => unixTimestamp(call.context.time.instant, 'ms'),
    ),
  };
}
