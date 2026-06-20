/// Minimal arbitrary-precision decimal, reproducing the subset of
/// `java.math.BigDecimal` semantics the original Kotlin app relies on:
///
/// * a [BigInt] unscaled value plus an `int` scale (value = unscaled * 10^-scale),
/// * `setScale(n, mode)` with HALF_UP / HALF_EVEN / DOWN rounding,
/// * `divide(divisor, mode)` keeping the RECEIVER's scale (this is what
///   Kotlin's `BigDecimal / BigDecimal` operator does, with HALF_EVEN),
/// * `stripTrailingZeros()` (may produce a negative scale),
/// * `toPlainString()` (never scientific notation),
/// * scale-insensitive comparison (`compareTo`).
library;

/// Rounding modes used by the calculator (subset of java.math.RoundingMode).
enum RoundingMode {
  /// Truncate toward zero.
  down,

  /// Round to nearest neighbour; ties round away from zero.
  halfUp,

  /// Round to nearest neighbour; ties round to the even neighbour
  /// (banker's rounding). This is what Kotlin's `/` operator uses.
  halfEven,
}

/// Immutable decimal number with Java BigDecimal-compatible behaviour.
class BigDecimal implements Comparable<BigDecimal> {
  BigDecimal._(this.unscaledValue, this.scale);

  /// The number is `unscaledValue * 10^-scale`.
  final BigInt unscaledValue;

  /// May be negative after [stripTrailingZeros] (e.g. 1E+6).
  final int scale;

  static final BigDecimal zero = BigDecimal._(BigInt.zero, 0);
  static final BigDecimal one = BigDecimal._(BigInt.one, 0);

  static final BigInt _ten = BigInt.from(10);

  /// Creates a decimal with the given integer value and scale 0.
  factory BigDecimal.fromInt(int value) => BigDecimal._(BigInt.from(value), 0);

  static final RegExp _numberPattern =
      RegExp(r'^([+-]?)(\d*)(\.(\d*))?([eE]([+-]?\d+))?$');

  /// Parses a decimal string, accepting the same shapes Java's BigDecimal
  /// constructor does: optional sign, digits, optional fraction (a bare
  /// trailing dot like `5.` is valid), optional exponent (`1.86E+7`).
  /// Throws [FormatException] on invalid input.
  factory BigDecimal.parse(String source) {
    final result = tryParse(source);
    if (result == null) {
      throw FormatException('Invalid decimal number: "$source"');
    }
    return result;
  }

  /// Like [BigDecimal.parse] but returns null instead of throwing.
  static BigDecimal? tryParse(String source) {
    final match = _numberPattern.firstMatch(source);
    if (match == null) return null;
    final sign = match.group(1)!;
    final intPart = match.group(2)!;
    final fracPart = match.group(4) ?? '';
    if (intPart.isEmpty && fracPart.isEmpty) return null;
    final exponentText = match.group(6);
    final exponent = exponentText == null ? 0 : int.parse(exponentText);
    var unscaled = BigInt.parse('$intPart$fracPart');
    if (sign == '-') unscaled = -unscaled;
    return BigDecimal._(unscaled, fracPart.length - exponent);
  }

  /// True iff the value compares equal to zero (scale-insensitive).
  bool get isZero => unscaledValue == BigInt.zero;

  BigInt _unscaledAt(int targetScale) =>
      unscaledValue * _ten.pow(targetScale - scale);

  BigDecimal operator +(BigDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return BigDecimal._(_unscaledAt(s) + other._unscaledAt(s), s);
  }

  BigDecimal operator -(BigDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return BigDecimal._(_unscaledAt(s) - other._unscaledAt(s), s);
  }

  BigDecimal operator *(BigDecimal other) => BigDecimal._(
        unscaledValue * other.unscaledValue,
        scale + other.scale,
      );

  BigDecimal operator -() => BigDecimal._(-unscaledValue, scale);

  /// Java `BigDecimal.divide(divisor, roundingMode)`: the result keeps the
  /// RECEIVER's scale and is rounded to it with [roundingMode]. Kotlin's
  /// `a / b` operator is `a.divide(b, RoundingMode.HALF_EVEN)`.
  BigDecimal divide(BigDecimal divisor, RoundingMode roundingMode) {
    if (divisor.unscaledValue == BigInt.zero) {
      throw UnsupportedError('Division by zero');
    }
    // quotient unscaled (at this.scale) = u1 * 10^(divisor.scale) / u2.
    var numerator = unscaledValue;
    var denominator = divisor.unscaledValue;
    if (divisor.scale >= 0) {
      numerator *= _ten.pow(divisor.scale);
    } else {
      denominator *= _ten.pow(-divisor.scale);
    }
    if (denominator.isNegative) {
      numerator = -numerator;
      denominator = -denominator;
    }
    return BigDecimal._(
      _divideRound(numerator, denominator, roundingMode),
      scale,
    );
  }

  /// Java `BigDecimal.setScale(newScale, roundingMode)`.
  BigDecimal setScale(int newScale, RoundingMode roundingMode) {
    final diff = newScale - scale;
    if (diff == 0) return this;
    if (diff > 0) {
      return BigDecimal._(unscaledValue * _ten.pow(diff), newScale);
    }
    return BigDecimal._(
      _divideRound(unscaledValue, _ten.pow(-diff), roundingMode),
      newScale,
    );
  }

  /// Java `BigDecimal.stripTrailingZeros()`: removes trailing zeros from the
  /// unscaled value, decreasing the scale (possibly below zero). A zero value
  /// collapses to scale 0 (Java 8+ behaviour).
  BigDecimal stripTrailingZeros() {
    if (unscaledValue == BigInt.zero) return zero;
    var u = unscaledValue;
    var s = scale;
    while (u % _ten == BigInt.zero) {
      u = u ~/ _ten;
      s--;
    }
    return BigDecimal._(u, s);
  }

  /// Scale-insensitive value comparison (Java `compareTo`).
  @override
  int compareTo(BigDecimal other) {
    final s = scale > other.scale ? scale : other.scale;
    return _unscaledAt(s).compareTo(other._unscaledAt(s));
  }

  /// Java `BigDecimal.toPlainString()`: decimal notation, never scientific.
  String toPlainString() {
    final negative = unscaledValue.isNegative;
    final digits = unscaledValue.abs().toString();
    String body;
    if (scale <= 0) {
      if (unscaledValue == BigInt.zero) {
        body = '0';
      } else {
        body = digits + '0' * (-scale);
      }
    } else if (digits.length <= scale) {
      body = '0.${digits.padLeft(scale, '0')}';
    } else {
      final pointIndex = digits.length - scale;
      body = '${digits.substring(0, pointIndex)}.${digits.substring(pointIndex)}';
    }
    return negative ? '-$body' : body;
  }

  /// Unlike Java's `toString()` this never uses scientific notation; nothing
  /// in the port relies on Java's exponent form.
  @override
  String toString() => toPlainString();

  /// Rounds `numerator / denominator` (denominator > 0) to an integer.
  static BigInt _divideRound(
    BigInt numerator,
    BigInt denominator,
    RoundingMode mode,
  ) {
    final negative = numerator.isNegative;
    final absNumerator = numerator.abs();
    var quotient = absNumerator ~/ denominator;
    final remainder = absNumerator - quotient * denominator;
    if (remainder != BigInt.zero) {
      final halfComparison = (remainder << 1).compareTo(denominator);
      final roundUp = switch (mode) {
        RoundingMode.down => false,
        RoundingMode.halfUp => halfComparison >= 0,
        RoundingMode.halfEven =>
          halfComparison > 0 || (halfComparison == 0 && quotient.isOdd),
      };
      if (roundUp) quotient += BigInt.one;
    }
    return negative ? -quotient : quotient;
  }
}
