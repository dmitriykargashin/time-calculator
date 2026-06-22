// F6: History / Calculation Log - the opt-in store, recording on "=", and the
// History overlay (entry point gated on the Settings toggle, tap-to-reload).

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/data/repositories.dart';
import 'package:cardamon_time_calculator/engine/big_decimal.dart';
import 'package:cardamon_time_calculator/engine/token.dart';
import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/services/history_service.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';

CalculatorModel _freshModel() => CalculatorModel(
      expressionRepository: ExpressionRepository(),
      tokensRepository: TokensRepository(),
      resultFormatsRepository: ResultFormatsRepository.getInstance(),
      perUnitsRepository: PerUnitsRepository.getInstance(),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CalculatorModel.instance.clearAll();
    CalculatorModel.instance.setIsHistoryLayoutVisible(false);
    // Reset the shared selected format to the default "Hour Minute" (index 18)
    // so the format-restore tests below don't leak into the others.
    ResultFormatsRepository.getInstance().setSelectedFormat(18);
    HistoryService.instance.clear();
    // Reset BOTH stores directly: setHistoryEnabled(false) no-ops when
    // SettingsModel is already false, so it would not reset HistoryService.
    HistoryService.instance.setEnabled(false);
    await SettingsModel.instance.setHistoryEnabled(false);
  });

  group('HistoryService', () {
    test('record is a no-op while history is disabled', () {
      HistoryService.instance.setEnabled(false);
      HistoryService.instance.record('5 Hour', '5 Hours');
      expect(HistoryService.instance.entries, isEmpty);
    });

    test('records newest-first when enabled', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours');
      HistoryService.instance.record('2 Day', '48 Hours');
      final e = HistoryService.instance.entries;
      expect(e.length, 2);
      expect(e.first.expression, '2 Day');
      expect(e.last.expression, '5 Hour');
    });

    test('caps at maxEntries; the oldest is dropped', () {
      HistoryService.instance.setEnabled(true);
      for (var i = 0; i < HistoryService.maxEntries + 3; i++) {
        HistoryService.instance.record('$i Hour', '$i Hours');
      }
      final e = HistoryService.instance.entries;
      expect(e.length, HistoryService.maxEntries);
      expect(e.first.expression, '${HistoryService.maxEntries + 2} Hour');
      expect(e.last.expression, '3 Hour'); // 0,1,2 dropped
    });

    test('skips an entry whose expression equals its result', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('4 Hours', '4 Hours');
      expect(HistoryService.instance.entries, isEmpty);
    });

    test('skips a duplicate of the most recent entry', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours');
      HistoryService.instance.record('5 Hour', '5 Hours');
      expect(HistoryService.instance.entries.length, 1);
    });

    test('clear empties the log', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours');
      HistoryService.instance.clear();
      expect(HistoryService.instance.entries, isEmpty);
    });

    test('record stamps a timestamp', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours', at: 1718000000000);
      expect(HistoryService.instance.entries.first.timestamp, 1718000000000);
    });

    test('removeAt deletes the specific record', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('1 Hour', '1 Hour x'); // a
      HistoryService.instance.record('2 Hour', '2 Hour x'); // b (newest)
      HistoryService.instance.record('3 Hour', '3 Hour x'); // c (newest)
      // Delete the middle one (index 1 = '2 Hour').
      HistoryService.instance.removeAt(1);
      final e = HistoryService.instance.entries;
      expect(e.length, 2);
      expect(e.map((x) => x.expression), ['3 Hour', '1 Hour']);
    });

    test('setNote sets and clears a record note', () {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours');
      HistoryService.instance.setNote(0, '  Payroll  ');
      expect(HistoryService.instance.entries.first.note, 'Payroll'); // trimmed
      HistoryService.instance.setNote(0, '');
      expect(HistoryService.instance.entries.first.note, isEmpty);
    });

    test('note, timestamp and format round-trip through persistence', () async {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance
          .record('5 Hour', '5 Hours', formatIndex: 18, at: 1718000000000);
      HistoryService.instance.setNote(0, 'Payroll');
      await HistoryService.instance.load(enabled: true);
      final e = HistoryService.instance.entries.first;
      expect(e.note, 'Payroll');
      expect(e.timestamp, 1718000000000);
      expect(e.formatIndex, 18);
    });

    test('persists and reloads', () async {
      HistoryService.instance.setEnabled(true);
      HistoryService.instance.record('5 Hour', '5 Hours');
      await HistoryService.instance.load(enabled: true);
      expect(HistoryService.instance.entries.length, 1);
      expect(HistoryService.instance.entries.first.expression, '5 Hour');
    });

    test('load drops corrupt rows without crashing', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(HistoryService.prefHistoryKey, [
        'not json',
        '{"e":"5 Hour","r":"5 Hours"}',
        '{"bad":1}',
      ]);
      await HistoryService.instance.load(enabled: true);
      expect(HistoryService.instance.entries.length, 1);
      expect(HistoryService.instance.entries.first.result, '5 Hours');
    });
  });

  group('SettingsModel.historyEnabled', () {
    test('defaults to ON; the setter persists + drives HistoryService',
        () async {
      // With no stored value, history is on by default.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SettingsModel.prefHistoryEnabledKey);
      await SettingsModel.instance.load();
      expect(SettingsModel.instance.historyEnabled, isTrue);
      expect(HistoryService.instance.isEnabled, isTrue);

      // Turning it off persists and stops recording.
      await SettingsModel.instance.setHistoryEnabled(false);
      expect(SettingsModel.instance.historyEnabled, isFalse);
      expect(HistoryService.instance.isEnabled, isFalse);
      expect(prefs.getBool(SettingsModel.prefHistoryEnabledKey), isFalse);
    });
  });

  group('CalculatorModel history wiring', () {
    test('"=" records "expression = result" when history is on', () {
      HistoryService.instance.setEnabled(true);
      final model = _freshModel();
      model.addToExpression(Token(TokenType.number, BigDecimal.fromInt(2), '2'));
      model.addToExpressionTimeUnit(TokenType.day);
      expect(model.isResultEmpty(), isFalse);

      model.sendResultToExpression(); // the "=" action
      final e = HistoryService.instance.entries;
      expect(e.length, 1);
      expect(e.first.expression, '2 Days');
      expect(e.first.result, '48 Hours');
      expect(e.first.formatIndex, 18); // the selected "Hour Minute" format
    });

    test('"=" records nothing while history is off', () {
      HistoryService.instance.setEnabled(false);
      final model = _freshModel();
      model.addToExpression(Token(TokenType.number, BigDecimal.fromInt(2), '2'));
      model.addToExpressionTimeUnit(TokenType.day);
      model.sendResultToExpression();
      expect(HistoryService.instance.entries, isEmpty);
    });

    test('loadExpressionFromHistory lexes the expression and recomputes', () {
      final model = _freshModel();
      model.loadExpressionFromHistory('2 Days');
      expect(model.expression.value.toStringWithSpaces(), '2 Days');
      expect(model.isResultEmpty(), isFalse);
      expect(model.resultTokens.value.toStringWithSpaces(), '48 Hours');
    });

    test('loadFromHistory restores the saved result format and result', () {
      final model = _freshModel();
      // An entry saved in the "Minute" format (index 21).
      model.loadFromHistory(
          const HistoryEntry('2 Day', '2880 Minutes', formatIndex: 21));
      expect(model.expression.value.toStringWithSpaces(), '2 Days');
      // Recomputed in the restored format, not the current "Hour Minute".
      expect(model.resultTokens.value.toStringWithSpaces(), '2880 Minutes');
      expect(model.selectedFormat.value!.textPresentationOfTokens, 'Minute');
    });
  });

  group('the History overlay in the UI', () {
    testWidgets('the History icon is hidden by default and appears when '
        'enabled; the overlay opens with an empty state', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.history), findsNothing);

      await SettingsModel.instance.setHistoryEnabled(true);
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.history), findsOneWidget);

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.textContaining('No calculations yet'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('tapping a history entry reloads it into the calculator and '
        'closes the overlay', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await SettingsModel.instance.setHistoryEnabled(true);
      HistoryService.instance.clear();
      HistoryService.instance.record('2 Days', '48 Hours');

      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      final rowFinder = find.byKey(const ValueKey('history-entry-0'));
      expect(rowFinder, findsOneWidget);

      // Invoke the entry row's tap callback directly: a positional tap through
      // the overlay's circular-reveal clip is flaky in tests, but this still
      // exercises the real onSelect -> load + close wiring.
      final row = tester.widget<InkWell>(rowFinder);
      expect(row.onTap, isNotNull);
      row.onTap!();
      await tester.pumpAndSettle();

      expect(CalculatorModel.instance.isHistoryLayoutVisible, isFalse);
      expect(
        CalculatorModel.instance.resultTokens.value.toStringWithSpaces(),
        '48 Hours',
      );

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('the per-record menu deletes that record', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await SettingsModel.instance.setHistoryEnabled(true);
      HistoryService.instance.clear();
      HistoryService.instance.record('5 Hour', '5 Hours');
      HistoryService.instance.record('2 Days', '48 Hours'); // newest

      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(HistoryService.instance.entries.length, 2);

      IconButton deleteBtnFor(int i) => tester.widget<IconButton>(
            find.descendant(
              of: find.byKey(ValueKey('history-entry-$i')),
              matching: find.widgetWithIcon(IconButton, Icons.delete_outline),
            ),
          );

      // Delete needs confirmation: Cancel keeps the record.
      deleteBtnFor(0).onPressed!();
      await tester.pumpAndSettle();
      expect(find.text('Delete this calculation?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(HistoryService.instance.entries.length, 2);

      // Now confirm: the newest record is removed.
      deleteBtnFor(0).onPressed!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(HistoryService.instance.entries.length, 1);
      expect(HistoryService.instance.entries.first.expression, '5 Hour');

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('adding a note via the menu dialog stores it (no dispose '
        'crash)', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await SettingsModel.instance.setHistoryEnabled(true);
      HistoryService.instance.clear();
      HistoryService.instance.record('2 Days', '48 Hours');

      await tester.pumpWidget(const TimeCalculatorApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Invoke the record's footer "edit note" action -> opens the dialog.
      final editBtn = tester.widget<IconButton>(
        find.descendant(
          of: find.byKey(const ValueKey('history-entry-0')),
          matching: find.widgetWithIcon(IconButton, Icons.edit_outlined),
        ),
      );
      editBtn.onPressed!();
      await tester.pumpAndSettle();

      // Type and save - this open/type/save/dispose flow previously crashed
      // with the InheritedElement `_dependents.isEmpty` assertion.
      await tester.enterText(find.byType(TextField), 'Payroll');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(HistoryService.instance.entries.first.note, 'Payroll');

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
