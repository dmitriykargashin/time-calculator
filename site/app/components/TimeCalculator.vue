<script setup lang="ts">
import { colorize, expandColon, hasColonTime, colonIsAmbiguous, toClockString, PER_UNITS, type ColorTok, type PerUnit } from '~/composables/useTimeEngine'

const { ready, evaluate, perBreakdown } = useTimeEngine()
const trackEvent = useTrack()

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

// Digital-clock display formats. These are NOT engine formats: we evaluate with
// `engine` and then post-process the numbers into a colon string (e.g. 25:15:00).
const CLOCK = [
  { label: 'H:MM', value: 'clock:hm', engine: 'Hour Minute', pads: [0, 2], msIndex: -1 },
  { label: 'H:MM:SS', value: 'clock:hms', engine: 'Hour Minute Second', pads: [0, 2, 2], msIndex: -1 },
  { label: 'H:MM:SS.mmm', value: 'clock:hmsms', engine: 'Hour Minute Second MSecond', pads: [0, 2, 2, 3], msIndex: 3 },
] as const

// Grouped exactly like the app's Formats screen: single-unit vs combined.
const unitCount = (v: string) => v.trim().split(/\s+/).length
const singleFormats = FORMATS.filter(f => unitCount(f.value) === 1)
const combinedFormats = FORMATS.filter(f => unitCount(f.value) > 1)
const labelOf = (v: string) =>
  FORMATS.find(f => f.value === v)?.label ?? CLOCK.find(c => c.value === v)?.label ?? v

const EXAMPLES = ['5h 30m + 2h 15m', '2 days - 4h', '8h 15m × 3', '1 week + 3 days', '1 day - 90 min']

const props = withDefaults(defineProps<{ initialExpr?: string; initialFormat?: string }>(), {
  initialExpr: '5h 30m + 2h 15m',
  initialFormat: 'Hour Minute',
})

const input = ref(props.initialExpr)
const format = ref<string>(props.initialFormat)
// Clock-style paste: a bare "2:45" reads as hours:minutes by default; the Adapt
// chip flips it to minutes:seconds. `adapted` is what we actually evaluate, so
// the result is live even before you click Adapt (which rewrites the field).
const colonMode = ref<'hm' | 'ms'>('hm')
const adapted = computed(() => expandColon(input.value, colonMode.value))
const hasColon = computed(() => hasColonTime(input.value))
const colonAmbiguous = computed(() => colonIsAmbiguous(input.value))
function applyAdapt() {
  input.value = adapted.value
  trackEvent('expr_adapted', { mode: colonMode.value })
}
// SSR default result is only valid for the homepage default; guides recompute on mount.
const result = ref(
  props.initialExpr === '5h 30m + 2h 15m' && props.initialFormat === 'Hour Minute'
    ? '7 Hours 45 Minutes'
    : '',
)
// Error feedback (the wavy underline + the hint line) is debounced: while you
// are actively typing it stays hidden, and only appears once you pause. The
// valid result still updates live.
const pendingError = ref(false)
const pendingIncomplete = ref(false)
const pendingHint = ref('')
const settled = ref(true)
const isError = computed(() => settled.value && pendingError.value)
const isIncomplete = computed(() => settled.value && pendingIncomplete.value)
const hintMsg = computed(() => (settled.value ? pendingHint.value : ''))
// zero-width space appended to the highlight so a trailing newline still renders
// a line — keeps the highlight the same height as the textarea (cursor aligned).
const pad = '​'
const copied = ref(false)
const clearing = ref(false)
const amount = ref('')
const rateUnit = ref('USD')

// One bottom panel open at a time (the Convert list, the rate helper, history).
const openPanel = ref<'convert' | 'rate' | 'history' | null>(null)
function togglePanel(p: 'convert' | 'rate' | 'history') {
  openPanel.value = openPanel.value === p ? null : p
  if (openPanel.value === p) trackEvent('panel_opened', { panel: p })
}

const ta = useTemplateRef<HTMLTextAreaElement>('ta')
const display = useTemplateRef<HTMLElement>('display')

const exprToks = computed(() => colorize(input.value))
const resultToks = computed(() => colorize(result.value))
const formatLabel = computed(() => labelOf(format.value))

// Evaluate, then (for a clock format) reshape the engine numbers into a colon
// string. Plain engine formats pass straight through.
function evalDisplay(src: string, fmt: string) {
  const clock = CLOCK.find(c => c.value === fmt)
  if (!clock) return evaluate(src, fmt)
  const r = evaluate(src, clock.engine)
  return r.ok ? { ...r, result: toClockString(r.result, clock.engine, [...clock.pads], clock.msIndex) } : r
}

function recompute() {
  if (!ready.value) return
  const r = evalDisplay(adapted.value, format.value)
  pendingError.value = r.error
  pendingIncomplete.value = !!r.incomplete
  pendingHint.value = r.hint ?? ''
  result.value = r.ok ? r.result : ''
}
// `immediate` so a calculator mounted after the engine already loaded (e.g. when
// navigating to a guide page) still computes — `ready` won't change, so without
// this the result would stay empty. recompute() no-ops while !ready, so this is
// safe during SSR and before the engine finishes loading.
watch([adapted, format, ready], recompute, { immediate: true })

// Debounce the error feedback: hide the wavy underline + hint while typing,
// reveal ~0.6s after the last keystroke.
let settleTimer: ReturnType<typeof setTimeout>
watch(input, () => {
  settled.value = false
  clearTimeout(settleTimer)
  settleTimer = setTimeout(() => { settled.value = true }, 600)
})

// Hold the unknown-unit underline back until typing settles (no mid-word flag).
function exprTokClass(t: ColorTok): string {
  return 't-' + (t.t === 'bad' && !settled.value ? 'num' : t.t)
}

// Fire once per session the first time the visitor edits the expression — a
// clean "did they actually use the calculator" signal (the field is pre-filled).
let usedFired = false
watch(input, () => {
  if (!usedFired) {
    usedFired = true
    trackEvent('calculator_used')
  }
})

// --- Convert panel: the current value in EVERY format (computed only while open) ---
const formatPreviews = computed<Record<string, string>>(() => {
  const m: Record<string, string> = {}
  if (openPanel.value !== 'convert' || !ready.value) return m
  for (const f of FORMATS) {
    const r = evalDisplay(adapted.value, f.value)
    m[f.value] = r.ok ? r.result : '—'
  }
  for (const c of CLOCK) {
    const r = evalDisplay(adapted.value, c.value)
    m[c.value] = r.ok ? r.result : '—'
  }
  return m
})

// --- format picker: a centered modal. Shows every format, is never clipped by
//     the page edges, and survives scroll (it's a fixed centered overlay). ---
const fmtOpen = ref(false)
function toggleFmt() { fmtOpen.value = !fmtOpen.value }
function pickFormat(v: string) {
  format.value = v
  fmtOpen.value = false
  trackEvent('format_changed', { format: v })
}
function onKey(e: KeyboardEvent) {
  if (e.key === 'Escape') fmtOpen.value = false
}

// --- history (localStorage, mirrors the app: newest first, max 10, deduped) ---
interface HistEntry { e: string; r: string; f: string; t: number }
const HIST_KEY = 'tc-history'
const HIST_MAX = 10
const history = ref<HistEntry[]>([])

function persistHistory() {
  try { localStorage.setItem(HIST_KEY, JSON.stringify(history.value)) } catch { /* ignore */ }
}
function loadHistory() {
  try {
    const raw = JSON.parse(localStorage.getItem(HIST_KEY) || '[]')
    if (Array.isArray(raw)) {
      history.value = raw
        .filter(x => x && typeof x.e === 'string' && typeof x.r === 'string')
        .map(x => ({ e: x.e, r: x.r, f: typeof x.f === 'string' ? x.f : 'Hour Minute', t: +x.t || 0 }))
        .slice(0, HIST_MAX)
    }
  } catch { /* ignore */ }
}
// History only holds what you deliberately star. The current result is
// "starred" when an identical entry is already saved.
const isStarred = computed(() => {
  const e = input.value.trim()
  const r = result.value.trim()
  return !!e && !!r && history.value.some(h => h.e === e && h.r === r)
})
function toggleStar() {
  const e = input.value.trim()
  const r = result.value.trim()
  if (!e || !r || isError.value || isIncomplete.value) return
  const idx = history.value.findIndex(h => h.e === e && h.r === r)
  if (idx >= 0) {
    history.value.splice(idx, 1) // un-star
  } else {
    history.value.unshift({ e, r, f: format.value, t: Date.now() })
    if (history.value.length > HIST_MAX) history.value = history.value.slice(0, HIST_MAX)
    trackEvent('result_starred')
  }
  persistHistory()
}
function restoreHistory(h: HistEntry) {
  if (FORMATS.some(f => f.value === h.f) || CLOCK.some(c => c.value === h.f)) format.value = h.f
  input.value = h.e
  openPanel.value = null
}
function clearHistory() {
  history.value = []
  persistHistory()
}
function relTime(t: number): string {
  if (!t) return ''
  const s = Math.max(0, Math.floor((Date.now() - t) / 1000))
  if (s < 45) return 'just now'
  if (s < 3600) return `${Math.round(s / 60)}m ago`
  if (s < 86400) return `${Math.round(s / 3600)}h ago`
  return `${Math.round(s / 86400)}d ago`
}

// Per / rate calculator. perBreak = the duration expressed in each unit (shown
// in every row, even before an amount); perTotals = that × the entered amount.
const perBreak = computed<Record<PerUnit, number> | null>(() => {
  void ready.value
  if (openPanel.value !== 'rate') return null
  return perBreakdown(input.value)
})
const perTotals = computed<Record<PerUnit, number> | null>(() => {
  const b = perBreak.value
  const amt = parseFloat(amount.value.replace(',', '.'))
  if (!b || !isFinite(amt)) return null
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
function fmtNum(n: number): string {
  if (!isFinite(n)) return '—'
  const a = Math.abs(n)
  const digits = a >= 100 ? 1 : a >= 1 ? 2 : 4
  return n.toLocaleString('en-US', { maximumFractionDigits: digits })
}
function unitWord(u: string, n: number): string {
  const w = u.toLowerCase()
  return Math.abs(n) === 1 ? w : `${w}s`
}
const niceAmount = computed(() => {
  const a = parseFloat(amount.value.replace(',', '.'))
  return isFinite(a) ? a.toLocaleString('en-US', { maximumFractionDigits: 4 }) : amount.value.trim()
})

function autoGrow() {
  const el = ta.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = el.scrollHeight + 'px'
}

watch(input, () => nextTick(autoGrow))

async function copyResult() {
  if (isError.value || !result.value) return
  try {
    await navigator.clipboard.writeText(result.value)
    copied.value = true
    trackEvent('result_copied', { source: 'result' })
    setTimeout(() => (copied.value = false), 1400)
  } catch { /* unavailable */ }
}
const copiedFmt = ref('')
async function copyConversion(v: string) {
  const val = formatPreviews.value[v]
  if (!val || val === '—') return
  try {
    await navigator.clipboard.writeText(val)
    copiedFmt.value = v
    trackEvent('result_copied', { source: 'convert', format: v })
    setTimeout(() => { if (copiedFmt.value === v) copiedFmt.value = '' }, 1200)
  } catch { /* unavailable */ }
}

// Clear, with the app's green "flash" wipe (a circular reveal across the card,
// then the expression + result clear). Skipped under reduced motion.
function clearAll() {
  if (!input.value) return
  const reduce = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
  if (reduce) { input.value = ''; return }
  clearing.value = true
  setTimeout(() => { input.value = ''; clearing.value = false }, 400)
}

function useExample(ex: string) {
  input.value = ex
  trackEvent('example_used', { expr: ex })
}

// --- mount: restore width, animate height changes, load history, wire listeners ---
const SIZE_KEY = 'tc-card-size'
onMounted(() => {
  autoGrow()
  loadHistory()
  document.addEventListener('keydown', onKey)

  const el = display.value
  if (!el) return
  try {
    const s = JSON.parse(localStorage.getItem(SIZE_KEY) || '{}')
    if (s.w) el.style.width = s.w
  } catch { /* ignore */ }
  if (!('ResizeObserver' in window)) return

  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  let cardH = el.offsetHeight
  let animating = false
  let saveTmr: ReturnType<typeof setTimeout>
  new ResizeObserver(() => {
    clearTimeout(saveTmr)
    saveTmr = setTimeout(() => {
      try { localStorage.setItem(SIZE_KEY, JSON.stringify({ w: el.style.width })) } catch { /* ignore */ }
    }, 250)

    // smoothly animate the card when its content height changes (a panel
    // opening, a wrapped expression, the result swapping) via a height FLIP.
    if (reduce || animating) { cardH = el.offsetHeight; return }
    const target = el.offsetHeight
    if (Math.abs(target - cardH) < 2) return
    const from = cardH
    animating = true
    el.style.overflow = 'hidden'
    el.style.transition = 'none'
    el.style.height = `${from}px`
    requestAnimationFrame(() => {
      el.style.transition = 'height 0.3s cubic-bezier(0.22, 1, 0.36, 1)'
      el.style.height = `${target}px`
    })
    const onEnd = (e: TransitionEvent) => {
      if (e.target !== el || e.propertyName !== 'height') return
      el.removeEventListener('transitionend', onEnd)
      el.style.transition = ''
      el.style.height = ''
      el.style.overflow = ''
      animating = false
      cardH = el.offsetHeight
    }
    el.addEventListener('transitionend', onEnd)
  }).observe(el)
})
onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKey)
})
</script>

<template>
  <section class="calc" aria-label="Time duration calculator">
    <div ref="display" class="display">
      <!-- result-format selector: a custom dropdown of format names. -->
      <div class="topbar">
        <span class="dot" aria-hidden="true" />
        <div class="fmt-pick">
          <span class="fmt-pick-label">Show result as</span>
          <button class="fmt-chip" type="button" :aria-expanded="fmtOpen" @click="toggleFmt">
            <span class="fmt-chip-name">{{ formatLabel }}</span>
            <svg class="caret" :class="{ up: fmtOpen }" viewBox="0 0 24 24" width="16" height="16" aria-hidden="true"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
          <Teleport to="body">
            <Transition name="fmtm">
              <div v-if="fmtOpen" class="fmt-overlay" @click.self="fmtOpen = false">
                <div class="fmt-modal" role="dialog" aria-modal="true" aria-label="Result format">
                  <div class="fmt-modal-head">
                    <span class="fmt-modal-title">Show result as</span>
                    <button class="fmt-close" type="button" aria-label="Close" @click="fmtOpen = false">✕</button>
                  </div>
                  <div class="fmt-modal-body">
                    <div class="fmt-sec">Single unit</div>
                    <div class="fmt-grid">
                      <button v-for="f in singleFormats" :key="f.value" type="button" class="fmt-opt" :class="{ on: f.value === format }" :aria-selected="f.value === format" @click="pickFormat(f.value)">{{ f.label }}</button>
                    </div>
                    <div class="fmt-sec">Combined</div>
                    <div class="fmt-grid">
                      <button v-for="f in combinedFormats" :key="f.value" type="button" class="fmt-opt" :class="{ on: f.value === format }" :aria-selected="f.value === format" @click="pickFormat(f.value)">{{ f.label }}</button>
                    </div>
                    <div class="fmt-sec">Digital clock</div>
                    <div class="fmt-grid">
                      <button v-for="c in CLOCK" :key="c.value" type="button" class="fmt-opt" :class="{ on: c.value === format }" :aria-selected="c.value === format" @click="pickFormat(c.value)">{{ c.label }}</button>
                    </div>
                  </div>
                </div>
              </div>
            </Transition>
          </Teleport>
        </div>
      </div>

      <!-- EXPRESSION: a highlighted, editable field (units green, ops blue) -->
      <div class="expr-field">
        <div class="expr-hl" aria-hidden="true">
          <template v-if="input"><span v-for="(t, i) in exprToks" :key="i" :class="exprTokClass(t)">{{ t.v }}</span><span class="t-pad">{{ pad }}</span></template>
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
        />
      </div>

      <!-- ADAPT: pasted a clock time like 2:30:15 or 2:45? Offer to rewrite it
           into the calculator's grammar; the result is already live below. -->
      <Transition name="adapt">
        <div v-if="hasColon" class="adapt-bar">
          <span class="adapt-txt">Clock time — read as <code>{{ adapted }}</code></span>
          <div v-if="colonAmbiguous" class="adapt-modes" role="group" aria-label="Read two-part time as">
            <button type="button" :class="{ on: colonMode === 'hm' }" @click="colonMode = 'hm'">H:MM</button>
            <button type="button" :class="{ on: colonMode === 'ms' }" @click="colonMode = 'ms'">M:SS</button>
          </div>
          <button type="button" class="adapt-btn" @click="applyAdapt">Adapt</button>
        </div>
      </Transition>

      <!-- RESULT -->
      <div class="result-row">
        <span class="eq" aria-hidden="true">=</span>
        <output class="result" :class="{ err: isError, hint: isIncomplete }" aria-live="polite">
          <template v-if="isIncomplete">{{ hintMsg }}</template>
          <template v-else-if="isError">can’t calculate that</template>
          <template v-else><span v-for="(t, i) in resultToks" :key="i" :class="'t-' + t.t">{{ t.v }}</span></template>
        </output>
        <button class="star" type="button" :class="{ on: isStarred }" :disabled="!result" :aria-pressed="isStarred" :title="isStarred ? 'Saved — click to remove from history' : 'Save to history'" @click="toggleStar">
          <svg viewBox="0 0 24 24" width="23" height="23" :fill="isStarred ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M12 3.2l2.7 5.48 6.05.88-4.38 4.27 1.04 6.02L12 17.1l-5.41 2.84 1.04-6.02L3.25 9.56l6.05-.88L12 3.2z"/></svg>
        </button>
      </div>

      <!-- actions -->
      <div class="actions">
        <button class="act" type="button" :disabled="!result" @click="copyResult">
          <Transition name="swap" mode="out-in">
            <span :key="copied ? 'y' : 'n'" class="act-in">
              <svg v-if="!copied" class="act-ico" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect x="9" y="9" width="11" height="11" rx="2"/><path d="M5 15V5a2 2 0 0 1 2-2h10"/></svg>
              <svg v-else class="act-ico" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 13l4 4 10-10"/></svg>
              {{ copied ? 'Copied' : 'Copy' }}
            </span>
          </Transition>
        </button>
        <button class="act" type="button" :disabled="!input" @click="clearAll">
          <svg class="act-ico" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="12" cy="12" r="9"/><path d="M9.5 9.5l5 5M14.5 9.5l-5 5"/></svg>
          Clear
        </button>
        <button class="act" type="button" :class="{ on: openPanel === 'convert' }" :aria-expanded="openPanel === 'convert'" @click="togglePanel('convert')">
          <svg class="act-ico" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M4 8h13l-3-3M20 16H7l3 3"/></svg>
          Convert
        </button>
        <button class="act" type="button" :class="{ on: openPanel === 'rate' }" :aria-expanded="openPanel === 'rate'" @click="togglePanel('rate')">
          <svg class="act-ico" viewBox="0 0 24 24" width="16" height="16" aria-hidden="true">
            <path fill="currentColor" d="M10 8v6l4.7 2.9.8-1.2-4-2.4V8z"/>
            <path fill="currentColor" d="M17.92 12A6.957 6.957 0 0 1 11 20c-3.9 0-7-3.1-7-7s3.1-7 7-7c.7 0 1.37.1 2 .29V4.23c-.64-.15-1.31-.23-2-.23-5 0-9 4-9 9s4 9 9 9a8.963 8.963 0 0 0 8.94-10h-2.02z"/>
            <path fill="currentColor" d="M20 5V2h-2v3h-3v2h3v3h2V7h3V5z"/>
          </svg>
          Rate
        </button>
        <button class="act" type="button" :class="{ on: openPanel === 'history' }" :aria-expanded="openPanel === 'history'" @click="togglePanel('history')">
          <svg class="act-ico" viewBox="0 0 24 24" width="15" height="15" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 4v4h4"/><path d="M12 8v4l3 2"/></svg>
          History
        </button>
      </div>

      <!-- one panel at a time (Convert / Rate / History). It slides in; the card
           animates its own height. -->
      <Transition name="rate">
        <div v-if="openPanel" class="panel">
          <!-- CONVERT: the current value in every format -->
          <div v-if="openPanel === 'convert'" class="convert">
            <p class="panel-intro">The current result in every format. Click a row to copy it.</p>
            <div class="cv-scroll">
            <div class="cv-sec">Single unit</div>
            <ul class="cv-list">
              <li v-for="f in singleFormats" :key="f.value">
                <button class="cv-row" :class="{ on: f.value === format }" type="button" @click="copyConversion(f.value)">
                  <span class="cv-name">{{ f.label }}</span>
                  <span class="cv-val">{{ copiedFmt === f.value ? '✓ copied' : (formatPreviews[f.value] || '—') }}</span>
                </button>
              </li>
            </ul>
            <div class="cv-sec">Combined</div>
            <ul class="cv-list">
              <li v-for="f in combinedFormats" :key="f.value">
                <button class="cv-row" :class="{ on: f.value === format }" type="button" @click="copyConversion(f.value)">
                  <span class="cv-name">{{ f.label }}</span>
                  <span class="cv-val">{{ copiedFmt === f.value ? '✓ copied' : (formatPreviews[f.value] || '—') }}</span>
                </button>
              </li>
            </ul>
            <div class="cv-sec">Digital clock</div>
            <ul class="cv-list">
              <li v-for="c in CLOCK" :key="c.value">
                <button class="cv-row" :class="{ on: c.value === format }" type="button" @click="copyConversion(c.value)">
                  <span class="cv-name">{{ c.label }}</span>
                  <span class="cv-val">{{ copiedFmt === c.value ? '✓ copied' : (formatPreviews[c.value] || '—') }}</span>
                </button>
              </li>
            </ul>
            </div>
          </div>

          <!-- RATE -->
          <div v-else-if="openPanel === 'rate'" class="per">
            <div class="per-explain">
              <p>
                <b>Got a rate?</b> Anything you measure <em>per unit of time</em>
                works here: pay, speed, data, output. Enter the <b>amount</b> and its
                <b>unit</b> (say <code>25</code> <code>USD</code>), and each row below
                shows what that rate adds up to over the duration above.
              </p>
              <p class="per-eg">
                Say you earn <b>25 USD&nbsp;per&nbsp;hour</b>. A <b>7h&nbsp;45m</b>
                shift comes to <b>193.75 USD</b>, right there on the “per&nbsp;hour”
                row. The same trick works for <b>km/h</b>, <b>MB/s</b>, or items per day.
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
            <ul v-if="perBreak" class="per-rows">
              <li v-for="u in PER_UNITS" :key="u">
                <div class="per-top">
                  <span class="per-k">per {{ u.toLowerCase() }}</span>
                  <span class="per-v">
                    <template v-if="perTotals">{{ fmtMoney(perTotals[u]) }} <em>{{ rateUnit }}</em></template>
                    <template v-else>{{ fmtNum(perBreak[u]) }} {{ unitWord(u, perBreak[u]) }}</template>
                  </span>
                </div>
                <div v-if="perTotals" class="per-calc">{{ niceAmount }} × {{ fmtNum(perBreak[u]) }} {{ unitWord(u, perBreak[u]) }}</div>
              </li>
            </ul>
            <p v-else class="per-hint">Enter a duration above to see the breakdown.</p>
          </div>

          <!-- HISTORY -->
          <div v-else class="hist">
            <div class="hist-head">
              <span class="panel-intro">Your saved calculations.</span>
              <button v-if="history.length" class="hist-clear" type="button" @click="clearHistory">Clear all</button>
            </div>
            <ul v-if="history.length" class="hist-list">
              <li v-for="(h, i) in history" :key="h.t + '-' + i">
                <button class="hist-row" type="button" @click="restoreHistory(h)" :title="`Reopen in ${labelOf(h.f)}`">
                  <span class="hist-expr">{{ h.e }}</span>
                  <span class="hist-res">= {{ h.r }}</span>
                  <span class="hist-meta">{{ labelOf(h.f) }}<template v-if="relTime(h.t)"> · {{ relTime(h.t) }}</template></span>
                </button>
              </li>
            </ul>
            <p v-else class="panel-empty">Tap the ★ next to a result to save it here.</p>
          </div>
        </div>
      </Transition>

      <!-- green "flash" wipe when clearing (mirrors the mobile app) -->
      <div v-if="clearing" class="clear-flash" aria-hidden="true" />
    </div>

    <!-- examples -->
    <div class="examples">
      <span class="ex-label">Try</span>
      <button v-for="ex in EXAMPLES" :key="ex" class="ex" type="button" @click="useExample(ex)">{{ ex }}</button>
    </div>
    <p class="micro">
      Type hours, minutes, days, weeks, months, years, or seconds, as full words
      or shorthand (<code>h m d w</code>), with <code>+ − × ÷</code>. Pick how the
      answer reads with <b>Show&nbsp;result&nbsp;as</b> up top. It all runs in
      your browser. <span class="resize-tip">Drag the card’s right edge to make it wider.</span>
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
  overflow: auto;
  resize: horizontal;
  min-width: 280px;
  max-width: 100%;
}
.display::-webkit-resizer {
  background:
    linear-gradient(135deg, transparent 0 50%, var(--app-unit) 50% 58%, transparent 58% 74%, var(--app-unit) 74% 82%, transparent 82%);
}
/* clear "flash": a green circular wipe across the card, then the content clears */
.clear-flash {
  position: absolute; inset: 0; z-index: 5; pointer-events: none;
  background: var(--green);
  animation: clearFlash 0.4s ease-in-out forwards;
}
@keyframes clearFlash {
  from { clip-path: circle(0% at 86% 90%); }
  to { clip-path: circle(150% at 86% 90%); }
}

.topbar {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  margin-bottom: clamp(0.8rem, 2vw, 1.4rem);
}
.dot {
  position: relative;
  width: 9px; height: 9px; border-radius: 50%;
  background: var(--green-bright);
  box-shadow: 0 0 0 4px rgba(61, 165, 12, 0.16);
}
.dot::after { content: ''; position: absolute; inset: 0; border-radius: 50%; }
.has-motion .dot::after { animation: dotPulse 2.6s ease-out infinite; }
@keyframes dotPulse {
  0% { box-shadow: 0 0 0 0 rgba(61, 165, 12, 0.45); }
  70%, 100% { box-shadow: 0 0 0 11px rgba(61, 165, 12, 0); }
}

/* result-format picker — label + custom dropdown chip */
.fmt-pick {
  margin-left: auto;
  display: flex; align-items: center; gap: 0.5rem; min-width: 0;
}
.fmt-pick-label {
  font-size: 0.74rem; color: var(--ink-faint); font-family: var(--font-body); white-space: nowrap;
}
.fmt-chip {
  display: inline-flex; align-items: center; gap: 0.4em;
  background: var(--paper-deep); border: 1px solid var(--line);
  color: var(--app-unit); font-family: var(--font-app); font-size: 0.92rem;
  padding: 0.5em 0.7em 0.5em 0.95em; border-radius: 999px; cursor: pointer;
  transition: border-color 0.16s, background 0.16s, box-shadow 0.16s; min-width: 0;
}
.fmt-chip:hover { border-color: rgba(51, 105, 30, 0.4); box-shadow: 0 4px 14px -8px rgba(28, 27, 21, 0.2); }
.fmt-chip-name { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 12rem; }
.caret { transition: transform 0.2s; opacity: 0.7; flex: none; }
.caret.up { transform: rotate(180deg); }
@media (max-width: 520px) {
  .fmt-pick-label { display: none; }
  .fmt-chip-name { max-width: 9rem; }
}

/* centered format-picker modal (every format, never clipped, survives scroll) */
.fmt-overlay {
  position: fixed; inset: 0; z-index: 200;
  display: flex; align-items: center; justify-content: center; padding: 1.2rem;
  background: rgba(28, 27, 21, 0.34);
  -webkit-backdrop-filter: blur(2px); backdrop-filter: blur(2px);
}
.fmt-modal {
  display: flex; flex-direction: column;
  width: min(94vw, 440px); max-height: min(86vh, 660px);
  background: var(--app-display);
  border: 1px solid var(--card-edge); border-radius: 18px;
  box-shadow: 0 30px 70px -28px rgba(40, 36, 20, 0.62);
  overflow: hidden;
}
.fmt-modal-head {
  display: flex; align-items: center; justify-content: space-between;
  padding: 0.85rem 1rem 0.45rem;
}
.fmt-modal-title {
  font-family: var(--font-mono); font-size: 0.62rem; letter-spacing: 0.16em;
  text-transform: uppercase; color: var(--ink-faint); font-weight: 600;
}
.fmt-close {
  background: transparent; border: 0; cursor: pointer; color: var(--ink-faint);
  font-size: 0.95rem; line-height: 1; padding: 0.3em 0.45em; border-radius: 8px;
}
.fmt-close:hover { color: var(--ink); background: var(--paper-deep); }
.fmt-modal-body {
  overflow-y: auto; padding: 0 9px 10px;
  scrollbar-width: thin; scrollbar-color: var(--line-strong) transparent;
}
.fmt-modal-body::-webkit-scrollbar { width: 11px; }
.fmt-modal-body::-webkit-scrollbar-thumb {
  background: var(--line-strong); border-radius: 9px;
  border: 3px solid var(--app-display); background-clip: padding-box;
}
.fmtm-enter-active, .fmtm-leave-active { transition: opacity 0.2s ease; }
.fmtm-enter-active .fmt-modal, .fmtm-leave-active .fmt-modal { transition: transform 0.26s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.2s ease; }
.fmtm-enter-from, .fmtm-leave-to { opacity: 0; }
.fmtm-enter-from .fmt-modal, .fmtm-leave-to .fmt-modal { opacity: 0; transform: translateY(10px) scale(0.97); }
.fmt-sec {
  font-family: var(--font-mono); font-size: 0.58rem; letter-spacing: 0.15em;
  text-transform: uppercase; color: var(--ink-faint); font-weight: 600;
  padding: 0.6em 0.5em 0.3em;
}
.fmt-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1px; }
.fmt-opt {
  text-align: left; background: transparent; border: 0; cursor: pointer;
  font-family: var(--font-app); font-size: 0.9rem; color: var(--app-unit);
  padding: 0.5em 0.55em; border-radius: 8px; line-height: 1.18;
}
.fmt-opt:hover { background: var(--paper-deep); }
.fmt-opt.on { background: rgba(51, 105, 30, 0.1); font-weight: 700; }
.fmt-opt.on::after { content: ' ✓'; }
@media (max-width: 440px) { .fmt-grid { grid-template-columns: 1fr; } }

/* expression: highlight layer behind a transparent textarea */
.expr-field { position: relative; margin: clamp(0.5rem, 2vw, 1.15rem) 0; }
.expr-hl,
.expr-input {
  font-family: var(--font-app);
  font-size: clamp(1.45rem, 1rem + 2.6vw, 2.6rem);
  line-height: 1.25;
  letter-spacing: 0.01em;
  padding: 0; margin: 0; border: 0;
  white-space: pre-wrap;
  overflow-wrap: anywhere;
  word-break: break-word;
}
.expr-hl { pointer-events: none; color: var(--app-num); min-height: 1.8em; }
.expr-input {
  position: absolute; inset: 0; width: 100%; height: 100%;
  resize: none; overflow: hidden; background: transparent;
  color: transparent; caret-color: var(--app-num); outline: none;
}
.t-num { color: var(--app-num); }
.t-unit { color: var(--app-unit); }
.t-op { color: var(--app-op); }
/* an unrecognised unit word (e.g. "minu") — a soft, thin wavy underline */
.t-bad { color: var(--app-num); text-decoration: wavy underline; text-decoration-color: color-mix(in srgb, var(--app-error) 42%, transparent); text-decoration-thickness: 1px; text-decoration-skip-ink: none; text-underline-offset: 3px; }
.ph { color: var(--ink-faint); }

/* adapt chip — shown when a pasted clock time (2:30:15 / 2:45) is detected */
.adapt-bar {
  display: flex; align-items: center; gap: 0.5rem 0.6rem; flex-wrap: wrap;
  margin: 0.15rem 0 0.1rem; padding: 0.45rem 0.65rem;
  border-radius: 0.6rem;
  background: color-mix(in srgb, var(--app-num) 7%, transparent);
  border: 1px solid color-mix(in srgb, var(--app-num) 18%, transparent);
  font-size: 0.84rem;
}
.adapt-txt { color: var(--app-num); }
.adapt-txt code { font-family: var(--font-app); color: var(--app-res-unit); font-weight: 700; background: none; padding: 0; }
.adapt-modes { display: inline-flex; border: 1px solid color-mix(in srgb, var(--app-num) 26%, transparent); border-radius: 0.5rem; overflow: hidden; }
.adapt-modes button { font: inherit; font-size: 0.76rem; padding: 0.16rem 0.5rem; background: none; border: 0; color: var(--app-num); cursor: pointer; }
.adapt-modes button.on { background: var(--app-unit); color: #fff; }
.adapt-btn { margin-left: auto; font: inherit; font-size: 0.8rem; font-weight: 700; padding: 0.26rem 0.85rem; border-radius: 0.5rem; border: 0; background: var(--app-unit); color: #fff; cursor: pointer; }
.adapt-btn:hover { filter: brightness(1.06); }
.adapt-enter-active, .adapt-leave-active { transition: opacity 0.2s ease, transform 0.2s var(--ease-pop); }
.adapt-enter-from, .adapt-leave-to { opacity: 0; transform: translateY(-4px); }

/* result */
.result-row {
  display: flex; align-items: baseline; gap: 0.55rem;
  margin-top: clamp(1rem, 3vw, 1.6rem);
  padding-top: clamp(0.9rem, 2.4vw, 1.3rem);
  border-top: 1px solid var(--line);
}
.eq {
  font-family: var(--font-app);
  font-size: clamp(1.35rem, 3.2vw, 2rem);
  color: var(--ink-faint); line-height: 1;
}
.result {
  flex: 1;
  font-family: var(--font-app);
  font-weight: 700;
  font-size: clamp(1.6rem, 1.1rem + 3vw, 2.9rem);
  line-height: 1.12; min-width: 0; overflow-wrap: anywhere;
}
.result .t-num { color: var(--app-res-num); }
.result .t-unit { color: var(--app-res-unit); }
.result.err { color: var(--app-error); font-size: clamp(1.3rem, 0.9rem + 2vw, 1.8rem); font-style: italic; }
.result.hint { color: var(--ink-faint); font-weight: 400; font-size: clamp(1.15rem, 0.9rem + 1.5vw, 1.55rem); font-style: italic; }
/* star: save the current result to history */
.star {
  flex: none; align-self: flex-start; margin-left: auto; margin-top: 0.15em;
  background: transparent; border: 0; cursor: pointer; padding: 0.2em;
  color: var(--ink-faint); line-height: 0; border-radius: 50%;
  transition: color 0.16s, transform 0.16s, background 0.16s;
}
.star:hover:not(:disabled) { color: var(--ochre); background: rgba(185, 121, 26, 0.12); transform: scale(1.1); }
.star.on { color: var(--ochre); }
.star:disabled { opacity: 0.3; cursor: default; }

.actions { display: flex; gap: 0.6rem; margin-top: 1.3rem; flex-wrap: wrap; }
.act {
  display: inline-flex; align-items: center; gap: 0.4em;
  background: transparent; border: 1.5px solid var(--line-strong);
  color: var(--ink-soft); font-family: var(--font-app); font-size: 0.9rem;
  padding: 0.55em 1em; border-radius: 999px; cursor: pointer; transition: 0.16s;
}
.act:hover:not(:disabled) { border-color: var(--line-strong); color: var(--ink); transform: translateY(-1px); box-shadow: 0 5px 16px -8px rgba(28, 27, 21, 0.26); }
.act.on { border-color: var(--app-unit); color: var(--app-unit); background: rgba(51,105,30,0.06); }
.act:disabled { opacity: 0.4; cursor: default; }
.act-ico { flex: none; opacity: 0.95; }
.act.on .act-ico { color: var(--app-unit); }
.swap-enter-active, .swap-leave-active { transition: opacity 0.18s, transform 0.18s, filter 0.18s; }
.swap-enter-from { opacity: 0; transform: translateY(3px); filter: blur(2px); }
.swap-leave-to { opacity: 0; transform: translateY(-3px); filter: blur(2px); }
.act-in { display: inline-flex; align-items: center; gap: 0.4em; }

/* bottom panels (Convert / Rate / History) */
.panel {
  margin-top: 1.3rem; padding-top: 1.3rem;
  border-top: 1px dashed var(--line-strong);
}
.panel-intro { margin: 0 0 0.9rem; font-size: 0.88rem; color: var(--ink-faint); }
.panel-empty { margin: 0.4rem 0 0.2rem; font-size: 0.92rem; color: var(--ink-faint); }
.rate-enter-active, .rate-leave-active { transition: opacity 0.28s ease, transform 0.3s cubic-bezier(0.25, 1.35, 0.45, 1); }
.rate-enter-from, .rate-leave-to { opacity: 0; transform: translateY(-6px); }

/* convert list */
.cv-sec {
  font-family: var(--font-mono); font-size: 0.58rem; letter-spacing: 0.15em;
  text-transform: uppercase; color: var(--ink-faint); font-weight: 600;
  margin: 0.6rem 0 0.3rem;
}
.cv-list {
  list-style: none; margin: 0 0 0.4rem; padding: 0;
  border: 1px solid var(--line); border-radius: 12px; overflow: hidden; background: var(--card);
}
.cv-list li + li { border-top: 1px solid var(--line); }
.cv-row {
  width: 100%; display: flex; align-items: baseline; justify-content: space-between; gap: 1rem;
  background: transparent; border: 0; cursor: pointer; text-align: left;
  padding: 0.5em 0.85em; font-family: var(--font-app);
}
.cv-row:hover { background: var(--paper-deep); }
.cv-row.on { background: rgba(51, 105, 30, 0.07); }
.cv-name { color: var(--app-unit); font-size: 0.92rem; }
.cv-val { color: var(--app-res-num); font-size: 0.95rem; font-weight: 700; text-align: right; }
.cv-row.on .cv-name { font-weight: 700; }
.cv-scroll {
  max-height: clamp(240px, 46vh, 420px); overflow-y: auto; padding-right: 2px;
  scrollbar-width: thin; scrollbar-color: var(--line-strong) transparent;
}
.cv-scroll::-webkit-scrollbar { width: 10px; }
.cv-scroll::-webkit-scrollbar-thumb {
  background: var(--line-strong); border-radius: 8px;
  border: 3px solid var(--app-display); background-clip: padding-box;
}

/* per / rate */
.per-explain { margin: 0 0 1.1rem; }
.per-explain p { margin: 0 0 0.7rem; font-size: 0.92rem; color: var(--ink-soft); line-height: 1.55; }
.per-explain code {
  font-family: var(--font-mono); font-size: 0.82em;
  background: var(--paper-deep); padding: 0.1em 0.35em; border-radius: 5px; color: var(--olive);
}
.per-eg { font-size: 0.87rem; color: var(--ink-faint); border-left: 2px solid var(--app-unit); padding-left: 0.85rem; }
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
  border: 1px solid var(--line); border-radius: 14px; overflow: hidden; background: var(--card);
}
.per-rows li {
  padding: 0.55em 0.95em; border-bottom: 1px solid var(--line);
}
.per-rows li:last-child { border-bottom: 0; }
.per-top { display: flex; align-items: baseline; justify-content: space-between; gap: 1rem; }
.per-k { color: var(--ink-soft); font-size: 0.92rem; }
.per-calc { margin-top: 0.12rem; font-size: 0.78rem; color: var(--ink-faint); font-variant-numeric: tabular-nums; }
.per-v { font-family: var(--font-app); font-size: 1.12rem; color: var(--app-res-num); font-variant-numeric: tabular-nums; }
.per-v em { font-style: normal; color: var(--app-res-unit); font-size: 0.85em; }
.per-hint { margin: 1rem 0 0; font-size: 0.88rem; color: var(--ink-faint); }

/* history */
.hist-head { display: flex; align-items: baseline; justify-content: space-between; gap: 1rem; }
.hist-clear {
  background: transparent; border: 0; cursor: pointer; flex: none;
  font-family: var(--font-body); font-size: 0.8rem; color: var(--app-error);
  padding: 0.1em 0.2em; text-decoration: underline; text-underline-offset: 2px;
}
.hist-clear:hover { color: var(--app-error); opacity: 0.8; }
.hist-list {
  list-style: none; margin: 0.3rem 0 0; padding: 0 2px 0 0; display: flex; flex-direction: column; gap: 0.45rem;
  max-height: clamp(220px, 42vh, 360px); overflow-y: auto;
  scrollbar-width: thin; scrollbar-color: var(--line-strong) transparent;
}
.hist-list::-webkit-scrollbar { width: 10px; }
.hist-list::-webkit-scrollbar-thumb {
  background: var(--line-strong); border-radius: 8px;
  border: 3px solid var(--app-display); background-clip: padding-box;
}
.hist-row {
  width: 100%; display: grid; grid-template-columns: 1fr auto; align-items: baseline; gap: 0.2rem 0.8rem;
  background: var(--card); border: 1px solid var(--line); border-radius: 12px;
  cursor: pointer; text-align: left; padding: 0.6em 0.85em; transition: border-color 0.16s, background 0.16s, box-shadow 0.16s;
}
.hist-row:hover { border-color: rgba(51, 105, 30, 0.34); background: var(--paper-deep); box-shadow: 0 4px 14px -9px rgba(28, 27, 21, 0.2); }
.hist-expr { font-family: var(--font-app); font-size: 0.98rem; color: var(--app-num); overflow-wrap: anywhere; }
.hist-res { font-family: var(--font-app); font-size: 0.98rem; font-weight: 700; color: var(--app-res-unit); white-space: nowrap; }
.hist-meta { grid-column: 1 / -1; font-family: var(--font-mono); font-size: 0.62rem; letter-spacing: 0.04em; color: var(--ink-faint); }

/* examples + micro */
.examples { display: flex; align-items: center; gap: 0.5rem; flex-wrap: wrap; margin-top: 1.4rem; }
.ex-label { font-family: var(--font-mono); font-size: 0.66rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--ink-faint); }
.ex {
  border: 1px solid var(--line); background: var(--paper-deep);
  color: var(--ink-soft); font-family: var(--font-app); font-size: 0.86rem;
  padding: 0.42em 0.7em; border-radius: 8px; cursor: pointer; transition: 0.16s;
}
.ex:hover { border-color: rgba(51, 105, 30, 0.36); color: var(--app-unit); background: var(--card); transform: translateY(-1px); box-shadow: 0 3px 11px -6px rgba(28, 27, 21, 0.2); }
.micro { margin: 1rem 0.2rem 0; font-size: 0.84rem; color: var(--ink-faint); max-width: none; }
.resize-tip { color: var(--app-unit); }
.micro code { font-family: var(--font-mono); font-size: 0.82em; background: var(--paper-deep); padding: 0.1em 0.35em; border-radius: 5px; color: var(--olive); }

@media (max-width: 560px) {
  .per-unit { width: 6.5rem; }
}
</style>
