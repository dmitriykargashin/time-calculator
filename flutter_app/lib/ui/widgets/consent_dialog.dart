import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../services/analytics_service.dart';

/// One-time analytics consent dialog for EEA / UK / Switzerland users (GDPR /
/// Consent Mode). Shown after the first frame in [_Home] only when
/// [AnalyticsService.needsConsentPrompt] is true. NOT dismissible without a
/// choice; either choice is recorded via [AnalyticsService.setConsentGranted]
/// (default DENIED if somehow dismissed), so the dialog never reappears. The
/// user can change the choice later from the Settings consent row.
Future<void> showAnalyticsConsentDialog(BuildContext context) async {
  final granted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      // No silent dismiss: a choice must be made (back press = "No thanks").
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(dialogContext).pop(false);
      },
      child: AlertDialog(
        title: const Text('Help improve the app?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We use Google Analytics and your device’s advertising ID '
              'to understand app usage and measure our ad campaigns, so we can '
              'improve and grow Time Calculator. We don’t show ads in the '
              'app and never sell your data. You can change this anytime in '
              'Settings.',
            ),
            if (kPrivacyPolicyUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => launchUrl(
                  Uri.parse(kPrivacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    color: Theme.of(dialogContext).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('No thanks'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    ),
  );
  await AnalyticsService.instance.setConsentGranted(granted ?? false);
}
