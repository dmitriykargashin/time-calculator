<script setup lang="ts">
const site = useSiteConfig()

useSeoMeta({
  title: 'Time Calculator Guides: Add, Subtract & Convert Time',
  description:
    'Step-by-step guides for adding hours and minutes, totalling timesheets, splitting durations, and converting time units, each with worked examples you can run.',
  ogTitle: 'Time Calculator guides',
  ogUrl: `${site.url}/guides`,
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
        { '@type': 'ListItem', position: 2, name: 'Guides', item: `${site.url}/guides` },
      ],
    },
    {
      '@type': 'ItemList',
      '@id': `${site.url}/guides#list`,
      itemListElement: GUIDES.map((g, i) => ({
        '@type': 'ListItem',
        position: i + 1,
        name: g.h1,
        url: `${site.url}/guides/${g.slug}`,
      })),
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <section class="wrap guides-hub">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">Guides</span>
    </nav>
    <span class="eyebrow">Guides</span>
    <h1>Time calculator guides</h1>
    <p class="hub-lead">
      Short, practical walk-throughs for the most common time-math jobs. Every guide leads
      with a direct answer, then shows worked examples you can run right here in the browser.
    </p>

    <div class="hub-grid">
      <NuxtLink v-for="(g, i) in GUIDES" :key="g.slug" :to="`/guides/${g.slug}`" class="hub-card">
        <span class="hub-num">Guide {{ String(i + 1).padStart(2, '0') }}</span>
        <h2>{{ g.h1 }}</h2>
        <p>{{ g.metaDescription }}</p>
        <span class="hub-go">Read the guide <span class="hub-arrow">→</span></span>
      </NuxtLink>
    </div>
  </section>
</template>

<style scoped>
.guides-hub { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.hub-lead { max-width: 60ch; font-size: 1.08rem; margin-bottom: 2rem; }
.hub-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(290px, 1fr)); gap: 1rem; }
.hub-card { display: flex; flex-direction: column; gap: 0.5rem; background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); padding: 1.4rem; text-decoration: none; box-shadow: var(--shadow-card); transition: transform 0.18s var(--ease-pop), box-shadow 0.18s, border-color 0.18s; }
.hub-card:hover { transform: translateY(-2px); border-color: var(--line-strong); box-shadow: var(--shadow-card), 0 14px 30px -20px rgba(28, 27, 21, 0.3); }
.hub-card h2 { font-size: 1.12rem; margin: 0; color: var(--ink); }
.hub-card p { margin: 0; font-size: 0.92rem; color: var(--ink-soft); }
.hub-num { font-family: var(--font-mono); font-size: 0.66rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--olive); }
.hub-go { margin-top: auto; font-weight: 600; font-size: 0.9rem; color: var(--green-deep); }
.hub-arrow { display: inline-block; transition: transform 0.2s var(--ease-pop); }
.hub-card:hover .hub-arrow { transform: translateX(4px); }
</style>
