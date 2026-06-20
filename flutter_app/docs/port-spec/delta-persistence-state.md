# RemoveADS branch delta: persistence-state

## Summary
The RemoveADS branch adds exactly one piece of disk persistence - a new PrefRepository storing the theme choice as String "0"/"1"/"2" under key "PREF_THEME_COLOR" in SharedPreferences file "MY_APP_PREF", written synchronously (commit()) on every Settings radio click and read on singleton init/first launch (blank -> "0"). The commit claim "all states save after state change and activity destroy" is implemented NOT by persisting app state to disk but by relocating every ViewModel-scoped field (formats/per overlay flags, tempResultInMsec cache, per-button gating) into a new process-scoped in-memory UtilityRepository singleton, adding two new overlay flags (Support, Settings) and a new Formats-button-disabled flag (Formats is now gated like Per, starting disabled), and giving getResultTokens() a side effect that re-derives both buttons' disabled state from result emptiness on re-subscribe; expression/result/format/per state still lives in the unchanged (or near-unchanged) four singletons and still dies with the process. Other state-layer deltas: ExpressionRepository gains addToExpressionTimeUnit(TokenType) feeding the new smart-plural Token(value: BigDecimal) model ("2 Hours"), TokensRepository gains a dead isEmpty(), ResultFormatsRepository's catalogue grows 23->24 (entry 3 becomes "Year Month Day Hour", new "Year Month Day Hour Minute" at index 4, default "Hour Minute" shifts to index 18), the ViewModel/Factory/InjectorUtils constructors gain prefRepository+utilityRepository+context, clearAll/sendResultToExpression/evaluateExpression also toggle the Formats button, clearOneLastSymbol takes a Context (log-only), and a TimeConverter change makes zero results render "0 <last unit>" instead of blank (incidentally fixing the per-unit units[0] zero crash). For Flutter, the UtilityRepository relocation is already structurally satisfied by the singleton CalculatorModel; the real porting work is the theme preference via shared_preferences, the new flags/gating, addToExpressionTimeUnit + Token.value pluralization, the 24-format list, and the dark-theme-aware span colors.

## Detailed spec
# RemoveADS branch - STATE & PERSISTENCE delta vs master (vs flutter_app/docs/port-spec/data-layer.md)

All Kotlin paths relative to `app/src/main/java/com/dmitriykargashin/cardamontimecalculator/`.

---

## 1. NEW: `PrefRepository` (`data/repository/PrefRepository.kt`) - the ONLY disk persistence in the app

Top-level constants (verbatim):
- `const val PREFERENCE_NAME = "MY_APP_PREF"`
- `const val PREF_THEME_COLOR = "PREF_THEME_COLOR"`

Class `PrefRepository(val context: Context)`:
- Backing store: `context.getSharedPreferences("MY_APP_PREF", Context.MODE_PRIVATE)`.
- A single `editor = pref.edit()` created once at construction and reused for every write.
- `private fun putString(parameterName, value)` = `editor.putString(...)` then **`editor.commit()`** (synchronous disk write, on the calling = main thread).
- `private fun getString(parameterName)` = `pref.getString(parameterName, "")!!` (default empty string).
- In-memory mirror: `private var prefThemeColorRep = "0"` + `private val prefThemeColor = MutableLiveData<String>()`.
- `init`: calls `getPrefThemeColor()` (reads disk into the mirror + LiveData); if the read value `isBlank()` (first run) calls `setPrefThemeColor("0")` - i.e. first launch writes `PREF_THEME_COLOR = "0"`.
- `fun getPrefThemeColor()`: re-reads the pref from disk into `prefThemeColorRep`, sets `prefThemeColor.value` synchronously, returns the `MutableLiveData<String>` (typed as such; the `as LiveData` cast is commented out).
- `fun setPrefThemeColor(value: String)`: updates mirror, `putString` (commit), then `prefThemeColor.postValue(...)` (async publish, comment: "for executing in background thread").
- Singleton: same `@Volatile` double-checked `getInstance(context: Context)` pattern as the other repos (note it takes a Context).

### Persisted value semantics (key `PREF_THEME_COLOR`, type String)
| value | meaning (applied in CalculatorActivity observer) |
|---|---|
| `"0"` | `AppCompatDelegate.MODE_NIGHT_FOLLOW_SYSTEM` + check `rbTheme_SystemDefault` radio |
| `"1"` | `AppCompatDelegate.MODE_NIGHT_NO` (light) + check `rbTheme_Light` |
| `"2"` | `AppCompatDelegate.MODE_NIGHT_YES` (dark) + check `rbTheme_Dark` |
| anything else | falls back to FOLLOW_SYSTEM + system-default radio |

WHEN written: immediately (synchronous `commit()`) every time a theme radio button is clicked in the new Settings overlay (`CalculatorActivity.onRadioButtonClicked` -> `viewModel.setPrefThemeColor("0"/"1"/"2")`). There is NO onPause/onStop persistence hook anywhere (`onPause` is empty).

WHEN restored: lazily on first `InjectorUtils.provideCalculatorViewModelFactory(context)` (PrefRepository singleton init reads disk); the Activity observes `viewModel.getPrefThemeColor()` at the end of `initUI()` and applies the night mode + radio state. Note: changing night mode recreates the Activity - which is precisely the "state change and activity destroy" scenario the commit message refers to.

### What is NOT persisted to disk (unchanged from master in this respect)
Expression tokens, result tokens, selected result format, format previews, per-unit amount/unitName/timeInterval, overlay visibility, tempResultInMsec, purchase/support state - none of it touches SharedPreferences. Purchase/support state is re-queried from Google Play Billing (`billingClient.queryPurchases(INAPP)`) in `onResume`/after billing setup; the rate-dialog library (`AppRating.Builder`, minimum 5 launches / 7 days, show-again 5 launches / 10 days, never-button after 3 dismissals) keeps its own internal prefs. Only theme color survives process death.

---

## 2. NEW: `UtilityRepository` (`data/repository/UtilityRepository.kt`) - process-scoped session-state singleton (in-memory only)

This is the actual mechanism behind the commit claim "2. All states of app saves now without issues (after state change and activity destroy)": every piece of state that master kept in the Activity-scoped CalculatorViewModel (overlay flags, `tempResultInMsec`, per-button gating - see data-layer.md section 3 'Internal state' and the suspected bug at CalculatorViewModel.kt:44) is RELOCATED into this plain singleton, so it now survives Activity (and ViewModel) destruction for the lifetime of the process. Nothing here is written to disk.

State (field + MutableLiveData pairs, getters return `as LiveData<...>`):
- `isInFormatsChooseModeRepository: Boolean = false` + `isInFormatsChooseMode` - Formats overlay open. `getIsFormatsLayoutVisible()` / `setIsFormatsLayoutVisible(visible)` (setter updates field then `value =`).
- `isInPerViewModeRepository: Boolean = false` + `isInPerViewMode` - Per overlay open. `getIsPerLayoutVisible()` / `setIsPerLayoutVisible(visible)`.
- NEW `isInSupportAppViewModeRepository: Boolean = false` + `isInSupportAppViewMode` - "Support the app" overlay open. `getIsSupportAppLayoutVisible()` / `setIsSupportAppLayoutVisible(visible)`.
- NEW `isInSettingsViewModeRepository: Boolean = false` + `isInSettingsViewMode` - Settings overlay open. `getIsSettingsLayoutVisible()` / `setIsSettingsLayoutVisible(visible)`.
- `tempResultInMsecRepository = Tokens()` + `tempResultInMsec = MutableLiveData<Tokens>()` - the cached engine result (`[NUMBER(msec), MSECOND]` / `[ERROR]` / empty), moved out of the ViewModel. `getTempResultInMsec()` / `setTempResultInMsec(value: Tokens)` (field then `value =`). **NOTE: `init` does NOT seed `tempResultInMsec.value`** (unlike all the boolean LiveDatas) - it stays `null` until the first evaluation (master's VM field was an initialized empty `Tokens()`).
- `isPerViewButtonDisabledRepository: Boolean = true` + `isPerViewButtonDisabled` - Per button gating, starts disabled. `getIsPerViewButtonDisabled()` / `setIsPerViewButtonDisabled(visible)`.
- NEW `isFormatsViewButtonDisabledRepository: Boolean = true` + `isFormatsViewButtonDisabled` - **the Formats button is now gated exactly like the Per button** (master had it always enabled). Starts disabled. `getIsFormatsViewButtonDisabled()` / `setIsFormatsViewButtonDisabled(visible)`.
- `init` publishes the four overlay booleans and the two button-disabled booleans (`value =` each); tempResultInMsec is the only LiveData left unseeded.
- Singleton: standard `@Volatile` double-checked `getInstance()` (no args).

All setters use synchronous `value =`; there is no postValue here.

---

## 3. `CalculatorViewModel` (`ui/calculator/CalculatorViewModel.kt`) - full API delta vs master

Constructor (was 4 repos): now `CalculatorViewModel(expressionRepository, tokensRepository, resultFormatsRepository, perUnitsRepository, prefRepository: PrefRepository, utilityRepository: UtilityRepository, context: Context)`. The `context` constructor param is stored but never used. The `init` block is now empty (master published 3 booleans).

REMOVED from VM (moved to UtilityRepository): `isInFormatsChooseModeRepository`, `isInFormatsChooseMode`, `isInPerViewModeRepository`, `isInPerViewMode`, `tempResultInMsec`, `isPerViewButtonDisabledRepository`, `isPerViewButtonDisabled`.

Pure delegations to UtilityRepository (same names as master where they existed): `getIsFormatsLayoutVisible()`, `getIsPerLayoutVisible()`, `setIsFormatsLayoutVisible(v)`, `setIsPerLayoutVisible(v)`, `getIsPerViewButtonDisabled()`, `setIsPerViewButtonDisabled(v)`.

NEW delegations: `getIsSupportAppLayoutVisible()`, `setIsSupportAppLayoutVisible(v)`, `getIsSettingsLayoutVisible()`, `setIsSettingsLayoutVisible(v)`, `getIsFormatsViewButtonDisabled()`, `setIsFormatsViewButtonDisabled(v)`.

NEW preference passthroughs: `getPrefThemeColor() = prefRepository.getPrefThemeColor()`, `setPrefThemeColor(value: String) = prefRepository.setPrefThemeColor(value)`.

CHANGED `getResultTokens(): LiveData<Tokens>` - now has a SIDE EFFECT before returning `tokensRepository.getTokens()`:
```
utilityRepository.setIsPerViewButtonDisabled(isResultEmpty())
utilityRepository.setIsFormatsViewButtonDisabled(isResultEmpty())
```
This runs when the Activity (re)subscribes in `initUI()`, re-deriving both buttons' enabled state from whether a result is currently displayed - this is the fix for master's "Per button resets to disabled after recreation despite a visible result" bug (data-layer.md suspected-bugs, CalculatorViewModel.kt:44 entry).

NEW `isResultEmpty(): Boolean = tokensRepository.getTokens().value.isNullOrEmpty()`.

NEW `addToExpressionTimeUnit(elementType: TokenType)` - mirrors `addToExpression`: `if (expressionRepository.addToExpressionTimeUnit(elementType)) { viewModelScope.coroutineContext.cancelChildren(); viewModelScope.launch { evaluateExpression() } }`. All 8 time-unit keypad buttons (Year...Msec) now call this instead of `addToExpression(Token(<keyword>))`.

CHANGED `clearOneLastSymbol(context: Context)` - signature gains a Context param, used ONLY for a `Log.i` of `toSpannableString(context)` (spannables are now theme-aware and need a Context). Behavior otherwise identical.

CHANGED `clearAll()` - additionally `utilityRepository.setIsFormatsViewButtonDisabled(true)` (Per disable as before, both via utilityRepository).

CHANGED `sendResultToExpression()` - additionally disables the Formats button (`setIsFormatsViewButtonDisabled(true)`) alongside Per.

CHANGED `evaluateExpression()` (private suspend) - same 4-step pipeline, but: step 1 stores via `utilityRepository.setTempResultInMsec(withContext(Dispatchers.Default){ CalculatorOfTime.evaluate(...) })`; step 2 reads `utilityRepository.getTempResultInMsec().value!!`; step 4 enables BOTH buttons: `setIsPerViewButtonDisabled(false)` and `setIsFormatsViewButtonDisabled(false)`.

CHANGED `updateResultFormats()` / `updatePerUnits()` / `updateSettingsForPerUnits(amount, unitName)` / `setSelectedFormat(position)` - identical logic to master except every read of the msec cache is `utilityRepository.getTempResultInMsec().value!!`, and the Per gating checks are now `utilityRepository.getIsPerViewButtonDisabled().value == false` (previously the VM boolean field). `updateSettingsForPerUnits` still sets `timeInterval := tokensRepository.getTokens().value!!` then refreshes previews.

Unchanged: `getResultFormats()`, `getPerUnits()`, `addToresultFormats()`, `addToken()`, `addToExpression(element)`, `getExpression()`, `isExpressionEmpty()`, `getSelectedFormat()`.

## 3b. `CalculatorViewModelFactory` / `InjectorUtils`
- `CalculatorViewModelFactory(expressionRepository, tokensRepository, resultFormatsRepository, perUnitsRepository, prefRepository, utilityRepository, context: Context)`; create() passes all 7 through.
- `InjectorUtils.provideCalculatorViewModelFactory(context: Context)` (was no-arg): additionally `PrefRepository.getInstance(context)` and `UtilityRepository.getInstance()`. The Activity calls it with `baseContext`.

---

## 4. `ExpressionRepository` - one NEW method (everything else byte-identical to master incl. all documented quirks)

```kotlin
fun addToExpressionTimeUnit(elementType: TokenType): Boolean {
    var tokenValue = 1.toBigDecimal()
    if (tokensList.isNotEmpty() && tokensList.last().type == TokenType.NUMBER) {
        tokenValue = tokensList.last().value
    }
    return addToExpression(Token(type = elementType, tokenValue))
}
```
Purpose: "smart plural". `Token` (branch) now carries `val value: BigDecimal`, and its `init` appends `'s'` to `strRepresentation` for time-keyword tokens whose `value.compareTo(BigDecimal.ONE) != 0` (so `2 -> "Hours"`, `0.5 -> "Hours"`, `1 -> "Hour"`). This method peeks at the trailing NUMBER token's `value` so the keyword being typed pluralizes to match; defaults to 1 (singular) when the expression is empty or doesn't end in a NUMBER. Validation/evaluation semantics are unchanged (it funnels into `addToExpression`, so a keyword still returns "evaluate iff legally appended").

Dependency note (lexer-tokens area, summarized because the repo files consume it): `Token(type, value: BigDecimal, strRepresentation = "")` with secondary ctor `(type, value)` setting `strRepresentation = type.value`; every Token construction site app-wide now passes a value (digit buttons pass the digit, operators/DOT pass 1, lexer NUMBER passes the parsed regex group, lexer time-keywords inherit the preceding NUMBER token's value, TimeConverter passes the computed per-unit quantity - so converted RESULTS pluralize correctly, e.g. "2 Hours 30 Minutes"). The lexer consumes `tmpToken.length()` characters, so a pluralized "Hours" (5 chars) round-trips through `String.toTokens()` when preceded by a non-1 number.

## 5. `TokensRepository` - NEW `fun isEmpty() = length() == 0` (currently dead code; the VM uses `isNullOrEmpty()` on the LiveData value instead). Whitespace-only change to `getTokens()`.

## 6. `ResultFormatsRepository` - format catalogue changed: 23 -> 24 entries
- Entry #3 `"Year Month Day Minute"` (preview `"1 Year 2 Month 3 Day 4 Minute"`) is REPLACED by `"Year Month Day Hour"` (preview `"1 Year 2 Month 3 Day 4 Hour"`).
- A NEW entry `"Year Month Day Hour Minute"` (preview `"1 Year 2 Month 3 Day 4 Hour 5 Minute"`) is inserted immediately after, at index 4.
- Every later index shifts +1: default selected `"Hour Minute"` is now index 18 (was 17); `"All Units"` is index 23. Default selection mechanism unchanged (`.isSelected = true` on the Hour Minute add; `getSelectedResulFormat()` still lateinit-throws if none selected).
- All other behavior (`setSelectedFormat` not republishing the list, `updateFormatsWithPreview`, postValue in `setTokens`, the "Month Day" no-numbers preview quirk, the "1 Day 1 Hour" quirk) unchanged.

## 7. `PerUnitsRepository`, `PerUnit`, `PerUnits`, `ResultFormat`, `ResultFormats`, `TokenType`, `CheckErrorsInExpression` - UNCHANGED on the branch (defaults still 25 / "USD" / "10 Hour"; timeInterval still never used in the math; `units[0]` indexing still present - but see the zero-result engine change below which de-fangs the zero crash).

---

## 8. Cross-cutting engine/UI changes that alter what the state layer stores/publishes (other agents own the files; listed here because repository outputs change)

a) **Zero result now renders as `0 <last format unit>` instead of blank** (`TimeConverter.convertTokensToTokensWithFormat`): a new `initialValueIsZero = (convertTokensToMScec(input) == 0)` flag is threaded into `addTimeUnitToResultAndGetReminder`; when the LAST format unit would be suppressed as zero, it now emits `[NUMBER("0"), <unit value=ZERO>]` if the total was zero. Consequences for state: `tokensRepository` never holds an empty list for a zero (or empty/ERROR-token, since `convertTokensToMScec` ignores ERROR -> total 0) evaluation result; per-unit `units[0]` no longer crashes on zero results (it computes amount x 0); the displayed unit pluralizes ("0 Minutes", since 0 != 1).

b) **Theme-aware rendering**: `Tokens.toSpannableString(context)` / `toLightSpannableString(context)` now require a Context; color helpers resolve resources instead of hardcoded hex: expression keywords -> `R.color.colorExpressionTime` (light `#33691e` via colorTimeBtns / dark `#53654D`), result keywords -> `R.color.colorResultTime` (light `#567749`, dark `#727C6E` - note: no longer `#4c992e`), result numbers/operators -> `R.color.colorResultNums` (light `#CC474646`, dark `#939292` - no longer `#807e7e`), and the gray helper now ALSO applies 0.7f relative size (master rendered gray at full size). Error red unchanged.

c) Disabled Per/Formats buttons render at alpha **0.2** (master: 0.5) and also `isClickable = false`.

d) `RvAdapterResultFormats(viewModel, context)` gains a context param; `RvAdapterPer` resolves its colors from the item view's context. Row text formats otherwise unchanged (header "<amount> <unitName> per <Unit> in the interval", value `setScale(16, HALF_UP).stripTrailingZeros().toPlainString() + " <unitName>"`).

---

## 9. Verification of the commit claim "All states of app saves now without issues (after state change and activity destroy)"

Mechanisms, in full:
1. ViewModel-scoped state (formats/per overlay flags, tempResultInMsec, per-button flag) moved to the process-scoped `UtilityRepository` singleton -> survives Activity AND ViewModel destruction (theme switch via `AppCompatDelegate.setDefaultNightMode` recreates the Activity; "Don't keep activities"/low-memory destroy also covered) as long as the process lives.
2. On re-subscribe in `initUI()`, every LiveData observer fires with the current singleton value, re-rendering: expression (`getExpression`), result (`getResultTokens`), formats list + selected format, per rows, all four overlay visibilities (an overlay that was open is re-shown, no animation), and both button-disabled states.
3. `getResultTokens()`'s new side effect re-derives Per/Formats enabled-ness from result emptiness, covering the case where the button flags would otherwise be stale.
4. Theme choice is the one state that must survive PROCESS death (because applying it happens before/around recreation) - hence the only SharedPreferences persistence.
5. The rate prompt is gated by `if (savedInstanceState == null)` so recreation doesn't re-trigger it.

LIMITS of the claim: on process death everything except `PREF_THEME_COLOR` still resets (empty expression/result, "Hour Minute" selected, 25/USD/"10 Hour", both buttons disabled). The Per overlay's amount/unit EditTexts are restored only by Android's built-in view-state mechanism, not by the data layer (the code that would push `PerUnits.amount/unitName` back into the EditTexts is present but commented out in the `getPerUnits` observer).

## Suspected bugs
- UtilityRepository.kt: the `tempResultInMsec` MutableLiveData is never seeded in `init` (all the boolean LiveDatas are). `getTempResultInMsec().value` is null until the first evaluation, and CalculatorViewModel dereferences it with `!!` in updateResultFormats(), updatePerUnits(), updateSettingsForPerUnits() and setSelectedFormat(). Master initialized the cache to an empty Tokens(). It is only saved by the new Formats/Per button gating (both start disabled and getResultTokens() re-disables them when the result is empty); any future code path that calls those methods before an evaluation NPEs.
- ExpressionRepository.addToExpressionTimeUnit + Token: `Token.value` is an immutable `val` set per keystroke, and `mergeNumberToNumber` only concatenates strRepresentation. Typing a multi-digit number digit-by-digit leaves the NUMBER token's value at the FIRST digit, so the plural decision is wrong: typing `1`,`2`,`Hour` yields expression text "12 Hour" (value=1 -> singular) instead of "12 Hours"; conversely typing `1`, then deleting and retyping changes the outcome. Re-lexed strings and converted results pluralize correctly because they carry the full parsed value - only the typed-expression display path is wrong.
- Token init pluralization is not idempotent: `Tokens.clone()` and CalculatorOfTime.setParenthesesToExpression construct `Token(type, value, strRepresentation)` with an ALREADY pluralized strRepresentation ("Hours"), and init appends another 's' when value != 1, producing "Hourss". Currently harmless because cloned keyword strings are replaced by "x <msec>" before display/evaluation, but any new consumer of cloned tokens' strRepresentation will surface it. A Dart port that copies clone semantics must guard against double-pluralizing.
- Lexer round-trip of singular keyword after non-1 number consumed length mismatch: lexing a string like "2 Hour" produces a token whose strRepresentation becomes "Hours" (5 chars) while the source had "Hour" (4 chars); currentPosition advances by token.length() = 5, silently swallowing the next character. Works for strings the app itself generates (always pluralized consistently) but corrupts externally supplied/edge-case strings such as "1 Hours" (advances 4, then lexes a stray 's' into a 5-char ERROR token).
- PrefRepository.kt: a single `editor = pref.edit()` is created at construction and reused for all writes, and `putString` uses synchronous `commit()` on the main thread (StrictMode disk-write violation; master had no prefs at all). Also `getPrefThemeColor()` re-reads disk and re-fires the LiveData on EVERY call while `setPrefThemeColor` publishes via postValue - mixing setValue/postValue on the same LiveData, same out-of-order-emission hazard the port spec already flags for the token repositories.
- CalculatorViewModel.getResultTokens() now mutates state (disables/enables both Per and Formats buttons) inside what looks like a getter; any new caller that merely wants the LiveData will silently toggle button state. Master's getter was pure.
- Carried over unchanged from master (still present on the branch): PerUnits.timeInterval is never used in the unitsPer_Result math; ResultFormats.getSelectedResulFormat() lateinit-throws if nothing is selected; format 'Month Day' initial preview has no numbers and 'Day Hour' preview is '1 Day 1 Hour'; deleteLastTokenOrSymbol leaves a stale result when the expression empties and contains dead lastOperator locals; the DOT-after-time-keyword expression corruption. The per-unit units[0] crash on zero results is incidentally FIXED by the TimeConverter zero-result change (zero now yields [NUMBER('0'), unit] instead of an empty list), but an empty/ERROR tempResultInMsec also converts to '0 <unit>' now - an ERROR expression displays as '0 <unit>' rather than blanking, which may or may not be intended.
- CalculatorViewModel constructor stores a `context: Context` that is never used (and holding an Activity-supplied baseContext in a ViewModel is a leak smell; here it is baseContext so benign, but the parameter is dead weight - the Flutter port should drop it).

## Flutter porting notes
- lib/data/repositories.dart - add a PrefRepository equivalent backed by shared_preferences: key 'PREF_THEME_COLOR' (String '0'|'1'|'2', default '0', write-through on every change - `await prefs.setString(...)` matches the Kotlin synchronous commit closely enough). Expose it as a LiveData<String>/ValueListenable<String> seeded from disk at startup (read before runApp or via an async init), mapping '0'->ThemeMode.system, '1'->ThemeMode.light, '2'->ThemeMode.dark, anything else->system. This is the ONLY new disk persistence on the branch.
- lib/state/calculator_model.dart - the central Android change (moving overlay flags + tempResultInMsec + button gating out of the Activity-scoped ViewModel into a process singleton UtilityRepository) is ALREADY structurally satisfied here: CalculatorModel is a process singleton holding tempResultInMsec and the flags, exactly as the port spec's 'design away the stale-cache bug' note anticipated. No restructuring needed; you may optionally split a UtilityRepository class for 1:1 parity, but it buys nothing in Flutter.
- lib/state/calculator_model.dart - add the NEW flags and methods: _isFormatsViewButtonDisabled (initial true; the Formats button is now gated exactly like Per - disabled until a result exists, re-disabled by clearAll() and sendResultToExpression(), enabled at the end of _evaluateExpression()); _isSupportAppLayoutVisible and _isSettingsLayoutVisible overlay flags with getters/setters; isResultEmpty() => resultTokens.value.isEmpty; and the master-bug fix where (re)attaching the result listener re-derives both button-disabled flags from isResultEmpty() (in Flutter, do this in the model constructor or screen initState rather than inside the resultTokens getter to avoid the Kotlin getter-with-side-effect smell). updatePerUnits/updateSettingsForPerUnits keep gating on the per-button flag only.
- lib/data/repositories.dart (ExpressionRepository) - add addToExpressionTimeUnit(TokenType elementType): tokenValue = last token is NUMBER ? lastToken.value : BigDecimal.one; return addToExpression(Token(elementType, tokenValue)). Requires engine/token.dart to gain the branch's `value: BigDecimal` field with the init-time plural rule (time keyword && value.compareTo(one) != 0 -> strRepresentation += 's') - coordinate with the lexer-tokens owner; decide whether to replicate or fix the two plural bugs (first-digit-only value on merged numbers; double-'s' on clone with explicit strRepresentation).
- lib/state/calculator_model.dart + lib/ui/calculator_screen.dart - route the 8 time-unit keys through model.addToExpressionTimeUnit(TokenType.year/.month/.week/.day/.hour/.minute/.second/.msecond) instead of addToExpression(Token(keyword)). clearOneLastSymbol needs no Context param in Dart (the Kotlin context was only for a log line).
- lib/data/repositories.dart (ResultFormatsRepository._fillRepository) - update the catalogue from 23 to 24 entries: replace 'Year Month Day Minute'/'1 Year 2 Month 3 Day 4 Minute' (index 3) with 'Year Month Day Hour'/'1 Year 2 Month 3 Day 4 Hour' and insert 'Year Month Day Hour Minute'/'1 Year 2 Month 3 Day 4 Hour 5 Minute' at index 4; 'Hour Minute' (still the default selected) moves to index 18, 'All Units' to 23. Update the '23 formats' doc comments in repositories.dart and calculator_model.dart.
- lib/data/repositories.dart (TokensRepository) - optionally add isEmpty() => length() == 0 for parity (dead code on the branch; CalculatorModel can keep using resultTokens.value.isEmpty).
- lib/engine/time_converter.dart (engine owner, but it changes what the repositories publish) - implement the zero-result rule: when the total milliseconds is exactly zero, the LAST format unit emits [NUMBER('0'), unit] instead of an empty list. This makes the existing units.isEmpty guard in PerUnitsRepository.updatePerUnitsWithPreview mostly moot (keep it anyway) and changes the blank-result behavior the formats/result UI currently relies on - note ERROR/empty inputs now also render '0 <unit>'.
- lib/ui/theme.dart + lib/ui/spans.dart - the branch makes token colors theme-resolved for dark mode: expression keywords colorExpressionTime (light #33691E / dark #53654D), result keywords colorResultTime (light #567749 - NO LONGER #4C992E - / dark #727C6E), result numbers+operators colorResultNums (light #CC474646 / dark #939292), and the gray 'light' span now renders at 0.7x size (was full size). Spans need a BuildContext/ColorScheme instead of the current hardcoded AppColors constants. Disabled Per/Formats buttons: alpha 0.2 (was 0.5) and non-tappable.
- lib/main.dart - wire MaterialApp(themeMode:) to the persisted theme ValueListenable and provide a darkTheme built from the values-night palette; add the Settings overlay (three radio options writing '0'/'1'/'2') and Support overlay open/closed flags to back-button handling order: formats -> per -> support -> settings -> background, mirroring onBackPressed.
- No other persistence to add: expression, result, selected format and per-unit params intentionally remain process-lifetime only on the branch (they reset on process death; only theme survives). The data-layer.md porting note suggesting shared_preferences for selected format/per-unit settings remains an optional improvement, NOT something the branch did. Purchase/support state is never stored locally (Play Billing queryPurchases on resume is the source of truth) - in Flutter that stays inside lib/services/monetization.dart.
