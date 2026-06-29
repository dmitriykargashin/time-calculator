<script setup lang="ts">
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const year = 2026
</script>

<template>
  <div class="page">
    <header class="site-head">
      <div class="wrap head-inner">
        <a href="/" class="brand" aria-label="Time Calculator Cardamon — home">
          <img src="/icons/app-logo.png" alt="" width="34" height="34" class="brand-mark" />
          <span class="brand-name">Time&nbsp;Calculator<span class="brand-sub">by Cardamon</span></span>
        </a>
        <nav class="head-nav">
          <a href="#how" class="head-link">How it works</a>
          <a href="#faq" class="head-link">FAQ</a>
          <a :href="playUrl" target="_blank" rel="noopener" class="btn btn-ghost head-cta">
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
          <img src="/icons/app-logo.png" alt="" width="30" height="30" />
          <div>
            <p class="foot-title">Time Calculator</p>
            <p class="foot-by">A Cardamon product · the same engine as the mobile apps.</p>
          </div>
        </div>
        <nav class="foot-links">
          <a :href="playUrl" target="_blank" rel="noopener">Google&nbsp;Play</a>
          <span class="foot-soon">App&nbsp;Store · soon</span>
          <a href="https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator" target="_blank" rel="noopener">Privacy</a>
          <a href="mailto:support@cardamon.org">support@cardamon.org</a>
        </nav>
      </div>
      <p class="foot-copy wrap">© {{ year }} Cardamon. All rights reserved.</p>
    </footer>
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
  border-radius: 7px;
  filter: drop-shadow(0 2px 5px rgba(40, 36, 20, 0.16));
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
  align-items: center;
  justify-content: space-between;
  gap: 1.4rem;
  flex-wrap: wrap;
  padding-top: 2.2rem;
}
.foot-brand {
  display: flex;
  align-items: center;
  gap: 0.8rem;
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
.foot-links {
  display: flex;
  gap: 1.3rem;
  flex-wrap: wrap;
  font-size: 0.9rem;
  font-weight: 500;
}
.foot-links a {
  color: var(--ink-soft);
  text-decoration: none;
}
.foot-links a:hover {
  color: var(--green-deep);
}
.foot-soon {
  color: var(--ink-faint);
}
.foot-copy {
  margin-top: 1.4rem;
  font-size: 0.8rem;
  color: var(--ink-faint);
}
</style>
