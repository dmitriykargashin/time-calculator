<script setup lang="ts">
import { colorize, PER_UNITS, type PerUnit } from '~/composables/useTimeEngine'

const { ready, evaluate, perBreakdown, normalizeExpression } = useTimeEngine()

// The full result-format set from the app (data/repositories.dart), same order.
const FORMATS = [
  { label: 'Year', value: 'Year' },
  { label: 'Year Month', value: 'Year Month' },
  { label: 'Year Month Day', value: 'Year Month Day' },
  { label: 'Year Month Day Hour', value: 'Year Month Day Hour' },
  { label: 'Year Month Day Hour Minute', value: 'Year Month Day Hour Minute' },
  { label: 'Month', value: 'Month' },
  { label: 'Month Day', value: 'Month Day' },
  { label: 'Month Day Hour', value: 'Month Day Hour' },
  { label: 'Month Day Hour Minute', value: 'Month Day Hour Minute' },
  { label: 'Month Day Hour Minute Second', value: 'Month Day Hour Minute Second' },
  { label: 'Month Week', value: 'Month Week' },
  { label: 'Week', value: 'Week' },
  { label: 'Week Day', value: 'Week Day' },
  { label: 'Day', value: 'Day' },
  { label: 'Day Hour', value: 'Day Hour' },
  { label: 'Day Hour Minute', value: 'Day Hour Minute' },
  { label: 'Day Hour Minute Second', value: 'Day Hour Minute Second' },
  { label: 'Hour', value: 'Hour' },
  { label: 'Hour Minute', value: 'Hour Minute' },
  { label: 'Hour Minute Second', value: 'Hour Minute Second' },
  { label: 'Hour Minute Second MSecond', value: 'Hour Minute Second MSecond' },
  { label: 'Minute', value: 'Minute' },
  { label: 'Minute Second', value: 'Minute Second' },
  { label: 'Second', value: 'Second' },
  { label: 'MSecond', value: 'MSecond' },
  { label: 'All Units', value: 'Year Month Week Day Hour Minute Second MSecond' },
] as const

// Grouped exactly like the app's Formats screen: single-unit vs combined.
const unitCount = (v: string) => v.trim().split(/\s+/).length
const singleFormats = FORMATS.filter(f => unitCount(f.value) === 1)
const combinedFormats = FORMATS.filter(f => unitCount(f.value) > 1)

const EXAMPLES = ['5h 30m + 2h 15m', '2 days - 4h', '8h 15m × 3', '1 week + 3 days', '1 day - 90 min']

const input = ref('5h 30m + 2h 15m')
const format = ref<string>('Hour Minute')
const result = ref('7 Hours 45 Minutes') // SSR default (matches the engine)
const isError = ref(false)
const formatsOpen = ref(false)
const copied = ref(false)
const perOpen = ref(false)
const amount = ref('')
const rateUnit = ref('USD')

const ta = useTemplateRef<HTMLTextAreaElement>('ta')
const display = useTemplateRef<HTMLElement>('display')
const chip = useTemplateRef<HTMLButtonElement>('chip')
const menu = useTemplateRef<HTMLElement>('menu')
const menuStyle = ref<Record<string, string>>({})

const exprToks = computed(() => colorize(input.value))
const resultToks = computed(() => colorize(result.value))
const formatLabel = computed(() => FORMATS.find(f => f.value === format.value)?.label ?? format.value)

// Live preview of the CURRENT result in each format (the app's grey preview line).
const formatPreviews = computed<Record<string, string>>(() => {
  const m: Record<string, string> = {}
  if (!ready.value) return m
  for (const f of FORMATS) {
    const r = evaluate(input.value, f.value)
    m[f.value] = r.ok ? r.result : ''
  }
  return m
})

function recompute() {
  if (!ready.value) return
  const r = evaluate(input.value, format.value)
  isError.value = r.error
  result.value = r.ok ? r.result : r.error ? 'ERROR' : '0'
}
watch([input, format, ready], recompute)

// Per / rate calculator: total = amount × (interval expressed in that unit).
const perTotals = computed<Record<PerUnit, number> | null>(() => {
  void ready.value
  const amt = parseFloat(amount.value.replace(',', '.'))
  if (!perOpen.value || !isFinite(amt)) return null
  const b = perBreakdown(input.value)
  if (!b) return null
  const out = {} as Record<PerUnit, number>
  for (const u of PER_UNITS) out[u] = b[u] * amt
  return out
})

function fmtMoney(n: number): string {
  if (!isFinite(n)) return '—'
  const abs = Math.abs(n)
  const digits = abs !== 0 && abs < 1 ? 4 : 2
  return n.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: digits })
}

function autoGrow() {
  const el = ta.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = el.scrollHeight + 'px'
}
watch(input, () => nextTick(autoGrow))

// --- format menu: teleported to <body> so the resizable card can't clip it ---
function toggleFormats() {
  formatsOpen.value = !formatsOpen.value
  if (formatsOpen.value) nextTick(positionMenu)
}
function positionMenu() {
  const el = chip.value
  if (!el) return
  const r = el.getBoundingClientRect()
  const vh = window.innerHeight
  const below = vh - r.bottom
  const wanted = Math.min(440, vh * 0.7)
  const style: Record<string, string> = {
    position: 'fixed',
    right: `${Math.round(window.innerWidth - r.right)}px`,
    'z-index': '200',
  }
  if (below < wanted + 12 && r.top > below) {
    // not enough room below → open upward
    style.bottom = `${Math.round(vh - r.top + 6)}px`
    style['max-height'] = `${Math.round(Math.min(wanted, r.top - 16))}px`
  } else {
    style.top = `${Math.round(r.bottom + 6)}px`
    style['max-height'] = `${Math.round(Math.min(wanted, below - 16))}px`
  }
  menuStyle.value = style
}
function onDocPointer(e: Event) {
  if (!formatsOpen.value) return
  const t = e.target as Node
  if (chip.value?.contains(t) || menu.value?.contains(t)) return
  formatsOpen.value = false
}
function onScroll() { if (formatsOpen.value) formatsOpen.value = false }
function onWinResize() { if (formatsOpen.value) positionMenu() }

// --- the card is user-resizable; remember the chosen size ---
const SIZE_KEY = 'tc-card-size'
onMounted(() => {
  autoGrow()
  const el = display.value
  if (el) {
    // width only — height is auto (grows with the expression, never scrolls)
    try {
      const s = JSON.parse(localStorage.getItem(SIZE_KEY) || '{}')
      if (s.w) el.style.width = s.w
    } catch { /* ignore */ }
    if ('ResizeObserver' in window) {
      let tmr: ReturnType<typeof setTimeout>
      new ResizeObserver(() => {
        clearTimeout(tmr)
        tmr = setTimeout(() => {
          try {
            localStorage.setItem(SIZE_KEY, JSON.stringify({ w: el.style.width }))
          } catch { /* ignore */ }
        }, 250)
      }).observe(el)
    }
  }
  document.addEventListener('click', onDocPointer)
  window.addEventListener('scroll', onScroll, true)
  window.addEventListener('resize', onWinResize)
})
onBeforeUnmount(() => {
  document.removeEventListener('click', onDocPointer)
  window.removeEventListener('scroll', onScroll, true)
  window.removeEventListener('resize', onWinResize)
})

function useExample(ex: string) {
  input.value = ex
}
function pickFormat(v: string) {
  format.value = v
  formatsOpen.value = false
}
async function copyResult() {
  if (isError.value || !result.value) return
  try {
    await navigator.clipboard.writeText(result.value)
    copied.value = true
    setTimeout(() => (copied.value = false), 1400)
  } catch { /* unavailable */ }
}
</script>

<template>
  <section class="calc" aria-label="Time duration calculator">
    <div ref="display" class="display">
      <!-- result-type (format) selector — like the app's tappable chip -->
      <div class="topbar">
        <span class="dot" aria-hidden="true" />
        <div class="fmt-wrap">
          <button ref="chip" class="fmt-chip" type="button" :aria-expanded="formatsOpen" @click="toggleFormats">
            <svg viewBox="0 0 24 24" width="15" height="15" aria-hidden="true"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 7v5l3 2" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
            <span>{{ formatLabel }}</span>
            <svg class="caret" :class="{ up: formatsOpen }" viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
          <Teleport to="body">
            <ul v-if="formatsOpen" ref="menu" class="fmt-menu" role="listbox" :style="menuStyle">
              <li class="fmt-sec" aria-hidden="true">Single unit</li>
              <li v-for="f in singleFormats" :key="f.value">
                <button type="button" :class="{ on: f.value === format }" role="option" :aria-selected="f.value === format" @click="pickFormat(f.value)">
                  <span class="fmt-name">{{ f.label }}</span>
                  <span v-if="formatPreviews[f.value]" class="fmt-prev">{{ formatPreviews[f.value] }}</span>
                </button>
              </li>
              <li class="fmt-sec" aria-hidden="true">Combined</li>
              <li v-for="f in combinedFormats" :key="f.value">
                <button type="button" :class="{ on: f.value === format }" role="option" :aria-selected="f.value === format" @click="pickFormat(f.value)">
                  <span class="fmt-name">{{ f.label }}</span>
                  <span v-if="formatPreviews[f.value]" class="fmt-prev">{{ formatPreviews[f.value] }}</span>
                </button>
              </li>
            </ul>
          </Teleport>
        </div>
      </div>

      <!-- EXPRESSION: a highlighted, editable field (units green, ops blue) -->
      <div class="expr-field">
        <div class="expr-hl" aria-hidden="true">
          <template v-if="input"><span v-for="(t, i) in exprToks" :key="i" :class="'t-' + t.t">{{ t.v }}</span></template>
          <span v-else class="ph">e.g. 5h 30m + 2h 15m</span>
        </div>
        <textarea
          ref="ta"
          v-model="input"
          class="expr-input"
          rows="1"
          spellcheck="false"
          autocapitalize="off"
          autocomplete="off"
          aria-label="Time expression"
          @keydown.enter.prevent
        />
      </div>

      <!-- RESULT -->
      <div class="result-row">
        <span class="eq" aria-hidden="true">=</span>
        <output class="result" :class="{ err: isError }" aria-live="polite">
          <template v-if="!isError"><span v-for="(t, i) in resultToks" :key="i" :class="'t-' + t.t">{{ t.v }}</span></template>
          <template v-else>can’t calculate that</template>
        </output>
      </div>

      <!-- actions -->
      <div class="actions">
        <button class="act" type="button" :disabled="isError" @click="copyResult">
          {{ copied ? '✓ Copied' : 'Copy' }}
        </button>
        <button class="act" type="button" :class="{ on: perOpen }" :aria-expanded="perOpen" @click="perOpen = !perOpen">
          Rate calculator
          <svg class="caret" :class="{ up: perOpen }" viewBox="0 0 24 24" width="15" height="15" aria-hidden="true"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </button>
      </div>

      <!-- PER / RATE helper -->
      <div v-if="perOpen" class="per">
        <div class="per-explain">
          <p>
            <b>Got a rate?</b> Pay, speed, data, output — anything measured
            <em>per unit of time</em>. Enter the <b>amount</b> and its
            <b>unit</b> (e.g. <code>25</code> <code>USD</code>), and for every
            time unit below you’ll see what that rate totals over the duration
            above.
          </p>
          <p class="per-eg">
            For example, at <b>25 USD&nbsp;per&nbsp;hour</b> a <b>7h&nbsp;45m</b>
            shift is worth <b>193.75 USD</b> — read it off the “per&nbsp;hour”
            row. The same amount works for <b>km/h</b>, <b>MB/s</b>, items/day…
          </p>
        </div>
        <div class="per-inputs">
          <label class="per-amt">
            <span>Amount</span>
            <input v-model="amount" type="text" inputmode="decimal" placeholder="25" aria-label="Rate amount" />
          </label>
          <label class="per-unit">
            <span>Unit</span>
            <input v-model="rateUnit" type="text" placeholder="USD" aria-label="Rate unit" />
          </label>
        </div>
        <ul v-if="perTotals" class="per-rows">
          <li v-for="u in PER_UNITS" :key="u">
            <span class="per-k">per {{ u.toLowerCase() }}</span>
            <span class="per-v">{{ fmtMoney(perTotals[u]) }} <em>{{ rateUnit }}</em></span>
          </li>
        </ul>
        <p v-else class="per-hint">Enter an amount to see totals over the duration above.</p>
      </div>
    </div>

    <!-- examples -->
    <div class="examples">
      <span class="ex-label">Try</span>
      <button v-for="ex in EXAMPLES" :key="ex" class="ex" type="button" @click="useExample(ex)">{{ ex }}</button>
    </div>
    <p class="micro">
      Type hours, minutes, days, weeks, months, years or seconds — full words or
      shorthand (<code>h m d w</code>), with <code>+ − × ÷</code>. Runs in your
      browser. <span class="resize-tip">Drag the card’s right edge to resize its width.</span>
    </p>
  </section>
</template>

<style scoped>
.calc { font-family: var(--font-app); }

/* the big app-style display */
.display {
  position: relative;
  background: var(--app-display);
  border: 1px solid var(--card-edge);
  border-radius: 22px;
  box-shadow: var(--shadow-card);
  padding: clamp(1.1rem, 0.5rem + 2.4vw, 2rem);
  /* Resize the WIDTH only (drag the side handle); the height stays auto, so the
     card grows with the expression and never gets an inner scrollbar. The
     format menu is teleported to <body>, so overflow:auto can't clip it. */
  overflow: auto;
  resize: horizontal;
  min-width: 280px;
  max-width: 100%;
}
.display::-webkit-resizer {
  background:
    linear-gradient(135deg, transparent 0 50%, var(--app-unit) 50% 58%, transparent 58% 74%, var(--app-unit) 74% 82%, transparent 82%);
}

.topbar {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-bottom: clamp(0.8rem, 2vw, 1.4rem);
}
.dot {
  width: 9px; height: 9px; border-radius: 50%;
  background: var(--green-bright);
  box-shadow: 0 0 0 4px rgba(61, 165, 12, 0.16);
}
.fmt-wrap { position: relative; margin-left: auto; }
.fmt-chip {
  display: inline-flex; align-items: center; gap: 0.5em;
  background: var(--paper-deep);
  border: 1px solid var(--line);
  color: var(--app-unit);
  font-family: var(--font-app);
  font-size: 0.92rem;
  padding: 0.5em 0.8em; border-radius: 999px; cursor: pointer;
  transition: border-color 0.16s, background 0.16s;
}
.fmt-chip:hover { border-color: var(--app-unit); }
.caret { transition: transform 0.2s; opacity: 0.7; }
.caret.up { transform: rotate(180deg); }
/* teleported to <body>; positioned via inline :style (fixed). Two columns so
   the 26-format list stays compact, with section headers spanning both. */
.fmt-menu {
  display: grid;
  grid-template-columns: 1fr 1fr;
  align-content: start;
  gap: 1px 4px;
  list-style: none; margin: 0; padding: 7px;
  background: #fff; border: 1px solid var(--card-edge);
  border-radius: 14px; box-shadow: 0 18px 44px -20px rgba(40, 36, 20, 0.55);
  width: min(94vw, 470px); overflow-y: auto;
}
.fmt-menu li:not(.fmt-sec) { display: contents; } /* button becomes the grid cell */
.fmt-sec {
  grid-column: 1 / -1;
  font-family: var(--font-mono); font-size: 0.6rem; letter-spacing: 0.16em;
  text-transform: uppercase; color: var(--ink-faint); font-weight: 600;
  padding: 0.75em 0.6em 0.3em;
}
.fmt-sec:first-child { padding-top: 0.35em; }
.fmt-menu button {
  display: flex; flex-direction: column; gap: 1px;
  text-align: left; background: transparent; border: 0; cursor: pointer;
  padding: 0.42em 0.55em; border-radius: 9px;
}
.fmt-menu button:hover { background: var(--paper-deep); }
.fmt-menu button.on { background: rgba(51, 105, 30, 0.09); }
.fmt-name {
  font-family: var(--font-app); font-size: 0.9rem; color: var(--app-unit);
  font-weight: 700; line-height: 1.18;
}
.fmt-menu button.on .fmt-name::after { content: " ✓"; }
.fmt-prev {
  font-family: var(--font-app); font-size: 0.76rem; color: var(--app-res-num);
  line-height: 1.2; overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
@media (max-width: 520px) {
  .fmt-menu { grid-template-columns: 1fr; width: min(94vw, 320px); }
}

/* expression: highlight layer behind a transparent textarea */
.expr-field { position: relative; }
.expr-hl,
.expr-input {
  font-family: var(--font-app);
  font-size: clamp(1.7rem, 1.1rem + 3.4vw, 3.1rem);
  line-height: 1.22;
  letter-spacing: 0.01em;
  padding: 0;
  margin: 0;
  border: 0;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  word-break: break-word;
}
.expr-hl {
  pointer-events: none;
  color: var(--app-num);
  min-height: 1.22em;
}
.expr-input {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  resize: none;
  overflow: hidden;
  background: transparent;
  color: transparent;
  caret-color: var(--app-num);
  outline: none;
}
.t-num { color: var(--app-num); }
.t-unit { color: var(--app-unit); }
.t-op { color: var(--app-op); }
.ph { color: var(--ink-faint); }

/* result */
.result-row {
  display: flex; align-items: baseline; gap: 0.55rem;
  margin-top: clamp(1rem, 3vw, 1.6rem);
  padding-top: clamp(0.9rem, 2.4vw, 1.3rem);
  border-top: 1px solid var(--line);
}
.eq {
  font-family: var(--font-app);
  font-size: clamp(1.6rem, 4vw, 2.4rem);
  color: var(--ink-faint);
  line-height: 1;
}
.result {
  font-family: var(--font-app);
  font-weight: 700; /* bold result, like the app (faux-bold; ABeeZee is 1 weight) */
  font-size: clamp(1.9rem, 1.2rem + 4vw, 3.5rem);
  line-height: 1.12;
  min-width: 0;
  overflow-wrap: anywhere;
}
.result .t-num { color: var(--app-res-num); }
.result .t-unit { color: var(--app-res-unit); }
.result.err { color: var(--app-error); font-size: clamp(1.3rem, 0.9rem + 2vw, 1.8rem); font-style: italic; }

.actions { display: flex; gap: 0.6rem; margin-top: 1.3rem; flex-wrap: wrap; }
.act {
  display: inline-flex; align-items: center; gap: 0.4em;
  background: transparent; border: 1.5px solid var(--line-strong);
  color: var(--ink-soft); font-family: var(--font-app); font-size: 0.9rem;
  padding: 0.55em 1em; border-radius: 999px; cursor: pointer; transition: 0.16s;
}
.act:hover:not(:disabled) { border-color: var(--ink); color: var(--ink); }
.act.on { border-color: var(--app-unit); color: var(--app-unit); background: rgba(51,105,30,0.06); }
.act:disabled { opacity: 0.4; cursor: default; }

/* per / rate */
.per {
  margin-top: 1.3rem; padding-top: 1.3rem;
  border-top: 1px dashed var(--line-strong);
}
.per-explain { margin: 0 0 1.1rem; }
.per-explain p { margin: 0 0 0.7rem; font-size: 0.92rem; color: var(--ink-soft); line-height: 1.55; }
.per-explain code {
  font-family: var(--font-mono); font-size: 0.82em;
  background: var(--paper-deep); padding: 0.1em 0.35em; border-radius: 5px; color: var(--olive);
}
.per-eg {
  font-size: 0.87rem; color: var(--ink-faint);
  border-left: 2px solid var(--app-unit); padding-left: 0.85rem;
}
.per-eg b { color: var(--ink-soft); }
.per-inputs { display: flex; gap: 0.8rem; }
.per-amt, .per-unit { display: flex; flex-direction: column; gap: 0.3rem; }
.per-amt { flex: 1 1 0; }
.per-unit { width: 8rem; }
.per-inputs span {
  font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.12em;
  color: var(--ink-faint); font-family: var(--font-body); font-weight: 600;
}
.per-inputs input {
  font-family: var(--font-app); font-size: 1.15rem; color: var(--ink);
  background: var(--paper-deep); border: 1px solid var(--line);
  border-radius: 11px; padding: 0.55em 0.7em; outline: none; min-width: 0;
}
.per-inputs input:focus { border-color: var(--app-unit); }
.per-rows {
  list-style: none; margin: 1.1rem 0 0; padding: 0;
  border: 1px solid var(--line); border-radius: 14px; overflow: hidden;
  background: var(--card);
}
.per-rows li {
  display: flex; align-items: baseline; justify-content: space-between;
  padding: 0.62em 0.95em; border-bottom: 1px solid var(--line);
}
.per-rows li:last-child { border-bottom: 0; }
.per-k { color: var(--ink-soft); font-size: 0.92rem; }
.per-v { font-family: var(--font-app); font-size: 1.12rem; color: var(--app-res-num); font-variant-numeric: tabular-nums; }
.per-v em { font-style: normal; color: var(--app-res-unit); font-size: 0.85em; }
.per-hint { margin: 1rem 0 0; font-size: 0.88rem; color: var(--ink-faint); }

/* examples + micro */
.examples { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; margin-top: 1.4rem; }
.ex-label { font-family: var(--font-mono); font-size: 0.66rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--ink-faint); }
.ex {
  border: 1px solid var(--line); background: var(--paper-deep);
  color: var(--ink-soft); font-family: var(--font-app); font-size: 0.86rem;
  padding: 0.42em 0.7em; border-radius: 8px; cursor: pointer; transition: 0.16s;
}
.ex:hover { border-color: var(--app-unit); color: var(--app-unit); background: #fff; }
.micro { margin: 1rem 0.2rem 0; font-size: 0.84rem; color: var(--ink-faint); max-width: none; }
.resize-tip { color: var(--app-unit); }
.micro code { font-family: var(--font-mono); font-size: 0.82em; background: var(--paper-deep); padding: 0.1em 0.35em; border-radius: 5px; color: var(--olive); }

@media (max-width: 560px) {
  .per-unit { width: 6.5rem; }
}
</style>
