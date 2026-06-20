import 'package:cardamon_time_calculator/engine/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Port of the Hamcrest matcher `isEqualTo` in WhenCalculateExpression.kt:
/// matches iff the sizes are equal AND strRepresentation matches at every
/// index. Token TYPES are intentionally NOT compared (parity with the
/// original tests).
Matcher isEqualTo(Tokens expectedTokens) => _TokensEqualMatcher(expectedTokens);

class _TokensEqualMatcher extends Matcher {
  _TokensEqualMatcher(this.expected);

  final Tokens expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! Tokens) return false;
    if (item.length != expected.length) return false;
    for (var i = 0; i < item.length; i++) {
      if (item[i].strRepresentation != expected[i].strRepresentation) {
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('Tokens "${expected.toStringWithSpaces()}"');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is Tokens) {
      return mismatchDescription.add('was Tokens "${item.toStringWithSpaces()}"');
    }
    return mismatchDescription.add('was $item');
  }
}
