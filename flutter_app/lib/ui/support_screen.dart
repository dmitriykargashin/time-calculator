import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/monetization.dart';
import '../services/rate_service.dart';
import '../services/share_service.dart';
import 'formats_screen.dart' show overlayHeader;
import 'theme.dart';

/// support_app_text, verbatim from the RemoveADS strings.xml (including the
/// literal leading space after the first newline).
const String kSupportAppText =
    'For your best user experience, the application is now free and '
    'ad-free.\n If you would like to support me, as a developer of the app, '
    'you can buy me some CUPS of TEA.\nAny purchase will give you a green '
    'star next to the corresponding tier\n\nYou can also leave a '
    'review or share to help improve the app.';

/// Copy for platforms where purchases are unavailable (iOS/macOS until App
/// Store Connect products exist; web has no IAP): same message minus the
/// tea/star sentences, since no buy buttons are shown there.
const String kSupportAppTextNoPurchases =
    'For your best user experience, the application is free and ad-free.'
    '\n\nYou can leave a review or share to help improve the app.';

/// Full-screen "Support the app" overlay (RemoveADS view_support_app.xml),
/// opened from the tea-cup action button with the same circular reveal as
/// Formats/Per.
///
/// MATERIAL 3 EXPRESSIVE restyle (matches Settings/Per/Formats): the old
/// custom toolbar + flat secondary-background panel + generic elevated buttons
/// are replaced by the shared modern [overlayHeader], the [AppPalette.mainBackground]
/// float, and rounded tonal SECTION cards of rows:
/// * the [kSupportAppText] message;
/// * a "BUY ME A TEA" section: one row per tier (SKUs support_1/3/5/9) - an
///   owned tier shows the green thank-you star and disables its row (legacy
///   remove_ads ownership lights up the 3-cups row via [Monetization.isOwned]);
/// * a "HELP THE APP" section: "Leave a review" -> the custom rating dialog
///   (bypassing all thresholds) and "Share the app" -> the plain-text share.
///
/// Buy rows exist ONLY where billing actually works (dead purchase UI is an App
/// Store 2.1 rejection); elsewhere just the message + the two help rows show.
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key, required this.onClose});

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  /// Outer screen padding around the floating sections - mirrors Settings.
  static const double _screenPadH = 16;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      color: palette.mainBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          overlayHeader(
            title: 'Support the app',
            onClose: onClose,
            dim: dim,
            palette: palette,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(_screenPadH, 4, _screenPadH, 24),
              child: ListenableBuilder(
                listenable: Monetization.instance,
                builder: (context, _) {
                  // Buy rows exist ONLY where billing actually works - dead
                  // purchase UI is an App Store 2.1 rejection.
                  final canBuy = Monetization.instance.isBillingAvailable;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _message(canBuy, palette),
                      SizedBox(height: dim.margin16),
                      if (canBuy) ...[
                        _sectionLabel('BUY ME A TEA', dim, palette),
                        _section(
                          dim,
                          palette,
                          children: [
                            _tierRow(context, 'buy 1 Cup', 'support_1', dim,
                                palette),
                            _innerDivider(palette),
                            _tierRow(context, 'buy 3 Cups', 'support_3', dim,
                                palette),
                            _innerDivider(palette),
                            _tierRow(context, 'buy 5 Cups', 'support_5', dim,
                                palette),
                            _innerDivider(palette),
                            _tierRow(context, 'buy 9 Cups', 'support_9', dim,
                                palette),
                          ],
                        ),
                        SizedBox(height: dim.margin16),
                      ],
                      _sectionLabel('HELP THE APP', dim, palette),
                      _section(
                        dim,
                        palette,
                        children: [
                          _actionRow(
                            label: 'Leave a review',
                            // ic_star_blue_24dp (accent-colored star).
                            icon: const Icon(Icons.star,
                                color: AppPalette.accent),
                            dim: dim,
                            palette: palette,
                            onTap: () {
                              AnalyticsService.instance.buttonSupportRate();
                              RateService.instance
                                  .showRatingFlow(context, force: true);
                            },
                          ),
                          _innerDivider(palette),
                          _actionRow(
                            label: 'Share the app',
                            // ic_baseline_share_24 (accent, alpha 0.8).
                            icon: Icon(Icons.share,
                                color: AppPalette.accent.withValues(alpha: 0.8)),
                            dim: dim,
                            palette: palette,
                            onTap: () {
                              AnalyticsService.instance.buttonShareTheApp();
                              shareTheApp();
                            },
                          ),
                        ],
                      ),
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

  /// The intro message (centered), in the muted strong-control tint so it reads
  /// as the same calm secondary copy the other overlays use.
  Widget _message(bool canBuy, AppPalette palette) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 0),
      child: Text(
        canBuy ? kSupportAppText : kSupportAppTextNoPurchases,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 15,
          color: palette.controlsStrong,
          height: 1.45,
        ),
      ),
    );
  }

  /// A rounded tonal SECTION card holding one or more rows - the Settings/Per
  /// card idiom (displayCardSurface + cardRadius, clipped for the row ripples).
  Widget _section(
    Dimens dim,
    AppPalette palette, {
    required List<Widget> children,
  }) {
    return Material(
      color: palette.displayCardSurface,
      borderRadius: BorderRadius.circular(dim.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  /// Small-caps group label sitting ABOVE its card, in the muted controls tint.
  Widget _sectionLabel(String text, Dimens dim, AppPalette palette) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 8),
      child: Text(
        text,
        style: TextStyle(
          color: palette.controlsStrong,
          fontSize: dim.settingsGroupTextSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  /// Soft inset hairline between rows WITHIN a card.
  Widget _innerDivider(AppPalette palette) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      // controlsStrong adapts (dark line in light theme, light line in dark),
      // so the separator stays visible on the near-black dark card surface.
      color: palette.controlsStrong.withValues(alpha: 0.25),
    );
  }

  /// One "buy N Cup(s)" tier row: the tea-cup glyph, the tier label, and a
  /// trailing affordance - the green thank-you star when the tier is owned
  /// (the row is then disabled and its lead dims), otherwise a chevron. Tapping
  /// a not-owned row starts the purchase.
  Widget _tierRow(
    BuildContext context,
    String label,
    String sku,
    Dimens dim,
    AppPalette palette,
  ) {
    final owned = Monetization.instance.isOwned(sku);
    return InkWell(
      onTap: owned
          ? null
          : () {
              AnalyticsService.instance.buttonSupportTier(sku);
              Monetization.instance.buy(sku);
            },
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 16),
        child: Row(
          children: [
            // The lead (icon + label) dims when owned so the row reads as
            // already-supported; the star stays bright as the positive cue.
            Opacity(
              opacity: owned ? 0.55 : 1.0,
              child: Icon(Icons.emoji_food_beverage,
                  color: palette.controlsStrong),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: owned ? 0.55 : 1.0,
                child: Text(
                  label,
                  style: TextStyle(
                    color: palette.resultNums,
                    fontSize: dim.settingsItemTextSize,
                  ),
                ),
              ),
            ),
            if (owned)
              Icon(
                Icons.star,
                color: AppPalette.supportStarOf(context),
                size: 24,
                semanticLabel: 'Owned',
              )
            else
              Icon(
                Icons.chevron_right,
                size: 22,
                color: palette.controlsStrong.withAlpha(0x99),
              ),
          ],
        ),
      ),
    );
  }

  /// A "Leave a review" / "Share the app" row inside the HELP card.
  Widget _actionRow({
    required String label,
    required Widget icon,
    required VoidCallback onTap,
    required Dimens dim,
    required AppPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: palette.controlsStrong.withAlpha(0x99),
            ),
          ],
        ),
      ),
    );
  }
}
