<script setup lang="ts">
const site = useSiteConfig()
const trackEvent = useTrack()
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const appStoreUrl = 'https://apps.apple.com/app/id6789162864'

// Real app screens (golden renders from the Flutter app). Each gets its own
// description — this is the screenshot tour, not a wall of identical cards.
const screens = [
  {
    img: '/screenshots/calculator.png',
    tag: 'The calculator',
    title: 'A keypad made for time',
    text: 'Tap the keypad to build a sum like 5h - 10m and read the answer as you go. Tap the format chip to change how the result reads, from hours and minutes to a full breakdown.',
    alt: 'Time Calculator app showing 5 Hours minus 10 Minutes equals 4 Hours 50 Minutes above a keypad of time-unit keys',
  },
  {
    img: '/screenshots/formats.png',
    tag: 'Result formats',
    title: 'Every unit on one screen',
    text: 'See the same total as years, days, hours, minutes, or milliseconds all at once, then tap one to set it as your result. No converting in your head.',
    alt: 'Result format screen listing the same duration as years, months, weeks, days, hours, minutes, seconds and milliseconds',
  },
  {
    img: '/screenshots/rate.png',
    tag: 'Rate calculator',
    title: 'Turn time into a rate',
    text: 'Enter an amount and read it per hour, minute, day, or week against your duration. Built for billing, pay, and quick what-if estimates.',
    alt: 'Rate calculator showing totals per hour, minute, second and day for a 25 USD amount over 4 Hours 50 Minutes',
  },
  {
    img: '/screenshots/history.png',
    tag: 'History',
    title: 'Saved, with your own notes',
    text: 'Keep a result, label it like "Project A payroll", and tap any entry to reopen it in the exact format you saved it with. Copy or edit in a tap.',
    alt: 'History screen with two saved calculations, one labelled Project A payroll, each with copy, edit and delete actions',
  },
  {
    img: '/screenshots/keypad.png',
    tag: 'Custom keypad',
    title: 'A keypad you shape',
    text: 'One-tap presets like Stopwatch or Media, or pick the exact unit keys you want. Fewer keys means a cleaner, faster pad with a live preview as you choose.',
    alt: 'Keypad keys settings with a live preview and presets including Standard, Stopwatch, Media, Calendar and Everything',
  },
  {
    img: '/screenshots/dark.png',
    tag: 'Themes',
    title: 'Light, dark, your call',
    text: 'Light, dark, and system themes, with the same quick keypad. Drag the divider to resize the display to fit your hand.',
    alt: 'Time Calculator app shown in its dark theme',
  },
]

useSeoMeta({
  title: SHOWCASE.metaTitle,
  description: SHOWCASE.metaDescription,
  ogTitle: SHOWCASE.h1,
  ogDescription: SHOWCASE.metaDescription,
  ogUrl: `${site.url}/app`,
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
    { '@type': 'ListItem', position: 2, name: 'Mobile app', item: `${site.url}/app` },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <div class="appshow">
    <section class="wrap as-hero">
      <nav class="crumbs" aria-label="Breadcrumb">
        <NuxtLink to="/">Home</NuxtLink>
        <span aria-hidden="true">/</span>
        <span aria-current="page">Mobile app</span>
      </nav>

      <h1 data-reveal style="--rd: 0s">{{ SHOWCASE.h1 }}</h1>
      <p class="as-pitch" data-reveal style="--rd: 0.06s">{{ SHOWCASE.pitch }}</p>

      <div class="as-cta" data-reveal style="--rd: 0.12s">
        <a :href="playUrl" target="_blank" rel="noopener" class="store-badge"
          @click="trackEvent('app_store_click', { store: 'play', location: 'app-page' })">
          <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
            <path fill="#3DA50C" d="M3.6 2.3 13 12 3.6 21.7a1.4 1.4 0 0 1-.6-1.2V3.5c0-.5.2-.9.6-1.2Z"/>
            <path fill="#5C7D0E" d="M16.8 8.4 14.3 12l2.5 3.6 3.6-2.1c1-.6 1-2 0-2.6l-3.6-2.5Z"/>
            <path fill="#1f6c10" d="M4 2.1c.3-.1.7-.1 1 .1l11 6.3-2.6 2.6L4 2.1Z"/>
            <path fill="#2f9412" d="M4 21.9 13.4 12.5 16 15.1 5 21.8c-.3.2-.7.2-1 .1Z"/>
          </svg>
          <span><small>Get it on</small>Google Play</span>
        </a>
        <a :href="appStoreUrl" target="_blank" rel="noopener" class="store-badge"
          @click="trackEvent('app_store_click', { store: 'ios', location: 'app-page' })">
          <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M16 1c.1 1.2-.4 2.4-1.1 3.2-.8.9-2 1.6-3.1 1.5-.1-1.2.4-2.4 1.1-3.2C13.7 1.6 15 .9 16 1Zm3.5 16.6c-.6 1.3-.9 1.9-1.6 3-1 1.6-2.5 3.6-4.3 3.6-1.6 0-2-1-4.2-1-2.1 0-2.6 1-4.2 1-1.8 0-3.2-1.8-4.2-3.4C-.9 17.4-1.2 11 1.5 7.9 2.7 6.4 4.4 5.6 6 5.6c1.7 0 2.7 1 4.1 1 1.3 0 2.1-1 4.1-1 1.4 0 2.9.8 4 2.1-3.5 1.9-3 6.9 1.3 7.9Z"/></svg>
          <span><small>Download on the</small>App Store</span>
        </a>
        <span class="as-rating">★ 4.6 · 391 ratings</span>
      </div>
    </section>

    <!-- screenshot tour: alternating phone + description -->
    <section class="wrap as-tour">
      <h2 class="as-h2">A look inside</h2>
      <div class="screens">
        <div v-for="(s, i) in screens" :key="i" class="screen-row" :class="{ flip: i % 2 === 1 }" data-reveal>
          <div class="screen-shot">
            <div class="phone">
              <span class="phone-notch" aria-hidden="true" />
              <img :src="s.img" :alt="s.alt" width="390" height="878" loading="lazy" />
              <span class="phone-glare" aria-hidden="true" />
            </div>
          </div>
          <div class="screen-copy">
            <span class="screen-tag">{{ s.tag }}</span>
            <h3>{{ s.title }}</h3>
            <p>{{ s.text }}</p>
          </div>
        </div>
      </div>
    </section>

    <!-- what's new callout -->
    <section class="wrap">
      <NuxtLink to="/whats-new" class="whatsnew-cta" data-reveal>
        <div>
          <span class="wn-pill">Latest update</span>
          <p>Customisable keypad, saved history, and quick result actions.</p>
        </div>
        <span class="wn-arrow">See what's new →</span>
      </NuxtLink>
    </section>

    <!-- use cases: a distinct, accent-left treatment (not the boxed cards) -->
    <section class="wrap as-uses">
      <h2 class="as-h2">What people use it for</h2>
      <div class="uc-grid">
        <div v-for="(u, i) in SHOWCASE.useCases" :key="i" class="uc" data-reveal :style="`--rd:${i * 0.04}s`">
          <span class="uc-tag">{{ u.tag }}</span>
          <h3>{{ u.title }}</h3>
          <p>{{ u.text }}</p>
        </div>
      </div>
    </section>

    <section class="wrap as-cols">
      <div>
        <h2 class="as-h2">What it does</h2>
        <ul class="as-list">
          <li v-for="(f, i) in SHOWCASE.features" :key="i">{{ f }}</li>
        </ul>
      </div>
      <div>
        <h2 class="as-h2">Why the app</h2>
        <ul class="as-list as-why">
          <li v-for="(w, i) in SHOWCASE.whyApp" :key="i">{{ w }}</li>
        </ul>
      </div>
    </section>

    <p class="wrap as-back">
      Prefer the browser? <NuxtLink to="/">Use the web calculator</NuxtLink> — same engine, nothing to install.
    </p>
  </div>
</template>

<style scoped>
.appshow { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.as-hero h1 { max-width: 18ch; }
.as-pitch { max-width: 62ch; font-size: 1.12rem; line-height: 1.6; margin: 1rem 0 1.6rem; }
.as-cta { display: flex; align-items: center; gap: 0.8rem; flex-wrap: wrap; }
.store-badge { display: inline-flex; align-items: center; gap: 0.6rem; padding: 0.6rem 1.05rem; border-radius: 13px; border: 1px solid var(--line-strong); background: var(--card); color: var(--ink); text-decoration: none; font-weight: 600; transition: transform 0.18s var(--ease-pop), border-color 0.18s; }
.store-badge:hover { border-color: var(--green); transform: translateY(-2px); }
.store-badge span { display: flex; flex-direction: column; line-height: 1.15; }
.store-badge small { font-size: 0.62rem; font-weight: 500; color: var(--ink-faint); text-transform: uppercase; letter-spacing: 0.08em; }
.as-rating { font-family: var(--font-mono); font-size: 0.8rem; color: var(--olive); }

.as-h2 { font-size: clamp(1.5rem, 1.2rem + 1vw, 2rem); margin-top: 0; }
.as-tour { margin-top: 3.4rem; }
.screens { display: grid; gap: 3.2rem; margin-top: 1.6rem; }
.screen-row { display: grid; grid-template-columns: 260px 1fr; gap: clamp(1.5rem, 4vw, 3.5rem); align-items: center; }
.screen-row.flip .screen-shot { order: 2; }
.screen-copy { min-width: 0; }
.screen-tag { font-family: var(--font-mono); font-size: 0.66rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--olive); }
.screen-copy h3 { font-size: clamp(1.3rem, 1.1rem + 0.7vw, 1.7rem); margin: 0.4rem 0 0.6rem; letter-spacing: -0.01em; }
.screen-copy p { font-size: 1.02rem; line-height: 1.6; max-width: 46ch; }

/* phone frame */
.phone { position: relative; width: 240px; margin-inline: auto; padding: 8px; border-radius: 26px; background: linear-gradient(155deg, #38332a, #14120c); box-shadow: 0 34px 60px -32px rgba(0, 0, 0, 0.6), inset 0 0 0 1.5px rgba(255, 255, 255, 0.06); transition: transform 0.45s var(--ease-pop); }
.screen-row:hover .phone { transform: translateY(-8px) rotate(-1.2deg); }
.screen-row.flip:hover .phone { transform: translateY(-8px) rotate(1.2deg); }
.phone-notch { position: absolute; top: 17px; left: 50%; transform: translateX(-50%); width: 9px; height: 9px; border-radius: 50%; background: rgba(0, 0, 0, 0.55); z-index: 2; }
.phone img { display: block; width: 100%; height: auto; border-radius: 18px; }
/* light reflection: a sheen that sweeps across the glass as the phone tilts */
.phone-glare { position: absolute; inset: 8px; border-radius: 18px; overflow: hidden; pointer-events: none; z-index: 3; }
.phone-glare::before {
  content: "";
  position: absolute;
  top: -40%;
  left: -75%;
  width: 55%;
  height: 180%;
  background: linear-gradient(100deg, transparent, rgba(255, 255, 255, 0.26), transparent);
  transform: rotate(9deg);
  opacity: 0;
  transition: transform 0.85s var(--ease-pop), opacity 0.45s ease;
}
.screen-row:hover .phone-glare::before { opacity: 1; transform: rotate(9deg) translateX(420%); }

/* what's new callout */
.whatsnew-cta { display: flex; align-items: center; justify-content: space-between; gap: 1rem; flex-wrap: wrap; margin-top: 3.4rem; padding: 1.2rem 1.5rem; border-radius: var(--radius); text-decoration: none; color: var(--ink); background: linear-gradient(120deg, color-mix(in srgb, var(--green) 14%, transparent), color-mix(in srgb, var(--ochre) 10%, transparent)); border: 1px solid var(--card-edge); transition: transform 0.2s var(--ease-pop), box-shadow 0.2s; }
.whatsnew-cta:hover { transform: translateY(-2px); box-shadow: 0 14px 30px -20px rgba(28, 27, 21, 0.35); }
.wn-pill { font-family: var(--font-mono); font-size: 0.62rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--on-green); background: var(--green); padding: 0.25em 0.7em; border-radius: 999px; }
.whatsnew-cta p { margin: 0.5rem 0 0; color: var(--ink); font-weight: 500; }
.wn-arrow { font-weight: 700; color: var(--green-deep); white-space: nowrap; }

/* use cases: accent-left, tinted — deliberately NOT the boxed cards */
.as-uses { margin-top: 3.4rem; }
.uc-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); gap: 0.8rem 1.4rem; margin-top: 1.4rem; }
.uc { padding: 0.7rem 0 0.7rem 1.1rem; border-left: 3px solid var(--green); }
.uc-tag { font-family: var(--font-mono); font-size: 0.6rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--olive); }
.uc h3 { font-size: 1.05rem; margin: 0.25rem 0 0.3rem; }
.uc p { margin: 0; font-size: 0.92rem; color: var(--ink-soft); }

.as-cols { display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.4rem 2.4rem; margin-top: 3.4rem; }
.as-list { padding-left: 1.1rem; margin: 0.6rem 0; }
.as-list li { margin: 0.4rem 0; color: var(--ink-soft); }
.as-list li::marker { color: var(--green); }
.as-back { margin-top: 3rem; font-size: 0.98rem; }
.as-back a { font-weight: 600; }

@media (max-width: 720px) {
  .screen-row { grid-template-columns: 1fr; }
  /* stacked: header + description first, then the screenshot */
  .screen-copy { order: 1; }
  .screen-shot { order: 2; display: flex; justify-content: center; }
}
</style>
