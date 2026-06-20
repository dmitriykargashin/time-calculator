import 'dart:ui' as ui;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Analytics for the SAME custom events the original Kotlin app logged
/// (button_long_delete, button_per, button_formats, button_support[_1/3/5/9],
/// button_support_rate, button_feedback, button_share_the_app), so the Flutter
/// build's events aggregate with the historical data in the SAME Google
/// Analytics property. (Firebase also auto-collects user_engagement, first_open,
/// screen_view, etc. with no code.)
///
/// GRACEFUL: analytics turns on ONLY when Firebase actually initialized in
/// [main] - i.e. a real `google-services.json` (Android) / `GoogleService-
/// Info.plist` (iOS) was present at build time. Without it (the `.dev` build,
/// web, CI, widget tests) [Firebase.apps] is empty, every method is a silent
/// no-op, and nothing is transmitted - so the app builds and runs identically
/// with or without the Firebase config. Mirrors the [Monetization] gating
/// pattern: never throw, never block startup.
///
/// CONSENT (GDPR / Consent Mode, no ad SDK): in [consentRegions] (EEA + UK +
/// Switzerland) analytics + ads consent default to DENIED until the user grants
/// them via the consent dialog (or the Settings toggle); EVERYWHERE ELSE they
/// are granted with no prompt. The SAME choice drives both analyticsStorage and
/// the ad-consent signals (the Advertising ID is collected for Google Ads
/// measurement/audiences). The choice is persisted under [_consentPrefKey] and
/// re-applied on every launch.
class AnalyticsService {
  AnalyticsService._();

  /// Process-wide singleton.
  static final AnalyticsService instance = AnalyticsService._();

  static const String _consentPrefKey = 'analytics_consent_granted';

  /// EEA + UK + Switzerland - the regions where we ask consent before analytics
  /// (GDPR / UK-GDPR / Swiss FADP). Detected from the device locale country.
  static const Set<String> consentRegions = {
    // EU-27
    'AT', 'BE', 'BG', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'GR',
    'HU', 'IE', 'IT', 'LV', 'LT', 'LU', 'MT', 'NL', 'PL', 'PT', 'RO', 'SK',
    'SI', 'ES', 'SE',
    // EEA (non-EU)
    'IS', 'LI', 'NO',
    // UK + Switzerland
    'GB', 'CH',
  };

  /// Non-null only once [init] finds an initialized Firebase app.
  FirebaseAnalytics? _analytics;

  /// The user's consent choice; null until they decide (only relevant in a
  /// [consentRegions] region - elsewhere analytics is on without asking).
  bool? _consentGranted;

  /// Whether events are actually being sent (a real Firebase config is wired).
  bool get isEnabled => _analytics != null;

  /// Whether the device's region requires a consent prompt before analytics.
  /// Read from the device locale's country code against [consentRegions].
  bool get isConsentRequiredRegion {
    final country =
        ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    return country != null && consentRegions.contains(country);
  }

  /// True ONLY when analytics is live, the user is in a consent region, AND
  /// they have not chosen yet - i.e. the consent dialog should be shown once.
  bool get needsConsentPrompt =>
      isEnabled && isConsentRequiredRegion && _consentGranted == null;

  /// The current consent decision (null = not yet chosen).
  bool? get consentGranted => _consentGranted;

  /// Wires up [FirebaseAnalytics] IFF Firebase initialized (see [main]), loads
  /// the persisted consent choice, and applies Consent Mode. Safe when Firebase
  /// is absent (stays disabled). Never throws.
  Future<void> init() async {
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
      }
    } catch (e) {
      debugPrint('AnalyticsService: disabled (Firebase not available): $e');
      _analytics = null;
    }
    if (_analytics == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(_consentPrefKey)) {
        _consentGranted = prefs.getBool(_consentPrefKey);
      }
    } catch (e) {
      debugPrint('AnalyticsService: consent read failed: $e');
    }
    // Consent Mode default: GRANTED outside the consent regions; inside them,
    // the stored choice or DENIED until the user grants it.
    final granted = _consentGranted ?? !isConsentRequiredRegion;
    await _applyConsent(granted);
  }

  /// Records the user's consent choice (consent dialog OR Settings toggle),
  /// persists it, and applies it to Consent Mode immediately. Never throws.
  Future<void> setConsentGranted(bool granted) async {
    _consentGranted = granted;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentPrefKey, granted);
    } catch (e) {
      debugPrint('AnalyticsService: consent write failed: $e');
    }
    await _applyConsent(granted);
  }

  Future<void> _applyConsent(bool granted) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.setConsent(
        analyticsStorageConsentGranted: granted,
        // Ad consent follows the SAME decision: the Advertising ID is used for
        // Google Ads measurement / conversions / audiences (the app is promoted
        // via Google Ads), so granting consent enables both analytics and ads
        // signals; denying (or an undecided EEA user) keeps both off.
        adStorageConsentGranted: granted,
        adUserDataConsentGranted: granted,
        adPersonalizationSignalsConsentGranted: granted,
      );
      await analytics.setAnalyticsCollectionEnabled(granted);
    } catch (e) {
      debugPrint('AnalyticsService: applyConsent failed: $e');
    }
  }

  Future<void> _log(String name) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name);
    } catch (e) {
      debugPrint('AnalyticsService: logEvent("$name") failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Custom events - named VERBATIM as the Kotlin app logged them so the metrics
  // continue uninterrupted. (Firebase event names: <=40 chars, [a-zA-Z0-9_],
  // must start with a letter - all of these comply.) When consent is not
  // granted, Consent Mode + setAnalyticsCollectionEnabled(false) suppress them.
  // ---------------------------------------------------------------------------

  /// Long-press of the single Backspace key (clear-all). Kotlin: button_long_delete.
  Future<void> buttonLongDelete() => _log('button_long_delete');

  /// Opening the Per/value calculator. Kotlin: button_per.
  Future<void> buttonPer() => _log('button_per');

  /// Opening the result-Formats overlay. Kotlin: button_formats.
  Future<void> buttonFormats() => _log('button_formats');

  /// Opening the "support the app" (tea) screen. Kotlin: button_support.
  Future<void> buttonSupport() => _log('button_support');

  /// Tapping "Send Feedback". Kotlin: button_feedback.
  Future<void> buttonFeedback() => _log('button_feedback');

  /// Tapping "Share the app". Kotlin: button_share_the_app.
  Future<void> buttonShareTheApp() => _log('button_share_the_app');

  /// Tapping "Leave a review" on the support screen. Kotlin: button_support_rate.
  Future<void> buttonSupportRate() => _log('button_support_rate');

  /// Tapping a donation tier's buy button. [sku] is e.g. 'support_3', logged as
  /// `button_support_3` to match the Kotlin button_support_1/3/5/9 events.
  Future<void> buttonSupportTier(String sku) => _log('button_$sku');

  // --- Test seams (no production caller) -------------------------------------

  /// Forces consent state in tests without a Firebase platform channel.
  @visibleForTesting
  void debugSetConsentForTest(bool? granted) => _consentGranted = granted;
}
