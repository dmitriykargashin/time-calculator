<script setup lang="ts">
// /convert — a time-unit converter hub. Each conversion is a self-contained
// Q&A block (answer-first, FAQPage schema) and the result chip is the real
// engine output (see app/utils/conversions.ts, verified at build time).
const site = useSiteConfig()
const url = `${site.url}/convert`

useSeoMeta({
  title: CONVERT_META.metaTitle,
  description: CONVERT_META.metaDescription,
  ogTitle: CONVERT_META.h1,
  ogDescription: CONVERT_META.metaDescription,
  ogUrl: url,
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'FAQPage',
      '@id': `${url}#faq`,
      mainEntity: CONVERSIONS.map((c) => ({
        '@type': 'Question',
        name: c.question,
        acceptedAnswer: { '@type': 'Answer', text: `${c.answer} In the calculator, ${c.expr} returns ${c.result}.` },
      })),
    },
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
        { '@type': 'ListItem', position: 2, name: 'Convert', item: url },
      ],
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <article class="wrap convert">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">Convert</span>
    </nav>

    <span class="eyebrow">Converter</span>
    <h1>{{ CONVERT_META.h1 }}</h1>
    <p class="c-answer">{{ CONVERT_META.answer }}</p>
    <p class="c-intro">{{ CONVERT_META.intro }}</p>

    <h2>Convert it yourself</h2>
    <div class="c-tool">
      <TimeCalculator :initial-expr="CONVERSIONS[0]?.expr" :initial-format="CONVERSIONS[0]?.format" />
    </div>

    <h2>Common time conversions</h2>
    <div class="c-grid">
      <NuxtLink v-for="c in CONVERSIONS" :key="c.slug" :to="`/convert/${c.slug}`" class="c-card">
        <span class="c-pair">{{ c.from }} <span aria-hidden="true">→</span> {{ c.to }}</span>
        <h3>{{ c.question }}</h3>
        <p>{{ c.answer }}</p>
        <div class="c-ex-line">
          <code class="c-expr">{{ c.expr }}</code>
          <span class="c-eq">=</span>
          <code class="c-res">{{ c.result }}</code>
        </div>
        <span class="c-go">Full table &amp; calculator <span class="c-arrow">→</span></span>
      </NuxtLink>
    </div>

    <nav class="c-related" aria-label="Related">
      <h2>Keep going</h2>
      <ul>
        <li><NuxtLink to="/guides/convert-time-units">Convert between any two time units</NuxtLink></li>
        <li><NuxtLink to="/guides/convert-time-to-decimal">Convert time to decimal hours</NuxtLink></li>
        <li><NuxtLink to="/guides">All time-math guides</NuxtLink></li>
      </ul>
    </nav>

    <p class="c-back"><NuxtLink to="/">← Back to the calculator</NuxtLink></p>
  </article>
</template>

<style scoped>
.convert { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.convert h1 { max-width: 20ch; }
.c-answer { font-size: 1.16rem; line-height: 1.6; color: var(--ink); max-width: 64ch; margin: 1rem 0 1.1rem; font-weight: 500; }
.c-intro { max-width: 64ch; }
.convert h2 { margin-top: 2.6rem; }
.c-tool { margin: 1rem 0; }
.c-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1rem; margin: 1rem 0; }
.c-card { display: flex; flex-direction: column; gap: 0.5rem; background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); padding: 1.3rem; box-shadow: var(--shadow-card); text-decoration: none; color: inherit; transition: transform 0.18s var(--ease-pop), box-shadow 0.18s, border-color 0.18s; }
.c-card:hover { transform: translateY(-2px); border-color: var(--line-strong); box-shadow: var(--shadow-card), 0 14px 30px -20px rgba(28, 27, 21, 0.3); }
.c-go { font-weight: 600; font-size: 0.86rem; color: var(--green-deep); }
.c-arrow { display: inline-block; transition: transform 0.2s var(--ease-pop); }
.c-card:hover .c-arrow { transform: translateX(4px); }
.c-pair { font-family: var(--font-mono); font-size: 0.66rem; letter-spacing: 0.14em; text-transform: uppercase; color: var(--olive); }
.c-card h3 { margin: 0; font-size: 1.04rem; color: var(--ink); }
.c-card p { margin: 0; font-size: 0.9rem; color: var(--ink-soft); max-width: none; }
.c-ex-line { margin-top: auto; display: flex; align-items: baseline; gap: 0.5rem; flex-wrap: wrap; font-family: var(--font-app); font-size: 1rem; background: var(--app-display); border: 1px solid var(--card-edge); border-radius: var(--radius-sm); padding: 0.55rem 0.75rem; }
.c-expr { color: var(--app-num); background: none; padding: 0; }
.c-eq { color: var(--ink-faint); }
.c-res { color: var(--app-res-unit); font-weight: 700; background: none; padding: 0; }
.c-related { margin-top: 2.6rem; }
.c-related ul { list-style: none; padding: 0; display: grid; gap: 0.5rem; }
.c-related a { color: var(--green-deep); font-weight: 600; text-decoration: none; }
.c-related a:hover { text-decoration: underline; }
.c-back { margin-top: 2rem; }
.c-back a { color: var(--ink-soft); text-decoration: none; font-weight: 500; }
.c-back a:hover { color: var(--green-deep); }
</style>
