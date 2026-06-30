<script setup lang="ts">
// /convert/[pair] — one landing page per conversion pair (e.g. minutes-to-hours).
// Data + the engine-verified value table come from app/utils/conversions.ts.
const slug = String(useRoute().params.pair)
const c = getConversion(slug)
if (!c) throw createError({ statusCode: 404, statusMessage: 'Conversion not found', fatal: true })

const site = useSiteConfig()
const url = `${site.url}/convert/${slug}`
const inverse = c.inverse ? getConversion(c.inverse) : undefined

useSeoMeta({
  title: c.metaTitle,
  description: c.metaDescription,
  ogTitle: c.h1,
  ogDescription: c.metaDescription,
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
      mainEntity: [
        { '@type': 'Question', name: c.question, acceptedAnswer: { '@type': 'Answer', text: `${c.answer} In the calculator, ${c.expr} returns ${c.result}.` } },
        ...c.faqs.map((f) => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })),
      ],
    },
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
        { '@type': 'ListItem', position: 2, name: 'Convert', item: `${site.url}/convert` },
        { '@type': 'ListItem', position: 3, name: c.h1, item: url },
      ],
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <article class="wrap pair">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <NuxtLink to="/convert">Convert</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">{{ c.from }} to {{ c.to }}</span>
    </nav>

    <span class="eyebrow">{{ c.from }} <span aria-hidden="true">→</span> {{ c.to }}</span>
    <h1>{{ c.h1 }}</h1>
    <p class="p-answer">{{ c.answer }}</p>
    <p class="p-intro">{{ c.intro }}</p>

    <p class="p-formula"><span class="p-formula-tag">Formula</span>{{ c.formula }}</p>

    <h2>Convert {{ c.from.toLowerCase() }} to {{ c.to.toLowerCase() }}</h2>
    <div class="p-tool">
      <TimeCalculator :initial-expr="c.expr" :initial-format="c.format" />
    </div>

    <h2>{{ c.from }} to {{ c.to }} conversion table</h2>
    <div class="p-table-card">
      <table class="p-table">
        <thead>
          <tr><th>{{ c.from }}</th><th>{{ c.to }}</th></tr>
        </thead>
        <tbody>
          <tr v-for="(row, i) in c.table" :key="i">
            <td>{{ row.label }}</td>
            <td class="p-res">{{ row.result }}</td>
          </tr>
        </tbody>
      </table>
    </div>

    <section v-if="c.faqs.length" class="p-faq">
      <h2>Common questions</h2>
      <details v-for="(f, i) in c.faqs" :key="i" class="faq-item" :open="i === 0">
        <summary>{{ f.q }}</summary>
        <p>{{ f.a }}</p>
      </details>
    </section>

    <nav class="p-related" aria-label="Related conversions">
      <h2>Related conversions</h2>
      <ul>
        <li v-if="inverse"><NuxtLink :to="`/convert/${inverse.slug}`">{{ inverse.h1 }}</NuxtLink></li>
        <li><NuxtLink to="/convert">All time unit conversions</NuxtLink></li>
        <li><NuxtLink to="/guides/convert-time-units">Guide: convert between any two units</NuxtLink></li>
        <li><NuxtLink to="/guides/convert-time-to-decimal">Guide: convert time to decimal hours</NuxtLink></li>
      </ul>
    </nav>

    <p class="p-back"><NuxtLink to="/convert">← All conversions</NuxtLink></p>
  </article>
</template>

<style scoped>
.pair { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.pair h1 { max-width: 18ch; }
.p-answer { font-size: 1.16rem; line-height: 1.6; color: var(--ink); max-width: 64ch; margin: 1rem 0 1.1rem; font-weight: 500; }
.p-intro { max-width: 64ch; }
.pair h2 { margin-top: 2.6rem; }
.p-formula { display: flex; align-items: baseline; gap: 0.7rem; flex-wrap: wrap; margin: 1.4rem 0 0; padding: 0.85rem 1.05rem; background: var(--app-display); border: 1px solid var(--card-edge); border-radius: var(--radius-sm); font-family: var(--font-app); color: var(--ink); max-width: 64ch; }
.p-formula-tag { font-family: var(--font-mono); font-size: 0.6rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--olive); }
.p-tool { margin: 1rem 0; }
.p-table-card { border: 1px solid var(--card-edge); border-radius: var(--radius); overflow: hidden; box-shadow: var(--shadow-card); margin: 1rem 0; max-width: 30rem; }
.p-table { width: 100%; border-collapse: collapse; font-family: var(--font-app); }
.p-table th { text-align: left; font-family: var(--font-display); font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.06em; color: var(--ink-soft); background: var(--card); padding: 0.65rem 1rem; border-bottom: 1px solid var(--card-edge); }
.p-table td { padding: 0.55rem 1rem; border-bottom: 1px solid var(--line); color: var(--app-num); }
.p-table tr:last-child td { border-bottom: 0; }
.p-table .p-res { color: var(--app-res-unit); font-weight: 700; }
.p-faq { margin-top: 2.6rem; }
.faq-item { border-top: 1px solid var(--line); }
.faq-item summary { cursor: pointer; font-weight: 600; font-family: var(--font-display); padding: 0.7rem 0; list-style: none; }
.faq-item summary::-webkit-details-marker { display: none; }
.faq-item p { margin: 0 0 0.7rem; max-width: 64ch; }
.p-related { margin-top: 2.6rem; }
.p-related ul { list-style: none; padding: 0; display: grid; gap: 0.5rem; }
.p-related a { color: var(--green-deep); font-weight: 600; text-decoration: none; }
.p-related a:hover { text-decoration: underline; }
.p-back { margin-top: 2rem; }
.p-back a { color: var(--ink-soft); text-decoration: none; font-weight: 500; }
.p-back a:hover { color: var(--green-deep); }
</style>
