# lexer-tokens

## Summary
This area defines the token model (TokenType sealed class, Token, Tokens collection) and the lexer (LexicalAnalyzer) for a time-expression calculator. The lexer strips all spaces from a raw string, then scans left-to-right producing NUMBER, time-unit (Year/Month/Week/Day/Hour/Minute/Second/MSecond), and operator (+ − × ÷, accepting ASCII aliases) tokens, falling back to an ERROR token for anything unrecognized. Tokens (an ArrayList<Token> subclass) provides string/Spannable rendering with per-type colors and sizes, plus query helpers used by the expression editor and calculator (last-operator lookup, time-keyword detection in last +/− block, etc.).

## Detailed spec
# Token model and lexical analysis — exhaustive spec

Source files:
- `/Volumes/Additional/My Projects/Apps/time-calculator/time-calculator/app/src/main/java/com/dmitriykargashin/cardamontimecalculator/data/tokens/TokenType.kt`
- `.../data/tokens/Token.kt`
- `.../data/tokens/Tokens.kt`
- `.../engine/lexer/LexicalAnalyzer.kt`
- Supporting extensions: `.../internal/extension/Extension.kt`, `.../internal/extension/SpannableFunctions.kt`

---

## 1. TokenType (sealed class, 17 singleton objects)

`sealed class TokenType { abstract val value: String }` — each subtype is an `object` (singleton, identity-comparable). Exact `value` strings, verbatim:

| TokenType | `value` | Notes |
|---|---|---|
| `PLUS` | `"+"` | ASCII plus U+002B |
| `MINUS` | `"−"` | **Unicode MINUS SIGN U+2212**, NOT ASCII hyphen |
| `PARENTHESESLEFT` | `"("` | never produced by lexer; used internally by CalculatorOfTime/TimeConverter |
| `PARENTHESESRIGHT` | `")"` | never produced by lexer |
| `MULTIPLY` | `"×"` | MULTIPLICATION SIGN U+00D7 |
| `DIVIDE` | `"÷"` | DIVISION SIGN U+00F7 |
| `NUMBER` | `"0.0"` | placeholder only; comment in source: `// current value may differ!! should use stringRepresenatation for view actual value` |
| `YEAR` | `"Year"` | |
| `MONTH` | `"Month"` | |
| `WEEK` | `"Week"` | |
| `DAY` | `"Day"` | |
| `HOUR` | `"Hour"` | |
| `MINUTE` | `"Minute"` | |
| `SECOND` | `"Second"` | |
| `MSECOND` | `"MSecond"` | capital M + capital S |
| `ERROR` | `"ERROR"` | length 5 — this matters for lexer advancement (see bug list) |
| `DOT` | `"."` | never produced by lexer (the `isDot` branch is commented out); created only by UI (`CalculatorActivity.kt:570`) for decimal-point button entry, handled by ExpressionRepository/CheckErrorsInExpression |

Methods on TokenType:
- `fun isOperator() = run { this == PLUS || this == MINUS || this == DIVIDE || this == MULTIPLY }` — true for exactly those 4. Parentheses are NOT operators.
- `fun isTimeKeyword() = run { this == YEAR || this == WEEK || this == MONTH || this == DAY || this == HOUR || this == MINUTE || this == SECOND || this == MSECOND }` — true for the 8 time units.

---

## 2. Token

`class Token(val type: TokenType, var strRepresentation: String = "")`

- Primary constructor: explicit `type` + `strRepresentation` (defaults to `""` if omitted — so `Token(TokenType.NUMBER)` via the *primary* ctor with only positional type is impossible in Kotlin; see secondary ctor).
- Secondary constructor: `constructor(type: TokenType) : this(type, type.value)` — copies `type.value` into `strRepresentation`. So `Token(TokenType.MINUS).strRepresentation == "−"`, `Token(TokenType.ERROR).strRepresentation == "ERROR"`, `Token(TokenType.NUMBER).strRepresentation == "0.0"`.
- `init` block is entirely commented out (was: strip trailing `.0` from integer-valued numbers). No-op at runtime.
- `type` is `val` (immutable); `strRepresentation` is `var` (mutable in place).

Methods (exact semantics):
- `fun addDotToNumber()` — if `strRepresentation` does not already contain `"."`, appends `"."` (`strRepresentation += "."`). **No type check** — works on any token type, callers must ensure it is a NUMBER. Idempotent w.r.t. dots: `"5"` → `"5."`; `"5."` → unchanged; `"5.2"` → unchanged.
- `fun length(): Int` — returns `strRepresentation.length` (NOT a fixed per-type length). The lexer uses this to advance its cursor.
- `fun mergeNumberToNumber(token: Token)` — `strRepresentation += token.strRepresentation`. Plain string concatenation, no type or validity checks (used when user types successive digits: `"1"` merge `"2"` → `"12"`).
- `fun deleteOneLastSymbolInNumber()` — only acts when `type == TokenType.NUMBER` AND `length() > 0`: `strRepresentation = strRepresentation.dropLast(1)`. Can leave an empty `strRepresentation` (length 0). Non-NUMBER tokens are untouched.
- `fun toTokens(): Tokens` — creates a new `Tokens()`, adds `this` (same instance, not a copy), returns it.

No `equals`/`hashCode` override — Token equality is reference identity. (Unit tests compare via `strRepresentation` only, using a custom Hamcrest matcher in `WhenCalculateExpression.kt:29-47` that checks `size` equality and per-index `strRepresentation` equality.)

---

## 3. Tokens

`class Tokens : ArrayList<Token>(), Cloneable` — a mutable list of tokens. Inherits all ArrayList operations (`add`, `removeAt`, `last`, `lastIndex`, indexing, iteration).

### clone()
`override fun clone(): Tokens` — deep copy: new `Tokens`, and for each token adds `Token(type = token.type, strRepresentation = token.strRepresentation)` (new Token objects; `type` singletons shared; strings immutable). Mutating a cloned token's `strRepresentation` does not affect the original.

### toString()
Concatenates per token with **no separators**:
- `PLUS` → `"+"`
- `MINUS` → `"-"` (**ASCII hyphen** — normalizes the Unicode `−` back to ASCII)
- `DIVIDE` → `"/"`
- `MULTIPLY` → `"*"`
- all other types → `token.strRepresentation` verbatim

Example: `[NUMBER "5", HOUR, MINUS, NUMBER "10", MINUTE]` → `"5Hour-10Minute"`.

### toStringWithSpaces()
Same mapping but each piece is prefixed with a single space (`" +"`, `" -"`, `" /"`, `" *"`, `" " + strRepresentation`), then the whole result is `.trim()`ed. Example above → `"5 Hour - 10 Minute"`.

### toSpannableString(): SpannableString  (normal/primary display)
Starts from `SpannableString("")`, appends per token via the custom `SpannableString.plus` operator (`SpannableString(TextUtils.concat(this, s))`, span-preserving):
- `NUMBER` → `strRepresentation` plain (no span, no spacing)
- `SECOND, MSECOND, YEAR, MONTH, WEEK, DAY, HOUR, MINUTE` → `strRepresentation.addStartAndEndSpace().toHTMLWithGreenColor()` = `" X "` wrapped in `RelativeSizeSpan(0.7f)` + `ForegroundColorSpan(Color.parseColor("#33691e"))` (dark green)
- `MULTIPLY, PLUS, DIVIDE, MINUS` → `strRepresentation.addStartAndEndSpace()` plain (`" + "`, `" − "`, `" × "`, `" ÷ "` — Unicode symbols since strRepresentation comes from `type.value`)
- `ERROR` → `" ERROR "` (addStartAndEndSpace) wrapped in `RelativeSizeSpan(0.7f)` + `ForegroundColorSpan(Color.parseColor("RED"))` (Android color name lookup → 0xFFFF0000)
- `DOT`, `PARENTHESESLEFT`, `PARENTHESESRIGHT` → **no branch; silently skipped** (when-statement without else)

### toLightSpannableString(): SpannableString  (dimmed/preview display)
- `NUMBER` → `strRepresentation.toHTMLWithGrayColor()` = `ForegroundColorSpan(Color.parseColor("#807e7e"))`, **no size span**, no spacing
- time keywords (same 8) → `" X "` with `RelativeSizeSpan(0.7f)` + `ForegroundColorSpan(Color.parseColor("#4c992e"))` (light green)
- operators → `" X "` with gray `#807e7e` (no size span)
- `ERROR` → `" ERROR "` with `RelativeSizeSpan(0.7f)` + red (`Color.parseColor("RED")`)
- `DOT`/parentheses → skipped

All spans applied with `Spannable.SPAN_EXCLUSIVE_EXCLUSIVE` over the full piece (see `SpannableFunctions.kt: span()`).

Exact color constants verbatim: `"#33691e"` (green), `"#4c992e"` (light green), `"#807e7e"` (gray), `"RED"` (Android named color = pure red 0xFFFF0000). Relative size factor: `0.7f`. Source comments note `//todo how to get color from colors.xml?`.

### isSimpleArithmeticExpression(): Boolean
Returns `false` if ANY token's type is one of `MSECOND, SECOND, HOUR, MINUTE, DAY, WEEK, MONTH, YEAR`; otherwise `true`. (ERROR, DOT, parentheses, operators, numbers all count as "simple". Empty list → `true`.)

### removeLastToken(): Tokens
`this.removeAt(this.lastIndex)` then returns `this` (mutates in place). **Throws `IndexOutOfBoundsException` on an empty list** (lastIndex == -1).

### findLastNearestOperatorToken(): Token?
Scans from index `size-1` down to 0; returns the first token whose `type.isOperator()` is true (i.e. the LAST operator in the list). Returns `null` if none.

### findTokenBeforeLastNearestOperatorToken(): Token?
Same backward scan for the last operator at index `i`; returns `this[i-1]` if `i > 0`, else `null`. Returns `null` if no operator exists.

### findTokenBeforeTokenBeforeLastNearestOperatorToken(): Token?
Same scan; returns `this[i-2]` if `i > 1`, else `null`; `null` if no operator.

### isLastExpressionBlockHasTimeKeyword(): Boolean
1. Scan backward from `size-1` until a token with type `PLUS` or `MINUS` is found (note: MULTIPLY/DIVIDE do NOT delimit blocks); `i` ends at that index, or `-1` if none.
2. `Log.d("Tag I", i.toString())` (Android log call inside the data class).
3. If `i < 0` set `i = 0`.
4. Scan forward from `i` to `size-1`; return `true` if any token's `type.isTimeKeyword()`.
5. Otherwise `false`. (Empty list → step 1 never runs, i=-1→0, forward loop never runs → `false`.)

---

## 4. LexicalAnalyzer

`abstract class LexicalAnalyzer` — all logic in `companion object` (effectively static). Companion holds mutable static state: `private var expressionLength = 0`.

### Public entry point
`fun analyze(stringexpression: String): Tokens`
1. Normalization: `val expression = stringexpression.removeAllSpaces()` where `removeAllSpaces()` is exactly `this.replace(" ","")` — removes **only ASCII space U+0020**, not tabs/newlines/NBSP.
2. `expressionLength = expression.length` (stored in companion-level var).
3. Returns `startAnalyze(expression)`.

Also exposed via String extensions in Extension.kt: `String.toTokens() = LexicalAnalyzer.analyze(this)` and `String.toToken() = LexicalAnalyzer.analyze(this).last()` (throws on empty result) and `String.toTokenInMSec()` (analyze then `TimeConverter.convertTokensToMScecToken`).

### Main loop — `startAnalyze(expression): Tokens`
```
currentPosition = 0
while (currentPosition < expressionLength):
    tmpToken = findCurrentFullToken(expression, currentPosition)
    resultTokens.add(tmpToken)
    currentPosition += tmpToken.length()     // length of strRepresentation!
```
Cursor advancement uses the produced token's `strRepresentation.length`, which equals the consumed input length ONLY when the match was exact (digits, exact-case unit words, single-char operators). For ERROR tokens it advances by 5 (`"ERROR".length`) regardless of actual input. Empty input → empty `Tokens`.

### Character classification (private helpers)
- `isDigit(x: Char) = x.isDigit()` (Kotlin/Java `Character.isDigit` — includes Unicode digits)
- `isLetter(x: Char) = x.isLetter()`
- `isOperator(x: Char)` = true if x is any of: `TokenType.PLUS.value[0]` (`+`), `TokenType.MINUS.value[0]` (`−` U+2212), `TokenType.MULTIPLY.value[0]` (`×`), `TokenType.DIVIDE.value[0]` (`÷`), or ASCII `'-'`, `'/'`, `'*'`, `'+'`. (Eight checks combined with non-short-circuit `or`.) So both Unicode math symbols and ASCII equivalents are accepted on input.
- `isDot` is commented out — a leading `.` is NOT a recognized token start.

### Dispatch — `findCurrentFullToken(expression, currentPosition): Token`
Initializes `findedToken = Token(type = TokenType.ERROR)` (strRepresentation `"ERROR"`). Guard: `if (currentPosition <= expressionLength)` (note `<=`, off-by-one-tolerant only because the caller's while uses `<`). Then `when`:
1. digit → `findCurrentDigitalToken`
2. letter → `findCurrentLetterToken`
3. operator char → `findCurrentOperatorToken`
4. anything else (e.g. `.`, `(`, `)`, `,`, tab) → falls through, returns the ERROR token.

### Operators — `findCurrentOperatorToken`
Checked in order PLUS, MINUS, DIVIDE, MULTIPLY; each branch tests `expression[currentPosition] == TokenType.X.value[0]` `or` the ASCII alias (`'+'`, `'-'`, `'/'`, `'*'`). Returns `Token(type = TokenType.X)` via the secondary ctor, so **ASCII input is normalized to the Unicode value**: input `-` produces a token whose strRepresentation is `"−"`; `*` → `"×"`; `/` → `"÷"`. All are length 1, so the cursor advances 1 either way. Unreachable `else` returns ERROR.

### Time units — `findCurrentLetterToken`
Tested with `expression.startsWith(TokenType.X.value, currentPosition)` in this exact order: YEAR (`"Year"`), MONTH (`"Month"`), WEEK (`"Week"`), DAY (`"Day"`), HOUR (`"Hour"`), MINUTE (`"Minute"`), SECOND (`"Second"`), MSECOND (`"MSecond"`). Matching is **case-sensitive, exact prefix** — `"hour"`, `"HOUR"`, `"Hours"`(matches `"Hour"` then leaves `s` → next iteration `s` is a letter, matches nothing → ERROR token). No two values are prefixes of one another, so order is not semantically load-bearing. Any other letter sequence → `Token(type = TokenType.ERROR)` (advances cursor by 5).

The token is built with the secondary ctor, so its strRepresentation is exactly the unit word, and the cursor advances by the word length (e.g. 4 for `"Year"`, 7 for `"MSecond"`).

### Numbers — `findCurrentDigitalToken`
```kotlin
val p = Pattern.compile("-?[\\d\\.]+")
val m = p.matcher(expression)
m.find(currentPosition)
return Token(type = TokenType.NUMBER, strRepresentation = m.group())
```
- Regex verbatim: `-?[\d\.]+` (Java `Pattern.compile("-?[\\d\\.]+")`).
- `m.find(currentPosition)` finds the first match at index >= currentPosition. Because this method is only entered when the current char is a digit, the match always begins exactly at `currentPosition` and the optional leading `-?` matches empty — **the lexer never emits negative NUMBER tokens** (a preceding `-` is lexed as MINUS).
- Greedily consumes digits and dots in any arrangement: `"12"` → `"12"`; `"12.5"` → `"12.5"`; `"5."` → `"5."`; `"1.2.3"` → single NUMBER `"1.2.3"`; `"1..2"` → `"1..2"`. No numeric validation at lex time.
- The return value of `find` is not checked; `m.group()` would throw `IllegalStateException` if no match (cannot happen under the digit guard).

### End-to-end examples
- `"10 Minute+ 5 Hour"` → spaces removed → `"10Minute+5Hour"` → `[NUMBER "10", MINUTE, PLUS, NUMBER "5", HOUR]`.
- `"5 Hour-10 Minute"` → `[NUMBER "5", HOUR, MINUS, NUMBER "10", MINUTE]` (MINUS token strRepresentation `"−"`).
- `"0 × 10"` → `[NUMBER "0", MULTIPLY, NUMBER "10"]`.
- `""` → empty Tokens.
- `"abc"` → `[ERROR]` then cursor jumps 0→5 (past end) → single ERROR token.
- `".5"` → leading dot is unclassified → ERROR token, cursor 0→5, loop ends → `[ERROR]` (the `5` is swallowed).

### Test fixtures (unit tests touching the lexer, `WhenCalculateExpression.kt`)
- Custom matcher `isEqualTo(expectedTokens)`: matches iff sizes equal and each index has equal `strRepresentation` (token `type` is NOT compared).
- Asserts after lex+evaluate: `"0 + 10"`-style input built as `"0${TokenType.PLUS.value.addStartAndEndSpace()}10"`; expected single token `"10"`; minus case expects `"-10"`; multiply/divide by `"0"` expect `"0"`. `"10 Minute+ 5 Hour"` evaluates to 4 tokens: `"5"`, HOUR, `"10"`, MINUTE (asserted via `listOfResultTokens[i].strRepresentation` and `type.value`).

---

## 5. Supporting extension functions (exact bodies)
- `String.addStartAndEndSpace(): String` → `return " $this "`
- `String.removeAllSpaces(): String` → `return this.replace(" ","")`
- `String.toHTMLWithGreenColor()` → `spannable { size(0.7f, color(Color.parseColor("#33691e"), this)) }`
- `String.toHTMLWithLightGreenColor()` → `spannable { size(0.7f, color(Color.parseColor("#4c992e"), this)) }`
- `String.toHTMLWithGrayColor()` → `spannable { color(Color.parseColor("#807e7e"), this) }` (no size)
- `String.toHTMLWithRedColor()` → `spannable { size(0.7f, color(Color.parseColor("RED"), this)) }`
- `SpannableFunctions.kt`: `span(s, o)` applies the span object over `[0, length)` with `Spannable.SPAN_EXCLUSIVE_EXCLUSIVE`; `operator fun SpannableString.plus(...)` concatenates via `TextUtils.concat`, preserving spans; `spannable { ... }` just invokes the lambda.

## Suspected bugs
- LexicalAnalyzer.kt:38-49 + Token.kt:32-34 — ERROR tokens advance the cursor by strRepresentation length, which is 5 ("ERROR"), not by the actual length of the unrecognized input. A single bad character (e.g. ".", "(", ",") swallows up to 5 characters of the expression, silently dropping valid tokens after it (".5+1Hour" lexes to a single ERROR token covering ".5+1H" then continues mid-word). This is the central tokenization bug.
- LexicalAnalyzer.kt:73 — bound guard is `if (currentPosition <= expressionLength)` but the body immediately indexes `expression[currentPosition]`; if it were ever called with currentPosition == expressionLength it would throw StringIndexOutOfBoundsException. Only safe because the caller's while loop uses `<`. Should be `<`.
- LexicalAnalyzer.kt:23,30-31 — `expressionLength` is mutable companion-object (static) state shared across calls; `startAnalyze` reads it instead of `expression.length`. Not reentrant/thread-safe: concurrent or nested analyze() calls corrupt each other.
- LexicalAnalyzer.kt:175 — number regex `-?[\d\.]+` accepts multiple/trailing dots ("1.2.3", "5..", "5.") as a single NUMBER token with no validation; downstream `toDouble()` will throw or misparse. The `-?` prefix is dead (match always starts on a digit).
- LexicalAnalyzer.kt:178-182 — return value of `m.find(currentPosition)` is unchecked before `m.group()`; would throw IllegalStateException if no match (currently unreachable, but fragile if the digit guard changes).
- LexicalAnalyzer.kt:134-170 — time-unit matching is case-sensitive exact ("Year", "MSecond"); any other casing or plural ("hours", "Hours") produces ERROR tokens with the 5-char skip bug above. The matched-word check uses startsWith, so "Hourz" lexes as HOUR followed by ERROR for "z" (skipping 5).
- Tokens.kt:112-115 — `removeLastToken()` calls `removeAt(lastIndex)` with no empty check; throws IndexOutOfBoundsException(-1) on an empty Tokens list.
- Tokens.kt:55-99 — `toSpannableString()`/`toLightSpannableString()` `when` blocks have no branch for DOT, PARENTHESESLEFT, PARENTHESESRIGHT; such tokens render as nothing (silently dropped from display).
- Token.kt:25-29 — `addDotToNumber()` has no `type == NUMBER` check (unlike `deleteOneLastSymbolInNumber`); calling it on a unit/operator token mutates its strRepresentation (e.g. "Hour."), desynchronizing it from type.value and from cursor-length assumptions.
- Token.kt:40-47 — `deleteOneLastSymbolInNumber()` can leave strRepresentation == "" (a zero-length NUMBER token); a Tokens list containing it round-trips through toString() as nothing but still counts in size/index-based logic.
- TokenType.kt:35-37 — NUMBER.value is the placeholder "0.0"; `Token(TokenType.NUMBER)` via the secondary constructor silently yields a token displaying "0.0", acknowledged by the in-source comment "current value may differ!!".
- Tokens.kt:23-37 vs TokenType values — toString() maps MINUS to ASCII "-" while strRepresentation/display use Unicode "−"; any code comparing the two forms (or re-lexing toString output vs original) must handle both. Re-lexing toString() output happens to work only because isOperator accepts both characters.
- Tokens.kt:159-176 — `isLastExpressionBlockHasTimeKeyword()` treats only PLUS/MINUS as block delimiters (MULTIPLY/DIVIDE do not start a new block — possibly intentional, but inconsistent with isOperator()), and contains a debug `Log.d("Tag I", ...)` left in production data-layer code.
- Token has no equals/hashCode — list equality, contains(), and test comparisons rely on reference identity; unit tests work around it with a custom matcher that compares only strRepresentation (and not type), so two tokens of different types with equal text compare as equal in tests (WhenCalculateExpression.kt:29-47).

## Porting notes
- android.text.SpannableString / setSpan with RelativeSizeSpan(0.7f) and ForegroundColorSpan (Tokens.toSpannableString/toLightSpannableString, SpannableFunctions.kt): Flutter equivalent is a List<TextSpan>/RichText (or AnnotatedString-style model). Port the per-token-type styling rules: time units = 0.7x size + Color(0xFF33691E); light variant 0.7x + Color(0xFF4C992E); gray Color(0xFF807E7E) (full size); ERROR = 0.7x + Colors.red (Color.parseColor("RED") == 0xFFFF0000). Decide whether the Dart token model should return style-agnostic data and let the widget layer style it (recommended) instead of embedding rendering in the Tokens class.
- Color.parseColor("RED") relies on Android's named-color lookup; Dart has no parseColor — use a const Color(0xFFFF0000)/Colors.red. The hex colors (#33691e, #4c992e, #807e7e) duplicate values that 'should' come from colors.xml per the in-source TODO; in Flutter put them in a theme/constants file.
- Spannable.SPAN_EXCLUSIVE_EXCLUSIVE and TextUtils.concat have no Dart counterpart; the custom `SpannableString.plus` operator becomes simple TextSpan list concatenation.
- android.util.Log.d("Tag I", ...) inside Tokens.isLastExpressionBlockHasTimeKeyword (Tokens.kt:168) — replace with debugPrint/logger or remove; it forces an Android dependency into an otherwise pure data class.
- Tokens extends ArrayList<Token> and overrides clone() — Dart cannot subclass List directly; use a class implementing ListBase<Token> (dart:collection) or composition with a List<Token> field, and replace clone() with a copy() method (Cloneable does not exist in Dart).
- java.util.regex.Pattern / Matcher.find(start) (LexicalAnalyzer.findCurrentDigitalToken): use Dart RegExp r'-?[\d\.]+' with firstMatch on substring or matchAsPrefix at the current position; note Dart's RegExp has no find(start) — `regExp.matchAsPrefix(expression, currentPosition)` is the faithful equivalent given the match always starts at currentPosition.
- Kotlin Char.isDigit()/isLetter() are Unicode-aware (Character.isDigit/isLetter); Dart needs an explicit choice — RegExp(r'\d')/unicode letter classes or charcode ranges. Decide whether to keep Unicode-digit acceptance or restrict to ASCII 0-9 (ASCII recommended; downstream parsing assumes it).
- Kotlin sealed class TokenType with singleton objects and identity comparison: port as a Dart enum (preferably enhanced enum with a `value` String field plus isOperator/isTimeKeyword getters) — enum identity semantics match Kotlin object identity.
- Unicode operator constants must be preserved exactly: MINUS "−" U+2212, MULTIPLY "×" U+00D7, DIVIDE "÷" U+00F7; keyboards/strings emitting ASCII -, *, / are normalized to these on lexing, while Tokens.toString() converts back to ASCII (+, -, /, *). Keep both mappings or downstream evaluation (which consumes toString output) breaks.
- Companion-object mutable static (`expressionLength`) — make the Dart lexer a pure function with local state (no top-level mutable globals); this also fixes the reentrancy bug.
- String extensions (toTokens, toToken, addStartAndEndSpace, removeAllSpaces) — Dart supports `extension on String`, so these port directly; toTokenInMSec depends on TimeConverter which is out of scope here.
- Token.strRepresentation is mutated in place by UI flows (addDotToNumber, mergeNumberToNumber, deleteOneLastSymbolInNumber via ExpressionRepository); if the Flutter port uses immutable state (e.g. with a state-management lib), these become copy-with operations and the repository must replace the last token rather than mutate it.
