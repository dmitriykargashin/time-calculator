// Cookie consent for Google Analytics, wired to Google Consent Mode v2.
//
// GA loads with analytics_storage DENIED by default (set via nuxt-gtag's
// `initCommands` in nuxt.config), so nothing is stored until a visitor opts in.
// Accepting pushes a live `consent update` (granted) — no page reload needed.
// Vercel Analytics is cookieless and isn't gated here.
//
// Stored shape: { analytics: boolean, ts: number } under `tc-cookie-consent`.
const KEY = 'tc-cookie-consent'

interface StoredConsent {
  analytics: boolean
  ts: number
}

export function useConsent() {
  // Shared so the footer "Cookie settings" link can re-open the banner.
  const open = useState('tc-consent-open', () => false)

  const read = (): StoredConsent | null => {
    if (!import.meta.client) return null
    try {
      const raw = localStorage.getItem(KEY)
      return raw ? (JSON.parse(raw) as StoredConsent) : null
    } catch {
      return null
    }
  }

  const pushConsent = (granted: boolean) => {
    if (!import.meta.client) return
    // useGtag().gtag pushes to window.dataLayer; a no-op when GA isn't loaded
    // (e.g. local dev with no NUXT_PUBLIC_GTAG_ID), so this is always safe.
    const { gtag } = useGtag()
    gtag('consent', 'update', { analytics_storage: granted ? 'granted' : 'denied' })
  }

  // Persist a choice and apply it to GA immediately.
  const choose = (analytics: boolean) => {
    if (!import.meta.client) return
    localStorage.setItem(KEY, JSON.stringify({ analytics, ts: Date.now() }))
    pushConsent(analytics)
    open.value = false
  }

  // Re-grant for returning visitors (the default each load is denied).
  const applyStored = () => {
    const stored = read()
    if (stored?.analytics) pushConsent(true)
  }

  const hasChoice = () => read() !== null
  const reopen = () => {
    open.value = true
  }

  return { open, read, choose, applyStored, hasChoice, reopen }
}
