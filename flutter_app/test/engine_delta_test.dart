// Ground-truth tests for the RemoveADS engine delta (smart plural, the
// zero-total fix, value plumbing and the changed result-format list).
//
// The Android branch never updated its JUnit tests - they reference the old
// Token constructors and do not even compile there - so this suite is the
// FIRST correct one for the new behavior. It also pins the two deliberate
// fixes the Flutter port applies on top of the branch:
//  1. unit tokens derive their plural from the preceding NUMBER's CURRENT
//     strRepresentation (the branch froze the value at the first keypress,
//     so "12 Hour" rendered singular);
//  2. Tokens.clone copies strRepresentation verbatim (the branch re-ran the
//     plural init on already-pluralized strings -> "Hourss").

import 'package:cardamon_time_calculator/data/repositories.dart';
import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/calculator_of_time.dart';
import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:cardamon_time_calculator/engine/time_converter.dart';
import 'package:cardamon_time_calculator/engine/token.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/engine/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Full production pipeline for one expression: lex was already done by the
/// caller-supplied string -> evaluate -> render in [format].
Tokens evalAndFormat(
  String expression,
  String format, {
  bool removeZeroUnits = true,
}) =>
    TimeConverter.convertTokensToTokensWithFormat(
      CalculatorOfTime.evaluate(expression.toTokens()),
      format.toTokens(),
      removeZeroUnits: removeZeroUnits,
    );

void main() {
  group('smart plural - boundary values at Token construction', () {
    test('value 1 stays singular', () {
      expect(Token(TokenType.hour, BigDecimal.one).strRepresentation, 'Hour');
    });

    test('value 1.0 stays singular (compare is scale-insensitive)', () {
      expect(Token(TokenType.hour, BigDecimal.parse('1.0')).strRepresentation,
          'Hour');
      expect(Token(TokenType.year, BigDecimal.parse('1.00')).strRepresentation,
          'Year');
    });

    test('value 0 is plural ("0 Hours")', () {
      expect(Token(TokenType.hour, BigDecimal.zero).strRepresentation, 'Hours');
    });

    test('negative values are plural ("-1"/"-10 Minutes")', () {
      expect(Token(TokenType.minute, BigDecimal.parse('-1')).strRepresentation,
          'Minutes');
      expect(Token(TokenType.minute, BigDecimal.parse('-10')).strRepresentation,
          'Minutes');
    });

    test('fractional 0.5 is plural ("0.5 Hours")', () {
      expect(Token(TokenType.hour, BigDecimal.parse('0.5')).strRepresentation,
          'Hours');
    });

    test('all 8 time-unit types pluralize with a literal s', () {
      final two = BigDecimal.fromInt(2);
      expect(Token(TokenType.year, two).strRepresentation, 'Years');
      expect(Token(TokenType.month, two).strRepresentation, 'Months');
      expect(Token(TokenType.week, two).strRepresentation, 'Weeks');
      expect(Token(TokenType.day, two).strRepresentation, 'Days');
      expect(Token(TokenType.hour, two).strRepresentation, 'Hours');
      expect(Token(TokenType.minute, two).strRepresentation, 'Minutes');
      expect(Token(TokenType.second, two).strRepresentation, 'Seconds');
      expect(Token(TokenType.mSecond, two).strRepresentation, 'MSeconds');
    });

    test('non-unit types never pluralize', () {
      final five = BigDecimal.fromInt(5);
      expect(Token(TokenType.number, five, '5').strRepresentation, '5');
      expect(Token(TokenType.plus, five).strRepresentation, '+');
      expect(Token(TokenType.error, five).strRepresentation, 'ERROR');
      expect(Token(TokenType.dot, five).strRepresentation, '.');
    });

    test('an explicit strRepresentation is never (re-)pluralized', () {
      // Deliberate fix vs the branch (which appended 's' to whatever string
      // was passed in, corrupting copies).
      final copy = Token(TokenType.hour, BigDecimal.fromInt(2), 'Hours');
      expect(copy.strRepresentation, 'Hours');
    });
  });

  group('smart plural - lexer value inheritance', () {
    test('"12 Hour" lexes plural (multi-digit number)', () {
      final tokens = '12 Hour'.toTokens();
      expect(tokens[1].strRepresentation, 'Hours');
      expect(tokens[1].value.compareTo(BigDecimal.fromInt(12)), 0);
    });

    test('"1 Hour" and "1.0 Year" lex singular', () {
      expect('1 Hour'.toTokens()[1].strRepresentation, 'Hour');
      expect('1.0 Year'.toTokens()[1].strRepresentation, 'Year');
    });

    test('a unit with no preceding NUMBER gets value 1 -> singular '
        '(format labels stay singular)', () {
      final tokens = 'Hour Minute'.toTokens();
      expect(tokens[0].strRepresentation, 'Hour');
      expect(tokens[1].strRepresentation, 'Minute');
      expect(tokens.toStringWithSpaces(), 'Hour Minute');
    });

    test('"2 Hour + 3 Minute" lexes fully plural', () {
      expect('2 Hour + 3 Minute'.toTokens().toStringWithSpaces(),
          '2 Hours + 3 Minutes');
    });

    test('"2Hours" round-trips (cursor advances over the plural s)', () {
      final tokens = '2Hours'.toTokens();
      expect(tokens.length, 2);
      expect(tokens[1].strRepresentation, 'Hours');
      expect(tokens.toString(), '2Hours');
    });

    test('"1Hour" round-trips', () {
      final tokens = '1Hour'.toTokens();
      expect(tokens.length, 2);
      expect(tokens[1].strRepresentation, 'Hour');
      expect(tokens.toString(), '1Hour');
    });

    test('DELIBERATE FIX: legacy singular text with value != 1 re-lexes '
        'losslessly ("2Hour+3Minute" keeps the +)', () {
      // The branch advanced the cursor by the PLURALIZED length and lost the
      // '+' here; the port consumes exactly the matched keyword (plus an
      // optional trailing s).
      expect('2Hour+3Minute'.toTokens().toStringWithSpaces(),
          '2 Hours + 3 Minutes');
    });

    test('DELIBERATE FIX: "1Hours" lexes to a clean singular token (the '
        'branch left a stray ERROR token)', () {
      final tokens = '1Hours'.toTokens();
      expect(tokens.length, 2);
      expect(tokens[1].strRepresentation, 'Hour');
    });

    test('DELIBERATE DEVIATION: malformed numbers no longer throw at lex '
        'time ("1.2.3" lexes with fallback value 1)', () {
      final tokens = '1.2.3 Hour'.toTokens();
      expect(tokens[0].strRepresentation, '1.2.3');
      expect(tokens[0].value.compareTo(BigDecimal.one), 0);
      expect(tokens[1].strRepresentation, 'Hour');
    });
  });

  group('smart plural - expression building (the fixed multi-digit '
      'behavior)', () {
    test('typing 1, 2, Hour yields "12 Hours" (the branch showed '
        '"12 Hour")', () {
      final repo = ExpressionRepository();
      repo.addToExpression(Token(TokenType.number, BigDecimal.one, '1'));
      repo.addToExpression(Token(TokenType.number, BigDecimal.fromInt(2), '2'));
      repo.addToExpressionTimeUnit(TokenType.hour);
      expect(repo.getExpression().value.toStringWithSpaces(), '12 Hours');
    });

    test('typing 1, Hour yields the singular "1 Hour"', () {
      final repo = ExpressionRepository();
      repo.addToExpression(Token(TokenType.number, BigDecimal.one, '1'));
      repo.addToExpressionTimeUnit(TokenType.hour);
      expect(repo.getExpression().value.toStringWithSpaces(), '1 Hour');
    });

    test('backspacing 12 -> 1 then Hour yields "1 Hour" (value derives from '
        'the CURRENT digits, not the first keypress)', () {
      final repo = ExpressionRepository();
      repo.addToExpression(Token(TokenType.number, BigDecimal.one, '1'));
      repo.addToExpression(Token(TokenType.number, BigDecimal.fromInt(2), '2'));
      repo.deleteLastTokenOrSymbol(); // "12" -> "1"
      repo.addToExpressionTimeUnit(TokenType.hour);
      expect(repo.getExpression().value.toStringWithSpaces(), '1 Hour');
    });

    test('a unit with no preceding NUMBER is rejected exactly as before '
        '(validation unchanged)', () {
      final repo = ExpressionRepository();
      expect(repo.addToExpressionTimeUnit(TokenType.hour), isFalse);
      expect(repo.getExpression().value, isEmpty);
    });
  });

  group('clone - no double pluralization (deliberate fix)', () {
    test('clone copies plural strings and values verbatim', () {
      final tokens = '2 Hour'.toTokens(); // -> [NUMBER "2", HOUR "Hours"]
      final cloned = tokens.clone();
      expect(cloned[1].strRepresentation, 'Hours'); // branch: "Hourss"
      expect(cloned[1].value.compareTo(BigDecimal.fromInt(2)), 0);
      expect(cloned.clone()[1].strRepresentation, 'Hours'); // and not worse
    });

    test('evaluate (which clones and parenthesizes internally) never '
        'corrupts unit strings', () {
      final tokens = '2 Hour + 3 Minute'.toTokens();
      final result = CalculatorOfTime.evaluate(tokens);
      expect(tokens.toStringWithSpaces(), '2 Hours + 3 Minutes');
      expect(result[0].strRepresentation, '7380000.0');
    });
  });

  group('MSECOND result tag carries the msec total', () {
    test('non-1 totals tag as "MSeconds"', () {
      final result = CalculatorOfTime.evaluate('5 Hour'.toTokens());
      expect(result[1].type, TokenType.mSecond);
      expect(result[1].strRepresentation, 'MSeconds');
    });

    test('a total of exactly 1 ms tags as singular "MSecond"', () {
      // MSECOND input tokens are dropped by convertExpressionToMsecs, so
      // "1 MSecond" evaluates to plain 1.0 ms (bug parity).
      final result = CalculatorOfTime.evaluate('1 MSecond'.toTokens());
      expect(result[0].strRepresentation, '1.0');
      expect(result[1].strRepresentation, 'MSecond');
    });
  });

  group('zero-total emission (RemoveADS fix: "0 <Unit>s" instead of an '
      'empty result)', () {
    test('5 Hour - 5 Hour in "Hour Minute" -> "0 Minutes"', () {
      expect(evalAndFormat('5 Hour - 5 Hour', 'Hour Minute')
          .toStringWithSpaces(), '0 Minutes');
    });

    test('5 Hour - 5 Hour in "Hour" -> "0 Hours"', () {
      expect(evalAndFormat('5 Hour - 5 Hour', 'Hour').toStringWithSpaces(),
          '0 Hours');
    });

    test('5 Minute - 5 Minute in the All Units format -> "0 MSeconds"', () {
      expect(
        evalAndFormat('5 Minute - 5 Minute',
                'Year Month Week Day Hour Minute Second MSecond')
            .toStringWithSpaces(),
        '0 MSeconds',
      );
    });

    test('BUG PARITY: an ERROR result (division by zero) is masked as a '
        'zero ("0 Hours")', () {
      final evaluated = CalculatorOfTime.evaluate('5 Hour / 0'.toTokens());
      expect(evaluated[0].type, TokenType.error);
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
                evaluated, 'Hour'.toTokens())
            .toStringWithSpaces(),
        '0 Hours',
      );
    });

    test('empty input tokens render as "0 Minutes" too', () {
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
                Tokens(), 'Hour Minute'.toTokens())
            .toStringWithSpaces(),
        '0 Minutes',
      );
    });

    test('the emitted zero tokens carry value 0 and text "0"', () {
      final result = evalAndFormat('5 Hour - 5 Hour', 'Hour Minute');
      expect(result.length, 2);
      expect(result[0].type, TokenType.number);
      expect(result[0].strRepresentation, '0');
      expect(result[0].value.isZero, isTrue);
      expect(result[1].type, TokenType.minute);
      expect(result[1].value.isZero, isTrue);
    });

    test('a NON-zero total whose last unit is 0 still omits that unit '
        '(no trailing "0 Minutes")', () {
      expect(evalAndFormat('2 Hour', 'Hour Minute').toStringWithSpaces(),
          '2 Hours');
    });

    test('removeZeroUnits=false is unchanged (normal emit path: '
        '"0 Hours 0 Minutes")', () {
      expect(
        evalAndFormat('5 Hour - 5 Hour', 'Hour Minute',
                removeZeroUnits: false)
            .toStringWithSpaces(),
        '0 Hours 0 Minutes',
      );
    });

    test('the Per-view math survives a zero total (amount x 0 = 0, no '
        'units[0] crash)', () {
      final repo = PerUnitsRepository.getInstance();
      repo.updatePerUnitsWithPreview(
          CalculatorOfTime.evaluate('5 Hour - 5 Hour'.toTokens()));
      for (final row in repo.getPerUnits().value) {
        expect(row.unitsPerResult.isZero, isTrue);
      }
    });
  });

  group('converted results pluralize by the converted amount', () {
    test('2 Day as "Hour" -> "48 Hours"', () {
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
                '2 Day'.toTokens(), 'Hour'.toTokens())
            .toStringWithSpaces(),
        '48 Hours',
      );
    });

    test('62 Minute as "Day Hour Minute Second" -> "1 Hour 2 Minutes" '
        '(singular next to plural)', () {
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
                '62 Minute'.toTokens(), 'Day Hour Minute Second'.toTokens())
            .toStringWithSpaces(),
        '1 Hour 2 Minutes',
      );
    });

    test('12.5 Month to YEAR -> "1.0 Year" (1.0 is singular)', () {
      expect(
        TimeConverter.convertExpressionInMsecsToType(
                '12.5 Month'.toTokenInMSec(), TokenType.year)
            .toStringWithSpaces(),
        '1.0 Year',
      );
    });

    test('1 Year to MONTH -> "12 Months"', () {
      expect(
        TimeConverter.convertExpressionInMsecsToType(
                '1 Year'.toTokenInMSec(), TokenType.month)
            .toStringWithSpaces(),
        '12 Months',
      );
    });

    test('negative results pluralize: 0 - 10 Minute as "Minute" -> '
        '"-10 Minutes"', () {
      expect(evalAndFormat('0 - 10 Minute', 'Minute').toStringWithSpaces(),
          '-10 Minutes');
    });
  });

  group('result formats list (RemoveADS: 26 entries)', () {
    test('26 formats; index 3 is the changed "Year Month Day Hour", index 4 '
        'is the new "Year Month Day Hour Minute"', () {
      final repo = ResultFormatsRepository.getInstance();
      expect(repo.length(), 26);

      final formats = repo.getResultFormats().value;
      expect(formats[3].textPresentationOfTokens, 'Year Month Day Hour');
      expect(formats[3].convertedResultTokens.toStringWithSpaces(),
          '1 Year 2 Months 3 Days 4 Hours'); // preview lexes pluralized
      expect(formats[4].textPresentationOfTokens, 'Year Month Day Hour Minute');
      expect(formats[4].convertedResultTokens.toStringWithSpaces(),
          '1 Year 2 Months 3 Days 4 Hours 5 Minutes');
    });

    test('default selection is still "Hour Minute", now at 0-based '
        'index 18', () {
      final repo = ResultFormatsRepository.getInstance();
      final formats = repo.getResultFormats().value;
      expect(formats[18].textPresentationOfTokens, 'Hour Minute');
      expect(formats[18].isSelected, isTrue);
      expect(repo.getSelectedFormat().value, same(formats[18]));
    });

    test('format labels are singular (format tokens carry value 1)', () {
      final repo = ResultFormatsRepository.getInstance();
      for (final format in repo.getResultFormats().value) {
        expect(format.textPresentationOfTokens, isNot(contains('s ')));
        expect(format.textPresentationOfTokens.endsWith('s'),
            format.textPresentationOfTokens == 'All Units');
      }
    });

    test('the new "MSecond" format renders the whole interval in ms', () {
      final formats = ResultFormatsRepository.getInstance()
          .getResultFormats()
          .value;
      final msec = formats.firstWhere(
          (f) => f.textPresentationOfTokens == 'MSecond');
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
          CalculatorOfTime.evaluate('2 Hour'.toTokens()),
          msec.formatTokens,
        ).toStringWithSpaces(),
        '7200000 MSeconds',
      );
    });

    test('the new "Hour Minute Second MSecond" format breaks out sub-second '
        'milliseconds', () {
      final formats = ResultFormatsRepository.getInstance()
          .getResultFormats()
          .value;
      final hmsms = formats.firstWhere(
          (f) => f.textPresentationOfTokens == 'Hour Minute Second MSecond');
      expect(
        TimeConverter.convertTokensToTokensWithFormat(
          '1.5 Second'.toTokens(),
          hmsms.formatTokens,
        ).toStringWithSpaces(),
        '1 Second 500 MSeconds',
      );
    });
  });
}
