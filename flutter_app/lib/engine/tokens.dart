import 'dart:collection';

import 'token.dart';
import 'token_type.dart';

/// A mutable list of [Token]s. Port of Kotlin `Tokens : ArrayList<Token>`
/// (data/tokens/Tokens.kt). All standard [List] operations are available
/// (add, removeAt, last, indexing, iteration, ...).
class Tokens extends ListBase<Token> {
  final List<Token> _tokens = <Token>[];

  @override
  int get length => _tokens.length;

  @override
  set length(int newLength) => _tokens.length = newLength;

  @override
  Token operator [](int index) => _tokens[index];

  @override
  void operator []=(int index, Token value) => _tokens[index] = value;

  @override
  void add(Token element) => _tokens.add(element);

  @override
  void addAll(Iterable<Token> iterable) => _tokens.addAll(iterable);

  /// Deep copy: new [Token] objects sharing the (enum) types, values and
  /// strings.
  ///
  /// DELIBERATE FIX vs the RemoveADS branch: passing the existing (possibly
  /// already-pluralized) strRepresentation re-ran the Kotlin plural init and
  /// turned "Hours" into "Hourss" on every clone. The Dart [Token]
  /// constructor never re-pluralizes an explicit strRepresentation, so this
  /// copy is verbatim.
  Tokens clone() {
    final newTokens = Tokens();
    for (final token in this) {
      newTokens.add(Token(token.type, token.value, token.strRepresentation));
    }
    return newTokens;
  }

  /// Concatenation with NO separators, normalizing operators to ASCII:
  /// PLUS -> "+", MINUS -> "-", DIVIDE -> "/", MULTIPLY -> "*"; every other
  /// token contributes its strRepresentation verbatim. This is the exact
  /// string fed to the expression evaluator.
  @override
  String toString() {
    final buffer = StringBuffer();
    for (final token in this) {
      buffer.write(switch (token.type) {
        TokenType.plus => '+',
        TokenType.minus => '-',
        TokenType.divide => '/',
        TokenType.multiply => '*',
        _ => token.strRepresentation,
      });
    }
    return buffer.toString();
  }

  /// Same mapping as [toString] but each piece is prefixed with a single
  /// space, and the result is trimmed (used for format labels, e.g.
  /// "Hour Minute", "5 Hour - 10 Minute").
  String toStringWithSpaces() {
    final buffer = StringBuffer();
    for (final token in this) {
      buffer.write(switch (token.type) {
        TokenType.plus => ' +',
        TokenType.minus => ' -',
        TokenType.divide => ' /',
        TokenType.multiply => ' *',
        _ => ' ${token.strRepresentation}',
      });
    }
    return buffer.toString().trim();
  }

  /// False iff any token is one of the 8 time units (MSECOND, SECOND, HOUR,
  /// MINUTE, DAY, WEEK, MONTH, YEAR). ERROR/DOT/parentheses/operators/numbers
  /// all count as "simple"; an empty list is simple.
  bool isSimpleArithmeticExpression() {
    for (final token in this) {
      if (token.type.isTimeKeyword) return false;
    }
    return true;
  }

  /// Removes the last token in place and returns `this`. Throws a
  /// [RangeError] on an empty list (like the original's
  /// IndexOutOfBoundsException).
  Tokens removeLastToken() {
    removeAt(length - 1);
    return this;
  }

  /// The LAST operator token (+ − × ÷) in the list, or null if none.
  Token? findLastNearestOperatorToken() {
    for (var i = length - 1; i >= 0; i--) {
      if (this[i].type.isOperator) return this[i];
    }
    return null;
  }

  /// The token immediately before the last operator, or null when the
  /// operator is at index 0 or no operator exists.
  Token? findTokenBeforeLastNearestOperatorToken() {
    for (var i = length - 1; i >= 0; i--) {
      if (this[i].type.isOperator) {
        return i > 0 ? this[i - 1] : null;
      }
    }
    return null;
  }

  /// The token two positions before the last operator, or null when the
  /// operator index is <= 1 or no operator exists.
  Token? findTokenBeforeTokenBeforeLastNearestOperatorToken() {
    for (var i = length - 1; i >= 0; i--) {
      if (this[i].type.isOperator) {
        return i > 1 ? this[i - 2] : null;
      }
    }
    return null;
  }

  /// Scans backward to the nearest PLUS or MINUS (MULTIPLY/DIVIDE do NOT
  /// delimit blocks; the found operator's own index is included), then
  /// forward from there: true iff any token in that tail block is a time
  /// keyword. An empty list returns false.
  bool isLastExpressionBlockHasTimeKeyword() {
    var i = length - 1;
    while (i >= 0) {
      if (this[i].type == TokenType.plus || this[i].type == TokenType.minus) {
        break;
      }
      i--;
    }
    if (i < 0) i = 0;
    while (i <= length - 1) {
      if (this[i].type.isTimeKeyword) return true;
      i++;
    }
    return false;
  }
}
