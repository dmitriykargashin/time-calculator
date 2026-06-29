// Bridge to the Dart-compiled time engine (public/engine/time_engine.js).
// The engine exposes a single global: window.evaluateTime(input, format).
// We load it client-side and feed it a NORMALIZED expression, so web users can
// type naturally ("5h 30m + 2h 15m") while the engine still receives its own
// grammar ("5 Hour 30 Minute + 2 Hour 15 Minute").

declare global {
  interface Window {
    evaluateTime?: (input: string, format: string) => string
    intervalBreakdown?: (input: string) => string
  }
}

/** A coloured token of an expression or result (units green, ops blue). */
export interface ColorTok {
  t: 'num' | 'unit' | 'op' | 'sp'
  v: string
}

const UNIT_WORD =
  /^(?:years?|yrs?|y|months?|mons?|mo|weeks?|wks?|w|days?|d|hours?|hrs?|h|milliseconds?|millis?|msecs?|ms|minutes?|mins?|m|seconds?|secs?|s)$/i

/** Split a duration string into coloured tokens (the app's display styling). */
export function colorize(s: string): ColorTok[] {
  const out: ColorTok[] = []
  const re = /(\d+(?:\.\d+)?)|([a-zA-Z]+)|([+\-*/×÷])|(\s+)|(.)/g
  let m: RegExpExecArray | null
  while ((m = re.exec(s))) {
    if (m[1] != null) out.push({ t: 'num', v: m[1] })
    else if (m[2] != null) out.push({ t: UNIT_WORD.test(m[2]) ? 'unit' : 'num', v: m[2] })
    else if (m[3] != null) out.push({ t: 'op', v: m[3] })
    else out.push({ t: 'sp', v: m[4] ?? m[5] ?? '' })
  }
  return out
}

export const PER_UNITS = ['Year', 'Month', 'Week', 'Day', 'Hour', 'Minute', 'Second'] as const
export type PerUnit = (typeof PER_UNITS)[number]

export interface EvalResult {
  ok: boolean // a usable result string is present
  result: string // e.g. "7 Hours 45 Minutes"
  error: boolean // engine returned ERROR (malformed / divide-by-zero)
  normalized: string // what we actually sent the engine (debug/preview)
  incomplete?: boolean // a number is missing its unit, e.g. "20h 15m + 25"
  hint?: string // a short reason to show in place of the result when incomplete
}

// Longest-match-first so "mo"→Month beats "m"→Minute and "ms"→MSecond, etc.
const UNIT_RULES: Array<[RegExp, string]> = [
  [/\b(?:years?|yrs?|y)\b/g, 'Year'],
  [/\b(?:months?|mons?|mo)\b/g, 'Month'],
  [/\b(?:weeks?|wks?|w)\b/g, 'Week'],
  [/\b(?:days?|d)\b/g, 'Day'],
  [/\b(?:hours?|hrs?|h)\b/g, 'Hour'],
  [/\b(?:milliseconds?|millis?|msecs?|ms)\b/g, 'MSecond'],
  [/\b(?:minutes?|mins?|m)\b/g, 'Minute'],
  [/\b(?:seconds?|secs?|s)\b/g, 'Second'],
]

/**
 * Normalize a free-form duration expression into the engine's grammar.
 * Examples: "5h30m" → "5 Hour 30 Minute"; "2 days - 4 hrs" → "2 Day - 4 Hour".
 */
export function normalizeExpression(raw: string): string {
  let s = (raw ?? '').toLowerCase()
  // Unify operator glyphs to ASCII.
  s = s.replace(/[×✕✖]/g, '*').replace(/[÷]/g, '/').replace(/[–—−]/g, '-')
  // Insert a space at every digit↔letter boundary so glued input splits:
  // "5h30m" → "5 h 30 m". (Lookarounds: no characters consumed.)
  s = s.replace(/(?<=\d)(?=[a-z])|(?<=[a-z])(?=\d)/g, ' ')
  // Map unit words → canonical engine unit names.
  for (const [re, name] of UNIT_RULES) s = s.replace(re, name)
  // Tidy whitespace.
  return s.replace(/\s+/g, ' ').trim()
}

let loadPromise: Promise<boolean> | null = null

function loadEngine(): Promise<boolean> {
  if (typeof window === 'undefined') return Promise.resolve(false)
  if (typeof window.evaluateTime === 'function') return Promise.resolve(true)
  if (loadPromise) return loadPromise

  loadPromise = new Promise<boolean>((resolve) => {
    const finish = (ok: boolean) => resolve(ok)
    const waitForGlobal = () => {
      if (typeof window.evaluateTime === 'function') return finish(true)
      let tries = 0
      const t = setInterval(() => {
        if (typeof window.evaluateTime === 'function') {
          clearInterval(t)
          finish(true)
        } else if (++tries > 200) {
          clearInterval(t)
          finish(false)
        }
      }, 15)
    }
    const s = document.createElement('script')
    s.src = '/engine/time_engine.js'
    s.async = true
    s.onload = waitForGlobal
    s.onerror = () => finish(false)
    document.head.appendChild(s)
  })
  return loadPromise
}

export function useTimeEngine() {
  const ready = useState('time-engine-ready', () => false)

  onMounted(async () => {
    ready.value = await loadEngine()
  })

  function evaluate(input: string, format: string): EvalResult {
    const normalized = normalizeExpression(input)
    if (typeof window === 'undefined' || typeof window.evaluateTime !== 'function') {
      return { ok: false, result: '', error: false, normalized }
    }
    if (normalized === '') return { ok: false, result: '', error: false, normalized }
    let out = ''
    try {
      out = window.evaluateTime(normalized, format)
    } catch {
      return { ok: false, result: '', error: true, normalized }
    }
    if (out === 'ERROR') return { ok: false, result: '', error: true, normalized }
    if (out === 'INCOMPLETE') return { ok: false, result: '', error: false, normalized, incomplete: true, hint: 'give every number a unit' }
    if (out === 'SCALAR_ONLY') return { ok: false, result: '', error: false, normalized, incomplete: true, hint: 'multiply and divide by a number only' }
    if (out === '') return { ok: false, result: '', error: false, normalized }
    return { ok: true, result: out, error: false, normalized }
  }

  /** The evaluated interval expressed as a decimal in each time unit (for Per).
   *  e.g. "5h 30m" → { Hour: 5.5, Minute: 330, Day: 0.229, … } or null. */
  function perBreakdown(input: string): Record<PerUnit, number> | null {
    if (typeof window === 'undefined' || typeof window.intervalBreakdown !== 'function') {
      return null
    }
    const norm = normalizeExpression(input)
    if (!norm) return null
    let obj: { ok?: boolean } & Record<string, string>
    try {
      obj = JSON.parse(window.intervalBreakdown(norm))
    } catch {
      return null
    }
    if (obj?.ok !== true) return null
    const r = {} as Record<PerUnit, number>
    for (const u of PER_UNITS) r[u] = parseFloat(obj[u]!)
    return r
  }

  return { ready, evaluate, perBreakdown, normalizeExpression }
}
