import 'dart:collection';

import '../engine/big_decimal.dart';
import '../engine/tokens.dart';
import 'per_unit.dart';

/// A list of [PerUnit] rows plus the three shared parameters of the "Per"
/// feature. Port of Kotlin `PerUnits : ArrayList<PerUnit>`.
class PerUnits extends ListBase<PerUnit> {
  PerUnits(this.amount, this.unitName, this.timeInterval);

  /// The user-entered rate amount (e.g. 25).
  BigDecimal amount;

  /// The user-entered unit name (e.g. "USD").
  String unitName;

  /// The displayed interval tokens. NOTE: never used in the per-unit math
  /// (parity with the original); shown in UI copy only.
  Tokens timeInterval;

  final List<PerUnit> _perUnits = <PerUnit>[];

  @override
  int get length => _perUnits.length;

  @override
  set length(int newLength) => _perUnits.length = newLength;

  @override
  PerUnit operator [](int index) => _perUnits[index];

  @override
  void operator []=(int index, PerUnit value) => _perUnits[index] = value;

  @override
  void add(PerUnit element) => _perUnits.add(element);

  @override
  void addAll(Iterable<PerUnit> iterable) => _perUnits.addAll(iterable);
}
