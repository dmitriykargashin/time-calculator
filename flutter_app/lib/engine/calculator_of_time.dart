import 'big_decimal.dart';
import 'expression_evaluator.dart';
import 'time_converter.dart';
import 'token.dart';
import 'token_type.dart';
import 'tokens.dart';

/// The calculation engine. Port of Kotlin `CalculatorOfTime`
/// (engine/calculator/CalculatorOfTime.kt).
abstract final class CalculatorOfTime {
  /// Evaluates a token expression. The result is always one of:
  /// * an empty [Tokens] (empty input),
  /// * `[NUMBER <milliseconds as a double string>, MSECOND]` on success -
  ///   the MSECOND tag is appended even for pure-number expressions and
  ///   carries the msec total as its value (so it reads "MSeconds" unless
  ///   the total is exactly 1),
  /// * `[ERROR "ERROR"]` on any failure (malformed input, division by zero).
  ///
  /// Time expressions are rewritten before evaluation: each maximal
  /// `NUMBER [unit] ...` run is parenthesized, each unit becomes
  /// `* <milliseconds-per-unit>` and each number gets a leading `+`, so
  /// `5 Hour - 10 Minute` evaluates `(+5*3600000)-(+10*60000)`.
  static Tokens evaluate(Tokens tokensToEvaluate) {
    final clonedTokensToEvaluate = tokensToEvaluate.clone();
    if (clonedTokensToEvaluate.isSimpleArithmeticExpression()) {
      return _evaluateSimpleArithmeticExpression(clonedTokensToEvaluate);
    }
    final tokensWithParentheses =
        _setParenthesesToExpression(clonedTokensToEvaluate);
    final tokensInMsecs =
        TimeConverter.convertExpressionToMsecs(tokensWithParentheses);
    return _evaluateSimpleArithmeticExpression(tokensInMsecs);
  }

  static Tokens _evaluateSimpleArithmeticExpression(Tokens tokensToEvaluate) {
    // If we have a trailing operator in the expression we need to delete it.
    if (tokensToEvaluate.isNotEmpty && tokensToEvaluate.last.type.isOperator) {
      tokensToEvaluate.removeLastToken();
    }
    // Repair a trailing "<operator> )" pair produced by the parenthesizer.
    if (tokensToEvaluate.length >= 2 &&
        tokensToEvaluate.last.type == TokenType.parenthesesRight &&
        tokensToEvaluate[tokensToEvaluate.length - 2].type.isOperator) {
      tokensToEvaluate.removeLastToken().removeLastToken();
    }

    final txt = tokensToEvaluate.toString();
    final resultTokens = Tokens();
    if (txt == '') return resultTokens;

    try {
      final result = ExpressionEvaluator.evaluate(txt);
      // Kotlin's Double.toBigDecimal() throws on Infinity/NaN inside the
      // same try block; mirror that so non-finite results become ERROR.
      if (!result.isFinite) {
        throw const FormatException('Non-finite result');
      }
      // Dart's double.toString() is used here where Kotlin used
      // Double.toBigDecimal().toString(); the string differs in shape
      // ("18600000.0" vs "1.86E+7") but is internal: every consumer parses
      // it with BigDecimal.parse and re-emits plain strings.
      final resultAsString = result.toString();
      // RemoveADS value plumbing: both the NUMBER and the MSECOND tag carry
      // the msec total, so the tag renders "MSeconds" unless the total is
      // exactly 1 (display-only; downstream matches by type).
      final resultValue = BigDecimal.parse(resultAsString);
      resultTokens.add(Token(TokenType.number, resultValue, resultAsString));
      resultTokens.add(Token(TokenType.mSecond, resultValue));
      return resultTokens;
    } catch (_) {
      resultTokens.add(Token(TokenType.error, BigDecimal.one, 'ERROR'));
      return resultTokens;
    }
  }

  static Tokens _setParenthesesToExpression(Tokens tokensToSetParentheses) {
    final tokensWithParentheses = Tokens();
    var isParenthesesBegins = false;
    for (final token in tokensToSetParentheses) {
      switch (token.type) {
        case TokenType.number:
          if (!isParenthesesBegins) {
            tokensWithParentheses
                .add(Token(TokenType.parenthesesLeft, BigDecimal.one));
            isParenthesesBegins = true;
          }
        case TokenType.multiply:
        case TokenType.divide:
        case TokenType.minus:
        case TokenType.plus:
          tokensWithParentheses
              .add(Token(TokenType.parenthesesRight, BigDecimal.one));
          isParenthesesBegins = false;
        default:
          break;
      }
      // Verbatim copy (keeps token.value; the explicit strRepresentation is
      // never re-pluralized - the branch grew an extra 's' here, see Token).
      tokensWithParentheses
          .add(Token(token.type, token.value, token.strRepresentation));
    }
    tokensWithParentheses
        .add(Token(TokenType.parenthesesRight, BigDecimal.one));
    return tokensWithParentheses;
  }
}
