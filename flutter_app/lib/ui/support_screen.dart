import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/monetization.dart';
import '../services/rate_service.dart';
import '../services/share_service.dart';
import 'theme.dart';

/// support_app_text, verbatim from the RemoveADS strings.xml (including the
/// literal leading space after the first newline).
const String kSupportAppText =
    'For your best user experience, the application is now free and '
    'ad-free.\n If you would like to support me, as a developer of the app, '
    'you can buy me some CUPS of TEA.\nAny purchase will give you a green '
    'star to the right of the corresponding button\n\nYou can also leave a '
    'review or share to help improve the app.';

/// Copy for platforms where purchases are unavailable (iOS/macOS until App
/// Store Connect products exist; web has no IAP): same message minus the
/// tea/star sentences, since no buy buttons are shown there.
const String kSupportAppTextNoPurchases =
    'For your best user experience, the application is free and ad-free.'
    '\n\nYou can leave a review or share to help improve the app.';

/// Full-screen "The app development support" overlay (RemoveADS
/// view_support_app.xml), opened from the tea-cup action button with the
/// same circular reveal as Formats/Per:
/// * the [kSupportAppText] paragraph;
/// * four 200dp "buy N Cup(s)" buttons (SKUs support_1/3/5/9) - an owned
///   tier shows the green thank-you star and its button is disabled at 50%
///   opacity (legacy remove_ads ownership lights up the 3-cups row via
///   [Monetization.isOwned]);
/// * "Leave a review" -> the custom rating dialog, bypassing all thresholds;
/// * "Share the app" -> plain-text share of the verbatim emoji copy.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, required this.onClose});

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  /// The four 200dp-wide buttons (and their star/spacer gutters).
  static const double _buttonWidth = 200;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.secondaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: palette.secondaryBackground,
            height: kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: onClose,
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Text(
                    'The app development support',
                    style: TextStyle(fontSize: 20),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(top: dim.margin16),
              child: ListenableBuilder(
                listenable: Monetization.instance,
                builder: (context, _) {
                  // Buy buttons exist ONLY where billing actually works -
                  // dead purchase UI is an App Store 2.1 rejection.
                  final canBuy = Monetization.instance.isBillingAvailable;
                  return Column(
                  children: [
                    Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: dim.margin16),
                      child: Text(
                        canBuy ? kSupportAppText : kSupportAppTextNoPurchases,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: dim.settingsGroupTextSize,
                          // lineSpacingExtra 4sp.
                          height: 1 + 4 / dim.settingsGroupTextSize,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (canBuy) ...[
                      _buyRow(context, 'buy 1 Cup', 'support_1'),
                      const SizedBox(height: 16),
                      _buyRow(context, 'buy 3 Cups', 'support_3'),
                      const SizedBox(height: 16),
                      _buyRow(context, 'buy 5 Cups', 'support_5'),
                      const SizedBox(height: 16),
                      _buyRow(context, 'buy 9 Cups', 'support_9'),
                      const SizedBox(height: 16),
                    ],
                    _actionButton(
                      label: 'Leave a review',
                      // ic_star_blue_24dp (accent-colored star).
                      icon: const Icon(
                        Icons.star,
                        color: AppPalette.accent,
                        size: 24,
                      ),
                      onPressed: () {
                        AnalyticsService.instance.buttonSupportRate();
                        RateService.instance
                            .showRatingFlow(context, force: true);
                      },
                    ),
                    const SizedBox(height: 16),
                    _actionButton(
                      label: 'Share the app',
                      // ic_baseline_share_24 (accent, alpha 0.8).
                      icon: Icon(
                        Icons.share,
                        color: AppPalette.accent.withValues(alpha: 0.8),
                        size: 24,
                      ),
                      onPressed: () {
                        AnalyticsService.instance.buttonShareTheApp();
                        shareTheApp();
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One "buy N Cup(s)" row: the 200dp button with the tea-cup icon, and -
  /// when the SKU is owned - the green thank-you star to its right plus a
  /// disabled button at 50% opacity. The invisible leading gutter mirrors
  /// the star gutter so the button itself stays optically centered (the
  /// Android layout centered the button and hung the star off its end).
  Widget _buyRow(BuildContext context, String label, String sku) {
    final owned = Monetization.instance.isOwned(sku);
    // No price on the button: the actual localized price is shown by Google
    // Play's purchase sheet when the user taps. (Keeps the row simple and avoids
    // a price that could lag the store.)
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 40),
        Opacity(
          opacity: owned ? 0.5 : 1.0,
          child: SizedBox(
            width: _buttonWidth,
            child: ElevatedButton.icon(
              onPressed: owned
                  ? null
                  : () {
                      AnalyticsService.instance.buttonSupportTier(sku);
                      Monetization.instance.buy(sku);
                    },
              icon: const Icon(Icons.emoji_food_beverage, size: 24),
              label: Text(label),
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 24,
          height: 24,
          // ic_star_green_24dp, visible only when the tier is owned;
          // brightened in dark so it clears the 3:1 icon-contrast floor on
          // the dark card.
          child: owned
              ? Icon(
                  Icons.star,
                  color: AppPalette.supportStarOf(context),
                  size: 24,
                  semanticLabel: 'Owned',
                )
              : null,
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required Widget icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: _buttonWidth,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: icon,
        label: Text(label),
      ),
    );
  }
}
