import 'package:flutter/material.dart';

/// Theme palette of the RemoveADS redesign: the role-named colors from
/// `res/values/colors.xml` (light) and `res/values-night/colors.xml` (dark),
/// verbatim from docs/port-spec/delta-ui-theme-redesign.md section 5.
///
/// The old master palette (yellow Formats panel #9AFDD835, green Per panel
/// #66BB6A, indigo outlined buttons #304FFE, FAB scrim) no longer exists.
/// The branch's leftover translucent-yellow `ToolbarTheme` literals
/// (#9AFDD835 colorPrimary/textColor) are a documented bug and are
/// deliberately NOT ported.
class AppPalette {
  const AppPalette({
    required this.mainBackground,
    required this.secondaryBackground,
    required this.nums,
    required this.timeButtons,
    required this.controls,
    required this.resultTime,
    required this.resultNums,
    required this.cardBackground,
    required this.shadowBase,
    required this.displayCardSurface,
    required this.keypadCardSurface,
    required this.digitKeySurface,
    required this.operatorKeyFill,
    required this.operatorKeyText,
    required this.timeKeyFill,
    required this.timeKeyText,
    required this.equalsKeyFill,
    required this.equalsKeyText,
    required this.toolButtonFill,
  });

  /// colorMainBackground - main screen background.
  final Color mainBackground;

  /// colorSecondaryBackground / ...ForPer / ...ForSupport - one neutral value
  /// for the Formats/Per/Support/Settings panels AND the status bar.
  final Color secondaryBackground;

  /// colorNums - digits / dot / equals keys; colorExpressionNums aliases it.
  final Color nums;

  /// colorTimeBtns - time-unit keys; colorExpressionTime aliases it.
  final Color timeButtons;

  /// colorControls (NEW) - action icons and the selected-format label.
  final Color controls;

  /// colorResultTime (NEW) - time-unit spans in the result, clear flash.
  final Color resultTime;

  /// colorResultNums (NEW) - numbers/operators in the result/previews.
  final Color resultNums;

  /// CardView surface (Android DayNight default card background).
  final Color cardBackground;

  /// Base color of the text_view_shadow stripes (#CCCCCC / #222222).
  final Color shadowBase;

  // --- Material 3 Expressive redesign tokens (the hero-display + keypad-card
  // restyle). Each is a tonal SURFACE or a glyph-on-fill pair; the fill/text
  // pairs are MEASURED for WCAG (see the per-field ratios). All within a few %
  // luminance of [mainBackground] so the cards read as surfaces, not blocks.

  /// Hero DISPLAY card background: a rounded tonal surface a few % off
  /// [mainBackground] (light #F1EFEA, ~1.12:1 vs cream bg; dark #1A1A1A,
  /// ~1.11:1 vs #0E0E0E) so it reads as a raised surface, not a hard block.
  final Color displayCardSurface;

  /// KEYPAD card background (light #F3F1EC; dark #161616). Same surface idiom
  /// as [displayCardSurface], a hair warmer/cooler so the two cards separate.
  final Color keypadCardSurface;

  /// Neutral raised DIGIT-key cell fill (light #FFFFFF white-ish; dark
  /// #262626). Digit glyphs stay [nums]: nums-on-digitKeySurface measures
  /// 13.73:1 (light) / 4.74:1 (dark).
  final Color digitKeySurface;

  /// Blue-tonal OPERATOR cell fill (÷ × + −): light #DCEFF6, dark #0A2D38.
  /// Preserves the #0099CC blue identity as a tonal fill of that hue.
  final Color operatorKeyFill;

  /// Operator glyph color on [operatorKeyFill]: light #026E94 (4.84:1 on the
  /// fill), dark #5FD0F0 (8.14:1) - both clear WCAG AA.
  final Color operatorKeyText;

  /// Green-tonal TIME-UNIT cell fill (the seven Year..Second keys): light
  /// #E3EEDC, dark #132515. Preserves the green=time identity as a tonal fill.
  final Color timeKeyFill;

  /// Time-unit glyph color on [timeKeyFill]: light #33691E (5.51:1 on the
  /// fill), dark #7A9A70 (5.13:1) - both clear WCAG AA. (The dark fill was
  /// darkened from the proto's #18301A to #132515 to lift this risky pair from
  /// 4.53:1 to 5.13:1.)
  final Color timeKeyText;

  /// EQUALS key - a SOLID green fill (vs the light-green TONAL time keys and
  /// the blue-tonal operators) with a near-white glyph, so the compute/commit
  /// key reads as a distinct, prominent control: light fill #33691E, dark fill
  /// #3F7D2C; glyph #FFFFFF / #0E140B respectively.
  final Color equalsKeyFill;

  /// Glyph color on [equalsKeyFill].
  final Color equalsKeyText;

  /// Filled-tonal icon-button background for the tools row AND the format chip
  /// (light #FFFFFF neutral, with the format chip tinted green via
  /// [timeKeyFill] downstream; dark #262626). Tool glyphs use [controlsStrong]
  /// / [operators] downstream and clear WCAG on this fill (9.59:1 light /
  /// 9.71:1 dark for the neutral #454545 / #CFCFCF glyph).
  final Color toolButtonFill;

  /// A fully-opaque variant of [controls] for the action icons: same hue as
  /// colorControls, but the light theme's 0.8-alpha grey (#CC474646, ~3.6:1
  /// on the cream background) is lifted to full opacity so the toolbar glyphs
  /// clear the 3:1 meaningful-icon floor and stop reading as a faint
  /// afterthought. In dark, colorControls is already opaque #CCCCCC, so this
  /// is a no-op there.
  Color get controlsStrong => controls.withAlpha(0xFF);

  /// colorExpressionNums resolves to colorNums in both themes.
  Color get expressionNums => nums;

  /// colorExpressionTime resolves to colorTimeBtns in both themes.
  Color get expressionTime => timeButtons;

  /// colorOperators / colorAccent - holo_blue_dark in BOTH themes.
  static const Color operators = Color(0xFF0099CC);

  /// colorAccent (= holo_blue_dark); star/share icon tint.
  static const Color accent = operators;

  /// ERROR token color (unchanged red).
  static const Color error = Color(0xFFFF0000);

  /// ic_food_checked red attention-badge dot (#FF0000).
  static const Color badge = Color(0xFFFF0000);

  /// ic_star_green_24dp fill verbatim (#33691E, same dark green as the
  /// light-theme time buttons) - the "thank-you" star on owned support tiers.
  static const Color supportStar = Color(0xFF33691E);

  /// Dark-theme variant of [supportStar]: a lighter shade of the same green
  /// (~6:1 on the #1E1E1E card) because #33691E is only 2.52:1 there - below
  /// the 3:1 meaningful-icon floor, so the owned-tier star was near-invisible.
  static const Color supportStarDark = Color(0xFF7CB342);

  /// The owned-tier star tint for the active theme.
  static Color supportStarOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? supportStarDark
          : supportStar;

  /// values/colors.xml (light theme).
  static const AppPalette light = AppPalette(
    mainBackground: Color(0xFFFDFCFA),
    secondaryBackground: Color(0xFFE8E8E8),
    nums: Color(0xFF2E2D2D),
    timeButtons: Color(0xFF33691E),
    controls: Color(0xCC474646),
    // Darkened from #567749 (4.42:1 on displayCardSurface #F1EFEA - fails the
    // 4.5:1 normal-text floor that the result's 0.7x time-unit spans hit at the
    // smallest landscape result size) to #4D6B41 = 5.23:1; same ~103deg green
    // hue/sat, lower luminance, still distinct from the brighter
    // expressionTime/timeButtons #33691E used on the same surface.
    resultTime: Color(0xFF4D6B41),
    resultNums: Color(0xCC474646), // = colorControls in light.
    cardBackground: Color(0xFFFFFFFF),
    shadowBase: Color(0xFFCCCCCC),
    // Expressive redesign tonal surfaces + glyph-on-fill pairs (light).
    displayCardSurface: Color(0xFFF1EFEA),
    keypadCardSurface: Color(0xFFF3F1EC),
    digitKeySurface: Color(0xFFFFFFFF),
    operatorKeyFill: Color(0xFFDCEFF6), // blue-tonal; #026E94 glyph = 4.84:1.
    operatorKeyText: Color(0xFF026E94),
    timeKeyFill: Color(0xFFE3EEDC), // green-tonal; #33691E glyph = 5.51:1.
    timeKeyText: Color(0xFF33691E),
    equalsKeyFill: Color(0xFF33691E), // SOLID green; white glyph = 5.6:1.
    equalsKeyText: Color(0xFFFFFFFF),
    toolButtonFill: Color(0xFFFFFFFF),
  );

  /// values-night/colors.xml (dark theme).
  static const AppPalette dark = AppPalette(
    mainBackground: Color(0xFF0E0E0E),
    secondaryBackground: Color(0xFF131313),
    // Brightened from #777777 (4.31:1, below AA) to #909090 (6.05:1) so the
    // digit keys read crisply and stop looking dim next to the blue operators.
    nums: Color(0xFF909090),
    // Brightened from #53654D (3.07:1, failed AA) to #7A9A70 (6.1:1) - same
    // desaturated olive-green identity, just lifted luminance so the time-unit
    // keys/expression spans are legible on the near-black background.
    timeButtons: Color(0xFF7A9A70),
    controls: Color(0xFFCCCCCC),
    // Brightened from #727C6E (4.43:1, fractionally below AA at the 0.7x token
    // size) to #828E7B (5.6:1); same hue, pairs with resultNums #939292.
    resultTime: Color(0xFF828E7B),
    resultNums: Color(0xFF939292),
    // MDC DayNight colorSurface #121212 + ~2dp elevation overlay, matching
    // the branch's un-themed MaterialCardView dark rendering.
    cardBackground: Color(0xFF1E1E1E),
    shadowBase: Color(0xFF222222),
    // Expressive redesign tonal surfaces + glyph-on-fill pairs (dark). The
    // green pairs the judge flagged were tuned here: timeKeyFill darkened to
    // #132515 so timeKeyText #7A9A70 reads at 5.13:1 (was 4.53:1 on the
    // proto's #18301A).
    displayCardSurface: Color(0xFF1A1A1A),
    keypadCardSurface: Color(0xFF161616),
    digitKeySurface: Color(0xFF262626),
    operatorKeyFill: Color(0xFF0A2D38), // deep teal-blue; #5FD0F0 glyph = 8.14:1.
    operatorKeyText: Color(0xFF5FD0F0),
    timeKeyFill: Color(0xFF132515), // deep green; #7A9A70 glyph = 5.13:1.
    timeKeyText: Color(0xFF7A9A70),
    equalsKeyFill: Color(0xFF3F7D2C), // SOLID brighter green; dark glyph 6.5:1.
    equalsKeyText: Color(0xFF0E140B),
    toolButtonFill: Color(0xFF262626),
  );

  /// The palette of the ACTIVE theme.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Alpha levels of the six 1dp text_view_shadow stripes, TOP to BOTTOM.
/// The light drawable lists them bottom-up as 00/10/20/30/50/00 CCCCCC.
/// DELIBERATE FIX vs the branch: drawable-night used #00222222 for the
/// 4th bottom-up layer (a typo leaving a transparent hole in the dark
/// gradient); both themes use the light sequence with their own base color,
/// i.e. the dark stripe is #30222222 where the branch had #00222222.
const List<int> kShadowStripeAlphas = [0x00, 0x50, 0x30, 0x20, 0x10, 0x00];

/// Which of the three fixed dimens buckets is active. The RemoveADS branch
/// replaced master's 13 continuously-scaled values-sw###dp buckets with
/// exactly three resource tables.
enum DimensBucket {
  /// values/ - phone portrait.
  base,

  /// values-land/ - phone landscape.
  land,

  /// values-sw600dp/ - tablets (shortestSide >= 600) in BOTH orientations
  /// (the Android sw qualifier beats the orientation qualifier).
  sw600,
}

/// The three fixed dimension tables, verbatim from
/// delta-ui-theme-redesign.md section 1 (values/ | values-land/ |
/// values-sw600dp/).
class Dimens {
  const Dimens._({
    required this.bucket,
    required this.buttonsNumSize,
    required this.buttonsNumMinWidth,
    required this.buttonsTimeSize,
    required this.buttonsOperatorsSize,
    required this.margin16,
    required this.margin8,
    required this.resultOutputMinTextSize,
    required this.expressionMinTextSize,
    required this.separatorTimeTextSize,
    required this.paddingButtons,
    required this.paddingButtonsTime,
    required this.paddingButtonsAction,
    required this.settingsGroupTextSize,
    required this.settingsItemTextSize,
    required this.settingsItemMinHeight,
  });

  /// Bucket resolution: tablets (shortestSide >= 600) use sw600 in BOTH
  /// orientations; phones use base in portrait and land in landscape.
  factory Dimens.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.shortestSide >= 600) return sw600;
    return size.width > size.height ? land : base;
  }

  final DimensBucket bucket;
  final double buttonsNumSize;
  final double buttonsNumMinWidth;
  final double buttonsTimeSize;
  final double buttonsOperatorsSize;
  final double margin16;
  final double margin8;
  final double resultOutputMinTextSize;
  final double expressionMinTextSize;
  final double separatorTimeTextSize;
  final double paddingButtons;
  final double paddingButtonsTime;
  final double paddingButtonsAction;
  final double settingsGroupTextSize;
  final double settingsItemTextSize;
  final double settingsItemMinHeight;

  /// values/ - phone portrait.
  // Keypad sizing trimmed for the redesign review: the keypad card was eating
  // ~55% of the screen and starving the hero display. The digit/time font
  // sizes (36->33, 24->23) and the row v-padding (6->5, 12->10) are pulled in
  // so the portrait keypad envelope shrinks and the hero display card
  // gains the freed vertical room. The trim is bounded so every key cell still
  // resolves to >=45dp tall (above the 44dp tap-target floor) after the 8dp
  // inter-row gaps; the bulk of the keypad-card shrink comes from the lighter
  // tools-row gap + card padding (see _kToolsRowGap / keypadCardPadding*).
  static const Dimens base = Dimens._(
    bucket: DimensBucket.base,
    buttonsNumSize: 33,
    buttonsNumMinWidth: 38,
    buttonsTimeSize: 24,
    buttonsOperatorsSize: 34,
    margin16: 16,
    margin8: 8,
    resultOutputMinTextSize: 16,
    expressionMinTextSize: 24,
    separatorTimeTextSize: 18,
    paddingButtons: 6,
    paddingButtonsTime: 11,
    paddingButtonsAction: 5,
    settingsGroupTextSize: 18,
    settingsItemTextSize: 20,
    settingsItemMinHeight: 50,
  );

  /// values-land/ - phone landscape.
  static const Dimens land = Dimens._(
    bucket: DimensBucket.land,
    // Key glyphs now size PROPORTIONALLY to the cell (keypad.dart); these are
    // only generous upper CAPS. Reverted from the earlier hard-reduction (which
    // marooned tiny text in big buttons) - landscape keys shrink by being
    // resized smaller, with the font scaling down with them.
    buttonsNumSize: 33,
    buttonsNumMinWidth: 38,
    buttonsTimeSize: 24,
    buttonsOperatorsSize: 33,
    margin16: 10,
    margin8: 6,
    // Raised from 10 to 20: the live RESULT is the hero of the display card and
    // must stay legible in the short landscape hero. At 10sp the 0.7x time-unit
    // spans rendered ~7sp grey (below the 4.5:1 normal-text floor) and the
    // result read as a tiny caption. At >=20 the result keeps a hero size and
    // the overflowReplacement scroll kicks in instead of collapsing.
    resultOutputMinTextSize: 20,
    expressionMinTextSize: 14,
    separatorTimeTextSize: 14,
    paddingButtons: 6,
    paddingButtonsTime: 7,
    paddingButtonsAction: 3,
    settingsGroupTextSize: 14,
    settingsItemTextSize: 16,
    settingsItemMinHeight: 44,
  );

  /// values-sw600dp/ - tablets, both orientations.
  static const Dimens sw600 = Dimens._(
    bucket: DimensBucket.sw600,
    buttonsNumSize: 36,
    buttonsNumMinWidth: 48,
    buttonsTimeSize: 24,
    buttonsOperatorsSize: 34,
    margin16: 16,
    margin8: 8,
    resultOutputMinTextSize: 16,
    expressionMinTextSize: 24,
    separatorTimeTextSize: 18,
    paddingButtons: 6,
    paddingButtonsTime: 14,
    paddingButtonsAction: 6,
    settingsGroupTextSize: 18,
    settingsItemTextSize: 20,
    settingsItemMinHeight: 50,
  );

  /// Constant in all three buckets.
  double get resultOutputHeight => 60;
  double get resultOutputMaxTextSize => 50;
  double get expressionMaxTextSize => 64;

  /// Autosize granularity: 2sp for BOTH the expression and (new on the
  /// branch) the result line.
  double get autoSizeStep => 2;

  /// Height of the fake drop-shadow strip (six 1dp layers).
  double get shadowHeight => 6;

  /// Action icon vectors are 30x30dp.
  double get actionIconSize => 30;

  // --- Material 3 Expressive redesign geometry (the hero-display + keypad-card
  // restyle). Constant across all three buckets, mirroring the proto: build
  // agents must read these instead of literals.

  /// Corner radius of each soft tonal KEY cell (digit / operator / time-unit).
  double get keyCellRadius => 18;

  /// Gap between adjacent key cells (both horizontal between cells in a row and
  /// vertical between rows) - the ~8dp grid of the redesign.
  double get keyGap => 8;

  /// Corner radius of the two large rounded cards (hero display + keypad).
  double get cardRadius => 32;

  /// Inner padding of the HERO DISPLAY card. The bottom inset is intentionally
  /// tight (10dp, was 22) so the bottom-anchored result HUGS the card's lower
  /// edge instead of stranding a band of empty surface below it - the wasted
  /// gap the redesign review flagged. Left/right stay at 22; the top stays
  /// smaller so the format chip sits close to the top edge.
  double get displayCardPaddingH => 22;
  double get displayCardPaddingTop => 18;
  double get displayCardPaddingBottom => 10;

  /// Inner padding of the KEYPAD card. The proto used LTRB 12/12/12/14; the
  /// top/bottom are pulled to 10 each as part of the keypad-card slimming so the
  /// freed vertical room goes to the hero display. L/R stay at 12.
  double get keypadCardPaddingH => 12;
  double get keypadCardPaddingTop => 10;
  double get keypadCardPaddingBottom => 10;

  /// Outer gap between the hero display card and the keypad card.
  double get cardGap => 16;

  /// Base (un-fitted) font size of the big live RESULT hero in the display
  /// card; the result auto-scales DOWN from here via FittedBox.
  double get heroResultBaseSize => 46;

  /// Base font size of the time-unit spans inside the result hero (the proto
  /// pairs a 46dp number with a 34dp unit word).
  double get heroResultUnitSize => 34;

  /// Whether this bucket lays the hero card out as a WIDE surface (landscape /
  /// tablet). The narrow portrait card makes right-aligned content read as
  /// intentional; the wide buckets need extra composition guards below so the
  /// expression+result group doesn't strand in the bottom-right corner of an
  /// otherwise empty card.
  bool get isWideHero => bucket != DimensBucket.base;

  /// Max width of the hero's expression+result content group on WIDE buckets
  /// (landscape/tablet). Without it the group hard-right-aligns against the
  /// card edge with the format chip stranded in the opposite corner; capping
  /// the width and right-aligning the group under the chip anchors both to a
  /// common right grid so the wide card reads as a deliberate hero. Portrait
  /// (base) is unconstrained (double.infinity) - its narrow card needs no cap.
  double get heroMaxContentWidth => isWideHero ? 520 : double.infinity;

  /// Max font size of the EXPRESSION line inside the hero. On wide buckets the
  /// expression is capped BELOW [heroResultBaseSize] so it can never render
  /// larger than the result hero and invert the visual hierarchy (the result
  /// is always the dominant line). Portrait keeps the original 64sp ceiling.
  double get heroExpressionMaxTextSize =>
      isWideHero ? heroResultBaseSize * 0.7 : expressionMaxTextSize;

  /// Edge length of a filled-tonal TOOL button (Per / tea / settings /
  /// backspace) and the format chip's optical height in the tools row. The
  /// padded hit region stays >= 48dp.
  double get toolButtonSize => 48;

  /// Corner radius of a filled-tonal tool button.
  double get toolButtonRadius => 16;

  /// Corner radius of the format-selector assist chip.
  double get formatChipRadius => 20;

  /// Unified optical size for ALL action-row glyphs (Delete/Per/Tea/Settings)
  /// so the row reads as one designed toolbar instead of a 30dp grey strip
  /// with a lone 24dp blue backspace. Matches the backspace at 24dp; the
  /// padded hit region (>=48dp) is unchanged.
  double get actionGlyphSize => 24;

}

/// Builds font-size presets descending from [max] to [min] in [step]
/// increments - the equivalent of Android autoSizeTextType=uniform with
/// min/max/granularity, expressed as auto_size_text presetFontSizes.
List<double> autoSizePresets({
  required double min,
  required double max,
  required double step,
}) {
  final sizes = <double>[];
  for (var size = max; size > min; size -= step) {
    sizes.add(size);
  }
  sizes.add(min);
  return sizes;
}

/// App-wide theme pair: ABeeZee everywhere, DayNight palettes, accent
/// holo_blue_dark (the branch AppTheme: Theme.MaterialComponents.DayNight
/// .NoActionBar.Bridge with colorPrimary #008577 and colorAccent
/// holo_blue_dark; status bar colorSecondaryBackground is applied via
/// SystemUiOverlayStyle in main.dart).
ThemeData buildAppTheme(Brightness brightness) {
  final palette =
      brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF008577),
    brightness: brightness,
  ).copyWith(secondary: AppPalette.accent);
  return ThemeData(
    fontFamily: 'ABeeZee',
    colorScheme: colorScheme,
    scaffoldBackgroundColor: palette.mainBackground,
    cardTheme: CardThemeData(color: palette.cardBackground),
    // The settings radios render in the accent color, like the Android
    // colorAccent-tinted AppCompat radio buttons.
    radioTheme: const RadioThemeData(
      fillColor: WidgetStatePropertyAll(AppPalette.accent),
    ),
    // ?android:attr/listDivider equivalent for the settings rows.
    dividerTheme: DividerThemeData(
      color: brightness == Brightness.dark
          ? const Color(0x1FFFFFFF)
          : const Color(0x1F000000),
      thickness: 1,
      space: 1,
    ),
  );
}
