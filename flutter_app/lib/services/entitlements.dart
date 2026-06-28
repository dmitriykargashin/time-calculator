import 'monetization.dart';

/// Result-format names that stay free even on a gated Apple build. These match
/// `ResultFormat.textPresentationOfTokens` exactly (the names shown in the
/// Formats list, e.g. "Hour Minute"). Everything outside this set is Pro-only
/// when [Monetization.isProGated] is on and Pro is not yet owned.
const Set<String> kFreeFormatNames = {
  'Hour Minute',
  'Hour',
  'Minute',
  'Second',
  'MSecond',
  'Day',
  'Year',
};

/// Whether the result format named [formatName] is available without Pro.
///
/// Free when gating is off (Android/web/Apple-before-go-live), OR when Pro is
/// owned, OR when the name is in the always-free [kFreeFormatNames] set.
/// [formatName] is `ResultFormat.textPresentationOfTokens`.
bool isFormatFree(String formatName) =>
    !Monetization.instance.isProGated ||
    Monetization.instance.isProUnlocked ||
    kFreeFormatNames.contains(formatName);

/// Keypad presets usable WITHOUT Pro on a gated (Apple go-live) build. Names
/// match [SettingsModel.keypadUnitPresets] entries exactly. Every other preset
/// AND the per-unit custom picker are Pro-only when gating is on. (On Android /
/// web / Apple-before-go-live nothing is gated, so all presets stay free.)
const Set<String> kFreeKeypadPresetNames = {'Standard', 'Stopwatch'};

/// Whether the keypad preset named [presetName] can be applied without Pro.
bool isKeypadPresetFree(String presetName) =>
    Monetization.instance.hasPro || kFreeKeypadPresetNames.contains(presetName);

/// Whether per-unit keypad customization (the UNITS picker and the non-free
/// presets) is available. True where gating is off OR Pro is owned.
bool get canCustomizeKeypad => Monetization.instance.hasPro;

/// How many history entries a free (gated, non-Pro) user can see. Pro / Android
/// / web see the full stored log (up to [HistoryService.maxEntries]).
const int kFreeHistoryLimit = 5;

/// Whether the full calculation history is available (no [kFreeHistoryLimit]
/// cap). True where gating is off OR Pro is owned.
bool get hasUnlimitedHistory => Monetization.instance.hasPro;
