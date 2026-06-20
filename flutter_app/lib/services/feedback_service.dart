import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

/// Android versionCode, from pubspec.yaml `version: 2.1.0+25`.
/// Keep in sync with pubspec when bumping releases.
const int _appVersionCode = 25;

/// Subject pattern verbatim from the original Settings "Send Feedback":
/// "Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}".
const String kFeedbackSubject =
    'Feedback Time Calculator Cardamon $_appVersionCode';

/// Subject variant used by the rating dialog's mail-feedback step, verbatim:
/// "Feedback Time Calculator Cardamon v.${BuildConfig.VERSION_CODE}"
/// (note the "v." prefix - only the rating-dialog mail has it).
const String kRatingFeedbackSubject =
    'Feedback Time Calculator Cardamon v.$_appVersionCode';

/// Opens a mail compose window addressed to [kFeedbackEmail] with the
/// original subject (the original ACTION_SENDTO mailto: intent). When no
/// mail client can handle the request, falls back to the system share sheet.
///
/// [subject] defaults to the Settings-screen pattern; the rating flow passes
/// [kRatingFeedbackSubject].
Future<void> sendFeedback({String subject = kFeedbackSubject}) async {
  final mailto = Uri(
    scheme: 'mailto',
    path: kFeedbackEmail,
    query: 'subject=${Uri.encodeComponent(subject)}',
  );
  try {
    if (await launchUrl(mailto)) return;
  } catch (e) {
    debugPrint('sendFeedback: no mail client, using share sheet: $e');
  }
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: '$subject - $kFeedbackEmail',
        subject: subject,
      ),
    );
  } catch (e) {
    debugPrint('sendFeedback: share fallback failed: $e');
  }
}
