import 'package:timezone/data/latest_all.dart' as data;
import 'package:timezone/timezone.dart' as tz;

bool _initialized = false;
late Map<String, tz.Location> _locations;
void _initialize() {
  if (_initialized) return;
  // The embedded loader uses global state. Keep our own immutable snapshot
  // and restore other consumers' database and local zone before returning.
  final previous = Map<String, tz.Location>.from(tz.timeZoneDatabase.locations);
  final local = previous.isEmpty ? tz.UTC : tz.local;
  try {
    data.initializeTimeZones();
    _locations = Map.unmodifiable(tz.timeZoneDatabase.locations);
  } finally {
    tz.timeZoneDatabase.clear();
    for (final location in previous.values) {
      tz.timeZoneDatabase.add(location);
    }
    tz.setLocalLocation(local);
  }
  _initialized = true;
}

class BdfdTimeState {
  BdfdTimeState({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  tz.Location? _location;
  String get timezone => _location?.name ?? 'UTC';
  DateTime get instant => _clock().toUtc();
  DateTime get current {
    return inTimezone(instant);
  }

  DateTime inTimezone(DateTime value) {
    final utc = value.toUtc();
    final location = _location;
    return location == null ? utc : tz.TZDateTime.from(utc, location);
  }

  void setTimezone(String name) {
    _initialize();
    // Resolve before replacing the old zone, including on a caught error.
    final location = _locations[name];
    if (location == null) {
      throw FormatException('Unknown TZ database timezone.', name);
    }
    _location = location;
  }
}

String unixTimestamp(DateTime instant, String unit) {
  final microseconds = BigInt.from(instant.microsecondsSinceEpoch);
  BigInt floorDivide(int divisor) {
    final scale = BigInt.from(divisor);
    final quotient = microseconds ~/ scale;
    return microseconds.isNegative &&
            microseconds.remainder(scale) != BigInt.zero
        ? quotient - BigInt.one
        : quotient;
  }

  return switch (unit) {
    's' => floorDivide(1000000).toString(),
    'ms' => floorDivide(1000).toString(),
    'ns' => (microseconds * BigInt.from(1000)).toString(),
    _ => throw ArgumentError('Timestamp unit must be s, ms or ns.'),
  };
}

String formatCalendarDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

const englishMonthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
