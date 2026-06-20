# ui-resources

## Summary
This area is the complete visual/resource layer of an Android time-interval calculator ("Time Calculator Cardamon"): a calculator screen with an expression field, a live result line, a "result format" picker button and a "Per" (amount-per-time) button, a 4-column keypad mixing digits, arithmetic operators and time-unit keys (Year/Month/Week/Day/Hour/Minute/Second/Msec), a FAB-based slide-out menu (settings/rate/feedback/remove-ads), an AdMob smart banner pinned at the bottom, and two full-screen overlays: a green-yellow "Choose a result format" card list and a green "Amount for the time interval" form with a card list. Sizing scales linearly across 13 smallest-width dimens buckets (base sw320, factor sw/320).

## Detailed spec
# Time Calculator — Visual Spec (res layer)

Source root: `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/res/`

---

## 1. Theme

`values/styles.xml`:
- `AppTheme` parent `Theme.MaterialComponents.Light.NoActionBar.Bridge`
  - `colorPrimary` = `@color/colorPrimary` (#008577)
  - `colorPrimaryDark` = `@color/colorPrimaryDark` (#00574B)
  - `colorAccent` = `@color/colorAccent` (#D81B60)
- `ToolbarTheme` parent `ThemeOverlay.AppCompat.Light`
  - `android:fontFamily` = `@font/googlesans_regular`
  - `colorPrimary` = `#9AFDD835` (semi-transparent yellow, alpha 0x9A) — this is what `?attr/colorPrimary` resolves to for the Formats toolbar background.

## 2. Colors (values/colors.xml, verbatim)

| name | value |
|---|---|
| colorPrimary | `#008577` |
| colorPrimaryDark | `#00574B` |
| colorAccent | `#D81B60` |
| colorNums | `@android:color/black` (#FF000000) |
| colorOperators | `@android:color/holo_blue_dark` (#FF0099CC) |
| colorTimeBtns | `#33691e` (dark green) |
| colorSecondaryBackground | `#9AFDD835` (translucent yellow) |
| colorSecondaryBackgroundForPer | `#66BB6A` (medium green) |
| semitransparentBackground | `#CCCACACA` (80%-alpha grey, dim layer) |

Android system colors used directly in layouts: `@android:color/background_light` (#FFFFFFFF), `@android:color/white` (#FFFFFFFF), `@android:color/black` (#FF000000), `@android:color/holo_blue_dark` (#FF0099CC). Hardcoded in layouts: `#304FFE` (Formats/Per button text+stroke, indigo A700), `#272727` (expression text), `#9AFDD835` (ToolbarTheme colorPrimary).

## 3. Strings (values/strings.xml, verbatim)

| name | value | usage |
|---|---|---|
| app_name | `Time Calculator Cardamon` | launcher label |
| button_multiply | `×` (U+00D7, `&#215;`) | keypad |
| button_divide | `÷` (U+00F7, `&#247;`) | keypad |
| button_substraction | `–` (U+2013 en-dash, `&#8211;`) | keypad |
| button_addition | `+` | keypad (portrait; landscape hardcodes literal `+`) |
| banner_ad_unit_id | `ca-app-pub-1503550792620709/2350324800` | AdMob |
| facebook_app_id | `2341977856105223` | FB SDK |
| settings | `Settings` | FAB contentDescription (menu item) |
| removeads | `Remove Ads` | FAB contentDescription (menu item) |
| ratetheapp | `Rate the App` | FAB contentDescription (menu item) |
| new_rate_dialog_message | `If you enjoy using this app, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!` | rate dialog body |
| send_feedback | `Send Feedback` | FAB menu label (tvFeedback) |
| remove_ads | `Remove Ads` | FAB menu label (tvRemoveAds) |
| rate_the_app | `Rate the App` | FAB menu label (tvRateApp) |
| feedback | `Send feedback` | FAB contentDescription (note lowercase f) |

Hardcoded user-facing strings in layouts (NOT in strings.xml): `Per`, `Hour Minute` (default format-button caption), `Year`, `Month`, `Week`, `Day`, `Hour` (landscape: `"Hour "` with trailing space), `Minute`, `Second`, `Msec`, digits `0`–`9`, `.`, `=`, `Delete` (contentDescription), `Del`/`Clear` (dead text attrs on ImageButton), toolbar titles `Choose a result format` and `Amount for the time interval`, labels `Time interval:`, `Value:`, `Value unit:`, defaults `25`, `USD`, placeholder `10 Hour 25 Minute 5 Second`, EditText contentDescriptions `Amount`, `Unit`. No error strings exist in resources (errors must live in code).

## 4. Font setup

- `font/googlesans_regular.ttf` — bundled TTF; this is the family every layout actually references (`android:fontFamily="@font/googlesans_regular"` on every Button/TextView and via ToolbarTheme).
- `font/abeezee.xml` — Downloadable Fonts definition: provider authority `com.google.android.gms.fonts`, package `com.google.android.gms`, query `ABeeZee`, certs `@array/com_google_android_gms_fonts_certs` (values/font_certs.xml). Preloaded via `values/preloaded_fonts.xml` array `preloaded_fonts` = `[@font/abeezee]`, but no layout references `@font/abeezee`. Practical Flutter take: ship one font family used app-wide; ABeeZee is available in google_fonts, Google Sans is not redistributable.

## 5. Dimens scaling strategy

Base bucket = `values/` and `values-sw320dp/` (identical except fab_margin). 13 buckets exist: sw300, sw320, sw340, sw360, sw380, sw400, sw420, sw440, sw460, sw480, sw500, sw600, sw800. Every value = base × (sw / 320), rounded/truncated to 1 decimal (e.g. sw360 num = 18×1.125 = 20.25 → 20.2sp; sw600 = 18×1.875 = 33.75 → 33.8sp; sw440 = 24.8; sw800 = 45 exactly).

Default `values/dimens.xml` (== sw320 sizes):
- buttons_num_size 18sp, buttons_time_size 16sp, buttons_operators_size 20sp
- margin_16_size 16dp, margin_8_size 8dp
- result_output_height 60dp, result_output_mintextsize 16sp, result_output_maxtextsize 50sp
- result_expression_mintextsize 24sp, result_expression_maxtextsize 64sp
- fab_margin 8dp

values-sw360dp: num 20.2sp, time 18sp, operators 22.5sp, margin16 18dp, margin8 9dp, output_height 67.5dp, output_min 18sp, output_max 56.2sp, expr_min 27sp, expr_max 72sp, fab_margin 4dp.

values-sw600dp: num 33.8sp, time 30sp, operators 37.5sp, margin16 30dp, margin8 15dp, output_height 112.5dp, output_min 30sp, output_max 93.7sp, expr_min 45sp, expr_max 120sp, fab_margin ABSENT (falls back to default 8dp).

fab_margin per bucket: 2dp (sw300/sw320/sw340), 4dp (sw360/sw380/sw400), absent sw420+ → default 8dp. Flutter equivalent: `scale = MediaQuery.size.shortestSide / 320` applied to the base table.

## 6. Main screen — PORTRAIT (`layout/activity_main.xml`)

Root: ConstraintLayout `commonConstraintLayout` (match_parent both).

### Vertical structure
1. `mainConstraintLayout` — width match_parent, height 0dp, constrained top→parent, bottom→top of `adView`; background `@android:color/background_light`; `descendantFocusability=beforeDescendants`, `focusableInTouchMode=true`.
2. `adView` (com.google.android.gms.ads.AdView) — wrap×wrap, bottom→parent, centered horizontally, `adSize=SMART_BANNER`, `adUnitId=@string/banner_ad_unit_id`.
3. `formatsLayout` (include `view_formats`, 0dp×0dp, visibility GONE) — top→parent, bottom→bottom of mainConstraintLayout, start/end→parent (covers everything except the ad).
4. `perLayout` (include `view_per`, same constraints, visibility GONE).

### Inside mainConstraintLayout (top→bottom)
- **tvExpressionField** (TextView): 0dp×0dp filling from parent top down to top of `buttonFormats`; vertical bias 1.0, horizontal bias 0.0. White bg, text `#272727`, gravity `bottom|end`, padding left/right `margin_16_size`, top `margin_8_size`, minHeight `result_expression_mintextsize`; autosize uniform min `result_expression_mintextsize` (24sp) max `result_expression_maxtextsize` (64sp) granularity 2sp; `ellipsize=marquee`, vertical scrollbars (`scrollbarStyle=outsideInset`, alwaysDrawVerticalTrack), `textIsSelectable=true`, fontFamily googlesans_regular.
- **Format buttons row** (both bottom→top of tvOnlineResult):
  - `buttonFormats` (MaterialButton, style `Widget.MaterialComponents.Button.TextButton`): start→parent +8dp marginStart, text `Hour Minute`, textAllCaps false, bold, color `#304FFE`, size `buttons_time_size`, cornerRadius 5dp, elevation 2dp, strokeColor `#304FFE`, strokeWidth 1dp, minWidth/minHeight 0dp, gravity start, background+foreground `?selectableItemBackgroundBorderless`, theme `Theme.MaterialComponents`.
  - `buttonPer` (MaterialButton, identical styling): end→parent with marginEnd 8dp (no start constraint), text `Per`.
- **tvOnlineResult** (TextView): 0dp wide (start/end→parent) × height `result_output_height` (60dp base), bottom→top of tvSpaceWithShadowOnly. White bg, black bold text, gravity `center_vertical|end`, padding left/end/right `margin_16_size`, autosize uniform 16–50sp granularity 1sp, singleLine=false, ellipsize none, vertical scrollbars, textIsSelectable.
- **tvSpaceWithShadowOnly** (TextView): 0dp×wrap, textSize 0sp, includeFontPadding=false, background `@drawable/text_view_shadow`, bottom→top of `buttonNum8`, start/end→parent. Acts as a ~6dp drop-shadow strip separating result area from keypad.
- **tvFakeForClear** (TextView): 0dp×0dp, holo_blue_dark bg, visibility GONE, overlays the expression field region (top/start/end = tvExpressionField, bottom→top of tvSpaceWithShadowOnly). Used for a clear-flash animation.

### Keypad grid (portrait) — 4 columns
All keypad keys are `Button` (Delete is `ImageButton`), style `Widget.AppCompat.Button.ButtonBar.AlertDialog` (borderless flat), background `?selectableItemBackgroundBorderless`, fontFamily googlesans_regular.

Column structure built from bottom-anchored vertical chains; bottom row `Hour|Minute|Second|Msec` is a horizontal chain across parent (Hour start→parent, Msec end→parent), each with `marginBottom=margin_16_size`. Every higher key is start/end-aligned to the key below it.

```
col1        col2        col3        col4
7           8           9           ⌫ (buttonDelete, icon)
4           5           6           ÷ (buttonDivide)
1           2           3           × (buttonMultiply)
0           .           =           + (buttonAddition)
                                    – (buttonSubstraction)
Year        Month       Week        Day
Hour        Minute      Second      Msec
```

- Digit/`.`/`=` keys: text size `buttons_num_size` (18sp base), color `colorNums` (black), minHeight 30dp, paddingTop/Bottom 10dp. Vertical stacks: 7→4→1→0→Year→Hour; 8→5→2(buttonComma above is `.`; chain is 8→5→2→`.`→Month→Minute); 9→6→3→`=`→Week→Second. `.` (`buttonComma`) baseline-aligned to `buttonNum0`; `=` (`buttonEqual`) baseline-aligned to `buttonComma`.
- Operator column (col4) is a separate vertical chain `spread_inside` from below tvSpaceWithShadowOnly to top of buttonDay: `buttonDelete` (ImageButton, src `ic_backspace_black_24dp`, scaleType center, minWidth 45dp, minHeight 30dp, padding v 5dp, horizontal bias 0.58, contentDescription `Delete`) → `buttonDivide` (`÷`) → `buttonMultiply` (`×`) → `buttonAddition` (`+`, textColor `@color/colorOperators`) → `buttonSubstraction` (`–`). Operators: height 0dp (stretch within chain), minWidth 45dp, minHeight 30dp, size `buttons_operators_size` (20sp base), color holo_blue_dark `#FF0099CC`.
- Time-unit keys (Year, Month, Week, Day, Hour, Minute, Second, Msec): textAllCaps=false, color `colorTimeBtns` `#33691e`, size `buttons_time_size` (16sp base), minHeight 30dp, paddingTop/Bottom 5dp.

### FAB menu (top-left, inside mainConstraintLayout)
- `fab`: mini FAB, top/start→parent with margins `fab_margin`, backgroundTint `colorTimeBtns` (#33691e), src `ic_menu_white_24dp` (white hamburger), elevation 6dp, tint @null, contentDescription `@string/settings`.
- Below it (each marginTop 8dp, start/end aligned to fab, white backgroundTint, elevation 4dp, mini, tint @null): `rateApp` (src `ic_star_green_24dp`, below fab) → `feedback` (src `ic_mail_green_24dp`, below rateApp) → `removeads` (src `ic_remove_ads_green_24dp`, below feedback).
- Labels to the right of each (marginStart 8dp, vertically centered on their FAB): `tvRateApp` (`Rate the App`), `tvFeedback` (`Send Feedback`), `tvRemoveAds` (`Remove Ads`); each background `@drawable/rounded_corner` (white, 5dp radius), elevation 2dp, bold, color `colorTimeBtns`, paddingStart/End `margin_8_size`.
- `dimmedBackground` (include `dimmed_background`, 0dp×0dp covering mainConstraintLayout, GONE by default) is declared BEFORE the FABs, so when visible it dims keypad/result but FABs+labels stay on top. dimmed_background.xml: ConstraintLayout match×match, `animateLayoutChanges=true`, clickable+focusable, background `semitransparentBackground` (#CCCACACA).

## 7. Main screen — LANDSCAPE (`layout-land/activity_main.xml`)

Same root/ad/include structure and same display stack (tvExpressionField top→buttonFormats; buttonFormats start-aligned + buttonPer end-aligned above tvOnlineResult; tvOnlineResult above tvSpaceWithShadowOnly; same FAB menu, dimmed layer, tvFakeForClear). Differences:
- `buttonFormats` has `app:elevation="1dp"` (portrait: 2dp) and a stray `android:layout_marginEnd="537dp"`.
- tvSpaceWithShadowOnly bottom→top of `buttonNum9`.
- Keypad is 7 columns × 4 rows. Bottom row is a horizontal `spread` chain across parent (all marginBottom `margin_8_size` except operators/Delete): `0 | . | = | Second | Msec | + | ⌫`. Columns above each bottom key:

```
7   8   9   Year    Month   ÷   ⌫(Delete)
4   5   6   Week    Day     ×
1   2   3   Hour    Minute  –
0   .   =   Second  Msec    +
```

- Digit minHeight 35dp (no extra padding). Time keys minHeight 35dp. Operators (`÷ × – +`): minWidth 50dp, minHeight 25dp, includeFontPadding=false, holo_blue_dark; vertical chain `spread_inside`: `÷` top→bottom of tvOnlineResult (marginTop 8dp) → `×` → `–` → `+` (bottom row). Landscape `+` is hardcoded text `+` (not the string resource).
- Row alignment via baselines: Year baseline=Num9, Month baseline=Year; Week baseline=Num6, Day baseline=Week; Hour bottom→top of Second (text `"Hour "` with trailing space), Minute bottom→top of Msec; Second baseline=buttonEqual, Msec baseline=Second.
- `buttonDelete` (ImageButton): top/bottom aligned to `buttonDivide` (top-right corner), start→end of buttonAddition, end→parent, minWidth 50dp, minHeight 25dp, padding 8dp, scaleType fitCenter, dead `android:text="Clear"`.

## 8. Formats overlay (`layout/view_formats.xml`)

ConstraintLayout match×match, background `@android:color/background_light`.
- `toolbar` (androidx Toolbar): 0dp×wrap, top/start/end→parent, background `?attr/colorPrimary` resolved through `android:theme="@style/ToolbarTheme"` → `#9AFDD835`; minHeight `?attr/actionBarSize`; `navigationIcon="?attr/homeAsUpIndicator"` (back arrow); `title="Choose a result format"`, titleMargin 4dp; fontFamily googlesans_regular via theme.
- `scrollView2` (ScrollView): 0dp×0dp, below toolbar to parent bottom, start/end→parent, background `colorSecondaryBackground` (#9AFDD835). Empty — used purely as a colored panel.
- `rvFormatsToChoose` (RecyclerView): 0dp×0dp pinned to scrollView2's top/bottom/start and parent end, margins start/end 8dp, bottom 8dp. Card list of format choices.

### Card (`layout/card_view_formats.xml`)
MaterialCardView `materialCardView`: match_parent×wrap, layout_margin 3dp, clickable/focusable, foreground `?android:attr/selectableItemBackground`, cardElevation 2dp, cardMaxElevation 3dp, contentPadding `margin_8_size`. Inside, a ConstraintLayout with:
- `tvFormat`: 0dp×wrap, top→parent, start/end→parent, 36sp bold (format name).
- `tvResultFormat`: 0dp×wrap, below tvFormat, bottom→parent with marginBottom `margin_8_size`, paddingStart/End `margin_16_size`, horizontal bias 0.2, 24sp (example/preview text).

## 9. Per overlay (`layout/view_per.xml`)

ConstraintLayout match×match, background `colorSecondaryBackgroundForPer` (#66BB6A).
- `toolbarPer`: same as formats toolbar but background `colorSecondaryBackgroundForPer`, title `Amount for the time interval`.
- `labelTimeInterval` (TextView `Time interval:`): below toolbar, marginStart 8dp (default size ~14sp).
- `labelTimeIntervalAmount` (TextView, placeholder `10 Hour 25 Minute 5 Second`): below labelTimeInterval, marginStart 16dp, 24sp bold — runtime shows the calculated interval.
- `labelTimeInterval2` (`Value:`): below labelTimeIntervalAmount, marginStart 8dp, marginTop 8dp, start→parent, labelFor etUnitAmount.
- `labelTimeInterval3` (`Value unit:`): same row — start→end of `etUnitAmount` +16dp, top below labelTimeIntervalAmount +8dp, labelFor etUnit.
- `etUnitAmount` (EditText): below labelTimeInterval2, start-aligned to it +8dp, `inputType=numberDecimal`, `imeOptions=actionDone`, ems=3, default text `25`, 24sp, paddingStart 8dp, includeFontPadding=false, contentDescription `Amount`.
- `etUnit` (EditText): below labelTimeInterval2, start-aligned to labelTimeInterval3 +8dp, `inputType=text`, actionDone, ems=5, default text `USD`, 24sp, paddingStart 8dp, contentDescription `Unit`.
- `scrollView2`: 0dp×0dp from below etUnitAmount (+8dp) to parent bottom, start/end→parent, background #66BB6A (panel only).
- `rvPer` (RecyclerView): overlaid on scrollView2 exactly like the formats one (8dp side/bottom margins).

### Card (`layout/card_view_per.xml`)
Identical MaterialCardView shell to card_view_formats; differences: `tvFormat` is 24sp bold (not 36sp); `tvResultFormat` has no bottom margin, paddingStart+paddingEnd `margin_16_size`, 24sp, bias 0.2.

## 10. Drawables

- `rounded_corner.xml`: rectangle shape, corner radius 5dp, stroke width 0dp (no color → none), solid white. Used for FAB label pills.
- `text_view_shadow.xml`: layer-list faking a downward drop shadow under the white result area. 6 stacked 1dp-bottom-padding layers then a white background layer. Visible bottom-up stripes (1dp each): `#00CCCCCC`, `#10CCCCCC`, `#20CCCCCC`, `#30CCCCCC`, `#50CCCCCC`, `#00cccccc` (transparent hairline), then solid white above. Flutter: a ~6dp Container with a top-down white→transparent grey gradient (or a BoxShadow on the result container).
- Vector icons (all 24×24 viewport): `ic_backspace_black_24dp` (16dp×16dp size, fill #FF000000, material backspace-with-X glyph), `ic_menu_white_24dp` (24dp, tint+fill #FFFFFF, hamburger), `ic_star_green_24dp` (24dp, tint/fill #33691e, star), `ic_mail_green_24dp` (24dp, #33691e, envelope), `ic_remove_ads_green_24dp` (24dp, #33691e, circle-slash "block"), `ic_close_white_24dp` (24dp, #FFFFFF, X — used when FAB menu is open).
- Mipmaps: `ic_launcher.png` + `ic_launcher_round.png` in mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi only (no adaptive icon, no anydpi-v26 dir).

## 11. Key behavioral implications for rebuild

- Text autosizing: expression 24→64sp step 2sp; result 16→50sp step 1sp; both uniform, both scale with sw bucket.
- Both text displays are selectable and vertically scrollable; expression is right/bottom-gravity, result is right/center-gravity with fixed height.
- Formats/Per buttons display CURRENT selection ("Hour Minute" / "Per" are just defaults set in XML; runtime replaces text).
- Overlays cover the whole screen except the ad banner; tapping the toolbar nav icon returns to the calculator.
- Dim layer (#CCCACACA) appears behind the expanded FAB menu, is clickable (dismiss), animates layout changes.

## Suspected bugs
- layout-land/activity_main.xml:564 — buttonFormats has android:layout_marginEnd="537dp", an obvious layout-editor artifact. It is only neutralized because horizontal bias is 0.0 with wrap_content width; any constraint change would fling the button off-layout.
- layout-land/activity_main.xml:139 — buttonHour text is "Hour " with a trailing space (portrait is "Hour"); if button text is compared/parsed anywhere this mismatches, and it renders with extra width.
- layout/activity_main.xml:136 and layout-land/activity_main.xml:53 — buttonDelete is an ImageButton but carries android:text ("Del"/"Clear"), android:fontFamily and android:textSize/textColor; ImageButton never renders text, so these are dead attributes (and the two layouts disagree on the label).
- Font confusion: every layout uses @font/googlesans_regular (bundled TTF), while font/abeezee.xml (downloadable ABeeZee) is declared and preloaded via values/preloaded_fonts.xml but referenced nowhere in layouts — the downloadable-font machinery is dead weight, and Google Sans is bundled likely without redistribution rights.
- fab_margin scaling is inconsistent: values/dimens.xml=8dp, sw300–sw340=2dp, sw360–sw400=4dp, and the key is absent from sw420–sw800 so those fall back to 8dp. A 419dp device gets 4dp while a 300dp device falls into sw300 (2dp) but a <300dp device gets 8dp — non-monotonic.
- values/strings.xml has duplicate-meaning pairs with inconsistent casing: removeads/remove_ads (both "Remove Ads"), ratetheapp/rate_the_app, and send_feedback ("Send Feedback") vs feedback ("Send feedback").
- drawable/text_view_shadow.xml — the 6th layer is #00cccccc (fully transparent), inserting a 1dp transparent hairline between the white content layer and the grey gradient; the fade sequence 00/10/20/30/50 then 00 looks like one accidental extra layer.
- layout/activity_main.xml:141 — buttonDelete app:layout_constraintHorizontal_bias="0.58" and layout/activity_main.xml:495 — buttonNum2 bias "0.521": editor-generated near-center biases that subtly misalign these keys relative to their columns.
- layout/view_formats.xml:34 and layout/view_per.xml:93 — ScrollView has layout_constraintHorizontal_bias=0.6 with width 0dp and both edges constrained to parent: a no-op artifact. Also both ScrollViews are empty and used only as colored panels with a RecyclerView absolutely overlaid on them — fragile pattern.
- Portrait buttonFormats elevation 2dp vs landscape 1dp (layout-land:578) — unintentional inconsistency.
- tvOnlineResult combines android:singleLine="false", fixed 60dp height, autosize 16–50sp and vertical scrollbars — multi-line text inside a fixed-height auto-sized TextView can clip; ellipsize="none" with marquee-style config on tvExpressionField (ellipsize=marquee + scrollbars + textIsSelectable) is contradictory.
- Landscape buttonAddition hardcodes text "+" instead of @string/button_addition, and portrait buttonAddition uses @color/colorOperators while all other operators reference @android:color/holo_blue_dark directly — same value today, but two sources of truth.
- view_per.xml row of labels/fields is cross-coupled: labelTimeInterval3 ("Value unit:") anchors to etUnitAmount's end while etUnit anchors to labelTimeInterval3 — longer localized label or wider amount text shifts the unit column unpredictably.

## Porting notes
- ConstraintLayout chains (vertical spread_inside operator chains, horizontal spread bottom rows, baseline constraints in landscape) — Flutter: rebuild as explicit Column/Row trees with Expanded/Flexible weights, or a Table; baseline alignment via Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic). Two separate trees behind OrientationBuilder for portrait vs landscape since the grids differ structurally (4-col vs 7-col).
- ?selectableItemBackgroundBorderless ripple on flat keypad keys — Flutter: InkResponse/InkWell with no border (containedInkWell:false) inside a Material ancestor; Widget.AppCompat.Button.ButtonBar.AlertDialog ≈ TextButton with zero elevation and tight padding (minHeight 30/35dp, custom paddings).
- TextView autosize (autoSizeTextType=uniform, min/max/granularity) for expression (24–64sp step 2) and result (16–50sp step 1) — Flutter: auto_size_text package (supports minFontSize/maxFontSize/stepGranularity) or FittedBox; combine with SelectableText for textIsSelectable and SingleChildScrollView for the vertical scrollbars.
- values-sw###dp dimens buckets (13 buckets, all = base × sw/320) — Flutter: compute scale = MediaQuery.sizeOf(context).shortestSide / 320 and multiply the base dimen table; decide whether to clamp like Android buckets (step function) or scale continuously.
- Downloadable Google Font ABeeZee (font/abeezee.xml via GMS provider) vs bundled googlesans_regular.ttf actually used everywhere — Flutter: pick one family; GoogleFonts.aBeeZee() is the legally safe equivalent; Google Sans/Product Sans cannot be redistributed, so do not copy the ttf.
- MaterialButton with strokeColor/strokeWidth/cornerRadius (#304FFE, 1dp, 5dp) for Formats/Per — Flutter: OutlinedButton with BorderSide(color: Color(0xFF304FFE), width:1), RoundedRectangleBorder(radius 5), bold label, textAllCaps:false (Flutter default), elevation 2.
- FloatingActionButton mini + speed-dial menu (fab toggles rateApp/feedback/removeads with pill labels and a dimmed scrim) — Flutter: FloatingActionButton.small or mini:true inside a Stack; scrim = ModalBarrier/GestureDetector with Color(0xCCCACACA); android:animateLayoutChanges ≈ AnimatedOpacity/AnimatedSlide; label pills = Material(elevation:2, borderRadius:5, color: white) + Padding.
- AdMob AdView SMART_BANNER pinned under the calculator — Flutter: google_mobile_ads; SMART_BANNER is deprecated, use AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize; main content must occupy remaining height above the banner (Expanded over a fixed banner slot).
- androidx Toolbar with navigationIcon=?homeAsUpIndicator and translucent background (#9AFDD835 / #66BB6A) — Flutter: AppBar with leading BackButton/IconButton(Icons.arrow_back), backgroundColor with alpha, elevation 0, custom titleTextStyle in the app font.
- RecyclerView + MaterialCardView lists (formats / per) — Flutter: ListView.builder of Card(elevation:2, margin: EdgeInsets.all(3)) wrapped in InkWell for ?selectableItemBackground foreground ripple; contentPadding 8dp via Padding; two-line card with title (36sp bold formats / 24sp bold per) and 24sp subtitle indented (bias 0.2 ≈ left padding).
- layer-list text_view_shadow (graduated 1dp stripes #00/#10/#20/#30/#50 CCCCCC under white) — Flutter: a 6-logical-pixel Container with LinearGradient(top white → Color(0x50CCCCCC) → transparent), or simply give the result container a BoxShadow and drop the fake-strip TextView (tvSpaceWithShadowOnly) entirely.
- ImageButton buttonDelete with vector ic_backspace_black_24dp — Flutter: IconButton(Icons.backspace) (Material backspace glyph matches the path); vector drawables otherwise map to standard Material Icons: menu, close, star, mail/email, block (remove-ads), tinted #33691e or white.
- EditTexts in Per view (inputType numberDecimal / text, imeOptions actionDone, ems widths, default values 25 / USD) — Flutter: TextField with TextInputType.numberWithOptions(decimal:true) / TextInputType.text, textInputAction: TextInputAction.done, controllers pre-filled, width constrained (ems≈3/5 → ~3/5 character widths, use SizedBox).
- android:descendantFocusability=beforeDescendants + focusableInTouchMode on the main layout (keyboard-focus suppression trick) — Flutter: FocusScope.of(context).unfocus() on tap-outside; no direct equivalent needed.
- tvFakeForClear (hidden holo-blue overlay over the expression area, presumably flashed on clear) — Flutter: an AnimatedOpacity/AnimatedContainer flash effect; decide whether to keep this affordance.
- @android:color/background_light and holo_blue_dark are framework colors — pin them as constants in Flutter: background_light = 0xFFFFFFFF, holo_blue_dark = 0xFF0099CC, so theming changes on Android never applied anyway.
- Launcher icons are legacy PNG mipmaps only (no adaptive icon) — Flutter: regenerate with flutter_launcher_icons including adaptive foreground/background for modern Android.
- tools:* attributes (tools:text="100", tools:text="dsfdfdsfdfdf", placeholder "10 Hour 25 Minute 5 Second") are design-time only in Android XML but view_per's label/EditText defaults ("25", "USD", "10 Hour 25 Minute 5 Second") are android:text — i.e. real runtime defaults that must be replicated.
