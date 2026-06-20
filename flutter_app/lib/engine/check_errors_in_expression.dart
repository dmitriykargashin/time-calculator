import 'token.dart';
import 'token_type.dart';
import 'tokens.dart';

/// Validates whether [expressionForAdd] may be appended to [expression].
/// Returns true = ERROR (reject the token), false = legal. Port of
/// CheckErrorsInExpression.kt; rules are evaluated in this exact order:
///
/// * R0: empty expression + NUMBER -> legal.
/// * R1: empty expression + (time keyword | operator | DOT) -> error.
///   (Any other type on an empty expression throws, like the original.)
/// * R2: NUMBER + (PLUS|MINUS) when the last block has no time unit -> error
///   (only +/- are blocked; MULTIPLY/DIVIDE after a bare number are legal).
/// * R3: operator + operator -> error.
/// * R4: operator + DOT -> error.
/// * R5: operator + time keyword -> error.
/// * R6: time keyword + time keyword -> error.
/// * R7: size > 1, last block has a time keyword, the second-to-last token is
///   MULTIPLY|DIVIDE, and a time keyword is added -> error (blocks
///   "2 Hour * 3 Minute").
/// * Otherwise legal.
bool isErrorsInExpression(Token expressionForAdd, Tokens expression) {
  if (expression.isEmpty && expressionForAdd.type == TokenType.number) {
    return false;
  }

  if (expression.isEmpty &&
      (expressionForAdd.type.isTimeKeyword ||
          expressionForAdd.type.isOperator ||
          expressionForAdd.type == TokenType.dot)) {
    return true;
  }

  final lastTokenInExpression = expression.last;
  final isLastExpressionBlockHasTimeKeyword =
      expression.isLastExpressionBlockHasTimeKeyword();

  // Check for add operator after number without time unit.
  if (lastTokenInExpression.type == TokenType.number &&
      (expressionForAdd.type == TokenType.plus ||
          expressionForAdd.type == TokenType.minus) &&
      !isLastExpressionBlockHasTimeKeyword) {
    return true;
  }

  // Check for double operators.
  if (lastTokenInExpression.type.isOperator &&
      expressionForAdd.type.isOperator) {
    return true;
  }

  // Check for dot after operators.
  if (lastTokenInExpression.type.isOperator &&
      expressionForAdd.type == TokenType.dot) {
    return true;
  }

  // Check for operator and time keyword in a row.
  if (lastTokenInExpression.type.isOperator &&
      expressionForAdd.type.isTimeKeyword) {
    return true;
  }

  // Check for double time keywords.
  if (lastTokenInExpression.type.isTimeKeyword &&
      expressionForAdd.type.isTimeKeyword) {
    return true;
  }

  // Check for divide or multiply on a number within a time block.
  if (expression.length > 1) {
    final preLastTokenInExpression = expression[expression.length - 2];
    if (isLastExpressionBlockHasTimeKeyword &&
        (preLastTokenInExpression.type == TokenType.multiply ||
            preLastTokenInExpression.type == TokenType.divide) &&
        expressionForAdd.type.isTimeKeyword) {
      return true;
    }
  }

  return false;
}

/// String-level dot validation (no production callers in the original;
/// ported for completeness). Returns true = error. A "." may only follow a
/// digit; any non-"." [expressionForAdd] is reported as "no error".
bool isErrorAfterCheckForPoint(String expressionForAdd, String expression) {
  if (expressionForAdd == '.') {
    if (expression.isNotEmpty && _isDigit(expression[expression.length - 1])) {
      return false;
    }
  } else {
    return false;
  }
  return true;
}

bool _isDigit(String character) {
  final codeUnit = character.codeUnitAt(0);
  return codeUnit >= 0x30 && codeUnit <= 0x39;
}
