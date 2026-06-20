# errors-and-tests

## Summary
This area is the expression-validation engine (`isErrorsInExpression` / `isErrorAfterCheckForPoint` in CheckErrorsInExpression.kt) plus the three JUnit test files that pin down ground-truth behavior for calculation, time-unit conversion, and error checking. `isErrorsInExpression` is a token-pair gatekeeper called before every token append in ExpressionRepository: it silently rejects (returns true) illegal sequences such as double operators, operator+time-keyword, double time-keywords, leading operators/keywords, +/− after a unit-less number block, and multiplying/dividing two time quantities. The tests exercise this gatekeeper (44 cases, all passing), the BigDecimal-based TimeConverter (17 cases, all passing), and CalculatorOfTime.evaluate (9 cases, of which 8 are stale and cannot pass against the current engine, which now always returns `[NUMBER msecValue, MSECOND]`).

## Detailed spec
# Spec: Expression Error Checking + Ground-Truth Unit Tests

Source files (absolute paths):
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/engine/expression/CheckErrorsInExpression.kt`
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/test/java/com/dmitriykargashin/cardamontimecalculator/WhenCalculateExpression.kt`
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/test/java/com/dmitriykargashin/cardamontimecalculator/WhenConvertResult.kt`
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/test/java/com/dmitriykargashin/cardamontimecalculator/WhenCheckExpressionForErrors.kt`
Supporting (read for exactness): `data/tokens/TokenType.kt`, `data/tokens/Token.kt`, `data/tokens/Tokens.kt`, `engine/lexer/LexicalAnalyzer.kt`, `engine/calculator/CalculatorOfTime.kt`, `engine/calculator/CalculatorOfTimeConst.kt`, `utilites/TimeConverter.kt`, `data/repository/ExpressionRepository.kt`, `internal/extension/Extension.kt`, `ui/calculator/CalculatorViewModel.kt`, `ui/calculator/CalculatorActivity.kt`.

---

## 1. Token model (prerequisite for all rules/tests)

`TokenType` (sealed class; each has a canonical `value` string — EXACT, including Unicode glyphs):

| Type | value | Notes |
|---|---|---|
| PLUS | `+` (U+002B) | operator |
| MINUS | `−` (U+2212, math minus, NOT ASCII hyphen) | operator |
| MULTIPLY | `×` (U+00D7) | operator |
| DIVIDE | `÷` (U+00F7) | operator |
| PARENTHESESLEFT | `(` | internal only |
| PARENTHESESRIGHT | `)` | internal only |
| NUMBER | `0.0` (placeholder; real value lives in `strRepresentation`) | |
| YEAR | `Year` | time keyword |
| MONTH | `Month` | time keyword |
| WEEK | `Week` | time keyword |
| DAY | `Day` | time keyword |
| HOUR | `Hour` | time keyword |
| MINUTE | `Minute` | time keyword |
| SECOND | `Second` | time keyword |
| MSECOND | `MSecond` | time keyword |
| ERROR | `ERROR` | |
| DOT | `.` | created only by the UI dot button; the lexer never emits DOT |

Predicates (TokenType.kt:78-79):
- `isOperator()` ⇔ type ∈ {PLUS, MINUS, DIVIDE, MULTIPLY}
- `isTimeKeyword()` ⇔ type ∈ {YEAR, WEEK, MONTH, DAY, HOUR, MINUTE, SECOND, MSECOND}

`Token(type)` secondary constructor sets `strRepresentation = type.value`. `Token(type, strRepresentation)` for numbers.

`Tokens` = `ArrayList<Token>`. `Tokens.toString()` concatenates with NO spaces, mapping PLUS→`+`, MINUS→`-`, DIVIDE→`/`, MULTIPLY→`*`, everything else → `strRepresentation` (so `[10, Minute, +, 5, Hour]` → `"10Minute+5Hour"`).

### Lexer (`LexicalAnalyzer.analyze(string)`) — how test inputs become tokens
1. All spaces removed first (`removeAllSpaces`).
2. Scan left-to-right; advance by the produced token's `strRepresentation.length`.
3. Digit at cursor → NUMBER via Java regex `-?[\d\.]+` with `Matcher.find(currentPosition)`; the matched group is the strRepresentation (multiple dots like `5.5.5` lex as ONE number).
4. Letter at cursor → case-sensitive `startsWith` check in order: `Year`, `Month`, `Week`, `Day`, `Hour`, `Minute`, `Second`, `MSecond`; otherwise ERROR.
5. Operator at cursor → accepts BOTH the Unicode glyphs (`+ − × ÷`) and ASCII `- / * +`; emits the canonical token (e.g. ASCII `-` → MINUS token whose strRepresentation is `−`).
6. Anything else (including `.`) → `Token(ERROR)` with strRepresentation `"ERROR"` (length 5, so the cursor jumps 5 chars).

Test helpers (Extension.kt): `String.toTokens()` = `LexicalAnalyzer.analyze(this)`; `String.toToken()` = `analyze(this).last()`; `String.toTokenInMSec()` = `TimeConverter.convertTokensToMScecToken(analyze(this))`. **Important:** `".".toToken()` therefore yields an ERROR token, not DOT.

### `Tokens.isLastExpressionBlockHasTimeKeyword()` (Tokens.kt:159-176) — used by rules R2/R7
1. Scan from the end toward index 0; stop at the first PLUS or MINUS token (MULTIPLY/DIVIDE do NOT delimit blocks). If none found, start index = 0; otherwise start index = the operator's own index.
2. From that start index to the end, return true if any token `isTimeKeyword()`; else false.
Examples: `[10, Hour, /, 2]` → no +/− → scans all → true. `[10, Hour, +, 2]` → stops at `+` (index 2), scans `[+, 2]` → false. `[]` → false.

---

## 2. `isErrorsInExpression(expressionForAdd: Token, expression: Tokens): Boolean`
(CheckErrorsInExpression.kt:12-75). Returns **true = ERROR** (the candidate token must be rejected), **false = legal**. There are no error messages; rejection is silent — `ExpressionRepository.tryToAddToExpression` simply does not append the token and returns false. The only user-visible "error" artifact anywhere is the token `Token(ERROR, "ERROR")` produced by `CalculatorOfTime.evaluate` when exp4j throws (rendered red, relative size 0.7, via `toHTMLWithRedColor` using `Color.parseColor("RED")`).

Rules, evaluated strictly in this order (first match wins):

- **R0 (line 25):** `expression.isEmpty() && add.type == NUMBER` → **false** (always legal to start with a number).
- **R1 (lines 29-30):** `expression.isEmpty() && (add.isTimeKeyword() || add.isOperator() || add.type == DOT)` → **true**. (Expression may not start with a time keyword, any operator, or a dot.)
- *(Implicit edge: if expression is empty and add is any OTHER type — ERROR, PARENTHESES — execution falls through to `expression.last()` and throws `NoSuchElementException`. See suspectedBugs.)*
- Let `last = expression.last()`, `blockHasTime = expression.isLastExpressionBlockHasTimeKeyword()`.
- **R2 (lines 37-41)** "operator after number w/o time unit": `last.type == NUMBER && (add.type == PLUS || add.type == MINUS) && !blockHasTime` → **true**. Note: only PLUS/MINUS are blocked here; MULTIPLY/DIVIDE after a bare number are legal (`5` + `×` → ok). Also note the block test means `10 Hour + 2` + `+` is an ERROR (the last block `2` has no unit).
- **R3 (lines 45-46)** "double operators": `last.isOperator() && add.isOperator()` → **true** (all 16 operator-pair combinations).
- **R4 (lines 49-50)** "dot after operator": `last.isOperator() && add.type == DOT` → **true**.
- **R5 (lines 53-56)** "operator then time keyword": `last.isOperator() && add.isTimeKeyword()` → **true** (e.g. `0/` + `Year`, `5 Year ×` + `Year`).
- **R6 (lines 59-60)** "double time keywords": `last.isTimeKeyword() && add.isTimeKeyword()` → **true** (e.g. `0 Year` + `Year`).
- **R7 (lines 63-71)** "multiply/divide two time quantities": only if `expression.size > 1`; let `preLast = expression[size-2]`; `blockHasTime && (preLast.type == MULTIPLY || preLast.type == DIVIDE) && add.isTimeKeyword()` → **true**. (e.g. `10 Hour / 2` + `Hour` → error; `10 / 2` + `Hour` → legal because block has no time keyword.)
- **Default:** **false**.

Sequences therefore implicitly LEGAL (no rule fires): NUMBER after anything; any operator after a time keyword; MULTIPLY/DIVIDE after a bare number; time keyword after NUMBER (when R7 conditions absent); DOT after NUMBER; **DOT after time keyword** (likely an oversight — see suspectedBugs); ERROR-typed token after anything (falls to default false).

## 3. `isErrorAfterCheckForPoint(expressionForAdd: String, expression: String): Boolean`
(CheckErrorsInExpression.kt:77-93). Note: takes **Strings**, not tokens. Returns true = error.
- If `expressionForAdd != "."` → **false** (treated as "no error", i.e. not applicable).
- If `expressionForAdd == "."`:
  - `expression` non-empty AND its last character is a digit (`Char.isDigit()`) → **false** (dot is allowed);
  - otherwise (empty expression, or last char not a digit, e.g. `"5."`, `"5+"`, `"5 Month"`) → **true** (error).
This function currently has **no production callers** (only commented-out tests reference it); duplicate-dot protection actually lives in `Token.addDotToNumber()` (appends `.` only if `strRepresentation` does not already contain `.`).

## 4. Behaviors the tests depend on (exact)

### 4.1 Time constants (CalculatorOfTimeConst.kt — all `BigDecimal`)
- `MILLISECONDS_IN_SECOND = 1000`
- `SECONDS_IN_MINUTE = 60`, `MINUTES_IN_HOUR = 60`, `HOURS_IN_DAY = 24`, `DAYS_IN_WEEK = 7`, `DAYS_IN_MONTH = 30`, `DAYS_IN_YEAR = 365`
- Derived: `MILLISECONDS_IN_MINUTE = 60_000`; `MILLISECONDS_IN_HOUR = 3_600_000`; `MILLISECONDS_IN_DAY = 86_400_000`; `MILLISECONDS_IN_WEEK = 604_800_000`; `MILLISECONDS_IN_MONTH = 2_592_000_000` (30-day month); `MILLISECONDS_IN_YEAR = 31_536_000_000` (365-day year).

### 4.2 TimeConverter functions under test
- `convertTokensToMScecToken(tokens) → Token(NUMBER, total.toPlainString())`: walks tokens; NUMBER sets `currentNumber`; each time keyword adds `currentNumber × unitMs` to the accumulator (currentNumber is NOT reset; a trailing bare number contributes nothing). MSECOND is NOT handled here (only in the private `convertTokensToMScec`, which adds `currentNumber` for MSECOND).
- `convertExpressionInMsecsToType(token, type) → Tokens [NUMBER, type]`: value = `token.strRepresentation.toBigDecimal() / unitMs` where `/` is Kotlin's `BigDecimal.div` ⇒ `divide(other, RoundingMode.HALF_EVEN)` with **result scale = dividend's scale**. Then `toPlainString()`. This is why `1 Year → Month` gives `12` (12.1666… rounded at scale 0) and `12.5 Month → Day` gives `375.0` / `→ Year` gives `1.0` (dividend scale 1). For MSECOND: value passed through unchanged.
- `convertTokensToTokensWithFormat(tokensToConvert, tokensFormat, removeZeroUnits = true) → Tokens`: `rem = convertTokensToMScec(tokensToConvert)`; for each format token (in order; `isLast` = last index):
  - `cur = rem.setScale(26, HALF_UP) / unitMs` (Kotlin div ⇒ HALF_EVEN, scale 26).
  - If `isLast`: unless (`cur == 0` && removeZeroUnits), append `Token(NUMBER, cur.setScale(7, HALF_UP).stripTrailingZeros().toPlainString())` + `Token(type)`. Remainder returned is 0.
  - Else: `rounded = cur.setScale(0, DOWN)` (truncate); `frac = (cur − rounded).setScale(26, HALF_UP)`; unless (`rounded == 0` && removeZeroUnits), append `Token(NUMBER, rounded.toPlainString())` + `Token(type)`; new remainder = `frac == 0 ? 0 : frac × unitMs`.
  - Each returned remainder is `setScale(7, HALF_UP).stripTrailingZeros()`.
  Net effect: intermediate units are floored integers, zero terms are skipped, the last unit keeps up to 7 decimal places (HALF_UP, trailing zeros stripped, plain string — e.g. `16.6666667`, `0.4366667`, `3052.8`, `48`).

### 4.3 CalculatorOfTime.evaluate(tokens) — CURRENT contract
- Clone input. If `isSimpleArithmeticExpression()` (contains no time keywords): evaluate directly. Else: wrap each NUMBER…(units) run in parentheses (`setParenthesesToExpression`), replace units via `convertExpressionToMsecs` (NUMBER → `+ n`; unit → `× unitMs`; operators/parens copied), then evaluate.
- `evaluateSimpleArithmeticExpression`: drop trailing operator; drop trailing `)`+operator pair; if string empty → empty Tokens; else build exp4j `ExpressionBuilder(tokens.toString())`, `evaluate()` (returns Double), `toBigDecimal()` (via Double.toString), and return **`[Token(NUMBER, result.toString()), Token(MSECOND)]`** — i.e. ALWAYS a 2-token msec result like `["10.0", MSecond]`. Any exception (parse error, exp4j `ArithmeticException("Division by zero!")`, etc.) → `[Token(ERROR, "ERROR")]`.
- Real display pipeline (CalculatorViewModel.evaluateExpression): `evaluate(...)` → `convertTokensToTokensWithFormat(result, selectedFormat.formatTokens)` → display.

### 4.4 ExpressionRepository (used by 2 tests)
- `setTokens(newTokens)`: replaces list, publishes via LiveData `postValue` (tests need `InstantTaskExecutorRule`).
- `deleteLastTokenOrSymbol(): Boolean`: empty → false. If last token is not NUMBER → remove whole token; if NUMBER → drop one character from `strRepresentation`, and if it becomes `""` remove the token. Publishes via `tokens.value =`. Returns `isLastExpressionBlockHasTimeKeyword() || (newLastToken != null && newLastToken.type != NUMBER)` (i.e. "caller should re-evaluate").
- `addToExpression(token): Boolean` ("should re-evaluate"): operators → try add (gated by `isErrorsInExpression`), always return false. DOT/NUMBER with trailing NUMBER → merge into it (`addDotToNumber` / `mergeNumberToNumber`), return a re-evaluate flag that is true only when the last block has a time keyword AND the nearest operator from the end is ×/÷ AND (the token before that operator is not a NUMBER, OR it is a NUMBER and the token two before the operator is also ×/÷). DOT/NUMBER otherwise → try add, same flag. Time keywords → try add, return whether the add succeeded.

### 4.5 Test equality matcher `isEqualTo(expectedTokens)` (WhenCalculateExpression.kt:29-47)
Hamcrest `TypeSafeDiagnosingMatcher<Tokens>`: matches iff sizes are equal AND `strRepresentation` is equal at every index. **Token types are NOT compared.**

---

## 5. Test tables — EVERY case, exact strings

### 5.1 WhenCalculateExpression.kt — `calculateExpression(s) = CalculatorOfTime.evaluate(LexicalAnalyzer.analyze(s))`
`addStartAndEndSpace()` wraps in single spaces; interpolated operator glyphs shown literally. Status column = whether the test can pass against the CURRENT engine (see suspectedBugs #1).

| Test | Input string (exact) | Assertions (exact) | Status vs HEAD |
|---|---|---|---|
| `Calculate Empty expression` | `""` | result isEqualTo `"".toTokens()` (empty list) | passes |
| `calculate_Expr_0_plus_10_Equals_10` | `0 + 10` | `lastIndex == 0`; `tokens[0].strRepresentation == "10"` | STALE (actual: `["10.0", MSecond]`) |
| `calculate_Expr_0_minus_10_Equals_minus10` | `0 − 10` (U+2212) | `lastIndex == 0`; `tokens[0].strRepresentation == "-10"` (ASCII hyphen) | STALE |
| `calculate_Expr_0_multiply_10_Equals_0` | `0 × 10` | `lastIndex == 0`; `tokens[0].strRepresentation == "0"` | STALE |
| `calculate_Expr_0_divide_10_Equals_0` | `0 ÷ 10` | `lastIndex == 0`; `tokens[0].strRepresentation == "0"` | STALE |
| `calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute` | `10 Minute+ 5 Hour` | `lastIndex == 3`; `[0].strRep == "5"`; `[1].type.value == "Hour"`; `[2].strRep == "10"`; `[3].type.value == "Minute"` | STALE |
| `calculate_Expr_10Minute_multiply_5_Equals_50Minute` | `10 Minute  × 5` (two spaces before ×) | `lastIndex == 1`; `[0].strRep == "50"`; `[1].type.value == "Minute"` | STALE |
| `calculate_Expr_10Minute_plus_5Hour_Equals_5Hour10Minute_a` | `10 Minute + 5 Hour` | isEqualTo `[NUMBER "5", HOUR "Hour", NUMBER "10", MINUTE "Minute"]` | STALE |
| `calculate_Expr_5Hour_Minus_10_Minute_Equals_4Hour50Minute` | `5 Hour-10 Minute` (ASCII hyphen) | isEqualTo `[NUMBER "4", HOUR "Hour", NUMBER "50", MINUTE "Minute"]` | STALE |

These STALE tests encode the OLD contract (evaluate returned a human-formatted nearest-units result). The Dart port must decide: reproduce the current engine (`[NUMBER msec, MSECOND]` then format via convertTokensToTokensWithFormat) and rewrite these tests, or reproduce the historical end-to-end expectations (recommended as integration tests through evaluate+format: `10 Minute + 5 Hour` ⇒ `5 Hour 10 Minute`; `5 Hour − 10 Minute` ⇒ `4 Hour 50 Minute`; `10 Minute × 5` ⇒ `50 Minute`).

### 5.2 WhenConvertResult.kt — all use `isEqualTo` (size + per-index strRepresentation)

Group A — `TimeConverter.convertExpressionInMsecsToType(input.toTokenInMSec(), targetType)`:

| Test name (exact) | Input → msec token | Target type | Expected tokens (from `"…".toTokens()`) |
|---|---|---|---|
| `Convert Result 10 Year to 10 Year` | `"10 Year"` → NUMBER `315360000000` | YEAR | `[NUMBER "10", YEAR "Year"]` |
| `Convert Result 1 Year to 12 Month` | `"1 Year"` → `31536000000` | MONTH | `[NUMBER "12", MONTH "Month"]` (12.1666… HALF_EVEN at scale 0) |
| `Convert Result 12 Month to 360 Day` | `"12 Month"` → `31104000000` | DAY | `[NUMBER "360", DAY "Day"]` |
| `Convert Result 12,5 Month to 375 Day` | `"12.5 Month"` → `32400000000.0` (scale 1) | DAY | `[NUMBER "375.0", DAY "Day"]` |
| `Convert Result 12,5 Month to 1,0273972602739727 Year` | `"12.5 Month"` → `32400000000.0` | YEAR | `[NUMBER "1.0", YEAR "Year"]` (1.0273… HALF_EVEN at scale 1) |

Group B — `TimeConverter.convertTokensToTokensWithFormat(input.toTokens(), format.toTokens())`:

| Test name (exact) | Input | Format string | Expected tokens |
|---|---|---|---|
| `Convert Result 2 Day to 48 Hour` | `"2 Day"` | `"Hour"` | `[NUMBER "48", HOUR]` |
| `Convert Result 2,1 Day to 50,4 Hour` | `"2.1 Day"` | `"Hour"` | `[NUMBER "50.4", HOUR]` |
| `Convert Result 48 Hour to 48 Hour` | `"48 Hour"` | `"Hour"` | `[NUMBER "48", HOUR]` |
| `Convert Result 2,1 Day to 50 Hour 24 Minute` | `"2.1 Day"` | `"Hour Minute"` | `[NUMBER "50", HOUR, NUMBER "24", MINUTE]` |
| `Convert Result 2,1 Day to 24 Minute` | `"2.1 Day"` | `"Minute"` | `[NUMBER "3024", MINUTE]` |
| `Convert Result 2,12 Day to 24 Minute` | `"2.12 Day"` | `"Minute"` | `[NUMBER "3052.8", MINUTE]` |
| `Convert Result 2,12 Day to Month` | `"2.12222222 Day"` | `"Month"` | `[NUMBER "0.0707407", MONTH]` (from `"0.0707407Month".toTokens()`) |
| `Convert Result 12 Day to 12 Day` | `"12 Day"` | `"Day"` | `[NUMBER "12", DAY]` |
| `Convert Result 12 Day to Year Month Day Minute Second` | `"0.1 Day"` | `"Year Month Day Hour Minute Second"` | `[NUMBER "2", HOUR, NUMBER "24", MINUTE]` (zero units skipped) |
| `Convert Result 12 Day to Month` | `"13.1 Day"` | `"Month "` | `[NUMBER "0.4366667", MONTH]` |
| `Convert Result 240000Msec to Minute` | `"235000 Second"` | `"Hour Minute "` | `[NUMBER "65", HOUR, NUMBER "16.6666667", MINUTE]` |
| `Convert Result 240000Msec to Day Hour Minute Second` | `"62 Minute"` | `"Day Hour Minute Second "` | `[NUMBER "1", HOUR, NUMBER "2", MINUTE]` |

(Note: several test NAMES are misleading — e.g. "12 Day to Month" actually converts 13.1 Day; "240000Msec…" actually converts 235000 Second / 62 Minute. The inputs in this table are what the code does.)

### 5.3 WhenCheckExpressionForErrors.kt — `assert(isErrorsInExpression(toAdd, expr))` / `assert(!…)`
`expr = "…".toTokens()`, `toAdd = "…".toToken()` (last lexed token). Expected: ERROR = function returns true; OK = returns false. All 44 tests pass at HEAD. Class has `@get:Rule val rule = InstantTaskExecutorRule()`.

| # | Test name (exact) | expression string | token-to-add string | Expected |
|---|---|---|---|---|
| 1 | `Check expression for double PLUS` | `"0+"` | `"+"` | ERROR (R3) |
| 2 | `Check expression for double MINUS` | `"0-"` | `"-"` | ERROR (R3) |
| 3 | `Check expression for double DIV` | `"0/"` | `"/"` | ERROR (R3) |
| 4 | `Check expression for double MULTIPLY` | `"0*"` | `"*"` | ERROR (R3) |
| 5 | `Check expression for OPERATORS * and div ` | `"0*"` | `"/"` | ERROR (R3) |
| 6 | `Check expression for double OPERATORS * and +` | `"0*"` | `"+"` | ERROR (R3) |
| 7 | `Check expression for double OPERATORS * and -` | `"0*"` | `"-"` | ERROR (R3) |
| 8 | `Check expression for double OPERATORS - and +` | `"0-"` | `"+"` | ERROR (R3) |
| 9 | `Check expression for double OPERATORS - and div` | `"0-"` | `"/"` | ERROR (R3) |
| 10 | `Check expression for double OPERATORS - and *` | `"0-"` | `"*"` | ERROR (R3) |
| 11 | `Check expression for double OPERATORS + and -` | `"0+"` | `"-"` | ERROR (R3) |
| 12 | `Check expression for double OPERATORS + and *` | `"0+"` | `"*"` | ERROR (R3) |
| 13 | `Check expression for double OPERATORS + and div` | `"0+"` | `"/"` | ERROR (R3) |
| 14 | `Check expression for double OPERATORS div and -` | `"0/"` | `"-"` | ERROR (R3) |
| 15 | `Check expression for double OPERATORS div and +` | `"0/"` | `"+"` | ERROR (R3) |
| 16 | `Check expression for double OPERATORS div and *` | `"0/"` | `"*"` | ERROR (R3) |
| 17 | `Check expression for double TIME KEYWORDS YEAR and YEAR` | `"0 Year"` | `"Year"` | ERROR (R6) |
| 18 | `Check expression for double TIME KEYWORDS MONTH and MONTH` | `"0 Month"` | `"Month"` | ERROR (R6) |
| 19 | `Check expression for double TIME KEYWORDS WEEK and WEEK` | `"0 Week"` | `"Week"` | ERROR (R6) |
| 20 | `Check expression for double TIME KEYWORDS DAY and DAY` | `"0 Day"` | `"Day"` | ERROR (R6) |
| 21 | `Check expression for double TIME KEYWORDS HOUR and HOUR` | `"0 Hour"` | `"Hour"` | ERROR (R6) |
| 22 | `Check expression for double TIME KEYWORDS MINUTE and MINUTE` | `"0 Minute"` | `"Minute"` | ERROR (R6) |
| 23 | `Check expression for double TIME KEYWORDS SECOND0 and SECOND` | `"0 Second"` | `"Second"` | ERROR (R6) |
| 24 | `Check expression for double TIME KEYWORDS MSecond and MSecond` | `"0 Hour"` (sic — duplicates #21, never tests MSecond) | `"Hour"` | ERROR (R6) |
| 25 | `Check expression for dividing on NUMBER with TIME OPERATOR` | `"10 Hour / 2"` | `"Hour"` | ERROR (R7) |
| 26 | `Check expression for multiplying NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR` | `"10 Hour * 2"` | `"Hour"` | ERROR (R7) |
| 27 | `Check NOT ERROR expression for dividing NUMBER with TIME OPERATOR on NUMBER with TIME OPERATOR` | `"10  / 2"` | `"Hour"` | OK |
| 28 | `Check NOT ERROR expression for multiplying on NUMBER with TIME OPERATOR` | `"10  * 2"` | `"Hour"` | OK |
| 29 | `Check NOT ERROR expression for Adding NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR` | `"10 Hour + 2"` | `"Hour"` | OK |
| 30 | `Check NOT ERROR expression for substracting NUMBER with TIME OPERATOR and NUMBER with TIME OPERATOR` | `"10 Hour - 2"` | `"Hour"` | OK |
| 31 | `Check expression for starting with OPERATOR +` | `""` | `"+"` | ERROR (R1) |
| 32 | `Check expression for starting with OPERATOR -` | `""` | `"-"` | ERROR (R1) |
| 33 | `Check expression for starting with OPERATOR *` | `""` | `"*"` | ERROR (R1) |
| 34 | `Check expression for starting with OPERATOR div` | `""` | `"/"` | ERROR (R1) |
| 35 | `Check expression for double OPERATORS div and YEAR` | `"0/"` | `"Year"` | ERROR (R5) |
| 36 | `Check expression for starting with YEAR Keyword` | `""` | `"Year"` | ERROR (R1) |
| 37 | `Check NOT ERROR expression for Number multiply` | `"5"` | `"*"` | OK (R2 only blocks +/−) |
| 38 | `Check NOT ERROR expression for + after Year Keyword` | `"5 Year"` | `"+"` | OK |
| 39 | `Check expression for Multiply NUMBER Years on Year Keyword` | `"5 Year *"` | `"Year"` | ERROR (R5) |
| 40 | `Check NOT ERROR expression for NUMBER and Month Keyword` | `"5 "` | `"Month"` | OK |
| 41 | `Check NOT ERROR expression for NUMBER and Year Keyword` | `"5 "` | `"Year"` | OK |
| 42 | `Check NOT ERROR float point()` | `"5"` | `"."` (lexes to ERROR token, NOT DOT — vacuous) | OK |

Plus two ExpressionRepository tests in the same file:

| # | Test name (exact) | Setup | Action | Expected (isEqualTo) |
|---|---|---|---|---|
| 43 | `Check for Delete symbol 55-2 result 55-` | `ExpressionRepository().setTokens("55-2".toTokens())` | `deleteLastTokenOrSymbol()` once; read `getExpression().value` | `"55-".toTokens()` = `[NUMBER "55", MINUS]` |
| 44 | `Check for TWICE Delete symbol 55-2 result 55` | same | `deleteLastTokenOrSymbol()` twice | `"55".toTokens()` = `[NUMBER "55"]` |

Commented-out (do NOT port as-is; they reference behavior that was never wired up): `Check expression for NUMBER + DOT` (`"5 + "` + `"."` expected ERROR — R4 would need a real DOT token); two `isErrorAfterCheckForPoint` tests (`"5."` + `"."` expected error; `"5 Month"` + `"."` expected error) — these don't even compile as written (pass Tokens where Strings are expected).

## 6. Acceptance criteria for the Dart port
1. `isErrorsInExpression` must reproduce rules R0-R7 in exactly this order, including the quirks: MULTIPLY/DIVIDE allowed after a unit-less number, +/− blocked after a unit-less block even mid-expression, DOT-after-keyword not blocked (unless you deliberately fix it — then update behavior docs).
2. All 44 WhenCheckExpressionForErrors cases and all 17 WhenConvertResult cases must pass byte-for-byte on the expected `strRepresentation` strings above (BigDecimal scale/rounding rules in §4.2 are load-bearing: HALF_EVEN division keeping dividend scale; scale-26 intermediates; scale-0 DOWN for non-last units; scale-7 HALF_UP + stripTrailingZeros + toPlainString for last units and remainders).
3. WhenCalculateExpression: only the empty-expression test matches the current engine; treat the other 8 as the historical end-to-end expectation (see §5.1) and decide explicitly which contract the port implements.

## Suspected bugs
- STALE TESTS: 8 of 9 tests in WhenCalculateExpression.kt (lines 71-164) cannot pass against the current engine. CalculatorOfTime.kt:79-92 ALWAYS appends a Token(MSECOND) after the result NUMBER and returns the millisecond value formatted via Double->BigDecimal->toString (e.g. "10.0", "-10.0", "3000000.0", "1.86E+7"), but the tests assert lastIndex==0 with "10"/"-10"/"0", or human-formatted unit lists like ["5",Hour,"10",Minute]. Git history confirms the human-format step (convertExpressionInMsecsToNearest) was removed from evaluate() in commits 8f204f2/f86b8bb without updating these tests. Only `Calculate Empty expression` still passes. (Reasoned from code; tests were not executed.)
- CheckErrorsInExpression.kt:32 - `expression.last()` is reached when the expression is empty and the added token type is not NUMBER/operator/time-keyword/DOT (e.g. ERROR or PARENTHESES), throwing NoSuchElementException instead of returning a boolean.
- CheckErrorsInExpression.kt - no rule blocks DOT after a time keyword: '5 Hour' + DOT passes validation, and ExpressionRepository.addToExpression (ExpressionRepository.kt:50-90) only merges DOT into a trailing NUMBER, so a literal DOT token is appended to the expression; TimeConverter.convertExpressionToMsecs (TimeConverter.kt:138-236) then silently drops it.
- CheckErrorsInExpression.kt:37-41 (rule R2) blocks + and − after ANY block lacking a time unit, including mid-expression: after '10 Hour + 2', adding '+' is rejected because the last block ('2') has no unit. This makes expressions like '10 Hour + 2 + 3' impossible to type; possibly intended (forces a unit per term) but very restrictive and worth a product decision before porting.
- isErrorAfterCheckForPoint (CheckErrorsInExpression.kt:77-93) is dead code: no production caller exists (only commented-out tests). It also returns false ('no error') for every non-'.' input, conflating 'not applicable' with 'valid', and would allow a second dot after '5.2' (last char is a digit) - the real duplicate-dot guard is hidden in Token.addDotToNumber (Token.kt:25-29).
- WhenCheckExpressionForErrors.kt:241-247 - test `Check expression for double TIME KEYWORDS MSecond and MSecond` actually uses "0 Hour" + "Hour", duplicating the HOUR test; MSECOND duplication is never tested.
- WhenCheckExpressionForErrors.kt:413-419 - `Check NOT ERROR float point()` uses ".".toToken(), which the lexer turns into a TokenType.ERROR token (dot handling in LexicalAnalyzer.kt:100-106 is commented out), so the test passes vacuously and never exercises DOT logic.
- LexicalAnalyzer.kt:172-185 - number regex "-?[\d\.]+" accepts multiple dots ("5.5.5" lexes as one NUMBER) and Matcher.find()'s boolean result is ignored (IllegalStateException if no match); the "-?" prefix is unreachable because '-' is always consumed by the operator branch first.
- LexicalAnalyzer.kt:68-112 - an unrecognized character yields Token(ERROR) whose strRepresentation "ERROR" has length 5, so the scan cursor advances 5 characters and silently swallows up to 4 valid following characters.
- ExpressionRepository.kt:139-162 - deleteLastTokenOrSymbol returns false when the remaining expression is empty or ends in a bare NUMBER (e.g. deleting from "55-" down to "55"), so CalculatorViewModel.clearOneLastSymbol (CalculatorViewModel.kt:139-149) skips re-evaluation and a stale result stays on screen.
- Tokens.kt:159-176 - isLastExpressionBlockHasTimeKeyword (pure logic) calls android.util.Log.d; unit tests only survive because app/build.gradle:71-72 sets unitTests.returnDefaultValues=true. Core data classes are needlessly Android-coupled.
- WhenConvertResult.kt - several test names lie about their inputs/expectations (e.g. `Convert Result 12 Day to Month` converts 13.1 Day; `Convert Result 240000Msec to Minute` converts 235000 Second; `Convert Result 2,1 Day to 24 Minute` expects 3024 Minute). Port the table values, not the names.

## Porting notes
- LiveData/MutableLiveData (ExpressionRepository, CalculatorViewModel): setTokens uses postValue while addToExpression/delete use value= ; tests need androidx InstantTaskExecutorRule (@get:Rule in WhenCheckExpressionForErrors). Flutter/Dart: ValueNotifier/ChangeNotifier or Stream; if synchronous, the rule has no equivalent and the postValue/setValue asymmetry disappears - keep ordering semantics in mind.
- exp4j (net.objecthunter.exp4j.ExpressionBuilder) evaluates the expression STRING and returns a Java double; CalculatorOfTime then does Double.toString -> BigDecimal, producing artifacts like "10.0" and "1.86E+7", and exp4j throws ArithmeticException("Division by zero!") which becomes Token(ERROR,"ERROR"). Dart needs an expression evaluator (e.g. math_expressions, or a hand-rolled shunting-yard over decimals). Recommend evaluating directly on decimals to avoid double round-trip artifacts - but that intentionally changes the current engine's exact output strings.
- java.math.BigDecimal is load-bearing for every WhenConvertResult expectation: Kotlin's `/` operator on BigDecimal means divide(other, RoundingMode.HALF_EVEN) with result scale = dividend's scale (this produces "12", "375.0", "1.0"); plus setScale(26, HALF_UP) intermediates, setScale(0, DOWN) floors, setScale(7, HALF_UP).stripTrailingZeros().toPlainString() finals (note stripTrailingZeros can yield scientific notation internally - toPlainString is required). Dart: package:decimal or a BigDecimal port; scale/rounding semantics must be replicated exactly.
- Unicode operator glyphs are canonical token values: MINUS="−" (U+2212), MULTIPLY="×" (U+00D7), DIVIDE="÷" (U+00F7), PLUS="+"; the lexer also accepts ASCII -, *, /, + and normalizes to the Unicode tokens; Tokens.toString() maps back to ASCII (-,*,/,+) for the evaluator. Preserve both directions in Dart.
- SpannableString rendering (Tokens.toSpannableString/toLightSpannableString + Extension.kt/SpannableFunctions.kt): unit keywords at relative size 0.7f colored #33691e (result view) or #4c992e (light/preview view), numbers/operators plain or gray #807e7e, ERROR tokens red via Color.parseColor("RED") at 0.7f. Flutter: build TextSpan trees with TextStyle(color, fontSize factor); note DOT tokens are not handled in either spannable when-branch (would render as nothing).
- Java regex Pattern/Matcher with find(startIndex) in LexicalAnalyzer.findCurrentDigitalToken: Dart RegExp has no find-from-index-returning-match-at-or-after with the same advance semantics; use matchAsPrefix at the cursor instead (and decide whether to keep the multiple-dot quirk).
- Kotlin Char.isDigit()/isLetter() are Unicode-aware; Dart needs explicit RegExp classes ([0-9], [a-zA-Z]) - sufficient here since keywords are ASCII, but document the narrowing.
- viewModelScope + cancelChildren() debounces re-evaluation on every keypress (CalculatorViewModel.addToExpression/clearOneLastSymbol). Dart: cancellable async (e.g. a generation counter or CancelableOperation); evaluation itself is fast enough to do synchronously.
- ExpressionRepository singleton via @Volatile + synchronized getInstance - Dart: a static final or top-level instance (single-threaded isolate makes the locking moot).
- android.util.Log calls inside engine/data classes (Tokens, TimeConverter, CalculatorOfTime, ExpressionRepository) rely on unitTests.returnDefaultValues=true (app/build.gradle:71-72). Strip logging or inject a logger in the Dart port so pure logic stays platform-free.
- Hamcrest TypeSafeDiagnosingMatcher `isEqualTo(Tokens)` compares ONLY list size and per-index strRepresentation, never TokenType. Replicate this looseness in Dart test matchers, otherwise expected fixtures built via the lexer (e.g. "375.0 Day".toTokens()) would over-constrain token types relative to the original tests.
- DOT tokens are produced ONLY by the UI dot button (CalculatorActivity.kt:570 creates Token(TokenType.DOT)); the lexer maps '.' to ERROR. Any Dart test helper equivalent of String.toToken() must reproduce this (".".toToken() == ERROR token), or test #42 changes meaning.
- InstantTaskExecutorRule + androidx.arch.core testing artifact are test-infrastructure only; no Dart equivalent needed once LiveData is replaced.
