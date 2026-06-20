// Port of WhenCalculateExpression.kt - all 9 tests with the original inputs
// and expected outputs.
//
// NOTE on the pipeline under test: 8 of these 9 Kotlin tests were written
// against the HISTORICAL evaluate() contract (a single plain number for
// simple arithmetic; a nearest-units decomposition for time expressions).
// The current engine - faithfully ported in CalculatorOfTime.evaluate -
// returns `[NUMBER <msec>, MSECOND]` instead, so, as recommended by
// docs/port-spec/errors-and-tests.md (section 5.1/6.3), these are ported as
// END-TO-END tests: evaluate + the historical display steps
// (stripTrailingZeros for simple arithmetic, convertExpressionInMsecsToNearest
// for time expressions). The expected values are unchanged from the Kotlin
// tests.

import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/calculator_of_time.dart';
import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:cardamon_time_calculator/engine/time_converter.dart';
import 'package:cardamon_time_calculator/engine/token.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/engine/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tokens_matcher.dart';

String addStartAndEndSpace(String s) => ' $s ';

Tokens calculateExpression(String stringExpression) {
  final listOfTokens = LexicalAnalyzer.analyze(stringExpression);
  final evaluated = CalculatorOfTime.evaluate(listOfTokens);
  if (evaluated.isEmpty || evaluated.first.type == TokenType.error) {
    return evaluated;
  }
  if (listOfTokens.isSimpleArithmeticExpression()) {
    // Historical contract: a single plain NUMBER token ("10", "-10", "0").
    final plainValue = BigDecimal.parse(evaluated.first.strRepresentation)
        .stripTrailingZeros();
    return Token(TokenType.number, plainValue, plainValue.toPlainString())
        .toTokens();
  }
  // Historical contract: nearest-units decomposition of the msec result.
  return TimeConverter.convertExpressionInMsecsToNearest(evaluated.first);
}

void main() {
  test('Calculate Empty expression', () {
    const expressionForCalculate = '';
    final listOfExpectedTokens = ''.toTokens();

    final listOfActualTokens = calculateExpression(expressionForCalculate);

    expect(listOfActualTokens, isEqualTo(listOfExpectedTokens));
  });

  test('calculate_Expr_0_plus_10_Equals_10', () {
    final listOfResultTokens = calculateExpression(
        '0${addStartAndEndSpace(TokenType.plus.value)}10');

    expect(listOfResultTokens.length - 1, equals(0));
    expect(listOfResultTokens[0].strRepresentation, equals('10'));
  });

  test('calculate_Expr_0_minus_10_Equals_minus10', () {
    final listOfResultTokens = calculateExpression(
        '0${addStartAndEndSpace(TokenType.minus.value)}10');

    expect(listOfResultTokens.length - 1, equals(0));
    expect(listOfResultTokens[0].strRepresentation, equals('-10'));
  });

  test('calculate_Expr_0_multiply_10_Equals_0', () {
    final listOfResultTokens = calculateExpression(
        '0${addStartAndEndSpace(TokenType.multiply.value)}10');

    expect(listOfResultTokens.length - 1, equals(0));
    expect(listOfResultTokens[0].strRepresentation, equals('0'));
  });

  test('calculate_Expr_0_divide_10_Equals_0', () {
    final listOfResultTokens = calculateExpression(
        '0${addStartAndEndSpace(TokenType.divide.value)}10');

    expect(listOfResultTokens.length - 1, equals(0));
    expect(listOfResultTokens[0].strRepresentation, equals('0'));
  });

  test('calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute', () {
    final listOfResultTokens = calculateExpression('10 Minute+ 5 Hour');

    expect(listOfResultTokens.length - 1, equals(3));
    expect(listOfResultTokens[0].strRepresentation, equals('5'));
    expect(listOfResultTokens[1].type.value, equals(TokenType.hour.value));
    expect(listOfResultTokens[2].strRepresentation, equals('10'));
    expect(listOfResultTokens[3].type.value, equals(TokenType.minute.value));
  });

  test('calculate_Expr_10Minute_multiply_5_Equals_50Minute', () {
    final listOfResultTokens = calculateExpression(
        '10 ${TokenType.minute.value} ${addStartAndEndSpace(TokenType.multiply.value)}5');

    expect(listOfResultTokens.length - 1, equals(1));
    expect(listOfResultTokens[0].strRepresentation, equals('50'));
    expect(listOfResultTokens[1].type.value, equals(TokenType.minute.value));
  });

  test('calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute_a', () {
    // RemoveADS smart plural: unit tokens carry the component amount and
    // pluralize when it is not 1 ("Hours", "Minutes").
    final listOfExpectedTokens = Tokens();
    listOfExpectedTokens.add(Token(TokenType.number, BigDecimal.fromInt(5), '5'));
    listOfExpectedTokens.add(Token(TokenType.hour, BigDecimal.fromInt(5)));
    listOfExpectedTokens
        .add(Token(TokenType.number, BigDecimal.fromInt(10), '10'));
    listOfExpectedTokens.add(Token(TokenType.minute, BigDecimal.fromInt(10)));

    const stringExpression = '10 Minute + 5 Hour';

    final listOfResultTokens = calculateExpression(stringExpression);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('calculate_Expr_5Hour_Minus_10_Minute_Equals_4Hour50Minute', () {
    final listOfExpectedTokens = Tokens();
    listOfExpectedTokens.add(Token(TokenType.number, BigDecimal.fromInt(4), '4'));
    listOfExpectedTokens.add(Token(TokenType.hour, BigDecimal.fromInt(4)));
    listOfExpectedTokens
        .add(Token(TokenType.number, BigDecimal.fromInt(50), '50'));
    listOfExpectedTokens.add(Token(TokenType.minute, BigDecimal.fromInt(50)));

    const stringExpression = '5 Hour-10 Minute';

    final listOfResultTokens = calculateExpression(stringExpression);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });
}
