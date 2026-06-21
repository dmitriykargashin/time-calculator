import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/monetization.dart';

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

  /// Whether the keypad's swappable slot shows the Msec key (true, the default)
  /// or the Year key (false). Read by the calculator screen when it builds the
  /// keypad; toggled from the Settings overlay. Persisted under
  /// [prefKeypadShowsMsecKey].
  bool get keypadShowsMsec => _keypadShowsMsec;

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

  /// The theme mode MaterialApp actually applies. While Pro gating is on and
  /// Pro is not yet unlocked (Apple-only, [kApplePurchasesEnabled]), the dark
  /// theme is a Pro feature, so the app is forced to [ThemeMode.light]
  /// regardless of the stored choice. The stored "0"/"1"/"2" value is left
  /// untouched, so unlocking Pro instantly applies the user's real selection
  /// (main.dart rebuilds on the Monetization notification). Everywhere gating
  /// is off this is identical to [themeMode].
  ThemeMode get effectiveThemeMode {
    final mon = Monetization.instance;
    if (mon.isProGated && !mon.isProUnlocked) return ThemeMode.light;
    return themeMode;
  }

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
    } catch (e) {
      debugPrint('SettingsModel: failed to load preferences: $e');
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
