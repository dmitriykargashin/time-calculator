import 'package:flutter/foundation.dart';

/// Feedback address, verbatim from the RemoveADS branch
/// (changed from dmitrii.kargashin@cardamon.org).
const String kFeedbackEmail = 'support@cardamon.org';

/// Privacy policy URL, shown from the analytics-consent dialog and the Settings
/// "Privacy Policy" row. REQUIRED now that the app collects analytics (Play Data
/// safety + GDPR). The page content is specified in
/// docs/privacy-policy-requirements.md. While empty, the consent dialog / the
/// Settings row omit the link.
const String kPrivacyPolicyUrl =
    'https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator';

/// True on iOS/macOS, where App Store rules apply (never link to Google
/// Play there - App Store guideline 2.3.10 forbids referencing rival
/// stores).
bool get isApplePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS);

/// Apple App Store numeric app id. EMPTY until the App Store Connect record
/// is created - set it there first, then fill this in. While empty, Apple
/// builds never open any store page.
const String kAppleAppId = '';

/// Non-consumable product id for the Apple-only "Pro" one-time unlock. Must
/// match the product id created in App Store Connect exactly.
const String kProSku = 'pro_unlock';

/// Master switch for Apple Pro billing. While `false`, NOTHING is gated on any
/// platform and no purchase UI ships - so no broken locks reach users before
/// the product exists.
///
/// To go live on iOS/macOS:
///   1. Create the `pro_unlock` non-consumable in App Store Connect (price it,
///      submit it for review with the build).
///   2. Set [kAppleAppId] to the App Store Connect numeric app id.
///   3. Flip this to `true`.
///   4. Ship.
///
/// Leave `false` until ALL of the above are done: this is the single switch
/// that turns gating, the paywall, and Pro billing on for Apple platforms.
/// Android and web ignore it entirely (they are never gated).
const bool kApplePurchasesEnabled = false;

/// App Store listing URL (meaningless while [kAppleAppId] is empty).
const String kAppStoreUrl = 'https://apps.apple.com/app/id$kAppleAppId';

/// Store page for the platform this build runs on, or null when none exists
/// yet (Apple platforms before [kAppleAppId] is set).
String? get storeUrlForCurrentPlatform {
  if (isApplePlatform) return kAppleAppId.isEmpty ? null : kAppStoreUrl;
  return kPlayStoreUrl;
}

/// Android applicationId of the Play Store listing.
const String kAndroidPackageId = 'com.dmitriykargashin.cardamontimecalculator';

/// Play Store web listing - the fallback used when the
/// native store sheet / market deep link is unavailable.
const String kPlayStoreUrl =
    'https://play.google.com/store/apps/details?id=$kAndroidPackageId';

/// "Share the app" pitch, verbatim from the original `shareTheApp()`
/// (ACTION_SEND text/plain, no subject, no chooser title) minus the link.
const String _kSharePitch = '😍 The Best Time Calculator.\n'
    '  ✅ Work Hours\n'
    '  ✅ Allows you to select different time formats for the result\n'
    '  ✅ Convert any Time Units\n'
    '  ✅ Calculates Salary, Distance, etc';

/// Android/web share text, verbatim from the original (the bit.ly link
/// redirects to the Google Play listing).
const String kShareAppText =
    '$_kSharePitch\n\n🔥 Please, try it: https://bit.ly/TimeCalcCardamon';

/// Platform-aware share text: Apple platforms get the App Store link (or no
/// link at all until [kAppleAppId] exists - never the Play link there);
/// everywhere else the verbatim original.
String get shareAppText {
  if (!isApplePlatform) return kShareAppText;
  if (kAppleAppId.isEmpty) return _kSharePitch;
  return '$_kSharePitch\n\n🔥 Please, try it: $kAppStoreUrl';
}
