<script setup lang="ts">
const { reopen: openCookieSettings } = useConsent()
const trackEvent = useTrack()
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const year = 2026

// Mobile burger menu (nav links are hidden under 640px).
const mobileOpen = ref(false)
const route = useRoute()
watch(() => route.fullPath, () => { mobileOpen.value = false })
</script>

<template>
  <div class="page">
    <header class="site-head">
      <div class="wrap head-inner">
        <a href="/" class="brand" aria-label="Time Calculator Cardamon home">
          <img src="/icons/app-logo.png" alt="" width="34" height="34" class="brand-mark" />
          <span class="brand-name">Time&nbsp;Calculator<span class="brand-sub">by Cardamon</span></span>
        </a>
        <nav class="head-nav">
          <NuxtLink to="/" class="head-link">Home</NuxtLink>
          <NuxtLink to="/guides" class="head-link">Guides</NuxtLink>
          <NuxtLink to="/convert" class="head-link">Convert</NuxtLink>
          <NuxtLink to="/app" class="head-link">Mobile&nbsp;app</NuxtLink>
          <NuxtLink to="/#faq" class="head-link">FAQ</NuxtLink>
          <ThemeSwitcher />
          <a :href="playUrl" target="_blank" rel="noopener" class="btn btn-ghost head-cta"
            @click="trackEvent('app_store_click', { store: 'play', location: 'header' })">
            Get the app
          </a>
          <button
            type="button"
            class="head-burger"
            :aria-expanded="mobileOpen"
            aria-controls="mobile-menu"
            aria-label="Menu"
            @click="mobileOpen = !mobileOpen"
          >
            <svg v-if="!mobileOpen" viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M3 6h18M3 12h18M3 18h18" /></svg>
            <svg v-else viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"><path d="M6 6l12 12M18 6L6 18" /></svg>
          </button>
        </nav>
      </div>

      <Transition name="mmenu">
        <nav v-if="mobileOpen" id="mobile-menu" class="mobile-menu" aria-label="Mobile">
          <NuxtLink to="/" @click="mobileOpen = false">Home</NuxtLink>
          <NuxtLink to="/guides" @click="mobileOpen = false">Guides</NuxtLink>
          <NuxtLink to="/convert" @click="mobileOpen = false">Convert</NuxtLink>
          <NuxtLink to="/app" @click="mobileOpen = false">Mobile app</NuxtLink>
          <NuxtLink to="/reviews" @click="mobileOpen = false">Reviews</NuxtLink>
          <NuxtLink to="/whats-new" @click="mobileOpen = false">What's new</NuxtLink>
          <NuxtLink to="/#faq" @click="mobileOpen = false">FAQ</NuxtLink>
          <a
            :href="playUrl"
            target="_blank"
            rel="noopener"
            class="btn btn-green mobile-cta"
            @click="mobileOpen = false; trackEvent('app_store_click', { store: 'play', location: 'mobile-menu' })"
          >Get the app</a>
        </nav>
      </Transition>
    </header>

    <main>
      <NuxtPage />
    </main>

    <footer class="site-foot">
      <div class="ticks" aria-hidden="true" />
      <div class="wrap foot-inner">
        <div class="foot-brand">
          <img src="/icons/app-logo.png" alt="" width="38" height="38" class="foot-mark" />
          <div>
            <p class="foot-title">Time Calculator</p>
            <p class="foot-by">From Cardamon, running the same engine as the mobile apps.</p>
          </div>
        </div>
        <nav class="foot-cols" aria-label="Footer">
          <div class="foot-col">
            <h3>Calculator</h3>
            <NuxtLink to="/">Web calculator</NuxtLink>
            <NuxtLink to="/convert">Unit converter</NuxtLink>
            <NuxtLink to="/guides">Guides</NuxtLink>
            <NuxtLink to="/reviews">Reviews</NuxtLink>
            <NuxtLink to="/#faq">FAQ</NuxtLink>
          </div>
          <div class="foot-col">
            <h3>Mobile app</h3>
            <NuxtLink to="/app">Overview</NuxtLink>
            <a :href="playUrl" target="_blank" rel="noopener"
              @click="trackEvent('app_store_click', { store: 'play', location: 'footer' })">Google&nbsp;Play</a>
            <NuxtLink to="/whats-new">What's&nbsp;new</NuxtLink>
            <span class="foot-soon">App&nbsp;Store · soon</span>
          </div>
          <div class="foot-col">
            <h3>More</h3>
            <a href="https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator" target="_blank" rel="noopener">Privacy</a>
            <button type="button" class="foot-cookie" @click="openCookieSettings">Cookie settings</button>
            <a href="mailto:support@cardamon.org">support@cardamon.org</a>
            <a href="/llms.txt">llms.txt</a>
          </div>
        </nav>
      </div>
      <div class="foot-bottom wrap">
        <a href="https://www.cardamon.org" target="_blank" rel="noopener" class="foot-cardamon" aria-label="Cardamon">
          <img src="/cardamon-logo.svg" alt="" width="20" height="20" />
          <span>Cardamon</span>
        </a>
        <span class="foot-copy">© {{ year }} Cardamon Inc. All rights reserved.</span>
      </div>
    </footer>

    <CookieConsent />
  </div>
</template>

<style scoped>
.page {
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
}
main {
  flex: 1;
}

/* header */
.site-head {
  position: sticky;
  top: 0;
  z-index: 50;
  backdrop-filter: saturate(1.4) blur(8px);
  background: color-mix(in srgb, var(--paper) 82%, transparent);
  border-bottom: 1px solid var(--line);
}
.head-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 68px;
}
.brand {
  display: inline-flex;
  align-items: center;
  gap: 0.6rem;
  text-decoration: none;
  color: var(--ink);
}
.brand-mark {
  /* transparent green-clock mark — height matched to the brand text block */
  display: block;
  width: auto;
  height: 2.2rem;
}
.brand-name {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 1.12rem;
  letter-spacing: -0.01em;
  line-height: 1;
  display: flex;
  flex-direction: column;
}
.brand-sub {
  font-family: var(--font-mono);
  font-size: 0.6rem;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--ink-faint);
  font-weight: 500;
  margin-top: 2px;
}
.head-nav {
  display: flex;
  align-items: center;
  gap: 1.6rem;
}
.head-link {
  font-size: 0.92rem;
  color: var(--ink-soft);
  text-decoration: none;
  font-weight: 500;
}
.head-link:hover {
  color: var(--ink);
}
.head-cta {
  padding: 0.6em 1.05em;
  font-size: 0.88rem;
}
.head-burger {
  display: none;
  background: none;
  border: 0;
  padding: 0.3rem;
  margin: -0.3rem;
  color: var(--ink);
  cursor: pointer;
  align-items: center;
}
@media (max-width: 640px) {
  .head-link,
  .head-cta {
    display: none;
  }
  .head-burger {
    display: inline-flex;
  }
}

/* mobile dropdown menu */
.mobile-menu {
  display: flex;
  flex-direction: column;
  padding: 0.4rem 1.2rem 1.1rem;
  background: var(--paper);
  border-bottom: 1px solid var(--line);
}
.mobile-menu > a:not(.mobile-cta) {
  padding: 0.85rem 0.3rem;
  color: var(--ink-soft);
  text-decoration: none;
  font-weight: 600;
  font-size: 1.02rem;
  border-bottom: 1px solid var(--line);
}
.mobile-menu > a:not(.mobile-cta):hover {
  color: var(--green-deep);
}
.mobile-cta {
  margin-top: 0.9rem;
  justify-content: center;
}
.mmenu-enter-active,
.mmenu-leave-active {
  transition: opacity 0.22s ease, transform 0.22s var(--ease-pop);
  transform-origin: top;
}
.mmenu-enter-from,
.mmenu-leave-to {
  opacity: 0;
  transform: translateY(-8px);
}
@media (min-width: 641px) {
  .mobile-menu {
    display: none !important;
  }
}

/* footer */
.site-foot {
  margin-top: 5rem;
  padding-bottom: 2.4rem;
  border-top: 1px solid transparent;
}
.foot-inner {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 2rem 3rem;
  flex-wrap: wrap;
  padding-top: 2.2rem;
}
.foot-brand {
  display: flex;
  align-items: center;
  gap: 0.8rem;
  flex: 1 1 260px;
  max-width: 340px;
}
.foot-mark {
  /* transparent green-clock mark — height matched to the footer text block */
  display: block;
  width: auto;
  height: 2.5rem;
}
.foot-title {
  font-family: var(--font-display);
  font-weight: 600;
  margin: 0;
  color: var(--ink);
  line-height: 1.1;
}
.foot-by {
  margin: 0;
  font-size: 0.85rem;
  color: var(--ink-faint);
}
.foot-cols {
  display: grid;
  grid-template-columns: repeat(3, minmax(104px, auto));
  gap: 1.4rem 2.6rem;
  flex: 2 1 auto;
  justify-content: end;
}
.foot-col {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 0.55rem;
  font-size: 0.9rem;
}
.foot-col h3 {
  font-family: var(--font-display);
  font-size: 0.82rem;
  font-weight: 600;
  color: var(--ink);
  margin: 0 0 0.35rem;
}
.foot-col a,
.foot-col .foot-cookie {
  color: var(--ink-soft);
  text-decoration: none;
  font-weight: 500;
}
.foot-col a:hover,
.foot-col .foot-cookie:hover {
  color: var(--green-deep);
}
@media (max-width: 560px) {
  .foot-cols {
    grid-template-columns: 1fr 1fr;
    justify-content: start;
  }
}
.foot-cookie {
  border: 0;
  background: none;
  padding: 0;
  font: inherit;
  font-weight: 500;
  color: var(--ink-soft);
  cursor: pointer;
}
.foot-cookie:hover {
  color: var(--green-deep);
}
.foot-soon {
  color: var(--ink-faint);
}
.foot-bottom {
  display: flex;
  align-items: center;
  gap: 0.5rem 1.1rem;
  flex-wrap: wrap;
  margin-top: 2rem;
}
.foot-cardamon {
  display: inline-flex;
  align-items: center;
  gap: 0.45rem;
  text-decoration: none;
  color: var(--ink);
}
.foot-cardamon img {
  display: block;
  width: 20px;
  height: 20px;
}
.foot-cardamon span {
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 0.95rem;
}
.foot-cardamon:hover {
  color: var(--green-deep);
}
.foot-copy {
  font-size: 0.8rem;
  color: var(--ink-faint);
}
</style>
