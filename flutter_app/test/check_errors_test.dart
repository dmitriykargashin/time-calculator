// Port of WhenCheckExpressionForErrors.kt - all 44 active tests with the
// original inputs and expected outcomes (test names kept verbatim, including
// typos/quirks; the commented-out Kotlin tests are intentionally not ported).

import 'package:cardamon_time_calculator/data/repositories.dart';
import 'package:cardamon_time_calculator/engine/check_errors_in_expression.dart';
import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tokens_matcher.dart';

void main() {
  test('Check expression for double PLUS', () {
    final expression = '0+'.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double MINUS', () {
    final expression = '0-'.toTokens();
    final expressionToAdd = '-'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double DIV', () {
    final expression = '0/'.toTokens();
    final expressionToAdd = '/'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double MULTIPLY', () {
    final expression = '0*'.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for OPERATORS * and div ', () {
    final expression = '0*'.toTokens();
    final expressionToAdd = '/'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS * and +', () {
    final expression = '0*'.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS * and -', () {
    final expression = '0*'.toTokens();
    final expressionToAdd = '-'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS - and +', () {
    final expression = '0-'.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS - and div', () {
    final expression = '0-'.toTokens();
    final expressionToAdd = '/'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS - and *', () {
    final expression = '0-'.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS + and -', () {
    final expression = '0+'.toTokens();
    final expressionToAdd = '-'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS + and *', () {
    final expression = '0+'.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS + and div', () {
    final expression = '0+'.toTokens();
    final expressionToAdd = '/'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS div and -', () {
    final expression = '0/'.toTokens();
    final expressionToAdd = '-'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS div and +', () {
    final expression = '0/'.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS div and *', () {
    final expression = '0/'.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  ////////////// checks for TimeOperators

  test('Check expression for double TIME KEYWORDS YEAR and YEAR', () {
    final expression = '0 Year'.toTokens();
    final expressionToAdd = 'Year'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS MONTH and MONTH', () {
    final expression = '0 Month'.toTokens();
    final expressionToAdd = 'Month'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS WEEK and WEEK', () {
    final expression = '0 Week'.toTokens();
    final expressionToAdd = 'Week'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS DAY and DAY', () {
    final expression = '0 Day'.toTokens();
    final expressionToAdd = 'Day'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS HOUR and HOUR', () {
    final expression = '0 Hour'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS MINUTE and MINUTE', () {
    final expression = '0 Minute'.toTokens();
    final expressionToAdd = 'Minute'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double TIME KEYWORDS SECOND0 and SECOND', () {
    final expression = '0 Second'.toTokens();
    final expressionToAdd = 'Second'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  // Quirk parity: the original test uses "0 Hour" + "Hour" despite its name.
  test('Check expression for double TIME KEYWORDS MSecond and MSecond', () {
    final expression = '0 Hour'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  //// another logic tests

  test('Check expression for dividing on NUMBER with TIME OPERATOR', () {
    final expression = '10 Hour / 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test(
      'Check expression for multiplying NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR',
      () {
    final expression = '10 Hour * 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test(
      'Check NOT ERROR expression for dividing NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR',
      () {
    final expression = '10  / 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check NOT ERROR expression for multiplying on NUMBER with TIME OPERATOR',
      () {
    final expression = '10  * 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test(
      'Check NOT ERROR expression for Adding NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR',
      () {
    final expression = '10 Hour + 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test(
      'Check NOT ERROR expression for substracting NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR',
      () {
    final expression = '10 Hour - 2'.toTokens();
    final expressionToAdd = 'Hour'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check expression for starting with OPERATOR +', () {
    final expression = ''.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for starting with OPERATOR -', () {
    final expression = ''.toTokens();
    final expressionToAdd = '-'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for starting with OPERATOR *', () {
    final expression = ''.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for starting with OPERATOR div', () {
    final expression = ''.toTokens();
    final expressionToAdd = '/'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for double OPERATORS div and YEAR', () {
    final expression = '0/'.toTokens();
    final expressionToAdd = 'Year'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check expression for starting with YEAR Keyword', () {
    final expression = ''.toTokens();
    final expressionToAdd = 'Year'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check NOT ERROR expression for Number multiply', () {
    final expression = '5'.toTokens();
    final expressionToAdd = '*'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check NOT ERROR expression for + after Year Keyword', () {
    final expression = '5 Year'.toTokens();
    final expressionToAdd = '+'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check expression for Multiply NUMBER Years on Year Keyword', () {
    final expression = '5 Year *'.toTokens();
    final expressionToAdd = 'Year'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isTrue);
  });

  test('Check NOT ERROR expression for NUMBER and Month Keyword', () {
    final expression = '5 '.toTokens();
    final expressionToAdd = 'Month'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check NOT ERROR expression for NUMBER and Year Keyword', () {
    final expression = '5 '.toTokens();
    final expressionToAdd = 'Year'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  // Quirk parity: ".".toToken() lexes to an ERROR token (not DOT), so this
  // passes vacuously, exactly like the original.
  test('Check NOT ERROR float point()', () {
    final expression = '5'.toTokens();
    final expressionToAdd = '.'.toToken();

    expect(isErrorsInExpression(expressionToAdd, expression), isFalse);
  });

  test('Check for Delete symbol 55-2 result 55-', () {
    final expressionRepository = ExpressionRepository();
    expressionRepository.setTokens('55-2'.toTokens());

    expressionRepository.deleteLastTokenOrSymbol();
    final listOfActualTokens = expressionRepository.getExpression().value;
    final listOfExpectedTokens = '55-'.toTokens();

    expect(listOfActualTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Check for TWICE Delete symbol 55-2 result 55', () {
    final expressionRepository = ExpressionRepository();
    expressionRepository.setTokens('55-2'.toTokens());

    expressionRepository.deleteLastTokenOrSymbol();
    expressionRepository.deleteLastTokenOrSymbol();

    final listOfActualTokens = expressionRepository.getExpression().value;
    final listOfExpectedTokens = '55'.toTokens();

    expect(listOfActualTokens, isEqualTo(listOfExpectedTokens));
  });
}
