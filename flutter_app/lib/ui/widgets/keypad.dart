import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../engine/big_decimal.dart';
import '../../engine/token.dart';
import '../../engine/token_type.dart';
import '../theme.dart';

/// Shared callbacks for both keypad layouts.
class KeypadCallbacks {
  const KeypadCallbacks({
    required this.onToken,
    required this.onUnit,
    required this.onEquals,
    required this.onBackspace,
    required this.onBackspaceLongPress,
  });

  final ValueChanged<Token> onToken;

  /// The 7 time-unit keys (RemoveADS: they dispatch by TokenType through
  /// CalculatorModel.addToExpressionTimeUnit so the unit token inherits the
  /// trailing NUMBER's value for smart pluralization). Msec is no longer
  /// typeable (its key was removed), but MSecond can still appear in results.
  final ValueChanged<TokenType> onUnit;

  final VoidCallback onEquals;

  /// Backspace: delete one trailing symbol (the keypad's bottom-right key, the
  /// ONLY delete control - tap deletes one symbol).
  final VoidCallback onBackspace;

  /// Long-press backspace: triggers the clear-flash (clear-all) animation. This
  /// is now the only clear-all, as in the original app.
  final VoidCallback onBackspaceLongPress;
}

/// The visual role of a key, which selects its tonal cell fill + glyph color
/// from [AppPalette] (Material 3 Expressive redesign):
/// * [digit] - neutral raised cell ([digitKeySurface]) with [nums] glyphs;
/// * [operator] - blue-tonal cell ([operatorKeyFill]/[operatorKeyText]) for
///   ÷ × + − , preserving the #0099CC operator identity as a tonal fill;
/// * [time] - green-tonal cell ([timeKeyFill]/[timeKeyText]) for the seven
///   Year..Second unit keys, preserving the green = time identity;
/// * [backspace] - blue-tonal cell (same fill as [operator]) for the backspace
///   delete key so it reads DISTINCTLY from the green time-unit keys (a delete
///   control, not a time unit) in its top-right grid slot;
/// * [equals] - green-tonal accent cell ([timeKeyFill]/[timeKeyText]) for the
///   "=" key now sitting in the operator column's BOTTOM-right corner. Using
///   the green time/result identity (the same accent as the result hero, the
///   format chip and the clear flash) reads as the COMPUTE/result action and
///   keeps it visually distinct from the blue ÷ × + − operators stacked above
///   it (a neutral digit "=" looked out of place wedged among the blue keys).
enum _KeyRole { digit, operator, time, backspace, equals }

/// One Material 3 Expressive keypad key: its own soft rounded tonal CELL.
///
/// Each key is a filled [Material] with [Dimens.keyCellRadius] corners and a
/// role-driven fill; the ink ripple is clipped inside the rounded cell. The
/// cell fills the slot it is given (the [Expanded] grid cell), so the rows
/// keep their flex-driven natural heights from the [Dimens] buckets while
/// gaining the tonal look. Gaps between cells are added by the row/column
/// builders (the ~8dp [Dimens.keyGap] grid).
///
/// A key may render a text [label] OR an [icon] glyph (the backspace key uses
/// the icon path). Both are wrapped in a FittedBox so they shrink-to-fit the
/// cell and never clip in either orientation.
class _KeypadKey extends StatelessWidget {
  const _KeypadKey({
    required this.role,
    required this.fontSize,
    this.label,
    this.icon,
    this.semanticLabel,
    this.minWidth,
    this.onLongPress,
    this.inkKey,
    required this.onTap,
  }) : assert(label != null || icon != null,
            'a key needs either a text label or an icon');

  /// Optional key on the inner [InkWell] - rides the backspace cell as a stable
  /// widget identity (the calculator passes its _deleteKey). The clear-flash
  /// reveal no longer measures it (the flash now originates from the result
  /// band inside the display card); it is kept only as the backspace cell's key.
  final GlobalKey? inkKey;

  final String? label;
  final IconData? icon;
  final String? semanticLabel;
  final _KeyRole role;
  final double fontSize;

  /// buttons_num_min_width: set on every key in land/sw600; portrait keys
  /// carry NO minWidth at all ("buttons fit to narrow screens").
  final double? minWidth;

  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);

    final (fill, glyph, weight) = switch (role) {
      _KeyRole.digit => (
          palette.digitKeySurface,
          palette.nums,
          FontWeight.w500,
        ),
      _KeyRole.operator => (
          palette.operatorKeyFill,
          palette.operatorKeyText,
          FontWeight.w600,
        ),
      _KeyRole.time => (
          palette.timeKeyFill,
          palette.timeKeyText,
          FontWeight.w600,
        ),
      // Backspace: the blue operator accent (fill + glyph), DISTINCT from the
      // neutral digits it sits beside in the top row, reading as a delete
      // control (it caps the blue operator column running down the right edge).
      _KeyRole.backspace => (
          palette.operatorKeyFill,
          palette.operatorKeyText,
          FontWeight.w600,
        ),
      // Equals: a SOLID green fill (vs the light-green TONAL time keys and the
      // blue-tonal operators), so the compute/commit key reads as a distinct,
      // prominent control - a different colour from every other key.
      _KeyRole.equals => (
          palette.equalsKeyFill,
          palette.equalsKeyText,
          FontWeight.w700,
        ),
    };
    final radius = BorderRadius.circular(dim.keyCellRadius);

    // Glyph size is PROPORTIONAL to the cell HEIGHT (a role-based fraction), so
    // a key and its text scale TOGETHER when the keypad is resized - no tiny
    // font marooned in a big button, no oversized font in a small one. It is
    // clamped between a readable FLOOR (so the smallest buttons never go
    // unreadably tiny) and a generous CAP (the bucket [fontSize]). A
    // FittedBox(scaleDown) then guards WIDTH so long unit words never clip.
    final double glyphFactor = switch (role) {
      _KeyRole.time => 0.42, // words - a bit smaller so they fit the cell width
      _ => 0.58, // single glyphs (digits / operators / = / backspace) fill more
    };
    // The font the smallest (minimal-height) cells settle at: when the keypad is
    // dragged short, cellH * glyphFactor drops below this and the glyph holds at
    // the floor. Raised (digits 17->20, words 13->15) to USE the spare vertical
    // room those small cells have - the FittedBox(scaleDown) below still caps the
    // glyph to the cell at the 24dp minimum, so a higher floor never clips.
    final double glyphFloor = switch (role) {
      _KeyRole.time => 15, // "Second" / "Minute" stay legible at min height
      _ => 20, // digits / operators / = / backspace
    };

    return Material(
      // The keypad card (drawn by calculator_screen) shows through the gaps;
      // each cell paints its own tonal fill here.
      color: fill,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: inkKey,
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: radius,
        child: LayoutBuilder(
          builder: (context, c) {
            final cellH = c.maxHeight.isFinite ? c.maxHeight : fontSize;
            final double fs = (cellH * glyphFactor)
                .clamp(glyphFloor, math.max(glyphFloor, fontSize * 1.5))
                .toDouble();
            final Widget glyphChild = icon != null
                // The icon box is ~1.2x its fontSize-equivalent so it tracks the
                // text line height.
                ? Icon(icon, size: fs * 1.2, color: glyph,
                    semanticLabel: semanticLabel)
                : Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    semanticsLabel: semanticLabel,
                    // height: 1.0 collapses the line box to the glyph's em size so
                    // a small cell's spare room becomes GLYPH, not leading - the
                    // raised glyphFloor then actually shows at minimal key height
                    // instead of being swallowed by the default ~1.25 line box.
                    // Safe: all key labels are single-line and descenderless
                    // (digits, operators, Year..Second), so the Center keeps them
                    // optically centred and the FittedBox still guards overflow.
                    style: TextStyle(
                        color: glyph,
                        fontSize: fs,
                        fontWeight: weight,
                        height: 1.0),
                  );
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth ?? 0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(fit: BoxFit.scaleDown, child: glyphChild),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Portrait phone keypad (RemoveADS layout/activity_main.xml) - 4 columns x
/// 6 rows. The Per/Support/Settings secondary tools moved to the top bar
/// (drawn by calculator_screen). There is NO separate utility row, NO AC and
/// NO Msec. The right column runs Backspace / ÷ / × / + / − / = top-to-bottom:
/// the Backspace delete key takes the TOP-right slot, the operator column
/// (÷ × + −) shifts DOWN one row to make room for it, and "=" sits in the
/// BOTTOM-right corner. The seven time units regroup with Year in the old "="
/// slot (Row4-col3), then Month/Week/Day on Row5 cols1-3 and Hour/Minute/Second
/// on Row6 cols1-3:
/// ```
/// 7     8      9      Backspace ⌫
/// 4     5      6      ÷
/// 1     2      3      ×
/// 0     .      Year   +
/// Month Week   Day    −
/// Hour  Minute Second =
/// ```
/// Every one of the SIX rows is an Expanded(flex:1) of EQUAL height; the
/// inter-row gaps are FIXED [Dimens.keyGap] spacers BETWEEN the rows so every
/// row is exactly as tall as the others.
class PortraitKeypad extends StatelessWidget {
  const PortraitKeypad({
    super.key,
    required this.callbacks,
    this.backspaceKey,
  });

  final KeypadCallbacks callbacks;

  /// Rides the backspace cell's ink as a stable widget identity (calculator
  /// _deleteKey). The clear-flash reveal no longer measures it - the flash now
  /// originates from the result band in the display card.
  final GlobalKey? backspaceKey;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    final k = _KeyFactory(
      dim,
      palette,
      callbacks,
      minWidth: null,
      backspaceKey: backspaceKey,
    );
    final gap = dim.keyGap;
    // UNIFORM equal-height grid: every one of the 6 rows is an Expanded(flex:1)
    // and the inter-row gaps are FIXED SizedBox spacers placed BETWEEN the rows
    // (not as a top inset inside the Expanded), so every row stays identical
    // height at any drag size. Right column top-to-bottom: Backspace, ÷, ×, +,
    // −, = (the Backspace delete key takes the TOP-right slot; the operator
    // column shifts down one row; "=" sits in the bottom-right corner). The
    // seven time units regroup: Year in the old "=" slot, then Month/Week/Day
    // and Hour/Minute/Second on the bottom two rows. No separate utility row,
    // no Msec, no AC.
    final rows = <List<Widget>>[
      [k.digit('7'), k.digit('8'), k.digit('9'), k.backspace()],
      [k.digit('4'), k.digit('5'), k.digit('6'), k.divide()],
      [k.digit('1'), k.digit('2'), k.digit('3'), k.multiply()],
      [k.digit('0'), k.dot(), k.unit(TokenType.year, 'Year'), k.plus()],
      [
        k.unit(TokenType.month, 'Month'),
        k.unit(TokenType.week, 'Week'),
        k.unit(TokenType.day, 'Day'),
        k.minus(),
      ],
      [
        k.unit(TokenType.hour, 'Hour'),
        k.unit(TokenType.minute, 'Minute'),
        k.unit(TokenType.second, 'Second'),
        k.equals(),
      ],
    ];
    return Material(
      color: Colors.transparent,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r != 0) SizedBox(height: gap),
            Expanded(child: _row(gap, rows[r])),
          ],
          // No internal bottom margin: the keypad card (drawn by
          // calculator_screen) owns the edge padding now.
        ],
      ),
    );
  }

  /// One row of equal-width cells separated by [gap] horizontally. The
  /// inter-ROW vertical [gap] is added by the build method as fixed SizedBox
  /// spacers between the Expanded rows, so every row stays equal height.
  Widget _row(double gap, List<Widget> keys) => Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i != 0) SizedBox(width: gap),
            Expanded(child: keys[i]),
          ],
        ],
      );
}

/// Land/sw600 keypad (layout-land/activity_main.xml ==
/// layout-sw600dp/activity_main.xml, byte-identical on the branch) - used by
/// phones in landscape AND by tablets in BOTH orientations. The Per/Support/
/// Settings secondary tools moved to the top bar, so the old 7th action-icon
/// column is gone. There is NO separate utility row (saving a row, as in
/// portrait): the single Backspace delete key takes the bottom-right slot
/// (where Msec used to be), and AC is gone. The grid is 6 columns x 4 rows:
/// ```
/// 7 8 9 divide   Hour   Minute
/// 4 5 6 multiply Second Day
/// 1 2 3 plus     Week   Month
/// 0 . = minus    Year   Backspace ⌫
/// ```
/// Every key carries minWidth buttons_num_min_width here (38sp land /
/// 48sp sw600). The four key rows are EQUAL height; no scroll, no overflow.
class LandscapeKeypad extends StatelessWidget {
  const LandscapeKeypad({
    super.key,
    required this.callbacks,
    this.backspaceKey,
  });

  final KeypadCallbacks callbacks;

  /// Rides the backspace cell's ink as a stable widget identity (calculator
  /// _deleteKey). The clear-flash reveal no longer measures it - the flash now
  /// originates from the result band in the display card.
  final GlobalKey? backspaceKey;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    final k = _KeyFactory(
      dim,
      palette,
      callbacks,
      minWidth: dim.buttonsNumMinWidth,
      backspaceKey: backspaceKey,
    );
    final gap = dim.keyGap;
    // ROW-MAJOR: the grid is built as 4 ROWS of 6 cells with FIXED gaps between
    // them - exactly the portrait rhythm. The 7 time units repack into the two
    // right columns (top-to-bottom), and the single Backspace delete key takes
    // the bottom-right slot (where Msec used to be). No utility row, no AC -
    // the four key rows are all EQUAL height.
    final keyRows = <List<Widget>>[
      [
        k.digit('7'),
        k.digit('8'),
        k.digit('9'),
        k.divide(),
        k.unit(TokenType.hour, 'Hour'),
        k.unit(TokenType.minute, 'Minute'),
      ],
      [
        k.digit('4'),
        k.digit('5'),
        k.digit('6'),
        k.multiply(),
        k.unit(TokenType.second, 'Second'),
        k.unit(TokenType.day, 'Day'),
      ],
      [
        k.digit('1'),
        k.digit('2'),
        k.digit('3'),
        k.plus(),
        k.unit(TokenType.week, 'Week'),
        k.unit(TokenType.month, 'Month'),
      ],
      [
        k.digit('0'),
        k.dot(),
        k.equals(),
        k.minus(),
        k.unit(TokenType.year, 'Year'),
        k.backspace(),
      ],
    ];
    return Material(
      // No internal edge margins: the keypad card (drawn by calculator_screen)
      // owns the surface padding. The grid fills the card width; the flex rows
      // fill the budgeted keypadHeight.
      color: Colors.transparent,
      child: Column(
        children: [
          for (var r = 0; r < keyRows.length; r++) ...[
            if (r != 0) SizedBox(height: gap),
            Expanded(child: _row(gap, keyRows[r])),
          ],
        ],
      ),
    );
  }

  /// One row of six equal-width cells separated by [gap] horizontally; the
  /// inter-ROW gaps are fixed spacers added by build between the Expanded rows,
  /// so every row stays equal height and the cells line up across columns.
  Widget _row(double gap, List<Widget> keys) => Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            if (i != 0) SizedBox(width: gap),
            Expanded(child: keys[i]),
          ],
        ],
      );
}

class _KeyFactory {
  _KeyFactory(
    this.dim,
    this.palette,
    this.callbacks, {
    required this.minWidth,
    this.backspaceKey,
  });

  final Dimens dim;
  final AppPalette palette;
  final KeypadCallbacks callbacks;
  final double? minWidth;
  final GlobalKey? backspaceKey;

  Widget _key(
    String label,
    _KeyRole role,
    double fontSize,
    VoidCallback onTap,
  ) =>
      _KeypadKey(
        label: label,
        role: role,
        fontSize: fontSize,
        minWidth: minWidth,
        onTap: onTap,
      );

  Widget digit(String d) => _key(
        d,
        _KeyRole.digit,
        dim.buttonsNumSize,
        // The digit's value is the digit itself (RemoveADS); informational
        // only - it is frozen at the first keypress, value consumers
        // re-parse the merged strRepresentation.
        () => callbacks.onToken(Token(TokenType.number, BigDecimal.parse(d), d)),
      );

  Widget dot() => _key(
        '.',
        _KeyRole.digit,
        dim.buttonsNumSize,
        () => callbacks.onToken(Token(TokenType.dot, BigDecimal.one)),
      );

  Widget equals() =>
      _key('=', _KeyRole.equals, dim.buttonsNumSize, callbacks.onEquals);

  // Operator KEYS use buttons_num_size on the branch; buttons_operators_size
  // is only a dead textSize attribute on the action-row ImageButtons.
  Widget _operator(TokenType type, String label) => _key(
        label,
        _KeyRole.operator,
        dim.buttonsNumSize,
        () => callbacks.onToken(Token(type, BigDecimal.one)),
      );

  Widget divide() => _operator(TokenType.divide, '÷');
  Widget multiply() => _operator(TokenType.multiply, '×');
  Widget plus() => _operator(TokenType.plus, '+');
  // EN DASH label (parity with the original button_substraction string).
  Widget minus() => _operator(TokenType.minus, '–');

  Widget unit(TokenType type, String label) => _key(
        label,
        _KeyRole.time,
        dim.buttonsTimeSize,
        () => callbacks.onUnit(type),
      );

  /// BACKSPACE delete key (bottom-right grid slot): the ONLY clear control.
  /// Tap deletes one trailing symbol; LONG-PRESS triggers the clear-flash
  /// (clear-all) animation, exactly as the original app's delete button did.
  /// Blue operator accent (distinct from the green time-unit keys it sits
  /// beside), an icon glyph (ic_backspace).
  Widget backspace() => _KeypadKey(
        icon: Icons.backspace,
        role: _KeyRole.backspace,
        fontSize: dim.buttonsNumSize,
        minWidth: minWidth,
        semanticLabel: 'Delete',
        inkKey: backspaceKey,
        onTap: callbacks.onBackspace,
        onLongPress: callbacks.onBackspaceLongPress,
      );
}
