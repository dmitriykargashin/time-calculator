<script setup lang="ts">
import { REVIEWS, REVIEW_RATING } from '~/utils/reviews'

const site = useSiteConfig()
const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'

useSeoMeta({
  title: 'Time Calculator Reviews: 4.6★ from 391 Ratings',
  description:
    'Real Google Play reviews of Time Calculator Cardamon. See what people say about adding, subtracting, and converting time, from work timesheets to audio editing.',
  ogTitle: 'Time Calculator reviews',
  ogDescription: 'What people say about Time Calculator Cardamon: 4.6 stars from 391 ratings on Google Play.',
  ogUrl: `${site.url}/reviews`,
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
        { '@type': 'ListItem', position: 2, name: 'Reviews', item: `${site.url}/reviews` },
      ],
    },
    {
      '@type': ['WebApplication', 'SoftwareApplication'],
      '@id': `${site.url}/#app`,
      name: 'Time Calculator Cardamon',
      applicationCategory: 'UtilitiesApplication',
      operatingSystem: 'Web, Android, iOS',
      url: site.url,
      offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
      aggregateRating: {
        '@type': 'AggregateRating',
        ratingValue: String(REVIEW_RATING.value),
        ratingCount: REVIEW_RATING.count,
        reviewCount: REVIEW_RATING.written,
        bestRating: '5',
        worstRating: '1',
      },
      review: REVIEWS.map((r) => ({
        '@type': 'Review',
        reviewRating: { '@type': 'Rating', ratingValue: r.stars, bestRating: 5 },
        author: { '@type': 'Person', name: r.name },
        reviewBody: r.text,
      })),
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <section class="wrap reviews-page">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">Reviews</span>
    </nav>

    <span class="eyebrow">Reviews</span>
    <h1>What people say about Time Calculator</h1>
    <div class="rp-summary">
      <span class="rp-score">{{ REVIEW_RATING.value.toFixed(1) }}</span>
      <span class="rp-stars" aria-hidden="true">★★★★★</span>
      <span class="rp-meta">
        from {{ REVIEW_RATING.count.toLocaleString() }} ratings on
        <a :href="playUrl" target="_blank" rel="noopener">Google&nbsp;Play</a>
      </span>
    </div>

    <div class="rp-wall">
      <figure v-for="(r, i) in REVIEWS" :key="i" class="rp-card">
        <div class="rp-cstars" :aria-label="`${r.stars} out of 5 stars`">{{ '★'.repeat(r.stars) }}</div>
        <blockquote>{{ r.text }}</blockquote>
        <figcaption><span class="rp-name">{{ r.name }}</span><span class="rp-date">{{ r.date }}</span></figcaption>
      </figure>
    </div>

    <p class="rp-cta">
      <a :href="playUrl" target="_blank" rel="noopener">Read more on Google&nbsp;Play →</a>
    </p>
  </section>
</template>

<style scoped>
.reviews-page { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.reviews-page h1 { max-width: 18ch; }
.rp-summary { display: flex; align-items: center; gap: 0.7rem; flex-wrap: wrap; margin: 0.6rem 0 2rem; }
.rp-score { font-family: var(--font-display); font-weight: 700; font-size: 2.1rem; line-height: 1; color: var(--ink); }
.rp-stars { color: var(--ochre); letter-spacing: 0.1em; }
.rp-meta { font-size: 0.95rem; color: var(--ink-soft); }
.rp-wall { columns: 3 280px; column-gap: 1rem; }
.rp-card { break-inside: avoid; width: 100%; margin: 0 0 1rem; padding: 1.05rem 1.15rem; background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); box-shadow: var(--shadow-card); }
.rp-cstars { color: var(--ochre); font-size: 0.85rem; letter-spacing: 0.08em; margin-bottom: 0.4rem; }
.rp-card blockquote { margin: 0; font-size: 0.95rem; line-height: 1.55; color: var(--ink); }
.rp-card figcaption { margin-top: 0.7rem; display: flex; align-items: baseline; justify-content: space-between; gap: 0.6rem; }
.rp-name { font-weight: 600; font-size: 0.86rem; color: var(--ink-soft); }
.rp-date { font-family: var(--font-mono); font-size: 0.68rem; color: var(--ink-faint); white-space: nowrap; }
.rp-cta { margin-top: 1.6rem; }
.rp-cta a { font-weight: 600; }
</style>
