import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../ui/widgets/rating_dialog.dart';
import 'feedback_service.dart';

/// Port of the RemoveADS branch's awesome-app-rating 2.3.0 flow (replaces
/// the ads-era hotchemi android-rate / native in_app_review prompt).
///
/// Thresholds, verbatim from the original `rateBuilder()`:
/// - first prompt: >= 5 launches AND >= 7 days since first launch;
/// - after a "Later" answer: >= 5 MORE launches AND >= 10 more days;
/// - a "NEVER" opt-out button is offered only from the 3rd automatic prompt;
/// - rating threshold: 4 FULL stars (full stars only, no halves).
///
/// The automatic prompt fires once per cold start only ([shouldAutoShow] is
/// consumed on first call - the Android original gated on
/// `savedInstanceState == null` so rotation/recreation never re-prompted).
///
/// Dialog flow ([showRatingFlow], custom widgets in
/// `lib/ui/widgets/rating_dialog.dart`):
/// - star dialog (title `rate_main_text`) -> Confirm/Later(/NEVER);
/// - rating >= 4 -> store prompt (`rate_store_second_text`) -> native
///   in-app review sheet, falling back to the Play listing /
///   [kPlayStoreUrl] via url_launcher;
/// - rating < 4 -> mail prompt (`rate_feedback_main_text`) ->
///   [sendFeedback] to support@cardamon.org with the "v."-prefixed subject.
///
/// `showRatingFlow(context, force: true)` is the support screen's
/// "Leave a review" button (the original
/// `rateBuilder().dontCountThisAsAppLaunch().showNow()`): it bypasses every
/// threshold and the never-flag, never offers the NEVER button, and leaves
/// the automatic schedule untouched except that confirming a rating still
/// ends the automatic prompts.
class RateService {
  RateService._();

  static final RateService _instance = RateService._();

  /// Process-wide singleton.
  static RateService get instance => _instance;

  // Verbatim from rateBuilder(): setMinimumLaunchTimes(5),
  // setMinimumDays(7), setMinimumLaunchTimesToShowAgain(5),
  // setMinimumDaysToShowAgain(10), showRateNeverButtonAfterNTimes(.., 3),
  // setRatingThreshold(RatingThreshold.FOUR).
  static const int _minLaunchTimes = 5;
  static const int _minDays = 7;
  static const int _minLaunchTimesToShowAgain = 5;
  static const int _minDaysToShowAgain = 10;
  static const int _neverButtonFromShowCount = 3;
  static const int _ratingThreshold = 4;

  // The launch bookkeeping keys are carried over from the ads-era service
  // (same semantics, so existing installs keep their counters); 'rate_agreed'
  // is also reused so users who already rated are not re-prompted.
  static const String _firstLaunchKey = 'rate_first_launch_millis';
  static const String _launchCountKey = 'rate_launch_count';
  static const String _agreedKey = 'rate_agreed';
  static const String _neverKey = 'rate_never';
  static const String _showLaterKey = 'rate_show_later';
  static const String _laterMillisKey = 'rate_later_millis';
  static const String _launchCountAtLaterKey = 'rate_launch_count_at_later';
  static const String _dialogShowCountKey = 'rate_dialog_show_count';

  /// [shouldAutoShow] may answer true only once per process (cold start).
  bool _autoShowConsumed = false;

  /// Records one app launch: stamps the first-launch time and increments the
  /// launch counter (the library's internal launch tracking equivalent).
  Future<void> registerLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey(_firstLaunchKey)) {
        await prefs.setInt(
          _firstLaunchKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }
      await prefs.setInt(
        _launchCountKey,
        (prefs.getInt(_launchCountKey) ?? 0) + 1,
      );
    } catch (e) {
      debugPrint('RateService: registerLaunch failed: $e');
    }
  }

  /// Whether the automatic rating prompt should be shown now
  /// (`showIfMeetsConditions()` equivalent). Consumed once per cold start:
  /// the first call answers from the persisted state, every later call in
  /// the same process returns false (mirrors the Android
  /// `savedInstanceState == null` gate). When this returns true the caller
  /// shows the prompt with `showRatingFlow(context)` (no force).
  Future<bool> shouldAutoShow() async {
    if (_autoShowConsumed) return false;
    _autoShowConsumed = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_neverKey) ?? false) return false;
      if (prefs.getBool(_agreedKey) ?? false) return false;
      final now = DateTime.now().millisecondsSinceEpoch;
      final launchCount = prefs.getInt(_launchCountKey) ?? 0;
      if (prefs.getBool(_showLaterKey) ?? false) {
        // "Later" was chosen: 5 more launches AND 10 more days.
        final laterMillis = prefs.getInt(_laterMillisKey) ?? now;
        final launchesAtLater = prefs.getInt(_launchCountAtLaterKey) ?? 0;
        return launchCount - launchesAtLater >= _minLaunchTimesToShowAgain &&
            now - laterMillis >=
                _minDaysToShowAgain * Duration.millisecondsPerDay;
      }
      final firstLaunch = prefs.getInt(_firstLaunchKey) ?? now;
      return launchCount >= _minLaunchTimes &&
          now - firstLaunch >= _minDays * Duration.millisecondsPerDay;
    } catch (e) {
      debugPrint('RateService: shouldAutoShow failed: $e');
      return false;
    }
  }

  /// Runs the full rating flow (see class docs). With [force] (the
  /// "Leave a review" button) every threshold and the never-flag are
  /// ignored, the prompt is not counted, and no NEVER button is offered.
  ///
  /// PLATFORM-SPECIFIC: on iOS/macOS the custom star dialog is never shown -
  /// App Store guideline 5.6.1 disallows custom review prompts, and the
  /// pre-filter (>=4 stars to the store, <4 to email) is review gating.
  /// Apple builds go straight to the system review sheet / the App Store
  /// write-review page instead.
  Future<void> showRatingFlow(
    BuildContext context, {
    bool force = false,
  }) async {
    if (isApplePlatform) {
      await _appleReviewFlow(force: force);
      return;
    }
    var showNeverButton = false;
    if (!force) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final showCount = (prefs.getInt(_dialogShowCountKey) ?? 0) + 1;
        await prefs.setInt(_dialogShowCountKey, showCount);
        // NEVER is offered from the 3rd automatic prompt on.
        showNeverButton = showCount >= _neverButtonFromShowCount;
      } catch (e) {
        debugPrint('RateService: show bookkeeping failed: $e');
      }
      if (!context.mounted) return;
    }
    final result =
        await RatingDialog.show(context, showNeverButton: showNeverButton);
    switch (result?.action) {
      case null: // Dialog dismissed without a choice - treat as "Later".
      case RatingDialogAction.later:
        if (!force) await _recordLater();
      case RatingDialogAction.never:
        await _recordNever();
      case RatingDialogAction.confirmed:
        // Confirming a rating ends the automatic prompts (library behavior:
        // the dialog-agreed flag is set on Confirm regardless of the stars).
        await _recordAgreed();
        if (!context.mounted) return;
        if (result!.rating >= _ratingThreshold) {
          if (await showStoreRatingPrompt(context)) {
            await _openStoreReview();
          }
        } else {
          if (await showMailFeedbackPrompt(context)) {
            await sendFeedback(subject: kRatingFeedbackSubject);
          }
        }
    }
  }

  /// The Apple-platform review path (no custom dialog - see
  /// [showRatingFlow]). Forced ("Leave a review"): the App Store
  /// write-review page when [kAppleAppId] exists, else the system sheet.
  /// Automatic: the system sheet only (it self-limits to 3 prompts per 365
  /// days and gives no callback), then re-arm the thresholds like "Later".
  Future<void> _appleReviewFlow({required bool force}) async {
    if (force && kAppleAppId.isNotEmpty) {
      try {
        await launchUrl(
          Uri.parse('$kAppStoreUrl?action=write-review'),
          mode: LaunchMode.externalApplication,
        );
        return;
      } catch (e) {
        debugPrint('RateService: write-review URL failed: $e');
      }
    }
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      }
    } catch (e) {
      debugPrint('RateService: requestReview failed: $e');
    }
    if (!force) await _recordLater();
  }

  /// Native in-app review sheet, falling back to the store listing and then
  /// to the store web URL for the current platform (the original positive
  /// store button opened the Play listing). Never opens the Play URL on
  /// Apple platforms.
  Future<void> _openStoreReview() async {
    try {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        return;
      }
    } catch (e) {
      debugPrint('RateService: requestReview failed: $e');
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      try {
        // market://details deep link, like the original.
        await InAppReview.instance.openStoreListing();
        return;
      } catch (e) {
        debugPrint('RateService: openStoreListing fallback to URL: $e');
      }
    }
    final url = storeUrlForCurrentPlatform;
    if (url == null) return; // Apple platform without an App Store id yet.
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('RateService: failed to open store URL: $e');
    }
  }

  Future<void> _recordLater() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showLaterKey, true);
      await prefs.setInt(
        _laterMillisKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setInt(
        _launchCountAtLaterKey,
        prefs.getInt(_launchCountKey) ?? 0,
      );
    } catch (e) {
      debugPrint('RateService: failed to record "later": $e');
    }
  }

  Future<void> _recordNever() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_neverKey, true);
    } catch (e) {
      debugPrint('RateService: failed to record "never": $e');
    }
  }

  Future<void> _recordAgreed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_agreedKey, true);
    } catch (e) {
      debugPrint('RateService: failed to record "agreed": $e');
    }
  }
}
