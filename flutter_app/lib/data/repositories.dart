/// In-memory singleton repositories. Port of the Kotlin data/repository
/// package; Android LiveData is replaced by [LiveData], a ChangeNotifier
/// that - like Android's - notifies on EVERY assignment, even when the same
/// (mutated-in-place) list instance is re-assigned. Nothing is persisted.
///
/// This is the only data-layer file that imports Flutter; everything under
/// lib/engine/ is pure Dart.
library;

import 'package:flutter/foundation.dart';

import '../engine/big_decimal.dart';
import '../engine/check_errors_in_expression.dart';
import '../engine/lexical_analyzer.dart';
import '../engine/time_converter.dart';
import '../engine/token.dart';
import '../engine/token_type.dart';
import '../engine/tokens.dart';
import 'per_unit.dart';
import 'per_units.dart';
import 'result_format.dart';
import 'result_formats.dart';

/// Minimal stand-in for Android's MutableLiveData: a [ValueListenable] whose
/// setter always notifies (Android LiveData notifies unconditionally on
/// setValue; Flutter's ValueNotifier would skip identical instances).
class LiveData<T> extends ChangeNotifier implements ValueListenable<T> {
  LiveData(this._value);

  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  /// Kotlin parity alias; Dart is single-threaded, so this is synchronous.
  void postValue(T newValue) => value = newValue;
}

/// Holds the RESULT tokens (the formatted result shown under the expression).
/// Port of TokensRepository.kt.
class TokensRepository {
  TokensRepository();

  Tokens _tokensList = Tokens();
  late final LiveData<Tokens> _tokens = LiveData<Tokens>(_tokensList);

  /// Appends [token] and republishes (no production UI caller; kept for
  /// parity).
  void addToken(Token token) {
    _tokensList.add(token);
    _tokens.value = _tokensList;
  }

  /// Number of result tokens.
  int length() => _tokensList.length;

  /// True when no result tokens are held (RemoveADS addition; trivial).
  bool isEmpty() => length() == 0;

  /// Observable result tokens.
  ValueListenable<Tokens> getTokens() => _tokens;

  /// Replaces the backing list and republishes.
  void setTokens(Tokens newTokens) {
    _tokensList = newTokens;
    _tokens.postValue(_tokensList);
  }

  static TokensRepository? _instance;

  /// Process-wide singleton accessor.
  static TokensRepository getInstance() => _instance ??= TokensRepository();
}

/// Holds the INPUT expression tokens and all append/delete editing logic.
/// Port of ExpressionRepository.kt.
class ExpressionRepository {
  ExpressionRepository();

  Tokens _tokensList = Tokens();
  late final LiveData<Tokens> _tokens = LiveData<Tokens>(_tokensList);

  /// Validates/merges [tokenForAdd] into the expression. The return value
  /// means "the caller must (re)evaluate the expression now":
  /// * operators: validated append, always returns false;
  /// * DOT merging into a trailing NUMBER: returns false;
  /// * digits merging into (or starting) a NUMBER: returns the
  ///   "live multiply/divide" condition (last block has a time keyword and
  ///   the digits are the operand right after a multiply/divide);
  /// * time keywords: returns whether the token was legally appended.
  bool addToExpression(Token tokenForAdd) {
    switch (tokenForAdd.type) {
      case TokenType.plus:
      case TokenType.minus:
      case TokenType.divide:
      case TokenType.multiply:
        _tryToAddToExpression(tokenForAdd);
        return false; // When we add operators we don't need to evaluate.
      default:
        break;
    }

    Token? lastToken;
    if (_tokensList.isNotEmpty) lastToken = _tokensList.last;

    // Snapshots taken BEFORE any add (parity with the original, including
    // its inconsistent-snapshot quirk).
    final lastOperator = _tokensList.findLastNearestOperatorToken();
    final tokenBeforeLastOperator =
        _tokensList.findTokenBeforeLastNearestOperatorToken();
    final lastTokenBeforeTokenBeforeLastOperator =
        _tokensList.findTokenBeforeTokenBeforeLastNearestOperatorToken();

    bool isLiveMultiplyDivide() {
      final operatorIsMulDiv = lastOperator != null &&
          (lastOperator.type == TokenType.divide ||
              lastOperator.type == TokenType.multiply);
      return (operatorIsMulDiv &&
              tokenBeforeLastOperator != null &&
              tokenBeforeLastOperator.type != TokenType.number) ||
          (operatorIsMulDiv &&
              tokenBeforeLastOperator != null &&
              tokenBeforeLastOperator.type == TokenType.number &&
              lastTokenBeforeTokenBeforeLastOperator != null &&
              (lastTokenBeforeTokenBeforeLastOperator.type ==
                      TokenType.divide ||
                  lastTokenBeforeTokenBeforeLastOperator.type ==
                      TokenType.multiply));
    }

    if (tokenForAdd.type == TokenType.dot ||
        tokenForAdd.type == TokenType.number) {
      if (lastToken != null && lastToken.type == TokenType.number) {
        if (tokenForAdd.type == TokenType.dot) {
          _tokensList.last.addDotToNumber();
          _tokens.value = _tokensList;
          return false;
        } else {
          _tokensList.last.mergeNumberToNumber(tokenForAdd);
          _tokens.value = _tokensList;
          return _tokensList.isLastExpressionBlockHasTimeKeyword() &&
              isLiveMultiplyDivide();
        }
      } else {
        _tryToAddToExpression(tokenForAdd); // Result ignored (parity).
        return _tokensList.isLastExpressionBlockHasTimeKeyword() &&
            isLiveMultiplyDivide();
      }
    } else {
      return _tryToAddToExpression(tokenForAdd);
    }
  }

  /// RemoveADS smart plural: the 8 unit keys come through here so the unit
  /// token inherits its value from the trailing NUMBER token of the
  /// expression (else 1) and pluralizes accordingly ("12" + Hour -> "12
  /// Hours"). Validation/evaluation-trigger logic is [addToExpression]'s,
  /// unchanged.
  bool addToExpressionTimeUnit(TokenType elementType) {
    var tokenValue = BigDecimal.one;
    if (_tokensList.isNotEmpty && _tokensList.last.type == TokenType.number) {
      // DELIBERATE FIX vs the branch: derive the value from the NUMBER's
      // CURRENT strRepresentation (fallback 1). The branch read the frozen
      // `value` field, which is set at the FIRST keypress and never updated
      // by mergeNumberToNumber/deleteOneLastSymbolInNumber, so typing
      // "1","2",Hour rendered the singular "12 Hour".
      tokenValue = BigDecimal.tryParse(_tokensList.last.strRepresentation) ??
          BigDecimal.one;
    }
    return addToExpression(Token(elementType, tokenValue));
  }

  bool _tryToAddToExpression(Token tokenForAdd) {
    if (!isErrorsInExpression(tokenForAdd, _tokensList)) {
      _tokensList.add(tokenForAdd);
      _tokens.value = _tokensList;
      return true;
    }
    return false; // Invalid keystrokes are silently dropped.
  }

  /// Observable expression tokens.
  ValueListenable<Tokens> getExpression() => _tokens;

  /// Replaces the backing list and republishes.
  void setTokens(Tokens newTokens) {
    _tokensList = newTokens;
    _tokens.postValue(_tokensList);
  }

  /// Backspace: removes the whole last token when it is not a NUMBER,
  /// otherwise drops one character from the NUMBER (removing it when it
  /// becomes empty). Returns "the caller must re-evaluate now": true iff the
  /// remaining last block still has a time keyword OR the new last token is
  /// not a NUMBER; false on an empty expression.
  bool deleteLastTokenOrSymbol() {
    Token? lastToken;
    if (_tokensList.isNotEmpty) lastToken = _tokensList.last;
    if (lastToken == null) return false;

    if (lastToken.type != TokenType.number) {
      _tokensList.removeLastToken();
    } else {
      lastToken.deleteOneLastSymbolInNumber();
      if (lastToken.strRepresentation == '') _tokensList.removeLastToken();
    }
    _tokens.value = _tokensList;

    Token? newLastToken;
    if (_tokensList.isNotEmpty) newLastToken = _tokensList.last;
    return _tokensList.isLastExpressionBlockHasTimeKeyword() ||
        (newLastToken != null && newLastToken.type != TokenType.number);
  }

  static ExpressionRepository? _instance;

  /// Process-wide singleton accessor.
  static ExpressionRepository getInstance() =>
      _instance ??= ExpressionRepository();
}

/// Holds the 26 selectable output formats (RemoveADS: "Year Month Day Minute"
/// became "Year Month Day Hour" at 0-based index 3, and "Year Month Day Hour
/// Minute" was inserted at index 4; later "Hour Minute Second MSecond" and a
/// milliseconds-only "MSecond" were added AFTER index 18). Port of
/// ResultFormatsRepository.kt. Use [getInstance]: it seeds the default formats
/// exactly once, with "Hour Minute" (0-based index 18) selected; a directly
/// constructed instance is empty.
class ResultFormatsRepository {
  ResultFormatsRepository();

  ResultFormats _resultFormatsList = ResultFormats();
  late final LiveData<ResultFormats> _resultFormats =
      LiveData<ResultFormats>(_resultFormatsList);
  final LiveData<ResultFormat?> _selectedResultFormats =
      LiveData<ResultFormat?>(null);

  /// Appends [resultFormat], republishes, and returns it (allows
  /// `addResultFormat(...).isSelected = true` chaining).
  ResultFormat addResultFormat(ResultFormat resultFormat) {
    _resultFormatsList.add(resultFormat);
    _resultFormats.value = _resultFormatsList;
    return resultFormat;
  }

  /// Number of formats (24 after seeding).
  int length() => _resultFormatsList.length;

  /// Observable list of formats.
  ValueListenable<ResultFormats> getResultFormats() => _resultFormats;

  /// Observable currently selected format (null only before seeding).
  ValueListenable<ResultFormat?> getSelectedFormat() => _selectedResultFormats;

  /// Selects the format at [position] (clearing all other isSelected flags),
  /// publishes and returns the selected-format listenable. Does NOT
  /// republish the formats list (parity with the original).
  ValueListenable<ResultFormat?> setSelectedFormat(int position) {
    _selectedResultFormats.value = _resultFormatsList.setSelection(position);
    return _selectedResultFormats;
  }

  /// Recomputes every format's convertedResultTokens preview from
  /// [resultTokens] (the cached `[NUMBER msec, MSECOND]` engine result) and
  /// republishes the list.
  void updateFormatsWithPreview(Tokens resultTokens) {
    for (final resultFormatElement in _resultFormatsList) {
      resultFormatElement.convertedResultTokens =
          TimeConverter.convertTokensToTokensWithFormat(
        resultTokens,
        resultFormatElement.formatTokens,
      );
    }
    _resultFormats.value = _resultFormatsList;
  }

  /// Replaces the whole list and republishes (no production caller; parity).
  void setTokens(ResultFormats newResultFormats) {
    _resultFormatsList = newResultFormats;
    _resultFormats.postValue(_resultFormatsList);
  }

  void _fillRepository() {
    addResultFormat(ResultFormat('Year'.toTokens(), '1 Year'.toTokens()));
    addResultFormat(
        ResultFormat('Year Month'.toTokens(), '1 Year 2 Month'.toTokens()));
    addResultFormat(ResultFormat(
        'Year Month Day'.toTokens(), '1 Year 2 Month 3 Day'.toTokens()));
    // RemoveADS: "Year Month Day Minute" replaced by "Year Month Day Hour"
    // (index 3) plus the NEW "Year Month Day Hour Minute" (index 4).
    addResultFormat(ResultFormat('Year Month Day Hour'.toTokens(),
        '1 Year 2 Month 3 Day 4 Hour'.toTokens()));
    addResultFormat(ResultFormat('Year Month Day Hour Minute'.toTokens(),
        '1 Year 2 Month 3 Day 4 Hour 5 Minute'.toTokens()));

    addResultFormat(ResultFormat('Month'.toTokens(), '1 Month'.toTokens()));
    // Quirk parity: this preview has no numbers in the original.
    addResultFormat(
        ResultFormat('Month Day'.toTokens(), 'Month Day'.toTokens()));
    addResultFormat(ResultFormat(
        'Month Day Hour'.toTokens(), '1 Month 2 Day 3 Hour'.toTokens()));
    addResultFormat(ResultFormat('Month Day Hour Minute'.toTokens(),
        '1 Month 2 Day 3 Hour 4 Minute'.toTokens()));
    addResultFormat(ResultFormat('Month Day Hour Minute Second'.toTokens(),
        '1 Month 2 Day 3 Hour 4 Minute 5 Second'.toTokens()));
    addResultFormat(
        ResultFormat('Month Week'.toTokens(), '1 Month 2 Week'.toTokens()));

    addResultFormat(ResultFormat('Week'.toTokens(), '1 Week'.toTokens()));
    addResultFormat(
        ResultFormat('Week Day'.toTokens(), '1 Week 2 Day'.toTokens()));

    addResultFormat(ResultFormat('Day'.toTokens(), '1 Day'.toTokens()));
    // Quirk parity: "1 Day 1 Hour" (not "1 Day 2 Hour") in the original.
    addResultFormat(
        ResultFormat('Day Hour'.toTokens(), '1 Day 1 Hour'.toTokens()));
    addResultFormat(ResultFormat(
        'Day Hour Minute'.toTokens(), '1 Day 2 Hour 3 Minute'.toTokens()));
    addResultFormat(ResultFormat('Day Hour Minute Second'.toTokens(),
        '1 Day 2 Hour 3 Minute 4 Second'.toTokens()));

    addResultFormat(ResultFormat('Hour'.toTokens(), '1 Hour'.toTokens()));
    addResultFormat(ResultFormat(
            'Hour Minute'.toTokens(), '1 Hour 2 Minute'.toTokens()))
        .isSelected = true; // The default format (0-based index 18).
    addResultFormat(ResultFormat('Hour Minute Second'.toTokens(),
        '1 Hour 2 Minute 3 Second'.toTokens()));
    // Inserted AFTER "Hour Minute" (index 18) so the default selection's index
    // is unchanged. The H:M:S:ms breakdown for sub-second precision.
    addResultFormat(ResultFormat('Hour Minute Second MSecond'.toTokens(),
        '1 Hour 2 Minute 3 Second 4 MSecond'.toTokens()));

    addResultFormat(ResultFormat('Minute'.toTokens(), '1 Minute'.toTokens()));
    addResultFormat(ResultFormat(
        'Minute Second'.toTokens(), '1 Minute 2 Second'.toTokens()));

    addResultFormat(ResultFormat('Second'.toTokens(), '1 Second'.toTokens()));
    // Milliseconds-only result format (the whole interval in MSeconds).
    addResultFormat(ResultFormat('MSecond'.toTokens(), '1 MSecond'.toTokens()));

    addResultFormat(ResultFormat(
      'Year Month Week Day Hour Minute Second MSecond'.toTokens(),
      '1 Year 2 Month 3 Week 4 Day 5 Hour 6 Minute 7 Second 8 MSecond'
          .toTokens(),
      'All Units',
    ));

    _selectedResultFormats.value =
        _resultFormatsList.getSelectedResultFormat();
  }

  static ResultFormatsRepository? _instance;

  /// Process-wide singleton accessor; seeds the 24 default formats exactly
  /// once.
  static ResultFormatsRepository getInstance() =>
      _instance ??= ResultFormatsRepository().._fillRepository();
}

/// Holds the "amount per time unit" rows and parameters. Port of
/// PerUnitsRepository.kt. Use [getInstance]: it seeds the defaults
/// (25 / "USD" / "10 Hour") and the 8 unit rows in this exact order:
/// Hour, Minute, Second, Day, Week, Month, Year, MSecond.
class PerUnitsRepository {
  PerUnitsRepository();

  final PerUnits _perUnitsList =
      PerUnits(BigDecimal.fromInt(25), 'USD', '10 Hour'.toTokens());
  late final LiveData<PerUnits> _perUnits = LiveData<PerUnits>(_perUnitsList);

  /// Appends [perUnit], republishes, and returns it.
  PerUnit addPerUnit(PerUnit perUnit) {
    _perUnitsList.add(perUnit);
    _perUnits.value = _perUnitsList;
    return perUnit;
  }

  /// Updates the shared amount / unit name / interval and republishes.
  /// NOTE: [timeInterval] is display-only; it is never used in the math.
  void setParams(BigDecimal amount, String unitName, Tokens timeInterval) {
    _perUnitsList.amount = amount;
    _perUnitsList.unitName = unitName;
    _perUnitsList.timeInterval = timeInterval;
    _perUnits.value = _perUnitsList;
  }

  /// Number of rows (8 after seeding).
  int length() => _perUnitsList.length;

  /// Observable per-unit rows (plus shared amount/unitName/timeInterval).
  ValueListenable<PerUnits> getPerUnits() => _perUnits;

  /// Recomputes every row: unitsPerResult = amount x (the millisecond total
  /// of [resultTokens] expressed in that row's unit).
  ///
  /// Since the RemoveADS zero-total fix, a zero/ERROR total converts to
  /// `["0", unit]` rather than an empty list, so units.first exists and the
  /// math yields amount x 0 = 0. The empty-list guard below (the master-era
  /// critic-gaps crash fix) is kept as a belt-and-braces fallback on top.
  void updatePerUnitsWithPreview(Tokens resultTokens) {
    for (final perUnitElement in _perUnitsList) {
      final units = TimeConverter.convertTokensToTokensWithFormat(
        resultTokens,
        perUnitElement.timeUnit.toTokens(),
      );
      final unitsValue = units.isEmpty
          ? BigDecimal.zero
          : BigDecimal.parse(units.first.strRepresentation);
      perUnitElement.unitsPerResult = _perUnitsList.amount * unitsValue;
    }
    _perUnits.value = _perUnitsList;
  }

  void _fillRepository() {
    setParams(BigDecimal.fromInt(25), 'USD', '10 Hour'.toTokens());
    addPerUnit(PerUnit('Hour'.toToken()));
    addPerUnit(PerUnit('Minute'.toToken()));
    addPerUnit(PerUnit('Second'.toToken()));
    addPerUnit(PerUnit('Day'.toToken()));
    addPerUnit(PerUnit('Week'.toToken()));
    addPerUnit(PerUnit('Month'.toToken()));
    addPerUnit(PerUnit('Year'.toToken()));
    addPerUnit(PerUnit('MSecond'.toToken()));
  }

  static PerUnitsRepository? _instance;

  /// Process-wide singleton accessor; seeds defaults and the 8 rows exactly
  /// once.
  static PerUnitsRepository getInstance() =>
      _instance ??= PerUnitsRepository().._fillRepository();
}
