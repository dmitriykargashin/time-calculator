<script setup lang="ts">
const site = useSiteConfig()

const releases = [
  {
    version: '2.4.0',
    title: 'Customisable keypad, saved history, and quick result actions',
    items: [
      'Customisable keypad: choose which time-unit keys appear with one-tap presets (Standard, Stopwatch, Media, Hours & minutes, Calendar, Everything) and a live preview, in Settings → Keypad keys.',
      'Calculation history: results are saved on your device. Add a note and tap an entry to reopen it in the format it was saved with.',
      'Tap a result for quick actions (copy, change format, rate, share); long-press to select text.',
      'Redesigned rate (“Per”) calculator for clarity, plus new result formats including milliseconds and Hour·Minute·Second·Msec.',
      'Smoother resizing as you drag the display and keypad split, with dark-theme divider and accessibility fixes.',
    ],
  },
  {
    version: 'Earlier releases',
    title: 'The foundation',
    items: [
      'The shared calculation engine: add, subtract, multiply, and divide durations from years down to milliseconds.',
      'Multiple result formats so the same total reads as hours, days, minutes, or a full breakdown.',
      'The rate calculator for working out an amount per time interval.',
    ],
  },
]

useSeoMeta({
  title: "What's New in Time Calculator: Release Notes",
  description:
    'Release notes for the Time Calculator app: a customisable keypad, saved calculation history, quick result actions, more result formats, and ongoing polish.',
  ogTitle: "What's new in Time Calculator",
  ogUrl: `${site.url}/whats-new`,
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
    { '@type': 'ListItem', position: 2, name: "What's new", item: `${site.url}/whats-new` },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <section class="wrap whatsnew">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">What's new</span>
    </nav>

    <span class="eyebrow">What's new</span>
    <h1>Release notes</h1>
    <p class="wn-lead">
      What changed in the Time Calculator app. The web version shares the same calculation
      engine, so improvements to the math land in both.
    </p>

    <div class="wn-list">
      <article v-for="(r, i) in releases" :key="i" class="wn-rel">
        <div class="wn-head">
          <span class="wn-ver">{{ r.version }}</span>
          <h2>{{ r.title }}</h2>
        </div>
        <ul>
          <li v-for="(item, j) in r.items" :key="j">{{ item }}</li>
        </ul>
      </article>
    </div>

    <p class="wn-back">
      <NuxtLink to="/app">Get the app</NuxtLink> or <NuxtLink to="/">use the web calculator</NuxtLink>.
    </p>
  </section>
</template>

<style scoped>
.whatsnew { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.wn-lead { max-width: 60ch; font-size: 1.08rem; margin-bottom: 2rem; }
.wn-list { display: grid; gap: 1.2rem; }
.wn-rel { background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); padding: 1.4rem 1.5rem; box-shadow: var(--shadow-card); }
.wn-head { display: flex; align-items: baseline; gap: 0.8rem; flex-wrap: wrap; margin-bottom: 0.6rem; }
.wn-ver { font-family: var(--font-mono); font-size: 0.72rem; letter-spacing: 0.1em; text-transform: uppercase; color: var(--on-green); background: var(--green); padding: 0.25em 0.7em; border-radius: 999px; white-space: nowrap; }
.wn-head h2 { margin: 0; font-size: 1.12rem; }
.wn-rel ul { margin: 0; padding-left: 1.1rem; }
.wn-rel li { margin: 0.45rem 0; color: var(--ink-soft); }
.wn-rel li::marker { color: var(--green); }
.wn-back { margin-top: 2.4rem; font-size: 0.98rem; }
.wn-back a { font-weight: 600; }
</style>
