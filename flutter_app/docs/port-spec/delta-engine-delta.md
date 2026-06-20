# RemoveADS branch delta: engine-delta

## Summary
The RemoveADS branch makes two behavioral engine changes plus rendering plumbing: (1) "smart plural" — Token gains a required BigDecimal `value` field and the Token constructor appends a literal 's' to strRepresentation of any time-unit token whose value != 1 (scale-insensitive compare), with the value sourced from the preceding NUMBER token (lexer and a new ExpressionRepository.addToExpressionTimeUnit), from the converted amount (TimeConverter), or from the msec result (CalculatorOfTime's MSECOND tag); (2) zero-total fix — convertTokensToTokensWithFormat computes `initialValueIsZero` up front and, when the total is 0 ms and the last format unit would be suppressed by removeZeroUnits, emits "0 <Unit>s" instead of an empty list (the commit-message "trailing zero bug" was introduced and fixed entirely within the branch; the net delta vs master is only the zero-total emission). Rendering: toSpannableString/toLightSpannableString now take a Context and resolve theme colors (dark-mode aware), and the gray number/operator style gains a 0.7 relative-size span. Result formats: "Year Month Day Minute" replaced by "Year Month Day Hour" plus a new "Year Month Day Hour Minute" (24 formats). No constants, no CheckErrorsInExpression, no TokenType changes. Unit tests were NOT updated — WhenCalculateExpression.kt still calls the old Token constructors and therefore the branch's test module does not compile; no test is ground truth for the new behavior.

## Detailed spec
# Engine delta: master → origin/RemoveADS

Delta is expressed against `flutter_app/docs/port-spec/lexer-tokens.md`, `calculator-engine.md`, `errors-and-tests.md`. Anything not mentioned here is byte-identical to master: `TokenType.kt`, `CalculatorOfTimeConst.kt` (all ms constants), `CheckErrorsInExpression.kt` (all rules R0–R7), `SpannableFunctions.kt`, and all of `app/src/test` are UNCHANGED on the branch.

Branch commits touching the engine: `a6470ba` (zero-result fix, intermediate), `994973d` (trailing-zero fix + theme colors), `6af830c` (smart plural).

---

## 1. Token model (`data/tokens/Token.kt`) — replaces lexer-tokens.md §2

New signature:
```kotlin
class Token(val type: TokenType, val value: BigDecimal, var strRepresentation: String = "")
```
- `value: BigDecimal` is a NEW required second positional parameter (immutable `val`). Every construction site in the app now supplies it (see §1.2).
- Secondary constructor: `constructor(type: TokenType, value: BigDecimal) : this(type, value, type.value)` — replaces master's `Token(type)`; still copies `type.value` into `strRepresentation`.
- NEW `init` block (this is the entire "smart plural" feature — there is NO other pluralization logic anywhere):
```kotlin
init {
    if (type.isTimeKeyword()) {
        if (value.compareTo(1.toBigDecimal()) != 0) {
            strRepresentation += 's'
        }
    }
}
```

### 1.1 Pluralization rule, exactly
- Applies ONLY to the 8 time-keyword types (YEAR, MONTH, WEEK, DAY, HOUR, MINUTE, SECOND, MSECOND). NUMBER, operators, parens, ERROR, DOT are never pluralized.
- Appends a single ASCII `'s'` to whatever `strRepresentation` the constructor received (normally `type.value`, e.g. `"Hour"` → `"Hours"`, `"MSecond"` → `"MSeconds"`).
- Trigger: `value.compareTo(BigDecimal(1)) != 0` — BigDecimal value comparison, SCALE-INSENSITIVE:
  - `1`, `1.0`, `1.00` → singular (`"Hour"`).
  - `0`, `0.5`, `2`, `12`, `-1`, `-10`, any non-one value → plural (`"Hours"`). Note 0 and negatives ARE plural ("0 Hours", "-10 Minutes").
- It runs at CONSTRUCTION TIME on every Token created, including copies that pass an already-pluralized strRepresentation (see suspected bug: double-'s' on clone).
- `value` is `val`: `mergeNumberToNumber`, `addDotToNumber`, `deleteOneLastSymbolInNumber` mutate `strRepresentation` only; `value` is frozen at construction. All other Token methods (`addDotToNumber`, `length()`, `mergeNumberToNumber`, `deleteOneLastSymbolInNumber`, `toTokens()`) are unchanged.

### 1.2 What `value` is at every construction site (exhaustive)
| Site | value |
|---|---|
| Lexer NUMBER (`findCurrentDigitalToken`) | `m.group().toBigDecimal()` (the parsed digits) |
| Lexer unit/letter token (`findCurrentLetterToken`) | value of the LAST token already lexed if it is a NUMBER, else `1` (see §2) |
| Lexer letter-branch ERROR fallback | same inherited value (irrelevant — ERROR never pluralizes) |
| Lexer operator tokens, dispatch-level ERROR init | `1.toBigDecimal()` |
| UI digit buttons (CalculatorActivity) | the digit itself, e.g. `Token(NUMBER, value=7.toBigDecimal(), strRepresentation="7")` |
| NEW `ExpressionRepository.addToExpressionTimeUnit(elementType)` | value of trailing NUMBER token in the expression, else 1 (see §6) |
| `CalculatorOfTime.evaluate` result NUMBER | `result` (the BigDecimal msec total) |
| `CalculatorOfTime.evaluate` MSECOND tag | `result` — so the tag renders `"MSeconds"` unless the msec total is exactly 1 |
| `CalculatorOfTime` ERROR token | `1.toBigDecimal()` (strRepresentation `"ERROR"`) |
| `setParenthesesToExpression` PARENTHESES tokens | `1.toBigDecimal()`; copied tokens keep `token.value` (and pass the already-final `strRepresentation` → re-runs init, see bugs) |
| `TimeConverter.convertExpressionToMsecs`: MULTIPLY/PLUS and copied operators/parens | `1.toBigDecimal()`; ms-constant NUMBERs carry the constant (e.g. `MILLISECONDS_IN_HOUR`); copied NUMBER carries `strRepresentation.toBigDecimal()` |
| `TimeConverter.convertTokensToMScecToken` | NUMBER carries `multipliedResult` |
| `TimeConverter.convertExpressionInMsecsToType` | NUMBER and the trailing unit token both carry `tempValue` = the converted amount (for non-handled target types, `tempValue` stays ZERO and the appended `Token(type, ZERO)` gets value 0) |
| `TimeConverter.convertExpressionInMsecsToNearest` | each NUMBER and unit token carries that component's amount (years, months, …) |
| `convertTokensToTokensWithFormat` / `addTimeUnitToResultAndGetReminder` | non-last format unit: NUMBER and unit carry `currentResultRounded`; LAST format unit: NUMBER carries the UNROUNDED `currentResult` (its strRepresentation is the 7dp-rounded string) and the unit token also carries unrounded `currentResult`; zero-emission path (§4) carries `ZERO` |
| `Tokens.clone()` | `Token(type = token.type, value = token.value, strRepresentation = token.strRepresentation)` |

### 1.3 Net display behavior (the user-visible feature)
- Expression: tapping `2` then `Hour` shows `2 Hours`; `1` then `Hour` shows `1 Hour`. (Caveat: the value is the FIRST digit pressed — see suspected bugs.)
- Formatted result: 18,600,000 ms with format `Hour Minute` → tokens `[NUMBER "5", HOUR "Hours", NUMBER "10", MINUTE "Minutes"]` → "5 Hours 10 Minutes". 3,600,000 ms → "1 Hour". 60,000 ms with format `Minute` → "1 Minute"; 0.5-valued last unit → "0.5 Hours"; negative → "-10 Minutes".
- Format definition strings ("Hour Minute" etc.) lex with no preceding number → value 1 → stay singular; format labels are unaffected.
- exp4j input is unaffected: units are replaced by `* <const>` by TYPE before `toString()`, so the plural 's' never reaches the evaluator.

## 2. Lexer (`engine/lexer/LexicalAnalyzer.kt`) — delta to lexer-tokens.md §4

- `findCurrentFullToken(expression, currentPosition)` gains a third parameter `currentTokens: Tokens` (the result list built so far); `startAnalyze` passes `resultTokens` into it. Initial fallback token is now `Token(type = TokenType.ERROR, value = 1.toBigDecimal())`.
- `findCurrentLetterToken(expression, currentPosition, currentTokens)` — NEW value-inheritance preamble:
```kotlin
var tokenValue = 1.toBigDecimal()
if (currentTokens.isNotEmpty() && currentTokens.last().type == TokenType.NUMBER) {
    tokenValue = currentTokens.last().value
}
```
  Every unit branch returns `Token(type = TokenType.X, tokenValue)`; the else branch returns `Token(type = TokenType.ERROR, tokenValue)`. Match order and case-sensitive `startsWith` checks are UNCHANGED (Year, Month, Week, Day, Hour, Minute, Second, MSecond — the conditions still match the SINGULAR words only).
- `findCurrentDigitalToken`: unchanged regex `-?[\d\.]+`; now returns `Token(TokenType.NUMBER, m.group().toBigDecimal(), strRepresentation = m.group())`. NOTE: this adds a `toBigDecimal()` parse at lex time — a malformed match like `"1..2"` or `"1.2.3"` now THROWS NumberFormatException during lexing (master deferred the failure downstream).
- `findCurrentOperatorToken`: each branch now passes `value = 1.toBigDecimal()`; otherwise identical.
- Cursor advancement is still `currentPosition += tmpToken.length()` — i.e. `strRepresentation.length` AFTER pluralization. Emergent round-trip semantics:
  - `"2Hours"` (or `"2 Hours"`) lexes cleanly: at the letter, prev NUMBER value=2 → token strRepresentation `"Hours"` (length 5) → cursor advances over the trailing `s`. `"1Hour"` likewise (length 4).
  - `"1Hours"` → token `"Hour"` (value 1, length 4) → trailing `s` lexes as letter → no unit matches → extra ERROR token (advances 5, past end).
  - `"2Hour+3Minute"` (singular text with value≠1, e.g. saved by the OLD app version) → token `"Hours"` length 5 over-advances by 1, SWALLOWING the `+` → `[NUMBER 2, HOUR "Hours", NUMBER 3, MINUTE "Minutes"]` — the operator is silently lost. Strings produced by the new code itself always round-trip because `toString()` emits the plural.
- Everything else (space stripping, dispatch order, `expressionLength` static, ERROR 5-char skip) is unchanged.

## 3. Tokens collection (`data/tokens/Tokens.kt`) — delta to lexer-tokens.md §3

- `clone()` now copies value: `Token(type = token.type, value = token.value, strRepresentation = token.strRepresentation)` (note: re-runs the plural init — see bugs).
- `toSpannableString(context: Context)` and `toLightSpannableString(context: Context)` now REQUIRE an Android `Context` (for theme color lookup). Branch structure and token-type dispatch are identical; only the color helpers changed (§5).
- `toString()`, `toStringWithSpaces()`, `isSimpleArithmeticExpression()`, `removeLastToken()`, the three `find...Operator...` helpers, `isLastExpressionBlockHasTimeKeyword()` — unchanged. (Since unit strRepresentations may now be plural, `toString()` output may contain `"Hours"` etc.; this is what gets persisted/logged and what makes the lexer round-trip in §2 work.)

## 4. TimeConverter (`utilites/TimeConverter.kt`) — delta to calculator-engine.md §5

### 4.1 The zero-total fix (the only numeric/output behavior change)
`convertTokensToTokensWithFormat(tokensToConvert, tokensFormat, removeZeroUnits = true)` now computes ONCE, before the format loop:
```kotlin
val initialValueIsZero = reminderInMsec.compareTo(ZERO) == 0  // total of convertTokensToMScec(tokensToConvert)
```
and passes it into every `addTimeUnitToResultAndGetReminder(...)` call as a new final parameter.

`addTimeUnitToResultAndGetReminder` — ONLY the `isLast` branch changed. New shape:
```kotlin
if (isLast) {
    if (!(currentResult.compareTo(ZERO) == 0 && removeZeroUnits)) {
        // unchanged: emit NUMBER(currentResult.setScale(7, HALF_UP).stripTrailingZeros().toPlainString())
        //            with value = currentResult (unrounded), then Token(type, currentResult)
    } else {
        if (initialValueIsZero) {
            endResult.add(Token(TokenType.NUMBER, ZERO, ZERO.toPlainString()))  // "0"
            endResult.add(Token(type, ZERO))                                    // pluralized: "Hours"/"Minutes"/"MSeconds"
        }
    }
}
```
The non-last branch is unchanged except value plumbing (no zero-emission there — intermediate zero units are still skipped).

Exact before/after vs MASTER:
- Total ≠ 0 ms: output is IDENTICAL to master (modulo plural strRepresentations). A non-zero result whose last unit is 0 still omits that unit: 7,200,000 ms with `Hour Minute` → "2 Hours" (NOT "2 Hours 0 Minutes").
- Total == 0 ms AND removeZeroUnits == true: master returned an EMPTY Tokens list; the branch returns exactly `[NUMBER "0" (value ZERO), <lastFormatUnit> (value ZERO, plural)]`. Examples:
  - `5 Minute − 5 Minute`, format `Hour Minute` → master: empty → branch: "0 Minutes".
  - format `Hour` → "0 Hours"; format `All Units` (… MSecond last) → "0 MSeconds".
  - ERROR result `[ERROR "ERROR"]` (e.g. division by zero): convertTokensToMScec ignores ERROR → total 0 → branch shows "0 <lastUnit>s" (master: empty). The error is now masked as a zero.
  - Empty input Tokens → total 0 → "0 <lastUnit>s" (master: empty).
- `removeZeroUnits == false`: unchanged (zero last unit takes the normal emit path, as in master).
- Side effect: the master-spec crash `PerUnitsRepository units[0]` (IndexOutOfBounds on zero/ERROR totals) no longer occurs — single-unit format conversion now returns `["0", unit]`, and the per-card math yields amount × 0 = 0.

Lineage (do NOT port the intermediate state): commit `a6470ba` ("Fixed bug with empty result in case of 0 Result") added the else-branch UNCONDITIONALLY, which made every non-zero result whose last format unit was 0 grow a trailing "0 <unit>" (e.g. "2 Hours 0 Minutes") — that is the "bug with trailing zero" that commit `994973d` fixed by gating the else on `initialValueIsZero`. Net-of-branch == master behavior + zero-total emission only.

### 4.2 Value plumbing (no numeric changes)
All emissions in `convertExpressionInMsecsToNearest`, `convertExpressionToMsecs`, `convertTokensToMScecToken`, `convertTokensToTokensWithFormat` now pass values per the §1.2 table. `convertExpressionInMsecsToType` was refactored to compute `var tempValue: BigDecimal = ZERO` once per branch (`tempValue = token.strRepresentation.toBigDecimal() / MILLISECONDS_IN_X`, Kotlin `/` = HALF_EVEN at dividend scale — unchanged math) and emits `Token(NUMBER, tempValue, tempValue.toPlainString())` then `Token(type, tempValue)` — so the trailing unit token now pluralizes by the converted amount (e.g. 1 Year→MONTH yields "12 Months"; 12.5 Month→YEAR yields value 1.0 → singular "Year"). For unhandled target types the appended `Token(type, ZERO)` carries value 0 (was `Token(type)`).
- `convertMsecsToMSecsInType`, `convertTokensToMScec` (incl. its MSECOND branch), `convertPartOfUnitToMScec` (still NO MSECOND branch), all scales/rounding modes (26 HALF_UP intermediates, 0 DOWN truncation, 7 HALF_UP + stripTrailingZeros finals/remainders): UNCHANGED.
- `convertTokensToMScecToken` still lacks the MSECOND branch (master bug retained).

## 5. CalculatorOfTime (`engine/calculator/CalculatorOfTime.kt`) — delta to calculator-engine.md §3

Pure value plumbing; pipeline, trailing-operator cleanup, exp4j string, exception → ERROR are unchanged. Success return is now:
```kotlin
[ Token(NUMBER, result, resultAsString /* = result.toString(), may be sci-notation */),
  Token(MSECOND, result) ]
```
so the MSECOND tag's strRepresentation is `"MSeconds"` whenever the msec total ≠ 1 (display-only; downstream matches by type). Error return: `Token(ERROR, 1.toBigDecimal(), "ERROR")`. `setParenthesesToExpression` parens get value 1; copied tokens are recreated as `Token(token.type, token.value, token.strRepresentation)`.

## 6. Extension.kt / rendering — delta to lexer-tokens.md §5

- `String.toHTMLWithGreenColor(context: Context)` → `spannable { size(0.7f, color(ContextCompat.getColor(context, R.color.colorExpressionTime), this)) }`. colorExpressionTime = colorTimeBtns = `#33691e` light (same value as master's hardcoded), `#53654D` dark.
- `String.toHTMLWithLightGreenColor(context)` → colorResultTime = `#567749` light (CHANGED from `#4c992e`), `#727C6E` dark. Still 0.7 size.
- `String.toHTMLWithGrayColor(context)` → colorResultNums = `#CC474646` light (semi-transparent, CHANGED from `#807e7e`), `#939292` dark — AND the body is now `spannable { size(0.7f, color(...)) }`: master had NO size span on gray, so NUMBERs and operators in `toLightSpannableString` (result line, format previews) now render at 0.7 relative size like the units.
- NEW `String.toHTMLBlackColor()` → `#000000` at 0.7f; no production caller (one commented-out call site). 
- `toHTMLWithRedColor()` (ERROR, `Color.parseColor("RED")`), `addStartAndEndSpace`, `removeAllSpaces`, `toTokens`, `toToken`, `toTokenInMSec`: unchanged.

## 7. Engine-boundary repository changes (context for the engine delta)

- NEW `ExpressionRepository.addToExpressionTimeUnit(elementType: TokenType): Boolean` — exact body:
```kotlin
var tokenValue = 1.toBigDecimal()
if (tokensList.isNotEmpty() && tokensList.last().type == TokenType.NUMBER) {
    tokenValue = tokensList.last().value
}
return addToExpression(Token(type = elementType, tokenValue))
```
  All 8 unit buttons now call `viewModel.addToExpressionTimeUnit(TokenType.X)` instead of `addToExpression(Token(TokenType.X))`. Validation/evaluation-trigger logic in `addToExpression` is unchanged.
- `ResultFormatsRepository.fillRepository` (calculator-engine.md §6): entry #4 `Year Month Day Minute` / `1 Year 2 Month 3 Day 4 Minute` is REPLACED by `Year Month Day Hour` / `1 Year 2 Month 3 Day 4 Hour`, and a NEW entry `Year Month Day Hour Minute` / `1 Year 2 Month 3 Day 4 Hour 5 Minute` follows it → 24 formats total; every later format shifts +1 index; default selection is still the `Hour Minute` entry (flag set directly on it, now index 18 zero-based).
- `TokensRepository` gains `fun isEmpty() = length() == 0` (trivial).

## 8. Tests (errors-and-tests.md §5) — ground truth

`app/src/test` and `app/src/androidTest` have ZERO diff between master and the branch. Consequences:
1. The branch's test module DOES NOT COMPILE: `WhenCalculateExpression.kt:131-134` and `151-154` construct `Token(TokenType.NUMBER, "5")` (String where BigDecimal is now required) and `Token(TokenType.HOUR)` (no 1-arg constructor exists). Every JUnit test is therefore un-runnable on RemoveADS; no test was added/updated for smart plural or the zero fix.
2. Had they compiled, all `WhenConvertResult` and `WhenCheckExpressionForErrors` expectations would still pass: fixtures are built via the lexer (`"360 Day".toTokens()` → `"Days"`, value 360) and actuals are built by the converter (`Token(DAY, 360)` → `"Days"`), so the plural is symmetric and the matcher compares only strRepresentation. `"1.0 Year"` fixtures stay singular (value 1.0 ≡ 1) on both sides. The 8 stale `WhenCalculateExpression` tests remain stale for the same reasons as master.
3. For the Flutter port, ADD tests pinning the new behavior: (a) zero totals — `convertTokensToTokensWithFormat` of a 0-ms input with formats `Hour Minute`, `Hour`, `Y M W D H M S MSec` → `["0","Minutes"]`, `["0","Hours"]`, `["0","MSeconds"]`; ERROR-token input → same; non-zero totals with zero last unit → unchanged (no trailing zero unit); (b) plural — `"2 Day"`→`Hour` = `["48","Hours"]`, `"62 Minute"`→`Day Hour Minute Second` = `["1","Hour","2","Minutes"]` (note singular Hour), `"12.5 Month"`→YEAR = `["1.0","Year"]` singular, negative path `0 − 10 Minute` formatted as Minute → `["-10","Minutes"]`; (c) lexer — `"2Hours"` round-trips, `"1Hour"` round-trips, value inheritance (unit with no preceding number → value 1 → singular).

## 9. Explicit non-changes (so the port doesn't drift)
- All ms constants, 30-day month / 365-day year, exp4j evaluation, parenthesization, trailing-operator cleanup, Kotlin `/` = HALF_EVEN-at-receiver-scale division, scale-26/scale-7/scale-0 rounding pipeline, `removeZeroUnits` default true, format-token ordering semantics, error-rule order R0–R7, the Per-unit math (`amount × units[0]`), `toString()` ASCII operator mapping: all unchanged.

## Suspected bugs
- Branch test module does not compile: app/src/test/.../WhenCalculateExpression.kt:131-134,151-154 still call Token(TokenType.NUMBER, "5") and Token(TokenType.HOUR), which no longer match any constructor after `value: BigDecimal` became a required second parameter. All JUnit tests are un-runnable on origin/RemoveADS; the smart-plural and zero-fix behaviors have no test coverage.
- Stale plural from first keypress: UI digit buttons create Token(NUMBER, value=<digit>) and mergeNumberToNumber/deleteOneLastSymbolInNumber mutate strRepresentation but never `value` (it is a val). Typing "1","2","Hour" yields a NUMBER token with strRepresentation "12" but value 1, so addToExpressionTimeUnit inherits 1 and displays the wrong singular "12 Hour". "0.5 Hours" only looks right because the first digit 0 != 1.
- Double-pluralization on copy: Token's init appends 's' on EVERY construction, including copies that pass an already-pluralized strRepresentation. Tokens.clone() (called at the top of CalculatorOfTime.evaluate) turns HOUR(value 2, "Hours") into "Hourss", and setParenthesesToExpression copies again into "Hoursss". Currently invisible (units are replaced by type before exp4j and the clone is discarded), but any future display of cloned tokens corrupts. A Dart port should pluralize from the base type.value, never from the incoming string.
- Lexer cursor over-advance on legacy singular text: cursor advances by strRepresentation.length AFTER pluralization, so re-lexing "2Hour+3Minute" (singular form, value!=1 — e.g. an expression persisted by the master-era app) produces "Hours" (length 5) and swallows the '+' operator; "1Hours" leaves a stray trailing ERROR token. Round-trip is only safe for strings the new code itself emitted.
- Lexer can now throw at lex time: findCurrentDigitalToken calls m.group().toBigDecimal(), so a malformed number match like "1..2"/"1.2.3" (regex -?[\d\.]+ still accepts them) throws NumberFormatException during analyze(); master stored the string and failed later/softly.
- Last-format-unit plural uses the UNROUNDED value: addTimeUnitToResultAndGetReminder emits NUMBER text rounded to 7dp HALF_UP but Token(type, currentResult) with the unrounded scale-26 value; a value like 1.00000004 hours displays "1 Hours" (rounded text 1, plural from raw != 1).
- Zero/ERROR masking: because convertTokensToMScec ignores ERROR tokens, a division-by-zero result ([ERROR "ERROR"]) now renders as "0 <unit>s" instead of an empty result (master) — the error is presented as a legitimate zero. Likewise an empty expression evaluation renders "0 <unit>s".
- findCurrentLetterToken's ERROR fallback inherits the preceding NUMBER's value (Token(ERROR, tokenValue)) instead of 1 — currently harmless (ERROR never pluralizes) but semantically wrong and inconsistent with the dispatch-level ERROR token (value 1).
- Carried over unfixed from master (still present on the branch): convertTokensToMScecToken and convertPartOfUnitToMScec lack MSECOND branches; convertExpressionInMsecsToType for non-unit target types returns a malformed 1-token list (now Token(type, ZERO)); toHTMLWithRedColor still uses Color.parseColor("RED"); ERROR tokens still skip 5 chars in the lexer.

## Flutter porting notes
- lib/engine/token.dart — add a `BigDecimal value` field as a required constructor parameter (positional second, before the optional strRepresentation, mirroring Kotlin `Token(type, value, strRepresentation = type.value)`), and implement the plural init: if type.isTimeKeyword && value.compareTo(BigDecimal.one) != 0 then strRepresentation += 's'. Recommendation: derive the plural from type.value + 's' rather than appending to the incoming string, to avoid the Kotlin double-'s'-on-copy bug; document the deviation.
- lib/engine/big_decimal.dart — needs a usable `one` constant and scale-insensitive compareTo (already present); ZERO.toPlainString() must be "0" for the zero-emission tokens.
- lib/engine/lexical_analyzer.dart — thread the in-progress Tokens list into the letter-token routine; inherit value from tokens.last when it is a NUMBER else 1; NUMBER tokens get value = BigDecimal.parse(match); operator/fallback ERROR tokens get value 1. Keep cursor advance = strRepresentation.length so "2Hours" round-trips; decide whether to reproduce or fix the over-advance on legacy singular input and the new lex-time NumberFormatException for "1..2" (both documented in the spec).
- lib/engine/tokens.dart — clone() must copy `value`; if you keep the recommended type.value+'s' pluralization, clone stays corruption-free without special-casing.
- lib/engine/calculator_of_time.dart — pass the msec result BigDecimal as value into both the NUMBER token and the MSECOND tag (tag becomes "MSeconds" when total != 1); ERROR token value 1; parentheses tokens value 1; copied tokens keep token.value.
- lib/engine/time_converter.dart — in convertTokensToTokensWithFormat compute `initialValueIsZero = total.compareTo(zero) == 0` before the loop and pass into _addTimeUnitToResultAndGetReminder; in the isLast branch add the else: if (initialValueIsZero) emit Token(NUMBER, zero, "0") + Token(type, zero). Thread values into every Token construction per the spec table (non-last unit: rounded value; last unit: unrounded currentResult; convertExpressionInMsecsToType: tempValue on both NUMBER and unit; convertExpressionToMsecs: constants/1).
- lib/data/repositories.dart — add ExpressionRepository.addToExpressionTimeUnit(TokenType) with the value-inheritance body from the spec; lib/state/calculator_model.dart — add the matching addToExpressionTimeUnit that triggers evaluation like addToExpression; lib/ui/widgets/keypad.dart (or wherever unit buttons dispatch) — switch the 8 unit buttons to it, and make digit buttons create Token(number, value: digit, text: digit).
- lib/data/result_formats.dart — replace the "Year Month Day Minute" format (preview "1 Year 2 Month 3 Day 4 Minute") with "Year Month Day Hour" (preview "1 Year 2 Month 3 Day 4 Hour") and insert a new "Year Month Day Hour Minute" (preview "1 Year 2 Month 3 Day 4 Hour 5 Minute") right after it — 24 formats; keep "Hour Minute" as the default-selected entry (index shifts to 18).
- lib/ui/spans.dart + lib/ui/theme.dart — make token colors theme-resolved: expression units colorExpressionTime (#33691E light / #53654D dark), result/preview units colorResultTime (#567749 light — CHANGED from #4C992E — / #727C6E dark), gray numbers+operators colorResultNums (#CC474646 light with alpha / #939292 dark — CHANGED from #807E7E); ALSO apply the 0.7 relative-size factor to the gray (number/operator) spans in tokensToLightSpans — master rendered them full size. The new toHTMLBlackColor (#000000, 0.7) has no production caller; skip it.
- test/convert_result_test.dart, test/calculate_expression_test.dart, test/tokens_matcher.dart — fixtures built via the lexer remain valid (plural is symmetric); fixtures built with direct Token(...) constructors need the new value argument. Add the new ground-truth cases from spec §8.3: zero totals → ["0", "<Unit>s"], plural/singular boundaries (value 1 vs 1.0 vs 0 vs negative), "62 Minute"→"1 Hour 2 Minutes", and lexer round-trip of "2Hours"/"1Hour".
- Behavioral ripple to verify in lib/state/calculator_model.dart / lib/ui/per_screen.dart: with the zero-emission, per-unit cards no longer hit the empty-list crash for zero/ERROR results (units[0] now exists and computes 0); the result line shows "0 Minutes" (default format) for zero totals, including after delete-to-empty re-evaluation — decide whether to keep the "0 <unit>" display for ERROR results or surface the error instead (the Kotlin branch masks it).
