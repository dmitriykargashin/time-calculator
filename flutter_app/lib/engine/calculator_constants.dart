/// Time-unit conversion constants. Port of CalculatorOfTimeConst.kt -
/// values verbatim. A month is exactly 30 days, a year exactly 365 days;
/// there is no calendar awareness (so 12 Month = 360 Day != 1 Year).
library;

import 'big_decimal.dart';

final BigDecimal millisecondsInSecond = BigDecimal.fromInt(1000);
final BigDecimal secondsInMinute = BigDecimal.fromInt(60);
final BigDecimal minutesInHour = BigDecimal.fromInt(60);
final BigDecimal hoursInDay = BigDecimal.fromInt(24);
final BigDecimal daysInWeek = BigDecimal.fromInt(7);
final BigDecimal daysInMonth = BigDecimal.fromInt(30);
final BigDecimal daysInYear = BigDecimal.fromInt(365);

/// 60 000
final BigDecimal millisecondsInMinute = millisecondsInSecond * secondsInMinute;

/// 3 600 000
final BigDecimal millisecondsInHour = millisecondsInMinute * minutesInHour;

/// 86 400 000
final BigDecimal millisecondsInDay = millisecondsInHour * hoursInDay;

/// 604 800 000
final BigDecimal millisecondsInWeek = millisecondsInDay * daysInWeek;

/// 2 592 000 000
final BigDecimal millisecondsInMonth = millisecondsInDay * daysInMonth;

/// 31 536 000 000
final BigDecimal millisecondsInYear = millisecondsInDay * daysInYear;
