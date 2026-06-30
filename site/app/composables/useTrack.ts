// One call → both analytics systems. Vercel Web Analytics (cookieless, counts
// everyone) and Google Analytics 4 (consent-gated, only records once a visitor
// accepts). Both are no-ops when their script isn't loaded, so this is safe in
// dev and before consent.
import { track as vercelTrack } from '@vercel/analytics'

type Props = Record<string, string | number | boolean>

export function useTrack() {
  const { gtag } = useGtag()
  return (name: string, props?: Props) => {
    if (!import.meta.client) return
    try {
      vercelTrack(name, props)
    } catch {
      /* noop */
    }
    try {
      gtag('event', name, props ?? {})
    } catch {
      /* noop */
    }
  }
}
