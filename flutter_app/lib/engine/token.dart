import 'big_decimal.dart';
import 'token_type.dart';
import 'tokens.dart';

/// A single lexical token. Port of Kotlin `Token` (data/tokens/Token.kt) as
/// of the RemoveADS branch: `Token(type, value, strRepresentation = type.value)`.
///
/// [value] is the branch's new required BigDecimal field. It drives the
/// "smart plural" feature (commit 6af830c): time-unit tokens whose value is
/// not 1 render with a trailing 's' ("2 Hours", "0 Minutes", "-10 Days",
/// "0.5 Hours"); exactly 1 - scale-insensitive, so 1, 1.0 and 1.00 all count -
/// stays singular ("1 Hour").
///
/// `Token(type, value)` mirrors the Kotlin secondary constructor and copies
/// [TokenType.value] into [strRepresentation]; `Token(type, value, text)`
/// sets it explicitly (used for NUMBER tokens, whose real digits live here,
/// and for verbatim copies).
///
/// Equality is reference identity, as in the original (tests compare lists by
/// per-index [strRepresentation] only).
class Token {
  Token(this.type, this.value, [String? strRepresentation])
      : strRepresentation = strRepresentation ?? type.value {
    // Smart plural: applies ONLY to the 8 time-keyword types; the trigger is
    // a scale-insensitive BigDecimal comparison against 1 (0, fractions and
    // negatives are all plural).
    //
    // DELIBERATE FIX vs the RemoveADS branch: the Kotlin init appended 's'
    // to WHATEVER string the constructor received, on EVERY construction -
    // so copies of already-pluralized tokens (Tokens.clone at the top of
    // CalculatorOfTime.evaluate, _setParenthesesToExpression) silently became
    // "Hourss"/"Hoursss". Here the plural is applied only when the caller did
    // NOT pass an explicit strRepresentation (i.e. the token starts from the
    // canonical singular type.value); explicit strings - clones and copies -
    // are kept verbatim and never re-pluralized.
    if (strRepresentation == null &&
        type.isTimeKeyword &&
        value.compareTo(BigDecimal.one) != 0) {
      this.strRepresentation += 's';
    }
  }

  /// The token's type (immutable).
  final TokenType type;

  /// The token's numeric value (immutable, like the Kotlin `val`). For unit
  /// tokens this is the amount that drives pluralization; for NUMBER tokens
  /// it is informational only (every consumer parses [strRepresentation],
  /// which - unlike `value` - tracks in-place edits such as
  /// [mergeNumberToNumber]).
  final BigDecimal value;

  /// The token's textual content (mutable in place, like the original).
  String strRepresentation;

  /// Appends `.` to [strRepresentation] unless it already contains one.
  /// No type check is performed (callers must ensure this is a NUMBER).
  void addDotToNumber() {
    if (!strRepresentation.contains('.')) strRepresentation += '.';
  }

  /// Length of [strRepresentation]; the lexer advances its cursor by this.
  int length() => strRepresentation.length;

  /// Concatenates [token]'s text onto this token (digit merging while the
  /// user types). No type or validity checks. NOTE: [value] is NOT updated
  /// (it is final, parity with the Kotlin `val`) - which is why value
  /// consumers re-parse [strRepresentation] instead.
  void mergeNumberToNumber(Token token) {
    strRepresentation += token.strRepresentation;
  }

  /// Drops the last character, but only when this is a NUMBER token with a
  /// non-empty text. Can leave an empty [strRepresentation].
  void deleteOneLastSymbolInNumber() {
    if (type == TokenType.number && length() > 0) {
      strRepresentation =
          strRepresentation.substring(0, strRepresentation.length - 1);
    }
  }

  /// Wraps this token (the same instance, not a copy) in a new [Tokens] list.
  Tokens toTokens() {
    final tokens = Tokens();
    tokens.add(this);
    return tokens;
  }
}
