// Popup entry: mounts the SITE's real TimeCalculator.vue (resolved via the `~`
// alias to ../../site/app) so the extension UI is literally the same component.
// Nuxt-only bits (useTimeEngine / useTrack) are supplied by build/shims via
// unplugin-auto-import; the engine is loaded by popup.html before this runs.
import { createApp } from 'vue'
import TimeCalculator from '~/components/TimeCalculator.vue'

// Mount AFTER Chrome's side panel commits its first compositor frame. Mounting
// synchronously during the initial page load renders the whole calculator into a
// panel whose hit-test region isn't live yet — a known Chrome side-panel bug where
// the content looks painted but is completely inert ("like a picture": text won't
// select, buttons don't click) until some reflow wakes it. Deferring past the first
// paint renders the tree into an already-interactive document. Two nested rAFs are
// imperceptible (~1 frame of empty #app) and reliably land after that first commit;
// setTimeout is the fallback where rAF is unavailable.
// The omnibox opens this page as a tab at panel.html?q=<expression> (see
// background.js onInputEntered). Prefill the calculator from it; no query → the
// component's own defaults. URLSearchParams decodes %2B back to "+" and %20 to a
// space, so "25hour%2B52minutes%20-45min" arrives as "25hour+52minutes -45min".
function rootProps(): Record<string, string> {
  try {
    const q = new URLSearchParams(location.search).get('q')
    return q && q.trim() ? { initialExpr: q } : {}
  } catch {
    return {}
  }
}
function mount() {
  createApp(TimeCalculator, rootProps()).mount('#app')
}
if (typeof requestAnimationFrame === 'function') {
  requestAnimationFrame(() => requestAnimationFrame(mount))
} else {
  setTimeout(mount, 0)
}
