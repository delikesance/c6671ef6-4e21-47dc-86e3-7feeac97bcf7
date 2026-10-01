/// Utility to parse BDFD duration strings (e.g. 10s, 1m, 1h, 1d, 1w, 1y).
Duration? parseBdfdDuration(String text) {
  final trimmed = text.trim().toLowerCase();
  if (trimmed.isEmpty) return null;

  if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(trimmed)) {
    final microseconds = double.parse(trimmed) * Duration.microsecondsPerSecond;
    if (!microseconds.isFinite || microseconds > 9223372036854775807) {
      return null;
    }
    return Duration(microseconds: microseconds.round());
  }
  const units = <String, int>{
    'ms': 1000,
    'millisecond': 1000,
    'milliseconds': 1000,
    's': 1000000,
    'sec': 1000000,
    'second': 1000000,
    'seconds': 1000000,
    'm': 60000000,
    'min': 60000000,
    'minute': 60000000,
    'minutes': 60000000,
    'h': 3600000000,
    'hour': 3600000000,
    'hours': 3600000000,
    'd': 86400000000,
    'day': 86400000000,
    'days': 86400000000,
    'w': 604800000000,
    'week': 604800000000,
    'weeks': 604800000000,
    'y': 31536000000000,
    'year': 31536000000000,
    'years': 31536000000000,
  };
  final parts = RegExp(r'(\d+(?:\.\d+)?)\s*([a-z]+)').allMatches(trimmed);
  var end = 0;
  var microseconds = 0;
  for (final part in parts) {
    if (trimmed.substring(end, part.start).trim().isNotEmpty) return null;
    final multiplier = units[part.group(2)];
    if (multiplier == null) return null;
    final amount = double.parse(part.group(1)!);
    final value = amount * multiplier;
    if (!value.isFinite || value > 9223372036854775807 - microseconds) {
      return null;
    }
    microseconds += value.round();
    end = part.end;
  }
  if (end == 0 || trimmed.substring(end).trim().isNotEmpty) return null;
  return Duration(microseconds: microseconds);
}

/// Formats a duration into a human-readable BDFD-style string.
String formatBdfdDuration(Duration duration) {
  if (duration.inDays >= 365) {
    final years = duration.inDays ~/ 365;
    return '$years Year${years > 1 ? 's' : ''}';
  }
  if (duration.inDays >= 7) {
    final weeks = duration.inDays ~/ 7;
    return '$weeks Week${weeks > 1 ? 's' : ''}';
  }
  if (duration.inDays >= 1) {
    final days = duration.inDays;
    return '$days Day${days > 1 ? 's' : ''}';
  }
  if (duration.inHours >= 1) {
    final hours = duration.inHours;
    return '$hours Hour${hours > 1 ? 's' : ''}';
  }
  if (duration.inMinutes >= 1) {
    final minutes = duration.inMinutes;
    return '$minutes Minute${minutes > 1 ? 's' : ''}';
  }
  final seconds = duration.inSeconds;
  return '$seconds Second${seconds > 1 ? 's' : ''}';
}
