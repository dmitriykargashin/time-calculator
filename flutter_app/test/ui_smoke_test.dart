import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';
import 'package:cardamon_time_calculator/ui/clipboard_feedback.dart';
import 'package:cardamon_time_calculator/ui/formats_screen.dart';
import 'package:cardamon_time_calculator/ui/widgets/keypad.dart';

void main() {
  setUp(() async {
    // In-memory prefs so SettingsModel / RateService bookkeeping never hits
    // a missing platform channel.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // The repositories are process singletons shared across tests: reset the
    // expression/result (selected format intentionally persists, like a
    // running app).
    CalculatorModel.instance.clearAll();
    // Pin the keypad's units to the shipped default (Standard: Msec, Second,
    // Minute, Hour, Day, Week, Month - no Year), so the layout-geometry tests
    // below run against a known key set.
    await SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first);
    // Pin history OFF so the top bar holds the original three tools (Per / Tea /
    // Settings); the on-by-default history icon + its placement are covered by
    // history_test and the goldens.
    await SettingsModel.instance.setHistoryEnabled(false);
  });

  testWidgets('typing an expression shows the formatted result and the '
      'formats overlay (opened from the selected-format label) '
      'selects/closes', (tester) async {
    // Run as a non-Android platform so the monetization layer stays inert
    // (no billing platform channels exist in tests).
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The selected-format label (plain text, default "Hour Minute").
    expect(find.text('Hour Minute'), findsOneWidget);

    // The Formats gate: with no result yet the label (like the Formats
    // icon) is disabled, so tapping it must not open the overlay.
    await tester.tap(find.text('Hour Minute'));
    await tester.pumpAndSettle();
    expect(find.text('Result format'), findsNothing);

    // Type "5 Hour − 10 Minute".
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Hour'));
    await tester.pump();
    await tester.tap(find.text('–')); // minus key (EN DASH label)
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Minute'));
    await tester.pump();

    // Live result in the default "Hour Minute" format, smart-pluralized
    // (RemoveADS): 4 Hours 50 Minutes.
    expect(
      find.textContaining('4 Hours 50 Minutes', findRichText: true),
      findsOneWidget,
    );

    // Open the formats chooser by tapping the label (the deliberate
    // improvement over the branch's inert tvFormats).
    await tester.tap(find.text('Hour Minute'));
    await tester.pumpAndSettle();
    expect(find.text('Result format'), findsOneWidget);

    // Scroll to and select the "Minute" format card (exact title match;
    // keypad keys are outside FormatsScreen). On open the list now
    // auto-scrolls to centre the DEFAULT selection ("Hour Minute", index 18,
    // in COMBINED), so the "Minute" SINGLE-UNIT row sits ABOVE the viewport -
    // scroll toward the START (negative delta) to reach it.
    final minuteCard = find.descendant(
      of: find.byType(FormatsScreen),
      matching: find.text('Minute', findRichText: true),
    );
    await tester.scrollUntilVisible(
      minuteCard,
      -200,
      scrollable: find.descendant(
        of: find.byType(FormatsScreen),
        matching: find.byType(Scrollable),
      ),
    );
    // Fully bring it into the viewport (scrollUntilVisible can stop with the
    // row just clipping the top edge under the header) before tapping.
    await tester.ensureVisible(minuteCard);
    await tester.pumpAndSettle();
    await tester.tap(minuteCard);
    await tester.pumpAndSettle();

    // Selecting closes the overlay and re-renders the result in the new
    // format (zero units hidden -> "290 Minutes", plural).
    expect(find.text('Result format'), findsNothing);
    expect(
      find.textContaining('290 Minutes', findRichText: true),
      findsOneWidget,
    );

    // Foundation debug variables must be reset before the test body ends.
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('opening the formats overlay with the default below-the-fold '
      'selection ("Hour Minute") auto-scrolls it into view', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // A tall-enough phone so the COMBINED section (where "Hour Minute" lives,
    // repository index 18) starts off-screen on open - the case the auto-scroll
    // fixes.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // The DEFAULT selection is "Hour Minute" (index 18) - the singleton's
    // selection persists across clearAll(), like a running app. Make it
    // explicit so the test is independent of prior-test selection leakage.
    CalculatorModel.instance.setSelectedFormat(18);

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Need a result before the Formats chip is enabled: type the sample.
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Hour'));
    await tester.pump();
    await tester.tap(find.text('–'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Minute'));
    await tester.pump();

    // Open the formats overlay via the chip (default "Hour Minute" label).
    await tester.tap(find.text('Hour Minute'));
    await tester.pumpAndSettle();
    expect(find.text('Result format'), findsOneWidget);

    // The selected row is marked by its "Selected" check_circle. With the
    // auto-scroll-to-selection, it must already be present in the tree WITHOUT
    // any manual scrolling (an off-screen lazy row would not render, but more
    // importantly its rect must sit INSIDE the list viewport).
    final selectedCheck = find.descendant(
      of: find.byType(FormatsScreen),
      matching: find.byIcon(Icons.check_circle),
    );
    expect(selectedCheck, findsOneWidget,
        reason: 'the selected row check must render on open (auto-scrolled in)');

    // Its rect must fall within the FormatsScreen scrollable viewport - i.e. it
    // is actually visible, not merely attached above/below the fold.
    final viewport = tester.getRect(
      find.descendant(
        of: find.byType(FormatsScreen),
        matching: find.byType(Scrollable),
      ),
    );
    final checkRect = tester.getRect(selectedCheck);
    expect(viewport.contains(checkRect.topLeft), isTrue,
        reason: 'selected row top must be within the viewport');
    expect(viewport.contains(checkRect.bottomRight), isTrue,
        reason: 'selected row bottom must be within the viewport');

    // And the "Hour Minute" highlighted row title is visible too (rich text in
    // the row, distinct from the chip which is now behind the overlay).
    final hourMinuteRow = find.descendant(
      of: find.byType(FormatsScreen),
      matching: find.text('Hour Minute', findRichText: true),
    );
    expect(hourMinuteRow, findsOneWidget);
    expect(tester.getRect(hourMinuteRow).top, greaterThanOrEqualTo(viewport.top),
        reason: 'the selected "Hour Minute" row title must be on-screen');
    expect(tester.getRect(hourMinuteRow).bottom,
        lessThanOrEqualTo(viewport.bottom),
        reason: 'the selected "Hour Minute" row title must be on-screen');

    // Close the overlay via the back arrow so the shared CalculatorModel
    // singleton's isFormatsLayoutVisible flag (which clearAll() does NOT reset)
    // doesn't leak an open overlay into the next test.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Result format'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('top bar carries Per/Support/Settings; the keypad carries a '
      'single Backspace (no AC, no Msec); no tea badge where billing is '
      'unavailable', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The three SECONDARY tools now live in the slim TOP BAR (not the keypad).
    // The Formats compare_arrows icon was removed: the tonal format chip
    // (carrying the expand_more caret) is the single entry point to Formats.
    expect(find.byIcon(Icons.compare_arrows), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
    expect(find.byIcon(Icons.more_time), findsOneWidget);
    expect(find.byIcon(Icons.emoji_food_beverage), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    // None of the three secondary tools are inside the keypad anymore.
    for (final icon in [
      Icons.more_time,
      Icons.emoji_food_beverage,
      Icons.settings,
    ]) {
      expect(
        find.descendant(
          of: find.byType(PortraitKeypad),
          matching: find.byIcon(icon),
        ),
        findsNothing,
        reason: 'secondary tool $icon must be in the top bar, not the keypad',
      );
    }

    // The single Backspace is the ONLY delete key (the TOP-right slot of the
    // number block). There is no AC key.
    expect(
      find.descendant(
        of: find.byType(PortraitKeypad),
        matching: find.byIcon(Icons.backspace),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PortraitKeypad),
        matching: find.text('AC'),
      ),
      findsNothing,
      reason: 'the AC (Clear) key was removed',
    );
    // No red attention badge on iOS: billing is gated to Android, so the
    // cup must not nag toward a Support screen without buy buttons.
    expect(find.byType(Badge), findsNothing);

    // All keys of the COMPACT portrait keypad are present: digits, operators,
    // "=", and the Standard unit set (Msec..Month, no Year).
    for (final label in [
      '7', '8', '9', '4', '5', '6', '1', '2', '3', '0', '.', '=',
      '÷', '×', '+', '–',
      'Msec', 'Second', 'Minute', 'Hour', 'Day', 'Week', 'Month',
    ]) {
      expect(
        find.descendant(
          of: find.byType(PortraitKeypad),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'key $label',
      );
    }

    // COMPACT portrait arrangement (number/operator block, then the green unit
    // band with "=" bottom-right) - Standard preset:
    //   7    8      9      ⌫
    //   4    5      6      ÷
    //   1    2      3      ×
    //   0    .      +      −
    //   Msec Second Minute Hour
    //   Day  Week   Month  =
    Rect kpRect(Finder f) => tester.getRect(find.descendant(
          of: find.byType(PortraitKeypad),
          matching: f,
        ));
    Rect rectText(String t) => kpRect(find.text(t));
    final backspaceRect = kpRect(find.byIcon(Icons.backspace));
    final divideRect = rectText('÷');
    final multiplyRect = rectText('×');
    final plusRect = rectText('+');
    final minusRect = rectText('–');
    final equalsRect = rectText('=');

    // Backspace is the TOP-right key (shares the "7" row, right of "9").
    expect((backspaceRect.center.dy - rectText('7').center.dy).abs(),
        lessThan(0.5),
        reason: 'Backspace sits on the top row (with 7/8/9)');
    expect(backspaceRect.center.dx, greaterThan(rectText('9').center.dx));
    // ÷, ×, − run down the right column under Backspace (shared x); + is to the
    // left of − on the "0" row.
    for (final r in [divideRect, multiplyRect, minusRect]) {
      expect((r.center.dx - backspaceRect.center.dx).abs(), lessThan(0.5),
          reason: 'right-column keys share the right-most column x');
    }
    expect(backspaceRect.center.dy, lessThan(divideRect.center.dy));
    expect(divideRect.center.dy, lessThan(multiplyRect.center.dy));
    expect(multiplyRect.center.dy, lessThan(minusRect.center.dy));
    expect((plusRect.center.dy - rectText('0').center.dy).abs(), lessThan(0.5),
        reason: '"+" shares the "0" row');
    expect((minusRect.center.dy - rectText('0').center.dy).abs(), lessThan(0.5),
        reason: '"−" shares the "0" row');
    expect(plusRect.center.dx, lessThan(minusRect.center.dx),
        reason: '"+" is left of "−"');

    // The green unit band sits BELOW the number/operator block: Msec is below
    // the "0" row.
    expect(rectText('Msec').center.dy, greaterThan(rectText('0').center.dy),
        reason: 'the unit band is below the number block');
    // "=" is the BOTTOM-RIGHT key: below the operator block and in the right-most
    // column (sharing Backspace's x).
    expect(equalsRect.center.dy, greaterThan(minusRect.center.dy),
        reason: '"=" is below the number/operator block');
    expect((equalsRect.center.dx - backspaceRect.center.dx).abs(), lessThan(0.5),
        reason: '"=" is in the right-most column (bottom-right corner)');

    // A digit keypress lands in the expression display.
    await tester.tap(find.text('7'));
    await tester.pump();
    expect(find.text('7', findRichText: true), findsAtLeastNWidgets(2));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('the single Backspace key deletes one trailing symbol on TAP '
      'and clears the WHOLE expression on LONG-PRESS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Type "789" via the keypad.
    for (final d in ['7', '8', '9']) {
      await tester.tap(find.descendant(
        of: find.byType(PortraitKeypad),
        matching: find.text(d),
      ));
      await tester.pump();
    }
    // The expression reads 789 (rich text in the display; the live result
    // echoes a bare number too, so >=1).
    expect(find.text('789', findRichText: true), findsAtLeastNWidgets(1));

    final backspace = find.descendant(
      of: find.byType(PortraitKeypad),
      matching: find.byIcon(Icons.backspace),
    );

    // TAP backspace deletes ONE trailing symbol -> "78".
    await tester.tap(backspace);
    await tester.pump();
    expect(find.text('78', findRichText: true), findsAtLeastNWidgets(1));
    expect(find.text('789', findRichText: true), findsNothing);

    // LONG-PRESS backspace is now the ONLY clear-all: it runs the clear-flash
    // animation, which wipes the WHOLE expression on completion -> empty.
    await tester.longPress(backspace);
    // Drive the 400ms clear-flash to completion (clearAll fires on completed).
    await tester.pumpAndSettle();
    expect(find.text('78', findRichText: true), findsNothing);
    expect(find.text('789', findRichText: true), findsNothing);
    expect(CalculatorModel.instance.isExpressionEmpty(), isTrue);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('dragging the resize handle DOWN grows the display, shrinks '
      'the keypad, and persists the new fraction to "display_fraction"',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Portrait phone window so the PortraitKeypad (4x6) renders with the
    // draggable handle (landscape/tablet keep a fixed split).
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Start from the known default split so the assertions are deterministic.
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The handle is present and grabbable (the "Resize display" semantics).
    final handle = find.bySemanticsLabel('Resize display');
    expect(handle, findsOneWidget);

    // Measure the keypad grid height before the drag.
    double keypadGridHeight() =>
        tester.getSize(find.byType(PortraitKeypad)).height;
    final keypadBefore = keypadGridHeight();
    final fractionBefore = SettingsModel.instance.displayFraction;

    // Drag the handle DOWN by 120 logical px (positive primaryDelta => the
    // display grows, the keypad shrinks).
    await tester.drag(handle, const Offset(0, 120));
    await tester.pumpAndSettle();

    // The keypad grid shrank ...
    final keypadAfter = keypadGridHeight();
    expect(
      keypadAfter,
      lessThan(keypadBefore),
      reason: 'dragging the handle down must shrink the keypad',
    );
    // ... and it shrank by a SUBSTANTIAL amount. The old 44dp key-height floor
    // pinned the display-fraction ceiling almost at the default, so a 120px
    // drag barely moved the keypad; the relaxed ~30dp floor + widened bounds
    // give the handle real travel, so the same drag now shrinks the keypad by a
    // large margin. Require >=80px of shrink (the old clamp allowed only a few
    // px here) to lock in that the keys NOTICEABLY resize again.
    expect(
      keypadBefore - keypadAfter,
      greaterThan(80),
      reason: 'the relaxed clamp must let a 120px drag shrink the keypad a lot '
          '(noticeable key resize), not the few px the old 44dp floor allowed',
    );
    // ... the display fraction grew ...
    expect(
      SettingsModel.instance.displayFraction,
      greaterThan(fractionBefore),
      reason: 'dragging the handle down must grow the display fraction',
    );
    // ... and it stays within the usable clamp.
    expect(
      SettingsModel.instance.displayFraction,
      lessThanOrEqualTo(SettingsModel.maxDisplayFraction),
    );

    // The new fraction is PERSISTED to "display_fraction" on drag end.
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getDouble('display_fraction'),
      closeTo(SettingsModel.instance.displayFraction, 1e-9),
    );

    // The full 4x6 keypad still renders (no overflow / dropped rows) at the
    // smaller size: every key is present and tappable.
    for (final label in ['7', '0', '=', '–', 'Hour', 'Second']) {
      expect(
        find.descendant(
          of: find.byType(PortraitKeypad),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'key $label after resize',
      );
    }
    // The single Backspace delete key is still present too.
    expect(
      find.descendant(
        of: find.byType(PortraitKeypad),
        matching: find.byIcon(Icons.backspace),
      ),
      findsOneWidget,
      reason: 'the single backspace key after resize',
    );
    // A keypress still registers on the shrunken keypad.
    await tester.tap(
      find.descendant(
        of: find.byType(PortraitKeypad),
        matching: find.text('7'),
      ),
    );
    await tester.pump();
    expect(find.text('7', findRichText: true), findsAtLeastNWidgets(2));

    // Restore the default split for the remaining tests.
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('portrait keypad rows are UNIFORM equal height (no taller first '
      'row) at default AND resized sizes', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The vertical center of one key in each of the four digit rows. Equal row
    // heights => equal spacing between consecutive row centers (the top row
    // must NOT be ~gap taller than the rest, the reported bug).
    double rowCenterY(String label) => tester
        .getRect(find.descendant(
          of: find.byType(PortraitKeypad),
          matching: find.text(label),
        ))
        .center
        .dy;

    void expectUniformRows() {
      final ys = ['7', '4', '1', '0'].map(rowCenterY).toList();
      final gap01 = ys[1] - ys[0];
      final gap12 = ys[2] - ys[1];
      final gap23 = ys[3] - ys[2];
      // All three inter-row spacings equal within 0.5dp (sub-pixel rounding).
      expect((gap01 - gap12).abs(), lessThan(0.5),
          reason: 'row 0->1 vs 1->2 spacing must match (uniform rows)');
      expect((gap12 - gap23).abs(), lessThan(0.5),
          reason: 'row 1->2 vs 2->3 spacing must match (uniform rows)');
    }

    // Default split.
    expectUniformRows();

    // Resized (dragged) split: drag the handle down so the keypad shrinks, then
    // re-check the rows stay uniform at the smaller size.
    await tester.drag(
        find.bySemanticsLabel('Resize display'), const Offset(0, 140));
    await tester.pumpAndSettle();
    expectUniformRows();

    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('landscape keypad: the number block is uniform, units stack in '
      'columns, and "=" is the bottom-right key', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The number block's digit column (7/4/1/0) has four UNIFORM cells: equal
    // spacing between consecutive cell centers.
    double cellCenterY(String label) => tester
        .getRect(find.descendant(
          of: find.byType(LandscapeKeypad),
          matching: find.text(label),
        ))
        .center
        .dy;
    Rect lkRect(Finder f) => tester.getRect(find.descendant(
          of: find.byType(LandscapeKeypad),
          matching: f,
        ));
    final ys = ['7', '4', '1', '0'].map(cellCenterY).toList();
    expect(((ys[1] - ys[0]) - (ys[2] - ys[1])).abs(), lessThan(0.5),
        reason: 'cell 0->1 vs 1->2 spacing must match (uniform block)');
    expect(((ys[2] - ys[1]) - (ys[3] - ys[2])).abs(), lessThan(0.5),
        reason: 'cell 1->2 vs 2->3 spacing must match (uniform block)');

    // Backspace is the TOP-right key of the number block (shares the "7" row,
    // right of "9").
    final backspaceRect = lkRect(find.byIcon(Icons.backspace));
    expect((backspaceRect.center.dy - cellCenterY('7')).abs(), lessThan(0.5),
        reason: 'Backspace sits on the top row (with 7/8/9)');
    expect(
        backspaceRect.center.dx, greaterThan(lkRect(find.text('9')).center.dx));

    // The Standard unit keys fill columns to the RIGHT of the number block.
    expect(lkRect(find.text('Hour')).center.dx,
        greaterThan(backspaceRect.center.dx),
        reason: 'unit keys are to the right of the number/operator block');

    // "=" is the BOTTOM-RIGHT key: on the bottom row (sharing the "0" row) and
    // to the right of the last unit column.
    final equalsRect = lkRect(find.text('='));
    expect((equalsRect.center.dy - cellCenterY('0')).abs(), lessThan(0.5),
        reason: '"=" sits on the bottom row');
    expect(equalsRect.center.dx,
        greaterThan(lkRect(find.text('Hour')).center.dx),
        reason: '"=" is the right-most cell of the bottom row');

    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('landscape phone shows the resize handle and a landscape drag '
      'changes the split (the 7-column keypad reflows)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Landscape phone window (width > height, shortestSide < 600) => the
    // LandscapeKeypad (7-column) renders. The draggable handle must now be
    // present and grabbable here too (it used to be portrait-only).
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    // Start near the landscape minimum (the landscape clamp is ~0.42..0.66) so
    // there is room to drag DOWN and grow the display deterministically.
    await SettingsModel.instance.setDisplayFraction(0.42);

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The 7-column keypad is the one in use (not the portrait 4x6).
    expect(find.byType(LandscapeKeypad), findsOneWidget);
    expect(find.byType(PortraitKeypad), findsNothing);

    // The handle is present and grabbable in landscape (same "Resize display"
    // semantics as portrait).
    final handle = find.bySemanticsLabel('Resize display');
    expect(handle, findsOneWidget);

    // Measure the landscape keypad height before the drag.
    double keypadHeight() =>
        tester.getSize(find.byType(LandscapeKeypad)).height;
    final keypadBefore = keypadHeight();
    final fractionBefore = SettingsModel.instance.displayFraction;

    // Drag the handle DOWN (positive primaryDelta => the display grows, the
    // keypad shrinks). A landscape drag must change the split.
    await tester.drag(handle, const Offset(0, 80));
    await tester.pumpAndSettle();

    final keypadAfter = keypadHeight();
    expect(
      keypadAfter,
      lessThan(keypadBefore),
      reason: 'a landscape drag down must shrink the 7-column keypad',
    );
    expect(
      SettingsModel.instance.displayFraction,
      greaterThan(fractionBefore),
      reason: 'a landscape drag down must grow the display fraction',
    );
    // The split stays within the landscape clamp (the effective max is the
    // min-key-height ceiling, at most _kWideMaxDisplayFraction = 0.66).
    expect(
      SettingsModel.instance.displayFraction,
      lessThanOrEqualTo(0.66 + 1e-9),
    );

    // The full 7-column keypad still renders at the new size: every key and
    // the action column are present and a keypress still registers.
    for (final label in ['7', '0', '=', '–', 'Hour', 'Second']) {
      expect(
        find.descendant(
          of: find.byType(LandscapeKeypad),
          matching: find.text(label),
        ),
        findsOneWidget,
        reason: 'key $label after landscape resize',
      );
    }
    // The single Backspace delete key is still present too.
    expect(
      find.descendant(
        of: find.byType(LandscapeKeypad),
        matching: find.byIcon(Icons.backspace),
      ),
      findsOneWidget,
      reason: 'the single backspace key after landscape resize',
    );
    // The action/tools column must still not introduce a scroll view.
    expect(
      find.descendant(
        of: find.byType(LandscapeKeypad),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: find.byType(LandscapeKeypad),
        matching: find.text('7'),
      ),
    );
    await tester.pump();
    expect(find.text('7', findRichText: true), findsAtLeastNWidgets(2));

    // Restore the default split for the remaining tests.
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('a persisted "display_fraction" is restored on launch',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(540, 960);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Seed a NON-default, larger-display fraction on disk and load it (the
    // analog of a previous session's saved split, picked up before runApp).
    const restored = 0.66;
    SharedPreferences.setMockInitialValues(
      <String, Object>{'display_fraction': restored},
    );
    await SettingsModel.instance.load();
    expect(SettingsModel.instance.displayFraction, closeTo(restored, 1e-9));

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // The restored (larger) fraction produces a SHORTER keypad than the
    // default split would. Capture this run's keypad height ...
    final keypadRestored = tester.getSize(find.byType(PortraitKeypad)).height;

    // ... then relaunch at the default fraction and confirm its keypad is
    // taller (i.e. the restored value really drove the first layout).
    await SettingsModel.instance.setDisplayFraction(
      SettingsModel.defaultDisplayFraction,
    );
    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();
    final keypadDefault = tester.getSize(find.byType(PortraitKeypad)).height;
    expect(
      keypadRestored,
      lessThan(keypadDefault),
      reason: 'a larger restored display fraction shrinks the keypad',
    );

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('settings overlay switches the theme immediately and persists '
      'PREF_THEME_COLOR', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('THEME'), findsOneWidget);
    expect(find.text('System default'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('FEEDBACK'), findsOneWidget);
    expect(find.text('Send Feedback'), findsOneWidget);

    // Selecting Dark applies immediately (MaterialApp themeMode) ...
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(SettingsModel.instance.themeMode, ThemeMode.dark);
    expect(
      Theme.of(tester.element(find.text('THEME'))).brightness,
      Brightness.dark,
    );
    // ... and persists "2" under the verbatim Android key.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('PREF_THEME_COLOR'), '2');

    // Back to Light, then close via the toolbar back arrow.
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    expect(SettingsModel.instance.themeMode, ThemeMode.light);
    expect(prefs.getString('PREF_THEME_COLOR'), '1');

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('THEME'), findsNothing);

    // Restore the default for the remaining tests.
    await SettingsModel.instance.setThemeValue('0');
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('support overlay on iOS hides the buy buttons and never shows '
      'the custom rating dialog (guideline 5.6.1)', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.emoji_food_beverage));
    await tester.pumpAndSettle();
    expect(find.text('Support the app'), findsOneWidget);

    // Billing is unavailable on iOS: no tea copy, no buy buttons - only
    // review and share (dead purchase UI would be a 2.1 rejection).
    expect(find.textContaining('CUPS of TEA'), findsNothing);
    expect(find.textContaining('free and ad-free'), findsOneWidget);
    for (final label in ['buy 1 Cup', 'buy 3 Cups', 'buy 5 Cups',
        'buy 9 Cups']) {
      expect(find.text(label), findsNothing, reason: 'button $label');
    }
    expect(find.text('Leave a review'), findsOneWidget);
    expect(find.text('Share the app'), findsOneWidget);

    // "Leave a review" must NOT open the custom star dialog on iOS (it goes
    // to the native review sheet, which has no platform channel in tests).
    await tester.tap(find.text('Leave a review'));
    await tester.pumpAndSettle();
    expect(
      find.text('How was your experience with the Time Calculator?'),
      findsNothing,
    );

    // Close the overlay via the toolbar back arrow.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Support the app'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('support overlay on Android shows the donation buttons, the '
      'tea badge, and the custom rating flow', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Red attention badge on the tea cup: billing available, nothing owned.
    expect(find.byType(Badge), findsOneWidget);

    await tester.tap(find.byIcon(Icons.emoji_food_beverage));
    await tester.pumpAndSettle();
    expect(find.text('Support the app'), findsOneWidget);
    expect(find.textContaining('CUPS of TEA'), findsOneWidget);
    for (final label in [
      'buy 1 Cup',
      'buy 3 Cups',
      'buy 5 Cups',
      'buy 9 Cups',
      'Leave a review',
      'Share the app',
    ]) {
      expect(find.text(label), findsOneWidget, reason: 'button $label');
    }

    // Nothing is owned: every tier row is enabled (no "Owned" star) and tapping
    // one is a harmless no-op in tests (Monetization.init() never ran, so buy()
    // bails before touching platform channels). The tap exercises that path.
    await tester.tap(find.text('buy 1 Cup'));
    await tester.pump();

    // "Leave a review" opens the custom rating dialog immediately (force
    // path, Android keeps the original flow); dismiss it with "Later".
    await tester.ensureVisible(find.text('Leave a review'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave a review'));
    await tester.pumpAndSettle();
    expect(
      find.text('How was your experience with the Time Calculator?'),
      findsOneWidget,
    );
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(
      find.text('How was your experience with the Time Calculator?'),
      findsNothing,
    );

    // Close the overlay via the toolbar back arrow.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Support the app'), findsNothing);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('single tap on the result opens the action menu; Copy works',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Type "5 Hour - 10 Minute" so there is a result to act on.
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Hour'));
    await tester.pump();
    await tester.tap(find.text('–'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Minute'));
    await tester.pump();

    // No menu until the result is tapped.
    expect(find.text('Change result format'), findsNothing);

    // Tap the result hero -> the action sheet appears with all four actions.
    await tester.tap(find.byKey(const ValueKey('result-tappable')));
    await tester.pumpAndSettle();
    expect(find.text('Copy result'), findsOneWidget);
    expect(find.text('Change result format'), findsOneWidget);
    expect(find.text('Rate calculator'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);

    // Copy dismisses the sheet and confirms with a single snackbar.
    await tester.tap(find.text('Copy result'));
    await tester.pumpAndSettle();
    expect(find.text('Copy result'), findsNothing); // sheet gone
    expect(find.text('Copied to clipboard'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget); // exactly one toast

    // Let the snackbar's auto-dismiss timer elapse so none is left pending.
    await tester.pump(const Duration(seconds: 2));

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
      'long press on the result selects text instead of opening the action '
      'menu', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Type "5 Hour - 10 Minute" so there is a result to select.
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Hour'));
    await tester.pump();
    await tester.tap(find.text('–'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Minute'));
    await tester.pump();

    // Long-press the result: this must NOT open the custom action menu - it
    // hands off to the wrapping SelectionArea for native text selection.
    await tester.longPress(find.byKey(const ValueKey('result-tappable')));
    await tester.pumpAndSettle();
    expect(find.text('Change result format'), findsNothing);
    expect(find.text('Rate calculator'), findsNothing);

    // The native selection toolbar (Copy / Select all) is shown instead.
    expect(find.byType(AdaptiveTextSelectionToolbar), findsOneWidget);

    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('copying twice in a row never stacks two toasts',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Type "5 Hour - 10 Minute" so there is a result to copy.
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.tap(find.text('Hour'));
    await tester.pump();
    await tester.tap(find.text('–'));
    await tester.pump();
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('0'));
    await tester.pump();
    await tester.tap(find.text('Minute'));
    await tester.pump();

    Future<void> copyViaMenu() async {
      await tester.tap(find.byKey(const ValueKey('result-tappable')));
      await tester.pumpAndSettle(); // open the sheet
      await tester.tap(find.text('Copy result'));
      await tester.pumpAndSettle(); // close the sheet; toast stays (timer pending)
    }

    await copyViaMenu();
    expect(find.byType(SnackBar), findsOneWidget);

    // Copy again while the first toast is still on screen (well within 1300ms):
    // removeCurrentSnackBar must replace it instantly, never showing two.
    await copyViaMenu();
    expect(find.byType(SnackBar), findsOneWidget);

    // Flush the snackbar timer so none is left pending at test end.
    await tester.pump(const Duration(seconds: 2));

    debugDefaultTargetPlatformOverride = null;
  });

  test('platformConfirmsCopy: true only on native Android (which shows its own '
      'system copy confirmation), false elsewhere', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(platformConfirmsCopy, isTrue);
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(platformConfirmsCopy, isFalse);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(platformConfirmsCopy, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });
}
