// F1: Empty/Invalid-Result Hint - "Add a Time Unit".
//
// The hint appears when the input is non-empty unitless arithmetic (e.g. "5",
// "5 x 3") that can never produce a time result, and hides as soon as a unit is
// added, the input is cleared, or a result exists.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/data/repositories.dart';
import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/token.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';

Token _num(int n) =>
    Token(TokenType.number, BigDecimal.fromInt(n), n.toString());

void main() {
  group('CalculatorModel.shouldShowAddUnitHint', () {
    CalculatorModel newModel() => CalculatorModel(
          expressionRepository: ExpressionRepository(),
          tokensRepository: TokensRepository(),
          resultFormatsRepository: ResultFormatsRepository.getInstance(),
          perUnitsRepository: PerUnitsRepository.getInstance(),
        );

    test('a blank input shows no hint', () {
      expect(newModel().shouldShowAddUnitHint, isFalse);
    });

    test('a bare number ("5") shows the hint', () {
      final model = newModel();
      model.addToExpression(_num(5));
      expect(model.shouldShowAddUnitHint, isTrue);
    });

    test('a unitless product ("5 x 3") shows the hint', () {
      final model = newModel();
      model.addToExpression(_num(5));
      model.addToExpression(Token(TokenType.multiply, BigDecimal.one));
      model.addToExpression(_num(3));
      expect(model.shouldShowAddUnitHint, isTrue);
    });

    test('adding a time unit ("5 Hour") clears the hint', () {
      final model = newModel();
      model.addToExpression(_num(5));
      expect(model.shouldShowAddUnitHint, isTrue);
      model.addToExpressionTimeUnit(TokenType.hour);
      expect(model.shouldShowAddUnitHint, isFalse);
      expect(model.isResultEmpty(), isFalse); // a real result now exists
    });

    test('an incomplete time expression ("2 Hour + 3") shows NO hint '
        '(it already has a unit)', () {
      final model = newModel();
      model.addToExpression(_num(2));
      model.addToExpressionTimeUnit(TokenType.hour);
      model.addToExpression(Token(TokenType.plus, BigDecimal.one));
      model.addToExpression(_num(3));
      expect(model.shouldShowAddUnitHint, isFalse);
    });

    test('clearing the input removes the hint', () {
      final model = newModel();
      model.addToExpression(_num(5));
      expect(model.shouldShowAddUnitHint, isTrue);
      model.clearAll();
      expect(model.shouldShowAddUnitHint, isFalse);
    });
  });

  group('the F1 hint in the UI', () {
    const hint = "Add a time unit - try '2 Hours 5 Minutes + 15 Minutes'";

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      CalculatorModel.instance.clearAll();
    });

    testWidgets('typing a unitless number shows the hint; adding a unit hides '
        'it', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();

      // Nothing typed yet -> no hint.
      expect(find.text(hint), findsNothing);

      // Type "5" (no unit) -> the hint appears.
      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text(hint), findsOneWidget);

      // Add a unit -> the hint is replaced by the real result.
      await tester.tap(find.text('Hour'));
      await tester.pumpAndSettle();
      expect(find.text(hint), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('deleting the unitless input removes the hint', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      expect(find.text(hint), findsOneWidget);

      // Backspace clears "5" -> blank input -> no hint.
      await tester.tap(find.byIcon(Icons.backspace));
      await tester.pumpAndSettle();
      expect(find.text(hint), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
