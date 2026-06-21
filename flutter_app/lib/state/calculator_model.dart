import 'package:flutter/foundation.dart';

import '../data/per_units.dart';
import '../data/repositories.dart';
import '../data/result_format.dart';
import '../data/result_formats.dart';
import '../engine/big_decimal.dart';
import '../engine/calculator_of_time.dart';
import '../engine/time_converter.dart';
import '../engine/token.dart';
import '../engine/token_type.dart';
import '../engine/tokens.dart';

/// Port of CalculatorViewModel: the single UI facade over the four process
/// singleton repositories.
///
/// The repositories expose their own [ValueListenable]s (expression, result
/// tokens, formats, per units); this model additionally notifies its own
/// listeners for the six booleans the RemoveADS branch keeps in its
/// process-scoped UtilityRepository singleton (four overlay visibility flags
/// and the Per/Formats button-disabled flags). Being a process singleton,
/// this model IS the UtilityRepository relocation: all of it survives
/// rebuilds, rotation and theme switches for the process lifetime.
///
/// Differences from the original (deliberate):
/// * evaluation is synchronous (no coroutine + cancelChildren; expressions
///   are tiny and Dart is single-threaded);
/// * [tempResultInMsec] lives next to the repositories for the process
///   lifetime, designing away the Android stale-cache-after-recreation bug;
/// * the Per crash guards from critic-gaps.md (zero/ERROR conversion treated
///   as 0 inside PerUnitsRepository; [updateSettingsForPerUnitsFromText]
///   try-parses the amount).
class CalculatorModel extends ChangeNotifier {
  CalculatorModel({
    ExpressionRepository? expressionRepository,
    TokensRepository? tokensRepository,
    ResultFormatsRepository? resultFormatsRepository,
    PerUnitsRepository? perUnitsRepository,
  }) : _expressionRepository =
           expressionRepository ?? ExpressionRepository.getInstance(),
       _tokensRepository = tokensRepository ?? TokensRepository.getInstance(),
       _resultFormatsRepository =
           resultFormatsRepository ?? ResultFormatsRepository.getInstance(),
       _perUnitsRepository =
           perUnitsRepository ?? PerUnitsRepository.getInstance() {
    // RemoveADS fix (branch: getResultTokens() side effect on re-subscribe):
    // both button-disabled flags are re-derived from result emptiness, so a
    // recreated UI never sees stale gating. Done here - in the constructor -
    // instead of inside a getter, avoiding the Kotlin
    // getter-with-side-effect smell the spec flags.
    _isPerViewButtonDisabled = isResultEmpty();
    _isFormatsViewButtonDisabled = isResultEmpty();
  }

  static CalculatorModel? _instance;

  /// Process-wide singleton used by the UI.
  static CalculatorModel get instance => _instance ??= CalculatorModel();

  final ExpressionRepository _expressionRepository;
  final TokensRepository _tokensRepository;
  final ResultFormatsRepository _resultFormatsRepository;
  final PerUnitsRepository _perUnitsRepository;

  /// Cache of the last CalculatorOfTime.evaluate output (normally
  /// `[NUMBER msec, MSECOND]`, or `[ERROR]`, or empty). All format previews,
  /// per-unit math and format switching read this cache, not the displayed
  /// result.
  Tokens tempResultInMsec = Tokens();

  bool _isFormatsLayoutVisible = false;
  bool _isPerLayoutVisible = false;
  bool _isSupportAppLayoutVisible = false;
  bool _isSettingsLayoutVisible = false;
  bool _isPerViewButtonDisabled = true;
  bool _isFormatsViewButtonDisabled = true;

  /// Whether the "Choose the result format" overlay is open.
  bool get isFormatsLayoutVisible => _isFormatsLayoutVisible;

  /// Whether the "Amount for the time interval" overlay is open.
  bool get isPerLayoutVisible => _isPerLayoutVisible;

  /// Whether the "The app development support" overlay is open (RemoveADS).
  bool get isSupportAppLayoutVisible => _isSupportAppLayoutVisible;

  /// Whether the "Settings" overlay is open (RemoveADS).
  bool get isSettingsLayoutVisible => _isSettingsLayoutVisible;

  /// Per button gating; starts disabled, enabled after any evaluation pass,
  /// disabled again by clear-all and equals.
  bool get isPerViewButtonDisabled => _isPerViewButtonDisabled;

  /// Formats button gating (RemoveADS: gated exactly like Per; master kept
  /// it always enabled).
  bool get isFormatsViewButtonDisabled => _isFormatsViewButtonDisabled;

  /// Whether a formatted result is currently displayed (drives the gating).
  bool isResultEmpty() => resultTokens.value.isEmpty;

  /// F1 (empty/invalid-result hint): whether to show the "Add a time unit"
  /// hint. True when the input is non-empty, contains NO time unit (pure
  /// arithmetic such as "5" or "5 x 3"), and there is no result. Such input
  /// never yields a result in this TIME calculator, so the hint explains why
  /// instead of leaving a new user staring at a blank result and assuming the
  /// app is broken. An expression that already has a unit - even an incomplete
  /// one like "2 Hour + 3" - is NOT flagged (it is a partial time expression,
  /// not the "missing unit" mistake), and neither is a blank input or a
  /// legitimate zero result ("0 Minutes").
  bool get shouldShowAddUnitHint =>
      expression.value.isNotEmpty &&
      expression.value.isSimpleArithmeticExpression() &&
      resultTokens.value.isEmpty;

  /// The INPUT expression tokens.
  ValueListenable<Tokens> get expression =>
      _expressionRepository.getExpression();

  /// The formatted RESULT tokens shown under the expression.
  ValueListenable<Tokens> get resultTokens => _tokensRepository.getTokens();

  /// The 24 selectable result formats (with live previews).
  ValueListenable<ResultFormats> get resultFormats =>
      _resultFormatsRepository.getResultFormats();

  /// The currently selected result format (non-null after seeding).
  ValueListenable<ResultFormat?> get selectedFormat =>
      _resultFormatsRepository.getSelectedFormat();

  /// The 8 per-unit rows plus shared amount/unitName/timeInterval.
  ValueListenable<PerUnits> get perUnits => _perUnitsRepository.getPerUnits();

  /// Keypad entry point: validates/merges [token] into the expression and
  /// re-evaluates when the repository says so.
  void addToExpression(Token token) {
    if (_expressionRepository.addToExpression(token)) {
      _evaluateExpression();
    }
  }

  /// Keypad entry point for the 8 time-unit keys (RemoveADS smart plural):
  /// the unit token inherits its value from the trailing NUMBER of the
  /// expression so it pluralizes ("12 Hours"); evaluation triggers exactly
  /// like [addToExpression].
  void addToExpressionTimeUnit(TokenType elementType) {
    if (_expressionRepository.addToExpressionTimeUnit(elementType)) {
      _evaluateExpression();
    }
  }

  /// Long-press-delete guard.
  bool isExpressionEmpty() => expression.value.isEmpty;

  /// Backspace: deletes one token/symbol and re-evaluates when needed.
  void clearOneLastSymbol() {
    if (_expressionRepository.deleteLastTokenOrSymbol()) {
      _evaluateExpression();
    }
  }

  /// Wipes both expression and result and disables the Per AND Formats
  /// buttons (long-press on delete, after the flash animation).
  void clearAll() {
    _tokensRepository.setTokens(Tokens());
    _expressionRepository.setTokens(Tokens());
    setIsPerViewButtonDisabled(true);
    setIsFormatsViewButtonDisabled(true);
  }

  /// "=" key: promotes the formatted result to be the new input expression
  /// (no evaluation occurs); result blanks and Per/Formats are disabled.
  void sendResultToExpression() {
    if (_tokensRepository.length() > 0) {
      _expressionRepository.setTokens(_tokensRepository.getTokens().value);
      _tokensRepository.setTokens(Tokens());
      setIsPerViewButtonDisabled(true);
      setIsFormatsViewButtonDisabled(true);
    }
  }

  /// Refreshes every format row's preview from [tempResultInMsec]
  /// (called before opening the Formats overlay).
  void updateResultFormats() =>
      _resultFormatsRepository.updateFormatsWithPreview(tempResultInMsec);

  /// Recomputes all per-unit rows from [tempResultInMsec] (no-op while the
  /// Per button is disabled; called before opening the Per overlay).
  void updatePerUnits() {
    if (!_isPerViewButtonDisabled) {
      _perUnitsRepository.updatePerUnitsWithPreview(tempResultInMsec);
    }
  }

  /// Live recomputation from the Per overlay text fields (no-op while the
  /// Per button is disabled). The timeInterval param is set to the currently
  /// displayed result tokens (display-only, parity).
  void updateSettingsForPerUnits(BigDecimal amount, String unitName) {
    if (_isPerViewButtonDisabled) return;
    _perUnitsRepository.setParams(
      amount,
      unitName,
      _tokensRepository.getTokens().value,
    );
    _perUnitsRepository.updatePerUnitsWithPreview(tempResultInMsec);
  }

  /// Crash-guarded bridge for the Per amount field (deliberate change from
  /// the original, which crashed on a lone "."): returns false - and changes
  /// nothing - when [amountText] is not a valid decimal.
  bool updateSettingsForPerUnitsFromText(String amountText, String unitName) {
    final amount = BigDecimal.tryParse(amountText);
    if (amount == null) return false;
    updateSettingsForPerUnits(amount, unitName);
    return true;
  }

  /// Selects the format at [position], re-renders the displayed result in
  /// the new format immediately, and closes the Formats overlay if open
  /// (the original did the closing via the selected-format observer).
  void setSelectedFormat(int position) {
    _resultFormatsRepository.setSelectedFormat(position);
    final selected = _resultFormatsRepository.getSelectedFormat().value!;
    _tokensRepository.setTokens(
      TimeConverter.convertTokensToTokensWithFormat(
        tempResultInMsec,
        selected.formatTokens,
      ),
    );
    if (_isFormatsLayoutVisible) setIsFormatsLayoutVisible(false);
  }

  /// Shows/hides the Formats overlay (state survives rebuilds/rotation).
  void setIsFormatsLayoutVisible(bool visible) {
    if (_isFormatsLayoutVisible == visible) return;
    _isFormatsLayoutVisible = visible;
    notifyListeners();
  }

  /// Shows/hides the Per overlay.
  void setIsPerLayoutVisible(bool visible) {
    if (_isPerLayoutVisible == visible) return;
    _isPerLayoutVisible = visible;
    notifyListeners();
  }

  /// Shows/hides the Support ("buy me cups of tea") overlay.
  void setIsSupportAppLayoutVisible(bool visible) {
    if (_isSupportAppLayoutVisible == visible) return;
    _isSupportAppLayoutVisible = visible;
    notifyListeners();
  }

  /// Shows/hides the Settings overlay.
  void setIsSettingsLayoutVisible(bool visible) {
    if (_isSettingsLayoutVisible == visible) return;
    _isSettingsLayoutVisible = visible;
    notifyListeners();
  }

  /// Enables/disables the Per button (alpha 0.2 + not clickable when
  /// disabled).
  void setIsPerViewButtonDisabled(bool disabled) {
    if (_isPerViewButtonDisabled == disabled) return;
    _isPerViewButtonDisabled = disabled;
    notifyListeners();
  }

  /// Enables/disables the Formats button (alpha 0.2 + not clickable when
  /// disabled).
  void setIsFormatsViewButtonDisabled(bool disabled) {
    if (_isFormatsViewButtonDisabled == disabled) return;
    _isFormatsViewButtonDisabled = disabled;
    notifyListeners();
  }

  /// The recalculation pipeline: evaluate the whole expression to
  /// milliseconds, convert to the selected format, publish, enable both the
  /// Per and (RemoveADS) Formats buttons.
  void _evaluateExpression() {
    final expression = _expressionRepository.getExpression().value;
    // An incomplete/malformed time expression - e.g. the "3 Hour 25" left by
    // deleting "Minute" from a result promoted to the input with "=" - has no
    // meaningful value: the bare "25" would be silently counted as 25 raw
    // milliseconds and rendered as "0.0004167 Minutes". Show NO result and keep
    // the Per/Formats buttons disabled instead of a nonsensical micro-amount.
    if (expression.hasDanglingUnitlessNumber()) {
      tempResultInMsec = Tokens();
      _tokensRepository.setTokens(Tokens());
      setIsPerViewButtonDisabled(true);
      setIsFormatsViewButtonDisabled(true);
      return;
    }
    tempResultInMsec = CalculatorOfTime.evaluate(expression);
    final selected = _resultFormatsRepository.getSelectedFormat().value!;
    _tokensRepository.setTokens(
      TimeConverter.convertTokensToTokensWithFormat(
        tempResultInMsec,
        selected.formatTokens,
      ),
    );
    setIsPerViewButtonDisabled(false);
    setIsFormatsViewButtonDisabled(false);
  }
}
