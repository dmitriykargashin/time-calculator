// Tests for the Year/Msec swappable keypad key (Settings "Show Msec key instead
// of Year"): the persisted setting and the live keypad swap.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cardamon_time_calculator/engine/token_type.dart';
import 'package:cardamon_time_calculator/main.dart';
import 'package:cardamon_time_calculator/state/calculator_model.dart';
import 'package:cardamon_time_calculator/state/settings_model.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CalculatorModel.instance.clearAll();
    // Reset the shared singleton to the shipped default (Msec) + the Standard
    // unit set (the picker mutates the same singleton).
    await SettingsModel.instance.setKeypadShowsMsec(true);
    await SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first);
    await SettingsModel.instance
        .setThemeValue(SettingsModel.themeValueLight);
  });

  KeypadUnitPreset presetNamed(String name) =>
      SettingsModel.keypadUnitPresets.firstWhere((p) => p.name == name);

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

  testWidgets('the keypad shows exactly the enabled unit keys', (tester) async {
    await tester.pumpWidget(const TimeCalculatorApp());
    await tester.pumpAndSettle();

    // Default (Standard): the Msec key is shown, no Year key.
    expect(find.text('Msec'), findsOneWidget);
    expect(find.text('Year'), findsNothing);

    // Calendar (Day/Week/Month/Year) -> the Year key appears, Msec is gone.
    await SettingsModel.instance.applyKeypadUnitPreset(presetNamed('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Year'), findsOneWidget);
    expect(find.text('Msec'), findsNothing);

    // Back to Standard -> Msec returns, Year is gone.
    await SettingsModel.instance
        .applyKeypadUnitPreset(SettingsModel.keypadUnitPresets.first);
    await tester.pumpAndSettle();
    expect(find.text('Msec'), findsOneWidget);
    expect(find.text('Year'), findsNothing);
  });

  group('SettingsModel keypad unit selection (keypad-key customization)', () {
    test('defaults to the Standard preset (Msec..Month, no Year)', () {
      final s = SettingsModel.instance;
      expect(s.isKeypadUnitEnabled(TokenType.mSecond), isTrue);
      expect(s.isKeypadUnitEnabled(TokenType.year), isFalse);
      expect(s.enabledUnits.length, 7);
      expect(s.activeKeypadUnitPreset?.name, 'Standard');
    });

    test('enabledUnits is always in canonical small->large order', () async {
      final s = SettingsModel.instance;
      await s.applyKeypadUnitPreset(presetNamed('Everything'));
      expect(s.enabledUnits, SettingsModel.allKeypadUnits);
    });

    test('toggling a unit off updates the getter and persists', () async {
      final s = SettingsModel.instance;
      await s.setKeypadUnitEnabled(TokenType.week, false);
      expect(s.isKeypadUnitEnabled(TokenType.week), isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getStringList(SettingsModel.prefEnabledUnitsKey),
        isNot(contains('week')),
      );
    });

    test('the minimum of two units is enforced', () async {
      final s = SettingsModel.instance;
      await s.applyKeypadUnitPreset(presetNamed('Hours & minutes'));
      expect(s.enabledUnits.length, 2);
      // Dropping to one is refused (the two keys stay).
      await s.setKeypadUnitEnabled(TokenType.hour, false);
      expect(s.enabledUnits.length, 2);
      expect(s.isKeypadUnitEnabled(TokenType.hour), isTrue);
    });

    test('a non-preset selection reports a Custom (null) preset', () async {
      final s = SettingsModel.instance;
      await s.setEnabledUnits(
          {TokenType.hour, TokenType.second, TokenType.day});
      expect(s.activeKeypadUnitPreset, isNull);
    });

    test('Year-without-Msec drives the keypad swap slot to Year', () async {
      final s = SettingsModel.instance;
      await s.setEnabledUnits(
          {TokenType.year, TokenType.hour, TokenType.minute});
      expect(s.keypadShowsMsec, isFalse);
    });

    test('load() reads the stored unit set back', () async {
      final s = SettingsModel.instance;
      await s.applyKeypadUnitPreset(presetNamed('Stopwatch'));
      await s.load();
      expect(s.activeKeypadUnitPreset?.name, 'Stopwatch');
    });
  });
}
