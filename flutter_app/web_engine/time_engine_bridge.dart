// Dart→JS bridge over the PURE-DART time engine (lib/engine/*). Compiled with
// `dart compile js` into a JS module the Nuxt web app loads, so the website
// uses the SAME math as the mobile apps — fix the Dart engine, recompile, and
// the web is fixed automatically (single source of truth).
//
// Exposes on globalThis:
//   evaluateTime(input, format) -> string
//     input  e.g. "5 Hour + 30 Minute"   (full unit words, like the app)
//     format e.g. "Hour Minute"           (an ordered unit set)
//     returns the formatted result ("7 Hours 45 Minutes"), "" for empty input,
//             or "ERROR" for malformed input / divide-by-zero.
//
//   intervalBreakdown(input) -> JSON string
//     The evaluated interval expressed as a DECIMAL in every time unit, used by
//     the "Per" / rate calculator (total = amount × interval-in-that-unit).
//     -> {"ok":true,"msec":"...","Year":"..","Month":"..", ... ,"Second":".."}
//        or {"ok":false,"error":true}.
import 'dart:js_interop';

import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/calculator_constants.dart';
import 'package:cardamon_time_calculator/engine/calculator_of_time.dart';
import 'package:cardamon_time_calculator/engine/lexical_analyzer.dart';
import 'package:cardamon_time_calculator/engine/time_converter.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';

String _evaluate(String input, String format) {
  try {
    final expr = LexicalAnalyzer.analyze(input);
    final result = CalculatorOfTime.evaluate(expr);
    if (result.isEmpty) return '';
    for (final t in result) {
      if (t.type == TokenType.error) return 'ERROR';
    }
    final formatTokens = LexicalAnalyzer.analyze(format);
    final formatted =
        TimeConverter.convertTokensToTokensWithFormat(result, formatTokens);
    // toStringWithSpaces() = the app's display spacing ("5 Hours 30 Minutes").
    return formatted.toStringWithSpaces();
  } catch (_) {
    return 'ERROR';
  }
}

String _intervalBreakdown(String input) {
  try {
    final expr = LexicalAnalyzer.analyze(input);
    final result = CalculatorOfTime.evaluate(expr);
    if (result.isEmpty) return '{"ok":false}';
    for (final t in result) {
      if (t.type == TokenType.error) return '{"ok":false,"error":true}';
    }
    // result is [NUMBER(msec), MSECOND]; the value is the total milliseconds.
    final msec = double.parse(result.first.value.toString());
    String per(BigDecimal c) => (msec / double.parse(c.toString())).toString();
    return '{"ok":true,'
        '"msec":"$msec",'
        '"Year":"${per(millisecondsInYear)}",'
        '"Month":"${per(millisecondsInMonth)}",'
        '"Week":"${per(millisecondsInWeek)}",'
        '"Day":"${per(millisecondsInDay)}",'
        '"Hour":"${per(millisecondsInHour)}",'
        '"Minute":"${per(millisecondsInMinute)}",'
        '"Second":"${per(millisecondsInSecond)}",'
        '"MSecond":"$msec"}';
  } catch (_) {
    return '{"ok":false,"error":true}';
  }
}

@JS('evaluateTime')
external set _evaluateTime(JSFunction value);

@JS('intervalBreakdown')
external set _intervalBreakdownJs(JSFunction value);

void main() {
  _evaluateTime =
      ((String input, String format) => _evaluate(input, format)).toJS;
  _intervalBreakdownJs =
      ((String input) => _intervalBreakdown(input)).toJS;
}
