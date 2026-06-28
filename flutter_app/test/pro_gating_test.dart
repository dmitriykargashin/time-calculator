import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/config.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/services/entitlements.dart';
import 'package:cardamon_time_calculator/services/history_service.dart';
import 'package:cardamon_time_calculator/services/monetization.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';
import 'package:cardamon_time_calculator/ui/formats_screen.dart';

/// Covers the Apple-only Pro gating in BOTH states, driven by the [Monetization]
/// test seam ([Monetization.debugSetProGated]) rather than the
/// [kApplePurchasesEnabled] compile-time const - so the same suite asserts the
/// gated (iOS go-live) world AND the ungated (Android, default) world.
///
/// The contract under test (PRO ENTITLEMENT CONTRACT v2):
/// * gating ON  => the Per icon and every non-free result-format card show a
///   lock and route taps to the paywall (and do NOT perform their underlying
///   action); buying `pro_unlock` flips [Monetization.hasPro] so the locks
///   vanish and everything works again;
/// * theme (incl. dark) is FREE on every platform — it is NEVER gated;
/// * gating OFF => no locks anywhere; Per/formats behave exactly as in the rest
///   of the app.
///
/// Keypad-customization and history caps are entitlement features covered by
/// their own groups below (free presets {Standard, Stopwatch} + no custom
/// picker; history capped at [kFreeHistoryLimit] while gated).
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

    testWidgets('theme is FREE even while gated: Dark applies, no theme-row '
        'lock, and tapping a theme row never opens the paywall', (tester) async {
      enterGated();
      // Store a Dark preference up front: while gated it must STILL take effect
      // (theme is not a Pro feature).
      await SettingsModel.instance.setThemeValue(SettingsModel.themeValueDark);

      await pumpApp(tester);

      // Dark applies despite gating being on.
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.dark);
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        Brightness.dark,
      );

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // The Pro upsell row is present (gating is on), but NO theme row is locked.
      expect(find.text('Unlock Pro'), findsWidgets);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      // No lock on the Dark row (the only lock_outline on screen is the offstage
      // Per badge behind the Settings overlay, so scope to the Dark row).
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text('Dark'),
            matching: find.byType(Row),
          ),
          matching: find.byIcon(Icons.lock_outline),
        ),
        findsNothing,
      );

      // Tapping System switches the theme directly — no paywall SHEET opens.
      // (find.text('Unlock Pro') would match the always-present gated _proRow,
      // so assert on the modal BottomSheet instead.)
      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(SettingsModel.instance.themeValue, SettingsModel.themeValueSystem);

      leavePlatform();
    });

    testWidgets('buying pro_unlock flips hasPro: locks vanish and Per / '
        'formats / dark all work; effectiveThemeMode follows the stored value',
        (tester) async {
      enterGated();
      await SettingsModel.instance.setThemeValue(SettingsModel.themeValueDark);

      await pumpApp(tester);
      await typeSample(tester);

      // Sanity: gated before the purchase — but theme is FREE, so the stored
      // dark choice already applies even while gated.
      expect(monetization.hasPro, isFalse);
      expect(SettingsModel.instance.effectiveThemeMode, ThemeMode.dark);

      // Mock the purchase grant (what the purchase stream would do).
      monetization.debugGrantPro();
      await tester.pumpAndSettle();

      // hasPro is now true; dark still applies (it never depended on Pro).
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

  // Pure entitlement logic (no widgets) driven by the Monetization seam, so it
  // is platform-independent: hasPro = !isProGated || isProUnlocked.
  group('entitlement getters', () {
    test('gated, no Pro: only {Standard, Stopwatch} are free, no custom, '
        'history capped at 5', () {
      monetization.debugSetProGated(true);
      expect(isKeypadPresetFree('Standard'), isTrue);
      expect(isKeypadPresetFree('Stopwatch'), isTrue);
      expect(isKeypadPresetFree('Media'), isFalse);
      expect(isKeypadPresetFree('Hours & minutes'), isFalse);
      expect(isKeypadPresetFree('Calendar'), isFalse);
      expect(isKeypadPresetFree('Everything'), isFalse);
      expect(canCustomizeKeypad, isFalse);
      expect(hasUnlimitedHistory, isFalse);
      expect(kFreeHistoryLimit, 5);
    });

    test('gated WITH Pro: every preset is free, custom + full history unlocked',
        () {
      monetization.debugSetProGated(true);
      monetization.debugGrantPro();
      expect(isKeypadPresetFree('Media'), isTrue);
      expect(isKeypadPresetFree('Everything'), isTrue);
      expect(canCustomizeKeypad, isTrue);
      expect(hasUnlimitedHistory, isTrue);
    });

    test('ungated: nothing is gated', () {
      monetization.debugSetProGated(false);
      expect(isKeypadPresetFree('Media'), isTrue);
      expect(canCustomizeKeypad, isTrue);
      expect(hasUnlimitedHistory, isTrue);
    });

    test('every free-preset name is a real preset', () {
      final realNames =
          SettingsModel.keypadUnitPresets.map((p) => p.name).toSet();
      expect(realNames.containsAll(kFreeKeypadPresetNames), isTrue,
          reason: 'kFreeKeypadPresetNames must match real preset names');
    });
  });

  group('keypad customization gating', () {
    testWidgets('gated: non-free presets + the custom picker lock to the '
        'paywall; free presets apply', (tester) async {
      enterGated();
      // Start from a known free preset (Standard).
      await SettingsModel.instance
          .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first);
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keypad keys'));
      await tester.pumpAndSettle();

      // The custom-picker lock hint is shown.
      expect(find.text('Choose individual keys with Pro'), findsOneWidget);

      // Tapping a locked preset ('Media') opens the paywall and does NOT change
      // the enabled units.
      final before = SettingsModel.instance.enabledUnits;
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();
      expect(paywall(), findsOneWidget);
      expect(SettingsModel.instance.enabledUnits, before);
      await dismissPaywall(tester);

      // Tapping a free preset ('Stopwatch') applies it (no paywall).
      await tester.tap(find.text('Stopwatch'));
      await tester.pumpAndSettle();
      expect(paywall(), findsNothing);
      expect(
          SettingsModel.instance.activeKeypadUnitPreset?.name, 'Stopwatch');

      leavePlatform();
    });

    testWidgets('ungated: all presets apply and the custom picker is live',
        (tester) async {
      enterUngated();
      await pumpApp(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keypad keys'));
      await tester.pumpAndSettle();

      // No lock hint; the custom picker works.
      expect(find.text('Choose individual keys with Pro'), findsNothing);

      // A normally-Pro preset applies with no paywall.
      await tester.tap(find.text('Media'));
      await tester.pumpAndSettle();
      expect(paywall(), findsNothing);
      expect(SettingsModel.instance.activeKeypadUnitPreset?.name, 'Media');

      leavePlatform();
    });
  });

  group('history cap gating', () {
    testWidgets('gated: only the latest 5 entries show + a Pro upsell; '
        'unlocking Pro reveals the rest', (tester) async {
      enterGated();
      // Seed 6 distinct entries directly (newest last → index 0 once stored).
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.clear();
      for (var i = 1; i <= 6; i++) {
        HistoryService.instance
            .record('$i Hour + 1 Minute', '$i Hours 1 Minute');
      }
      addTearDown(HistoryService.instance.clear);

      await pumpApp(tester);
      // warnIfMissed:false: the history icon lives under the reveal-overlay
      // stack (reported offstage during layout), but the tap still opens it.
      await tester.tap(find.byIcon(Icons.history), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Exactly 5 rows render, plus the upsell; the 6th is hidden.
      expect(find.byKey(const ValueKey('history-entry-4')), findsOneWidget);
      expect(find.byKey(const ValueKey('history-entry-5')), findsNothing);
      expect(find.byKey(const ValueKey('history-pro-upsell')), findsOneWidget);

      // Unlock Pro: the upsell vanishes and the 6th row appears.
      monetization.debugGrantPro();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('history-pro-upsell')), findsNothing);
      expect(find.byKey(const ValueKey('history-entry-5')), findsOneWidget);

      leavePlatform();
    });

    testWidgets('ungated: all entries show, no upsell', (tester) async {
      enterUngated();
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.clear();
      for (var i = 1; i <= 6; i++) {
        HistoryService.instance
            .record('$i Hour + 1 Minute', '$i Hours 1 Minute');
      }
      addTearDown(HistoryService.instance.clear);

      await pumpApp(tester);
      // warnIfMissed:false: the history icon lives under the reveal-overlay
      // stack (reported offstage during layout), but the tap still opens it.
      await tester.tap(find.byIcon(Icons.history), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('history-entry-5')), findsOneWidget);
      expect(find.byKey(const ValueKey('history-pro-upsell')), findsNothing);

      leavePlatform();
    });
  });
}
