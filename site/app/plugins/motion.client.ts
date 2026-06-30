// Progressive-enhancement reveal-on-scroll.
//
// The `has-motion` class is set by a tiny inline <head> script (see
// nuxt.config) so [data-reveal] elements never flash and stay fully visible for
// no-JS / reduced-motion / crawlers. Here we just flip `is-in` as each element
// scrolls into view; the transition itself lives in main.css.
export default defineNuxtPlugin((nuxtApp) => {
  nuxtApp.hook('app:mounted', () => {
    if (!document.documentElement.classList.contains('has-motion')) return

    const reveal = (el: Element) => el.classList.add('is-in')
    const run = () => {
      const els = Array.from(document.querySelectorAll<HTMLElement>('[data-reveal]:not(.is-in)'))
      if (!els.length) return
      if (!('IntersectionObserver' in window)) {
        els.forEach(reveal)
        return
      }
      const io = new IntersectionObserver((entries) => {
        for (const e of entries) {
          if (e.isIntersecting) {
            reveal(e.target)
            io.unobserve(e.target)
          }
        }
      }, { rootMargin: '0px 0px -8% 0px', threshold: 0.08 })
      els.forEach(el => io.observe(el))
    }

    requestAnimationFrame(run)
    // re-scan after client-side navigation
    nuxtApp.hook('page:finish', () => { requestAnimationFrame(run) })
  })
})
