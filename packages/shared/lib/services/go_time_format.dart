import 'time_operations.dart' show englishMonthNames;

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _tokens = [
  '-07:00:00',
  'Z07:00:00',
  'January',
  '-070000',
  'Z070000',
  'Monday',
  '-07:00',
  'Z07:00',
  '-0700',
  'Z0700',
  '2006',
  '__2',
  '002',
  'MST',
  'Jan',
  'Mon',
  '-07',
  'Z07',
  '_2',
  '06',
  '01',
  '02',
  '15',
  '03',
  '04',
  '05',
  'PM',
  '1',
  '2',
  '3',
  '4',
  '5',
];

/// Go reference-date layouts, with BDFD's documented case-insensitive names.
/// Unknown layout text stays literal. This does not parse formatted dates.
String formatGoTime(
  DateTime date,
  String layout, {
  void Function()? checkBudget,
}) {
  String pad(int value, [int width = 2, String fill = '0']) =>
      value.toString().padLeft(width, fill);
  final month = englishMonthNames[date.month - 1];
  final weekday = _weekdays[date.weekday - 1];
  final dayOfYear =
      DateTime.utc(
        date.year,
        date.month,
        date.day,
      ).difference(DateTime.utc(date.year, 1, 1)).inDays +
      1;
  final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
  String offset(String token) {
    final seconds = date.timeZoneOffset.inSeconds;
    if (token[0].toUpperCase() == 'Z' && seconds == 0) return 'Z';
    final absolute = seconds.abs();
    final hours = pad(absolute ~/ 3600);
    final minutes = pad((absolute ~/ 60) % 60);
    final rest = pad(absolute % 60);
    final sign = seconds < 0 ? '-' : '+';
    return sign +
        switch (token.length) {
          3 => hours,
          5 => '$hours$minutes',
          6 => '$hours:$minutes',
          7 => '$hours$minutes$rest',
          _ => '$hours:$minutes:$rest',
        };
  }

  String render(String token, String raw) => switch (token) {
    'January' => month,
    'Jan' => month.substring(0, 3),
    'Monday' => weekday,
    'Mon' => weekday.substring(0, 3),
    'MST' => date.timeZoneName,
    '2006' => pad(date.year, 4),
    '06' => pad(date.year % 100),
    '__2' => pad(dayOfYear, 3, ' '),
    '002' => pad(dayOfYear, 3),
    '01' => pad(date.month),
    '1' => '${date.month}',
    '02' => pad(date.day),
    '2' => '${date.day}',
    '_2' => pad(date.day, 2, ' '),
    '15' => pad(date.hour),
    '03' => pad(hour12),
    '3' => '$hour12',
    '04' => pad(date.minute),
    '4' => '${date.minute}',
    '05' => pad(date.second),
    '5' => '${date.second}',
    'PM' =>
      raw == 'pm'
          ? (date.hour < 12 ? 'am' : 'pm')
          : (date.hour < 12 ? 'AM' : 'PM'),
    _ => offset(token),
  };
  final output = StringBuffer();
  var index = 0;
  while (index < layout.length) {
    if ((index & 255) == 0) checkBudget?.call();
    // Go treats the underscore immediately before a long year as literal.
    if (layout.startsWith('_2006', index)) {
      output.write('_${pad(date.year, 4)}');
      index += 5;
      continue;
    }
    final char = layout[index];
    if ((char == '.' || char == ',') &&
        index + 1 < layout.length &&
        (layout[index + 1] == '0' || layout[index + 1] == '9')) {
      final digit = layout[index + 1];
      var end = index + 2;
      while (end < layout.length && layout[end] == digit) {
        if ((end & 255) == 0) checkBudget?.call();
        end++;
      }
      if (end == layout.length || !RegExp(r'[0-9]').hasMatch(layout[end])) {
        final width = end - index - 1;
        var fraction = pad(
          date.millisecond * 1000000 + date.microsecond * 1000,
          9,
        ).substring(0, width > 9 ? 9 : width);
        if (digit == '9') fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
        if (fraction.isNotEmpty) output.write('$char$fraction');
        index = end;
        continue;
      }
    }
    String? selected;
    for (final token in _tokens) {
      if (index + token.length > layout.length) continue;
      if (layout.substring(index, index + token.length).toLowerCase() !=
          token.toLowerCase()) {
        continue;
      }
      final end = index + token.length;
      if ((token == 'Jan' || token == 'Mon') &&
          end < layout.length &&
          RegExp(r'[a-z]').hasMatch(layout[end])) {
        continue;
      }
      selected = token;
      break;
    }
    if (selected == null) {
      output.write(char);
      index++;
    } else {
      output.write(
        render(selected, layout.substring(index, index + selected.length)),
      );
      index += selected.length;
    }
  }
  checkBudget?.call();
  return output.toString();
}

DateTime discordSnowflakeCreation(String raw) {
  final id = raw.trim();
  final value = RegExp(r'^[0-9]+$').hasMatch(id) ? BigInt.tryParse(id) : null;
  if (value == null ||
      value <= BigInt.zero ||
      value > (BigInt.one << 64) - BigInt.one) {
    throw const FormatException(
      'Expected a positive unsigned 64-bit Discord ID.',
    );
  }
  final milliseconds = (value >> 22) + BigInt.from(1420070400000);
  return DateTime.fromMillisecondsSinceEpoch(milliseconds.toInt(), isUtc: true);
}
