/// Replacement for the exp4j 0.4.8 library used by the original app.
///
/// Evaluates expression strings produced by `Tokens.toString()` - decimal
/// numbers, ASCII `+ - * /`, parentheses and unary plus/minus - in IEEE-754
/// double arithmetic exactly like exp4j: `*` and `/` bind tighter than
/// `+`/`-`, operators are left-associative, and division by zero throws
/// (exp4j throws `ArithmeticException("Division by zero!")`).
library;

/// Thrown for malformed expressions and division by zero. The calculator
/// catches every exception and maps it to an ERROR token.
class ExpressionEvaluationException implements Exception {
  ExpressionEvaluationException(this.message);

  final String message;

  @override
  String toString() => 'ExpressionEvaluationException: $message';
}

/// A tiny recursive-descent evaluator over doubles.
abstract final class ExpressionEvaluator {
  /// Evaluates [expression] and returns the result as a double.
  /// Throws [ExpressionEvaluationException] on malformed input or division
  /// by zero.
  static double evaluate(String expression) {
    final parser = _Parser(expression);
    final value = parser.parseExpression();
    parser.expectEnd();
    return value;
  }
}

class _Parser {
  _Parser(this.input);

  final String input;
  int _position = 0;

  /// Next non-space character, or null at end of input.
  String? _peek() {
    while (_position < input.length && input[_position] == ' ') {
      _position++;
    }
    return _position < input.length ? input[_position] : null;
  }

  void expectEnd() {
    final character = _peek();
    if (character != null) {
      throw ExpressionEvaluationException(
        'Unexpected character "$character" at position $_position',
      );
    }
  }

  double parseExpression() {
    var value = parseTerm();
    while (true) {
      final character = _peek();
      if (character == '+') {
        _position++;
        value += parseTerm();
      } else if (character == '-') {
        _position++;
        value -= parseTerm();
      } else {
        return value;
      }
    }
  }

  double parseTerm() {
    var value = parseUnary();
    while (true) {
      final character = _peek();
      if (character == '*') {
        _position++;
        value *= parseUnary();
      } else if (character == '/') {
        _position++;
        final divisor = parseUnary();
        if (divisor == 0) {
          // exp4j: ArithmeticException("Division by zero!").
          throw ExpressionEvaluationException('Division by zero!');
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double parseUnary() {
    final character = _peek();
    if (character == '+') {
      _position++;
      return parseUnary();
    }
    if (character == '-') {
      _position++;
      return -parseUnary();
    }
    return parsePrimary();
  }

  double parsePrimary() {
    final character = _peek();
    if (character == null) {
      throw ExpressionEvaluationException('Unexpected end of expression');
    }
    if (character == '(') {
      _position++;
      final value = parseExpression();
      if (_peek() != ')') {
        throw ExpressionEvaluationException('Expected ")"');
      }
      _position++;
      return value;
    }
    if (_isDigit(character) || character == '.') {
      return _parseNumber();
    }
    throw ExpressionEvaluationException(
      'Unexpected character "$character" at position $_position',
    );
  }

  double _parseNumber() {
    final start = _position;
    while (_position < input.length &&
        (_isDigit(input[_position]) || input[_position] == '.')) {
      _position++;
    }
    final text = input.substring(start, _position);
    // Java's Double.parseDouble (used by exp4j) accepts "5." and ".5";
    // Dart's double.parse does not accept a bare trailing dot, so normalize.
    var normalized = text;
    if (normalized.startsWith('.')) normalized = '0$normalized';
    if (normalized.endsWith('.')) normalized = '${normalized}0';
    final value = double.tryParse(normalized);
    if (value == null) {
      throw ExpressionEvaluationException('Invalid number "$text"');
    }
    return value;
  }

  static bool _isDigit(String character) {
    final codeUnit = character.codeUnitAt(0);
    return codeUnit >= 0x30 && codeUnit <= 0x39;
  }
}
