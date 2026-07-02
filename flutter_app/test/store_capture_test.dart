// High-DPI store-listing capture pass (NOT a pass/fail golden test).
//
// Renders the REAL app screens at 3x device pixel ratio so the marketing
// screenshots stay razor-sharp at Play / App Store resolution, then writes the
// PNGs into test/goldens/store/. The store-listings/ compositor frames these.
//
// Run with:
//   flutter test test/store_capture_test.dart --update-goldens
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/services/history_service.dart';
import 'package:cardamon_time_calculator/services/monetization.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';

const double kScale = 3.0; // 390x844 logical -> 1170x2532 physical

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
    matchesGoldenFile('goldens/store/$name.png'),
  );
}

Future<void> _typeSample(WidgetTester tester) async {
  for (final key in ['5', 'Hour', '–', '1', '0', 'Minute']) {
    await tester.tap(find.text(key).first);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, List<String> keys) async {
  for (final key in keys) {
    await tester.tap(find.text(key).first);
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final model = CalculatorModel.instance;
    model.clearAll();
    model.setIsFormatsLayoutVisible(false);
    model.setIsPerLayoutVisible(false);
    model.setIsSupportAppLayoutVisible(false);
    model.setIsSettingsLayoutVisible(false);
    model.setIsHistoryLayoutVisible(false);
    HistoryService.instance.clear();
  });

  Future<void> sizePhone(WidgetTester tester) async {
    tester.view.physicalSize = Size(390 * kScale, 844 * kScale);
    tester.view.devicePixelRatio = kScale;
    // Reserve a top status-bar inset so the app's top toolbar renders BELOW
    // where the framed status bar sits (otherwise the composited status bar
    // overlaps the toolbar). SafeArea(top:true) on each screen honors this.
    final inset = FakeViewPadding(top: 48 * kScale);
    tester.view.padding = inset;
    tester.view.viewPadding = inset;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
  }

  const int kDefaultFormatIndex = 18;

  // ---- Calculator (hero) — both platforms (the toolbar differs: Android has
  // the donation tea-cup, iOS does not). ----
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    final tag = platform == TargetPlatform.iOS ? 'ios' : 'android';

    // iOS gates Pro features by default (kApplePurchasesEnabled). Marketing
    // screenshots show the FULL unlocked app, so grant Pro on the Apple set.
    void grantProForApple(WidgetTester tester) {
      if (platform == TargetPlatform.iOS) {
        Monetization.instance.debugGrantPro();
        addTearDown(Monetization.instance.debugReset);
      }
    }

    testWidgets('calc light - $tag', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await sizePhone(tester);
      await SettingsModel.instance.setThemeValue('1');
      grantProForApple(tester);
      await tester.pumpWidget(const TimeCalculatorApp());
      await _settle(tester);
      await _typeSample(tester);
      await _shot(tester, 'calc_light_$tag');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('calc dark - $tag', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await sizePhone(tester);
      await SettingsModel.instance.setThemeValue('2');
      grantProForApple(tester);
      await tester.pumpWidget(const TimeCalculatorApp());
      await _settle(tester);
      await _typeSample(tester);
      await _shot(tester, 'calc_dark_$tag');
      await SettingsModel.instance.setThemeValue('1');
      debugDefaultTargetPlatformOverride = null;
    });
  }

  // ---- Rate calculator (the "per" overlay). ----
  testWidgets('rate', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, 'rate');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---- Rate calculator in the LOCKED (free iOS, Pro-gated, not unlocked)
  // state: the overlay OPENS but the computed totals are blurred behind an
  // "Unlock Pro to see totals" CTA. Diagnostic capture only - the marketing
  // shots show the unlocked app (rate.png / rate_ipad.png).
  testWidgets('rate locked - ios free', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(Monetization.instance.debugReset);
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    Monetization.instance.debugReset(); // NOT unlocked -> the Pro gate is active
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, 'per_locked');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---- Result-format picker. "Hour Minute Second" (index 19) is selected — a
  // format people actually use; "Year" is shown to almost nobody. ----
  testWidgets('formats', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    CalculatorModel.instance.setSelectedFormat(19); // Hour Minute Second
    await _settle(tester);
    await tester.tap(find.text('Hour Minute Second').first);
    await _settle(tester);
    await _shot(tester, 'formats');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---- Customizable keypad sub-screen (preview + presets + unit chips),
  // showing the "Media" preset selected for the demo. ----
  testWidgets('keypad', (tester) async {
    addTearDown(() => SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.applyKeypadUnitPreset(
        SettingsModel.keypadUnitPresets.firstWhere((x) => x.name == 'Media'));
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Keypad keys'));
    await _settle(tester);
    await _shot(tester, 'keypad');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---- History with several entries + notes. ----
  testWidgets('history', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizePhone(tester);
    await SettingsModel.instance.setThemeValue('1');
    HistoryService.instance.setEnabled(true);
    HistoryService.instance.clear();
    void rec(String e, String r, DateTime at) =>
        HistoryService.instance.record(e, r, at: at.millisecondsSinceEpoch);
    // Oldest first so the newest ends up at index 0.
    rec('45 Minutes × 12', '9 Hours', DateTime(2026, 6, 19, 16, 45));
    rec('3 Days 4 Hours ÷ 2', '1 Day 14 Hours', DateTime(2026, 6, 20, 11, 0));
    rec('8 Hours 30 Minutes + 1 Hour 15 Minutes', '9 Hours 45 Minutes',
        DateTime(2026, 6, 20, 18, 20));
    rec('5 Hours - 10 Minutes', '4 Hours 50 Minutes',
        DateTime(2026, 6, 21, 9, 5));
    rec('2 Days', '48 Hours', DateTime(2026, 6, 21, 14, 30));
    HistoryService.instance.setNote(0, 'Sprint length');
    HistoryService.instance.setNote(1, 'Project A payroll');
    HistoryService.instance.setNote(2, 'Billable hours');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.history));
    await _settle(tester);
    await _shot(tester, 'history');
    debugDefaultTargetPlatformOverride = null;
  });

  // ---- Resizable split with a LONG expression shown in All Units (index 25:
  // Year..MSecond; the engine drops the zero leading units, leaving
  // Days/Hours/Minutes/Seconds/MSeconds). Captured per platform so the iOS
  // toolbar has no donation tea-cup (Pro granted). ----
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    final tag = platform == TargetPlatform.iOS ? 'ios' : 'android';
    testWidgets('resized - $tag', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
      addTearDown(() => SettingsModel.instance
          .setDisplayFraction(SettingsModel.defaultDisplayFraction));
      await sizePhone(tester);
      await SettingsModel.instance.setThemeValue('1');
      await SettingsModel.instance
          .setDisplayFraction(SettingsModel.defaultDisplayFraction);
      if (platform == TargetPlatform.iOS) {
        Monetization.instance.debugGrantPro();
        addTearDown(Monetization.instance.debugReset);
      }
      await tester.pumpWidget(const TimeCalculatorApp());
      await _settle(tester);
      await _type(tester, <String>[
        '2', 'Day', '5', 'Hour', '3', '0', 'Minute',
        '+',
        '1', 'Day', '3', 'Hour', '2', '0', 'Minute',
        '1', '5', 'Second', '5', '0', '0', 'Msec',
      ]);
      CalculatorModel.instance.setSelectedFormat(25); // All Units
      await _settle(tester);
      await tester.drag(
          find.bySemanticsLabel('Resize display'), const Offset(0, 160));
      await _settle(tester);
      await _shot(tester, 'resized_$tag');
      debugDefaultTargetPlatformOverride = null;
    });
  }

  // ===================== ANDROID TABLET (7-column, 16:10 portrait) =====================
  // sw 800dp >= 600 puts the app into its genuine tablet layout (7-column keypad
  // in portrait). Captured at 2.5x -> 2000x3200 so it stays crisp at 10-inch.
  Future<void> sizeTablet(WidgetTester tester) async {
    const s = 2.5;
    tester.view.physicalSize = const Size(800 * s, 1280 * s);
    tester.view.devicePixelRatio = s;
    const inset = FakeViewPadding(top: 38 * s);
    tester.view.padding = inset;
    tester.view.viewPadding = inset;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
  }

  // A longer expression on the big tablet display so it doesn't read empty.
  const tabExpr = <String>[
    '2', 'Day', '8', 'Hour', '+', '5', 'Hour', '3', '0', 'Minute', '+', '4', '5', 'Minute',
  ];

  // Tablet calc frames use a keypad-favored split (smaller display) so the big
  // tablet display doesn't read as empty space.
  const tabFraction = 0.36;

  testWidgets('tab calc light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.setDisplayFraction(tabFraction);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, tabExpr);
    await _shot(tester, 'calc_tab_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab calc convert (decimal hours)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.setDisplayFraction(tabFraction);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, <String>[
      '5', 'Hour', '3', '0', 'Minute', '+', '2', 'Hour', '4', '5', 'Minute',
    ]);
    CalculatorModel.instance.setSelectedFormat(17); // Hour (decimal hours)
    await _settle(tester);
    await _shot(tester, 'calc_tab_convert');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab calc dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('2');
    await SettingsModel.instance.setDisplayFraction(tabFraction);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, tabExpr);
    await _shot(tester, 'calc_tab_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab rate', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, 'rate_tab');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab formats', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    CalculatorModel.instance.setSelectedFormat(19); // Hour Minute Second
    await _settle(tester);
    await tester.tap(find.text('Hour Minute Second').first);
    await _settle(tester);
    await _shot(tester, 'formats_tab');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab keypad (Media)', (tester) async {
    addTearDown(() => SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first));
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.applyKeypadUnitPreset(
        SettingsModel.keypadUnitPresets.firstWhere((x) => x.name == 'Media'));
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Keypad keys'));
    await _settle(tester);
    await _shot(tester, 'keypad_tab');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab history', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    HistoryService.instance.setEnabled(true);
    HistoryService.instance.clear();
    void rec(String e, String r, DateTime at) =>
        HistoryService.instance.record(e, r, at: at.millisecondsSinceEpoch);
    // More entries so the taller tablet history list fills the screen.
    rec('90 Minutes × 8', '12 Hours', DateTime(2026, 6, 18, 10, 15));
    rec('1 Week - 2 Days', '5 Days', DateTime(2026, 6, 18, 15, 40));
    rec('45 Minutes × 12', '9 Hours', DateTime(2026, 6, 19, 16, 45));
    rec('3 Days 4 Hours ÷ 2', '1 Day 14 Hours', DateTime(2026, 6, 20, 11, 0));
    rec('8 Hours 30 Minutes + 1 Hour 15 Minutes', '9 Hours 45 Minutes',
        DateTime(2026, 6, 20, 18, 20));
    rec('5 Hours - 10 Minutes', '4 Hours 50 Minutes',
        DateTime(2026, 6, 21, 9, 5));
    rec('2 Days', '48 Hours', DateTime(2026, 6, 21, 14, 30));
    HistoryService.instance.setNote(0, 'Sprint length');
    HistoryService.instance.setNote(1, 'Project A payroll');
    HistoryService.instance.setNote(2, 'Billable hours');
    HistoryService.instance.setNote(4, 'Study sessions');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.history));
    await _settle(tester);
    await _shot(tester, 'history_tab');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('tab resized (all units)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    addTearDown(() => SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeTablet(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, <String>[
      '2', 'Day', '5', 'Hour', '3', '0', 'Minute',
      '+',
      '1', 'Day', '3', 'Hour', '2', '0', 'Minute',
      '1', '5', 'Second', '5', '0', '0', 'Msec',
    ]);
    CalculatorModel.instance.setSelectedFormat(25); // All Units
    await _settle(tester);
    await tester.drag(
        find.bySemanticsLabel('Resize display'), const Offset(0, 160));
    await _settle(tester);
    await _shot(tester, 'resized_tab');
    debugDefaultTargetPlatformOverride = null;
  });

  // ===================== iPad 13" (universal iOS build, 3:4 portrait) =====================
  // shortestSide 1024dp >= 600 puts the app in its genuine tablet layout
  // (7-column keypad). Captured at 2x -> 2048x2732, which the compositor frames
  // into Apple's 2064x2752 iPad 13" slot. The Apple build gates Pro features, so
  // EVERY iPad frame grants Pro to show the fully unlocked app (and the iOS
  // toolbar carries no donation tea-cup).
  Future<void> sizeIpad(WidgetTester tester) async {
    const s = 2.0;
    tester.view.physicalSize = const Size(1024 * s, 1366 * s);
    tester.view.devicePixelRatio = s;
    // The composited iPad status bar in the frame is taller (in the downscaled
    // screen space) than a literal 24pt inset, so reserve more here to push the
    // app's own toolbar clear of it. 64pt clears the framed status bar with a
    // small natural gap.
    const inset = FakeViewPadding(top: 64 * s);
    tester.view.padding = inset;
    tester.view.viewPadding = inset;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
  }

  void grantProIpad(WidgetTester tester) {
    Monetization.instance.debugGrantPro();
    addTearDown(Monetization.instance.debugReset);
  }

  // Keypad-favored split so the wide iPad display doesn't read as empty space.
  const ipadFraction = 0.4;

  testWidgets('ipad calc light', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.setDisplayFraction(ipadFraction);
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, tabExpr);
    await _shot(tester, 'calc_ipad_light');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad calc convert (decimal hours)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.setDisplayFraction(ipadFraction);
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, <String>[
      '5', 'Hour', '3', '0', 'Minute', '+', '2', 'Hour', '4', '5', 'Minute',
    ]);
    CalculatorModel.instance.setSelectedFormat(17); // Hour (decimal hours)
    await _settle(tester);
    await _shot(tester, 'calc_ipad_convert');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad calc dark', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => SettingsModel.instance.setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('2');
    await SettingsModel.instance.setDisplayFraction(ipadFraction);
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, tabExpr);
    await _shot(tester, 'calc_ipad_dark');
    await SettingsModel.instance.setThemeValue('1');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad rate', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    await tester.tap(find.byIcon(Icons.more_time));
    await _settle(tester);
    await _shot(tester, 'rate_ipad');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad formats', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _typeSample(tester);
    CalculatorModel.instance.setSelectedFormat(19); // Hour Minute Second
    await _settle(tester);
    await tester.tap(find.text('Hour Minute Second').first);
    await _settle(tester);
    await _shot(tester, 'formats_ipad');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad keypad (Media)', (tester) async {
    addTearDown(() => SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first));
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance.applyKeypadUnitPreset(
        SettingsModel.keypadUnitPresets.firstWhere((x) => x.name == 'Media'));
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.settings));
    await _settle(tester);
    await tester.tap(find.text('Keypad keys'));
    await _settle(tester);
    await _shot(tester, 'keypad_ipad');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad history', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    grantProIpad(tester);
    HistoryService.instance.setEnabled(true);
    HistoryService.instance.clear();
    void rec(String e, String r, DateTime at) =>
        HistoryService.instance.record(e, r, at: at.millisecondsSinceEpoch);
    // More rows than the phone/tablet set so the taller iPad list fills.
    rec('40 Hours ÷ 5', '8 Hours', DateTime(2026, 6, 17, 9, 0));
    rec('1 Day 12 Hours + 6 Hours', '1 Day 18 Hours', DateTime(2026, 6, 17, 14, 20));
    rec('25 Minutes × 3', '1 Hour 15 Minutes', DateTime(2026, 6, 17, 16, 50));
    rec('90 Minutes × 8', '12 Hours', DateTime(2026, 6, 18, 10, 15));
    rec('1 Week - 2 Days', '5 Days', DateTime(2026, 6, 18, 15, 40));
    rec('45 Minutes × 12', '9 Hours', DateTime(2026, 6, 19, 16, 45));
    rec('3 Days 4 Hours ÷ 2', '1 Day 14 Hours', DateTime(2026, 6, 20, 11, 0));
    rec('8 Hours 30 Minutes + 1 Hour 15 Minutes', '9 Hours 45 Minutes',
        DateTime(2026, 6, 20, 18, 20));
    rec('5 Hours - 10 Minutes', '4 Hours 50 Minutes',
        DateTime(2026, 6, 21, 9, 5));
    rec('2 Days', '48 Hours', DateTime(2026, 6, 21, 14, 30));
    HistoryService.instance.setNote(0, 'Sprint length');
    HistoryService.instance.setNote(1, 'Project A payroll');
    HistoryService.instance.setNote(2, 'Billable hours');
    HistoryService.instance.setNote(4, 'Study sessions');
    HistoryService.instance.setNote(7, 'Overtime check');
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await tester.tap(find.byIcon(Icons.history));
    await _settle(tester);
    await _shot(tester, 'history_ipad');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ipad resized (all units)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => CalculatorModel.instance.setSelectedFormat(kDefaultFormatIndex));
    addTearDown(() => SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction));
    await sizeIpad(tester);
    await SettingsModel.instance.setThemeValue('1');
    await SettingsModel.instance
        .setDisplayFraction(SettingsModel.defaultDisplayFraction);
    grantProIpad(tester);
    await tester.pumpWidget(const TimeCalculatorApp());
    await _settle(tester);
    await _type(tester, <String>[
      '2', 'Day', '5', 'Hour', '3', '0', 'Minute',
      '+',
      '1', 'Day', '3', 'Hour', '2', '0', 'Minute',
      '1', '5', 'Second', '5', '0', '0', 'Msec',
    ]);
    CalculatorModel.instance.setSelectedFormat(25); // All Units
    await _settle(tester);
    await tester.drag(
        find.bySemanticsLabel('Resize display'), const Offset(0, 160));
    await _settle(tester);
    await _shot(tester, 'resized_ipad');
    debugDefaultTargetPlatformOverride = null;
  });
}
