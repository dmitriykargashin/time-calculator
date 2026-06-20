import '../engine/tokens.dart';

/// One selectable output format. Port of Kotlin `ResultFormat`
/// (data/resultFormat/ResultFormat.kt).
class ResultFormat {
  /// [exactlyTextPresentationOfTokens] overrides the display label, which
  /// otherwise defaults to `formatTokens.toStringWithSpaces()` (used only by
  /// the "All Units" format).
  ResultFormat(
    this.formatTokens,
    this.convertedResultTokens, [
    String? exactlyTextPresentationOfTokens,
  ]) : textPresentationOfTokens =
            exactlyTextPresentationOfTokens ?? formatTokens.toStringWithSpaces();

  /// The ordered unit tokens of the format (e.g. "Hour Minute").
  final Tokens formatTokens;

  /// The current result rendered in this format (preview row content);
  /// replaced by ResultFormatsRepository.updateFormatsWithPreview.
  Tokens convertedResultTokens;

  /// Single-selection flag managed by ResultFormats.setSelection.
  bool isSelected = false;

  /// Display label (e.g. "Hour Minute", "All Units").
  String textPresentationOfTokens;
}
