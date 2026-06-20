// Port of WhenConvertResult.kt - all 17 tests with the original inputs and
// expected outputs (several test NAMES are misleading in the original, e.g.
// "Convert Result 12 Day to Month" actually converts 13.1 Day; the names are
// kept verbatim, the table values are what matters).

import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:cardamon_time_calculator/engine/time_converter.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:flutter_test/flutter_test.dart';

import 'tokens_matcher.dart';

void main() {
  test('Convert Result 10 Year to 10 Year', () {
    final listOfExpectedTokens = '10 Year'.toTokens();
    final forConvertInMsec = '10 Year'.toTokenInMSec();

    final listOfResultTokens = TimeConverter.convertExpressionInMsecsToType(
        forConvertInMsec, TokenType.year);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 1 Year to 12 Month', () {
    final listOfExpectedTokens = '12 Month'.toTokens();
    final forConvertInMsec = '1 Year'.toTokenInMSec();

    final listOfResultTokens = TimeConverter.convertExpressionInMsecsToType(
        forConvertInMsec, TokenType.month);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12 Month to 360 Day', () {
    final listOfExpectedTokens = '360 Day'.toTokens();
    final forConvertInMsec = '12 Month'.toTokenInMSec();

    final listOfResultTokens = TimeConverter.convertExpressionInMsecsToType(
        forConvertInMsec, TokenType.day);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12,5 Month to 375 Day', () {
    final listOfExpectedTokens = '375.0 Day'.toTokens();
    final forConvertInMsec = '12.5 Month'.toTokenInMSec();

    final listOfResultTokens = TimeConverter.convertExpressionInMsecsToType(
        forConvertInMsec, TokenType.day);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12,5 Month to 1,0273972602739727 Year', () {
    final listOfExpectedTokens = '1.0 Year'.toTokens();
    final forConvertInMsec = '12.5 Month'.toTokenInMSec();

    final listOfResultTokens = TimeConverter.convertExpressionInMsecsToType(
        forConvertInMsec, TokenType.year);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2 Day to 48 Hour', () {
    final forConvertInTokens = '2 Day'.toTokens();
    final formatResult = 'Hour'.toTokens();
    final listOfExpectedTokens = '48 Hour'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2,1 Day to 50,4 Hour', () {
    final forConvertInTokens = '2.1 Day'.toTokens();
    final formatResult = 'Hour'.toTokens();
    final listOfExpectedTokens = '50.4 Hour'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 48 Hour to 48 Hour', () {
    final forConvertInTokens = '48 Hour'.toTokens();
    final formatResult = 'Hour'.toTokens();
    final listOfExpectedTokens = '48 Hour'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2,1 Day to 50 Hour 24 Minute', () {
    final forConvertInTokens = '2.1 Day'.toTokens();
    final formatResult = 'Hour Minute'.toTokens();
    final listOfExpectedTokens = '50 Hour 24 Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2,1 Day to 24 Minute', () {
    final forConvertInTokens = '2.1 Day'.toTokens();
    final formatResult = 'Minute'.toTokens();
    final listOfExpectedTokens = '3024 Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2,12 Day to 24 Minute', () {
    final forConvertInTokens = '2.12 Day'.toTokens();
    final formatResult = 'Minute'.toTokens();
    final listOfExpectedTokens = '3052.8 Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 2,12 Day to Month', () {
    final forConvertInTokens = '2.12222222 Day'.toTokens();
    final formatResult = 'Month'.toTokens();
    final listOfExpectedTokens = '0.0707407Month'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12 Day to 12 Day', () {
    final forConvertInTokens = '12 Day'.toTokens();
    final formatResult = 'Day'.toTokens();
    final listOfExpectedTokens = '12 Day'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12 Day to Year Month Day Minute Second', () {
    final forConvertInTokens = '0.1 Day'.toTokens();
    final formatResult = 'Year Month Day Hour Minute Second'.toTokens();
    final listOfExpectedTokens = '2Hour24Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 12 Day to Month', () {
    final forConvertInTokens = '13.1 Day'.toTokens();
    final formatResult = 'Month '.toTokens();
    final listOfExpectedTokens = '0.4366667Month'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 240000Msec to Minute', () {
    final forConvertInTokens = '235000 Second'.toTokens();
    final formatResult = 'Hour Minute '.toTokens();
    final listOfExpectedTokens = '65 Hour 16.6666667Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });

  test('Convert Result 240000Msec to Day Hour Minute Second', () {
    final forConvertInTokens = '62 Minute'.toTokens();
    final formatResult = 'Day Hour Minute Second '.toTokens();
    final listOfExpectedTokens = '1 Hour 2 Minute'.toTokens();

    final listOfResultTokens = TimeConverter.convertTokensToTokensWithFormat(
        forConvertInTokens, formatResult);

    expect(listOfResultTokens, isEqualTo(listOfExpectedTokens));
  });
}
