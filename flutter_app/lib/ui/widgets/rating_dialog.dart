import 'package:flutter/material.dart';

/// Strings of the rating flow, verbatim from the RemoveADS branch
/// res/values/strings.xml.
const String kRateMainText =
    'How was your experience with the Time Calculator?';
const String kRateSecondText = 'The app is absolutely free.\n'
    'You can contribute to the development of the app by writing a review!';
const String kRateStoreSecondText =
    'If you enjoy using this app, would you mind taking a moment to rate it '
    'in the store?\n\nYour review will help this app develop further.';
const String kRateFeedbackMainText =
    "I want to improve the App with your help. Don't hesitate to send an "
    'email with your suggestions.\n\nSend an email?';

/// `never_show_ratetheapp` - custom label for the opt-out button.
const String kRateNeverText = 'NEVER';

// Default labels/titles of awesome-app-rating 2.3.0 (the app overrode only
// the texts above), verbatim from the library's values/strings.xml:
// rating_dialog_button_rate_later / rating_dialog_overview_button_confirm /
// rating_dialog_store_title / rating_dialog_store_button_rate_now /
// rating_dialog_feedback_title / rating_dialog_feedback_button_cancel /
// rating_dialog_feedback_mail_button_send.
const String kRateLaterText = 'Later';
const String kRateConfirmText = 'Confirm';
const String kRateStoreTitle = 'Store Rating';
const String kRateStoreButtonText = 'Rate';
const String kRateFeedbackTitle = 'Give Feedback';
const String kRateFeedbackCancelText = 'Cancel';
const String kRateFeedbackSendText = 'Send';

/// What the user chose in the star [RatingDialog].
enum RatingDialogAction {
  /// Confirmed a star rating ([RatingDialogResult.rating] is 1-5).
  confirmed,

  /// "Later" - ask again after the show-again thresholds.
  later,

  /// "NEVER" - suppress the automatic prompt forever.
  never,
}

/// Result popped by [RatingDialog.show].
class RatingDialogResult {
  const RatingDialogResult(this.action, [this.rating = 0]);

  final RatingDialogAction action;

  /// Selected stars (1-5); meaningful only when [action] is
  /// [RatingDialogAction.confirmed].
  final int rating;
}

/// Custom star-rating dialog - the Flutter port of awesome-app-rating
/// 2.3.0's custom Material dialog (NOT the native review sheet): title
/// [kRateMainText], message [kRateSecondText], a row of five FULL stars
/// (`setShowOnlyFullStars(true)` - no half stars), Confirm disabled until a
/// star is selected, a Later button, and (from the 3rd automatic prompt
/// only) a NEVER opt-out button. Used by `RateService.showRatingFlow`.
class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key, this.showNeverButton = false});

  /// Whether the NEVER opt-out button is offered (automatic prompts only,
  /// from the 3rd time the dialog is shown; never on the manual
  /// "Leave a review" path).
  final bool showNeverButton;

  /// Shows the dialog. Not barrier-dismissible (the library dialog is not
  /// cancelable); resolves with the user's choice.
  static Future<RatingDialogResult?> show(
    BuildContext context, {
    bool showNeverButton = false,
  }) {
    return showDialog<RatingDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => RatingDialog(showNeverButton: showNeverButton),
    );
  }

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  /// 0 = nothing selected yet; otherwise 1-5 full stars.
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text(kRateMainText),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(kRateSecondText),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => setState(() => _rating = star),
                  tooltip: '$star',
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: colorScheme.primary,
                    size: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.showNeverButton)
          TextButton(
            onPressed: () => Navigator.of(context).pop(
              const RatingDialogResult(RatingDialogAction.never),
            ),
            child: const Text(kRateNeverText),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const RatingDialogResult(RatingDialogAction.later),
          ),
          child: const Text(kRateLaterText),
        ),
        TextButton(
          // Disabled until a star is selected, like the library's dialog.
          onPressed: _rating == 0
              ? null
              : () => Navigator.of(context).pop(
                    RatingDialogResult(RatingDialogAction.confirmed, _rating),
                  ),
          child: const Text(kRateConfirmText),
        ),
      ],
    );
  }
}

/// The follow-up "store rating" step shown after a rating of 4+ stars:
/// library-default title, message [kRateStoreSecondText], Later / Rate.
/// Resolves true when the user agrees to rate in the store.
Future<bool> showStoreRatingPrompt(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text(kRateStoreTitle),
      content: const Text(kRateStoreSecondText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(kRateLaterText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(kRateStoreButtonText),
        ),
      ],
    ),
  );
  return agreed ?? false;
}

/// The follow-up "mail feedback" step shown after a rating below 4 stars:
/// library-default title, message [kRateFeedbackMainText], Cancel / Send.
/// Resolves true when the user agrees to send a feedback email.
Future<bool> showMailFeedbackPrompt(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text(kRateFeedbackTitle),
      content: const Text(kRateFeedbackMainText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(kRateFeedbackCancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(kRateFeedbackSendText),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
