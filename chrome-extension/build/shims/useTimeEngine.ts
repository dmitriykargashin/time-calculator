// Extension replacement for the site's Nuxt `useTimeEngine()` composable. The
// site version uses Nuxt's `useState` + injects the engine from the site's public
// root (`/engine/time_engine.js`). Here we drop Nuxt and load the engine from the
// extension bundle (popup.html loads it before this runs). The PURE helpers
// (colorize, expandColon, toClockString, …) are still imported straight from the
// site file via the `~` alias, so the reused component behaves identically.
import { ref, onMounted } from 'vue'
import { normalizeExpression, type EvalResult, type PerUnit } from '~/composables/useTimeEngine'

declare global {
  interface Window {
    evaluateTime?: (input: string, format: string) => string
    intervalBreakdown?: (input: string) => string
  }
}

const PER_UNITS: PerUnit[] = ['Year', 'Month', 'Week', 'Day', 'Hour', 'Minute', 'Second']
const CANONICAL = new Set(['Year', 'Month', 'Week', 'Day', 'Hour', 'Minute', 'Second', 'MSecond'])

function firstUnknownUnit(normalized: string): string | null {
  const words = normalized.match(/[A-Za-z]+/g)
  if (!words) return null
  for (const w of words) if (!CANONICAL.has(w)) return w
  return null
}

let loadPromise: Promise<boolean> | null = null
function loadEngine(): Promise<boolean> {
  if (typeof window === 'undefined') return Promise.resolve(false)
  if (typeof window.evaluateTime === 'function') return Promise.resolve(true)
  if (loadPromise) return loadPromise
  // popup.html already injects engine/time_engine.js; just wait for the global.
  loadPromise = new Promise<boolean>((resolve) => {
    let tries = 0
    const t = setInterval(() => {
      if (typeof window.evaluateTime === 'function') { clearInterval(t); resolve(true) }
      else if (++tries > 200) { clearInterval(t); resolve(false) }
    }, 15)
  })
  return loadPromise
}

export function useTimeEngine() {
  const ready = ref(typeof window !== 'undefined' && typeof window.evaluateTime === 'function')

  onMounted(async () => { ready.value = await loadEngine() })

  function evaluate(input: string, format: string): EvalResult {
    const normalized = normalizeExpression(input)
    if (typeof window === 'undefined' || typeof window.evaluateTime !== 'function') {
      return { ok: false, result: '', error: false, normalized }
    }
    if (normalized === '') return { ok: false, result: '', error: false, normalized }
    const unknown = firstUnknownUnit(normalized)
    if (unknown) {
      return { ok: false, result: '', error: false, normalized, incomplete: true, hint: `"${unknown}" is not a known unit` }
    }
    let out = ''
    try { out = window.evaluateTime(normalized, format) } catch { return { ok: false, result: '', error: true, normalized } }
    if (out === 'ERROR') return { ok: false, result: '', error: true, normalized }
    if (out === 'INCOMPLETE') return { ok: false, result: '', error: false, normalized, incomplete: true, hint: 'give every number a unit' }
    if (out === 'SCALAR_ONLY') return { ok: false, result: '', error: false, normalized, incomplete: true, hint: 'multiply and divide by a number only' }
    if (out === '') return { ok: false, result: '', error: false, normalized }
    return { ok: true, result: out, error: false, normalized }
  }

  function perBreakdown(input: string): Record<PerUnit, number> | null {
    if (typeof window === 'undefined' || typeof window.intervalBreakdown !== 'function') return null
    const norm = normalizeExpression(input)
    if (!norm) return null
    let obj: { ok?: boolean } & Record<string, string>
    try { obj = JSON.parse(window.intervalBreakdown(norm)) } catch { return null }
    if (obj?.ok !== true) return null
    const r = {} as Record<PerUnit, number>
    for (const u of PER_UNITS) r[u] = parseFloat(obj[u]!)
    return r
  }

  return { ready, evaluate, perBreakdown, normalizeExpression }
}
