<script setup lang="ts">
const site = useSiteConfig()

const faqs = [
  {
    q: 'How do I add or subtract hours and minutes?',
    a: 'Type the durations on one line with + or -, for example 5h 30m + 2h 15m or 40h - 6h 30m, then read the total. Use full words or shorthand (h, m, d, w).',
  },
  {
    q: 'Can I multiply or divide a duration?',
    a: 'Yes. Type * to multiply and / to divide, for example 90m * 3 or 3d 4h / 2. On a keyboard the operators are + - * /. The mobile app also has × and ÷ keys on its keypad.',
  },
  {
    q: 'How do I convert hours to minutes or decimal hours?',
    a: 'Open Convert to see the result in every unit from years down to milliseconds, or pick a format from "Show result as", including decimal hours and clock styles like H:MM:SS.',
  },
  {
    q: 'How do I calculate a time difference?',
    a: 'Subtract one duration from another, for example 40h - 6h 30m, and the calculator shows the remaining time.',
  },
  {
    q: 'Is my data private?',
    a: 'Yes. The calculator runs on your device. It makes no network calls and collects no personal data. Your calculation history stays in your browser or on your phone.',
  },
  {
    q: 'Is Time Calculator free?',
    a: 'Yes. The web calculator and the Chrome extension are free. The Android app is free on Google Play. On iOS the app is free to download, and a one-time Pro purchase unlocks the rate calculator, every result format, the custom keypad, and unlimited history.',
  },
  {
    q: 'Where can I get the app or the browser extension?',
    a: 'Get it on Google Play or the App Store, use it on the web at timecalculator.app, or add the Chrome extension to calculate time in your browser side panel.',
  },
  {
    q: 'How do I report a bug or request a feature?',
    a: 'Email support@cardamon.org with what you tried and what you expected. Screenshots help. We read every message.',
  },
]

useSeoMeta({
  title: 'Time Calculator Support: Help and FAQ',
  description:
    'Get help with Time Calculator: how to add, subtract, multiply, divide and convert time, plus privacy, pricing, and how to reach support at support@cardamon.org.',
  ogTitle: 'Time Calculator support',
  ogUrl: `${site.url}/support`,
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = [
  {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
      { '@type': 'ListItem', position: 2, name: 'Support', item: `${site.url}/support` },
    ],
  },
  {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((f) => ({
      '@type': 'Question',
      name: f.q,
      acceptedAnswer: { '@type': 'Answer', text: f.a },
    })),
  },
]
useHead({ script: jsonLd.map((j) => ({ type: 'application/ld+json', innerHTML: JSON.stringify(j) })) })
</script>

<template>
  <section class="wrap support">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">Support</span>
    </nav>

    <h1>Support</h1>
    <p class="sup-lead">
      Need a hand with Time Calculator? Email us and we read every message. The
      answers below cover the questions we get most.
    </p>

    <div class="sup-contact">
      <div class="sup-contact-row">
        <span class="sup-k">Email</span>
        <a href="mailto:support@cardamon.org">support@cardamon.org</a>
      </div>
      <p class="sup-note">
        Tell us what you tried and what you expected, and add a screenshot if you can.
      </p>
    </div>

    <h2 class="sup-h2">Common questions</h2>
    <div class="sup-faq">
      <article v-for="(f, i) in faqs" :key="i" class="sup-item">
        <h3>{{ f.q }}</h3>
        <p>{{ f.a }}</p>
      </article>
    </div>

    <p class="sup-back">
      <NuxtLink to="/app">Get the app</NuxtLink>,
      <NuxtLink to="/">use the web calculator</NuxtLink>, or
      <a href="https://chromewebstore.google.com/detail/time-calculator-cardamon/apgmodigokbblokbgfokpobmlcmijjpl" target="_blank" rel="noopener">add the Chrome extension</a>.
    </p>
  </section>
</template>

<style scoped>
.support { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.sup-lead { max-width: 60ch; font-size: 1.08rem; margin-bottom: 1.8rem; }
.sup-contact { background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); padding: 1.3rem 1.5rem; box-shadow: var(--shadow-card); margin-bottom: 2.4rem; }
.sup-contact-row { display: flex; align-items: baseline; gap: 0.9rem; flex-wrap: wrap; }
.sup-k { font-family: var(--font-mono); font-size: 0.68rem; letter-spacing: 0.12em; text-transform: uppercase; color: var(--on-green); background: var(--green); padding: 0.28em 0.75em; border-radius: 999px; }
.sup-contact-row a { font-size: 1.16rem; font-weight: 700; color: var(--green-deep); text-decoration: none; }
.sup-contact-row a:hover { text-decoration: underline; }
.sup-note { margin: 0.75rem 0 0; font-size: 0.94rem; color: var(--ink-soft); }
.sup-h2 { font-size: 1.25rem; margin: 0 0 1rem; }
.sup-faq { display: grid; gap: 0.9rem; }
.sup-item { background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); padding: 1.15rem 1.4rem; }
.sup-item h3 { margin: 0 0 0.4rem; font-size: 1.04rem; }
.sup-item p { margin: 0; color: var(--ink-soft); line-height: 1.55; }
.sup-back { margin-top: 2.4rem; font-size: 0.98rem; }
.sup-back a { font-weight: 600; }
</style>
