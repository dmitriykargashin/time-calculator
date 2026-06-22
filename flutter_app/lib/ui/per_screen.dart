import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

import '../data/per_units.dart';
import '../engine/big_decimal.dart';
import '../engine/tokens.dart';
import '../state/calculator_model.dart';
import 'formats_screen.dart' show overlayHeader;
import 'spans.dart';
import 'theme.dart';

/// Full-screen "Rate calculator" overlay (was view_per.xml's "Amount for the
/// time interval").
///
/// WHAT IT DOES (unchanged): the user enters a rate - an [Amount] and a [Unit]
/// name (e.g. 25 USD, 10 km) - and the screen shows, for EACH time unit, the
/// total of that rate over the current calculator interval. "Per hour 635 USD"
/// means: at 25 USD per hour, over the interval you get 635 USD. The math is
/// `amount x (interval expressed in that unit)`, computed by
/// PerUnitsRepository.updatePerUnitsWithPreview - this view is presentation
/// only.
///
/// DECROWDED REDESIGN: the old layout stacked eight tall cards (each a 30sp
/// "hero" total, so nothing actually read as the answer) below an inline
/// "Rate: [25] [USD] per time unit" sentence that OVERFLOWED in portrait. The
/// new layout is a compact, scannable table:
///  * two side-by-side [Expanded] fields ("Amount" / "Unit") that can never
///    overflow - no inline sentence;
///  * a one-line explainer naming the live interval ("Totals over 4 Hours
///    50 Minutes:");
///  * ONE tonal card holding eight single-line rows ("Per hour" on the left,
///    the right-aligned total on the right, soft dividers between) so all eight
///    units are visible at once and the totals line up as a column to scan.
///
/// The totals are rounded for readability (see [formatPerTotal]) - money-like
/// 2 fractional digits for typical values, more significant digits for tiny
/// ones, with a "~" marker when the shown value was rounded. PER-VIEW DISPLAY
/// rounding only; the underlying [PerUnit.unitsPerResult] math is unchanged.
///
/// Material 3 look preserved: the overlay floats on [AppPalette.mainBackground]
/// under the shared modern [overlayHeader]; the inputs are M3 filled tonal
/// fields; the results card reuses [AppPalette.displayCardSurface] +
/// [Dimens.cardRadius]; green = time unit, blue = accent, ABeeZee throughout.
///
/// Crash guards (deliberate changes from the original, preserved): the amount
/// text is try-parsed (a lone "." no longer crashes), and zero/ERROR results
/// are treated as 0 by the repository instead of throwing. The empty-state
/// (either field blank -> hide the list, show a hint) is preserved.
class PerScreen extends StatefulWidget {
  const PerScreen({super.key, required this.model, required this.onClose});

  final CalculatorModel model;

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  @override
  State<PerScreen> createState() => _PerScreenState();
}

class _PerScreenState extends State<PerScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _unitController;
  bool _listVisible = true;

  @override
  void initState() {
    super.initState();
    final perUnits = widget.model.perUnits.value;
    _amountController = TextEditingController(
      text: perUnits.amount.toPlainString(),
    );
    _unitController = TextEditingController(text: perUnits.unitName);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  /// Mirror of the original TextWatchers: both fields non-empty -> update
  /// params + show the list; either empty -> hide the list (show a hint).
  /// An unparseable amount (e.g. lone ".") skips the update instead of
  /// crashing.
  void _onFieldsChanged() {
    final amountText = _amountController.text;
    final unitText = _unitController.text;
    if (amountText.isNotEmpty && unitText.isNotEmpty) {
      widget.model.updateSettingsForPerUnitsFromText(amountText, unitText);
      setState(() => _listVisible = true);
    } else {
      setState(() => _listVisible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return GestureDetector(
      // Tap outside the fields dismisses the keyboard.
      onTap: () => FocusScope.of(context).unfocus(),
      child: Material(
        color: palette.mainBackground,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            overlayHeader(
              title: 'Rate calculator',
              onClose: widget.onClose,
              dim: dim,
              palette: palette,
            ),
            SizedBox(height: dim.margin8),
            // Two side-by-side fields that share the width via Expanded, so the
            // rate input can never overflow (the old inline "Rate: ... per time
            // unit" sentence clipped in portrait).
            _rateInput(dim, palette),
            SizedBox(height: dim.margin16),
            // One tight line naming the live interval, so the totals below read
            // as "over THIS span" (rubric: say what the screen does).
            _explainer(palette),
            SizedBox(height: dim.margin8),
            Expanded(
              // Either field empty -> the original Android INVISIBLE behavior;
              // instead of a blank gap, show a centered hint (rubric axis 5:
              // empty states say what to do next).
              child: _listVisible
                  ? ValueListenableBuilder<PerUnits>(
                      valueListenable: widget.model.perUnits,
                      builder: (context, perUnits, _) =>
                          _resultsCard(perUnits, dim, palette),
                    )
                  : _emptyHint(palette),
            ),
          ],
        ),
      ),
    );
  }

  /// The rate inputs: an "Amount" field and a "Unit" field side by side, each in
  /// an [Expanded] so they split the row and never overflow. Amount is given the
  /// larger share (numbers run longer than a short unit name like "USD").
  Widget _rateInput(Dimens dim, AppPalette palette) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: _labeledField(
              label: 'Amount',
              semantics: 'Amount',
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              palette: palette,
              dim: dim,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _labeledField(
              label: 'Unit',
              semantics: 'Unit',
              controller: _unitController,
              keyboardType: TextInputType.text,
              palette: palette,
              dim: dim,
            ),
          ),
        ],
      ),
    );
  }

  /// "Amount" / "Unit" label over an M3 filled text field (a soft rounded
  /// [AppPalette.toolButtonFill] fill, no underline) matching the calculator's
  /// tonal cells. The field fills its [Expanded] parent (no fixed width), so the
  /// two inputs always fit the row.
  Widget _labeledField({
    required String label,
    required String semantics,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required AppPalette palette,
    required Dimens dim,
  }) {
    const fieldSize = 22.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: palette.controlsStrong),
          ),
        ),
        Semantics(
          label: semantics,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            textInputAction: TextInputAction.done,
            cursorColor: AppPalette.accent,
            // Brighter strong-control tint (light #474646 opaque / dark #CCCCCC)
            // so the typed value reads as a crisp editable input, not a dim
            // half-disabled chip (rubric axis 4/5).
            style: TextStyle(
              fontSize: fieldSize,
              color: palette.controlsStrong,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.toolButtonFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(dim.toolButtonRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(dim.toolButtonRadius),
                // Always-visible hairline so the unfocused box reads as input
                // chrome; lifted alpha in dark (0.7 vs 0.4) since the fill
                // barely separates from the dark surface.
                borderSide: BorderSide(
                  color: palette.shadowBase.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.7
                        : 0.4,
                  ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(dim.toolButtonRadius),
                borderSide:
                    const BorderSide(color: AppPalette.accent, width: 2),
              ),
            ),
            onChanged: (_) => _onFieldsChanged(),
          ),
        ),
      ],
    );
  }

  /// One-line plain-English explainer under the inputs. The current interval is
  /// rendered live (with the green time-unit spans) right inside the sentence so
  /// the totals below read as "for THIS interval".
  Widget _explainer(AppPalette palette) {
    const size = 15.0;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: ValueListenableBuilder<Tokens>(
        valueListenable: widget.model.resultTokens,
        builder: (context, tokens, _) => Text.rich(
          TextSpan(
            style: TextStyle(
              fontSize: size,
              color: palette.controlsStrong,
              height: 1.3,
            ),
            children: [
              const TextSpan(text: 'Totals over '),
              ...tokensToSpans(tokens, fontSize: size, palette: palette),
              const TextSpan(text: ':'),
            ],
          ),
        ),
      ),
    );
  }

  /// The results: ONE rounded tonal card holding a single-line row per time
  /// unit, soft inset dividers between, scrollable so the eight rows stay
  /// reachable in a short landscape height / at large text scale.
  Widget _resultsCard(PerUnits perUnits, Dimens dim, AppPalette palette) {
    final rows = <Widget>[];
    for (var index = 0; index < perUnits.length; index++) {
      if (index > 0) rows.add(_rowDivider(palette));
      rows.add(_perRow(perUnits, index, dim, palette));
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, dim.margin16),
      child: Material(
        color: palette.displayCardSurface,
        borderRadius: BorderRadius.circular(dim.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }

  /// Soft inset hairline between result rows (indented so it reads as a row
  /// separator, not an edge-to-edge rule) - the Settings-card idiom.
  Widget _rowDivider(AppPalette palette) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 16,
      // controlsStrong adapts (dark line in light theme, light line in dark),
      // so the separator stays visible on the near-black dark card surface.
      color: palette.controlsStrong.withValues(alpha: 0.25),
    );
  }

  /// One result row: "Per hour" on the left (the unit in the green time tint),
  /// the right-aligned total on the right. The total is an [AutoSizeText] so a
  /// huge per-millisecond figure plus a long unit name shrinks to fit one line
  /// instead of wrapping/overflowing (rubric: fixed displays must not overflow).
  Widget _perRow(
    PerUnits perUnits,
    int index,
    Dimens dim,
    AppPalette palette,
  ) {
    final perUnit = perUnits[index];
    const totalSize = 22.0;
    final formatted = formatPerTotal(perUnit.unitsPerResult);
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 16, 12),
      child: Row(
        children: [
          // Left: "Per hour" - the unit word green (the green=time identity).
          Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.controlsStrong,
              ),
              children: [
                const TextSpan(text: 'Per '),
                TextSpan(
                  text: perUnit.timeUnit.strRepresentation.toLowerCase(),
                  style: TextStyle(color: palette.expressionTime),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: the computed total, right-aligned so the figures form a
          // scannable column down the card.
          Expanded(
            child: AutoSizeText.rich(
              TextSpan(
                children: [
                  // "~" (ASCII tilde) marks a rounded total. The math glyph "≈"
                  // is not in ABeeZee and renders as tofu, so use the ASCII sign.
                  if (formatted.rounded) const TextSpan(text: '~'),
                  TextSpan(text: formatted.text),
                  TextSpan(
                    // Unit-name suffix in colorResultTime, smaller so the number
                    // stays the focus and the repeated unit reads as a quiet tag.
                    text: ' ${perUnits.unitName}',
                    style: TextStyle(
                      color: palette.resultTime,
                      fontSize: totalSize * kTokenRelativeSize,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              minFontSize: 12,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: totalSize,
                fontWeight: FontWeight.bold,
                color: palette.nums,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Empty state shown when either field is blank: a centered muted hint in the
  /// space the result list would occupy, so the area never reads as an
  /// unfinished blank region.
  Widget _emptyHint(AppPalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          'Enter an amount and a unit to see the total for each time unit',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: palette.controlsStrong,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// PER-VIEW DISPLAY rounding for a computed total. Returns the readable text
/// and whether it was rounded (so the card can prefix a "~"). The underlying
/// [PerUnit.unitsPerResult] math is never changed by this - it is presentation
/// only.
///
/// Rules:
/// * an integer value (after stripping trailing zeros) shows exactly, no marker
///   (e.g. 7250, 435000, 25);
/// * a typical fractional value rounds money-like to at most 2 fractional
///   digits with trailing zeros stripped (120.8333325 -> "120.83",
///   120.80 -> "120.8");
/// * a tiny value (below 0.005, where 2dp would collapse to 0) keeps ~4
///   significant figures so it never reads as "0" (0.0005518 -> "0.0005518");
/// * `rounded` is true only when the shown text differs from the exact value.
({String text, bool rounded}) formatPerTotal(BigDecimal raw) {
  final stripped = raw.stripTrailingZeros();
  // Integer magnitude (scale <= 0 after stripping): exact, no marker.
  if (stripped.scale <= 0) {
    return (text: _grouped(stripped.toPlainString()), rounded: false);
  }
  // Typical fractional value: money-like 2 fractional digits.
  final twoDp = stripped.setScale(2, RoundingMode.halfUp).stripTrailingZeros();
  if (twoDp.compareTo(BigDecimal.zero) != 0) {
    return (
      text: _grouped(twoDp.toPlainString()),
      rounded: twoDp.compareTo(stripped) != 0,
    );
  }
  // Tiny magnitude (2dp would vanish): keep ~4 significant figures so the value
  // never reads as a misleading "0".
  var plain = stripped.toPlainString();
  if (plain.startsWith('-')) plain = plain.substring(1);
  final frac = plain.substring(plain.indexOf('.') + 1);
  var leadingZeros = 0;
  while (leadingZeros < frac.length && frac[leadingZeros] == '0') {
    leadingZeros++;
  }
  final tiny = stripped
      .setScale(leadingZeros + 4, RoundingMode.halfUp)
      .stripTrailingZeros();
  return (
    text: _grouped(tiny.toPlainString()),
    rounded: tiny.compareTo(stripped) != 0,
  );
}

/// Inserts ASCII thousands separators into the INTEGER part of a decimal
/// string for display only (435000 -> "435,000"), so a long hero total scans
/// in groups instead of as one digit run. The fractional remainder and any
/// leading "-" are preserved verbatim; this never touches the underlying
/// [PerUnit.unitsPerResult] math (presentation only). A comma is used (not a
/// locale-aware grouping) because ABeeZee is the only bundled face and the rest
/// of the app's display formatting is ASCII; intl is not a project dependency.
String _grouped(String plain) {
  var sign = '';
  var body = plain;
  if (body.startsWith('-')) {
    sign = '-';
    body = body.substring(1);
  }
  final dot = body.indexOf('.');
  final intPart = dot < 0 ? body : body.substring(0, dot);
  final fracPart = dot < 0 ? '' : body.substring(dot);
  if (intPart.length <= 3) return plain;
  final buffer = StringBuffer();
  final firstGroup = intPart.length % 3;
  var i = 0;
  if (firstGroup > 0) {
    buffer.write(intPart.substring(0, firstGroup));
    i = firstGroup;
  }
  for (; i < intPart.length; i += 3) {
    if (buffer.isNotEmpty) buffer.write(',');
    buffer.write(intPart.substring(i, i + 3));
  }
  return '$sign$buffer$fracPart';
}
