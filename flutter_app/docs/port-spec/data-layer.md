# data-layer

## Summary
The data/state layer consists of four in-memory singleton repositories (TokensRepository for the result, ExpressionRepository for the input expression, ResultFormatsRepository for the 23 selectable output formats, PerUnitsRepository for the "amount per time unit" feature), each exposing MutableLiveData of a mutable ArrayList subclass that is mutated in place and re-published. CalculatorViewModel (built via CalculatorViewModelFactory from InjectorUtils, which wires the four singletons) is the single UI facade: it validates/appends tokens to the expression, re-evaluates the expression into a cached milliseconds token (tempResultInMsec) on a background coroutine, converts that into the currently selected ResultFormat for display, and recomputes per-unit money/distance previews. Nothing is persisted to disk - all state lives in process-scope singletons plus activity-scoped ViewModel flags.

## Detailed spec
# Time Calculator - Data/State Layer Specification

All paths relative to `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/`.

---

## 0. Foundation types (needed to understand repository semantics)

### 0.1 `TokenType` (`data/tokens/TokenType.kt`) - sealed class, one object per type, each with a `value: String`:

| Type | `value` (verbatim) | Notes |
|---|---|---|
| PLUS | `"+"` | |
| MINUS | `"−"` | **U+2212 MINUS SIGN, not ASCII hyphen** |
| PARENTHESESLEFT | `"("` | engine-only, never typed by user |
| PARENTHESESRIGHT | `")"` | engine-only |
| MULTIPLY | `"×"` | U+00D7 |
| DIVIDE | `"÷"` | U+00F7 |
| NUMBER | `"0.0"` | placeholder; real value lives in `Token.strRepresentation` |
| YEAR | `"Year"` | |
| MONTH | `"Month"` | |
| WEEK | `"Week"` | |
| DAY | `"Day"` | |
| HOUR | `"Hour"` | |
| MINUTE | `"Minute"` | |
| SECOND | `"Second"` | |
| MSECOND | `"MSecond"` | |
| ERROR | `"ERROR"` | |
| DOT | `"."` | |

Helpers: `isOperator()` = PLUS|MINUS|DIVIDE|MULTIPLY. `isTimeKeyword()` = YEAR|WEEK|MONTH|DAY|HOUR|MINUTE|SECOND|MSECOND.

### 0.2 `Token` (`data/tokens/Token.kt`)
`class Token(val type: TokenType, var strRepresentation: String = "")`; secondary ctor `Token(type)` sets `strRepresentation = type.value`.
- `addDotToNumber()`: appends `"."` only if `strRepresentation` does not already contain `"."`.
- `length()` = `strRepresentation.length`.
- `mergeNumberToNumber(token)`: string-concatenates `token.strRepresentation` onto this one (digit append).
- `deleteOneLastSymbolInNumber()`: only for type NUMBER, drops last char if length > 0.
- `toTokens()`: wraps this token into a new `Tokens` list.

### 0.3 `Tokens` (`data/tokens/Tokens.kt`) - `ArrayList<Token>`, `Cloneable`
- `clone()`: deep copy (new Token per element).
- `toString()`: concatenation with operator substitution PLUS→`"+"`, MINUS→`"-"`, DIVIDE→`"/"`, MULTIPLY→`"*"`, everything else → `strRepresentation`, **no spaces** (this string is fed to exp4j).
- `toStringWithSpaces()`: same substitution but each piece prefixed with a space (operators become `" +"` etc., others `" " + strRepresentation`), then `.trim()`.
- `toSpannableString()`: NUMBER plain; time keywords space-padded, colored **#33691e** at relative size **0.7f**; operators space-padded plain; ERROR space-padded **red** (`Color.parseColor("RED")`) at 0.7f.
- `toLightSpannableString()`: NUMBER gray **#807e7e**; time keywords light-green **#4c992e** 0.7f; operators gray #807e7e; ERROR red 0.7f.
- `isSimpleArithmeticExpression()`: true iff no time-keyword tokens present.
- `removeLastToken()`: removes element at `lastIndex`, returns `this`.
- `findLastNearestOperatorToken()`: scans backward, returns first token whose type `isOperator()`, else null.
- `findTokenBeforeLastNearestOperatorToken()`: token at index (operatorIndex − 1), null if operator is at index 0 or no operator.
- `findTokenBeforeTokenBeforeLastNearestOperatorToken()`: token at (operatorIndex − 2), null if operatorIndex ≤ 1 or no operator.
- `isLastExpressionBlockHasTimeKeyword()`: scan backward to the nearest **PLUS or MINUS** (MULTIPLY/DIVIDE do NOT bound a block); clamp start to 0; then scan forward from there - true iff any token `isTimeKeyword()`.

### 0.4 String/lexer extensions (`internal/extension/Extension.kt`, `engine/lexer/LexicalAnalyzer.kt`)
- `String.toTokens()` = `LexicalAnalyzer.analyze(this)`: removes ALL spaces, then greedily tokenizes: digits/dots via regex `-?[\d\.]+` → NUMBER; letters matched by prefix in this order: `Year`, `Month`, `Week`, `Day`, `Hour`, `Minute`, `Second`, `MSecond` (case-sensitive); operator chars `+ − × ÷ - / *` → operator tokens; anything else → ERROR token (`"ERROR"`, length 5 consumed).
- `String.toToken()` = `analyze(this).last()`.
- Color helpers used by spannables: green `#33691e` (0.7f), light-green `#4c992e` (0.7f), gray `#807e7e` (full size), red `Color.parseColor("RED")` (0.7f).

### 0.5 Time constants (`engine/calculator/CalculatorOfTimeConst.kt`) - all `BigDecimal`:
- `MILLISECONDS_IN_SECOND = 1000`
- `SECONDS_IN_MINUTE = 60`, `MINUTES_IN_HOUR = 60`, `HOURS_IN_DAY = 24`, `DAYS_IN_WEEK = 7`, `DAYS_IN_MONTH = 30`, `DAYS_IN_YEAR = 365`
- Derived: `MILLISECONDS_IN_MINUTE = 60 000`; `MILLISECONDS_IN_HOUR = 3 600 000`; `MILLISECONDS_IN_DAY = 86 400 000`; `MILLISECONDS_IN_WEEK = 604 800 000`; `MILLISECONDS_IN_MONTH = 2 592 000 000`; `MILLISECONDS_IN_YEAR = 31 536 000 000`.
- So 1 Month ≡ 30 days exactly, 1 Year ≡ 365 days exactly.

### 0.6 `TimeConverter.convertTokensToTokensWithFormat(tokensToConvert, tokensFormat, removeZeroUnits = true)` (`utilites/TimeConverter.kt:691`)
This is THE conversion used everywhere (result display, format previews, per-unit math):
1. `reminderInMsec = convertTokensToMScec(tokensToConvert)`: walks tokens; NUMBER sets `currentNumber`; each time keyword adds `currentNumber × MILLISECONDS_IN_<unit>` (MSECOND adds raw `currentNumber`). Operators/ERROR are ignored. Empty input → 0.
2. For each unit token in `tokensFormat`, in order, via `addTimeUnitToResultAndGetReminder`:
   - `currentResult = reminderInMsec.setScale(26, HALF_UP) / MILLISECONDS_IN_<unit>` (MSECOND divides by nothing - returns raw msec; unknown types yield 0).
   - If it is the **last** format unit: emit `[NUMBER(currentResult.setScale(7, HALF_UP).stripTrailingZeros().toPlainString()), <unit>]` **unless** `currentResult == 0 && removeZeroUnits` (then emit nothing). Last unit keeps decimals.
   - Otherwise: `floor = currentResult.setScale(0, DOWN)`; emit `[NUMBER(floor.toPlainString()), <unit>]` unless `floor == 0 && removeZeroUnits`; new remainder = fractional part converted back to msec (`convertPartOfUnitToMScec`; note: **no MSECOND case** there → remainder 0), then `.setScale(7, HALF_UP).stripTrailingZeros()`.
3. Returns the accumulated `Tokens`. **A zero total with `removeZeroUnits=true` returns an EMPTY Tokens list.**

### 0.7 `CalculatorOfTime.evaluate(tokens)` (`engine/calculator/CalculatorOfTime.kt`)
- Clones input. If `isSimpleArithmeticExpression()` → evaluate directly; else wrap each number-block in parentheses (`setParenthesesToExpression`) and rewrite via `TimeConverter.convertExpressionToMsecs` (each time keyword becomes `× <msecPerUnit>`, each NUMBER is prefixed with `+` - yes, a leading `+` before every number), then evaluate.
- `evaluateSimpleArithmeticExpression`: drops one trailing operator; drops a trailing `<operator> )` pair; if string empty returns empty `Tokens`; otherwise builds the `toString()` string and evaluates with **exp4j** (`ExpressionBuilder(txt).build().evaluate()` → Double → `toBigDecimal()` → `toString()`). Success → `[NUMBER(result), MSECOND]` (result is ALWAYS interpreted as milliseconds, even for pure arithmetic like `2+3`). Any exception → `[ERROR("ERROR")]`.

### 0.8 `isErrorsInExpression(tokenForAdd, expression)` (`engine/expression/CheckErrorsInExpression.kt`) - returns **true = reject**:
1. empty expression + NUMBER → false (allowed).
2. empty expression + (time keyword | operator | DOT) → true.
3. last token NUMBER + (PLUS|MINUS) + last block has NO time keyword → true (you cannot add/subtract bare numbers).
4. operator + operator → true.
5. operator + DOT → true.
6. operator + time keyword → true.
7. time keyword + time keyword → true.
8. size > 1 ∧ last block has time keyword ∧ second-to-last token is MULTIPLY|DIVIDE ∧ adding a time keyword → true.
9. otherwise false (allowed).

---

## 1. Repositories

All four repositories use the identical thread-safe lazy singleton pattern: `@Volatile private var instance: X? = null`; `fun getInstance() = instance ?: synchronized(this) { instance ?: X().also { instance = it } }`. ResultFormatsRepository and PerUnitsRepository additionally call `it.fillRepository()` inside the `also` block (once per process, before assigning `instance`). They are pure in-memory JVM singletons - **no persistence whatsoever**.

A common idiom in all of them: the backing list (an `ArrayList` subclass) is mutated in place and the SAME instance is re-assigned to `MutableLiveData.value` to trigger observers.

### 1.1 `TokensRepository` (`data/repository/TokensRepository.kt`) - holds the RESULT tokens (the converted result shown under the expression)
- State: `private var tokensList = Tokens()`; `private val tokens = MutableLiveData<Tokens>()`; `init { tokens.value = tokensList }`.
- `addToken(token: Token)`: `tokensList.add(token); tokens.value = tokensList` (synchronous setValue). (Exposed via VM `addToken`, but no UI caller.)
- `length(): Int = tokensList.lastIndex + 1` (i.e. size).
- `getTokens() = tokens as LiveData<Tokens>`.
- `setTokens(newTokens: Tokens)`: replaces backing list reference, publishes with **`postValue`** (async main-thread post; comment says "for executing in background thread").

### 1.2 `ExpressionRepository` (`data/repository/ExpressionRepository.kt`) - holds the INPUT expression tokens
Same fields/init/singleton as above.

- `addToExpression(tokenForAdd: Token): Boolean` - the return value means "caller must (re)evaluate the expression now":
  - **Operators (PLUS, MINUS, DIVIDE, MULTIPLY)**: `tryToAddToExpression(tokenForAdd)` (validated add), then **return false** - typing an operator never triggers evaluation.
  - Snapshot (computed BEFORE any add): `lastToken` (null if empty), `lastOperator = findLastNearestOperatorToken()`, `tokenBeforeLastOperator`, `lastTokenBeforeTokenBeforeLastOperator`.
  - **DOT or NUMBER**:
    - If `lastToken != null && lastToken.type == NUMBER`:
      - DOT: `tokensList.last().addDotToNumber()` (merge dot into the number, idempotent w.r.t. existing dot); `tokens.value = tokensList`; **return false**.
      - NUMBER: `tokensList.last().mergeNumberToNumber(tokenForAdd)` (digit concat); `tokens.value = tokensList`; **return** the "live-division re-eval" condition:
        `isLastExpressionBlockHasTimeKeyword() && ((lastOperator is DIVIDE|MULTIPLY && tokenBeforeLastOperator != null && tokenBeforeLastOperator.type != NUMBER) || (lastOperator is DIVIDE|MULTIPLY && tokenBeforeLastOperator.type == NUMBER && lastTokenBeforeTokenBeforeLastOperator is DIVIDE|MULTIPLY))`.
        Intuition: while the user types the divisor/multiplier digits of a `<time-expr> ÷/× n` block, every digit re-evaluates.
    - Else (last token is not a NUMBER, or expression empty): `tryToAddToExpression(tokenForAdd)` (**return value ignored**); **return** the same condition as above (with `isLastExpressionBlockHasTimeKeyword()` evaluated AFTER the add but the operator snapshots from BEFORE).
  - **Anything else (time keywords)**: `return tryToAddToExpression(tokenForAdd)` - evaluate iff the keyword was legally appended.
- `private tryToAddToExpression(tokenForAdd): Boolean`: if `!isErrorsInExpression(tokenForAdd, tokensList)` → append, `tokens.value = tokensList`, true; else false (silently dropped - invalid keystrokes are simply ignored).
- `getExpression() = tokens as LiveData<Tokens>`.
- `setTokens(newTokens)`: replace reference + `postValue`.
- `deleteLastTokenOrSymbol(): Boolean` (return = "re-evaluate now"):
  - (Computes `lastOperator`/`tokenBeforeLastOperator` - **dead code, never used**.)
  - If empty → return false.
  - If last token type != NUMBER → `removeLastToken()` (whole token, e.g. an entire `Hour` keyword or operator disappears).
  - Else (NUMBER) → `deleteOneLastSymbolInNumber()` (drop one character, including a dot); if its `strRepresentation` becomes `""` remove the token.
  - `tokens.value = tokensList` (synchronous).
  - Return `isLastExpressionBlockHasTimeKeyword() || (newLastToken != null && newLastToken.type != NUMBER)` where `newLastToken` is the post-delete last token. (Empty expression after delete → returns false → result is NOT recalculated.)

### 1.3 `ResultFormatsRepository` (`data/repository/ResultFormatsRepository.kt`)
- State: `private var resultFormatsList = ResultFormats()`; `private val resultFormats = MutableLiveData<ResultFormats>()`; `private lateinit var selectedResFormat: ResultFormat`; `private val selectedResultFormats = MutableLiveData<ResultFormat>()`. `init { resultFormats.value = resultFormatsList }` (selected LiveData NOT initialized until `fillRepository`).
- `addResultFormat(resultFormat): ResultFormat`: append, `resultFormats.value = list`, return the added format (used for `.isSelected = true` chaining).
- `length() = lastIndex + 1`.
- `getResultFormats() = resultFormats as LiveData<ResultFormats>`.
- `getSelectedFormat() = selectedResultFormats as LiveData<ResultFormat>`.
- `setSelectedFormat(position: Int): LiveData<ResultFormat>`: `selectedResFormat = resultFormatsList.setSelection(position)` (clears every `isSelected`, sets index `position` true, returns it); `selectedResultFormats.value = selectedResFormat`; returns the LiveData. Note: it does **not** republish `resultFormats`.
- `updateFormatsWithPreview(resultTokens: Tokens)`: for every format, `convertedResultTokens = TimeConverter.convertTokensToTokensWithFormat(resultTokens, format.formatTokens)`; then `resultFormats.value = list` (UI rebuilds the formats RecyclerView). Called with the cached milliseconds result so each list row previews the CURRENT result in that format.
- `setTokens(newResultFormats: ResultFormats)`: replace + `postValue` (no caller in app code).
- `private fillRepository()` (invoked exactly once from `getInstance`): adds the default formats below, then `selectedResFormat = resultFormatsList.getSelectedResulFormat(); selectedResultFormats.value = selectedResFormat`.

#### DEFAULT RESULT FORMATS (verbatim, in insertion order; "display name" = `textPresentationOfTokens`, derived from `formatTokens.toStringWithSpaces()` unless explicitly given):

| # | formatTokens (lexed from) | initial convertedResultTokens (lexed from) | display name | selected |
|---|---|---|---|---|
| 0 | `"Year"` | `"1 Year"` | `Year` | |
| 1 | `"Year Month"` | `"1 Year 2 Month"` | `Year Month` | |
| 2 | `"Year Month Day"` | `"1 Year 2 Month 3 Day"` | `Year Month Day` | |
| 3 | `"Year Month Day Minute"` | `"1 Year 2 Month 3 Day 4 Minute"` | `Year Month Day Minute` | |
| 4 | `"Month"` | `"1 Month"` | `Month` | |
| 5 | `"Month Day"` | `"Month Day"` (no numbers!) | `Month Day` | |
| 6 | `"Month Day Hour"` | `"1 Month 2 Day 3 Hour"` | `Month Day Hour` | |
| 7 | `"Month Day Hour Minute"` | `"1 Month 2 Day 3 Hour 4 Minute"` | `Month Day Hour Minute` | |
| 8 | `"Month Day Hour Minute Second"` | `"1 Month 2 Day 3 Hour 4 Minute 5 Second"` | `Month Day Hour Minute Second` | |
| 9 | `"Month Week"` | `"1 Month 2 Week"` | `Month Week` | |
| 10 | `"Week"` | `"1 Week"` | `Week` | |
| 11 | `"Week Day"` | `"1 Week 2 Day"` | `Week Day` | |
| 12 | `"Day"` | `"1 Day"` | `Day` | |
| 13 | `"Day Hour"` | `"1 Day 1 Hour"` (note: 1,1 not 1,2) | `Day Hour` | |
| 14 | `"Day Hour Minute"` | `"1 Day 2 Hour 3 Minute"` | `Day Hour Minute` | |
| 15 | `"Day Hour Minute Second"` | `"1 Day 2 Hour 3 Minute 4 Second"` | `Day Hour Minute Second` | |
| 16 | `"Hour"` | `"1 Hour"` | `Hour` | |
| 17 | `"Hour Minute"` | `"1 Hour 2 Minute"` | `Hour Minute` | **YES (default)** |
| 18 | `"Hour Minute Second"` | `"1 Hour 2 Minute 3 Second"` | `Hour Minute Second` | |
| 19 | `"Minute"` | `"1 Minute"` | `Minute` | |
| 20 | `"Minute Second"` | `"1 Minute 2 Second"` | `Minute Second` | |
| 21 | `"Second"` | `"1 Second"` | `Second` | |
| 22 | `"Year Month Week Day Hour Minute Second MSecond"` | `"1 Year 2 Month 3 Week 4 Day 5 Hour 6 Minute 7 Second 8 MSecond"` | **`All Units`** (explicit 3rd-arg label) | |

23 formats total. The initial `convertedResultTokens` are only placeholder previews until the first `updateFormatsWithPreview` overwrites them.

### 1.4 `ResultFormat` (`data/resultFormat/ResultFormat.kt`)
`class ResultFormat(val formatTokens: Tokens, var convertedResultTokens: Tokens)`; `var isSelected = false`; `var textPresentationOfTokens: String` initialized in `init` to `formatTokens.toStringWithSpaces()`. Secondary constructor `(formatTokens, convertedResultTokens, exactlyTextPresentationOfTokens: String)` overrides `textPresentationOfTokens` (used only for "All Units").

### 1.5 `ResultFormats` (`data/resultFormat/ResultFormats.kt`) - `ArrayList<ResultFormat>`
- `setSelection(position): ResultFormat`: sets `isSelected = false` on all elements, then `this[position].isSelected = true`, returns `this[position]` (single-selection invariant).
- `getSelectedResulFormat(): ResultFormat` (sic, typo): scans all, returns the LAST element with `isSelected == true`; uses a `lateinit var` local → throws `UninitializedPropertyAccessException` if nothing is selected.

### 1.6 `PerUnitsRepository` (`data/repository/PerUnitsRepository.kt`)
- State: `private var perUnitsList = PerUnits(25.toBigDecimal(), "USD", "10 Hour".toTokens())` - defaults: amount = 25, unitName = "USD", timeInterval = tokens of `10 Hour`. `private val perUnits = MutableLiveData<PerUnits>()`; `init { perUnits.value = perUnitsList }`.
- `addPerUnit(perUnit): PerUnit`: append + republish + return.
- `setParams(amount: BigDecimal, unitName: String, timeInterval: Tokens)`: mutates the three `PerUnits` container fields, republishes (`value =`).
- `length() = lastIndex + 1`.
- `getPerUnits() = perUnits as LiveData<PerUnits>`.
- `updatePerUnitsWithPreview(resultTokens: Tokens)`: for each `perUnitElement`:
  - `units = TimeConverter.convertTokensToTokensWithFormat(resultTokens, perUnitElement.timeUnit.toTokens())` - single-unit format, so normally returns `[NUMBER(value-in-that-unit), <unit>]` where the number keeps up to 7 decimals (HALF_UP, trailing zeros stripped).
  - `perUnitElement.unitsPer_Result = perUnitsList.amount * units[0].strRepresentation.toBigDecimal()` - i.e. **result = amount × (total time expressed in that unit)**; the amount is interpreted as "per 1 unit". **`perUnitsList.timeInterval` is never used in this math.**
  - Then `perUnits.value = perUnitsList`.
- `private fillRepository()` (once from `getInstance`): `setParams(25.toBigDecimal(), "USD", "10 Hour".toTokens())`, then adds PerUnit entries in this exact order (each `"<X>".toToken()`):
  1. `Hour` 2. `Minute` 3. `Second` 4. `Day` 5. `Week` 6. `Month` 7. `Year` 8. `MSecond`

### 1.7 `PerUnit` (`data/perUnit/PerUnit.kt`)
`class PerUnit(val timeUnit: Token)`; `var unitsPer_Result: BigDecimal = BigDecimal.ZERO`.

### 1.8 `PerUnits` (`data/perUnit/PerUnits.kt`)
`class PerUnits(var amount: BigDecimal, var unitName: String, var timeInterval: Tokens) : ArrayList<PerUnit>()` - a list of PerUnit rows plus three shared mutable params.

---

## 2. DI wiring

### 2.1 `InjectorUtils` (`utilites/InjectorUtils.kt`) - Kotlin `object`
`provideCalculatorViewModelFactory()`: fetches all four singletons via `getInstance()` and returns `CalculatorViewModelFactory(expressionRepository, tokensRepository, resultFormatsRepository, perUnitsRepository)` - note parameter order: **expression first, tokens second**.

### 2.2 `CalculatorViewModelFactory` (`ui/calculator/CalculatorViewModelFactory.kt`)
Extends `ViewModelProvider.NewInstanceFactory`; `create()` ignores `modelClass` and returns `CalculatorViewModel(expressionRepository, tokensRepository, resultFormatsRepository, perUnitsRepository) as T` (unchecked cast).

---

## 3. `CalculatorViewModel` (`ui/calculator/CalculatorViewModel.kt`) - full public surface

### Internal state (activity/ViewModel-scoped, NOT in repositories):
- `isInFormatsChooseModeRepository: Boolean = false` + `isInFormatsChooseMode = MutableLiveData<Boolean>()` - is the format-chooser overlay open.
- `isInPerViewModeRepository: Boolean = false` + `isInPerViewMode = MutableLiveData<Boolean>()` - is the "Per" overlay open.
- `tempResultInMsec = Tokens()` - cache of the last `CalculatorOfTime.evaluate` output (normally `[NUMBER(msecs), MSECOND]`, or `[ERROR]`, or empty). All format previews, per-unit math, and format switching read this cache, NOT the displayed result.
- `isPerViewButtonDisabledRepository: Boolean = true` + `isPerViewButtonDisabled = MutableLiveData<Boolean>()` - Per button gating; starts disabled.
- `init` publishes all three booleans.

### Public methods (UI callers in `ui/calculator/CalculatorActivity.kt`, `RvAdapterResultFormats.kt`, `RvAdapterPer.kt` noted):

| Method | Semantics | UI caller |
|---|---|---|
| `getResultTokens(): LiveData<Tokens>` | `tokensRepository.getTokens()` - the formatted result | observed: renders `tvOnlineResult` (light spannable), `labelTimeIntervalAmount` (normal spannable), and recreates `RvAdapterPer` |
| `getResultFormats(): LiveData<ResultFormats>` | repo passthrough | observed: recreates `RvAdapterResultFormats`; adapter reads `textPresentationOfTokens` (green) and `convertedResultTokens.toLightSpannableString()` per row |
| `getPerUnits(): LiveData<PerUnits>` | repo passthrough | observed: recreates `RvAdapterPer`; adapter row header = `"<amount> <unitName> per <Unit> in the interval"`, row value = `unitsPer_Result.setScale(16, HALF_UP).stripTrailingZeros().toPlainString() + " <unitName>"` |
| `addToresultFormats(resultFormat)` | `resultFormatsRepository.addResultFormat(...)` | none (dead API) |
| `addToken(token)` | `tokensRepository.addToken(...)` | none (dead API) |
| `getIsFormatsLayoutVisible(): LiveData<Boolean>` | exposes formats-overlay flag | observed: toggles `formatsLayout` visibility; read synchronously in `onBackPressed` |
| `getIsPerLayoutVisible(): LiveData<Boolean>` | exposes per-overlay flag | observed: toggles `perLayout`; read in `onBackPressed` |
| `setIsFormatsLayoutVisible(visible)` | sets backing field + LiveData (setValue) | Formats button (true), closeFormatsLayout (false) |
| `setIsPerLayoutVisible(visible)` | same for Per overlay | Per button (true), closePerLayout (false) |
| `getIsPerViewButtonDisabled(): LiveData<Boolean>` | Per button gating | observed: disables button & alpha 0.5 when true, else enabled & alpha 1.0 |
| `setIsPerViewButtonDisabled(visible)` | sets backing field + LiveData | internal + (public) |
| `addToExpression(element: Token)` | `if (expressionRepository.addToExpression(element)) { viewModelScope.coroutineContext.cancelChildren(); viewModelScope.launch { evaluateExpression() } }` - i.e. token is validated/merged into the expression by the repo; if the repo says "evaluate", any in-flight evaluation is cancelled and a new one starts | every calculator key: digits 0-9 as `Token(NUMBER, "0"… "9")`, `buttonComma` → `Token(DOT)`, Year/Month/Week/Day/Hour/Minute/Second/Msec → keyword tokens, ×, ÷, −, + → operator tokens |
| `getExpression(): LiveData<Tokens>` | repo passthrough | observed: `tvExpressionField.text = it.toSpannableString()` |
| `isExpressionEmpty(): Boolean` | `getExpression().value.isNullOrEmpty()` | long-press delete guard |
| `clearAll()` | `tokensRepository.setTokens(Tokens()); expressionRepository.setTokens(Tokens()); setIsPerViewButtonDisabled(true)` - wipes both expression and result, disables Per | long-press on delete button (after reveal animation) |
| `clearOneLastSymbol()` | `if (expressionRepository.deleteLastTokenOrSymbol()) { cancelChildren(); launch evaluateExpression() }` | delete (backspace) button |
| `sendResultToExpression()` | if `tokensRepository.length() > 0`: copy result tokens reference into expression repo (`expressionRepository.setTokens(tokensRepository.getTokens().value!!)`), reset result (`tokensRepository.setTokens(Tokens())`), disable Per button | `buttonEqual` ("=") - result becomes the new editable expression |
| `updateResultFormats()` | `resultFormatsRepository.updateFormatsWithPreview(tempResultInMsec)` - refreshes every row's preview to show the current result in that format | Formats button, before opening overlay |
| `updatePerUnits()` | if `!isPerViewButtonDisabledRepository`: `perUnitsRepository.updatePerUnitsWithPreview(tempResultInMsec)` | Per button, before opening overlay |
| `updateSettingsForPerUnits(amount: BigDecimal, unitName: String)` | if `!isPerViewButtonDisabledRepository`: `perUnitsRepository.setParams(amount, unitName, tokensRepository.getTokens().value!!)` (timeInterval := current displayed result tokens) then `updatePerUnitsWithPreview(tempResultInMsec)` | TextWatchers on `etUnitAmount`/`etUnit` (only when both fields non-empty; otherwise rvPer hidden) |
| `getSelectedFormat(): LiveData<ResultFormat>` | repo passthrough | observed: sets `buttonFormats.text = it.textPresentationOfTokens.toHTMLWithLightGreenColor()` and closes formats overlay if open |
| `setSelectedFormat(position: Int): LiveData<ResultFormat>` | `resultFormatsRepository.setSelectedFormat(position)`; then converts `tempResultInMsec` with the new format and `tokensRepository.setTokens(converted)` - the displayed result is re-rendered immediately in the new format; returns the selected-format LiveData | `RvAdapterResultFormats` row click |

### `private suspend fun evaluateExpression()` (the recalculation pipeline):
1. `tempResultInMsec = withContext(Dispatchers.Default) { CalculatorOfTime.evaluate(getExpression().value!!) }` - background-thread evaluation of the WHOLE current expression into `[NUMBER(msec), MSECOND]` / `[ERROR]` / empty.
2. `resultTokens = TimeConverter.convertTokensToTokensWithFormat(tempResultInMsec, resultFormatsRepository.getSelectedFormat().value!!.formatTokens)` - convert to the selected display format (zero components removed; ERROR/empty inputs yield empty output, blanking the result).
3. `tokensRepository.setTokens(resultTokens)` (postValue → UI updates result text and per-unit list).
4. `setIsPerViewButtonDisabled(false)` - Per becomes available after any successful evaluation pass.

### When does typing recalculate? (combining VM + ExpressionRepository rules)
- Operator key: never (added if valid; evaluation deferred).
- Time-keyword key: yes, iff the keyword was legally appended (it completes a `<number> <unit>` pair).
- Digit key merging into an existing number: only in "live division/multiplication" mode - last block contains a time keyword AND the digits being typed are the operand right after a `÷`/`×` (per the two-branch condition in §1.2).
- Digit/DOT starting a new token: token added (if valid), evaluation per the same live-÷/× condition.
- DOT into an existing number: never evaluates.
- Backspace: re-evaluates iff the remaining last block still has a time keyword OR the new last token is a non-NUMBER.

---

## 4. Persistence

**Nothing is persisted to disk.** No SharedPreferences, no database, no files.
- Process-lifetime (singleton repositories): expression tokens, result tokens, all 23 ResultFormat objects incl. which one `isSelected`, PerUnits list + amount/unitName/timeInterval. These survive Activity recreation (rotation) because the singletons outlive the Activity, and the ViewModel survives via `ViewModelProviders.of(this, factory)`.
- ViewModel-lifetime: overlay visibility flags, `tempResultInMsec`, Per-button-disabled flag. Lost on Activity finish/process death; notably `tempResultInMsec` resets to empty `Tokens()` on full ViewModel recreation even though the repos still hold data, so format previews/per-unit math would compute from a zero result until the next evaluation.
- On process death everything resets to defaults: empty expression/result, selected format = `Hour Minute`, per params = 25 / "USD" / `10 Hour`, Per button disabled.

## Suspected bugs
- PerUnitsRepository.kt:64-65 - `units[0]` will throw IndexOutOfBoundsException whenever the evaluated result is zero (or tempResultInMsec is empty/[ERROR]): convertTokensToTokensWithFormat with removeZeroUnits=true returns an EMPTY Tokens list for a zero total, so `units[0].strRepresentation` crashes. Reproduce: get a result of 0 (e.g. '1 Hour - 1 Hour' style), open Per view, type amount+unit.
- PerUnitsRepository.kt:54-71 - `perUnitsList.timeInterval` (the 'per 10 Hour' denominator, also set from the displayed result in CalculatorViewModel.updateSettingsForPerUnits) is NEVER used in the unitsPer_Result calculation. The math is amount × (result expressed in unit), i.e. 'amount per 1 unit'. Either the field is dead or the formula is missing a division by the interval.
- ResultFormatsRepository.kt:104 - default format 'Month Day' has preview tokens "Month Day".toTokens() with no numbers, inconsistent with every other entry (expected "1 Month 2 Day"). Until updateFormatsWithPreview runs, that row's preview renders as just 'Month Day'.
- ResultFormatsRepository.kt:129 - 'Day Hour' preview is "1 Day 1 Hour" while the convention everywhere else is sequential numbering ("1 Day 2 Hour"). Cosmetic inconsistency in initial preview.
- ExpressionRepository.kt:75 - in the DOT/NUMBER else-branch the result of tryToAddToExpression(tokenForAdd) is discarded; the method can return true (triggering evaluation) even when the token was rejected and the expression did not change. Also the operator snapshots (lastOperator etc., lines 44-47) are taken BEFORE the add while isLastExpressionBlockHasTimeKeyword() is computed AFTER it - an inconsistent snapshot.
- ExpressionRepository.kt:50 + CheckErrorsInExpression.kt - pressing DOT when the last token is a time keyword (e.g. expression '5 Hour' then '.') is not rejected by isErrorsInExpression (no rule for timeKeyword+DOT), so a standalone Token(DOT) is appended to the expression; Tokens.toString() then yields e.g. '5*3600000+.' which makes exp4j throw → result becomes ERROR/blank. Likely should be rejected like operator+DOT.
- ExpressionRepository.kt:127-162 deleteLastTokenOrSymbol - returns false when the expression becomes empty (newLastToken == null and no time keyword), so the previously displayed result is left stale on screen after deleting the whole expression; locals lastOperator/tokenBeforeLastOperator (lines 131-132) are computed and never used (dead code).
- ResultFormats.kt:25-35 getSelectedResulFormat() (typo: 'Resul') - uses a lateinit local and throws UninitializedPropertyAccessException if no format has isSelected==true; the whole app depends on fillRepository() marking exactly one ('Hour Minute') as selected. setSelection also doesn't republish the formats LiveData, so list checkmark state (if it were rendered) would go stale.
- CalculatorViewModel.kt:44 + repository singletons - tempResultInMsec lives in the Activity-scoped ViewModel while expression/result live in process-scoped singletons. After the Activity (and its ViewModel) is recreated with the process alive, tempResultInMsec is empty but the old result is still displayed; pressing Formats then shows blank previews and setSelectedFormat blanks the visible result; isPerViewButtonDisabled also resets to true despite a visible result.
- TokensRepository.kt / ExpressionRepository.kt - mixed setValue (addToken/addToExpression/delete, synchronous) and postValue (setTokens, asynchronous) on the same MutableLiveData. A setValue racing a pending postValue can be overwritten when the posted runnable lands, giving out-of-order UI states. Also LiveData.value is always re-assigned the SAME mutated list instance - observers relying on instance change/equality would never fire; the code works only because Android LiveData notifies unconditionally on setValue.
- Tokens.kt:7/168 - the core data class imports android.text.SpannableString and android.util.Log and logs Log.d("Tag I", ...) inside isLastExpressionBlockHasTimeKeyword on every keystroke - data layer is welded to Android APIs and noisy.
- CalculatorOfTime.kt:67-76 - evaluation goes through exp4j doubles (expression.evaluate().toBigDecimal()), silently losing BigDecimal precision for large millisecond totals (e.g. multi-year expressions exceed 2^53 ms exactness); also a result of pure arithmetic like '2+3' is labeled MSECOND (5 milliseconds) by design, which is surprising.
- CalculatorActivity.kt:486-506 - the getResultTokens observer recreates RvAdapterPer on every result change, and getPerUnits observer recreates it again; adapters are rebuilt wholesale on each emission (performance smell, full-list redraw).

## Porting notes
- LiveData/MutableLiveData → Flutter: use ValueNotifier/ChangeNotifier/Stream (or Riverpod StateNotifier). Critical: the Kotlin code mutates the SAME ArrayList instance and re-assigns it to .value; Android LiveData notifies even when the instance is identical, but Dart ValueNotifier checks == and would NOT notify. Either emit fresh immutable copies (recommended) or call notifyListeners() explicitly.
- setValue vs postValue distinction (main-thread sync vs posted async) disappears in Dart's single-threaded event loop - all updates become synchronous; re-audit any logic that implicitly relied on postValue ordering (TokensRepository.setTokens, ExpressionRepository.setTokens).
- viewModelScope + Dispatchers.Default + coroutineContext.cancelChildren() (cancel in-flight evaluation before relaunching) → Dart has no structured cancellation; use a generation counter / CancelableOperation (package:async), or just evaluate synchronously since expressions are tiny; Isolate.run/compute only if keeping background-thread parity.
- java.math.BigDecimal is load-bearing: setScale(26, HALF_UP) before division, setScale(0, DOWN) for floor, setScale(7, HALF_UP).stripTrailingZeros().toPlainString() for display, setScale(16, HALF_UP) in RvAdapterPer. Dart has no BigDecimal - use package:decimal (Decimal/Rational) and replicate rounding modes and toPlainString (no scientific notation) exactly.
- exp4j ExpressionBuilder (CalculatorOfTime.evaluateSimpleArithmeticExpression) → no Dart equivalent bundled; use math_expressions package or hand-roll a parser. Note exp4j evaluates to double; decide whether to keep that precision loss or evaluate in Decimal (behavior change for huge values).
- SpannableString rendering (Tokens.toSpannableString/toLightSpannableString, Extension.kt color helpers) → Flutter TextSpan/RichText. Exact values to preserve: time keywords #33691E at 0.7x font size, light variant #4C992E at 0.7x, numbers/operators gray #807E7E in 'light' mode, errors red at 0.7x, keywords padded with a leading/trailing space.
- Token glyphs are data-significant: MINUS is U+2212 '−', MULTIPLY U+00D7 '×', DIVIDE U+00F7 '÷' - the lexer matches these exact code points (plus ASCII -, *, / fallbacks). Keep them verbatim in the Dart token model and button labels.
- Singleton repositories with @Volatile double-checked locking → plain Dart lazy static finals (no thread-safety needed); preserve the 'fillRepository exactly once' behavior for ResultFormats (23 defaults, 'Hour Minute' selected) and PerUnits (25/USD/'10 Hour', 8 unit rows).
- ViewModelProvider + NewInstanceFactory + InjectorUtils → Provider/Riverpod/get_it composition root. Decide ViewModel scope: in Android the VM survives rotation but tempResultInMsec dies with the Activity ViewModelStore; in Flutter there is no config-change destruction, so this entire class of stale-cache bugs can be designed away by keeping tempResultInMsec alongside the repos.
- RecyclerView + adapter recreation per LiveData emission → ListView.builder/AnimatedList; the formats list row = (green format name, light-spannable preview), per list row = (header '<amount> <unitName> per <Unit> in the interval', value with unit suffix), row tap on formats calls setSelectedFormat(index).
- android.util.Log calls scattered through repos/Tokens/TimeConverter → replace with package:logging or delete; required to decouple the data layer from Android.
- No persistence exists today (selected format, per-unit amount/currency, expression all reset on process death). Decide for Flutter: replicate in-memory-only behavior, or add shared_preferences for selected format index and per-unit amount/unitName (likely a UX win, but a deliberate behavior change).
- Android-only Activity concerns referenced from the same screen (Google Play Billing 'remove_ads' SKU, AdMob banner, AppRate dialog, circular reveal animations, BuildConfig.PRO_VERSION flavor flag) are outside the data layer but must be re-decided for Flutter (in_app_purchase, google_mobile_ads, rate_my_app, custom reveal animations, build flavors/dart-define).
