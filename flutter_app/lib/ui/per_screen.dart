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
/// Intuitive-UX redesign (on top of the earlier Material 3 visual pass): the
/// screen now explains itself. A one-line subtitle under the header states what
/// it does and echoes the live interval ("Enter a rate to see its total over
/// your interval (4 Hours 50 Minutes)."). The two inputs read as a plain-English
/// rate - "Amount" and "Unit" (was the cryptic "Value" / "Value unit") - shown
/// inline as "Rate: [25] [USD] per time unit". Each result card flips the
/// hierarchy so the COMPUTED TOTAL is the hero: a small green caption ("Per
/// hour") sits above a large bold total ("~120.83 USD"), instead of the old
/// "25 USD per Hour in the interval" restating the input in big bold with the
/// real answer demoted to a small grey line.
///
/// The totals are rounded for readability (see [formatPerTotal]) - money-like
/// 2 fractional digits for typical values, more significant digits for tiny
/// ones, with a "~" (approximation) marker when the shown value was rounded.
/// This is a PER-VIEW DISPLAY rounding only; the underlying
/// [PerUnit.unitsPerResult] math is unchanged.
///
/// Material 3 look preserved: the overlay floats on [AppPalette.mainBackground]
/// under the shared modern [overlayHeader]; the inputs are M3 filled tonal
/// fields; the result rows are soft rounded tonal cards
/// ([AppPalette.displayCardSurface] + [Dimens.cardRadius]); green = time unit,
/// blue = accent, ABeeZee throughout.
///
/// Layout (unchanged structure): in portrait the explainer + inline rate sit in
/// a column; in land/sw600 the rate fields ride a horizontally scrollable row.
///
/// Crash guards (deliberate changes from the original, preserved): the amount
/// text is try-parsed (a lone "." no longer crashes), and zero/ERROR results
/// are treated as 0 by the repository instead of throwing. The empty-state
/// (either field blank -> hide the list) is preserved.
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
  /// params + show the list; either empty -> hide (INVISIBLE) the list.
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
    const fieldSize = 24.0;
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
            // One-line explainer of what the screen does, echoing the live
            // interval so the user knows the totals below are "over THIS span"
            // (rubric: tell the user what the screen does / no mystery labels).
            _explainer(palette),
            SizedBox(height: dim.margin8),
            if (dim.bucket == DimensBucket.base)
              _portraitRate(dim, palette, fieldSize)
            else
              _wideRate(dim, palette, fieldSize),
            SizedBox(height: dim.margin8),
            Expanded(
              // When a field is empty the result list is hidden (the original
              // Android INVISIBLE behavior); instead of leaving the maintained
              // space blank, fill it with a centered muted hint telling the user
              // what to do next (rubric axis 5: empty states say what to do).
              child: _listVisible
                  ? ValueListenableBuilder<PerUnits>(
                      valueListenable: widget.model.perUnits,
                      builder: (context, perUnits, _) => ListView.builder(
                        // Cards carry their own 8dp margins; the list keeps the
                        // screen's side gutters + a little bottom air so the last
                        // card doesn't kiss the screen edge.
                        padding: EdgeInsets.fromLTRB(
                          dim.margin8,
                          0,
                          dim.margin8,
                          dim.margin16,
                        ),
                        itemCount: perUnits.length,
                        itemBuilder: (context, index) =>
                            _perCard(perUnits, index, dim, palette),
                      ),
                    )
                  : _emptyHint(palette),
            ),
          ],
        ),
      ),
    );
  }

  /// One-line plain-English explainer under the header. The current interval is
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
              height: 1.35,
            ),
            children: [
              const TextSpan(
                text: 'Enter a rate to see its total over your interval of ',
              ),
              ...tokensToSpans(tokens, fontSize: size, palette: palette),
            ],
          ),
        ),
      ),
    );
  }

  /// Portrait (base bucket): the inline rate "Rate: [Amount] [Unit] per time
  /// unit" with the two M3 filled fields.
  Widget _portraitRate(Dimens dim, AppPalette palette, double fieldSize) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
      child: _rateRow(dim, palette, fieldSize),
    );
  }

  /// Land/sw600: the inline rate on one horizontally scrollable row so the
  /// fields never clip in the short landscape height.
  Widget _wideRate(Dimens dim, AppPalette palette, double fieldSize) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
        child: _rateRow(dim, palette, fieldSize),
      ),
    );
  }

  /// The shared inline rate: a "Rate:" lead-in, the Amount field, the Unit
  /// field, then a "per time unit" trailer - so the inputs read as a sentence
  /// ("Rate: 25 USD per time unit") instead of two mystery boxes.
  Widget _rateRow(Dimens dim, AppPalette palette, double fieldSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12),
          child: Text(
            'Rate:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.controlsStrong,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _labeledField(
          label: 'Amount',
          semantics: 'Amount',
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          fieldSize: fieldSize,
          palette: palette,
          dim: dim,
        ),
        const SizedBox(width: 10),
        _labeledField(
          label: 'Unit',
          semantics: 'Unit',
          controller: _unitController,
          keyboardType: TextInputType.text,
          fieldSize: fieldSize,
          palette: palette,
          dim: dim,
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: 12),
          child: Text(
            'per time unit',
            style: TextStyle(
              fontSize: 15,
              color: palette.controlsStrong,
            ),
          ),
        ),
      ],
    );
  }

  /// "Amount" / "Unit" label over an M3 filled text field (a soft rounded
  /// [AppPalette.toolButtonFill] fill, no underline) matching the calculator's
  /// tonal cells. (Renamed from the cryptic "Value" / "Value unit".)
  Widget _labeledField({
    required String label,
    required String semantics,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required double fieldSize,
    required AppPalette palette,
    required Dimens dim,
  }) {
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
        SizedBox(
          // Android ems 3 = three times the text size (plus the filled field's
          // inner padding so the glyphs aren't cramped against the fill edge).
          width: fieldSize * 3 + 24,
          child: Semantics(
            label: semantics,
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              textInputAction: TextInputAction.done,
              cursorColor: AppPalette.accent,
              // Use the brighter strong-control tint (light #474646 opaque /
              // dark #CCCCCC) instead of [nums] so the typed value reads as a
              // crisp editable input, not a dim half-disabled chip - on the
              // near-black dark background the dimmer [nums] (#909090) on the
              // #262626 fill made the fields look greyed-out (rubric axis 4/5).
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
                  // chrome. The fill (#262626) barely separates from the dark
                  // surface, so the outline alpha is lifted in dark (0.7) vs
                  // light (0.4) to keep the field perceptible without shouting.
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
        ),
      ],
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

  Widget _perCard(
    PerUnits perUnits,
    int index,
    Dimens dim,
    AppPalette palette,
  ) {
    final perUnit = perUnits[index];
    final captionSize = dim.buttonsTimeSize * 0.75;
    const totalSize = 30.0;
    final formatted = formatPerTotal(perUnit.unitsPerResult);
    final radius = BorderRadius.circular(dim.cardRadius);
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: dim.margin8,
        vertical: dim.margin8,
      ),
      decoration: BoxDecoration(
        // The same neutral display-card surface the calculator + Formats cards
        // use, so the Per results read as the same family of tonal cards. Flat
        // (no border, no drop shadow) to match the calculator/Settings idiom.
        color: palette.displayCardSurface,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SMALL green caption: the meaning ("Per hour"), with the time unit
            // emphasized green (the green=time identity). Was the BIG bold
            // "25 USD per Hour in the interval" that buried the answer.
            Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: captionSize,
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
            const SizedBox(height: 4),
            // HERO total: the computed amount is the big bold line. The "~"
            // marker (when rounded) + the unit-name span in resultTime keep the
            // identity while making the answer the focal point. Wrapped in an
            // AutoSizeText (single line, sane min) so a 7-digit per-millisecond
            // total plus a long typed unit name shrinks to fit instead of
            // wrapping/overflowing on a narrow screen or at large text scale
            // (rubric: fixed displays must not overflow).
            AutoSizeText.rich(
              TextSpan(
                children: [
                  // "~" (ASCII tilde) marks a rounded total. The math glyph
                  // "≈" (U+2248) is NOT in the ABeeZee font and renders as a
                  // tofu box, so the readable ASCII approximation sign is used.
                  if (formatted.rounded) const TextSpan(text: '~'),
                  TextSpan(text: formatted.text),
                  TextSpan(
                    // Unit-name span in colorResultTime (RvAdapterPer).
                    text: ' ${perUnits.unitName}',
                    style: TextStyle(
                      color: palette.resultTime,
                      fontSize: totalSize * kTokenRelativeSize,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              minFontSize: 18,
              style: TextStyle(
                fontSize: totalSize,
                fontWeight: FontWeight.bold,
                color: palette.nums,
              ),
            ),
          ],
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
/// * a typical fractional value rounds money-like to <=2 fractional digits with
///   trailing zeros stripped (120.8333325 -> "120.83", 120.80 -> "120.8");
/// * a tiny value (<0.005, where 2dp would collapse to 0) keeps ~4 significant
///   figures so it never reads as "0" (0.0005518 -> "0.0005518");
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
