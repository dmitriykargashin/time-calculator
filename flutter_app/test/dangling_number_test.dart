// Regression tests for the "dangling unitless number" bug: after "=" promotes
// a result like "3 Hour 25 Minute" into the input, deleting the trailing
// "Minute" used to leave "3 Hour 25" - and the bare "25" was silently counted
// as 25 raw milliseconds, rendering the nonsensical "3 Hour 0.0004167 Minute".
// The fix suppresses the result of such a malformed time expression entirely.

import 'package:cardamon_time_calculator/data/repositories.dart';
import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:cardamon_time_calculator/engine/token.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/engine/tokens.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:flutter_test/flutter_test.dart';

Token _num(int n) =>
    Token(TokenType.number, BigDecimal.fromInt(n), n.toString());

void main() {
  group('Tokens.hasDanglingUnitlessNumber - engine rule', () {
    test('"3 Hour 25" (deleted unit) IS malformed', () {
      expect('3 Hour 25'.toTokens().hasDanglingUnitlessNumber(), isTrue);
    });

    test('"2 Hour + 3" (additive bare number) IS malformed', () {
      expect('2 Hour + 3'.toTokens().hasDanglingUnitlessNumber(), isTrue);
    });

    test('"2 Hour * 3 + 5" (dangling number after a valid product) IS '
        'malformed', () {
      expect('2 Hour * 3 + 5'.toTokens().hasDanglingUnitlessNumber(), isTrue);
    });

    test('"3 Hour 25 Minute" (every number has a unit) is well formed', () {
      expect(
          '3 Hour 25 Minute'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('"5 Hour - 10 Minute" is well formed', () {
      expect(
          '5 Hour - 10 Minute'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('"2 Hour * 3" - the 3 is a multiply scalar - is well formed', () {
      expect('2 Hour * 3'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('"3 * 2 Hour" - the 3 is a multiply scalar - is well formed', () {
      expect('3 * 2 Hour'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('"6 Hour / 2" - the 2 is a divide scalar - is well formed', () {
      expect('6 Hour / 2'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('a pure-arithmetic expression (no time unit) is never malformed', () {
      expect('3 + 5'.toTokens().hasDanglingUnitlessNumber(), isFalse);
      expect('25'.toTokens().hasDanglingUnitlessNumber(), isFalse);
    });

    test('an empty expression is not malformed', () {
      expect(Tokens().hasDanglingUnitlessNumber(), isFalse);
    });
  });

  group('CalculatorModel - result suppression for malformed expressions', () {
    CalculatorModel newModel() => CalculatorModel(
          expressionRepository: ExpressionRepository(),
          tokensRepository: TokensRepository(),
          resultFormatsRepository: ResultFormatsRepository.getInstance(),
          perUnitsRepository: PerUnitsRepository.getInstance(),
        );

    test('the reported flow: build "3 Hour 25 Minute", "=", delete "Minute" -> '
        'no result, Per/Formats disabled', () {
      final model = newModel();

      // Type "3 Hour 25 Minute".
      model.addToExpression(_num(3));
      model.addToExpressionTimeUnit(TokenType.hour);
      model.addToExpression(_num(2));
      model.addToExpression(_num(5));
      model.addToExpressionTimeUnit(TokenType.minute);

      // A real result exists and the action buttons are enabled.
      expect(model.isResultEmpty(), isFalse);
      expect(model.isPerViewButtonDisabled, isFalse);
      expect(model.isFormatsViewButtonDisabled, isFalse);

      // "=" promotes the result to the input (result blanks; buttons disable).
      model.sendResultToExpression();
      expect(model.expression.value.toStringWithSpaces(), '3 Hours 25 Minutes');

      // Delete the trailing "Minute" -> "3 Hours 25" (a dangling bare number).
      model.clearOneLastSymbol();

      // No result is shown and the action buttons stay disabled.
      expect(model.resultTokens.value, isEmpty);
      expect(model.isResultEmpty(), isTrue);
      expect(model.isPerViewButtonDisabled, isTrue);
      expect(model.isFormatsViewButtonDisabled, isTrue);
      expect(model.tempResultInMsec, isEmpty);
    });

    test('re-adding the unit restores the result', () {
      final model = newModel();
      model.addToExpression(_num(3));
      model.addToExpressionTimeUnit(TokenType.hour);
      model.addToExpression(_num(2));
      model.addToExpression(_num(5));
      model.addToExpressionTimeUnit(TokenType.minute);
      model.sendResultToExpression();
      model.clearOneLastSymbol(); // "3 Hours 25" - suppressed
      expect(model.isResultEmpty(), isTrue);

      // Put the unit back: "3 Hours 25 Minutes" computes again.
      model.addToExpressionTimeUnit(TokenType.minute);
      expect(model.isResultEmpty(), isFalse);
      expect(model.resultTokens.value.toStringWithSpaces(), '3 Hours 25 Minutes');
      expect(model.isPerViewButtonDisabled, isFalse);
      expect(model.isFormatsViewButtonDisabled, isFalse);
    });

    test('a multiply scalar ("2 Hour * 3") still shows a result', () {
      final model = newModel();
      model.addToExpression(_num(2));
      model.addToExpressionTimeUnit(TokenType.hour);
      model.addToExpression(Token(TokenType.multiply, BigDecimal.one));
      model.addToExpression(_num(3));

      expect(model.isResultEmpty(), isFalse);
      // 2 hours x 3 = 6 hours.
      expect(model.resultTokens.value.toStringWithSpaces(), '6 Hours');
      expect(model.isPerViewButtonDisabled, isFalse);
    });
  });
}
