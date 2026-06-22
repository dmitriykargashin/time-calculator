import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One stored calculation: the entered [expression] and its [result], both as
/// display strings (e.g. "5 Hours + 10 Minutes" and "4 Hours 50 Minutes"). The
/// expression string is re-lexable, so tapping a history entry reloads it.
/// [note] is the user's optional label for the record; [timestamp] is when it
/// was saved (epoch millis, 0 = unknown, e.g. a legacy entry); [formatIndex] is
/// the selected result-format index at save time (-1 = unknown, keep current).
@immutable
class HistoryEntry {
  const HistoryEntry(
    this.expression,
    this.result, {
    this.note = '',
    this.timestamp = 0,
    this.formatIndex = -1,
  });

  final String expression;
  final String result;
  final String note;
  final int timestamp;
  final int formatIndex;

  HistoryEntry withNote(String note) => HistoryEntry(
        expression,
        result,
        note: note,
        timestamp: timestamp,
        formatIndex: formatIndex,
      );

  Map<String, dynamic> toJson() => {
        'e': expression,
        'r': result,
        if (note.isNotEmpty) 'n': note,
        if (timestamp > 0) 't': timestamp,
        if (formatIndex >= 0) 'f': formatIndex,
      };

  /// Parses one persisted row; returns null for anything malformed (so a
  /// corrupt entry is dropped instead of crashing - F6: must not crash). The
  /// note/timestamp/formatIndex are optional, so older rows without them load.
  static HistoryEntry? fromJson(Object? raw) {
    if (raw is Map && raw['e'] is String && raw['r'] is String) {
      return HistoryEntry(
        raw['e'] as String,
        raw['r'] as String,
        note: raw['n'] is String ? raw['n'] as String : '',
        timestamp: raw['t'] is int ? raw['t'] as int : 0,
        formatIndex: raw['f'] is int ? raw['f'] as int : -1,
      );
    }
    return null;
  }
}

/// F6 (history / calculation log): the last [maxEntries] committed
/// calculations, persisted to SharedPreferences, newest first.
///
/// OFF by default - nothing is recorded unless history is enabled (driven by
/// [SettingsModel.setHistoryEnabled] -> [setEnabled]). No timestamps, no
/// export, no sync (all out of scope per the spec). Corrupt/empty storage
/// never throws.
class HistoryService extends ChangeNotifier {
  HistoryService._();

  static HistoryService? _instance;
  static HistoryService get instance => _instance ??= HistoryService._();

  /// SharedPreferences key for the JSON-encoded entry list.
  static const String prefHistoryKey = 'calc_history';

  /// The cap from the spec ("5-10 most recent ... oldest removed at the 11th").
  static const int maxEntries = 10;

  bool _enabled = false;
  List<HistoryEntry> _entries = <HistoryEntry>[];

  /// Newest-first snapshot (unmodifiable).
  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;

  /// Whether recording is currently on (mirrors [SettingsModel.historyEnabled]).
  bool get isEnabled => _enabled;

  /// Loads the persisted entries and seeds the enabled flag. Never throws -
  /// a corrupt row is skipped and a corrupt list resets to empty.
  Future<void> load({required bool enabled}) async {
    _enabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(prefHistoryKey) ?? const <String>[];
      final parsed = <HistoryEntry>[];
      for (final row in raw) {
        try {
          final entry = HistoryEntry.fromJson(jsonDecode(row));
          if (entry != null) parsed.add(entry);
        } catch (_) {
          // Skip a single corrupt row.
        }
      }
      _entries = parsed.take(maxEntries).toList();
    } catch (e) {
      debugPrint('HistoryService: failed to load history: $e');
      _entries = <HistoryEntry>[];
    }
    notifyListeners();
  }

  /// Mirrors [SettingsModel.historyEnabled]. Turning it OFF stops recording but
  /// KEEPS stored entries (re-enabling restores them); the UI just hides the
  /// entry point while off.
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  /// Records one calculation (newest first), capped at [maxEntries]. No-op when
  /// history is disabled, when either field is blank, when the expression and
  /// result are identical ("=" on an already-computed value), or when it equals
  /// the most recent entry (avoids duplicate spam). Stamps the entry with [at]
  /// (epoch millis) or the current time. Persists best-effort.
  void record(String expression, String result, {int? formatIndex, int? at}) {
    if (!_enabled) return;
    final e = expression.trim();
    final r = result.trim();
    if (e.isEmpty || r.isEmpty || e == r) return;
    if (_entries.isNotEmpty &&
        _entries.first.expression == e &&
        _entries.first.result == r) {
      return;
    }
    _entries.insert(
      0,
      HistoryEntry(
        e,
        r,
        timestamp: at ?? DateTime.now().millisecondsSinceEpoch,
        formatIndex: formatIndex ?? -1,
      ),
    );
    if (_entries.length > maxEntries) {
      _entries = _entries.sublist(0, maxEntries);
    }
    _persist();
    notifyListeners();
  }

  /// Deletes the entry at [index] (the per-record delete). Out-of-range is a
  /// no-op.
  void removeAt(int index) {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeAt(index);
    _persist();
    notifyListeners();
  }

  /// Sets (or clears, when [note] is blank) the user's note on the entry at
  /// [index]. Out-of-range or an unchanged note is a no-op.
  void setNote(int index, String note) {
    if (index < 0 || index >= _entries.length) return;
    final trimmed = note.trim();
    if (_entries[index].note == trimmed) return;
    _entries[index] = _entries[index].withNote(trimmed);
    _persist();
    notifyListeners();
  }

  /// Clears all entries (the Settings / overlay "Clear history" action).
  void clear() {
    if (_entries.isEmpty) return;
    _entries = <HistoryEntry>[];
    _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        prefHistoryKey,
        _entries.map((e) => jsonEncode(e.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('HistoryService: failed to persist history: $e');
    }
  }
}
