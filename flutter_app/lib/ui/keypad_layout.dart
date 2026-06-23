import '../engine/token_type.dart';

/// The kind of a keypad cell - drives both its colour/role and its tap action.
enum KeypadCellKind {
  digit,
  divide,
  multiply,
  plus,
  minus,
  backspace,
  equals,
  unit,
}

/// One abstract keypad cell, orientation-independent. A renderer maps it to an
/// interactive key (the real keypad) or a static cell (the Settings preview), so
/// both are guaranteed to use the SAME layout.
class KeypadCell {
  const KeypadCell(this.kind, {this.digit, this.unit});

  final KeypadCellKind kind;

  /// The glyph for [KeypadCellKind.digit] ('7'..'0', '.').
  final String? digit;

  /// The time unit for [KeypadCellKind.unit].
  final TokenType? unit;
}

/// Short display label for a unit key. The keypad shows "Msec" for the
/// millisecond key rather than the token's verbose "MSecond" value.
String keypadUnitLabel(TokenType unit) =>
    unit == TokenType.mSecond ? 'Msec' : unit.value;

const KeypadCell _d7 = KeypadCell(KeypadCellKind.digit, digit: '7');
const KeypadCell _d8 = KeypadCell(KeypadCellKind.digit, digit: '8');
const KeypadCell _d9 = KeypadCell(KeypadCellKind.digit, digit: '9');
const KeypadCell _d4 = KeypadCell(KeypadCellKind.digit, digit: '4');
const KeypadCell _d5 = KeypadCell(KeypadCellKind.digit, digit: '5');
const KeypadCell _d6 = KeypadCell(KeypadCellKind.digit, digit: '6');
const KeypadCell _d1 = KeypadCell(KeypadCellKind.digit, digit: '1');
const KeypadCell _d2 = KeypadCell(KeypadCellKind.digit, digit: '2');
const KeypadCell _d3 = KeypadCell(KeypadCellKind.digit, digit: '3');
const KeypadCell _d0 = KeypadCell(KeypadCellKind.digit, digit: '0');
const KeypadCell _dot = KeypadCell(KeypadCellKind.digit, digit: '.');
const KeypadCell _back = KeypadCell(KeypadCellKind.backspace);
const KeypadCell _div = KeypadCell(KeypadCellKind.divide);
const KeypadCell _mul = KeypadCell(KeypadCellKind.multiply);
const KeypadCell _plus = KeypadCell(KeypadCellKind.plus);
const KeypadCell _minus = KeypadCell(KeypadCellKind.minus);
const KeypadCell _equals = KeypadCell(KeypadCellKind.equals);

/// The fixed 4x4 number/operator block shared by BOTH orientations:
/// ```
/// 7 8 9 ⌫
/// 4 5 6 ÷
/// 1 2 3 ×
/// 0 . + −
/// ```
const List<List<KeypadCell>> keypadNumberBlock = <List<KeypadCell>>[
  <KeypadCell>[_d7, _d8, _d9, _back],
  <KeypadCell>[_d4, _d5, _d6, _div],
  <KeypadCell>[_d1, _d2, _d3, _mul],
  <KeypadCell>[_d0, _dot, _plus, _minus],
];

/// PORTRAIT compact layout: the number block rows, then the green unit band
/// (units in rows of up to 4) with "=" appended as the LAST cell of the LAST row
/// - so "=" is always the bottom-right key at operator width. Fewer units ->
/// fewer band rows -> shorter keypad.
List<List<KeypadCell>> portraitKeypadLayout(List<TokenType> units) {
  final rows = <List<KeypadCell>>[
    for (final r in keypadNumberBlock) List<KeypadCell>.of(r),
  ];
  for (var i = 0; i < units.length; i += 4) {
    final end = (i + 4 < units.length) ? i + 4 : units.length;
    rows.add(<KeypadCell>[
      for (final u in units.sublist(i, end))
        KeypadCell(KeypadCellKind.unit, unit: u),
      if (end >= units.length) _equals,
    ]);
  }
  return rows;
}

/// The number block + unit columns for the LANDSCAPE compact layout.
class LandscapeKeypadLayout {
  const LandscapeKeypadLayout(this.block, this.columns);

  /// The fixed 4x4 number/operator block (4 rows of 4).
  final List<List<KeypadCell>> block;

  /// The unit columns to the right (each a top-to-bottom list of cells). A
  /// partial last column has FEWER cells (the renderer stretches them); "=" is
  /// the last cell of the last column and never sits alone.
  final List<List<KeypadCell>> columns;
}

/// LANDSCAPE compact layout: units + "=" packed into columns of up to 4
/// (column-major). A partial last column keeps "=" company (a unit is pulled
/// down) so "=" is never stranded, and the renderer stretches a short column to
/// fill the height - no empty cells. Fewer units -> fewer columns -> narrower.
LandscapeKeypadLayout landscapeKeypadLayout(List<TokenType> units) {
  final cells = <KeypadCell>[
    for (final u in units) KeypadCell(KeypadCellKind.unit, unit: u),
    _equals,
  ];
  final columns = <List<KeypadCell>>[];
  for (var i = 0; i < cells.length; i += 4) {
    final end = (i + 4 < cells.length) ? i + 4 : cells.length;
    columns.add(cells.sublist(i, end));
  }
  // Never strand "=" alone in the last column: pull the previous column's last
  // unit down to share it.
  if (columns.length >= 2 && columns.last.length == 1) {
    columns.last.insert(0, columns[columns.length - 2].removeLast());
  }
  return LandscapeKeypadLayout(keypadNumberBlock, columns);
}
