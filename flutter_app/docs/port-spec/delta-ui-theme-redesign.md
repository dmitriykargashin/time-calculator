# RemoveADS branch delta: ui-theme-redesign

## Summary
The RemoveADS branch is a full visual overhaul of the master UI the Flutter port was built from. Ads and the FAB speed-dial menu are deleted; the calculator gains a 4-icon action row (Formats/Per/Support-cup/Settings + backspace) and a read-only selected-format label; the 13 values-sw###dp scaling buckets are replaced by three fixed dimen tables (base, values-land, values-sw600dp) with much larger key text (36/24/34sp) and no minWidth in portrait so keys fit narrow screens; landscape and sw600 tablets share one identical 7-column layout (tablets use it in both orientations). A new in-app Settings overlay (THEME radio group: System default/Light/Dark persisted as "0"/"1"/"2" in SharedPreferences MY_APP_PREF/PREF_THEME_COLOR, applied instantly via AppCompatDelegate DayNight; FEEDBACK mailto support@cardamon.org) and a new Support overlay (buy 1/3/5/9 cups, Leave a review, Share the app) open with the same circular-reveal as Formats/Per, and all overlay visibility persists across the theme-change recreation. Dark theme ships as Theme.MaterialComponents.DayNight + values-night/colors.xml (near-black #0E0E0E/#131313 palette mirroring the new neutral light palette #FDFCFA/#E8E8E8), values-v23 adds windowLightStatusBar, and every span/icon color was refactored from hardcoded hex to theme-resolved resources. Formats/Per overlays turn neutral grey, cards get 20dp corners/8dp margins, the Per form is restructured with horizontally scrollable headers, and a handful of new strings (rating dialog, support copy) are added verbatim. For flutter_app this means restructuring calculator_screen/keypad (new grids, new action row, two new screens, no fab_menu/ad_banner) plus a theming pass (dual palettes, ThemeMode setting, 3-bucket Dimens, theme-aware spans).

## Detailed spec
# RemoveADS branch — UI Redesign, Settings & Dark Theme (delta vs master / flutter_app port-spec ui-resources.md)

Branch intent (commit messages): remove ads entirely, full UI redesign ("The vertical layout is ready", "COOL Responsive UI!", "buttons fit to narrow screens"), add Settings screen with theme switching (System/Light/Dark via DayNight), add a "Support the app" (buy cups) screen replacing the Remove-Ads FAB menu, theme-aware colors everywhere.

Everything below is expressed as a DELTA against the master behavior documented in `flutter_app/docs/port-spec/ui-resources.md`.

---

## 0. Removed wholesale (vs master spec sections 6–7, 10–11)

- **AdMob banner (`adView`) is gone** from every layout; AdMob `APPLICATION_ID` and Facebook SDK meta-data removed from AndroidManifest (`ACCESS_NETWORK_STATE` permission added; `banner_ad_unit_id`/`facebook_app_id` strings remain but are dead).
- **The entire FAB speed-dial menu is gone**: `fab`, `rateApp`, `feedback`, `removeads` mini-FABs, label pills `tvRateApp`/`tvFeedback`/`tvRemoveAds`, `dimmed_background` include, `rounded_corner` pill drawable usage, icons `ic_menu_white_24dp`/`ic_close_white_24dp` usage, and all `fabInitalize()/showIn/showOut` code. Replaced by a 4-icon action row (portrait) / right icon column (landscape) — see §2.
- **The Formats/Per outlined MaterialButtons (#304FFE stroke) are gone.** `buttonFormats` and `buttonPer` are now borderless `ImageButton`s with vector icons; the currently selected format is displayed in a new plain TextView `tvFormats` (see §2).
- **The 13 `values-sw###dp` dimens buckets are gone** (sw300, 320, 340, 360, 380, 400, 420, 440, 460, 480, 500, 800 all deleted). New system: `values/` (portrait-phone base) + NEW `values-land/` + rewritten `values-sw600dp/`. See §1.
- `minSdkVersion` 19→21 for all flavors (free versionCode 20, versionName "2.0.5"). Material lib 1.4.0-alpha01 (needed for `Theme.MaterialComponents.DayNight...Bridge`).

---

## 1. New responsive dimens system (verbatim)

Resolution rule (Android): tablets (`sw >= 600dp`) always use the **sw600** table and the **sw600 layouts** in BOTH orientations (sw qualifier beats orientation). Phones use `values/` + `layout/` in portrait and `values-land/` + `layout-land/` in landscape. No more continuous `sw/320` scaling — three fixed buckets.

| dimen | values/ (base, phone portrait) | values-land/ (phone landscape) | values-sw600dp/ (tablet) | master base (for delta) |
|---|---|---|---|---|
| buttons_num_size | **36sp** | 30sp | 36sp | 18sp |
| buttons_num_min_width (NEW) | **38sp** | 38sp | 48sp | — (was hardcoded 45dp minWidth on operators) |
| buttons_time_size | **24sp** | 20sp | 24sp | 16sp |
| buttons_operators_size | **34sp** | 30sp | 34sp | 20sp |
| margin_16_size | 16dp | 10dp | 16dp | 16dp |
| margin_8_size | 8dp | 6dp | 8dp | 8dp |
| result_output_height | 60dp | 60dp | 60dp | 60dp |
| result_output_mintextsize | 16sp | **10sp** | 16sp | 16sp |
| result_output_maxtextsize | 50sp | 50sp | 50sp | 50sp |
| result_expression_mintextsize | 24sp | **14sp** | 24sp | 24sp |
| result_expression_maxtextsize | 64sp | 64sp | 64sp | 64sp |
| fab_margin (dead — no FAB) | 8dp | 8dp | 8dp | 8dp |
| separator_time_text_size (NEW) | **18sp** | 14sp | 18sp | — |
| padding_buttons (NEW, digit keys v-padding) | **6dp** | 6dp | 6dp | — (was 10dp literal) |
| padding_buttons_time (NEW, time keys v-padding) | **12dp** | 7dp | 14dp | — (was 5dp literal) |
| padding_buttons_action (NEW, action icons v-padding) | **5dp** | 3dp | 6dp | — |
| settings_group_text_size (NEW) | **18sp** | 14sp | 18sp | — |
| settings_item_text_size (NEW) | **20sp** | 16sp | 20sp | — |
| settings_item_min_height (NEW) | **50dp** | 44dp | 50dp | — |

"Buttons fit to narrow screens" mechanics: portrait keys carry **no minWidth at all** (wrap_content in spread chains, width driven by text), and the old hardcoded `minWidth=45dp` on operators is replaced in land/sw600 by `@dimen/buttons_num_min_width` (38sp/48sp). All keys keep `minHeight=30dp` and style `Widget.AppCompat.Button.ButtonBar.AlertDialog` + `?selectableItemBackgroundBorderless` + `@font/googlesans_regular`.

Result-line autosize granularity changed: `tvOnlineResult` is now step **2sp** (master: 1sp). Expression stays 2sp.

---

## 2. Main screen — PORTRAIT (`layout/activity_main.xml`, full new tree)

Root `commonConstraintLayout` (match×match) contains:
1. `mainConstraintLayout` — match×match (no longer constrained above an ad), background **`@color/colorMainBackground`** (was `@android:color/background_light`), keeps `descendantFocusability=beforeDescendants` + `focusableInTouchMode`.
2. Includes, all 0dp×0dp covering `mainConstraintLayout`, visibility GONE: `formatsLayout` (view_formats), `perLayout` (view_per), **NEW `support_appLayout` (view_support_app)**, **NEW `settingsLayout` (view_settings)**.

Inside `mainConstraintLayout`, top→bottom:
- **tvExpressionField** — 0dp×0dp, parent top → top of `tvFormats`, marginBottom 8dp; gravity `bottom|end`; padding start 8 / top 4 / end 8 / bottom 4 (master: 16/8 margins); textColor **`@color/colorExpressionNums`** (master hardcoded #272727); autosize uniform `result_expression_mintextsize`–`maxtextsize` step 2sp; `ellipsize=marquee`, vertical scrollbars (`scrollbarAlwaysDrawVerticalTrack`), `textIsSelectable`.
- **tvFormats (NEW TextView)** — wrap×wrap, start→parent +8dp marginStart, bottom→top of `tvOnlineResult`; default text `Hour Minute`; textAllCaps=false; textSize `@dimen/separator_time_text_size`; textColor `@color/colorControls`. This is the read-only label that shows the currently selected result format (replaces the old `buttonFormats` MaterialButton text). It has **no click handler**.
- **tvOnlineResult** — 0dp wide × `result_output_height`, bottom→top of `buttonSettings`, marginBottom 8dp; **no background** (was white), **no textColor in portrait** (all content arrives pre-colored via spans); gravity `center_vertical|end`; padding start 8 / end 8 / bottom 4; bold; autosize 16–50sp step **2sp**; `app:elevation="-100dp"` (z-order hack to keep it under the action row ripple).
- **Action icon row (NEW)** — five ImageButtons, each bottom→top of `tvSpaceWithShadowOnly`, style/ripple/font as keys, `paddingTop/Bottom=@dimen/padding_buttons_action`, `scaleType=center`, textSize `buttons_operators_size` (dead attr):
  - `buttonFormats` — src `ic_convert_24`, contentDescription "Formats", column-aligned to `buttonNum7` (col 1).
  - `buttonPer` — src `ic_per`, contentDescription "Per", chained between Formats and Food.
  - `buttonFood` (NEW, opens Support screen) — src `ic_food_checked` (cup with red badge; swapped at runtime, §7), contentDescription "Tea", chained between Per and Settings.
  - `buttonSettings` (NEW) — src `ic_settings`, contentDescription "Settings", column-aligned to `buttonNum9` (col 3), `app:elevation="100dp"`.
  - `buttonDelete` — ImageButton, src `ic_backspace_black_24dp` (now 24×24dp, fill `@color/colorOperators` blue — was 16dp black), contentDescription "Delete", column-aligned to `buttonDivide` (col 4), top/bottom aligned to `buttonSettings`, paddingTop/Bottom 5dp.
- **tvSpaceWithShadowOnly** — 0dp×wrap, textSize 0sp, background `@drawable/text_view_shadow`, bottom→**top of `buttonNum9`** (sits BETWEEN the action row and the keypad; in master it sat under the result). The drawable's solid-white background layer was removed (now transparent), so it works on any background; a `drawable-night` variant uses #222222 stripes (§5).
- **tvFakeForClear** — 0dp×0dp, GONE; covers tvExpressionField-top → top of shadow; background now **`@color/colorResultTime`** (green; master: holo_blue_dark).

### Portrait keypad grid — 4 columns × 6 rows (was 4 cols with side operator chain)
All wrap×wrap, bottom row is a horizontal chain across parent (Hour start→parent, Msec end→parent), `marginBottom=@dimen/margin_16_size` on the bottom row only; every higher key start/end-aligned to the key below; `.`/`=`/`–` baseline-aligned to `0`'s row; `÷ × +` baseline-aligned to `9 6 3`.

```
row A (action):  Formats  Per  Food  Settings | Delete(col4)
row B:           7        8        9        ÷
row C:           4        5        6        ×
row D:           1        2        3        +
row E:           0        .        =        –
row F:           Year     Month    Week     Day
row G:           Hour     Minute   Second   Msec
```

Deltas vs master grid: the operator column is now a normal 4-row column (`÷ × + –`, one per digit row, `–` on the `0 . =` row) instead of a 5-key spread_inside chain; Delete moved up into the action row; the time-unit rows sit at the BOTTOM under the digits (master had them at the bottom too, but `Day` column was under the operators — now `– / Day / Msec` share col 4). Digit keys: padding `@dimen/padding_buttons`, color `colorNums`, size `buttons_num_size`. Time keys: padding `@dimen/padding_buttons_time`, color `colorTimeBtns`, size `buttons_time_size`, textAllCaps=false. Operators `÷ × –` textColor `@android:color/holo_blue_dark`, `+` uses `@color/colorOperators` (same value). `=` and `.` colored `colorNums`.

---

## 3. Main screen — LANDSCAPE (`layout-land/activity_main.xml`) and TABLET (`layout-sw600dp/activity_main.xml`)

**The two files are byte-identical** (sw600dp/activity_main.xml is NEW; tablets get this layout in both orientations). Same display stack as portrait (tvExpressionField → tvFormats → tvOnlineResult → shadow above `buttonNum9`), except `tvOnlineResult` here has `android:textColor=@android:color/black` and no marginBottom, and `tvFormats` is identical. New 7-column × 4-row grid (replaces master's 7-col layout):

```
col1 col2 col3 col4  col5     col6     col7 (icon column)
7    8    9    ÷     Hour     Minute   ⌫ (Delete)
4    5    6    ×     Second   Msec     Formats
1    2    3    +     Day      Week     Per
0    .    =    –     Month    Year     Food
                                       Settings
```

- Bottom row is the anchor chain: `0` (start→parent, marginStart `margin_8_size`, marginBottom `margin_16_size`, bottom→parent) → `.` → `=` → `–` (baseline=`=`) → `Month` (baseline=`–`) → `Year` (baseline=`Month`) → `buttonSettings` (end→parent, marginEnd `margin_8_size`).
- Column verticals: digits stack 7→4→1→0 etc.; operators ÷(baseline=9) → ×(baseline=6) → +(baseline=3) → – ; time col 5: Hour(baseline=÷) → Second → Day → Month; time col 6: Minute(baseline=Hour) → Msec → Week → Year. NOTE the unit order per row pairs: Hour|Minute, Second|Msec, Day|Week, Month|Year (top→bottom) — different from master landscape (Year/Month on top).
- Icon column 7 (all ImageButtons, padding `padding_buttons_action`, minWidth `buttons_num_min_width`): `buttonDelete` (top/bottom aligned to `buttonMinute` row, start/end aligned to `buttonFormats`) → `buttonFormats` → `buttonPer` → `buttonFood` → `buttonSettings` (aligned to `buttonYear` row), vertically chained between Delete and Settings.
- Every key in land/sw600 has `android:minWidth=@dimen/buttons_num_min_width`; "Hour " trailing-space bug from master is fixed (text is `Hour`); `+` uses `@string/button_addition` (master landscape hardcoded "+").

---

## 4. Settings screen — NEW (`layout/view_settings.xml`, single file for all configs)

Full-screen overlay include (`settingsLayout`), revealed/hidden with the same circular-reveal as Formats/Per (open: 600ms from buttonSettings center; close: 450ms collapsing to (10,10); AccelerateDecelerateInterpolator). Root ConstraintLayout, background `@color/colorSecondaryBackgroundForSupport`.

Widget tree:
- `toolbarSettings` (androidx Toolbar) — 0dp×wrap, background `colorSecondaryBackgroundForSupport`, minHeight `?actionBarSize`, theme `@style/ToolbarTheme`, `navigationIcon=?homeAsUpIndicator`, **title "Settings"** (hardcoded), titleMargin 4dp. Nav click → `closeSettingsLayout(10,10)`.
- ScrollView (0dp×0dp below toolbar → parent bottom) containing a wrap×wrap ConstraintLayout with:
  - `tvTheme` group header — text **"THEME"**, background `colorMainBackground`, font googlesans_regular, gravity bottom, minHeight `settings_item_min_height`, paddingStart 16dp / top 8 / bottom 8, textColor `colorExpressionNums`, textSize `settings_group_text_size`.
  - divider (`?android:attr/listDivider`).
  - `rgTheme` RadioGroup (paddingStart 30dp, paddingRight 30dp, marginTop 1dp) with three RadioButtons (each: match_parent width, background `colorSecondaryBackground`, font googlesans_regular, minHeight `settings_item_min_height`, paddingStart 16dp, textColor `colorResultNums`, textSize `settings_item_text_size`, `android:onClick="onRadioButtonClicked"`), separated by 1dp listDivider views:
    - `rbTheme_SystemDefault` — text **"System default"** — XML default `checked=true` — writes pref value **"0"**.
    - `rbTheme_Light` — text **"Light"** — writes **"1"**.
    - `rbTheme_Dark` — text **"Dark"** — writes **"2"**.
  - divider.
  - `tvFeedbackG` group header — text **"FEEDBACK"** (same styling as THEME header).
  - divider.
  - `buttonFeedback_Sendfeedback` Button (style `Widget.AppCompat.Button.ButtonBar.AlertDialog`) — text **"Send Feedback"**, textAllCaps=false, textAlignment viewStart, paddingStart 35dp, minHeight `settings_item_min_height`, textColor `colorResultNums`, textSize `settings_item_text_size`.
  - divider.

### Persistence & behavior
- `PrefRepository` (NEW singleton): SharedPreferences file **"MY_APP_PREF"**, key **"PREF_THEME_COLOR"**, stores `"0" | "1" | "2"` as String; on first run (blank) writes "0". Exposes `MutableLiveData<String>`; `setPrefThemeColor` uses `postValue` + synchronous `commit()`.
- The activity observes `viewModel.getPrefThemeColor()`; on each value:
  - "0" → `AppCompatDelegate.setDefaultNightMode(MODE_NIGHT_FOLLOW_SYSTEM)`; check `rbTheme_SystemDefault` if not checked.
  - "1" → `MODE_NIGHT_NO`; check `rbTheme_Light`.
  - "2" → `MODE_NIGHT_YES`; check `rbTheme_Dark`.
  - anything else → same as "0".
  Effect is IMMEDIATE: DayNight recreates the activity; all UI state (open overlay, expression, result, formats) survives because it lives in singleton repositories/ViewModel (`UtilityRepository` keeps `isInFormatsChooseMode/isInPerViewMode/isInSupportAppViewMode/isInSettingsViewMode`, the per/formats button-disabled flags, and `tempResultInMsec` as LiveData; the activity re-applies overlay visibility from these on every create — that is commit 994973d "All states of app saves now without issues").
- "Send Feedback" → `ACTION_SENDTO` `mailto:`, EXTRA_EMAIL `support@cardamon.org`, EXTRA_SUBJECT `"Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}"`; logs Firebase event `button_feedback`. (Note: feedback address changed from master's dmitrii.kargashin@cardamon.org used in flutter config.dart to **support@cardamon.org**.)
- Back button priority (new `onBackPressed`): formats open → close formats; else per open → close per; else support open → close support; else settings open → close settings; else `moveTaskToBack(true)`.

---

## 5. Dark theme

### Theme/styles
- `values/styles.xml`: `AppTheme` parent changed `Theme.MaterialComponents.Light.NoActionBar.Bridge` → **`Theme.MaterialComponents.DayNight.NoActionBar.Bridge`**; adds `android:statusBarColor=@color/colorSecondaryBackground`. `ToolbarTheme` parent changed `ThemeOverlay.AppCompat.Light` → `Theme.MaterialComponents.DayNight.NoActionBar.Bridge`, keeps `android:fontFamily=@font/googlesans_regular`, `colorPrimary=#9AFDD835`, and adds `android:textColor=#9AFDD835` (leftover yellow, see bugs).
- NEW `values-v23/styles.xml`: same `AppTheme` (DayNight Bridge, colorPrimary/colorPrimaryDark/colorAccent, statusBarColor=colorSecondaryBackground) plus **`android:windowLightStatusBar=?attr/isLightTheme`** (dark status icons in light theme on API 23+).
- Application: DayNight + `AppCompatDelegate.setDefaultNightMode` (per §4). Default = follow system. Manual override persisted.

### Colors — values/colors.xml (light) vs NEW values-night/colors.xml (dark), verbatim resolved table

| name | LIGHT | DARK (values-night) | master light (delta) |
|---|---|---|---|
| colorPrimary | #008577 | #008577 | unchanged |
| colorPrimaryDark | `@color/colorMainBackground` | `@color/colorMainBackground` | was #00574B |
| colorAccent | `@android:color/holo_blue_dark` (#FF0099CC) | same | was #D81B60 |
| colorNums | #2E2D2D | #777777 | was black |
| colorOperators | holo_blue_dark | holo_blue_dark | unchanged |
| colorTimeBtns | #33691E | **#53654D** | unchanged light |
| colorMainBackground (NEW) | **#FDFCFA** | **#0E0E0E** | — |
| colorSecondaryBackground | **#E8E8E8** | **#131313** | was #9AFDD835 translucent yellow |
| colorSecondaryBackgroundForPer | **#E8E8E8** | **#131313** | was #66BB6A green |
| colorSecondaryBackgroundForSupport (NEW) | #E8E8E8 | #131313 | — |
| semitransparentBackground | #CCCACACA | #CCCACACA | unchanged (dead, no scrim) |
| colorControls (NEW) | **#CC474646** | **#CCCCCC** | — |
| colorExpressionTime (NEW) | →colorTimeBtns | →colorTimeBtns | — |
| colorExpressionNums (NEW) | →colorNums | →colorNums | — |
| colorResultTime (NEW) | **#567749** | **#727C6E** | — |
| colorResultNums (NEW) | →colorControls (#CC474646) | **#939292** | — |

So the whole palette is neutral now: light = warm-white background (#FDFCFA) with grey panels (#E8E8E8); dark = near-black (#0E0E0E) with #131313 panels. The yellow Formats panel and green Per panel from master no longer exist.

### Theme-aware span colors (code)
Extension functions now resolve resource colors instead of hardcoded hex (needed so spans flip with the theme):
- `String.toHTMLWithGreenColor(context)` → `colorExpressionTime` at 0.7× size (was #33691e).
- `String.toHTMLWithLightGreenColor(context)` → `colorResultTime` (was #4c992e).
- `String.toHTMLWithGrayColor(context)` → `colorResultNums`, no size change (was #807e7e at full size).
- NEW `String.toHTMLBlackColor()` → hardcoded #000000 at 0.7× (unused in final wiring).
- `Tokens.toSpannableString(context)` / `Tokens.toLightSpannableString(context)` now take a Context and pass it through. `RvAdapterResultFormats` gains a `context` constructor param for the same reason; `RvAdapterPer` colors the time-unit span with `colorExpressionTime` and the unit-name span with `colorResultTime` via `ContextCompat.getColor`.

### Shadow drawables
- `drawable/text_view_shadow.xml`: the final background layer's `<solid android:color="@android:color/white"/>` removed (background layer now empty/transparent); grey stripes unchanged: bottom-up 1dp layers #00CCCCCC, #10CCCCCC, #20CCCCCC, #30CCCCCC, #50CCCCCC, #00CCCCCC.
- NEW `drawable-night/text_view_shadow.xml`: identical structure with #222222 stripes: **#00222222, #10222222, #20222222, #00222222, #50222222, #00222222** (note the 4th layer is 00 where light has 30 — looks like a typo) + empty background layer.

### New vector icons (all fill `@color/colorControls` unless noted → auto theme-adapt)
- `ic_convert_24` (30×30dp, two opposing arrows — Formats), `ic_per` (30×30dp, clock + plus — Per), `ic_settings` (30×30dp, gear), `ic_food` (30×30dp, beer-mug/cup), `ic_food_checked` (same cup + **#FF0000 red dot badge** top-right), `ic_star_blue_24dp` (24dp star, fill `@color/colorAccent`), `ic_baseline_share_24` (24dp share glyph, fill `@color/colorAccent`, alpha 0.8). `ic_backspace_black_24dp` resized 16→24dp and recolored #FF000000 → `@color/colorOperators`. `radio_buttons_supportview.xml` — selector mapping checked/unchecked both to `ic_food` (unused leftover).

---

## 6. Formats & Per overlays + cards (delta)

### view_formats.xml
- Toolbar title changed: "Choose a result format" → **"Choose the result format"**.
- Toolbar background now explicit `@color/colorSecondaryBackground` (grey/dark-grey) instead of `?attr/colorPrimary` (yellow). Root background still `@android:color/background_light` (hard white — not night-adapted, mostly hidden by the panel).
- `scrollView2` colored panel unchanged structurally (now #E8E8E8/#131313). `rvFormatsToChoose` lost its 8dp bottom margin (keeps start/end 8dp).
- The formats list itself gained entries (data-layer change, affects this screen): "Year Month Day Minute" replaced by **"Year Month Day Hour"** (preview "1 Year 2 Month 3 Day 4 Hour") and NEW **"Year Month Day Hour Minute"** (preview "1 Year 2 Month 3 Day 4 Hour 5 Minute").

### card_view_formats.xml / card_view_per.xml (both)
- `layout_margin` 3dp → **8dp**; NEW `app:cardCornerRadius="20dp"`; cardElevation 2dp / maxElevation 3dp / contentPadding `margin_8_size` kept; inner ConstraintLayout gains padding start 10dp / top 4dp / end 4dp.
- Formats card: `tvFormat` textSize 36sp → `@dimen/buttons_num_size` (36sp base, 30sp land — now responsive); `tvResultFormat` lost its 0.2 horizontal bias; keeps marginBottom `margin_8_size`, padding start/end `margin_16_size`, 24sp.
- Per card: `tvFormat` textSize 24sp → `@dimen/buttons_time_size`, NEW explicit `textColor=@color/colorExpressionNums`; `tvResultFormat` NEW explicit `textColor=@color/colorResultNums`, keeps bias 0.2, padding `margin_16_size`, 24sp.

### view_per.xml (base/portrait — restructured)
- Background `colorSecondaryBackgroundForPer` (now grey/near-black, not green). Toolbar unchanged except color; title still "Amount for the time interval".
- The "Time interval:" label + bold 24sp interval value (`labelTimeIntervalAmount`, default "10 Hour 25 Minute 5 Second") are now wrapped in a **HorizontalScrollView** (`horizontalScrollView` > ConstraintLayout `clInner`), below the toolbar, so long intervals scroll horizontally. Label marginStart 16dp (was 8dp).
- `labelTimeInterval2` "Value:" — below the HorizontalScrollView, marginStart 16dp, marginTop 8dp. `etUnitAmount` below it, start-aligned (no extra indent; master indented +8dp), `inputType=numberDecimal`, ems 3, default "25", 24sp, paddingTop 0 / bottom 4, includeFontPadding=false.
- `labelTimeInterval3` "Value unit:" — start→end of etUnitAmount +16dp. `etUnit` below it: **ems 5 → 3**, default "USD", `inputType=text`, same paddings.
- The empty colored `ScrollView` panel was REMOVED from this layout; `rvPer` now constrains directly from below `etUnitAmount` to parent bottom, margins start/end 8dp.

### NEW layout-land/view_per.xml == layout-sw600dp/view_per.xml (identical files)
Landscape/tablet Per puts ALL header content in one horizontal row inside a HorizontalScrollView (`svForLabels`, scrollbars=horizontal) below the toolbar: `Time interval:` over the bold interval value, then (marginStart 32dp, paddingStart 2dp) `Value:` over `etUnitAmount`, then (+16dp) `Value unit:` over `etUnit` (both ems 3). `rvPer` fills from below `svForLabels` to parent bottom (8dp side margins).

### Reveal/close animations & misc behavior (unchanged math, new targets)
Formats/Per/Support/Settings all use identical circular reveal: open from the pressed button's screen-center, radius 0 → hypot(rootW, rootH), 600ms; close collapsing to (10,10), 450ms; AccelerateDecelerateInterpolator; visibility flag mirrored into UtilityRepository LiveData so it persists across recreation. Long-press Delete clear-flash: reveal `tvFakeForClear` (now green `colorResultTime`) from delete-button x / result-bottom y, radius → hypot(exprW, exprH+resultH), 400ms, then GONE + `clearAll()`. Per/Formats buttons disabled state: alpha **0.2** (master Per used 0.5) + not clickable; NEW — the Formats button is also disabled when the result is empty (master only disabled Per). Firebase events on clicks: `button_formats`, `button_per`, `button_support`, `button_long_delete`, `button_feedback`, `button_support_rate`, `button_share_the_app`, `button_support_{1,3,5,9}` (Settings button logs nothing).

---

## 7. Support screen — NEW (`layout/view_support_app.xml`) (adjacent scope, summarized)

Full-screen overlay (`support_appLayout`) opened by `buttonFood`, background `colorSecondaryBackgroundForSupport`. Toolbar title **"The app development support"** (same ToolbarTheme/nav-icon pattern). ScrollView (marginTop `margin_16_size`) containing: `labelSupport` TextView = `@string/support_app_text`, centered, textSize `settings_group_text_size`, lineSpacingExtra 4sp, side margins `margin_16_size`; then five 200dp-wide default-styled Buttons centered (first marginTop 32dp, rest 16dp): `btnSupport1` "buy 1 Cup" / `btnSupport3` "buy 3 Cups" / `btnSupport5` "buy 5 Cups" / `btnSupport9` "buy 9 Cups" (each `drawableLeft=@drawable/ic_food`), `btnSupportRate` "Leave a review" (`ic_star_blue_24dp`), `btnShareTheApp` "Share the app" (`ic_baseline_share_24`), plus a 32dp Space. Hidden `ic_star_green_24dp` ImageViews (`imageStar1/3/5/9`) to the right of each buy button become VISIBLE when that SKU is owned (button then disabled, alpha 0.5; legacy `remove_ads` purchase maps to the 3-cups star). `buttonFood` main-screen icon: any purchase owned → `ic_food` (no badge), none → `ic_food_checked` (red badge). "Leave a review" shows the in-app rating dialog immediately; "Share the app" fires ACTION_SEND text/plain with verbatim text: `"😍 The Best Time Calculator.\n  ✅ Work Hours\n  ✅ Allows you to select different time formats for the result\n  ✅ Convert any Time Units\n  ✅ Calculates Salary, Distance, etc\n\n🔥 Please, try it: https://bit.ly/TimeCalcCardamon"`.

---

## 8. New/changed strings (verbatim)

values/strings.xml additions:
- `never_show_ratetheapp` = `NEVER`
- `rate_main_text` = `How was your experience with the Time Calculator?`
- `rate_second_text` = `The app is absolutely free.\nYou can contribute to the development of the app by writing a review!`
- `rate_store_second_text` = `If you enjoy using this app, would you mind taking a moment to rate it in the store?\n\nYour review will help this app develop further.`
- `rate_feedback_main_text` = `I want to improve the App with your help. Don\'t hesitate to send an email with your suggestions.\n\nSend an email?`
- `support_app_text` = `For your best user experience, the application is now free and ad-free.\n If you would like to support me, as a developer of the app, you can buy me some CUPS of TEA.\nAny purchase will give you a green star to the right of the corresponding button\n\nYou can also leave a review or share to help improve the app.`

New hardcoded layout strings: `Settings` (toolbar), `THEME`, `System default`, `Light`, `Dark`, `FEEDBACK`, `Send Feedback` (settings button), `Choose the result format` (changed), `The app development support`, `buy 1 Cup`, `buy 3 Cups`, `buy 5 Cups`, `buy 9 Cups`, `Leave a review`, `Share the app`, `Hour Minute` (tvFormats default), contentDescriptions `Formats` / `Per` / `Tea` / `Settings` / `Delete`. Code strings: Snackbar `Purchase is pending. Please wait`; feedback email `support@cardamon.org`; subjects `Feedback Time Calculator Cardamon v.${VERSION_CODE}` (rating-dialog mail) and `Feedback Time Calculator Cardamon ${VERSION_CODE}` (settings mail — note no "v."). Rating dialog (awesome-app-rating 2.3.0) config: minLaunchTimes 5, minDays 7, minLaunchTimesToShowAgain 5, minDaysToShowAgain 10, threshold FOUR, only-full-stars, NEVER button appears after 3 prompts; shown on cold start only (savedInstanceState == null).

## Suspected bugs
- drawable-night/text_view_shadow.xml: stripe sequence is #00/#10/#20/#00/#50/#00 222222 — the 4th layer should almost certainly be #30222222 (light variant is 00/10/20/30/50/00 CCCCCC); the dark shadow gradient has a transparent hole in it.
- values/styles.xml ToolbarTheme sets android:textColor=#9AFDD835 (translucent yellow) and colorPrimary=#9AFDD835 — leftovers from the old yellow design applied to every overlay toolbar; any text resolving through android:textColor renders translucent yellow on grey. Do not port these literals.
- layout-land/sw600 activity_main tvOnlineResult hardcodes android:textColor=@android:color/black while portrait omits it — any unspanned result text (e.g. plain segments) is black-on-#0E0E0E in dark landscape.
- view_formats.xml root background is still @android:color/background_light (hard white), not theme-aware; only hidden because the colorSecondaryBackground ScrollView panel covers it.
- view_settings.xml: the ScrollView's inner ConstraintLayout is wrap_content wide while headers/dividers are width 0dp matched to it — the settings list width is dictated by the RadioGroup (widest child) and does not span the full screen on wide displays; group-header backgrounds stop short of the right edge.
- Settings RadioGroup mixes paddingStart=30dp with paddingRight=30dp (start/right inconsistency — breaks under RTL).
- CalculatorActivity.onResume() calls checkPurchases() unconditionally, but billingClient is only initialized when !isPaidVersion() — lateinit crash on the pro flavor; also on free, onResume can run before billing connection is ready, so queryPurchases returns empty and buttonFood incorrectly shows the red-badge ic_food_checked.
- initUI() calls toolbarInitalize() twice, and setSupportActionBar() is called three times in a row (support/per/formats toolbars) while toolbarSettings is never set — only the last call wins; harmless but confused wiring.
- tvFormats (the selected-format label) has no click handler — only the small ic_convert_24 icon opens the Formats screen; the old design let you tap the format text itself.
- Portrait buttonSubstraction declares both layout_constraintBaseline_toBaselineOf=buttonEqual and layout_constraintTop_toBottomOf=buttonAddition (conflicting constraints; baseline wins). Portrait buttonNum2 still carries the editor artifact bias 0.521 (now on its alignment to buttonComma).
- Dead resources kept: fab_margin dimens (no FAB exists), strings settings/removeads/ratetheapp/remove_ads/rate_the_app/new_rate_dialog_message/banner_ad_unit_id/facebook_app_id, semitransparentBackground color (no scrim), radio_buttons_supportview.xml selector (unused, and both states map to the same drawable), android:text attributes on ImageButtons (Del/Food/Formats/Per/Settings).
- Feedback subject strings diverge: rating-dialog mail uses 'Feedback Time Calculator Cardamon v.<code>' but the Settings Send-Feedback intent uses 'Feedback Time Calculator Cardamon <code>' (no 'v.'); both now target support@cardamon.org while flutter_app config.dart still has dmitrii.kargashin@cardamon.org.
- PrefRepository keeps a single SharedPreferences.Editor instance and uses commit() (synchronous, main thread) instead of apply(); theme value is a magic string '0'/'1'/'2'.
- buttonFood contentDescription is 'Tea' while the icon is a beer-mug glyph and the support copy says 'CUPS of TEA' — accessibility label mismatch is intentional-ish but odd; ic_food_checked's red dot looks like a notification badge and is shown precisely when the user has NOT purchased (nag pattern).
- skuList still contains 'remove_ads' and handlePurchase maps an owned remove_ads to the support_3 star/disabled state — legacy purchase silently rebranded as '3 cups'.

## Flutter porting notes
- lib/ui/theme.dart — biggest rework. (1) Replace the single AppColors set with a light/dark pair keyed by the new role names: mainBackground #FDFCFA/#0E0E0E, secondaryBackground (status bar + formats panel + settings rows) #E8E8E8/#131313, perPanel and supportPanel = same values (no more yellow/green), nums #2E2D2D/#777777, timeBtns #33691E/#53654D, controls #CC474646/#CCCCCC, resultTime #567749/#727C6E, resultNums = controls in light but #939292 in dark, expressionNums→nums, expressionTime→timeBtns, accent = 0xFF0099CC. (2) Delete the continuous shortestSide/320 Dimens scaling and the fabMargin step function; replace with a 3-bucket lookup: base (phone portrait), land (phone landscape), sw600 (shortestSide>=600, BOTH orientations) using the verbatim tables in §1 (buttons_num 36/30/36sp, time 24/20/24, operators 34/30/34, new paddings 6 / 12-7-14 / 5-3-6, settings sizes 18-14, 20-16, 50-44, separator 18/14, min key width 38/38/48). (3) buildAppTheme → build light+dark ThemeData; MaterialApp gets darkTheme + themeMode from a settings controller (ThemeMode.system default).
- lib/main.dart — add themeMode plumbing: load persisted value before runApp (shared_preferences, file-equivalent key 'PREF_THEME_COLOR' values '0'/'1'/'2' or just store a ThemeMode enum), expose as ValueNotifier/ChangeNotifier consumed by MaterialApp.
- lib/ui/calculator_screen.dart — STRUCTURAL rebuild, not retheme: remove FabMenu and AdBannerSlot entirely; display column becomes Expression (autosize, scrollable, colorExpressionNums) → tvFormats label (selected format text, separator_time_text_size, colorControls, NOT tappable per Android — consider keeping it tappable as an improvement) → result line (60dp, autosize step 2) → portrait action icon row [convert, per, food, settings, backspace] → shadow strip → keypad. Wire two new overlays (settings, support) into the existing circular_reveal.dart mechanism (open 600ms from button center, close 450ms to top-left, same as formats/per). onWillPop/back priority: formats > per > support > settings > background app. Formats button now also gets the disabled/alpha-0.2 treatment (alpha changed from 0.5 to 0.2 for Per too).
- lib/ui/widgets/keypad.dart — rewrite both grids. Portrait (4 cols × 6 rows + action row): cols = [7,4,1,0,Year,Hour],[8,5,2,'.',Month,Minute],[9,6,3,'=',Week,Second],[÷,×,+,–,Day,Msec]; digit v-padding = padding_buttons, time rows = padding_buttons_time, bottom row margin_16. Landscape/tablet (7 cols × 4 rows): [7,4,1,0],[8,5,2,.],[9,6,3,=],[÷,×,+,–],[Hour,Second,Day,Month],[Minute,Msec,Week,Year],[backspace,formats,per,food,settings icons]. Use the sw600 layout for tablets in BOTH orientations (shortestSide>=600 check before OrientationBuilder). All keys minWidth buttons_num_min_width in land/sw600, none in portrait.
- lib/ui/widgets/fab_menu.dart and lib/ui/widgets/ad_banner.dart — delete (FAB speed-dial and AdMob banner removed); also drop scrim color usage and google_mobile_ads dependency; remove banner ids from config.
- NEW lib/ui/settings_screen.dart — overlay screen per §4: toolbar 'Settings' (back arrow closes via reveal), 'THEME' group header (mainBackground bg) + 3 radio rows System default/Light/Dark (secondaryBackground bg, 1px dividers, settings_item_min_height) writing '0'/'1'/'2' and switching ThemeMode immediately; 'FEEDBACK' header + 'Send Feedback' row launching mailto:support@cardamon.org with subject 'Feedback Time Calculator Cardamon <versionCode>' (update lib/services/feedback_service.dart: address changed from dmitrii.kargashin@ to support@cardamon.org).
- NEW lib/ui/support_screen.dart — 'The app development support' overlay: support_app_text copy, 4 IAP cup buttons (200dp wide) + green star when owned (disabled, alpha 0.5), 'Leave a review' (opens rate dialog), 'Share the app' (share_plus with the verbatim emoji text + https://bit.ly/TimeCalcCardamon). Hook lib/services/monetization.dart to SKUs support_1/3/5/9 (+ legacy remove_ads → support_3) and drive the main-screen food icon (badge when nothing owned).
- lib/state/calculator_model.dart — add persisted-across-rebuild flags isSupportOpen and isSettingsOpen alongside the existing formats/per flags (Android keeps these in a singleton so they survive theme-change recreation — in Flutter they survive setState anyway, but they must survive a ThemeMode switch, which they will if the model is above MaterialApp); add isFormatsButtonDisabled mirroring isPerButtonDisabled; add themePref get/set delegating to shared_preferences.
- lib/ui/spans.dart — make span colors theme-dependent: green span → colorExpressionTime (expression) and the result/preview light-spannable uses colorResultNums (gray role) + colorResultTime (unit role); remove hardcoded 0xFF33691E/0xFF4C992E/0xFF807E7E constants in favor of Theme lookups (this is what the Kotlin Context-passing refactor did).
- lib/ui/formats_screen.dart — title 'Choose the result format' (the→a changed), toolbar+panel color secondaryBackground (grey, not yellow); cards: margin 8, cornerRadius 20, inner padding (10,4,4), title size = buttons_num_size dimen (responsive), drop the 0.2 bias on the preview line. Two formats list changes ripple in from the data layer ('Year Month Day Hour' and 'Year Month Day Hour Minute').
- lib/ui/per_screen.dart — neutral grey background (no green); portrait: interval label+value inside a horizontal SingleChildScrollView; 'Value:'/'Value unit:' fields below, etUnit width ems 5→3; list fills the rest (no colored sub-panel). Landscape/tablet: single horizontally-scrollable header row (Time interval | Value | Value unit). Per cards: title buttons_time_size + colorExpressionNums, preview colorResultNums.
- Shadow strip widget (wherever the text_view_shadow equivalent lives, likely calculator_screen.dart): remove the solid-white top layer; stripes #CCCCCC-based in light, #222222-based in dark (replicate alphas 00/10/20/30/50 — fix the Android night-variant 00-instead-of-30 typo deliberately); the strip now sits between the action row and the keypad, not under the result.
- Icons: backspace now operator-blue (colorOperators) instead of black; new icons map to Material: ic_convert_24≈Icons.sync_alt/compare_arrows, ic_per≈Icons.more_time (clock+plus), ic_settings=Icons.settings, ic_food≈Icons.sports_bar/emoji_food_beverage + a red Badge for the 'checked' state, share=Icons.share, star=Icons.star (accent blue). All tinted with the controls color so they theme-switch.
- Status bar: colorSecondaryBackground with windowLightStatusBar=isLightTheme → in Flutter use AnnotatedRegion/SystemUiOverlayStyle per theme (statusBarColor #E8E8E8 + dark icons in light; #131313 + light icons in dark).
- Docs: update flutter_app/docs/port-spec/ui-resources.md (this delta) — note especially that its sections 5 (13-bucket scaling), 6 (FAB menu, MaterialButton formats/per, ad), and the color table are obsolete on this branch.
