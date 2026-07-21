// Initialize Google Analytics at browser idle instead of during startup.
// nuxt-gtag is set to initMode: 'manual' (nuxt.config.ts), so gtag.js — the
// single heaviest third-party script (~169 KiB, ~350 ms of mobile main-thread
// in Lighthouse) — stays off the critical path. The Consent Mode defaults from
// initCommands are applied when initialize() runs, so the EEA/UK/CH consent
// gating is unchanged; only the load timing moves. The timeout guarantees
// analytics still starts within a few seconds even on a permanently busy tab.
export default defineNuxtPlugin(() => {
  const { initialize } = useGtag()
  const start = () => initialize()
  if ('requestIdleCallback' in window) {
    requestIdleCallback(start, { timeout: 3500 })
  } else {
    setTimeout(start, 2000)
  }
})
