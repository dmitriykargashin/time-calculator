/// Token types of the time-expression language. Port of the Kotlin sealed
/// class `TokenType` (data/tokens/TokenType.kt); each enum value carries the
/// exact display string of the original, including the Unicode operator
/// glyphs (MINUS is U+2212, MULTIPLY U+00D7, DIVIDE U+00F7).
enum TokenType {
  plus('+'),
  minus('−'), // "−" Unicode MINUS SIGN, NOT ASCII hyphen.
  parenthesesLeft('('), // never produced by the lexer; engine-internal.
  parenthesesRight(')'), // never produced by the lexer; engine-internal.
  multiply('×'), // "×" MULTIPLICATION SIGN.
  divide('÷'), // "÷" DIVISION SIGN.
  number('0.0'), // placeholder; the real digits live in Token.strRepresentation.
  year('Year'),
  month('Month'),
  week('Week'),
  day('Day'),
  hour('Hour'),
  minute('Minute'),
  second('Second'),
  mSecond('MSecond'),
  error('ERROR'), // length 5 drives lexer cursor advancement on bad input.
  dot('.'); // never produced by the lexer; created only by the UI dot button.

  const TokenType(this.value);

  /// Canonical display string of this token type.
  final String value;

  /// True for exactly PLUS, MINUS, DIVIDE, MULTIPLY (parentheses are not
  /// operators).
  bool get isOperator =>
      this == plus || this == minus || this == divide || this == multiply;

  /// True for the 8 time units.
  bool get isTimeKeyword =>
      this == year ||
      this == week ||
      this == month ||
      this == day ||
      this == hour ||
      this == minute ||
      this == second ||
      this == mSecond;
}
