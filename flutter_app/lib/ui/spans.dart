import 'package:flutter/painting.dart';

import '../engine/big_decimal.dart';
import '../engine/token.dart';
import '../engine/token_type.dart';
import '../engine/tokens.dart';
import 'theme.dart';

/// RelativeSizeSpan factor used by the original for time units, ERROR and
/// (new on the RemoveADS branch) the gray result numbers/operators.
const double kTokenRelativeSize = 0.7;

/// Port of `Tokens.toSpannableString(context)` (expression / Per interval
/// header rendering), theme-aware since RemoveADS:
/// * NUMBER - plain text, inherits the surrounding style (the caller paints
///   colorExpressionNums);
/// * time units - " Unit " space-padded, colorExpressionTime at 0.7x size;
/// * operators - " op " space-padded, plain (Unicode glyphs);
/// * ERROR - " ERROR " red at 0.7x;
/// * DOT / parentheses - silently skipped (no branch in the original).
///
/// [fontSize] is the base font size; only the 0.7x pieces set an explicit
/// size, everything else inherits, so AutoSizeText scaling stays uniform.
List<TextSpan> tokensToSpans(
  Tokens tokens, {
  required double fontSize,
  required AppPalette palette,
}) =>
    _spans(
      tokens,
      fontSize: fontSize,
      unitColor: palette.expressionTime,
      plainColor: null,
      plainRelativeSize: false,
    );

/// Port of `Tokens.toLightSpannableString(context)` (result / preview
/// rendering), theme-aware since RemoveADS:
/// * NUMBER and operators - colorResultNums at 0.7x size (the gray helper
///   gained a 0.7f RelativeSizeSpan on the branch - the engine-delta reading
///   confirmed by delta-critic-gaps.md; master rendered gray at full size);
/// * time units - " Unit " colorResultTime at 0.7x;
/// * ERROR - " ERROR " red at 0.7x;
/// * DOT / parentheses - skipped.
List<TextSpan> tokensToLightSpans(
  Tokens tokens, {
  required double fontSize,
  required AppPalette palette,
}) =>
    _spans(
      tokens,
      fontSize: fontSize,
      unitColor: palette.resultTime,
      plainColor: palette.resultNums,
      plainRelativeSize: true,
    );

List<TextSpan> _spans(
  Tokens tokens, {
  required double fontSize,
  required Color unitColor,
  required Color? plainColor,
  required bool plainRelativeSize,
}) {
  final plainStyle = plainColor == null
      ? null
      : TextStyle(
          color: plainColor,
          fontSize: plainRelativeSize ? fontSize * kTokenRelativeSize : null,
        );
  final spans = <TextSpan>[];
  for (final token in tokens) {
    final type = token.type;
    if (type == TokenType.number) {
      spans.add(TextSpan(text: token.strRepresentation, style: plainStyle));
    } else if (type.isTimeKeyword) {
      spans.add(
        TextSpan(
          text: ' ${token.strRepresentation} ',
          style: TextStyle(
            color: unitColor,
            fontSize: fontSize * kTokenRelativeSize,
          ),
        ),
      );
    } else if (type.isOperator) {
      spans.add(
        TextSpan(text: ' ${token.strRepresentation} ', style: plainStyle),
      );
    } else if (type == TokenType.error) {
      spans.add(
        TextSpan(
          text: ' ${token.strRepresentation} ',
          style: TextStyle(
            color: AppPalette.error,
            fontSize: fontSize * kTokenRelativeSize,
          ),
        ),
      );
    }
    // DOT, PARENTHESESLEFT, PARENTHESESRIGHT: skipped (parity).
  }
  return spans;
}

/// Port of `toHTMLWithGreenColor(context)` - colorExpressionTime at 0.7x
/// [fontSize] (format card titles).
///
/// `toHTMLWithLightGreenColor` has no port anymore: its last consumer was
/// the master-era Formats button label, and the RemoveADS selected-format
/// label renders as PLAIN unstyled text at colorControls
/// (delta-critic-gaps.md: the branch sets tvFormats.text without any span).
TextSpan greenSpan(
  String text, {
  required double fontSize,
  required AppPalette palette,
}) =>
    TextSpan(
      text: text,
      style: TextStyle(
        color: palette.expressionTime,
        fontSize: fontSize * kTokenRelativeSize,
      ),
    );

/// Max SIGNIFICANT fractional digits kept in a rounded preview number. A value
/// like 4.8333333 becomes 4.8333 (4 sig figs after the point); 0.0005518 keeps
/// its 4 significant digits past the leading zeros (0.0005518). Whole numbers
/// are shown plainly (no rounding).
const int _kPreviewFractionSigDigits = 4;

/// Hard ceiling on the fractional scale so a tiny value with many leading zeros
/// (e.g. 0.00000001234) can't produce an unreadably long preview string.
const int _kPreviewMaxScale = 8;

/// The outcome of rounding a preview's NUMBER tokens for human-friendly
/// display: the (possibly) shortened tokens and whether any value actually
/// changed (so the caller can prefix an approximation hint only when it did).
class RoundedPreview {
  const RoundedPreview(this.tokens, {required this.wasRounded});

  /// A clone of the input with each NUMBER token's text rounded for display.
  final Tokens tokens;

  /// True iff at least one number was actually shortened from its exact value
  /// (an exact integer or an already-short value leaves this false, so no
  /// approximation marker).
  final bool wasRounded;
}

/// Rounds the NUMBER tokens of a [preview] result to a readable precision for
/// the Formats chooser previews ONLY. This never touches the engine or the
/// committed selected-result formatting - it is a display hint.
///
/// Each NUMBER token is parsed and, if it has a fractional part, capped to
/// [_kPreviewFractionSigDigits] SIGNIFICANT fractional digits (bounded by
/// [_kPreviewMaxScale]) with trailing zeros stripped. Exact integers and values
/// already within that precision are left verbatim. Non-number tokens (units,
/// operators, ERROR) are cloned unchanged so the unit spans still render.
RoundedPreview roundPreviewTokens(Tokens preview) {
  final out = Tokens();
  var wasRounded = false;
  for (final token in preview) {
    if (token.type != TokenType.number) {
      out.add(Token(token.type, token.value, token.strRepresentation));
      continue;
    }
    final result = _roundNumberText(token.strRepresentation);
    // Mark as rounded only when the displayed value is LOSSY (truncated), not
    // for cosmetic trailing-zero stripping (1.20 -> 1.2 is still exact).
    if (result.wasRounded) wasRounded = true;
    out.add(Token(TokenType.number, token.value, result.text));
  }
  return RoundedPreview(out, wasRounded: wasRounded);
}

/// A rounded NUMBER string plus whether the value was truncated (lossy).
class _RoundedNumber {
  const _RoundedNumber(this.text, {required this.wasRounded});
  final String text;
  final bool wasRounded;
}

/// Rounds a single decimal string to a readable preview form. Returns the
/// original verbatim (never lossy) when it is not a parseable decimal, is a
/// whole number, or already fits the precision budget.
_RoundedNumber _roundNumberText(String text) {
  final value = BigDecimal.tryParse(text);
  if (value == null) return _RoundedNumber(text, wasRounded: false);
  final stripped = value.stripTrailingZeros();
  // Whole numbers render plainly - not lossy (1E+1 has scale < 0 after
  // stripping; scale <= 0 means an integer value).
  if (stripped.scale <= 0) {
    return _RoundedNumber(stripped.toPlainString(), wasRounded: false);
  }
  // Keep N *significant* fraction digits, not N decimal places: count the
  // leading zeros right after the point so 0.0005518 keeps 0.0005518 (4 sig
  // figs) rather than collapsing to 0.0006.
  final frac = stripped.toPlainString().split('.')[1];
  var leadingZeros = 0;
  while (leadingZeros < frac.length && frac[leadingZeros] == '0') {
    leadingZeros++;
  }
  final targetScale =
      (leadingZeros + _kPreviewFractionSigDigits).clamp(0, _kPreviewMaxScale);
  if (stripped.scale <= targetScale) {
    // Already within budget; the stripped form is exact (only trailing zeros
    // dropped), so it is not lossy.
    return _RoundedNumber(stripped.toPlainString(), wasRounded: false);
  }
  final rounded =
      stripped.setScale(targetScale, RoundingMode.halfUp).stripTrailingZeros();
  return _RoundedNumber(
    rounded.toPlainString(),
    wasRounded: rounded.compareTo(stripped) != 0,
  );
}
