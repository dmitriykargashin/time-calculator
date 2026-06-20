import 'dart:collection';

import 'result_format.dart';

/// A mutable list of [ResultFormat]s with single-selection helpers. Port of
/// Kotlin `ResultFormats : ArrayList<ResultFormat>`.
class ResultFormats extends ListBase<ResultFormat> {
  final List<ResultFormat> _formats = <ResultFormat>[];

  @override
  int get length => _formats.length;

  @override
  set length(int newLength) => _formats.length = newLength;

  @override
  ResultFormat operator [](int index) => _formats[index];

  @override
  void operator []=(int index, ResultFormat value) => _formats[index] = value;

  @override
  void add(ResultFormat element) => _formats.add(element);

  @override
  void addAll(Iterable<ResultFormat> iterable) => _formats.addAll(iterable);

  /// Clears every isSelected flag, selects the format at [position] and
  /// returns it.
  ResultFormat setSelection(int position) {
    for (final format in this) {
      format.isSelected = false;
    }
    this[position].isSelected = true;
    return this[position];
  }

  /// Returns the LAST format whose isSelected is true. Throws [StateError]
  /// when nothing is selected (the original threw
  /// UninitializedPropertyAccessException). Original name (with typo):
  /// getSelectedResulFormat.
  ResultFormat getSelectedResultFormat() {
    ResultFormat? selected;
    for (final format in this) {
      if (format.isSelected) selected = format;
    }
    if (selected == null) {
      throw StateError('No result format is selected.');
    }
    return selected;
  }
}
