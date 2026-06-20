import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../services/analytics_service.dart';
import '../services/feedback_service.dart';
import '../services/monetization.dart';
import '../state/settings_model.dart';
import 'formats_screen.dart' show overlayHeader;
import 'pro_screen.dart';
import 'theme.dart';

/// Full-screen "Settings" overlay (RemoveADS view_settings.xml), opened with
/// the same circular reveal as Formats/Per.
///
/// MATERIAL 3 EXPRESSIVE restyle (matches the redesigned calculator's two
/// rounded tonal cards): the old flat, edge-to-edge rows on a single panel are
/// regrouped into rounded tonal SECTIONS that float on [mainBackground] -
/// * an optional Pro section (gated builds only);
/// * a "THEME" section: System default / Light / Dark radio rows - selecting
///   one applies the ThemeMode IMMEDIATELY and persists "0"/"1"/"2" via
///   [SettingsModel] (PREF_THEME_COLOR);
/// * a "FEEDBACK" section: a "Send Feedback" row -> [sendFeedback]
///   (mailto support@cardamon.org).
///
/// All cards reuse the calculator's [AppPalette.displayCardSurface] /
/// [AppPalette.toolButtonFill] tokens and [Dimens.cardRadius] so the overlay
/// reads as the same surface idiom, not a dated grey list. Every row keeps its
/// >=48dp tap target and the Pro gating (locks + paywall) is unchanged.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.onClose});

  /// Toolbar back-arrow handler (closes with the top-left reveal center).
  final VoidCallback onClose;

  /// Outer screen padding around the floating sections - mirrors the
  /// calculator's 16dp screen margins so the two screens share a left grid.
  static const double _screenPadH = 16;

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    return Material(
      // Float the tonal sections on the main background, like the calculator's
      // two cards (the old flat secondaryBackground panel is retired).
      color: palette.mainBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Reuse the shared modern overlay header so Settings reads as the same
          // chrome family as Formats/Per (identical back-button cell radius and
          // title spec: 20sp w600 in controlsStrong, which also lifts the light
          // title contrast from ~5.3:1 to 9.17:1).
          overlayHeader(
            title: 'Settings',
            onClose: onClose,
            dim: dim,
            palette: palette,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                _screenPadH,
                4,
                _screenPadH,
                24,
              ),
              child: ListenableBuilder(
                // Rebuild on theme changes AND on Pro unlock (the latter clears
                // the theme-row locks and flips the Pro row instantly).
                listenable: Listenable.merge(
                  [SettingsModel.instance, Monetization.instance],
                ),
                builder: (context, _) {
                  final settings = SettingsModel.instance;
                  final monetization = Monetization.instance;
                  // Theme is gated only where Pro gating is on and not unlocked;
                  // then only "Light" is selectable (matching effectiveThemeMode)
                  // and System/Dark route to the paywall.
                  final themeGated =
                      monetization.isProGated && !monetization.isProUnlocked;
                  // While gated the radio reflects the forced Light selection;
                  // the stored "0"/"1"/"2" value is preserved underneath.
                  final selectedThemeValue = themeGated
                      ? SettingsModel.themeValueLight
                      : settings.themeValue;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (monetization.isProGated) ...[
                        _section(
                          dim,
                          palette,
                          children: [
                            _proRow(context, monetization, dim, palette),
                          ],
                        ),
                        SizedBox(height: dim.margin16),
                      ],
                      _sectionLabel('THEME', dim, palette),
                      // The three theme radios live in one tonal card, split by
                      // soft inset dividers (instead of edge-to-edge hairlines).
                      RadioGroup<String>(
                        groupValue: selectedThemeValue,
                        onChanged: (value) {
                          if (value != null) settings.setThemeValue(value);
                        },
                        child: _section(
                          dim,
                          palette,
                          children: [
                            _themeRow(
                              'System default',
                              SettingsModel.themeValueSystem,
                              dim,
                              palette,
                              locked: themeGated,
                              onLocked: () => showProPaywall(context),
                            ),
                            _innerDivider(palette),
                            _themeRow(
                              'Light',
                              SettingsModel.themeValueLight,
                              dim,
                              palette,
                            ),
                            _innerDivider(palette),
                            _themeRow(
                              'Dark',
                              SettingsModel.themeValueDark,
                              dim,
                              palette,
                              locked: themeGated,
                              onLocked: () => showProPaywall(context),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: dim.margin16),
                      _sectionLabel('FEEDBACK', dim, palette),
                      _section(
                        dim,
                        palette,
                        children: [_feedbackRow(dim, palette)],
                      ),
                      // PRIVACY section: the always-available Privacy Policy
                      // link (Google requires the policy to be reachable inside
                      // the app) plus the analytics-consent toggle when analytics
                      // is active.
                      _privacySection(dim, palette),
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

  /// A rounded tonal SECTION card (the calculator's display-card surface +
  /// cardRadius) holding one or more rows. Clipped so the row ink ripples and
  /// the inset dividers stay inside the rounded corners.
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

  /// Small-caps group label (tvTheme / tvFeedbackG) sitting ABOVE its card, in
  /// the muted controls tint - the grouping cue without a flat header band.
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

  /// Soft inset hairline between rows WITHIN a card (indented so it reads as a
  /// row separator, not an edge-to-edge rule).
  Widget _innerDivider(AppPalette palette) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: palette.shadowBase.withValues(alpha: 0.5),
    );
  }

  /// One theme radio row inside the THEME card: min height
  /// settings_item_min_height, label at settings_item_text_size in
  /// colorResultNums. Tapping anywhere on the row selects it.
  ///
  /// When [locked] (Pro gating on, not unlocked) the row shows a trailing lock
  /// and tapping it runs [onLocked] (the paywall) instead of switching theme.
  Widget _themeRow(
    String label,
    String value,
    Dimens dim,
    AppPalette palette, {
    bool locked = false,
    VoidCallback? onLocked,
  }) {
    return InkWell(
      onTap: locked
          ? onLocked
          : () => SettingsModel.instance.setThemeValue(value),
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 12, end: 20),
        child: Row(
          children: [
            // Locked rows ignore the radio (it can never be the forced-Light
            // selection); the lock_outline carries the affordance instead.
            IgnorePointer(child: Radio<String>(value: value)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
            if (locked)
              Icon(
                Icons.lock_outline,
                color: palette.controlsStrong,
                semanticLabel: 'Locked (Pro)',
              ),
          ],
        ),
      ),
    );
  }

  /// The "Send Feedback" row inside the FEEDBACK card.
  Widget _feedbackRow(Dimens dim, AppPalette palette) {
    return InkWell(
      onTap: () {
        AnalyticsService.instance.buttonFeedback();
        sendFeedback();
      },
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
        child: Row(
          children: [
            Icon(
              Icons.mail_outline,
              color: palette.controlsStrong,
              semanticLabel: null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Send Feedback',
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The PRIVACY section: the Privacy Policy link (whenever [kPrivacyPolicyUrl]
  /// is set - it is required to be reachable in-app once the app collects
  /// analytics) and, where analytics is actually active, the consent toggle.
  /// Collapses to nothing when neither applies.
  Widget _privacySection(Dimens dim, AppPalette palette) {
    final showPolicy = kPrivacyPolicyUrl.isNotEmpty;
    final showConsent = AnalyticsService.instance.isEnabled;
    if (!showPolicy && !showConsent) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: dim.margin16),
        _sectionLabel('PRIVACY', dim, palette),
        _section(
          dim,
          palette,
          children: [
            if (showPolicy) _privacyPolicyRow(dim, palette),
            if (showPolicy && showConsent) _innerDivider(palette),
            if (showConsent) _analyticsRow(dim, palette),
          ],
        ),
      ],
    );
  }

  /// Opens [kPrivacyPolicyUrl] in the browser - a persistent in-app entry point
  /// to the policy (Google requires the policy be reachable from inside the app,
  /// not only from the first-launch consent dialog).
  Widget _privacyPolicyRow(Dimens dim, AppPalette palette) {
    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(kPrivacyPolicyUrl),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
        child: Row(
          children: [
            Icon(Icons.privacy_tip_outlined, color: palette.controlsStrong),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
            Icon(Icons.open_in_new, size: 18, color: palette.controlsStrong),
          ],
        ),
      ),
    );
  }

  /// The analytics-consent toggle (PRIVACY card). Lets the user grant OR
  /// withdraw analytics consent at any time (GDPR: withdrawal as easy as
  /// granting). A StatefulBuilder holds the toggle state since AnalyticsService
  /// is not a ChangeNotifier. Default ON outside the consent regions (where
  /// analytics runs without a prompt); reflects the stored choice otherwise.
  Widget _analyticsRow(Dimens dim, AppPalette palette) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        final granted = AnalyticsService.instance.consentGranted ?? true;
        void toggle(bool value) {
          AnalyticsService.instance.setConsentGranted(value);
          setLocalState(() {});
        }

        return InkWell(
          onTap: () => toggle(!granted),
          child: Container(
            constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
            padding: const EdgeInsetsDirectional.only(start: 20, end: 12),
            child: Row(
              children: [
                Icon(Icons.insights_outlined, color: palette.controlsStrong),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Share anonymous usage analytics',
                    style: TextStyle(
                      color: palette.resultNums,
                      fontSize: dim.settingsItemTextSize,
                    ),
                  ),
                ),
                Switch(value: granted, onChanged: toggle),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The Pro entitlement row, shown only where gating is on. Locked: an
  /// "Unlock Pro" action opening the paywall. Unlocked: a non-interactive
  /// "Pro unlocked" with a check.
  Widget _proRow(
    BuildContext context,
    Monetization monetization,
    Dimens dim,
    AppPalette palette,
  ) {
    if (monetization.isProUnlocked) {
      return Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
        child: Row(
          children: [
            Icon(Icons.check, color: AppPalette.supportStarOf(context)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pro unlocked',
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return InkWell(
      onTap: () => showProPaywall(context),
      child: Container(
        constraints: BoxConstraints(minHeight: dim.settingsItemMinHeight),
        padding: const EdgeInsetsDirectional.only(start: 20, end: 20),
        child: Row(
          children: [
            Icon(Icons.lock_open, color: palette.controlsStrong),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unlock Pro',
                style: TextStyle(
                  color: palette.resultNums,
                  fontSize: dim.settingsItemTextSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
