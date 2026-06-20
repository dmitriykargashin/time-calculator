import 'big_decimal.dart';
import 'token.dart';
import 'token_type.dart';
import 'tokens.dart';

/// Lexer for raw expression strings. Port of Kotlin `LexicalAnalyzer`
/// (engine/lexer/LexicalAnalyzer.kt, RemoveADS branch), without the
/// original's mutable static state (the Dart version is a pure function and
/// therefore reentrant).
///
/// Rules (faithful to the original, including its quirks):
/// * All ASCII spaces (U+0020 only) are stripped first.
/// * A digit starts a NUMBER matched by the regex `-?[\d.]+` from the current
///   position (the `-?` never matches; multiple dots like "1.2.3" lex as ONE
///   number with no validation).
/// * A letter starts a case-sensitive exact-prefix match against
///   Year, Month, Week, Day, Hour, Minute, Second, MSecond (in that order;
///   the conditions match the SINGULAR words only). The unit token inherits
///   its [Token.value] from the NUMBER token lexed immediately before it
///   (else 1), so "2 Hour" lexes to a HOUR token displayed as "Hours".
/// * Operators accept both the Unicode glyphs (+ − × ÷) and the ASCII aliases
///   (- / *), normalizing to the Unicode token values.
/// * Anything else (e.g. ".", "(", ",") yields an ERROR token.
/// * The cursor advances by the produced token's strRepresentation length
///   (an ERROR token advances 5 characters - "ERROR".length - swallowing up
///   to 4 valid characters after the bad one), EXCEPT for time units - see
///   [_consumedLength].
///
/// Deliberate divergences:
/// * Classification is ASCII-only where Kotlin's `Char.isDigit()`/`isLetter()`
///   were Unicode-aware. A Unicode digit (e.g. Arabic-Indic U+0665) crashed
///   the original; here it lexes as an ERROR token instead. Unreachable from
///   the keypad-driven UI either way - see docs/port-spec/lexer-tokens.md.
/// * The branch parsed NUMBER values with `toBigDecimal()` and THREW a
///   NumberFormatException at lex time on malformed matches like "1.2.3";
///   here `tryParse` falls back to 1 (see [_findCurrentDigitalToken]).
/// * The branch advanced the cursor by the PLURALIZED strRepresentation
///   length for unit tokens, over-running singular input text whose value is
///   not 1 (see [_consumedLength] for the fix and rationale).
abstract final class LexicalAnalyzer {
  static final RegExp _numberPattern = RegExp(r'-?[\d.]+');

  /// Tokenizes [stringExpression]. An empty input yields an empty [Tokens].
  static Tokens analyze(String stringExpression) {
    final expression = stringExpression.replaceAll(' ', '');
    final resultTokens = Tokens();
    var currentPosition = 0;
    while (currentPosition < expression.length) {
      final tmpToken =
          _findCurrentFullToken(expression, currentPosition, resultTokens);
      resultTokens.add(tmpToken);
      currentPosition += _consumedLength(expression, currentPosition, tmpToken);
    }
    return resultTokens;
  }

  /// How far the cursor advances for [token], matched at [position].
  ///
  /// Branch parity for everything but units: strRepresentation length (so
  /// ERROR still advances 5).
  ///
  /// DELIBERATE FIX vs the RemoveADS branch for time units: the branch
  /// advanced by the PLURALIZED length even when the matched input text was
  /// singular, so re-lexing singular text whose value is not 1 swallowed the
  /// next character ("2Hour+3Minute" lost the '+'; the seeded format preview
  /// "1 Year 2 Month 3 Day 4 Hour" lost the '3') and "1Hours" left a stray
  /// ERROR token. Here a unit consumes exactly what it matched - the
  /// singular keyword plus an optional trailing 's' - so plural output
  /// emitted by this code ("2Hours"), legacy singular text ("2Hour") and
  /// "1Hours" all re-lex losslessly.
  static int _consumedLength(String expression, int position, Token token) {
    if (token.type.isTimeKeyword) {
      final matchedLength = token.type.value.length;
      final next = position + matchedLength;
      final hasPluralS =
          next < expression.length && expression.codeUnitAt(next) == 0x73; // s
      return matchedLength + (hasPluralS ? 1 : 0);
    }
    return token.length();
  }

  static bool _isDigit(int codeUnit) => codeUnit >= 0x30 && codeUnit <= 0x39;

  static bool _isLetter(int codeUnit) =>
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A);

  static bool _isOperator(String character) =>
      character == TokenType.plus.value ||
      character == TokenType.minus.value ||
      character == TokenType.multiply.value ||
      character == TokenType.divide.value ||
      character == '-' ||
      character == '/' ||
      character == '*' ||
      character == '+';

  static Token _findCurrentFullToken(
    String expression,
    int currentPosition,
    Tokens currentTokens,
  ) {
    final codeUnit = expression.codeUnitAt(currentPosition);
    if (_isDigit(codeUnit)) {
      return _findCurrentDigitalToken(expression, currentPosition);
    }
    if (_isLetter(codeUnit)) {
      return _findCurrentLetterToken(expression, currentPosition, currentTokens);
    }
    if (_isOperator(expression[currentPosition])) {
      return _findCurrentOperatorToken(expression, currentPosition);
    }
    return Token(TokenType.error, BigDecimal.one);
  }

  static Token _findCurrentOperatorToken(
    String expression,
    int currentPosition,
  ) {
    final character = expression[currentPosition];
    if (character == TokenType.plus.value || character == '+') {
      return Token(TokenType.plus, BigDecimal.one);
    }
    if (character == TokenType.minus.value || character == '-') {
      return Token(TokenType.minus, BigDecimal.one);
    }
    if (character == TokenType.divide.value || character == '/') {
      return Token(TokenType.divide, BigDecimal.one);
    }
    if (character == TokenType.multiply.value || character == '*') {
      return Token(TokenType.multiply, BigDecimal.one);
    }
    return Token(TokenType.error, BigDecimal.one);
  }

  static Token _findCurrentLetterToken(
    String expression,
    int currentPosition,
    Tokens currentTokens,
  ) {
    // Value inheritance (RemoveADS smart plural): a unit token takes the
    // value of the NUMBER token lexed immediately before it, else 1.
    //
    // DELIBERATE FIX vs the branch: derive the value from the NUMBER's
    // CURRENT strRepresentation (fallback 1), not from its frozen `value`
    // field. (Within the lexer the two coincide; the same derivation is used
    // in ExpressionRepository.addToExpressionTimeUnit where they do NOT - the
    // branch froze the value at the first keypress, rendering "12 Hour"
    // singular.)
    var tokenValue = BigDecimal.one;
    if (currentTokens.isNotEmpty &&
        currentTokens.last.type == TokenType.number) {
      tokenValue = BigDecimal.tryParse(currentTokens.last.strRepresentation) ??
          BigDecimal.one;
    }
    const unitTypes = [
      TokenType.year,
      TokenType.month,
      TokenType.week,
      TokenType.day,
      TokenType.hour,
      TokenType.minute,
      TokenType.second,
      TokenType.mSecond,
    ];
    for (final type in unitTypes) {
      if (expression.startsWith(type.value, currentPosition)) {
        return Token(type, tokenValue);
      }
    }
    // Branch parity: the letter-branch ERROR fallback inherits the value
    // (harmless - ERROR never pluralizes).
    return Token(TokenType.error, tokenValue);
  }

  static Token _findCurrentDigitalToken(
    String expression,
    int currentPosition,
  ) {
    // The current character is a digit, so a prefix match always exists.
    final match = _numberPattern.matchAsPrefix(expression, currentPosition)!;
    final text = match.group(0)!;
    // DELIBERATE DEVIATION from the branch: Kotlin's `m.group().toBigDecimal()`
    // threw at lex time on malformed matches like "1.2.3" (the regex accepts
    // multiple dots). The NUMBER's value is informational only - unit tokens
    // re-parse strRepresentation (see _findCurrentLetterToken) - so tryParse
    // with a fallback of 1 keeps the lexer total and crash-free.
    return Token(TokenType.number, BigDecimal.tryParse(text) ?? BigDecimal.one,
        text);
  }
}

/// String conveniences mirroring the Kotlin extensions in Extension.kt.
extension StringTokenization on String {
  /// `LexicalAnalyzer.analyze(this)`.
  Tokens toTokens() => LexicalAnalyzer.analyze(this);

  /// Last token of the analyzed string. Throws [StateError] when the string
  /// lexes to no tokens. Note ".".toToken() yields an ERROR token (the lexer
  /// never emits DOT).
  Token toToken() => LexicalAnalyzer.analyze(this).last;
}
