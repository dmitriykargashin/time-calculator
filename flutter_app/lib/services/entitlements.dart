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
