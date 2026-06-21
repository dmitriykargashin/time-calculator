// Screenshot-generation harness (NOT a pass/fail golden test).
//
// Run with:
//   flutter test test/golden_capture_test.dart --update-goldens
// to WRITE PNGs of every key UI state into test/goldens/ for a visual audit.
// Real fonts (ABeeZee + MaterialIcons) are loaded so glyphs render properly.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:cardamon_time_calculator/config.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/services/monetization.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';
import 'package:cardamon_time_calculator/ui/calculator_screen.dart';
import 'package:cardamon_time_calculator/ui/widgets/consent_dialog.dart';
import 'package:cardamon_time_calculator/ui/widgets/keypad.dart';

/// Loads every font declared in the built test asset bundle (MaterialIcons,
/// CupertinoIcons, ABeeZee) so goldens render real glyphs instead of boxes.
Future<void> loadAppFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest) {
    final family = entry['family'] as String;
    final loader = FontLoader(family);
    for (final font in entry['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _settle(WidgetTester tester) => tester.pumpAndSettle();

Future<void> _shot(WidgetTester tester, String name) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

/// Types "5 Hour − 10 Minute" so the calculator shows a real expression and
/// live result.
Future<void> _typeSample(WidgetTester tester) async {
  for (final key in ['5', 'Hour', '–', '1', '0', 'Minute']) {
    await tester.tap(find.text(key).first);
    await tester.pump();
  }
  // Settle so transient ink splashes/highlights from the taps clear (they
  // would otherwise show as a bright radial blob on the dark keypad).
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final model = CalculatorModel.instance;
    model.clearAll();
    // clearAll() leaves the overlay-visibility flags set; reset them so a shot
    // never inherits an overlay a previous shot left open in this singleton.
    model.setIsFormatsLayoutVisible(false);
    model.setIsPerLayoutVisible(false);
    model.setIsSupportAppLayoutVisible(false);
    model.setIsSettingsLayoutVisible(false);
  });

  Future<void> sizePhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> sizeLandscape(WidgetTester tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // Tablet (shortestSide >= 600 => sw600 bucket, 7-column keypad in BOTH
  // orientations). Guards the action ("tools") column against scrolling.
  Future<void> sizeTabletPortrait(WidgetTester tester) async {
    tester.view.physicalSize = const Size(834, 1112);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> sizeTabletLandscape(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1112, 834);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('phone portrait - light - populated', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1'); // light
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await _shot(tester, '01_calc_portrait_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // Regression guard for the edge-to-edge keypad: simulate a gesture-nav bottom
  // inset (the strip a SafeArea would normally reserve). With SafeArea(bottom:
  // false) the keypad card must extend DOWN through that inset to ~8dp from the
  // physical bottom edge - NOT stop ~64dp short of it. If someone re-enables the
  // bottom SafeArea, the keypad card jumps up by the inset and this golden
  // changes, flagging the regression.
  testWidgets('phone portrait - light - keypad fills the bottom gesture inset',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    const inset = FakeViewPadding(bottom: 48);
    tester.view.padding = inset;
    tester.view.viewPadding = inset;
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await SettingsModel.instance.setThemeValue('1'); // light
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await _shot(tester, '19_calc_portrait_bottom_inset_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('analytics consent dialog - light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1'); // light
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    // Show the consent dialog (don't await - capture it while open). Analytics
    // is off in tests (no Firebase), so the choice handler is a harmless no-op.
    showAnalyticsConsentDialog(tester.element(find.byType(CalculatorScreen)));
    await _settle(tester);
    await _shot(tester, '21_consent_dialog_light');
    await tester.tap(find.text('No thanks'));
    await _settle(tester);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('phone portrait - dark - populated', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('2'); // dark
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await _shot(tester, '02_calc_portrait_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('phone landscape - light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeLandscape(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await _shot(tester, '03_calc_landscape_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tablet portrait - light (tools column must not scroll)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeTabletPortrait(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    expect(
      find.descendant(
        of: find.byType(LandscapeKeypad),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
      reason: 'the action/tools column must not introduce a scroll view',
    );
    await _shot(tester, '15_calc_tablet_portrait_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tablet landscape - light (tools column must not scroll)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeTabletLandscape(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    expect(
      find.descendant(
        of: find.byType(LandscapeKeypad),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
      reason: 'the action/tools column must not introduce a scroll view',
    );
    await _shot(tester, '16_calc_tablet_landscape_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // "Hour Minute" is the default-selected format (repository index 18); it
  // sits below the fold so its selected highlight is never captured. Select
  // "Year" (index 0, a free format) so the green fill + accent border +
  // check_circle land in the first screenful, then RESTORE index 18 so the
  // shared CalculatorModel singleton's selection doesn't leak into later tests
  // (e.g. the gated formats shot that taps the "Hour Minute" chip).
  const int kDefaultFormatIndex = 18;
  void restoreDefaultFormat() =>
      CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex);

  testWidgets('formats overlay', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(restoreDefaultFormat);
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    CalculatorModel.instance.setSelectedFormat(0);
    await _settle(tester);
    // The chip "Year" (display card, first in the tree) collides with the
    // keypad's "Year" time-unit key, so target the first match (the chip).
    await tester.tap(find.text('Year').first);
    await _settle(tester);
    await _shot(tester, '04_formats_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // Auto-scroll-to-selection: open the overlay with the DEFAULT selection
  // ("Hour Minute", repository index 18) which lives deep in COMBINED, below
  // the fold. On open the list now centres that selected row, so this shot must
  // show the highlighted (green fill + accent ring + check) "Hour Minute" row
  // comfortably in view rather than the top "Year" row.
  testWidgets('formats overlay - scrolled to default selection', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(restoreDefaultFormat);
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    // Make the default selection explicit (it is index 18 anyway) so the shot
    // is independent of any selection a prior test left in the singleton.
    CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex);
    await _settle(tester);
    // Open via the "Hour Minute" chip (the default-selected label).
    await tester.tap(find.text('Hour Minute'));
    await _settle(tester);
    await _shot(tester, '04c_formats_scrolled_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('formats overlay - dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(restoreDefaultFormat);
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('2'); // dark
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    CalculatorModel.instance.setSelectedFormat(0);
    await _settle(tester);
    await tester.tap(find.text('Year').first);
    await _settle(tester);
    await _shot(tester, '04b_formats_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('per overlay', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, '05_per_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('per overlay - dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('2'); // dark
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, '05b_per_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('add-unit hint (unitless input shows the F1 hint)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    // A unitless number produces no result; the F1 hint explains why.
    await tester.tap(find.text('5'));
    await _settle(tester);
    await _shot(tester, '22_add_unit_hint_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('settings overlay - dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('2');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await _shot(tester, '06_settings_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('support overlay - android (buy buttons)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.emoji_food_beverage));
    await _settle(tester);
    await _shot(tester, '07_support_android_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('support overlay - ios (no buy buttons)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.emoji_food_beverage));
    await _settle(tester);
    await _shot(tester, '08_support_ios_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---------------------------------------------------------------------------
  // Apple-only Pro gating shots. These FORCE gating on via the Monetization
  // test seam (production keeps it off until kApplePurchasesEnabled flips), so
  // we can audit how the paywall and the three locks actually render. The
  // earlier (android, gating-off) shots above are unaffected.
  // ---------------------------------------------------------------------------

  /// Loaded fake Pro product so the paywall button shows a real price.
  ProductDetails proProduct() => ProductDetails(
        id: kProSku,
        title: 'Pro',
        description: 'One-time unlock',
        price: r'$2.99',
        rawPrice: 2.99,
        currencyCode: 'USD',
      );

  testWidgets('pro paywall - gated', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    Monetization.instance.debugSetProGated(true);
    Monetization.instance.debugSetProProduct(proProduct());
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    // Open the paywall from the Settings "Unlock Pro" row.
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Unlock Pro').first);
    await _settle(tester);
    await _shot(tester, '09_pro_paywall_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pro paywall - gated - dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('2'); // dark
    Monetization.instance.debugSetProGated(true);
    Monetization.instance.debugSetProProduct(proProduct());
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Unlock Pro').first);
    await _settle(tester);
    await _shot(tester, '12_pro_paywall_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('pro paywall - gated - no product (coming soon / disabled)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    // Gating on but NO product loaded => canBuyPro is false: the button is
    // disabled and the "Coming soon" note shows (the state that ships first).
    Monetization.instance.debugSetProGated(true);
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Unlock Pro').first);
    await _settle(tester);
    await _shot(tester, '13_pro_paywall_coming_soon_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('calculator portrait - gated (Per lock badge)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    Monetization.instance.debugSetProGated(true);
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await _shot(tester, '14_calc_portrait_gated_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('formats overlay - gated (locks on non-free formats)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    Monetization.instance.debugSetProGated(true);
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    // Formats is now reached through the tonal format chip (the compare_arrows
    // action icon was removed); the chip shows the default "Hour Minute".
    await tester.tap(find.text('Hour Minute'));
    await _settle(tester);
    await _shot(tester, '10_formats_gated_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('settings overlay - gated (locked theme rows + Pro row)',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    Monetization.instance.debugSetProGated(true);
    addTearDown(Monetization.instance.debugReset);

    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await _shot(tester, '11_settings_gated_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // Draggable split: type the sample, then drag the resize handle DOWN so the
  // display card is ENLARGED and the keypad is shorter (smaller-but-fine keys),
  // and shoot the result - confirming the handle is visible/grabbable and the
  // resized split renders cleanly with no overflow/clipping.
  testWidgets('resized split - enlarged display - light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(restoreDefaultFormat);
    addTearDown(() => SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction);
    CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    // Drag the handle down toward the larger-display clamp so the keys reflow
    // visibly smaller in the shot.
    await tester.drag(find.bySemanticsLabel('Resize display'),
        const Offset(0, 160));
    await _settle(tester);
    await _shot(tester, '17_calc_resized_light');
    debugDefaultTargetPlatformOverride = null;
  });

  // Landscape draggable split: the SAME resize handle now works in the
  // 7-column landscape layout. Seed a mid-range landscape fraction, drag the
  // handle DOWN so the display grows and the 7-column keypad reflows shorter,
  // and shoot the result - confirming the handle is visible/grabbable in
  // landscape and the resized split renders cleanly (no overflow/clipping, rows
  // still equal height across all seven columns).
  testWidgets('resized split - landscape - light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(restoreDefaultFormat);
    addTearDown(() => SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeLandscape(tester);
    await SettingsModel.instance.setThemeValue('1');
    // Seed the keypad-favored floor of the landscape clamp (0.18) so dragging
    // DOWN lands the split MID-RANGE - a state visibly distinct from the
    // display-favored default (0.45) captured in 03, so 18 shows a taller
    // keypad / shorter display than the default landscape shot.
    await SettingsModel.instance.setDisplayFraction(0.18);
    CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.drag(find.bySemanticsLabel('Resize display'),
        const Offset(0, 45));
    await _settle(tester);
    await _shot(tester, '18_calc_landscape_resized_light');
    debugDefaultTargetPlatformOverride = null;
  });
}
