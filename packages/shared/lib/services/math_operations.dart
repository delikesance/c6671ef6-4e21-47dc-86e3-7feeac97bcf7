/// Nearest integer with midpoint ties toward positive infinity, as Math.round.
num bdfdNearestInteger(num value) {
  if (value is int) return value;
  final lower = value.floorToDouble();
  return value - lower >= .5 ? lower + 1 : lower;
}

String bdfdNumberText(num value) {
  if (value == 0) return '0';
  if (value is int) return '$value';
  if (value == value.truncateToDouble()) return BigInt.from(value).toString();
  return '$value';
}

/// Decimal rounding with a finite-number input and arbitrary integer places.
/// Uses the supplied decimal text, avoiding overflowing intermediate powers.
String bdfdRoundDecimal(
  String input,
  BigInt places, {
  void Function()? checkBudget,
}) {
  checkBudget?.call();
  var value = input.trim();
  final negative = value.startsWith('-');
  if (value.startsWith('-') || value.startsWith('+')) {
    value = value.substring(1);
  }
  final exponentAt = value.toLowerCase().indexOf('e');
  final exponent = exponentAt < 0
      ? BigInt.zero
      : BigInt.parse(value.substring(exponentAt + 1));
  final mantissa = exponentAt < 0 ? value : value.substring(0, exponentAt);
  final dot = mantissa.indexOf('.');
  var scale = BigInt.from(dot < 0 ? 0 : mantissa.length - dot - 1) - exponent;
  var digits = mantissa.replaceAll('.', '').replaceFirst(RegExp(r'^0+'), '');
  if (digits.isEmpty) return '0';
  var coefficient = BigInt.parse(digits);
  final shift = scale - places;
  if (shift > BigInt.zero) {
    if (shift > BigInt.from(digits.length)) return '0';
    final divisor = BigInt.from(10).pow(shift.toInt());
    final remainder = coefficient.remainder(divisor);
    coefficient ~/= divisor;
    final comparison = (remainder * BigInt.two).compareTo(divisor);
    if (comparison > 0 || comparison == 0 && !negative) {
      coefficient += BigInt.one;
    }
    scale = places;
  }
  if (coefficient == BigInt.zero) return '0';
  digits = coefficient.toString();
  var end = digits.length;
  while (digits.codeUnitAt(end - 1) == 48) {
    if (end % 256 == 0) checkBudget?.call();
    end--;
  }
  scale -= BigInt.from(digits.length - end);
  digits = digits.substring(0, end);
  final sign = negative ? '-' : '';
  final exponentOut = BigInt.from(digits.length - 1) - scale;
  checkBudget?.call();
  // Scientific text avoids allocating arbitrarily many zeroes for huge places.
  if (exponentOut < BigInt.from(-6) || exponentOut > BigInt.from(20)) {
    return '$sign${digits[0]}${digits.length > 1 ? '.${digits.substring(1)}' : ''}e${exponentOut.isNegative ? '' : '+'}$exponentOut';
  }
  final point = digits.length - scale.toInt();
  if (point <= 0) return '${sign}0.${'0' * -point}$digits';
  if (point >= digits.length) {
    return '$sign$digits${'0' * (point - digits.length)}';
  }
  return '$sign${digits.substring(0, point)}.${digits.substring(point)}';
}
