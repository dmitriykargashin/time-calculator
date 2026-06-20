import 'big_decimal.dart';
import 'calculator_constants.dart';
import 'lexical_analyzer.dart';
import 'token.dart';
import 'token_type.dart';
import 'tokens.dart';

/// Conversions between token expressions and millisecond totals, plus the
/// display formatter. Port of Kotlin `TimeConverter` (utilites/TimeConverter.kt).
/// All arithmetic uses [BigDecimal] with the original's exact scale/rounding
/// rules (Kotlin's `/` operator = divide with HALF_EVEN at the receiver's
/// scale).
abstract final class TimeConverter {
  /// Greedy decomposition of a millisecond NUMBER token into
  /// Year > Month > Week > Day > Hour > Minute > Second > MSecond, skipping
  /// zero-valued units. (Dead code in the production pipeline of the
  /// original, but public and exercised by the historical calculate tests.)
  static Tokens convertExpressionInMsecsToNearest(Token token) {
    final convertedTokens = Tokens();
    final valueOfToken = BigDecimal.parse(token.strRepresentation);

    BigDecimal divDown(BigDecimal value, BigDecimal unitMs) =>
        value.divide(unitMs, RoundingMode.halfEven).setScale(
              0,
              RoundingMode.down,
            );

    final years = divDown(valueOfToken, millisecondsInYear);
    var consumed = years * millisecondsInYear;
    final months = divDown(valueOfToken - consumed, millisecondsInMonth);
    consumed += months * millisecondsInMonth;
    final weeks = divDown(valueOfToken - consumed, millisecondsInWeek);
    consumed += weeks * millisecondsInWeek;
    final days = divDown(valueOfToken - consumed, millisecondsInDay);
    consumed += days * millisecondsInDay;
    final hours = divDown(valueOfToken - consumed, millisecondsInHour);
    consumed += hours * millisecondsInHour;
    final minutes = divDown(valueOfToken - consumed, millisecondsInMinute);
    consumed += minutes * millisecondsInMinute;
    final seconds = divDown(valueOfToken - consumed, millisecondsInSecond);
    consumed += seconds * millisecondsInSecond;
    final mseconds =
        (valueOfToken - consumed).setScale(0, RoundingMode.down);

    void addUnit(BigDecimal value, TokenType type) {
      if (!value.isZero) {
        convertedTokens
            .add(Token(TokenType.number, value, value.toPlainString()));
        convertedTokens.add(Token(type, value));
      }
    }

    addUnit(years, TokenType.year);
    addUnit(months, TokenType.month);
    addUnit(weeks, TokenType.week);
    addUnit(days, TokenType.day);
    addUnit(hours, TokenType.hour);
    addUnit(minutes, TokenType.minute);
    addUnit(seconds, TokenType.second);
    addUnit(mseconds, TokenType.mSecond);
    return convertedTokens;
  }

  /// Rewrites a (parenthesized) token expression for evaluation: every time
  /// unit becomes `MULTIPLY NUMBER(<ms-per-unit>)`, every NUMBER becomes
  /// `PLUS NUMBER`, operators and parentheses are copied. MSECOND, ERROR and
  /// DOT tokens are silently dropped (bug parity with the original).
  static Tokens convertExpressionToMsecs(Tokens tokensToConvert) {
    final convertedTokens = Tokens();
    // `* <ms-per-unit>` pair; the constant NUMBER carries the constant as its
    // value (RemoveADS value plumbing).
    void addUnitAsMultiply(BigDecimal unitMs) {
      convertedTokens.add(Token(TokenType.multiply, BigDecimal.one));
      convertedTokens
          .add(Token(TokenType.number, unitMs, unitMs.toPlainString()));
    }

    for (final token in tokensToConvert) {
      switch (token.type) {
        case TokenType.second:
          addUnitAsMultiply(millisecondsInSecond);
        case TokenType.minute:
          addUnitAsMultiply(millisecondsInMinute);
        case TokenType.hour:
          addUnitAsMultiply(millisecondsInHour);
        case TokenType.day:
          addUnitAsMultiply(millisecondsInDay);
        case TokenType.week:
          addUnitAsMultiply(millisecondsInWeek);
        case TokenType.month:
          addUnitAsMultiply(millisecondsInMonth);
        case TokenType.year:
          addUnitAsMultiply(millisecondsInYear);
        case TokenType.number:
          convertedTokens.add(Token(TokenType.plus, BigDecimal.one));
          // Copied NUMBER carries its parsed string as value (the branch
          // used strRepresentation.toBigDecimal(); tryParse keeps a lone "."
          // or similar from throwing - the value is informational only).
          convertedTokens.add(Token(
            TokenType.number,
            BigDecimal.tryParse(token.strRepresentation) ?? BigDecimal.one,
            token.strRepresentation,
          ));
        case TokenType.multiply:
        case TokenType.divide:
        case TokenType.minus:
        case TokenType.plus:
        case TokenType.parenthesesRight:
        case TokenType.parenthesesLeft:
          convertedTokens.add(Token(token.type, BigDecimal.one));
        default:
          break; // MSECOND, ERROR, DOT: silently dropped.
      }
    }
    return convertedTokens;
  }

  /// Converts a millisecond NUMBER token into one target unit:
  /// `[NUMBER(msec / unitMs), Token(type)]`. The division is Kotlin's `/`:
  /// HALF_EVEN rounded to the SCALE OF THE INPUT STRING (so "32400000000.0"
  /// to YEAR yields "1.0"). MSECOND passes the value through unchanged. For
  /// non-unit types no NUMBER is emitted (a malformed 1-token list - bug
  /// parity) and the unit token carries value 0. Both emitted tokens carry
  /// the converted amount as their value, so the trailing unit pluralizes by
  /// it (1 Year -> MONTH yields "12 Months"; 12.5 Month -> YEAR yields value
  /// 1.0 -> singular "Year").
  static Tokens convertExpressionInMsecsToType(Token token, TokenType type) {
    final convertedTokens = Tokens();
    var tempValue = BigDecimal.zero;
    final unitMs = _millisecondsPerUnit(type);
    if (type == TokenType.mSecond) {
      tempValue = BigDecimal.parse(token.strRepresentation);
      convertedTokens
          .add(Token(TokenType.number, tempValue, tempValue.toPlainString()));
    } else if (unitMs != null) {
      tempValue = BigDecimal.parse(token.strRepresentation)
          .divide(unitMs, RoundingMode.halfEven);
      convertedTokens
          .add(Token(TokenType.number, tempValue, tempValue.toPlainString()));
    }
    convertedTokens.add(Token(type, tempValue));
    return convertedTokens;
  }

  /// Folds a token list into a single millisecond NUMBER token
  /// (`total.toPlainString()`). NUMBER sets the current value; each time
  /// keyword adds `current * unitMs`. NOTE: unlike the internal fold used by
  /// [convertTokensToTokensWithFormat], this has NO MSECOND branch
  /// ("5 MSecond" folds to 0) - bug parity with the original.
  static Token convertTokensToMScecToken(Tokens tokens) {
    var multipliedResult = BigDecimal.zero;
    var currentNumber = BigDecimal.zero;
    for (final token in tokens) {
      if (token.type == TokenType.number) {
        currentNumber = BigDecimal.parse(token.strRepresentation);
      } else {
        final unitMs = _millisecondsPerUnit(token.type);
        if (unitMs != null) {
          multipliedResult += currentNumber * unitMs;
        }
      }
    }
    return Token(
        TokenType.number, multipliedResult, multipliedResult.toPlainString());
  }

  /// THE display formatter: re-expresses the millisecond total of
  /// [tokensToConvert] in the ordered units of [tokensFormat]. Intermediate
  /// units are truncated toward zero, only the last unit keeps decimals
  /// (7 dp HALF_UP, trailing zeros stripped). With [removeZeroUnits] (the
  /// production default) zero-valued units are hidden - EXCEPT that a zero
  /// total now emits `[NUMBER "0", <last format unit>]` ("0 Minutes") instead
  /// of the master-era EMPTY list (RemoveADS zero-total fix, commit 994973d).
  /// ERROR/empty inputs fold to a 0 total and therefore also render as
  /// `"0 <Unit>s"` (branch parity: the error is masked as a legitimate zero).
  /// A NON-zero total whose last unit is 0 still omits that unit.
  static Tokens convertTokensToTokensWithFormat(
    Tokens tokensToConvert,
    Tokens tokensFormat, {
    bool removeZeroUnits = true,
  }) {
    final endResult = Tokens();
    var reminderInMsec = _convertTokensToMScec(tokensToConvert);
    // Computed ONCE, before the format loop (RemoveADS zero-total fix). The
    // intermediate branch state (commit a6470ba) emitted the zero
    // UNCONDITIONALLY, growing trailing "0 <unit>"s on non-zero results;
    // do NOT replicate that.
    final initialValueIsZero = reminderInMsec.isZero;
    for (var index = 0; index < tokensFormat.length; index++) {
      reminderInMsec = _addTimeUnitToResultAndGetReminder(
        reminderInMsec,
        tokensFormat[index].type,
        index == tokensFormat.length - 1,
        endResult,
        removeZeroUnits,
        initialValueIsZero,
      );
    }
    return endResult;
  }

  /// Milliseconds per unit, or null for non-unit (and MSECOND) types.
  static BigDecimal? _millisecondsPerUnit(TokenType type) {
    return switch (type) {
      TokenType.second => millisecondsInSecond,
      TokenType.minute => millisecondsInMinute,
      TokenType.hour => millisecondsInHour,
      TokenType.day => millisecondsInDay,
      TokenType.week => millisecondsInWeek,
      TokenType.month => millisecondsInMonth,
      TokenType.year => millisecondsInYear,
      _ => null,
    };
  }

  /// Converts milliseconds into the given unit via Kotlin `/` (HALF_EVEN at
  /// the receiver's scale). MSECOND passes through; unmatched types yield 0.
  static BigDecimal _convertMsecsToMSecsInType(
    BigDecimal mSecToConvert,
    TokenType type,
  ) {
    if (type == TokenType.mSecond) return mSecToConvert;
    final unitMs = _millisecondsPerUnit(type);
    if (unitMs == null) return BigDecimal.zero;
    return mSecToConvert.divide(unitMs, RoundingMode.halfEven);
  }

  /// Internal fold (this one DOES handle MSECOND, adding the raw number).
  /// A unit with no preceding NUMBER reuses the stale current number; a
  /// trailing NUMBER with no unit contributes nothing - bug parity.
  static BigDecimal _convertTokensToMScec(Tokens tokens) {
    var multipliedResult = BigDecimal.zero;
    var currentNumber = BigDecimal.zero;
    for (final token in tokens) {
      if (token.type == TokenType.number) {
        currentNumber = BigDecimal.parse(token.strRepresentation);
      } else if (token.type == TokenType.mSecond) {
        multipliedResult += currentNumber;
      } else {
        final unitMs = _millisecondsPerUnit(token.type);
        if (unitMs != null) {
          multipliedResult += currentNumber * unitMs;
        }
      }
    }
    return multipliedResult;
  }

  /// Fractional carry back to milliseconds. NOTE: no MSECOND branch (an
  /// MSECOND carry would be lost), like the original.
  static BigDecimal _convertPartOfUnitToMScec(
    BigDecimal partOfUnit,
    TokenType type,
  ) {
    final unitMs = _millisecondsPerUnit(type);
    if (unitMs == null) return BigDecimal.zero;
    return partOfUnit * unitMs;
  }

  static BigDecimal _addTimeUnitToResultAndGetReminder(
    BigDecimal reminderInMsec,
    TokenType type,
    bool isLast,
    Tokens endResult,
    bool removeZeroUnits,
    bool initialValueIsZero,
  ) {
    var reminderInMsecResult = BigDecimal.zero;
    final currentResult = _convertMsecsToMSecsInType(
      reminderInMsec.setScale(26, RoundingMode.halfUp),
      type,
    );

    if (isLast) {
      // If it's the last unit we should leave it decimal.
      if (!(currentResult.isZero && removeZeroUnits)) {
        // Branch quirk parity: the NUMBER's text is 7dp-rounded but both
        // values are the UNROUNDED currentResult, so e.g. 1.00000004 hours
        // displays "1 Hours" (text rounds to 1, plural from the raw value).
        endResult.add(Token(
          TokenType.number,
          currentResult,
          currentResult
              .setScale(7, RoundingMode.halfUp)
              .stripTrailingZeros()
              .toPlainString(),
        ));
        endResult.add(Token(type, currentResult));
      } else if (initialValueIsZero) {
        // RemoveADS zero-total fix: a 0-ms total emits "0 <Unit>s" for the
        // last format unit instead of an empty list. This supersedes the
        // master-era empty-conversion behavior (the Per-view guard in
        // PerUnitsRepository stays as a belt-and-braces fallback on top).
        endResult.add(Token(
          TokenType.number,
          BigDecimal.zero,
          BigDecimal.zero.toPlainString(),
        ));
        endResult.add(Token(type, BigDecimal.zero));
      }
    } else {
      final currentResultRounded =
          currentResult.setScale(0, RoundingMode.down);
      final reminderFromFullNumber = (currentResult - currentResultRounded)
          .setScale(26, RoundingMode.halfUp);

      // No zero-emission here: intermediate zero units are still skipped.
      if (!(currentResultRounded.isZero && removeZeroUnits)) {
        endResult.add(Token(
          TokenType.number,
          currentResultRounded,
          currentResultRounded.toPlainString(),
        ));
        endResult.add(Token(type, currentResultRounded));
      }

      reminderInMsecResult = reminderFromFullNumber.isZero
          ? BigDecimal.zero
          : _convertPartOfUnitToMScec(reminderFromFullNumber, type);
    }
    return reminderInMsecResult
        .setScale(7, RoundingMode.halfUp)
        .stripTrailingZeros();
  }
}

/// Port of the Kotlin test helper `String.toTokenInMSec()` (Extension.kt).
extension StringToTokenInMSec on String {
  /// Lexes this string and folds it into a single millisecond NUMBER token
  /// via [TimeConverter.convertTokensToMScecToken].
  Token toTokenInMSec() =>
      TimeConverter.convertTokensToMScecToken(LexicalAnalyzer.analyze(this));
}
