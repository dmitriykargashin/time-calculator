// Tests for the Year/Msec swappable keypad key (Settings "Show Msec key instead
// of Year"): the persisted setting and the live keypad swap.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CalculatorModel.instance.clearAll();
    // Reset the shared singleton to the shipped default (Msec).
    await SettingsModel.instance.setKeypadShowsMsec(true);
    await SettingsModel.instance
        .setThemeValue(SettingsModel.themeValueLight);
  });

  group('SettingsModel.keypadShowsMsec', () {
    test('defaults to true (Msec) when nothing is stored', () async {
      // Clear the key on the (cached) prefs instance, then load: the absent
      // value must fall back to the Msec default.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(SettingsModel.prefKeypadShowsMsecKey);
      await SettingsModel.instance.load();
      expect(SettingsModel.instance.keypadShowsMsec, isTrue);
    });

    test('the setter updates the getter and persists to prefs', () async {
      await SettingsModel.instance.setKeypadShowsMsec(false);
      expect(SettingsModel.instance.keypadShowsMsec, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsModel.prefKeypadShowsMsecKey), isFalse);

      await SettingsModel.instance.setKeypadShowsMsec(true);
      expect(SettingsModel.instance.keypadShowsMsec, isTrue);
      expect(prefs.getBool(SettingsModel.prefKeypadShowsMsecKey), isTrue);
    });

    test('load() reads a stored value back', () async {
      await SettingsModel.instance.setKeypadShowsMsec(false);
      await SettingsModel.instance.load();
      expect(SettingsModel.instance.keypadShowsMsec, isFalse);
    });
  });

  testWidgets('the keypad swaps Msec <-> Year with the setting',
      (tester) async {
    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Default: the Msec key is shown, no Year key.
    expect(find.text('Msec'), findsOneWidget);
    expect(find.text('Year'), findsNothing);

    // Turn the option OFF -> the Year key replaces Msec.
    await SettingsModel.instance.setKeypadShowsMsec(false);
    await tester.pumpAndSettle();
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Msec'), findsNothing);

    // Turn it ON -> the Msec key returns.
    await SettingsModel.instance.setKeypadShowsMsec(true);
    await tester.pumpAndSettle();
    expect(find.text('Msec'), findsOneWidget);
    expect(find.text('Year'), findsNothing);
  });
}
