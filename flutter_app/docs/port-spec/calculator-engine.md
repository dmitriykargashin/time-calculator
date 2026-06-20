# calculator-engine

## Summary
The calculation engine evaluates token-based time expressions ("5 Hour - 10 Minute", "10 Minute * 5") by wrapping each contiguous number+unit run in parentheses, rewriting every time unit as "* <milliseconds-per-unit>" and every number as "+<number>", feeding the resulting ASCII string to the exp4j 0.4.8 library (double-precision math, standard operator precedence), and tagging the numeric result with an MSECOND token. TimeConverter then re-expresses that millisecond total in a user-selected ordered format (e.g. "Hour Minute") via greedy truncation with a 26-digit working scale and 7-decimal HALF_UP rounding on the last unit, hiding zero-valued units. The "Per" feature multiplies a user-entered amount (e.g. 25 USD) by the result interval expressed as a decimal in each of 8 time units to show e.g. salary over the interval. All arithmetic outside exp4j is BigDecimal; Kotlin's `/`-operator semantics (divide with HALF_EVEN at the receiver's scale) are load-bearing.

## Detailed spec
# Time-Calculator Calculation Engine — Behavioral Spec

Source files (absolute paths):
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/engine/calculator/CalculatorOfTime.kt`
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/engine/calculator/CalculatorOfTimeConst.kt`
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/utilites/TimeConverter.kt`
- Supporting: `data/tokens/{Token,Tokens,TokenType}.kt`, `engine/lexer/LexicalAnalyzer.kt`, `engine/expression/CheckErrorsInExpression.kt`, `data/repository/{ExpressionRepository,ResultFormatsRepository,PerUnitsRepository}.kt`, `data/perUnit/{PerUnit,PerUnits}.kt`, `data/resultFormat/{ResultFormat,ResultFormats}.kt`, `ui/calculator/{CalculatorViewModel,RvAdapterPer}.kt`, `internal/extension/Extension.kt`, tests in `app/src/test/.../WhenCalculateExpression.kt`, `WhenConvertResult.kt`.

---

## 1. Token model

`TokenType` is a sealed class; each object has a display `value` string (verbatim):

| Type | value | Notes |
|---|---|---|
| PLUS | `"+"` | |
| MINUS | `"−"` | U+2212 minus sign, NOT ASCII hyphen |
| PARENTHESESLEFT | `"("` | |
| PARENTHESESRIGHT | `")"` | |
| MULTIPLY | `"×"` | U+00D7 |
| DIVIDE | `"÷"` | U+00F7 |
| NUMBER | `"0.0"` | placeholder; actual digits live in `Token.strRepresentation` |
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

Predicates: `isOperator()` = PLUS|MINUS|DIVIDE|MULTIPLY. `isTimeKeyword()` = YEAR|WEEK|MONTH|DAY|HOUR|MINUTE|SECOND|MSECOND.

`Token(type, strRepresentation = "")`; secondary ctor `Token(type)` sets `strRepresentation = type.value`. `Token` helpers: `addDotToNumber()` appends "." if absent; `mergeNumberToNumber(t)` string-concats digits; `deleteOneLastSymbolInNumber()` drops last char if NUMBER.

`Tokens : ArrayList<Token>`:
- `clone()` — deep copy (new Token per element).
- `toString()` — concatenation with operator remapping to ASCII: PLUS→`"+"`, MINUS→`"-"`, DIVIDE→`"/"`, MULTIPLY→`"*"`, everything else → `strRepresentation` (no separators). **This is the exact string fed to exp4j.**
- `toStringWithSpaces()` — same mapping but each piece prefixed with a space, then `trim()` (used for format labels, e.g. "Hour Minute").
- `isSimpleArithmeticExpression()` — returns false iff any token type is MSECOND|SECOND|HOUR|MINUTE|DAY|WEEK|MONTH|YEAR; true otherwise.
- `isLastExpressionBlockHasTimeKeyword()` — scans backward to the nearest PLUS/MINUS (not ×/÷), then forward from there; true if any time keyword in that tail block.
- `findLastNearestOperatorToken()` / `findTokenBeforeLastNearestOperatorToken()` / `findTokenBeforeTokenBeforeLastNearestOperatorToken()` — backward scans used by ExpressionRepository to decide whether re-evaluation is needed.
- `toSpannableString()` / `toLightSpannableString()` — display rendering (see Porting Notes): units colored `#33691e` (normal) / `#4c992e` (light) at relative size 0.7; numbers plain (normal) or gray `#807e7e` (light); ERROR colored `Color.parseColor("RED")` (note: invalid color string, throws — see bugs) at size 0.7; units and operators padded with one space each side.

## 2. Conversion constants (CalculatorOfTimeConst.kt, verbatim)

Base values (all `BigDecimal`):
```
MILLISECONDS_IN_SECOND = 1000
SECONDS_IN_MINUTE      = 60
MINUTES_IN_HOUR        = 60
HOURS_IN_DAY           = 24
DAYS_IN_WEEK           = 7
DAYS_IN_MONTH          = 30
DAYS_IN_YEAR           = 365
```
Derived (products, exact integer values):
```
MILLISECONDS_IN_MINUTE = 1000*60                 = 60000
MILLISECONDS_IN_HOUR   = 1000*60*60              = 3600000
MILLISECONDS_IN_DAY    = 1000*60*60*24           = 86400000
MILLISECONDS_IN_WEEK   = 1000*60*60*24*7         = 604800000
MILLISECONDS_IN_MONTH  = 1000*60*60*24*30        = 2592000000
MILLISECONDS_IN_YEAR   = 1000*60*60*24*365       = 31536000000
```
A month is exactly 30 days; a year is exactly 365 days. There is no calendar awareness. Note 12 × MILLISECONDS_IN_MONTH = 360 days ≠ 1 year (tests rely on this: "12 Month → 360 Day").

## 3. Evaluation pipeline — `CalculatorOfTime.evaluate(tokens: Tokens): Tokens`

1. Deep-clones input.
2. If `isSimpleArithmeticExpression()` (pure numbers/operators) → step 5 directly.
3. Else `setParenthesesToExpression`: walk tokens, copying each; **before** copying a NUMBER, if no group is open, emit `PARENTHESESLEFT` and mark group open; **before** copying any of MULTIPLY/DIVIDE/MINUS/PLUS, emit `PARENTHESESRIGHT` and mark group closed; after the loop always append one `PARENTHESESRIGHT`. Effect: every maximal run `NUMBER [unit] NUMBER [unit] ...` between operators becomes one parenthesized group. Example `5 Hour - 10 Minute` → `( 5 Hour ) - ( 10 Minute )`. A trailing operator yields `( ... ) op )` (fixed in step 5). Units/other tokens never open a group.
4. `TimeConverter.convertExpressionToMsecs`: per-token rewrite into a new list:
   - SECOND → `MULTIPLY` + `NUMBER("1000")`; MINUTE → `MULTIPLY` + `NUMBER("60000")`; HOUR → `MULTIPLY` + `NUMBER("3600000")`; DAY → `MULTIPLY` + `NUMBER("86400000")`; WEEK → `MULTIPLY` + `NUMBER("604800000")`; MONTH → `MULTIPLY` + `NUMBER("2592000000")`; YEAR → `MULTIPLY` + `NUMBER("31536000000")` (constants via `toPlainString()`).
   - NUMBER → `PLUS` + copy of the NUMBER. (The unary/leading `+` makes adjacent terms inside one group sum: `2 Hour 30 Minute` → `(+2*3600000+30*60000)`.)
   - MULTIPLY/DIVIDE/MINUS/PLUS/PARENTHESESLEFT/PARENTHESESRIGHT → copied (type-only token).
   - **MSECOND, ERROR, DOT have no branch and are silently dropped.** (Dropping MSECOND is numerically a ×1 no-op since the preceding number is already in ms.)
5. `evaluateSimpleArithmeticExpression`:
   - Trailing cleanup: if last token `isOperator()` → remove it; **else** if last is PARENTHESESRIGHT and the token before it is an operator → remove BOTH (this repairs the `... op )` tail produced in step 3, leaving balanced parens).
   - `txt = tokens.toString()` (ASCII operators, see §1). If `txt == ""` → return empty `Tokens`.
   - `ExpressionBuilder(txt).build().evaluate()` — **exp4j 0.4.8** (`net.objecthunter:exp4j:0.4.8`). Math is IEEE-754 double. Operator precedence is exp4j's standard: `*`/`/` bind tighter than `+`/`-`, left-associative, unary `+`/`-` supported, parentheses honored. Division by zero throws `ArithmeticException("Division by zero!")`; malformed/unbalanced input throws `IllegalArgumentException`.
   - `result.toBigDecimal()` — Kotlin `Double.toBigDecimal()` ≡ `BigDecimal(double.toString())`, so e.g. `17400000.0` → `BigDecimal("1.74E7")`. `resultAsString = result.toString()` — BigDecimal.toString **may be scientific notation** (e.g. `"1.74E+7"`, `"10.0"` for ten).
   - Success return: `Tokens[ Token(NUMBER, resultAsString), Token(MSECOND) ]` — the MSECOND tag is appended **unconditionally**, even for pure-number expressions.
   - Any exception → `Tokens[ Token(ERROR, "ERROR") ]`.

Worked example, `10 Minute + 5 Hour`:
- parenthesized: `( 10 Minute ) + ( 5 Hour )`
- msec rewrite, exact exp4j input string: `(+10*60000)+(+5*3600000)`
- exp4j → `18600000.0` → tokens `[NUMBER "1.86E+7", MSECOND]`.

Semantics that fall out of this design:
- Multiplying/dividing a time group by a number multiplies the whole group: `10 Minute * 5` → `(+10*60000)*(+5)` = 3,000,000 ms = 50 Minute.
- A bare number inside a time expression means **milliseconds**: `5 Hour + 2` → `(+5*3600000)+(+2)` (UI error rules mostly prevent this for +/-).
- time ÷ time and time × time are syntactically evaluable (dimensionless / ms² results mislabeled as ms); the UI error checker blocks adding a unit right after ×/÷ in a time block, so it shouldn't be reachable from buttons.
- Precedence between groups is mathematical, not calculator-left-to-right: `1 Hour + 2 Hour * 2` = 5 Hour.

## 4. Kotlin BigDecimal semantics (load-bearing for a port)

- Kotlin `BigDecimal / BigDecimal` and `.div(...)` operator = `this.divide(other, RoundingMode.HALF_EVEN)` → **result keeps the receiver's scale** and is rounded HALF_EVEN to that scale. So `BigDecimal("32400000000.0") / 86400000` = `375.0` (scale 1), and `BigDecimal("32400000000.0") / 31536000000` = `1.0` — both asserted by tests.
- `Double.toBigDecimal()` = `BigDecimal(double.toString())`.
- `toPlainString()` (no exponent) vs `toString()` (may use exponent) matters: engine output uses `toString()`, everything else uses `toPlainString()`.
- `stripTrailingZeros()` is applied before `toPlainString()` for formatted numbers, so `10.0000000` renders `"10"`, `375.0` stays `"375.0"` only when scale survives (in formats it's stripped → `"375"`; the `convertExpressionInMsecsToType` path does NOT strip → `"375.0"`).
- `compareTo(ZERO) != 0` (value comparison, scale-insensitive) is the zero test everywhere.

## 5. TimeConverter — public API

### 5.1 `convertExpressionToMsecs(Tokens): Tokens` — covered in §3.4.

### 5.2 `convertTokensToTokensWithFormat(tokensToConvert: Tokens, tokensFormat: Tokens, removeZeroUnits: Boolean = true): Tokens` — THE display formatter
This is the only formatter used in production (ViewModel result display, format previews, per-unit values).

Step A — `convertTokensToMScec(tokens)` (private): folds the token list into one BigDecimal total. State machine: on NUMBER, remember `currentNumber = strRepresentation.toBigDecimal()`; on a unit token add `currentNumber × unitMs` to the running total — MSECOND adds `currentNumber × 1`; SECOND ×1000; MINUTE ×60000; HOUR ×3600000; DAY ×86400000; WEEK ×604800000; MONTH ×2592000000; YEAR ×31536000000. All other token types ignored. (A unit with no preceding NUMBER reuses the stale `currentNumber`; a trailing NUMBER with no unit contributes nothing.)

Step B — for each format token, in the given order (format lists are curated biggest→smallest; the algorithm does NOT sort), call `addTimeUnitToResultAndGetReminder(reminderMs, type, isLast = (index == lastIndex), endResult, removeZeroUnits)`:
- `currentResult = convertMsecsToMSecsInType(reminderMs.setScale(26, RoundingMode.HALF_UP), type)` — division by the unit's ms constant via Kotlin `/` (HALF_EVEN at scale 26); MSECOND passes through unchanged; unmatched types (ERROR/operators/NUMBER) yield ZERO.
- If **last** format unit: keep decimal. Emit nothing if `currentResult == 0 && removeZeroUnits`; otherwise emit `NUMBER(currentResult.setScale(7, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString())` + the unit token. So the final unit is rounded to **7 decimal places, HALF_UP, trailing zeros stripped**.
- If **not last**: `currentResultRounded = currentResult.setScale(0, RoundingMode.DOWN)` (truncate toward zero); `reminderFromFullNumber = (currentResult − currentResultRounded).setScale(26, HALF_UP)`. Emit `NUMBER(currentResultRounded.toPlainString())` + unit token unless `(rounded == 0 && removeZeroUnits)`. Carry: if fraction ≠ 0, `convertPartOfUnitToMScec(fraction, type)` = fraction × unitMs (no MSECOND branch there — MSECOND carry would be lost, though MSECOND is only ever last in curated formats); else ZERO.
- Return carry as `reminder.setScale(7, RoundingMode.HALF_UP).stripTrailingZeros()` — i.e. the carried milliseconds are themselves rounded to 7 dp HALF_UP each step (this repairs scale-26 truncation drift, see worked example).

Properties: zero-valued units are hidden (`removeZeroUnits=true` everywhere in production — the `false` path is never used); a total of 0 yields an **empty** Tokens list; intermediate units are integers (truncated), only the final unit may be fractional.

Worked examples (all asserted by unit tests in `WhenConvertResult.kt`):
- `2 Day` → format `Hour` → `48 Hour`.
- `2.1 Day` → `Hour` → `50.4 Hour`; → `Hour Minute` → `50 Hour 24 Minute`; → `Minute` → `3024 Minute`.
- `2.12 Day` → `Minute` → `3052.8 Minute`.
- `2.12222222 Day` → `Month` → `0.0707407 Month` (7 dp HALF_UP of 0.0707407407…).
- `13.1 Day` → `Month` → `0.4366667 Month`.
- `0.1 Day` → `Year Month Day Hour Minute Second` → `2 Hour 24 Minute` (Year/Month/Day truncate to 0 and are hidden, full value carries down; Second is 0 → hidden).
- `235000 Second` → `Hour Minute` → `65 Hour 16.6666667 Minute`.
- `62 Minute` → `Day Hour Minute Second` → `1 Hour 2 Minute`.
- `48 Hour` → `Hour` → `48 Hour`; `12 Day` → `Day` → `12 Day`.

### 5.3 `convertExpressionInMsecsToType(token: Token, type: TokenType): Tokens` — single-unit conversion (tests only; production call is commented out)
Parses `token.strRepresentation.toBigDecimal()` and emits `[NUMBER((msec / unitMs).toPlainString()), Token(type)]`. The division is Kotlin `/` → **HALF_EVEN rounded to the scale of the input string**. MSECOND → value unchanged. No `stripTrailingZeros`. Test assertions (verbatim expectations): `10 Year`→YEAR→`10 Year`; `1 Year`→MONTH→`12 Month` (≈12.1666 HALF_EVEN at scale 0 → 12); `12 Month`→DAY→`360 Day`; `12.5 Month`→DAY→`375.0 Day`; `12.5 Month`→YEAR→`1.0 Year` (1.0273… rounded at scale 1).

### 5.4 `convertExpressionInMsecsToNearest(token: Token): Tokens` — greedy decomposition (dead code; its call in CalculatorOfTime.kt:33 is commented out)
Decomposes a ms value into Year→Month→Week→Day→Hour→Minute→Second→MSecond. Each step: `remaining.div(unitMs).setScale(0, RoundingMode.DOWN)` — but since Kotlin `div` already rounds HALF_EVEN at the receiver's scale, for scale-0 inputs the value can round UP before the DOWN setScale (a real bug, see suspectedBugs). Units with value `compareTo(ZERO) == 0` are skipped; emitted as `NUMBER(value.toPlainString())` + unit token.

### 5.5 `convertTokensToMScecToken(tokens: Tokens): Token`
Same fold as 5.2 step A but **without an MSECOND branch** (MSecond quantities ignored → 0) and returns a single `Token(NUMBER, total.toPlainString())`. Used only by the test/extension helper `String.toTokenInMSec()`.

## 6. Result formats (ResultFormatsRepository.fillRepository, in insertion order)

`ResultFormat(formatTokens, convertedResultTokens[, exactTextLabel])`; label defaults to `formatTokens.toStringWithSpaces()`. The 23 formats (formatTokens string / preview tokens string):
1. `Year` / `1 Year`
2. `Year Month` / `1 Year 2 Month`
3. `Year Month Day` / `1 Year 2 Month 3 Day`
4. `Year Month Day Minute` / `1 Year 2 Month 3 Day 4 Minute`
5. `Month` / `1 Month`
6. `Month Day` / `Month Day` (preview has no numbers — likely a typo in source)
7. `Month Day Hour` / `1 Month 2 Day 3 Hour`
8. `Month Day Hour Minute` / `1 Month 2 Day 3 Hour 4 Minute`
9. `Month Day Hour Minute Second` / `1 Month 2 Day 3 Hour 4 Minute 5 Second`
10. `Month Week` / `1 Month 2 Week`
11. `Week` / `1 Week`
12. `Week Day` / `1 Week 2 Day`
13. `Day` / `1 Day`
14. `Day Hour` / `1 Day 1 Hour`
15. `Day Hour Minute` / `1 Day 2 Hour 3 Minute`
16. `Day Hour Minute Second` / `1 Day 2 Hour 3 Minute 4 Second`
17. `Hour` / `1 Hour`
18. **`Hour Minute` / `1 Hour 2 Minute` — `isSelected = true` (default format)**
19. `Hour Minute Second` / `1 Hour 2 Minute 3 Second`
20. `Minute` / `1 Minute`
21. `Minute Second` / `1 Minute 2 Second`
22. `Second` / `1 Second`
23. `Year Month Week Day Hour Minute Second MSecond` / `1 Year 2 Month 3 Week 4 Day 5 Hour 6 Minute 7 Second 8 MSecond`, custom label **"All Units"**

`ResultFormats.setSelection(position)` clears all `isSelected` flags then sets one. `updateFormatsWithPreview(resultTokens)` recomputes every format's `convertedResultTokens = convertTokensToTokensWithFormat(resultTokens, formatTokens)` (called when the formats panel opens).

## 7. End-to-end flow (CalculatorViewModel)

- `addToExpression(token)`: ExpressionRepository validates+appends; returns "needs evaluation" boolean. Operators (+ − × ÷) never trigger evaluation. NUMBER/DOT merge into a trailing NUMBER token. Evaluation is triggered only when `isLastExpressionBlockHasTimeKeyword()` AND the last block involves ×/÷ in specific shapes, or via `tryToAddToExpression` for unit tokens. On trigger: `viewModelScope.coroutineContext.cancelChildren()` then launch `evaluateExpression()` (debounce-by-cancellation).
- `evaluateExpression()`: `tempResultInMsec = CalculatorOfTime.evaluate(expression)` on `Dispatchers.Default`; then `resultTokens = TimeConverter.convertTokensToTokensWithFormat(tempResultInMsec, selectedFormat.formatTokens)`; publish to TokensRepository; `setIsPerViewButtonDisabled(false)` unconditionally.
- `setSelectedFormat(position)`: re-converts cached `tempResultInMsec` with the newly selected format and republishes.
- `sendResultToExpression()` ("=" button): moves the formatted result tokens into the expression (so a formatted result like `2.5 Hour` becomes new input) and clears the result; disables Per button.
- `clearAll()` / `clearOneLastSymbol()`: delete-last re-evaluates when the remaining tail block has a time keyword or last token is not a NUMBER.
- Expression input validation (`isErrorsInExpression`): rejects — unit/operator/dot as first token; `+`/`-` after a plain number whose block has no time unit; operator after operator; dot after operator; time unit right after an operator; unit immediately after unit; and unit after `×|÷ NUMBER` within a time block (blocks `2 Hour * 3 Minute`). `isErrorAfterCheckForPoint` allows "." only after a digit.

## 8. "Per unit" (amount per time interval — salary/distance) feature

Data: `PerUnits(amount: BigDecimal, unitName: String, timeInterval: Tokens) : ArrayList<PerUnit>`; `PerUnit(timeUnit: Token)` with `unitsPer_Result: BigDecimal = ZERO`. Defaults: `amount = 25`, `unitName = "USD"`, `timeInterval = "10 Hour".toTokens()`. `fillRepository()` adds 8 PerUnit rows in this exact order: **Hour, Minute, Second, Day, Week, Month, Year, MSecond**.

Computation (`PerUnitsRepository.updatePerUnitsWithPreview(resultTokens)` — `resultTokens` is the engine output `[NUMBER msecTotal, MSECOND]`):
```
for each perUnit:
    units = TimeConverter.convertTokensToTokensWithFormat(resultTokens, [perUnit.timeUnit])   // single-unit decimal, 7dp HALF_UP, stripped
    perUnit.unitsPer_Result = perUnitsList.amount * units[0].strRepresentation.toBigDecimal()
```
i.e. **result-per-card = amount × (total calculated interval expressed in that unit)**. The semantics: user enters a rate of `amount unitName` per ONE unit; each card answers "if the rate were per <unit>, how much over this interval". The stored `timeInterval` field is **never used** in the math. Example: result 5 Hour 10 Minute (18,600,000 ms), amount 25 USD → Hour card: 25 × 5.1666667 = 129.1666675 USD; Minute card: 25 × 310 = 7750 USD.

Display (`RvAdapterPer.onBindViewHolder`): header = `"{amount} {unitName} per"` + `" {timeUnit.strRepresentation}"` (color `#33691e`, relative size 1.0) + `" in the interval"`; value = `unitsPer_Result.setScale(16, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString()` + `" {unitName}"` (color `#33691e`, size 0.7).

Triggers: the Per button (`buttonPer`, disabled with alpha 0.5 until a successful evaluation) calls `updatePerUnits()` (gated on `!isPerViewButtonDisabledRepository`); text watchers on `etUnitAmount`/`etUnit` call `updateSettingsForPerUnits(etUnitAmount.text.toBigDecimal(), etUnit.text)` whenever both fields are non-empty (`setParams(amount, unitName, currentResultTokens)` then recompute); `rvPer` is hidden when either field is empty.

## 9. Lexer (`LexicalAnalyzer.analyze(string): Tokens`) — used by `"..."​.toTokens()`
Removes ALL spaces first, then scans: digit start → regex `-?[\d\.]+` matched from current position (the leading `-` never matches because dispatch saw a digit); letter start → case-sensitive prefix match against `Year|Month|Week|Day|Hour|Minute|Second|MSecond` (note: `Minute` is checked before `Second`, and `MSecond` last — `MSecond` still lexes correctly because the letter `M` fails `Month`/`Minute` prefix checks at that position... actually "MSecond" fails `Month` and `Minute` (no 'o'/'i'), fails others, matches MSECOND); operator start → accepts both Unicode (`−×÷+`) and ASCII (`- * / +`) forms; anything else → ERROR token (advancing by its `strRepresentation.length`).

## 10. Test assertions (verbatim, `app/src/test`)
`WhenCalculateExpression.kt` — equality matcher compares only `strRepresentation` element-wise and size:
- `""` → empty Tokens.
- `"0 + 10"` → expects lastIndex 0, `[0]=="10"`; `"0 − 10"` → `"-10"`; `"0 × 10"` → `"0"`; `"0 ÷ 10"` → `"0"`.
- `"10 Minute+ 5 Hour"` → expects 4 tokens `5/Hour/10/Minute`; `"10 Minute × 5"` → `50/Minute`; `"5 Hour-10 Minute"` → `4/Hour/50/Minute`.
(These expect post-format output from `evaluate` — see suspectedBugs: current `evaluate` returns `[NUMBER msec, MSECOND]`, so these tests document the OLD intended behavior.)
`WhenConvertResult.kt` — see §5.2/§5.3 worked examples; all current-code-accurate.
`build.gradle`: `testOptions { unitTests.returnDefaultValues = true }` (android.util.Log no-ops in JVM tests); `minSdkVersion 19`, `targetSdkVersion 29`.

## 11. Invariants & edge cases summary
- Engine output is always one of: empty Tokens (empty input), `[NUMBER <doubleString>, MSECOND]`, or `[ERROR "ERROR"]`.
- Engine number string may be scientific notation (`1.86E+7`); all downstream consumers parse via `toBigDecimal()`, all downstream emissions use `toPlainString()`.
- Formatting truncates intermediate units toward zero, rounds the final unit to 7 dp HALF_UP, strips trailing zeros, hides zero units, and yields an empty list for a zero total.
- Format unit order is taken as given (assumed descending); duplicate units in a format would double-process the remainder.
- exp4j math is double-precision: exact only up to 2^53 ms (~285,000 years); beyond that, precision loss.
- Negative results are possible (`0 - 10 Minute`); decomposition truncation (`RoundingMode.DOWN`) is toward zero, so all components carry the negative sign through the carry chain (the in-source TODO at CalculatorOfTime.kt:152 notes each term displays its own minus).

## Suspected bugs
- CalculatorOfTime.kt:79-93 vs WhenCalculateExpression.kt:71-163 — stale tests: evaluate() now returns [NUMBER(rawDoubleString), MSECOND] (e.g. "10.0" with 2 tokens), but tests assert single-token "10" and fully formatted results like 5/Hour/10/Minute (the old convertExpressionInMsecsToNearest path, commented out at CalculatorOfTime.kt:33). These tests should fail against current code; they document removed behavior.
- PerUnitsRepository.kt:59-65 — `units[0]` will throw IndexOutOfBoundsException when convertTokensToTokensWithFormat returns an empty list, which happens whenever the result total is 0 ms (e.g. expression "0 Hour" or "5 Minute - 5 Minute") or when the result is the ERROR token (ERROR is ignored by convertTokensToMScec → total 0 → empty). Reachable because CalculatorViewModel.evaluateExpression (CalculatorViewModel.kt:115-128) enables the Per button unconditionally, even for ERROR/zero results.
- CalculatorViewModel.kt:121-125 — an ERROR result is silently swallowed: convertTokensToTokensWithFormat ignores ERROR tokens, so a division-by-zero (exp4j ArithmeticException → [ERROR "ERROR"]) renders as an empty result instead of showing ERROR.
- PerUnits.timeInterval (PerUnits.kt:10, set in PerUnitsRepository.setParams) is stored and shown in the UI copy ("per ... in the interval") but never used in updatePerUnitsWithPreview's math — the rate is implicitly per ONE unit. Either dead state or an unfinished feature (the default "10 Hour" interval is meaningless).
- TimeConverter.kt:20-54 (convertExpressionInMsecsToNearest, currently dead code but public) — `valueOfToken.div(MILLISECONDS_IN_YEAR).setScale(0, RoundingMode.DOWN)` does not truncate: Kotlin's BigDecimal.div is divide(other, HALF_EVEN) at the receiver's scale, so for scale-0 inputs the quotient is already HALF_EVEN-rounded (can round UP) before the no-op setScale(DOWN). E.g. 1.9 years of ms yields years=2 and then negative month/week components.
- TimeConverter.kt:240-321 (convertExpressionInMsecsToType) — same Kotlin `/` pitfall: result precision equals the scale of the input string. "1 Hour" in ms (scale 0) converted to YEAR returns "0", not 0.0001141; tests only pass because their inputs happen to carry a decimal scale. Also for type=ERROR/DOT/operators the `when` falls through and the function still appends Token(type) with no NUMBER, returning a malformed 1-token list.
- TimeConverter.kt:369-434 (convertTokensToMScecToken) lacks the MSECOND branch that its private twin convertTokensToMScec (line 437-507) has — "5 MSecond".toTokenInMSec() returns 0. Likewise convertExpressionToMsecs (TimeConverter.kt:138-236) and convertPartOfUnitToMScec (TimeConverter.kt:510-565) have no MSECOND branch; in convertExpressionToMsecs an MSecond unit token is silently dropped (numerically correct only by accident, ×1).
- TimeConverter.kt:443-453 (convertTokensToMScec) — stale-state fold: a unit token without a preceding NUMBER reuses the previous currentNumber (e.g. tokens "5 Hour Minute" sum 5h+5min), and a NUMBER without a following unit contributes nothing. Relies entirely on upstream UI validation.
- CalculatorOfTime.kt:76 — resultAsString = BigDecimal.toString() can be scientific notation ("1.86E+7") while every other number in the app uses toPlainString(); if this token ever reaches the lexer (e.g. a future sendResultToExpression of an unformatted result) it lexes as NUMBER("1.86")+ERROR("E")+... Currently latent.
- Extension.kt:73 (toHTMLWithRedColor) — Color.parseColor("RED") is invalid (parseColor accepts "red" lowercase or #RRGGBB); rendering an ERROR token through toSpannableString should throw IllegalArgumentException, meaning the ERROR display path likely crashes if ever exercised.
- ResultFormatsRepository.kt:104 — the "Month Day" format's preview tokens are "Month Day".toTokens() (no numbers), inconsistent with every other preview ("1 Month 2 Day" style); renders a preview without example values.
- evaluate uses exp4j double math: ms totals beyond 2^53 (~285,485 years) silently lose precision, and even small fractional inputs (0.1 Day) round-trip through binary doubles; the BigDecimal pipeline then treats the inexact double as exact. The 7dp HALF_UP carry rounding in addTimeUnitToResultAndGetReminder (TimeConverter.kt:792) papers over this but caps precision at 7 decimals per unit step.
- CalculatorActivity.kt:855-861 — etUnitAmount text watcher calls s.toString().toBigDecimal() without try/catch; inputs like "." or "1.2.3" (if the EditText inputType allows) throw NumberFormatException and crash.
- ResultFormats.getSelectedResulFormat (ResultFormats.kt:25-35) returns a lateinit var that is never assigned when no element has isSelected — UninitializedPropertyAccessException; safe only because fillRepository hardcodes format #18 ("Hour Minute") as selected.

## Porting notes
- exp4j (net.objecthunter:exp4j:0.4.8) has no Dart port. Options: a Dart expression-eval package (math_expressions, expressions) or a ~50-line shunting-yard evaluator. Required behavior: ASCII + - * / with parentheses, unary +/- (the engine emits a leading '+' before every number, e.g. "(+10*60000)+(+5*3600000)"), standard precedence, and a thrown error on division by zero / malformed input that maps to the ERROR token. Consider evaluating with exact decimal/rational arithmetic instead of double to fix the 2^53 precision ceiling — but then test expectations tied to double round-tripping may shift.
- java.math.BigDecimal — Dart core has no decimal type. Use package:decimal (Decimal/Rational) or BigInt-scaled ints. Must reproduce exactly: setScale(n, HALF_UP) and setScale(0, DOWN/truncate), stripTrailingZeros, toPlainString vs toString (scientific), compareTo-based zero checks, and crucially Kotlin's operator `/` semantics = divide(other, RoundingMode.HALF_EVEN) at the RECEIVER's scale (affects convertExpressionInMsecsToType/Nearest results asserted by tests, e.g. 12.5 Month → "1.0" Year). package:decimal's `/` returns exact Rational — you must explicitly emulate scale+HALF_EVEN.
- Kotlin Double.toBigDecimal() == BigDecimal(double.toString()); Java's Double.toString differs from Dart's (Java: "1.86E7", Dart: "18600000.0" / different shortest-repr rules). The engine's internal msec string format depends on this — normalize (e.g. always store plain decimal) and adjust any string-level expectations.
- android.util.Log.{i,d} calls sprinkled through engine code (CalculatorOfTime, TimeConverter, Tokens) → remove or replace with debugPrint/logger; note JVM tests rely on unitTests.returnDefaultValues=true to no-op them.
- LiveData/MutableLiveData + ViewModel + viewModelScope coroutines: evaluateExpression runs on Dispatchers.Default with coroutineContext.cancelChildren() as a debounce → in Flutter use ChangeNotifier/ValueNotifier/Riverpod/Bloc; computation is cheap enough to run synchronously, or use compute()/Isolate; replicate the cancel-previous-evaluation debounce.
- SpannableString rendering (Tokens.toSpannableString / toLightSpannableString, custom spannable{} DSL in SpannableFunctions.kt): units at relative size 0.7 colored #33691e (result) / #4c992e (light preview), numbers/operators gray #807e7e in light mode, ERROR red, single-space padding around units/operators → Flutter RichText/TextSpan with TextStyle(color: Color(0xFF33691E), fontSize: base*0.7).
- TokenType uses Unicode glyphs for display (MINUS "−" U+2212, MULTIPLY "×", DIVIDE "÷") but Tokens.toString() maps them to ASCII for evaluation; keep both representations and the mapping in the Dart token model.
- Singleton repositories (@Volatile + synchronized getInstance with one-time fillRepository) → Dart top-level lazy singletons or DI (get_it/provider); preserve the one-time seeding of the 23 ResultFormats (default selected index 17, "Hour Minute") and 8 PerUnits (Hour, Minute, Second, Day, Week, Month, Year, MSecond; defaults 25/"USD"/"10 Hour").
- RecyclerView adapters (RvAdapterPer, RvAdapterResultFormats) recreated on every LiveData emission → ListView.builder driven by state; per-card text composition (header "{amount} {unitName} per {unit} in the interval", value setScale(16, HALF_UP).stripTrailingZeros()) belongs in a view model/formatter, not the widget.
- Android view plumbing in CalculatorActivity that gates engine calls: TextWatchers on etUnitAmount/etUnit (recompute per-units only when both non-empty; hide rvPer otherwise), buttonPer enabled/alpha state from isPerViewButtonDisabled, EditorInfo.IME_ACTION_DONE keyboard hiding → Flutter TextEditingController listeners, FocusScope, enabled/Opacity.
- ViewAnimationUtils.createCircularReveal panels (formats/per overlays, 600ms open / 450ms close, AccelerateDecelerateInterpolator) and the clear-all reveal → Flutter custom ClipOval/ClipPath animation or a package; back-button closes overlays first (WillPopScope).
- Pattern.compile("-?[\\d\\.]+") with Matcher.find(fromIndex) in the lexer → Dart RegExp with allMatches/matchAsPrefix from an offset; preserve case-sensitive unit-keyword prefix matching and acceptance of both Unicode and ASCII operator characters.
- Out-of-scope-but-entangled Android services in the same Activity: Google Play Billing (remove_ads SKU), AdMob, hotchemi AppRate, Facebook SDK, mailto feedback intent — need Flutter equivalents (in_app_purchase, google_mobile_ads, rate_my_app, url_launcher) or removal; the PRO_VERSION BuildConfig flag → Dart build flavor/--dart-define.
