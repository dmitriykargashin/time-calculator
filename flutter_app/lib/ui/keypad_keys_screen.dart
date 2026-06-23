import 'package:flutter/material.dart';

import '../engine/token_type.dart';
import '../state/settings_model.dart';
import 'formats_screen.dart' show overlayHeader;
import 'keypad_layout.dart';
import 'theme.dart';

/// Dedicated "Keypad keys" sub-screen (One UI style: a full page pushed from a
/// Settings row, not an inline section). It pairs the presets + per-unit chips
/// with a LIVE, WHOLE-KEYPAD preview that rebuilds as the selection changes, so
/// the user sees the actual (compact) keypad their choices produce.
///
/// The preview renders from the SAME shared [keypad_layout] the real keypad now
/// uses, so what you see here is exactly the calculator's keypad (portrait +
/// landscape). Fewer units make the keypad more compact; today that means TALLER
/// keys at the same keypad height (auto-growing the display is a separate,
/// deferred change).
class KeypadKeysScreen extends StatelessWidget {
  const KeypadKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.mainBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            overlayHeader(
              title: 'Keypad keys',
              onClose: () => Navigator.of(context).pop(),
              dim: dim,
              palette: palette,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: ListenableBuilder(
                  listenable: SettingsModel.instance,
                  builder: (context, _) {
                    final settings = SettingsModel.instance;
                    final active = settings.activeKeypadUnitPreset;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('PREVIEW', dim, palette),
                        _card(
                          palette,
                          dim,
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 360),
                                child: _KeypadPreviewCarousel(
                                    settings.enabledUnits),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: dim.margin16),
                        _label('PRESETS', dim, palette),
                        _card(
                          palette,
                          dim,
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final preset
                                    in SettingsModel.keypadUnitPresets)
                                  ChoiceChip(
                                    label: Text(preset.name),
                                    selected: active == preset,
                                    onSelected: (_) =>
                                        settings.applyKeypadUnitPreset(preset),
                                  ),
                                if (active == null)
                                  ChoiceChip(
                                    label: const Text('Custom'),
                                    selected: true,
                                    onSelected: (_) {},
                                  ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: dim.margin16),
                        _label('UNITS', dim, palette),
                        _card(
                          palette,
                          dim,
                          child: Padding(
                            padding:
                                const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final unit in SettingsModel.allKeypadUnits)
                                  FilterChip(
                                    label: Text(keypadUnitLabel(unit)),
                                    selected:
                                        settings.isKeypadUnitEnabled(unit),
                                    onSelected: (enabled) => settings
                                        .setKeypadUnitEnabled(unit, enabled),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Keep at least ${SettingsModel.minKeypadUnits} '
                            'unit keys.',
                            style: TextStyle(
                              color: palette.controls,
                              fontSize: dim.settingsGroupTextSize,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small-caps group label above a card (mirrors Settings' section labels).
  Widget _label(String text, Dimens dim, AppPalette palette) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
      child: Text(
        text,
        style: TextStyle(
          color: palette.controlsStrong,
          fontSize: dim.settingsGroupTextSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Rounded tonal card matching the Settings sections.
  Widget _card(AppPalette palette, Dimens dim, {required Widget child}) {
    return Material(
      color: palette.displayCardSurface,
      borderRadius: BorderRadius.circular(dim.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// The visual role of a preview cell (mirrors the real keypad's key roles).
enum _Role { digit, op, unit, equals, back, empty }

/// One preview key cell's visual (colour + glyph). The caller wraps it in an
/// [Expanded] (portrait, stretches in its row) or a fixed [SizedBox]
/// (landscape, sized so a FittedBox can scale the wide grid down).
Widget _cellBox(AppPalette palette, _Role role, {String? label}) {
  final (Color bg, Color fg, FontWeight weight) = switch (role) {
    _Role.digit => (palette.digitKeySurface, palette.nums, FontWeight.w500),
    _Role.op =>
      (palette.operatorKeyFill, palette.operatorKeyText, FontWeight.w600),
    _Role.back =>
      (palette.operatorKeyFill, palette.operatorKeyText, FontWeight.w600),
    _Role.unit => (palette.timeKeyFill, palette.timeKeyText, FontWeight.w600),
    _Role.equals =>
      (palette.equalsKeyFill, palette.equalsKeyText, FontWeight.w700),
    _Role.empty => (Colors.transparent, Colors.transparent, FontWeight.w400),
  };
  return Container(
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    alignment: Alignment.center,
    child: role == _Role.back
        ? Icon(Icons.backspace, color: fg, size: 16)
        : (role == _Role.empty || label == null)
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                        color: fg, fontWeight: weight, fontSize: 15),
                  ),
                ),
              ),
  );
}

/// Maps an abstract [KeypadCell] (from the shared [keypad_layout]) to a static
/// preview cell - so the preview uses the EXACT layout the real keypad does.
Widget _previewCell(AppPalette palette, KeypadCell c) => switch (c.kind) {
      KeypadCellKind.digit => _cellBox(palette, _Role.digit, label: c.digit),
      KeypadCellKind.divide => _cellBox(palette, _Role.op, label: '÷'),
      KeypadCellKind.multiply => _cellBox(palette, _Role.op, label: '×'),
      KeypadCellKind.plus => _cellBox(palette, _Role.op, label: '+'),
      KeypadCellKind.minus => _cellBox(palette, _Role.op, label: '–'),
      KeypadCellKind.backspace => _cellBox(palette, _Role.back),
      KeypadCellKind.equals => _cellBox(palette, _Role.equals, label: '='),
      KeypadCellKind.unit =>
        _cellBox(palette, _Role.unit, label: keypadUnitLabel(c.unit!)),
    };

/// Swipeable preview: page 0 = the PORTRAIT keypad, page 1 = the LANDSCAPE
/// keypad, both rendered live from the chosen [units]. A dot indicator + label
/// shows which orientation is on screen.
class _KeypadPreviewCarousel extends StatefulWidget {
  const _KeypadPreviewCarousel(this.units);

  final List<TokenType> units;

  @override
  State<_KeypadPreviewCarousel> createState() => _KeypadPreviewCarouselState();
}

class _KeypadPreviewCarouselState extends State<_KeypadPreviewCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    const labels = ['Portrait', 'Landscape'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 300,
          child: PageView(
            controller: _controller,
            onPageChanged: (p) => setState(() => _page = p),
            children: [
              // Fill the page width so the portrait rows' Expanded cells lay
              // out; centre vertically.
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [_PortraitKeypad(widget.units)],
              ),
              // The landscape grid is WIDE; scale it down to fit the card.
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _LandscapeKeypad(widget.units),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i != 0) const SizedBox(width: 7),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _page
                      ? palette.timeKeyText
                      : palette.controls.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          labels[_page],
          style: TextStyle(color: palette.controls, fontSize: 13),
        ),
      ],
    );
  }
}

/// Portrait compact keypad: the fixed number/operator block, then the green
/// unit band (4 per row) with "=" appended as the bottom-right cell of the last
/// row. Fewer units -> fewer band rows -> shorter keypad.
class _PortraitKeypad extends StatelessWidget {
  const _PortraitKeypad(this.units);

  final List<TokenType> units;

  static const double _rowH = 42;
  static const double _gap = 6;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    Widget row(List<KeypadCell> cells) => SizedBox(
          height: _rowH,
          child: Row(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i != 0) const SizedBox(width: _gap),
                Expanded(child: _previewCell(palette, cells[i])),
              ],
            ],
          ),
        );

    final rows = portraitKeypadLayout(units);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i != 0) const SizedBox(height: _gap),
          row(rows[i]),
        ],
      ],
    );
  }
}

/// Landscape compact keypad: a fixed 4x4 number/operator block on the left, and
/// the green unit keys stacked in columns to the right with "=" at the bottom.
///
/// A 4-row grid is only perfectly clean when (units + "=") is a multiple of 4,
/// so to avoid empty cells / a stranded "=" for every other count we: fill
/// complete columns, let a PARTIAL last column's cells STRETCH to fill the full
/// height, and never leave "=" alone in a column (a unit is pulled down to share
/// it). The result is always a filled rectangle. Fewer units -> fewer columns
/// -> a narrower keypad. Rendered at a fixed cell size so a FittedBox scales it.
class _LandscapeKeypad extends StatelessWidget {
  const _LandscapeKeypad(this.units);

  final List<TokenType> units;

  static const double _cellW = 44;
  static const double _cellH = 40;
  static const double _gap = 5;
  static const double _totalH = 4 * _cellH + 3 * _gap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final layout = landscapeKeypadLayout(units);

    final numberBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < layout.block.length; r++) ...[
          if (r != 0) const SizedBox(height: _gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var ci = 0; ci < layout.block[r].length; ci++) ...[
                if (ci != 0) const SizedBox(width: _gap),
                SizedBox(
                  width: _cellW,
                  height: _cellH,
                  child: _previewCell(palette, layout.block[r][ci]),
                ),
              ],
            ],
          ),
        ],
      ],
    );

    // A unit column fills the FULL height: cells stretch (Expanded) so a partial
    // column has fewer, taller cells instead of leaving empty space.
    Widget unitColumn(List<KeypadCell> col) => SizedBox(
          width: _cellW,
          height: _totalH,
          child: Column(
            children: [
              for (var i = 0; i < col.length; i++) ...[
                if (i != 0) const SizedBox(height: _gap),
                Expanded(child: _previewCell(palette, col[i])),
              ],
            ],
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        numberBlock,
        for (final col in layout.columns) ...[
          const SizedBox(width: _gap),
          unitColumn(col),
        ],
      ],
    );
  }
}
