import '../engine/big_decimal.dart';
import '../engine/token.dart';

/// One "amount per time unit" row. Port of Kotlin `PerUnit`
/// (data/perUnit/PerUnit.kt).
class PerUnit {
  PerUnit(this.timeUnit);

  /// The unit this row represents (e.g. an Hour token).
  final Token timeUnit;

  /// amount x (calculated interval expressed in [timeUnit]); recomputed by
  /// PerUnitsRepository.updatePerUnitsWithPreview. Original name:
  /// unitsPer_Result.
  BigDecimal unitsPerResult = BigDecimal.zero;
}
