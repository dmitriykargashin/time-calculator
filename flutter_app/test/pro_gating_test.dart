import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/config.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/services/entitlements.dart';
import 'package:cardamon_time_calculator/services/monetization.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';
import 'package:cardamon_time_calculator/ui/formats_screen.dart';

/// Covers the Apple-only Pro gating in BOTH states, driven by the [Monetization]
/// test seam ([Monetization.debugSetProGated]) rather than the
/// [kApplePurchasesEnabled] compile-time const - so the same suite asserts the
/// gated (iOS go-live) world AND the ungated (Android, default) world.
///
/// The contract under test (PRO ENTITLEMENT CONTRACT v1):
/// * gating ON  => the Per icon, every non-free format card and the
///   System/Dark theme rows show a lock and route taps to the paywall (and do
///   NOT perform their underlying action); buying `pro_unlock` flips
///   [Monetization.hasPro] so the locks vanish and everything works again;
/// * gating OFF => no locks anywhere and Per/formats/dark behave exactly as in
///   the rest of the app.
///
/// `debugDefaultTargetPlatformOverride` is reset at the END of each test body
/// (not via tearDown): the foundation-debug-var invariant check runs before
/// tearDown callbacks, so a tearDown reset would trip "a foundation debug
/// variable was changed by the test".
void main() {
  final monetization = Monetization.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final model = CalculatorModel.instance;
    model.clearAll();
    // clearAll() leaves the overlay-visibility flags untouched; a fresh app in
    // the next test would otherwise render a Formats/Settings/Per overlay that
    // a previous test left "open" in this process singleton - covering the
    // calculator and blocking taps.
    model.setIsFormatsLayoutVisible(false);
    model.setIsPerLayoutVisible(false);
    model.setIsSupportAppLayoutVisible(false);
    model.setIsSettingsLayoutVisible(false);
    // The selected format ALSO persists in this singleton; reset it to the
    // default "Hour Minute" (index 18 per the repositories' seed order) so the
    // selected-format label every test taps to open Formats reads "Hour
    // Minute" rather than whatever the previous test selected.
    model.setSelectedFormat(18);
    monetization.debugReset();
    // Drop any dark choice a previous test stored (the SettingsModel singleton
    // persists across tests). AWAITED so the reset fully lands before the body
    // - an unawaited reset races with the body's own setThemeValue(Dark).
    await SettingsModel.instance.setThemeValue(SettingsModel.themeValueSystem);
    // Ownership/gating overrides must never leak into the suites that share
    // these process singletons (this is not a foundation var, so tearDown is
    // fine for it).
    addTearDown(monetization.debugReset);
  });

  /// A loaded fake [kProSku] product so [Monetization.canBuyPro] is true and
  /// the paywall shows a real price.
  ProductDetails proProduct() => ProductDetails(
        id: kProSku,
        title: 'Pro',
        description: 'One-time unlock',
        price: r'$2.99',
        rawPrice: 2.99,
        currencyCode: 'USD',
      );

  /// Enters the gated (Apple go-live) world: iOS platform + forced gating + a
  /// loaded Pro product. Must be paired with [leavePlatform] at the end of the
  /// body.
  void enterGated() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    monetization.debugSetProGated(true);
    monetization.debugSetProProduct(proProduct());
  }

  /// Enters the ungated (Android, default) world. No gating override - this is
  /// the production default on Android. Pair with [leavePlatform].
  void enterUngated() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(monetization.isProGated, isFalse,
        reason: 'Android is never gated by default');
  }

  /// Resets the foundation platform override. Call as the LAST line of every
  /// test body (see the file-level note on why tearDown is too late).
  void leavePlatform() => debugDefaultTargetPlatformOverride = null;

  /// Pumps a fresh app. Pumps a throwaway widget of a DIFFERENT type first so
  /// the previous test's MaterialApp element (and its Navigator) fully unmounts
  /// - otherwise Flutter reuses the element tree across tests and a paywall
  /// bottom sheet pushed by an earlier test lingers as a pointer-absorbing
  /// modal barrier over the keypad.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();
  }

  /// Types "5 Hour − 10 Minute" so a real result exists (the Per/Formats
  /// buttons gate on having a result first, independent of Pro gating).
  Future<void> typeSample(WidgetTester tester) async {
    for (final key in ['5', 'Hour', '–', '1', '0', 'Minute']) {
      await tester.tap(find.text(key).first);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Finder paywall() => find.text('Unlock Pro');

  /// Dismisses an open paywall bottom sheet so it does not linger as a
  /// pointer-absorbing modal into the next test (the modal route is pushed on
  /// the root Navigator and is NOT torn down by re-pumping the app root).
  Future<void> dismissPaywall(WidgetTester tester) async {
    final sheet = find.byType(BottomSheet);
    if (sheet.evaluate().isEmpty) return;
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pop();
    await tester.pumpAndSettle();
  }

  String? selectedFormatName() =>
      CalculatorModel.instance.selectedFormat.value?.textPresentationOfTokens;

  group('gating ON (Apple go-live simulation)', () {
    testWidgets('Per icon shows a lock and tapping opens the paywall, not the '
        'Per overlay', (tester) async {
      enterGated();
      await pumpApp(tester);
      await typeSample(tester);

      // The Per glyph carries the lock badge while gated and not unlocked. No
      // overlay is open, so the only lock on screen is the Per icon's badge.
      // (find.byIcon, not find.bySemanticsLabel: the semantics tree is not
      // built in widget tests without an active SemanticsHandle.)
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_time));
      await tester.pumpAndSettle();

      // The paywall opened ...
      expect(paywall(), findsOneWidget);
      expect(find.text('Restore Purchases'), findsOneWidget);
      // ... and the Per overlay did NOT (no per-unit calculator).
      expect(CalculatorModel.instance.isPerLayoutVisible, isFalse);

      await dismissPaywall(tester);
      leavePlatform();
    });

    testWidgets('a non-free format card shows a lock; tapping opens the '
        'paywall and does NOT change the selected format', (tester) async {
      enterGated();
      await pumpApp(tester);
      await typeSample(tester);

      // Open the Formats chooser via the (free) selected-format label.
      await tester.tap(find.text('Hour Minute'));
      await tester.pumpAndSettle();
      expect(find.text('Result format'), findsOneWidget);

      final before = selectedFormatName();

      // "Hour Minute Second" is outside kFreeFormatNames, so it is locked.
      expect(isFormatFree('Hour Minute Second'), isFalse);
      final lockedCard = find.descendant(
        of: find.byType(FormatsScreen),
        matching: find.text('Hour Minute Second', findRichText: true),
      );
      await tester.scrollUntilVisible(
        lockedCard,
        200,
        scrollable: find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      // The locked cards carry a trailing lock icon.
      expect(
        find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsWidgets,
      );

      // ensureVisible: the tall card can sit just past the viewport bottom.
      await tester.ensureVisible(lockedCard);
      await tester.pumpAndSettle();
      await tester.tap(lockedCard);
      await tester.pumpAndSettle();

      // The paywall opened and the selection is unchanged (the format was NOT
      // applied - the Formats overlay is still mounted underneath).
      expect(paywall(), findsOneWidget);
      expect(selectedFormatName(), before);

      await dismissPaywall(tester);
      leavePlatform();
    });

    testWidgets('Dark and System theme rows are locked; tapping opens the '
        'paywall and effectiveThemeMode stays light', (tester) async {
      enterGated();
      // Store a Dark preference up front: while gated it must NOT take effect.
      await SettingsModel.instance.setThemeValue(SettingsModel.themeValueDark);

      await pumpApp(tester);

      // Despite the stored "dark", the app is clamped to light while gated.
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.light);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.light,
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // The Pro upsell row + locked System/Dark theme rows are present.
      expect(find.text('Unlock Pro'), findsWidgets);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      // System and Dark each carry a lock (Light does not); plus the Per badge
      // is offstage behind the Settings overlay - so scope to the rows we tap.
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Dark'),
            matching: find.byType(Row),
          ),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      // Tapping Dark opened the paywall and did NOT switch the theme.
      expect(paywall(), findsWidgets);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.light);
      // The stored value is preserved underneath (so unlock restores it).
      expect(SettingsModel.instance.themeValue, SettingsModel.themeValueDark);

      await dismissPaywall(tester);
      leavePlatform();
    });

    testWidgets('buying pro_unlock flips hasPro: locks vanish and Per / '
        'formats / dark all work; effectiveThemeMode follows the stored value',
        (tester) async {
      enterGated();
      await SettingsModel.instance.setThemeValue(SettingsModel.themeValueDark);

      await pumpApp(tester);
      await typeSample(tester);

      // Sanity: gated and clamped before the purchase.
      expect(monetization.hasPro, isFalse);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.light);

      // Mock the purchase grant (what the purchase stream would do).
      monetization.debugGrantPro();
      await tester.pumpAndSettle();

      // hasPro is now true; the stored dark theme applies instantly.
      expect(monetization.hasPro, isTrue);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.dark);
      // Read brightness from a descendant of MaterialApp - Theme.of at the
      // MaterialApp element itself resolves to the fallback theme ABOVE the
      // app's own (light) and would never reflect the dark choice.
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );

      // No lock badges anywhere now (the Per icon's badge is gone).
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      // Every format now selects normally - pick the once-locked one. (Formats
      // first, while no other overlay has ever opened, so nothing obscures the
      // card.)
      await tester.tap(find.text('Hour Minute'));
      await tester.pumpAndSettle();
      final unlockedCard = find.descendant(
        of: find.byType(FormatsScreen),
        matching: find.text('Hour Minute Second', findRichText: true),
      );
      await tester.scrollUntilVisible(
        unlockedCard,
        200,
        scrollable: find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      // ensureVisible: the tall "Hour Minute Second" card can sit with its
      // tap point just past the viewport bottom after scrollUntilVisible.
      await tester.ensureVisible(unlockedCard);
      await tester.pumpAndSettle();
      await tester.tap(unlockedCard);
      await tester.pumpAndSettle();
      expect(find.text('Result format'), findsNothing);
      expect(selectedFormatName(), 'Hour Minute Second');

      // Per now opens the per-unit calculator (not the paywall).
      await tester.tap(find.byIcon(Icons.more_time));
      await tester.pumpAndSettle();
      expect(CalculatorModel.instance.isPerLayoutVisible, isTrue);
      expect(paywall(), findsNothing);

      leavePlatform();
    });

    testWidgets('the paywall shows the localized price and a Restore action',
        (tester) async {
      enterGated();
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unlock Pro').first);
      await tester.pumpAndSettle();

      // canBuyPro is true (gated + product loaded), so the button carries the
      // price and the "coming soon" note is absent.
      expect(monetization.canBuyPro, isTrue);
      expect(find.textContaining(r'$2.99'), findsOneWidget);
      expect(find.text('Coming soon'), findsNothing);
      expect(find.text('Restore Purchases'), findsOneWidget);

      await dismissPaywall(tester);
      leavePlatform();
    });
  });

  group('gating OFF (Android, default)', () {
    testWidgets('no locks anywhere; Per opens, every format selects, dark '
        'applies', (tester) async {
      enterUngated();
      await SettingsModel.instance.setThemeValue(SettingsModel.themeValueDark);

      await pumpApp(tester);
      await typeSample(tester);

      // Gating off: dark applies, hasPro is unconditionally true.
      expect(monetization.hasPro, isTrue);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.dark);
      // No lock badges anywhere.
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      // A normally-Pro format selects without any paywall (Formats first,
      // before any other overlay opens, so nothing obscures the card).
      await tester.tap(find.text('Hour Minute'));
      await tester.pumpAndSettle();
      expect(isFormatFree('Hour Minute Second'), isTrue);
      final card = find.descendant(
        of: find.byType(FormatsScreen),
        matching: find.text('Hour Minute Second', findRichText: true),
      );
      await tester.scrollUntilVisible(
        card,
        200,
        scrollable: find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byType(Scrollable),
        ),
      );
      // No lock icons in the list.
      expect(
        find.descendant(
          of: find.byType(FormatsScreen),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );
      // ensureVisible: the tall card can sit just past the viewport bottom.
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      expect(find.text('Result format'), findsNothing);
      expect(selectedFormatName(), 'Hour Minute Second');

      // Per opens the calculator (no paywall).
      await tester.tap(find.byIcon(Icons.more_time));
      await tester.pumpAndSettle();
      expect(CalculatorModel.instance.isPerLayoutVisible, isTrue);
      expect(paywall(), findsNothing);

      leavePlatform();
    });

    testWidgets('the Settings overlay shows no Pro row and the theme rows are '
        'all selectable', (tester) async {
      enterUngated();
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // No "Unlock Pro" / "Pro unlocked" row when gating is off.
      expect(find.text('Unlock Pro'), findsNothing);
      expect(find.text('Pro unlocked'), findsNothing);
      // No theme-row locks either.
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      // Dark switches the theme directly (no paywall).
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(SettingsModel.instance.themeMode, ThemeMode.dark);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.dark);
      expect(find.text('Unlock Pro'), findsNothing);

      leavePlatform();
    });
  });
}
