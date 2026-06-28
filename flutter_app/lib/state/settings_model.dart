import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/token_type.dart';
import '../services/history_service.dart';

/// Port of the RemoveADS branch's PrefRepository - the ONLY disk persistence
/// in the app: the theme choice, stored as String "0"/"1"/"2" under the
/// verbatim key [prefThemeColorKey] (the Android prefs FILE name
/// "MY_APP_PREF" has no shared_preferences equivalent; the key is kept).
///
/// Value semantics (PrefRepository + the getPrefThemeColor observer):
/// * "0" -> follow system (MODE_NIGHT_FOLLOW_SYSTEM);
/// * "1" -> light (MODE_NIGHT_NO);
/// * "2" -> dark (MODE_NIGHT_YES);
/// * anything else -> follow system;
/// * first run (missing/blank) -> "0" is written back.
///
/// Written through on every Settings radio click (the Kotlin synchronous
/// `commit()`); loaded once in main() before runApp so the first frame
/// already renders the persisted theme. MaterialApp consumes [themeMode],
/// so a change applies IMMEDIATELY - the Flutter analog of the DayNight
/// activity recreation (whose state-survival problem does not exist here:
/// all app state lives in process singletons above the widget tree).
class SettingsModel extends ChangeNotifier {
  SettingsModel();

  static SettingsModel? _instance;

  /// Process-wide singleton used by main.dart and the Settings overlay.
  static SettingsModel get instance => _instance ??= SettingsModel();

  /// SharedPreferences key, verbatim from PrefRepository.PREF_THEME_COLOR.
  static const String prefThemeColorKey = 'PREF_THEME_COLOR';

  /// SharedPreferences key for the draggable display/keypad split: the fraction
  /// of the available content height the HERO DISPLAY card occupies (the keypad
  /// card takes the rest). A new Flutter-only preference (no Android analog).
  static const String prefDisplayFractionKey = 'display_fraction';

  /// SharedPreferences key for the swappable keypad unit key: when `true` the
  /// keypad's single swappable slot shows the Msec (millisecond) key; when
  /// `false` it shows the Year key. Default `true` (Msec). A Flutter-only
  /// preference (no Android analog).
  static const String prefKeypadShowsMsecKey = 'keypad_shows_msec';

  /// SharedPreferences key for the F6 calculation-history switch. Default
  /// `true` (on) - history records and shows unless the user turns it off.
  static const String prefHistoryEnabledKey = 'history_enabled';

  /// Default display fraction (~0.52 display / 0.48 keypad), matching the split
  /// the screen shipped with before the divider was draggable, so first launch
  /// looks unchanged.
  static const double defaultDisplayFraction = 0.52;

  /// PORTRAIT clamp bounds for the display fraction. WIDENED so the draggable
  /// divider has real travel again: down to ~0.25 (a tall keypad / compact
  /// display) and up to ~0.72 (a big hero display / smaller-but-still-usable
  /// keys, whose FittedBox labels stay legible). The keypad floor
  /// ([_kMinKeyHeight], now ~30dp) still tightens this max on a given viewport
  /// so the keys never go below the usable minimum. The calculator screen
  /// clamps PORTRAIT drags to this range; the landscape/tablet (7-column)
  /// layout uses its own tighter range (defined on the screen) over the SAME
  /// persisted fraction.
  static const double minDisplayFraction = 0.25;
  static const double maxDisplayFraction = 0.72;

  /// STORAGE clamp bounds for [setDisplayFraction]. The same persisted fraction
  /// feeds both layouts, and the landscape layout allows a SMALLER display
  /// fraction (down to ~0.18) than portrait, so the on-disk value is clamped to
  /// this wider envelope rather than the portrait-only range - otherwise a
  /// landscape drag below 0.25 could never be saved. Each layout re-clamps the
  /// loaded value to its own usable range when it builds.
  static const double minStoredDisplayFraction = 0.18;
  static const double maxStoredDisplayFraction = 0.72;

  /// The three persisted values ("0"/"1"/"2").
  static const String themeValueSystem = '0';
  static const String themeValueLight = '1';
  static const String themeValueDark = '2';

  String _themeValue = themeValueSystem;

  double _displayFraction = defaultDisplayFraction;

  bool _keypadShowsMsec = true;

  /// VESTIGIAL: the keypad no longer has a Msec/Year swap slot - it renders the
  /// full [enabledUnits] set. This flag is kept ONLY as a persistence bridge:
  /// [setEnabledUnits] keeps it in sync (Msec enabled, or Year not) and persists
  /// it under [prefKeypadShowsMsecKey], so an older build reading that pref still
  /// sees a sensible value. Nothing in the live UI reads it anymore.
  bool get keypadShowsMsec => _keypadShowsMsec;

  /// SharedPreferences key for the customizable keypad time-unit key set
  /// (keypad-key customization, phase 1). Stored as the enum names of the
  /// enabled units; absent on first run -> [_defaultEnabledUnits].
  static const String prefEnabledUnitsKey = 'keypad_enabled_units';

  /// Every time-unit key the keypad can offer, in canonical small -> large
  /// order (also the order they render in the chips / preview / keypad).
  static const List<TokenType> allKeypadUnits = <TokenType>[
    TokenType.mSecond,
    TokenType.second,
    TokenType.minute,
    TokenType.hour,
    TokenType.day,
    TokenType.week,
    TokenType.month,
    TokenType.year,
  ];

  /// The keypad must keep at least this many unit keys (you cannot form a time
  /// expression with fewer); the picker blocks dropping below it.
  static const int minKeypadUnits = 2;

  /// Shipping default: Msec + Second..Month (Year is the swap alternative and
  /// is off by default), matching today's keypad.
  static const Set<TokenType> _defaultEnabledUnits = <TokenType>{
    TokenType.mSecond,
    TokenType.second,
    TokenType.minute,
    TokenType.hour,
    TokenType.day,
    TokenType.week,
    TokenType.month,
  };

  /// Named one-tap presets shown above the per-unit chips in the picker.
  static const List<KeypadUnitPreset> keypadUnitPresets = <KeypadUnitPreset>[
    KeypadUnitPreset('Standard', _defaultEnabledUnits),
    KeypadUnitPreset('Stopwatch', <TokenType>{
      TokenType.mSecond,
      TokenType.second,
      TokenType.minute,
    }),
    // Hour:Minute:Second:Msec - video/audio timecode work.
    KeypadUnitPreset('Media', <TokenType>{
      TokenType.mSecond,
      TokenType.second,
      TokenType.minute,
      TokenType.hour,
    }),
    KeypadUnitPreset('Hours & minutes', <TokenType>{
      TokenType.minute,
      TokenType.hour,
    }),
    KeypadUnitPreset('Calendar', <TokenType>{
      TokenType.day,
      TokenType.week,
      TokenType.month,
      TokenType.year,
    }),
    KeypadUnitPreset('Everything', <TokenType>{
      TokenType.mSecond,
      TokenType.second,
      TokenType.minute,
      TokenType.hour,
      TokenType.day,
      TokenType.week,
      TokenType.month,
      TokenType.year,
    }),
  ];

  Set<TokenType> _enabledUnits = <TokenType>{..._defaultEnabledUnits};

  /// The enabled keypad unit keys, in canonical [allKeypadUnits] order.
  List<TokenType> get enabledUnits =>
      allKeypadUnits.where(_enabledUnits.contains).toList(growable: false);

  /// Whether [unit] is currently an enabled keypad key.
  bool isKeypadUnitEnabled(TokenType unit) => _enabledUnits.contains(unit);

  static bool _sameUnits(Set<TokenType> a, Set<TokenType> b) =>
      a.length == b.length && a.containsAll(b);

  /// The preset whose set exactly matches the current selection, or null when
  /// the selection is "Custom".
  KeypadUnitPreset? get activeKeypadUnitPreset {
    for (final preset in keypadUnitPresets) {
      if (_sameUnits(preset.units, _enabledUnits)) return preset;
    }
    return null;
  }

  /// Replaces the enabled keypad unit set. Ignored if it would drop below
  /// [minKeypadUnits] or is unchanged. Persists, and bridges the choice onto
  /// today's fixed keypad: its single swap slot shows Msec when Msec is enabled
  /// (or whenever Year is not), else Year. The full reflow that makes the
  /// keypad honor the WHOLE set is the next step.
  Future<void> setEnabledUnits(Set<TokenType> units) async {
    final next = allKeypadUnits.where(units.contains).toSet();
    if (next.length < minKeypadUnits || _sameUnits(next, _enabledUnits)) return;
    _enabledUnits = next;
    _keypadShowsMsec =
        next.contains(TokenType.mSecond) || !next.contains(TokenType.year);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      prefEnabledUnitsKey,
      enabledUnits.map((u) => u.name).toList(),
    );
    await prefs.setBool(prefKeypadShowsMsecKey, _keypadShowsMsec);
  }

  /// Enables/disables a single keypad unit key (min-[minKeypadUnits] enforced).
  Future<void> setKeypadUnitEnabled(TokenType unit, bool enabled) {
    final next = <TokenType>{..._enabledUnits};
    if (enabled) {
      next.add(unit);
    } else {
      next.remove(unit);
    }
    return setEnabledUnits(next);
  }

  /// Applies a named preset's unit set.
  Future<void> applyKeypadUnitPreset(KeypadUnitPreset preset) =>
      setEnabledUnits(<TokenType>{...preset.units});

  bool _historyEnabled = true;

  /// Whether the F6 calculation history is on (true, the default). Drives
  /// recording in [HistoryService] and the visibility of the History entry
  /// point/overlay. Persisted under [prefHistoryEnabledKey].
  bool get historyEnabled => _historyEnabled;

  /// The persisted display fraction, always within
  /// [[minDisplayFraction], [maxDisplayFraction]]. The calculator screen reads
  /// it on first build and writes it back via [setDisplayFraction] on drag end.
  double get displayFraction => _displayFraction;

  /// A notifier the screen can listen to so it picks up the restored fraction
  /// once [load] completes (load runs before runApp, but the screen subscribes
  /// to be robust to any future async load ordering). It carries the same value
  /// as [displayFraction].
  final ValueNotifier<double> displayFractionListenable =
      ValueNotifier<double>(defaultDisplayFraction);

  /// The raw persisted value ("0"/"1"/"2"; unknown values behave as "0").
  String get themeValue => _themeValue;

  /// [themeValue] mapped for MaterialApp.themeMode.
  ThemeMode get themeMode => switch (_themeValue) {
        themeValueLight => ThemeMode.light,
        themeValueDark => ThemeMode.dark,
        // "0" and anything unexpected fall back to follow-system, like the
        // Android observer's else branch.
        _ => ThemeMode.system,
      };

  /// The theme mode MaterialApp actually applies. Theme (including dark mode) is
  /// a FREE feature on every platform, so this is simply [themeMode] — there is
  /// no Pro clamp. Kept as a distinct getter so [main] and Settings read one
  /// source of truth (and so the call sites stay stable if gating ever returns).
  ThemeMode get effectiveThemeMode => themeMode;

  /// Loads the persisted values; call before runApp. A blank first run writes
  /// "0" back for the theme (PrefRepository.init parity). The display fraction
  /// is read and clamped (a missing/corrupt value leaves the default). Never
  /// throws.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(prefThemeColorKey) ?? '';
      if (stored.isEmpty) {
        await prefs.setString(prefThemeColorKey, themeValueSystem);
        _themeValue = themeValueSystem;
      } else if (stored != themeValueLight && stored != themeValueDark) {
        // Unknown/corrupted value: coerce to "0" so the Settings radio group
        // shows "System default" checked (Android observer's else branch).
        _themeValue = themeValueSystem;
      } else {
        _themeValue = stored;
      }
      final fraction = prefs.getDouble(prefDisplayFractionKey);
      if (fraction != null) {
        _displayFraction =
            fraction.clamp(minStoredDisplayFraction, maxStoredDisplayFraction);
        displayFractionListenable.value = _displayFraction;
      }
      _keypadShowsMsec = prefs.getBool(prefKeypadShowsMsecKey) ?? true;
      final storedUnits = prefs.getStringList(prefEnabledUnitsKey);
      if (storedUnits != null) {
        final parsed =
            allKeypadUnits.where((u) => storedUnits.contains(u.name)).toSet();
        if (parsed.length >= minKeypadUnits) _enabledUnits = parsed;
      }
      _historyEnabled = prefs.getBool(prefHistoryEnabledKey) ?? true;
    } catch (e) {
      debugPrint('SettingsModel: failed to load preferences: $e');
    }
    // Seed the history store with the loaded entries + the enabled flag (best
    // effort; never blocks startup).
    try {
      await HistoryService.instance.load(enabled: _historyEnabled);
    } catch (e) {
      debugPrint('SettingsModel: failed to load history: $e');
    }
    notifyListeners();
  }

  /// Applies [value] immediately (notifies MaterialApp) and writes it
  /// through to disk. Never throws.
  Future<void> setThemeValue(String value) async {
    if (_themeValue != value) {
      _themeValue = value;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefThemeColorKey, value);
    } catch (e) {
      debugPrint('SettingsModel: failed to persist theme preference: $e');
    }
  }

  /// Applies the keypad unit-key choice immediately (notifies the calculator
  /// screen, which rebuilds the keypad) and writes it through to disk. `true`
  /// shows the Msec key in the swappable slot, `false` the Year key. Never
  /// throws.
  Future<void> setKeypadShowsMsec(bool value) async {
    if (_keypadShowsMsec != value) {
      _keypadShowsMsec = value;
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKeypadShowsMsecKey, value);
    } catch (e) {
      debugPrint('SettingsModel: failed to persist keypad unit preference: $e');
    }
  }

  /// Applies the F6 history opt-in immediately (notifies listeners + tells
  /// [HistoryService] to start/stop recording) and writes it through to disk.
  /// Never throws.
  Future<void> setHistoryEnabled(bool value) async {
    if (_historyEnabled != value) {
      _historyEnabled = value;
      HistoryService.instance.setEnabled(value);
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefHistoryEnabledKey, value);
    } catch (e) {
      debugPrint('SettingsModel: failed to persist history preference: $e');
    }
  }

  /// Persists the draggable display/keypad split. Called on DRAG END (not every
  /// frame). [value] is clamped to the wide STORAGE range
  /// [[minStoredDisplayFraction], [maxStoredDisplayFraction]] (so a landscape
  /// drag below the portrait floor is still saved), stored under
  /// [prefDisplayFractionKey], and published on [displayFractionListenable].
  /// Each layout re-clamps to its own usable range when it builds. Never throws.
  Future<void> setDisplayFraction(double value) async {
    final clamped =
        value.clamp(minStoredDisplayFraction, maxStoredDisplayFraction);
    if (_displayFraction != clamped) {
      _displayFraction = clamped;
      displayFractionListenable.value = clamped;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefDisplayFractionKey, clamped);
    } catch (e) {
      debugPrint('SettingsModel: failed to persist display fraction: $e');
    }
  }
}

/// A one-tap preset of keypad time-unit keys for the Settings picker.
@immutable
class KeypadUnitPreset {
  const KeypadUnitPreset(this.name, this.units);

  final String name;
  final Set<TokenType> units;
}
