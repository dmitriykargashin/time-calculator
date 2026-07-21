<script setup lang="ts">
import { FAQS } from '~/utils/faqs'
import { personNode } from '~/utils/author'

const site = useSiteConfig()
const trackEvent = useTrack()
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const appStoreUrl = 'https://apps.apple.com/app/id6789162864'

useSeoMeta({
  title: 'Time Calculator: Add & Subtract Hours, Minutes & Days',
  description:
    'Free online time duration calculator. Type "5h 30m + 2h 15m" to add or '
    + 'subtract hours, minutes, days, and seconds, right in your browser.',
  ogTitle: 'Time Calculator: add and subtract durations',
  ogDescription:
    'Type something like "2 days - 4h" and read off the answer. Free, fast, and '
    + 'it runs in your browser.',
  ogUrl: site.url,
  ogType: 'website',
  // Dedicated 1200×630 social card (og-image module stays off — see nuxt.config;
  // this is a pre-rendered PNG in public/og.png).
  ogImage: `${site.url}/og.png`,
  ogImageWidth: 1200,
  ogImageHeight: 630,
  ogImageType: 'image/png',
  ogImageAlt: 'Time Calculator by Cardamon: 5h 30m + 2h 15m = 7 Hours 45 Minutes',
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
  twitterImageAlt: 'Time Calculator by Cardamon: 5h 30m + 2h 15m = 7 Hours 45 Minutes',
})
// Canonical is handled automatically by nuxt-seo-utils (now Nuxt 4-compatible).

// Answer-first FAQ — single source in utils/faqs.ts (also feeds llms.txt and
// llms-full.txt). Emitted as FAQPage JSON-LD for AI extraction.
const faqs = FAQS

// Real Google Play reviews (391 ratings, 4.564★ average). Verbatim, lightly
// tidied for readability. The same set feeds the visible cards and the schema.
const rating = { value: 4.6, count: 391, reviews: 256 }
const testimonials = [
  { name: 'Sharon Lloyd', stars: 5, use: 'Timesheets', text: 'Love the app, makes doing my timesheets for work so much easier.' },
  { name: 'Carlos L.', stars: 5, use: 'Truck driving', text: "As a truck driver, it's important to keep track of all the different times you've worked. Very practical." },
  { name: 'John Berghof', stars: 5, use: 'Developers', text: 'Handy tool to convert time between different formats, e.g. for software developers.' },
  { name: 'austin somerset', stars: 5, use: 'Audio editing', text: 'Works great for my audio editing.' },
  { name: 'One Room Shed', stars: 5, text: 'Able to do any type of time calculation that I would ever need, with ease. No ads either. What else could you ask for?' },
  { name: 'debest autofix', stars: 5, use: 'Milliseconds', text: 'The only time calculator app with milliseconds I found.' },
  { name: 'Konstantin M.', stars: 5, use: 'Custom formats', text: 'It correctly converts to days, hours, minutes and seconds, and you can choose a different format. I liked it, even with the simple interface.' },
  { name: 'Haris Siddiqui', stars: 5, use: 'Work hours', text: 'Use it to calculate work hours.' },
  { name: 'Slimmy Jimmy', stars: 5, text: 'I like this app because you can divide, multiply, subtract and add the time.' },
]

const jsonLd = computed(() => ({
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'Organization',
      '@id': `${site.url}/#org`,
      name: 'Cardamon',
      url: 'https://www.cardamon.org',
      logo: `${site.url}/icons/icon-512.png`,
      email: 'support@cardamon.org',
      founder: { '@id': `${site.url}/#person` },
      sameAs: [playUrl, appStoreUrl],
    },
    personNode(site.url),
    {
      '@type': ['WebApplication', 'SoftwareApplication'],
      '@id': `${site.url}/#app`,
      name: 'Time Calculator Cardamon',
      applicationCategory: 'UtilitiesApplication',
      operatingSystem: 'Web, Android, iOS',
      url: site.url,
      description:
        'Free online time duration calculator. Add, subtract, multiply, and divide hours, minutes, days, weeks, and seconds.',
      publisher: { '@id': `${site.url}/#org` },
      offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
      featureList: [
        'Add and subtract time durations',
        'Multiply and divide durations',
        'Years, months, weeks, days, hours, minutes, seconds, milliseconds',
        'Multiple result formats',
      ],
      aggregateRating: {
        '@type': 'AggregateRating',
        ratingValue: '4.6',
        ratingCount: 391,
        reviewCount: 256,
        bestRating: '5',
        worstRating: '1',
      },
      review: testimonials.map((t) => ({
        '@type': 'Review',
        reviewRating: { '@type': 'Rating', ratingValue: t.stars, bestRating: 5 },
        author: { '@type': 'Person', name: t.name },
        reviewBody: t.text,
      })),
    },
    {
      '@type': 'FAQPage',
      '@id': `${site.url}/#faq`,
      mainEntity: faqs.map((f) => ({
        '@type': 'Question',
        name: f.q,
        acceptedAnswer: { '@type': 'Answer', text: f.a },
      })),
    },
  ],
}))

useHead({
  script: [
    {
      type: 'application/ld+json',
      innerHTML: computed(() => JSON.stringify(jsonLd.value)),
    },
  ],
})
</script>

<template>
  <!-- One real H1 for SEO; the visible hero title carries it. -->
  <section class="hero">
    <div class="wrap hero-inner">
      <header class="hero-copy">
        <span class="eyebrow" data-reveal style="--rd: 0s">Free · runs in your browser</span>
        <h1 data-reveal style="--rd: 0.07s">The time calculator<br /><em>that just adds up</em>.</h1>
        <p class="lede" data-reveal style="--rd: 0.14s">
          Type a sum like <code>5h 30m + 2h 15m</code> and read off the answer.
          Add, subtract, multiply, and divide durations straight from your keyboard.
          It runs the same engine as the Cardamon app, now in your browser.
        </p>
      </header>

      <div class="hero-tool" data-reveal style="--rd: 0.24s">
        <TimeCalculator />
      </div>

      <div class="hero-cta" data-reveal style="--rd: 0.34s">
        <a :href="playUrl" target="_blank" rel="noopener" class="store-badge"
          @click="trackEvent('app_store_click', { store: 'play', location: 'hero' })">
          <svg viewBox="0 0 24 24" width="22" height="22" aria-hidden="true">
            <path fill="#3DA50C" d="M3.6 2.3 13 12 3.6 21.7a1.4 1.4 0 0 1-.6-1.2V3.5c0-.5.2-.9.6-1.2Z"/>
            <path fill="#5C7D0E" d="M16.8 8.4 14.3 12l2.5 3.6 3.6-2.1c1-.6 1-2 0-2.6l-3.6-2.5Z"/>
            <path fill="#1f6c10" d="M4 2.1c.3-.1.7-.1 1 .1l11 6.3-2.6 2.6L4 2.1Z"/>
            <path fill="#2f9412" d="M4 21.9 13.4 12.5 16 15.1 5 21.8c-.3.2-.7.2-1 .1Z"/>
          </svg>
          <span><small>Get it on</small>Google Play</span>
        </a>
        <a :href="appStoreUrl" target="_blank" rel="noopener" class="store-badge"
          @click="trackEvent('app_store_click', { store: 'ios', location: 'hero' })">
          <svg viewBox="0 0 24 24" width="20" height="20" aria-hidden="true"><path fill="currentColor" d="M16 1c.1 1.2-.4 2.4-1.1 3.2-.8.9-2 1.6-3.1 1.5-.1-1.2.4-2.4 1.1-3.2C13.7 1.6 15 .9 16 1Zm3.5 16.6c-.6 1.3-.9 1.9-1.6 3-1 1.6-2.5 3.6-4.3 3.6-1.6 0-2-1-4.2-1-2.1 0-2.6 1-4.2 1-1.8 0-3.2-1.8-4.2-3.4C-.9 17.4-1.2 11 1.5 7.9 2.7 6.4 4.4 5.6 6 5.6c1.7 0 2.7 1 4.1 1 1.3 0 2.1-1 4.1-1 1.4 0 2.9.8 4 2.1-3.5 1.9-3 6.9 1.3 7.9Z"/></svg>
          <span><small>Download on the</small>App Store</span>
        </a>
      </div>
    </div>
  </section>

  <div class="wrap"><div class="ticks" aria-hidden="true" /></div>

  <!-- HOW: answer-first + syntax table -->
  <section id="how" class="wrap block" data-reveal>
    <span class="eyebrow">How it works</span>
    <h2>How do I calculate time with this tool?</h2>
    <p class="answer">
      Write your durations on one line and join them with operators.
      <strong>+</strong> adds, <strong>−</strong> subtracts, <strong>×</strong>
      multiplies by a number, and <strong>÷</strong> divides. Each duration is a
      number and a unit, like <code>2h</code> or <code>45 min</code>. Chain as
      many as you want and the calculator rolls them up for you.
    </p>

    <div class="table-card">
      <table class="ref">
        <caption class="sr-only">Supported units and shorthand</caption>
        <thead>
          <tr><th>Unit</th><th>Type</th><th>Example</th></tr>
        </thead>
        <tbody>
          <tr><td>Years</td><td><code>y · year · years</code></td><td><code>1y 6mo</code></td></tr>
          <tr><td>Months</td><td><code>mo · month</code></td><td><code>3mo + 2w</code></td></tr>
          <tr><td>Weeks</td><td><code>w · week</code></td><td><code>1w 3d</code></td></tr>
          <tr><td>Days</td><td><code>d · day</code></td><td><code>2 days - 4h</code></td></tr>
          <tr><td>Hours</td><td><code>h · hr · hour</code></td><td><code>8h 15m</code></td></tr>
          <tr><td>Minutes</td><td><code>m · min · minute</code></td><td><code>90 min</code></td></tr>
          <tr><td>Seconds</td><td><code>s · sec · second</code></td><td><code>30s</code></td></tr>
          <tr><td>Milliseconds</td><td><code>ms · msec · millisecond</code></td><td><code>500 ms</code></td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <!-- REFERENCE: quotable conversion facts (GEO gold) -->
  <section class="wrap block" data-reveal>
    <span class="eyebrow">Reference</span>
    <h2>Time unit conversions, at a glance</h2>
    <p class="answer">
      The calculator runs on these exact numbers. <strong>1 day = 24 hours =
      1,440 minutes = 86,400 seconds.</strong> A week is 7 days, an hour is 60
      minutes, a minute is 60 seconds, and a second is 1,000 milliseconds.
    </p>
    <div class="conv-grid">
      <div class="conv"><b>1 week</b><span>7 days · 168 hours</span></div>
      <div class="conv"><b>1 day</b><span>24 hours · 1,440 minutes</span></div>
      <div class="conv"><b>1 hour</b><span>60 minutes · 3,600 seconds</span></div>
      <div class="conv"><b>1 minute</b><span>60 seconds · 60,000 ms</span></div>
      <div class="conv"><b>1 second</b><span>1,000 milliseconds</span></div>
    </div>
    <p><NuxtLink class="guide-teaser-all" to="/convert">Convert any time unit →</NuxtLink></p>
  </section>

  <!-- GUIDES teaser: surfaces the cluster + internal links from the home page -->
  <section class="wrap block" data-reveal>
    <span class="eyebrow">Guides</span>
    <h2>Step-by-step time-math guides</h2>
    <ul class="guide-teaser">
      <li v-for="g in GUIDES.slice(0, 4)" :key="g.slug">
        <NuxtLink :to="`/guides/${g.slug}`">{{ g.h1 }}</NuxtLink>
      </li>
    </ul>
    <p><NuxtLink class="guide-teaser-all" to="/guides">See all guides →</NuxtLink></p>
  </section>

  <!-- REVIEWS: real Google Play testimonials + AggregateRating schema -->
  <Testimonials :items="testimonials" :rating="rating" :play-url="playUrl" />

  <!-- FAQ -->
  <section id="faq" class="wrap block" data-reveal>
    <span class="eyebrow">FAQ</span>
    <h2>Frequently asked questions</h2>
    <div class="faq">
      <details v-for="(f, i) in faqs" :key="i" :open="i === 0" class="faq-item">
        <summary>{{ f.q }}</summary>
        <p>{{ f.a }}</p>
      </details>
    </div>
  </section>
</template>

<style scoped>
.block {
  padding: 3.4rem 0 0;
}
.block > h2 {
  margin-top: 0.5rem;
}
.answer {
  font-size: 1.08rem;
  color: var(--ink-soft);
  max-width: 68ch;
}

/* hero */
.hero {
  padding: clamp(2rem, 1rem + 4vw, 4.5rem) 0 1.5rem;
}
.hero-inner {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  gap: clamp(1.6rem, 1rem + 2.6vw, 2.6rem);
}
.hero-copy {
  max-width: 62ch;
}
.hero-copy h1 em {
  font-style: italic;
  color: var(--green-deep);
}
.lede {
  font-size: clamp(1.05rem, 1rem + 0.4vw, 1.2rem);
  color: var(--ink-soft);
  margin: 1.1rem auto 0;
  max-width: 52ch;
}
.lede code,
.hero-copy code {
  font-family: var(--font-mono);
  font-size: 0.86em;
  background: var(--paper-deep);
  padding: 0.12em 0.4em;
  border-radius: 6px;
  color: var(--olive);
}
.hero-cta {
  display: flex;
  gap: 0.8rem;
  flex-wrap: wrap;
  justify-content: center;
}
.store-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.65rem;
  padding: 0.7em 1.15em;
  border-radius: 13px;
  background: var(--ink);
  color: var(--paper);
  text-decoration: none;
  border: 1px solid var(--ink);
  transition: transform 0.18s, box-shadow 0.18s;
}
.store-badge:hover {
  transform: translateY(-2px);
  box-shadow: 0 14px 26px -16px rgba(0, 0, 0, 0.5);
  color: var(--paper);
}
.store-badge span {
  display: flex;
  flex-direction: column;
  font-weight: 600;
  font-size: 1.02rem;
  line-height: 1.1;
}
.store-badge small {
  font-weight: 400;
  font-size: 0.64rem;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  opacity: 0.7;
}
.hero-tool {
  width: 100%;
  max-width: 880px;
  text-align: left;
}

/* tables / reference */
.table-card {
  margin-top: 1.5rem;
  background: var(--card);
  border: 1px solid var(--card-edge);
  border-radius: var(--radius);
  overflow: hidden;
  box-shadow: var(--shadow-card);
}
.ref {
  width: 100%;
  border-collapse: collapse;
  font-size: 0.95rem;
}
.ref th,
.ref td {
  text-align: left;
  padding: 0.78em 1.1em;
  border-bottom: 1px solid var(--line);
}
.ref thead th {
  font-family: var(--font-mono);
  font-size: 0.68rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--ink-faint);
  background: var(--paper-deep);
}
.ref tbody tr:last-child td {
  border-bottom: 0;
}
.ref td:first-child {
  font-weight: 600;
  color: var(--ink);
}
.ref code {
  font-family: var(--font-mono);
  font-size: 0.82em;
  color: var(--olive);
}

.conv-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
  gap: 0.9rem;
  margin-top: 1.5rem;
}
.conv {
  background: var(--card);
  border: 1px solid var(--card-edge);
  border-radius: var(--radius-sm);
  padding: 1.1rem 1.2rem;
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
}
.conv b {
  font-family: var(--font-display);
  font-size: 1.3rem;
  color: var(--green-deep);
}
.conv span {
  font-family: var(--font-mono);
  font-size: 0.82rem;
  color: var(--ink-soft);
}
.guide-teaser {
  list-style: none;
  padding: 0;
  margin: 1.2rem 0 0.9rem;
  display: grid;
  gap: 0.55rem;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
}
.guide-teaser a {
  color: var(--green-deep);
  font-weight: 600;
  text-decoration: none;
}
.guide-teaser a:hover {
  text-decoration: underline;
}
.guide-teaser-all {
  font-weight: 600;
}


/* faq */
.faq {
  margin-top: 1.4rem;
  border-top: 1px solid var(--line);
}
.faq-item {
  border-bottom: 1px solid var(--line);
}
.faq-item summary {
  cursor: pointer;
  list-style: none;
  padding: 1.15rem 2.5rem 1.15rem 0;
  font-family: var(--font-display);
  font-weight: 600;
  font-size: 1.12rem;
  color: var(--ink);
  position: relative;
}
.faq-item summary::-webkit-details-marker {
  display: none;
}
.faq-item summary::after {
  content: "+";
  position: absolute;
  right: 0.3rem;
  top: 50%;
  transform: translateY(-50%);
  font-family: var(--font-mono);
  font-size: 1.5rem;
  color: var(--green);
  transition: transform 0.2s;
}
.faq-item[open] summary::after {
  content: "−";
}
.faq-item p {
  margin: 0 0 1.2rem;
  max-width: 70ch;
}
</style>
