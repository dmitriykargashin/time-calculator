# ui-activity

## Summary
This area is the entire UI layer of "Time Calculator Cardamon": a single-Activity (CalculatorActivity) MVVM calculator where every keypad button appends typed Tokens to an expression LiveData, a live result is rendered with colored/scaled Spannables, and two full-screen circular-reveal overlays provide (1) a single-select result-format chooser (RvAdapterResultFormats) and (2) a "Per" view that multiplies a user-entered amount/unit (e.g. 25 USD per Hour) across the computed time interval (RvAdapterPer). It also contains all monetization: an AdMob smart banner (loaded on every resume when no purchase exists), Google Play Billing 2.1.0 for a single non-consumable SKU "remove_ads", a compile-time PRO flavor flag, the hotchemi android-rate prompt, and a manifest-auto-initialized Facebook SDK. A FAB speed-dial (not a nav drawer) exposes Rate / Feedback / Remove-Ads actions.

## Detailed spec
# UI Behavior Spec — CalculatorActivity + Adapters + Spannable Extensions

Source files (absolute paths):
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/ui/calculator/CalculatorActivity.kt`
- `.../ui/calculator/RvAdapterPer.kt`, `.../ui/calculator/RvAdapterResultFormats.kt`
- `.../internal/extension/Extension.kt`, `.../internal/extension/SpannableFunctions.kt`
- Supporting: `.../ui/calculator/CalculatorViewModel.kt`, `.../data/tokens/Tokens.kt`, `Token.kt`, `TokenType.kt`, repositories, `res/layout/activity_main.xml`, `res/layout-land/activity_main.xml`, `res/layout/view_formats.xml`, `res/layout/view_per.xml`, `res/layout/card_view_formats.xml`, `res/layout/card_view_per.xml`, `res/values/{strings,colors,dimens,styles}.xml`, `AndroidManifest.xml`, `app/build.gradle`.

## 1. Architecture
- One activity: `CalculatorActivity : AppCompatActivity(), PurchasesUpdatedListener`. Launcher activity (MAIN/LAUNCHER intent filter). Theme `AppTheme` = `Theme.MaterialComponents.Light.NoActionBar.Bridge` (colorPrimary `#008577`, colorPrimaryDark `#00574B`, colorAccent `#D81B60`).
- Views accessed via `kotlinx-android-synthetic` (`activity_main`, `view_formats`, `view_per`).
- `CalculatorViewModel` obtained via `ViewModelProviders.of(this, InjectorUtils.provideCalculatorViewModelFactory())`. The factory wires 4 process-wide singletons: `TokensRepository` (result tokens), `ExpressionRepository` (input tokens), `ResultFormatsRepository` (23 formats, single-selected), `PerUnitsRepository` (8 per-units + amount/unitName/timeInterval). Because repositories are singletons, expression/result/format/per state survives rotation and activity recreation.
- All state is in-memory LiveData; nothing is persisted to disk (no SharedPreferences anywhere).

## 2. Screen structure (portrait `layout/activity_main.xml`)
Root `commonConstraintLayout` contains:
1. `mainConstraintLayout` (background `@android:color/background_light`), constrained above the `adView`. Children (top→bottom):
   - `tvExpressionField` — expression display (see §5).
   - Row above result: `buttonFormats` (MaterialButton TextButton, default text "Hour Minute", textColor `#304FFE`, bold, stroke `#304FFE` 1dp, corner 5dp, textSize `buttons_time_size`=16sp) on the left; `buttonPer` (text "Per", same style) on the right.
   - `tvOnlineResult` — result display (see §6).
   - `tvSpaceWithShadowOnly` — 0sp text, `@drawable/text_view_shadow` divider.
   - Keypad grid (all `Widget.AppCompat.Button.ButtonBar.AlertDialog` style, background `?selectableItemBackgroundBorderless`, font `@font/googlesans_regular`):
     - Column-paired layout: digits 7 8 9 / 4 5 6 / 1 2 3 / 0 . = (digits & dot & equal: textColor `@color/colorNums` = black, textSize `buttons_num_size`=18sp).
     - Time-unit buttons: `Year Month Week Day` row and `Hour Minute Second Msec` bottom row (textColor `@color/colorTimeBtns` = `#33691e`, textSize 16sp, textAllCaps=false).
     - Operator column (right edge): `buttonDelete` (ImageButton, icon `ic_backspace_black_24dp`), `buttonDivide` "÷", `buttonMultiply` "×", `buttonAddition` "+" (textColor `@color/colorOperators` = holo_blue_dark), `buttonSubstraction` "–" (string `&#8211;` EN DASH; operators textColor holo_blue_dark, textSize `buttons_operators_size`=20sp).
   - `tvFakeForClear` — hidden TextView covering the expression area, background `@android:color/holo_blue_dark`; used as flash overlay for clear-all animation.
   - `dimmedBackground` — include of `dimmed_background.xml` (full-screen clickable ConstraintLayout, background `@color/semitransparentBackground` = `#CCCACACA`), initially `gone`.
   - FAB cluster top-start: `fab` (mini, backgroundTint `#33691e`, icon `ic_menu_white_24dp`) with vertical children `rateApp` (icon `ic_star_green_24dp`), `feedback` (`ic_mail_green_24dp`), `removeads` (`ic_remove_ads_green_24dp`) — all mini, white background — plus pill labels `tvRateApp` ("Rate the App"), `tvFeedback` ("Send Feedback"), `tvRemoveAds` ("Remove Ads"), rounded_corner background, textColor `#33691e`, bold.
2. `adView` — `com.google.android.gms.ads.AdView`, `adSize="SMART_BANNER"`, `adUnitId="@string/banner_ad_unit_id"`, pinned to bottom of screen.
3. `formatsLayout` — include of `view_formats.xml`, initially `gone`, constrained to cover `mainConstraintLayout` (NOT the banner — banner stays visible under it).
4. `perLayout` — include of `view_per.xml`, initially `gone`, same constraints.

## 3. Button behaviors (initUI)
All keypad clicks call `viewModel.addToExpression(Token(...))`:
- `buttonNum0..9` → `Token(TokenType.NUMBER, strRepresentation = "0".."9")`.
- `buttonComma` → `Token(TokenType.DOT)` (value ".").
- `buttonYear/Month/Week/Day/Hour/Minute/Second/Msec` → `Token(YEAR/MONTH/WEEK/DAY/HOUR/MINUTE/SECOND/MSECOND)` with strRepresentation from `TokenType.value`: `"Year"`, `"Month"`, `"Week"`, `"Day"`, `"Hour"`, `"Minute"`, `"Second"`, `"MSecond"`.
- `buttonMultiply` → `Token(MULTIPLY)` value `"×"` (U+00D7); `buttonDivide` → `"÷"` (U+00F7); `buttonSubstraction` → `Token(MINUS)` value `"−"` (U+2212 MINUS SIGN — note button label is U+2013 EN DASH); `buttonAddition` → `"+"`.

ViewModel semantics of `addToExpression`:
- Delegates to `ExpressionRepository.addToExpression`. Operators (+,−,×,÷) are validated/added but NEVER trigger re-evaluation (returns false). DOT: appended to the last NUMBER token only if it doesn't already contain "." (no eval). NUMBER: merged (string-concatenated) into a trailing NUMBER token, or added as new token; validation via `isErrorsInExpression(token, list)` silently rejects invalid additions (no UI feedback).
- Re-evaluation is triggered (returns true) when the last `+`/`−`-delimited block contains a time keyword, AND for numbers only under extra conditions involving a preceding `×`/`÷` operator chain; plain time-unit/number-after-unit additions evaluate via `tryToAddToExpression` returning true.
- On true: `viewModelScope.coroutineContext.cancelChildren()` then launch `evaluateExpression()`: `CalculatorOfTime.evaluate(expression)` on `Dispatchers.Default` → `tempResultInMsec` (Tokens, milliseconds) → `TimeConverter.convertTokensToTokensWithFormat(tempResultInMsec, selectedFormat.formatTokens)` → `tokensRepository.setTokens(result)`; then `setIsPerViewButtonDisabled(false)`.

### Backspace (`buttonDelete`)
- Click → `viewModel.clearOneLastSymbol()` → `ExpressionRepository.deleteLastTokenOrSymbol()`: if last token is not NUMBER → remove whole token; if NUMBER → drop one trailing character (remove token when string becomes empty). Recomputes result (re-launch `evaluateExpression`) iff the remaining last block has a time keyword OR the new last token is non-NUMBER.
- Long-press → if `!viewModel.isExpressionEmpty()`: on API ≥21, circular reveal of `tvFakeForClear` (blue flash) centered at x = buttonDelete screen-x + width/2, y = `tvOnlineResult.bottom`, start radius 0 → end radius `hypot(tvExpressionField.width, tvExpressionField.height + tvOnlineResult.height + buttonFormats.height)`, `AccelerateDecelerateInterpolator`, duration **400ms**; on animation end: hide overlay and `viewModel.clearAll()`. On API <21: immediate `clearAll()`. Listener returns `true` (consumes long-press). `clearAll()` empties both result and expression Tokens and disables the Per button.

### Equals (`buttonEqual`)
- `viewModel.sendResultToExpression()`: if result token list non-empty — expression := result tokens, result := empty `Tokens()`, Per button disabled. (i.e. "=" promotes the formatted result to be the new input; no evaluation occurs.)

### Formats button (`buttonFormats`)
- Click: `viewModel.updateResultFormats()` (recomputes `convertedResultTokens` preview for ALL 23 formats from `tempResultInMsec`), then on API ≥21 a circular reveal OPEN of `formatsLayout`: center = buttonFormats on-screen center, radius 0 → `hypot(commonConstraintLayout.width, commonConstraintLayout.height)`, AccelerateDecelerate, **600ms**; `setIsFormatsLayoutVisible(true)` + `visibility=VISIBLE` before `anim.start()`. API <21: just set visible.
- Label: observer on `getSelectedFormat()` sets `buttonFormats.text = format.textPresentationOfTokens.toHTMLWithLightGreenColor()` (i.e. `#4c992e` at 0.7 relative size). Same observer, when `formatsLayout.isAttachedToWindow && isFormatsLayoutVisible`, calls `closeFormatsLayout(commonConstraintLayout.width/2, commonConstraintLayout.height/2)` — i.e. selecting a format closes the chooser with a shrink animation centered mid-screen.

### Per button (`buttonPer`)
- Enabled-state observer `getIsPerViewButtonDisabled()`: disabled → `isEnabled=false`, `isClickable=false`, `alpha=0.5f`; enabled → true/true/`1.0f`. Initial state: disabled (repository default `true`). Enabled after any successful evaluation; disabled again by clear-all and equals.
- Click: `viewModel.updatePerUnits()` (no-op while disabled; otherwise recompute all per-unit results from `tempResultInMsec`), then identical 600ms circular reveal of `perLayout` from buttonPer center; `setIsPerLayoutVisible(true)`.
- `toolbarInitalize()` re-renders the Per button text: `buttonPer.text = buttonPer.text.toString().toHTMLWithLightGreenColor()` (so "Per" displays light-green `#4c992e` @0.7 despite XML color `#304FFE`).

## 4. Spannable system (exact values)
`SpannableFunctions.kt` (DSL from a public gist): `span(s, o)` wraps a String into `SpannableString` (or reuses a SpannableString; any other CharSequence becomes empty `SpannableString("")`) and applies the span over `[0, length]` with `SPAN_EXCLUSIVE_EXCLUSIVE`. Provided combinators: `bold, italic, underline, strike, sup, sub, size(Float→RelativeSizeSpan), color(Int→ForegroundColorSpan), background, url, normal`, plus `SpannableString.plus` concatenation via `TextUtils.concat` and `spannable { }` runner.

`Extension.kt` string helpers (exact colors):
- `toHTMLWithGreenColor()` = `size(0.7f, color(Color.parseColor("#33691e"), this))` → dark green, 70% relative size.
- `toHTMLWithLightGreenColor()` = `size(0.7f, color(Color.parseColor("#4c992e"), this))` → light green, 70% size.
- `toHTMLWithGrayColor()` = `color(Color.parseColor("#807e7e"), this)` → gray, full size.
- `toHTMLWithRedColor()` = `size(0.7f, color(Color.parseColor("RED"), this))` → named color red (0xFFFF0000), 70% size.
- `addStartAndEndSpace()` = `" $this "`; `removeAllSpaces()`, `removeHTML()` (char copy), `toTokens()/toToken()/toTokenInMSec()` lexer bridges; `Activity.logger(String|Int)` → `Log.d(localClassName, msg)`.

`Tokens.toSpannableString()` (expression rendering):
- NUMBER → plain text (inherits TextView color `#272727`), full size.
- Time units (SECOND, MSECOND, YEAR, MONTH, WEEK, DAY, HOUR, MINUTE) → `" Unit "` (space-padded) in `#33691e` @ 0.7 relative size.
- Operators (×, +, ÷, −) → `" op "` plain, full size.
- ERROR → `" ERROR "` red @ 0.7.

`Tokens.toLightSpannableString()` (result rendering):
- NUMBER → gray `#807e7e`, full size.
- Time units → `" Unit "` light green `#4c992e` @ 0.7.
- Operators → `" op "` gray `#807e7e`, full size.
- ERROR → `" ERROR "` red @ 0.7.

## 5. Expression display (`tvExpressionField`)
- Observer on `getExpression()`: `tvExpressionField.text = it.toSpannableString()` and `movementMethod = ScrollingMovementMethod()` (re-assigned every update). (Auto-scroll-to-bottom code present but commented out.)
- XML: width 0dp (full), height 0dp stretching from top to buttonFormats; gravity `bottom|end`; auto-size uniform **24sp–64sp**, granularity 2sp (`result_expression_mintextsize/maxtextsize`); textColor `#272727`; white background; vertical scrollbars with `scrollbarAlwaysDrawVerticalTrack="true"`, `scrollbarStyle="outsideInset"`; `textIsSelectable="true"`; `ellipsize="marquee"`; font googlesans_regular; padding left/right 16dp, top 8dp.

## 6. Result display (`tvOnlineResult`)
- Observer on `getResultTokens()`: `tvOnlineResult.text = it?.toLightSpannableString()`; also recreates `rvPer.adapter = RvAdapterPer(viewModel)` and sets Per-view header `labelTimeIntervalAmount.text = it?.toSpannableString()` (dark-green variant).
- XML: fixed height `result_output_height` = **60dp**; gravity `center_vertical|end`; auto-size uniform **16sp–50sp**, granularity 1sp; bold; base textColor black (numbers overridden gray by spans); vertical scrollbars (`outsideInset`), `singleLine="false"`, `ellipsize="none"`, `textIsSelectable="true"` (selectability supplies the movement method; no ScrollingMovementMethod is set in code); padding 16dp horizontal.
- Result updates live while typing (no equals needed) whenever evaluation triggers per §3.

## 7. Formats chooser overlay (`view_formats.xml` + `RvAdapterResultFormats`)
- Layout: Toolbar `toolbar` (title **"Choose a result format"**, `navigationIcon="?attr/homeAsUpIndicator"`, theme ToolbarTheme: googlesans font, colorPrimary `#9AFDD835`, toolbar background `?attr/colorPrimary`), beneath it a ScrollView strip with background `@color/colorSecondaryBackground` = `#9AFDD835` and a RecyclerView `rvFormatsToChoose` (8dp margins) overlaying it.
- Toolbar nav click → `closeFormatsLayout(10, 10)`.
- `rvFormatsToChoose` uses a vertical `LinearLayoutManager`; the adapter is **recreated** (`RvAdapterResultFormats(viewModel)`) on every `getResultFormats()` emission.
- `RvAdapterResultFormats.onBindViewHolder` (item layout `card_view_formats.xml`: MaterialCardView, 3dp margin, cardElevation 2dp/max 3dp, contentPadding 8dp, clickable/focusable, selectableItemBackground foreground):
  - `tvFormat` (36sp bold) = `format.textPresentationOfTokens.toHTMLWithGreenColor()` → e.g. "Hour Minute" in `#33691e` at 0.7×36 ≈ 25.2sp.
  - `tvResultFormat` (24sp, paddings 16dp) = `format.convertedResultTokens.toLightSpannableString()` → live preview of the current result expressed in that format.
  - Card click → `viewModel.setSelectedFormat(position)`.
- Selection model: **strict single-select**. `ResultFormats.setSelection(position)` clears `isSelected` on all formats and sets the clicked one. `setSelectedFormat` then re-converts `tempResultInMsec` into the new format and replaces the result tokens → main screen result text changes immediately; `selectedFormat` observer updates the `buttonFormats` label and closes the overlay (450ms shrink reveal centered mid-screen). No checkmark/visual selected state is rendered in the list itself.
- Format list (`ResultFormatsRepository.fillRepository`), in order, label = formatTokens joined with spaces unless overridden: `Year`; `Year Month`; `Year Month Day`; `Year Month Day Minute`; `Month`; `Month Day`; `Month Day Hour`; `Month Day Hour Minute`; `Month Day Hour Minute Second`; `Month Week`; `Week`; `Week Day`; `Day`; `Day Hour`; `Day Hour Minute`; `Day Hour Minute Second`; `Hour`; **`Hour Minute` (default selected)**; `Hour Minute Second`; `Minute`; `Minute Second`; `Second`; and last `Year Month Week Day Hour Minute Second MSecond` displayed with explicit label **"All Units"**.

## 8. Per view overlay (`view_per.xml` + `RvAdapterPer`)
- Layout (background `@color/colorSecondaryBackgroundForPer` = `#66BB6A`): Toolbar `toolbarPer` titled **"Amount for the time interval"** (same green background, homeAsUp icon → `closePerLayout(10,10)`); labels `"Time interval:"` over `labelTimeIntervalAmount` (24sp bold; runtime = current result tokens via `toSpannableString()`; XML placeholder "10 Hour 25 Minute 5 Second"); `"Value:"` over `etUnitAmount` (EditText, `inputType="numberDecimal"`, default text **"25"**, ems 3, 24sp, `imeOptions="actionDone"`); `"Value unit:"` over `etUnit` (EditText, `inputType="text"`, default text **"USD"**, ems 5, 24sp, actionDone); below: ScrollView strip + RecyclerView `rvPer` (vertical LinearLayoutManager, 8dp margins).
- `setOnEditorActionListener` on both EditTexts: on `IME_ACTION_DONE` → `hideKeyboard()`; lambda effectively returns `false` always (the inner `true` is dead — see bugs).
- `TextWatcher.onTextChanged` on `etUnitAmount`: if its text non-empty AND `etUnit` non-empty → `viewModel.updateSettingsForPerUnits(s.toString().toBigDecimal(), etUnit.text.toString())` and `rvPer.visibility = VISIBLE`; else `rvPer.visibility = INVISIBLE`. Mirror watcher on `etUnit` (uses `etUnitAmount.text.toString().toBigDecimal()`). So clearing either field hides the list; typing recomputes it live.
- `updateSettingsForPerUnits(amount, unitName)` (no-op when Per button disabled): `PerUnitsRepository.setParams(amount, unitName, tokensRepository.getTokens().value!!)` then `updatePerUnitsWithPreview(tempResultInMsec)`.
- `PerUnitsRepository`: defaults `PerUnits(amount=25, unitName="USD", timeInterval="10 Hour".toTokens())`; per-unit rows in order: **Hour, Minute, Second, Day, Week, Month, Year, MSecond**. `updatePerUnitsWithPreview`: for each row, convert the result-in-msec into that single unit (`TimeConverter.convertTokensToTokensWithFormat(resultTokens, unitToken)`), then `unitsPer_Result = amount * units[0].strRepresentation.toBigDecimal()`.
- `RvAdapterPer.onBindViewHolder` (item layout `card_view_per.xml` — same MaterialCardView shell as formats card; `tvFormat` is 24sp bold here, `tvResultFormat` 24sp; note the adapter imports `card_view_formats` synthetics but the IDs match):
  - Header (`tvFormat`): `SpannableString("{amount} {unitName} per")` + `spannable { size(1.0f, color(Color.parseColor("#33691e"), " " + perUnit.timeUnit.strRepresentation)) }` + `" in the interval"` — e.g. "25 USD per **Hour** in the interval" with the unit word dark green at size 1.0 (no scaling).
  - Result (`tvResultFormat`): `perUnit.unitsPer_Result.setScale(16, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString()` + `spannable { size(0.7f, color(Color.parseColor("#33691e"), " " + perUnits.unitName)) }` — e.g. "250 USD" with "USD" green @0.7.
  - Cards are NOT clickable (click listener commented out). `getItemCount` = perUnits list size (8).
- `getPerUnits()` observer and `getResultTokens()` observer both recreate `rvPer.adapter` on each emission (full list refresh, no diffing).

## 9. Overlay open/close animations (API ≥ 21 only; minSdk is 19 free / 20 pro, so the no-animation fallback path is reachable)
- OPEN (formats & per): `ViewAnimationUtils.createCircularReveal(layout, buttonCenterXOnScreen, buttonCenterYOnScreen, 0f, hypot(commonW, commonH))`, AccelerateDecelerateInterpolator, **600ms**; LiveData visible=true and `visibility=VISIBLE` set before start.
- CLOSE `closeFormatsLayout(x,y)` / `closePerLayout(x,y)`: reveal from `hypot(commonW, commonH)` down to 0 at (x,y), **450ms**, AccelerateDecelerate; `onAnimationEnd`: set LiveData false + `visibility=GONE`. Call sites: toolbar nav buttons and back button use `(10, 10)` (top-left corner); format selection uses screen center.
- Visibility observers: `getIsFormatsLayoutVisible()` / `getIsPerLayoutVisible()` set the corresponding include VISIBLE/GONE — this restores overlay state after rotation/recreation (no animation).

## 10. Back button (`onBackPressed`)
1. If `getIsFormatsLayoutVisible().value!!` → `closeFormatsLayout(10,10)`.
2. Else if `getIsPerLayoutVisible().value!!` → `closePerLayout(10,10)`.
3. Else `moveTaskToBack(true)` — the activity is never finished by back; the task is just backgrounded (preserves in-memory state).

## 11. Soft keyboard
- `dispatchTouchEvent` override: on EVERY touch event in the activity, if `currentFocus != null` → `InputMethodManager.hideSoftInputFromWindow(currentFocus.windowToken, 0)`, then normal dispatch. Net effect: tapping anywhere (including outside the Per EditTexts) dismisses the keyboard.

## 12. FAB speed-dial ("menu" — there is no navigation drawer or options menu)
- `fabInitalize()` (called twice from initUI): `init(v)` sets `removeads`, `tvRemoveAds` (only when `!isRemoveAdsPurchased`), `rateApp`, `tvRateApp`, `feedback`, `tvFeedback` to `INVISIBLE`.
- `fab` click: if not expanded → `fadeInFABs()`, else `fadeOutFABs()`.
- `fadeInFABs`: `fadeIn()` dims background (alpha 0→1, **100ms**); each item `showIn(v, -anchorFab.height)`: VISIBLE, alpha 0, translationY = −height → animate to 0 translation/alpha 1 over **200ms**; `fab.isExpanded = true`; fab icon → `ic_close_white_24dp`. Remove-ads pair only shown when `!isRemoveAdsPurchased`.
- `fadeOutFABs`: `fadeOut()` background alpha→0 over 100ms then GONE; each item `showOut(v, -height)`: animate translationY to −height, alpha→0 over 200ms, then GONE; `fab.isExpanded=false`; icon → `ic_menu_white_24dp`.
- `dimmedBackground` click → `fadeOutFABs()` (scrim is clickable, blocking underlying UI).
- `rateApp` click → `fadeOutFABs(); rateMeOnGooglePlay()`: `ACTION_VIEW market://details?id=$packageName`, on `ActivityNotFoundException` fallback `http://play.google.com/store/apps/details?id=$packageName`.
- `feedback` click → `fadeOutFABs(); sendFeedback()`: `ACTION_SENDTO` with `data = Uri.parse("mailto:")`, `EXTRA_EMAIL = ["dmitrii.kargashin@cardamon.org"]`, `EXTRA_SUBJECT = "Feedback Time Calculator Cardamon ${BuildConfig.VERSION_CODE}"`; started only if `resolveActivity != null`.
- `removeads` click → listener assigned only after SKU details load (see §14): `fadeOutFABs()` + `launchBillingFlow`.

## 13. Lifecycle
- `onCreate`: `setContentView(R.layout.activity_main)`; (commented-out Facebook key-hash dump); if `!isPaidVersion()` (`BuildConfig.PRO_VERSION == false`) → `setupBillingClient()`; else `adView.visibility = GONE`. Then `initUI()` and `setupRateMe()`. **Ads are NOT loaded in onCreate** (that code is commented out) — loading happens via `checkPurchases()`.
- `onResume`: `checkPurchases()` unconditionally (queries Play cache; loads banner ad if no purchases); then if `!isPaidVersion() && !isRemoveAdsPurchased` → `adView.resume()`.
- `onPause`: if `!isPaidVersion() && !isRemoveAdsPurchased` → `adView.pause()`.
- `onDestroy`: if `!isPaidVersion() && !isRemoveAdsPurchased` → `adView.destroy()`; then super.
- Rotation: activity recreated; layout-land used; ViewModel + singleton repositories preserve expression/result/formats/per state; overlay visibility re-applied by observers; `isRemoveAdsPurchased` field resets to false until the next `checkPurchases()`.

## 14. Monetization — AdMob
- AdMob Application ID (AndroidManifest meta-data `com.google.android.gms.ads.APPLICATION_ID`): **`ca-app-pub-1503550792620709~9288270264`**.
- Banner ad unit (`strings.xml` `banner_ad_unit_id`): **`ca-app-pub-1503550792620709/2350324800`**; `adSize="SMART_BANNER"`; bottom-anchored in both orientations. Dependency: `com.google.firebase:firebase-ads:18.3.0`; `com.google.gms.google-services` plugin applied (no `google-services.json` committed to the repo).
- Load path: only inside `checkPurchases()` when `queryPurchases(INAPP).purchasesList` is null/empty: `MobileAds.initialize(this)`; `AdRequest.Builder().addTestDevice("C38113ED0332D64C52D625B7ED43DDED").build()`; `adView.loadAd(adRequest)`. Triggered (a) on every `onResume`, (b) once after billing setup finishes.
- **No interstitial ads exist anywhere in the codebase** (grep confirms zero Interstitial references).
- PRO flavor: adView set GONE in onCreate; pause/resume/destroy skipped.

## 15. Monetization — Google Play Billing (library `com.android.billingclient:billing:2.1.0`)
- `skuList = listOf("remove_ads")` — single INAPP (non-consumable) SKU, id verbatim **`remove_ads`**.
- `setupBillingClient()` (free flavor only): `BillingClient.newBuilder(this).enablePendingPurchases().setListener(this).build()`; `startConnection`; `onBillingSetupFinished` with `BillingResponseCode.OK` → `loadAllSKUs()` + `checkPurchases()`. `onBillingServiceDisconnected` → only logs "Failed" (no reconnect).
- `loadAllSKUs()`: if `billingClient.isReady` → `querySkuDetailsAsync(SkuDetailsParams(skuList, SkuType.INAPP))`; on OK + non-empty list, for the skuDetails with `sku == "remove_ads"` attaches the `removeads` FAB click listener: `fadeOutFABs()` then `launchBillingFlow(this, BillingFlowParams.newBuilder().setSkuDetails(skuDetails).build())`.
- `onPurchasesUpdated(billingResult?, purchases?)`: if OK && purchases != null → for each purchase: `acknowledgePurchase(purchase.purchaseToken)` then `handlePurchase(purchase)`. If `USER_CANCELED` → logs only. Else → logs and shows `Snackbar.make(commonConstraintLayout, "Purchase is pending. Please wait", LENGTH_SHORT)`.
- `acknowledgePurchase(token)`: `AcknowledgePurchaseParams.newBuilder().setPurchaseToken(token)`; callback only logs responseCode/debugMessage.
- `checkPurchases()`: synchronous `billingClient.queryPurchases(SkuType.INAPP)`; non-empty → `handlePurchase` each; empty/null → initialize MobileAds and load the banner (see §14); logs "Purchases checked".
- `handlePurchase(purchase)`: if `purchaseState == PURCHASED` and `purchase.sku == "remove_ads"` → `removeAds()`. If `PENDING` → logs "Purchase pending" only. (Commented-out `consumeAsync` test code retained.)
- `removeAds()`: `isRemoveAdsPurchased = true`; `adView.visibility = GONE`; `removeads.visibility = GONE`; `tvRemoveAds.visibility = GONE`; logs "Purchase applied. ads removed".
- PRO/no-ads state storage: **in-memory boolean only** (`isRemoveAdsPurchased`, default false) re-derived from Play's purchase cache every onResume; never persisted locally.
- `BuildConfig.PRO_VERSION`: gradle `buildConfigField "boolean", "PRO_VERSION"` — flavor `free` = false (applicationId `com.dmitriykargashin.cardamontimecalculator`, minSdk 19, versionCode 15, versionName "1.0.11"), flavor `pro` = true (applicationId `com.dmitriykargashin.cardamontimecalculator.pro`, minSdk 20, versionCode 6, versionName "1.0.4"). `isPaidVersion() = BuildConfig.PRO_VERSION` gates billing setup and ad lifecycle calls.

## 16. Monetization — android-rate prompt (`com.github.hotchemi:android-rate:1.0.1`)
`setupRateMe()` in onCreate:
```
AppRate.with(this)
  .setStoreType(StoreType.GOOGLEPLAY)
  .setInstallDays(10)
  .setLaunchTimes(10)
  .setRemindInterval(2)
  .setShowLaterButton(true)
  .setDebug(false)
  .setCancelable(false)
  .setOnClickButtonListener { if (it == 0) rateMeOnGooglePlay() }  // 0 = "rate" button index
  .setMessage(R.string.new_rate_dialog_message)
  .monitor()
AppRate.showRateDialogIfMeetsConditions(this)
```
Message verbatim: "If you enjoy using this app, would you mind taking a moment to rate it? It won't take more than a minute. Thanks for your support!". This dialog is the only dialog in the app (besides the Play billing sheet and the Snackbar).

## 17. Facebook SDK
- Dependency `com.facebook.android:facebook-android-sdk:5.13.0`; manifest meta-data `com.facebook.sdk.ApplicationId` = `@string/facebook_app_id` = **`2341977856105223`**.
- `import com.facebook.FacebookSdk` in CalculatorActivity is **unused**; no Facebook API calls in code. The SDK auto-initializes via its ContentProvider and auto-logs app-activation analytics events. A commented-out block in onCreate computes/logs the Facebook key hash (SHA of package signature, Base64).

## 18. Landscape vs portrait
- `layout-land/activity_main.xml` contains the exact same view IDs (verified) — only geometry differs (e.g. buttonDelete icon padding 8dp / `fitCenter` vs portrait 5dp / `center`; tvSpaceWithShadowOnly anchored to buttonNum9 instead of buttonNum8; buttonPer/tvOnlineResult/buttonFormats declared at a different position in the file). All Kotlin behavior is orientation-agnostic. Same SMART_BANNER ad at the bottom. There are 13 `values-sw*dp` buckets overriding dimensions per screen width.

## 19. Constants quick table
| Item | Value |
|---|---|
| Dark green (units in expression, formats label, Per accents) | `#33691e` |
| Light green (units in result, buttonFormats/buttonPer label) | `#4c992e` |
| Gray (numbers/operators in result) | `#807e7e` |
| Error color | named "RED" (0xFFFF0000) |
| Unit/error relative size | 0.7 |
| Expression text color | `#272727` |
| Formats/Per accent buttons | `#304FFE` |
| Formats overlay bg / toolbar | `#9AFDD835` |
| Per overlay bg | `#66BB6A` |
| Scrim | `#CCCACACA` |
| Reveal open / close / clear-flash durations | 600ms / 450ms / 400ms |
| FAB scrim fade / item slide | 100ms / 200ms |
| Result display | 60dp tall, autosize 16–50sp step 1sp |
| Expression display | autosize 24–64sp step 2sp |
| Card text sizes | formats 36sp/24sp; per 24sp/24sp |
| Per result rounding | `setScale(16, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString()` |
| Feedback email | dmitrii.kargashin@cardamon.org |
| AdMob app id | ca-app-pub-1503550792620709~9288270264 |
| Banner unit id | ca-app-pub-1503550792620709/2350324800 |
| Test device id | C38113ED0332D64C52D625B7ED43DDED |
| Billing SKU | remove_ads (INAPP) |
| Facebook app id | 2341977856105223 |

## Suspected bugs
- CalculatorActivity.kt:84-91 + 130-141 + 304-306 — PRO-flavor crash: onResume() calls checkPurchases() unconditionally, but billingClient (lateinit, line 69) is only initialized inside setupBillingClient(), which is skipped when isPaidVersion() is true. First onResume in the pro flavor throws UninitializedPropertyAccessException.
- CalculatorActivity.kt:262-266 — onPurchasesUpdated acknowledges every purchase (acknowledgePurchase(purchase.purchaseToken)) BEFORE checking purchaseState; PENDING purchases should not be acknowledged (Billing API error), and acknowledgement result is never verified before granting entitlement.
- CalculatorActivity.kt:278-283 — generic billing errors (ITEM_ALREADY_OWNED, SERVICE_UNAVAILABLE, etc.) all show the misleading Snackbar 'Purchase is pending. Please wait'.
- CalculatorActivity.kt:304-328 — checkPurchases() runs on every onResume and, when the user has no purchases, calls MobileAds.initialize + adView.loadAd each time (banner reload on every resume); also the AdRequest permanently includes test device C38113ED0332D64C52D625B7ED43DDED in production.
- CalculatorActivity.kt:385-392 — entitlement is never persisted (no SharedPreferences); isRemoveAdsPurchased resets on every process start and depends on Play's queryPurchases cache, so a paying user can be shown ads (e.g. offline first launch), and the banner may load+show briefly before checkPurchases hides it.
- CalculatorActivity.kt:856-858 and 882-885 — TextWatchers call s.toString().toBigDecimal() / etUnitAmount.text.toString().toBigDecimal() without try/catch; inputType numberDecimal allows entering '.' alone, and BigDecimal(".") throws NumberFormatException -> crash while typing in the Per view.
- CalculatorActivity.kt:804-824 — setOnEditorActionListener lambdas: the 'true' inside the if-block is a dead expression; the lambda always returns false, so the DONE action is never consumed (keyboard hide works only because hideKeyboard() is called as a side effect, then default handling also runs).
- CalculatorActivity.kt:1125-1128 — dispatchTouchEvent hides the soft keyboard on EVERY touch event, including taps inside the focused EditText (keyboard hide/re-show flicker) and during scrolling.
- CalculatorActivity.kt:528-529 and 835-836 — toolbarInitalize() and fabInitalize() are each called twice inside initUI(); listeners are re-assigned (harmless) but buttonPer.text gets the spannable transform applied twice and FAB items are re-hidden.
- CalculatorActivity.kt:226-255 + 898-904 — the 'Remove Ads' FAB row is visible (when !isRemoveAdsPurchased) even if loadAllSKUs never succeeds (offline / pro flavor): no click listener is ever attached, so the button silently does nothing.
- CalculatorActivity.kt:215-220 — onBillingServiceDisconnected only logs; no reconnection retry, so billing silently stays dead for the session.
- CalculatorActivity.kt:751-755 — clear-all reveal mixes coordinate spaces: x is from getLocationOnScreen (screen coords) while y = tvOnlineResult.bottom (parent-relative coords), so the reveal center is only approximately correct (and wrong under translucent status bar/landscape).
- CalculatorActivity.kt:193-194 — onBackPressed uses getIsFormatsLayoutVisible().value!! / getIsPerLayoutVisible().value!! with non-null assertions; safe only because the ViewModel init block seeds both LiveDatas — fragile against reordering.
- RvAdapterPer.kt:17,27 — imports kotlinx.android.synthetic.main.card_view_formats.view.* while inflating R.layout.card_view_per; it works only because both card layouts coincidentally declare identical view IDs (tvFormat, tvResultFormat, materialCardView).
- RvAdapterResultFormats.kt:30-39 / RvAdapterPer adapters are recreated wholesale on every LiveData emission (CalculatorActivity.kt:415-431, 486-506) instead of notifyDataSetChanged/diffing — scroll position resets and there is no selected-state indicator in the formats list.
- Extension.kt:73 — Color.parseColor("RED") relies on parseColor lowercasing color names; unconventional and easy to break when porting (should be a constant 0xFFFF0000).
- PerUnitsRepository.kt:54-66 — updatePerUnitsWithPreview assumes the conversion result list is non-empty and units[0] is a parseable number; an ERROR token or empty result tokens would throw (NumberFormatException/IndexOutOfBounds).
- ResultFormatsRepository.kt:104 — initial preview for the 'Month Day' format is "Month Day".toTokens() (no numbers), inconsistent with every other format's '1 Month 2 Day'-style placeholder; visible only before the first updateFormatsWithPreview call.
- CalculatorActivity.kt:626-679 / 682-735 — opening Formats/Per before any expression is entered previews conversions of the initial empty tempResultInMsec (Tokens()); buttonPer is guarded by the disabled flag but buttonFormats is not, so the formats sheet can show degenerate previews.
- app/build.gradle:8-14 — release keystore path AND passwords ('Vfhbyf456keystore' / 'Vfhbyf456key0') are committed in plaintext to the repo.
- Tokens.kt:55-76 toSpannableString has no else branch for DOT/PARENTHESES tokens — a bare trailing DOT token (typed before any number) would render nothing while still being in the model (mostly prevented by ExpressionRepository merging DOT into numbers).

## Porting notes
- Spannable rendering (ForegroundColorSpan + RelativeSizeSpan 0.7, SPAN_EXCLUSIVE_EXCLUSIVE, TextUtils.concat) -> Flutter RichText/TextSpan trees; replicate exact colors (#33691e, #4c992e, #807e7e, #272727, red) and the 0.7 relative font factor; note units/operators are space-padded (' Hour '), which a port should reproduce or normalize deliberately.
- TextView autosize (uniform 16-50sp step 1sp for result, 24-64sp step 2sp for expression) -> Flutter has no built-in autosizing; use auto_size_text package (supports rich text via AutoSizeText.rich) or FittedBox; result field is a fixed 60dp-high box, expression fills remaining space with gravity bottom|end.
- LiveData + ViewModel + singleton repositories -> choose a Flutter state solution (Riverpod/Provider/Bloc). Repositories are process singletons that outlive the screen; expression/result/format/per state must survive orientation change (trivial in Flutter) and back-press backgrounding (moveTaskToBack keeps state in Android; Flutter equivalent is default behavior).
- ViewAnimationUtils.createCircularReveal open/close (600ms open from button center, 450ms close to (10,10) or screen center, AccelerateDecelerateInterpolator, radius = hypot(screen w,h)) -> implement with a custom ClipOval/ClipPath animation or the circular_reveal_animation package; also the long-press-clear blue flash (400ms reveal of a colored overlay, then clear).
- The API<21 no-animation fallback paths become irrelevant in Flutter; decide whether to keep instant toggling as a reduced-motion option.
- ScrollingMovementMethod + textIsSelectable on TextViews -> SelectableText.rich inside SingleChildScrollView; expression auto-scroll-to-bottom was attempted but commented out — decide whether to implement it properly in Flutter (ScrollController.jumpTo(maxScrollExtent) on update).
- FAB speed-dial (fab.isExpanded, translate/fade 200ms, scrim fade 100ms, icon swap menu<->close) -> flutter_speed_dial package or custom AnimatedSlide/FadeTransition + ModalBarrier for the #CCCACACA scrim.
- AdMob: google_mobile_ads plugin; SMART_BANNER is deprecated -> use anchored adaptive banner; keep ids ca-app-pub-1503550792620709~9288270264 (app) and ca-app-pub-1503550792620709/2350324800 (banner); replicate gating (hide ad when PRO flavor or purchase owned); drop the hard-coded test device id; banner pause/resume lifecycle is automatic in the plugin (no onPause/onResume calls needed) — use WidgetsBindingObserver only if re-checking purchases on resume.
- Google Play Billing 2.1.0 -> in_app_purchase plugin: SKU 'remove_ads' as a non-consumable; purchase stream replaces PurchasesUpdatedListener; completePurchase() replaces acknowledgePurchase (and must only run for purchased status); restore via queryPastPurchases/restorePurchases on startup instead of queryPurchases-per-resume; PERSIST the entitlement locally (shared_preferences) — the original keeps it only in memory.
- BuildConfig.PRO_VERSION free/pro product flavors (different applicationIds com.dmitriykargashin.cardamontimecalculator[.pro], versionCode 15/6, versionName 1.0.11/1.0.4, minSdk 19/20) -> Flutter flavors + --dart-define (e.g. PRO_VERSION=true) and per-flavor bundle ids; all ad/billing code must be compile-time or runtime gated on it.
- hotchemi android-rate (GOOGLEPLAY store, installDays 10, launchTimes 10, remindInterval 2 days, showLaterButton true, cancelable false, custom message, rate button -> market:// deep link with http fallback) -> rate_my_app package reproduces these exact conditions, or in_app_review for the native Play sheet (which loses the custom message/conditions).
- Facebook SDK 5.13.0 is manifest-auto-initialized only (app id 2341977856105223, no code usage) -> decide to drop entirely or use facebook_app_events plugin for install/activation analytics parity.
- BigDecimal math in the Per view (amount * units, setScale(16, RoundingMode.HALF_UP), stripTrailingZeros, toPlainString) -> Dart has no BigDecimal; use the decimal package and replicate rounding/formatting exactly (toPlainString avoids scientific notation; stripTrailingZeros of '250.00' -> '250'; beware Java quirk where stripTrailingZeros may produce 2.5E+2 — toPlainString fixes it).
- exp4j (net.objecthunter:exp4j:0.4.8) is a build dependency for the calculation engine -> Dart equivalent needed (e.g. math_expressions) or hand-rolled evaluator; verify which engine paths actually use it before porting.
- Intents: mailto (ACTION_SENDTO with EXTRA_EMAIL/EXTRA_SUBJECT incl. BuildConfig.VERSION_CODE) and market://details fallback http URL -> url_launcher; resolveActivity guard -> canLaunchUrl.
- Snackbar.make(commonConstraintLayout, 'Purchase is pending. Please wait', LENGTH_SHORT) -> ScaffoldMessenger SnackBar.
- dispatchTouchEvent hide-keyboard-on-any-touch -> Flutter: GestureDetector(onTap: FocusScope.unfocus) wrapping the Per view, or Listener on the root; do NOT replicate the hide-on-every-touch behavior literally.
- onBackPressed cascade (close formats overlay -> close per overlay -> moveTaskToBack(true)) -> PopScope/WillPopScope; moveTaskToBack has no exact Flutter equivalent (SystemNavigator.pop kills the engine on Android by default; consider MethodChannel calling moveTaskToBack, or accept normal pop).
- Separate layout-land XML with identical IDs but different geometry -> OrientationBuilder/LayoutBuilder with two arrangements of the same widget set; 13 values-sw*dp dimension buckets -> responsive sizing logic (MediaQuery width breakpoints).
- EditText specifics in Per view: inputType numberDecimal (locale decimal separators!), imeOptions actionDone, ems widths, default texts '25'/'USD', live TextWatcher recomputation, RecyclerView hidden (INVISIBLE not GONE) when either field empty -> TextField with TextInputType.numberWithOptions(decimal: true), onChanged, and input validation to fix the '.'-crash.
- kotlinx synthetics + MaterialCardView cards (3dp margin, elevation 2, contentPadding 8dp, ripple foreground) -> Flutter Card/InkWell with exact paddings; formats card title 36sp bold (rendered at 0.7 => ~25.2sp effective), preview 24sp; per card title 24sp bold.
- Custom font googlesans_regular (preloaded_fonts/font_certs downloadable fonts) -> bundle a substitute font in Flutter assets; Google Sans has licensing restrictions — pick Product Sans alternative or Roboto.
- google-services.json is NOT in the repo though the gms plugin is applied — the Flutter port should decide whether Firebase is needed at all (it is only used transitively by firebase-ads).
- There is no navigation drawer, no options menu, no interstitial ads, and only one dialog (the android-rate prompt) — do not invent them when porting.
