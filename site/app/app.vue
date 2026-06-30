<script setup lang="ts">
const { reopen: openCookieSettings } = useConsent()
const trackEvent = useTrack()
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const year = 2026
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
          <NuxtLink to="/app" class="head-link">Mobile&nbsp;app</NuxtLink>
          <NuxtLink to="/#faq" class="head-link">FAQ</NuxtLink>
          <ThemeSwitcher />
          <a :href="playUrl" target="_blank" rel="noopener" class="btn btn-ghost head-cta"
            @click="trackEvent('app_store_click', { store: 'play', location: 'header' })">
            Get the app
          </a>
        </nav>
      </div>
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
@media (max-width: 640px) {
  .head-link {
    display: none;
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
