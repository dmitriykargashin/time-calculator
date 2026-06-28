import 'package:flutter/material.dart';

import '../services/monetization.dart';
import 'theme.dart';

/// Shows the Apple-only "Pro" paywall as a modal bottom sheet.
///
/// Unlike the Formats/Per/Settings overlays this is NOT the circular-reveal
/// overlay - it is a self-contained modal, so it can be presented from ANY
/// screen (the Per action, a locked format row, the dark-theme radio).
///
/// Contents:
/// * the four unlocks (the value/"Per" calculator, all result formats, custom
///   keypad, and unlimited history);
/// * an "Unlock Pro" button - its label includes [Monetization.proPrice] when
///   known, it calls [Monetization.buyPro], and it is disabled with a subtle
///   "coming soon" note while [Monetization.canBuyPro] is false (i.e. before
///   Apple billing goes live or before the product loads);
/// * a "Restore Purchases" action ([Monetization.restore]).
///
/// The sheet closes itself the moment [Monetization.isProUnlocked] flips true
/// (the purchase stream grants Pro asynchronously). Styled with AppPalette /
/// Dimens / ABeeZee so it reads correctly in BOTH light and dark.
Future<void> showProPaywall(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppPalette.of(context).secondaryBackground,
    showDragHandle: true,
    builder: (context) => const _ProPaywall(),
  );
}

class _ProPaywall extends StatefulWidget {
  const _ProPaywall();

  @override
  State<_ProPaywall> createState() => _ProPaywallState();
}

class _ProPaywallState extends State<_ProPaywall> {
  final Monetization _monetization = Monetization.instance;

  /// True while a Restore round-trip is in flight: disables the button and
  /// shows a spinner so the store-mandated control never looks dead on tap.
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _monetization.addListener(_onMonetizationChanged);
  }

  @override
  void dispose() {
    _monetization.removeListener(_onMonetizationChanged);
    super.dispose();
  }

  void _onMonetizationChanged() {
    if (!mounted) return;
    // Close the moment Pro becomes owned (granted via the purchase stream).
    if (_monetization.isProUnlocked) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {});
  }

  /// Runs the store-mandated "Restore Purchases" action with feedback: a brief
  /// in-button busy state, and - on completion WITHOUT an unlock - a transient
  /// "No purchases to restore" message so a no-op tap is never silent. On a
  /// successful restore the listener auto-closes the sheet instead.
  Future<void> _onRestore() async {
    if (_restoring) return;
    setState(() => _restoring = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _monetization.restore();
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
    // If the restore granted Pro, the listener already popped the sheet; only
    // surface the "nothing to restore" message on the still-locked path.
    if (mounted && !_monetization.isProUnlocked) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No purchases to restore')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dim = Dimens.of(context);
    final palette = AppPalette.of(context);
    final canBuy = _monetization.canBuyPro;
    final price = _monetization.proPrice;
    final unlockLabel = price != null ? 'Unlock Pro – $price' : 'Unlock Pro';

    return SafeArea(
      // Scroll so a short viewport (small phone / landscape) or large text
      // scaling scrolls the fixed stack inside the sheet instead of tripping a
      // bottom RenderFlex overflow. isScrollControlled is already true, so the
      // sheet grows to fit when the content does.
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            dim.margin16,
            dim.margin8,
            dim.margin16,
            dim.margin16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Unlock Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: dim.settingsItemTextSize + 4,
                  fontWeight: FontWeight.bold,
                  color: palette.nums,
                ),
              ),
              SizedBox(height: dim.margin8),
              Text(
                'A one-time purchase unlocks everything below, forever.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: dim.settingsGroupTextSize,
                  color: palette.resultNums,
                  height: 1 + 4 / dim.settingsGroupTextSize,
                ),
              ),
              SizedBox(height: dim.margin16 + dim.margin8),
              _unlockRow(
                dim,
                palette,
                Icons.calculate_outlined,
                'The value calculator',
                'Use "Per" to work out salary, distance and any other '
                    'amount-per-time-interval.',
              ),
              SizedBox(height: dim.margin16),
              _unlockRow(
                dim,
                palette,
                Icons.format_list_bulleted,
                'All result formats',
                'Every time format for the result, not just the basic ones.',
              ),
              SizedBox(height: dim.margin16),
              _unlockRow(
                dim,
                palette,
                Icons.dialpad,
                'Custom keypad',
                'Pick any time-unit keys and every preset, beyond the two '
                    'free layouts.',
              ),
              SizedBox(height: dim.margin16),
              _unlockRow(
                dim,
                palette,
                Icons.history,
                'Unlimited history',
                'Keep every calculation, not just the last five.',
              ),
              SizedBox(height: dim.margin16 + dim.margin8),
              ElevatedButton(
                onPressed: canBuy ? () => _monetization.buyPro() : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(unlockLabel),
              ),
              if (!canBuy) ...[
                SizedBox(height: dim.margin8),
                Text(
                  'Coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dim.settingsGroupTextSize - 2,
                    // Full-opacity resultNums (>=4.5:1 in both themes); the
                    // disabled button already conveys "not available", so the
                    // note must not be dimmed below the AA contrast floor.
                    color: palette.resultNums,
                  ),
                ),
              ],
              SizedBox(height: dim.margin8),
              TextButton(
                onPressed: _restoring ? null : _onRestore,
                child: _restoring
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'Restore Purchases',
                        // Raw accent (#0099CC) only clears AA on the dark
                        // sheet; in light it is 2.67:1. Use palette.nums there
                        // so the store-mandated control stays legible.
                        style: TextStyle(color: _restoreLabelColor(palette)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The "Restore Purchases" label color: the accent reads fine on the dark
  /// sheet (5.69:1) but fails AA on the light sheet (2.67:1 on #E8E8E8), so
  /// light mode falls back to the high-contrast [AppPalette.nums].
  Color _restoreLabelColor(AppPalette palette) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppPalette.accent
      : palette.nums;

  /// One "what you get" row: accent icon + title and one-line description.
  Widget _unlockRow(
    Dimens dim,
    AppPalette palette,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppPalette.accent, size: 28),
        SizedBox(width: dim.margin16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: dim.settingsItemTextSize,
                  fontWeight: FontWeight.w600,
                  color: palette.nums,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: dim.settingsGroupTextSize - 2,
                  color: palette.resultNums,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
