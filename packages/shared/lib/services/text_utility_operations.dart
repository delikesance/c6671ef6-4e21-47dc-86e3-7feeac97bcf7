/// UTF-8 byte length, including replacement of unpaired UTF-16 surrogates.
int bdfdUtf8ByteCount(String text, {void Function()? checkBudget}) {
  var count = 0;
  for (var i = 0; i < text.length; i++) {
    if (i % 256 == 0) checkBudget?.call();
    final unit = text.codeUnitAt(i);
    if (unit < 0x80) {
      count++;
    } else if (unit < 0x800) {
      count += 2;
    } else if (unit >= 0xd800 &&
        unit <= 0xdbff &&
        i + 1 < text.length &&
        text.codeUnitAt(i + 1) >= 0xdc00 &&
        text.codeUnitAt(i + 1) <= 0xdfff) {
      count += 4;
      i++;
    } else {
      count += 3;
    }
  }
  checkBudget?.call();
  return count;
}

/// LF-delimited lines; a trailing LF starts another line.
int bdfdLineCount(String text, {void Function()? checkBudget}) {
  var count = 1;
  for (var i = 0; i < text.length; i++) {
    if (i % 256 == 0) checkBudget?.call();
    if (text.codeUnitAt(i) == 10) count++;
  }
  checkBudget?.call();
  return count;
}

/// Cropping counts Unicode scalar values, as in the wiki's emoji example.
String bdfdCropText(
  String text,
  int maximum,
  String ending, {
  void Function()? checkBudget,
}) {
  if (maximum < 0) throw ArgumentError.value(maximum, 'maximum');
  var offset = 0;
  var count = 0;
  while (offset < text.length && count < maximum) {
    if (count % 256 == 0) checkBudget?.call();
    final unit = text.codeUnitAt(offset++);
    if (unit >= 0xd800 &&
        unit <= 0xdbff &&
        offset < text.length &&
        text.codeUnitAt(offset) >= 0xdc00 &&
        text.codeUnitAt(offset) <= 0xdfff) {
      offset++;
    }
    count++;
  }
  checkBudget?.call();
  return offset < text.length ? text.substring(0, offset) + ending : text;
}

String bdfdNumberSeparator(
  BigInt value,
  String separator, {
  void Function()? checkBudget,
}) {
  final digits = value.abs().toString();
  final output = StringBuffer(value.isNegative ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i % 256 == 0) checkBudget?.call();
    if (i > 0 && (digits.length - i) % 3 == 0) output.write(separator);
    output.write(digits[i]);
  }
  checkBudget?.call();
  return output.toString();
}

const bdfdBooleanWords = {
  'true',
  'false',
  'yes',
  'no',
  'on',
  'off',
  'enable',
  'disable',
};

final _decimal = RegExp(
  r'^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$',
);
final _hex = RegExp(r'^#?[0-9a-fA-F]+$');
final _hexNumber = RegExp(r'^0[xX][0-9a-fA-F]+$');
final _binaryNumber = RegExp(r'^0[bB][01]+$');
final _octalNumber = RegExp(r'^0[oO][0-7]+$');

/// Matches the official playground's parseFloat plus finite-number check.
bool bdfdIsNumber(String text) {
  final value = text.trim();
  if (_decimal.hasMatch(value)) {
    return double.tryParse(value)?.isFinite ?? false;
  }
  var radix = 0;
  if (_hexNumber.hasMatch(value)) radix = 16;
  if (_binaryNumber.hasMatch(value)) radix = 2;
  if (_octalNumber.hasMatch(value)) radix = 8;
  return radix != 0 &&
      BigInt.parse(value.substring(2), radix: radix).toDouble().isFinite;
}

bool bdfdIsValidHex(String text) => _hex.hasMatch(text);

/// Strict decimal integer, without Dart's accepted hexadecimal extension.
BigInt? bdfdDecimalInteger(String text) {
  final value = text.trim();
  if (!RegExp(r'^[+-]?[0-9]+$').hasMatch(value)) return null;
  return BigInt.tryParse(value);
}

num? bdfdFiniteDecimal(String text) {
  final value = text.trim();
  if (!_decimal.hasMatch(value)) return null;
  final number = num.tryParse(value);
  return number != null && number.isFinite ? number : null;
}

/// Exact decimal comparison without rounding large integer or fractional inputs.
/// Inputs must already satisfy [bdfdFiniteDecimal].
int bdfdCompareDecimals(
  String left,
  String right, {
  void Function()? checkBudget,
}) {
  ({int sign, String digits, BigInt magnitude}) parts(String text) {
    var value = text.trim();
    final sign = value.startsWith('-') ? -1 : 1;
    if (value.startsWith('-') || value.startsWith('+')) {
      value = value.substring(1);
    }
    final exponentAt = value.toLowerCase().indexOf('e');
    final exponent = exponentAt < 0
        ? BigInt.zero
        : BigInt.parse(value.substring(exponentAt + 1));
    final mantissa = exponentAt < 0 ? value : value.substring(0, exponentAt);
    final dot = mantissa.indexOf('.');
    final fractionLength = dot < 0 ? 0 : mantissa.length - dot - 1;
    final digits = mantissa
        .replaceAll('.', '')
        .replaceFirst(RegExp(r'^0+'), '');
    return (
      sign: digits.isEmpty ? 0 : sign,
      digits: digits,
      magnitude: exponent + BigInt.from(digits.length - fractionLength),
    );
  }

  checkBudget?.call();
  final a = parts(left);
  final b = parts(right);
  if (a.sign != b.sign) return a.sign.compareTo(b.sign);
  if (a.sign == 0) return 0;
  final magnitude = a.magnitude.compareTo(b.magnitude);
  if (magnitude != 0) return magnitude * a.sign;
  final count = a.digits.length > b.digits.length
      ? a.digits.length
      : b.digits.length;
  for (var i = 0; i < count; i++) {
    if (i % 256 == 0) checkBudget?.call();
    final x = i < a.digits.length ? a.digits.codeUnitAt(i) : 48;
    final y = i < b.digits.length ? b.digits.codeUnitAt(i) : 48;
    if (x != y) return x.compareTo(y) * a.sign;
  }
  return 0;
}
