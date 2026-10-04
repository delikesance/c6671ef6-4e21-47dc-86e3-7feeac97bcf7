import 'dart:math';
import 'dart:typed_data';
import '../engine/execution_budget.dart';

/// Uniform integer choice in [minimum, maximum), including wide signed ranges.
BigInt randomInteger(
  Random random,
  int minimum,
  int maximum,
  CommandExecutionBudget budget,
) {
  return randomBigInteger(
    random,
    BigInt.from(minimum),
    BigInt.from(maximum),
    budget,
  );
}

BigInt randomBigInteger(
  Random random,
  BigInt minimum,
  BigInt maximum,
  CommandExecutionBudget budget,
) {
  budget.check();
  final lower = minimum;
  final width = maximum - lower;
  if (width <= BigInt.zero) throw ArgumentError('Maximum must exceed minimum.');
  if (width == BigInt.one) return lower;
  if (width <= BigInt.from(4294967296)) {
    return lower + BigInt.from(random.nextInt(width.toInt()));
  }
  final bits = (width - BigInt.one).bitLength;
  while (true) {
    budget.check();
    var value = BigInt.zero;
    var remaining = bits;
    while (remaining > 0) {
      budget.check();
      final chunk = min(remaining, 32);
      final bound = chunk == 32 ? 4294967296 : 1 << chunk;
      value = (value << chunk) | BigInt.from(random.nextInt(bound));
      remaining -= chunk;
    }
    if (value < width) return lower + value;
  }
}

/// The largest representable double below a finite value.
double _below(double value) {
  if (value == 0) return -double.minPositive;
  final bytes = ByteData(8)..setFloat64(0, value);
  var high = bytes.getUint32(0);
  var low = bytes.getUint32(4);
  if (value > 0) {
    if (low == 0) {
      high--;
      low = 0xffffffff;
    } else {
      low--;
    }
  } else {
    if (low == 0xffffffff) {
      high++;
      low = 0;
    } else {
      low++;
    }
  }
  bytes
    ..setUint32(0, high)
    ..setUint32(4, low);
  return bytes.getFloat64(0);
}

double randomDecimal(Random random, double minimum, double maximum) {
  if (!minimum.isFinite || !maximum.isFinite || maximum <= minimum) {
    throw ArgumentError('Expected increasing finite bounds.');
  }
  final fraction = random.nextDouble();
  final span = maximum - minimum;
  final value = span.isFinite
      ? minimum + fraction * span
      : (1 - fraction) * minimum + fraction * maximum;
  // Floating arithmetic can round to the excluded upper bound.
  return value >= maximum ? _below(maximum) : max(minimum, value);
}
