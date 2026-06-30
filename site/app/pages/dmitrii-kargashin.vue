<script setup lang="ts">
import { AUTHOR, personNode } from '~/utils/author'

const site = useSiteConfig()
const url = `${site.url}/dmitrii-kargashin`

useSeoMeta({
  title: 'About Dmitrii Kargashin, maker of Time Calculator',
  description:
    'Time Calculator is built by Dmitrii Kargashin, solo founder of Cardamon Inc. He builds and ships full-stack products end to end and wrote the engine behind the web and mobile apps.',
  ogTitle: 'Dmitrii Kargashin — maker of Time Calculator',
  ogDescription: AUTHOR.tagline,
  ogUrl: url,
  ogType: 'profile',
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'ProfilePage',
      '@id': `${url}#profilepage`,
      url,
      name: 'About Dmitrii Kargashin',
      mainEntity: { '@id': `${site.url}/#person` },
    },
    personNode(site.url),
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
        { '@type': 'ListItem', position: 2, name: 'Dmitrii Kargashin', item: url },
      ],
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })

const playUrl =
  'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
</script>

<template>
  <article class="wrap about">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">Dmitrii Kargashin</span>
    </nav>

    <header class="about-head">
      <img class="about-av" :src="AUTHOR.photo" :alt="AUTHOR.name" width="74" height="74" />
      <div>
        <h1>{{ AUTHOR.name }}</h1>
        <p class="about-title">{{ AUTHOR.jobTitle }}</p>
      </div>
    </header>

    <p class="about-lead">{{ AUTHOR.bio }}</p>

    <h2>What Dmitrii builds</h2>
    <p>
      Everything ships under his Cardamon brand. Time Calculator is the calculator you are using
      now, on the web and in the Android and iOS apps. He also builds:
    </p>
    <ul class="about-links">
      <li v-for="p in AUTHOR.projects" :key="p.url">
        <a :href="p.url" target="_blank" rel="noopener">{{ p.name }}</a> — {{ p.desc }}.
      </li>
    </ul>

    <h2>Before Cardamon</h2>
    <p>
      Dmitrii did not start out solo. He spent years in enterprise engineering, where he led and
      mentored several development teams and built core modules for a high-load product and
      workflow system used by thousands of people, with an estimated commercial value in the tens
      of millions of dollars. He automated dozens of business processes, cut a document approval
      cycle by roughly ten times, and helped reshape how whole departments worked.
    </p>

    <h2>Why Time Calculator exists</h2>
    <p>
      Most time calculators make you convert everything to minutes first. Dmitrii built Time
      Calculator so you can type a duration the way you say it, like
      <code>5h 30m + 2h 15m</code>, and read the answer straight off. The same calculation engine
      runs here in the browser and inside the Android and iOS apps, so the numbers always match,
      down to the millisecond.
    </p>

    <h2>Find Dmitrii elsewhere</h2>
    <ul class="about-links">
      <li>
        <a :href="AUTHOR.linkedin" target="_blank" rel="noopener">LinkedIn</a>
        — work history and what he is building now.
      </li>
      <li>
        <a :href="AUTHOR.github" target="_blank" rel="noopener">GitHub</a>
        — code and projects.
      </li>
      <li>
        <a :href="playUrl" target="_blank" rel="noopener">Time Calculator on Google Play</a>
        — the Android app.
      </li>
      <li>
        <a href="https://www.cardamon.org" target="_blank" rel="noopener">Cardamon Inc</a>
        — the studio behind the app.
      </li>
    </ul>

    <h2>Written by Dmitrii</h2>
    <p>
      He writes and maintains every guide on this site.
      <NuxtLink to="/guides">Read the time-math guides</NuxtLink> or
      <NuxtLink to="/convert">browse the unit converter</NuxtLink>.
    </p>

    <p class="about-back"><NuxtLink to="/">← Back to the calculator</NuxtLink></p>
  </article>
</template>

<style scoped>
.about { padding: 2.2rem 0 1rem; max-width: 760px; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.about-head { display: flex; gap: 1.2rem; align-items: center; }
.about-av { flex: none; width: 4.6rem; height: 4.6rem; border-radius: 50%; object-fit: cover; background: var(--green); }
.about h1 { margin: 0.2rem 0 0; }
.about-title { margin: 0.2rem 0 0; color: var(--ink-faint); }
.about-lead { font-size: 1.16rem; line-height: 1.6; color: var(--ink); margin: 1.4rem 0 1.1rem; font-weight: 500; }
.about h2 { margin-top: 2.4rem; }
.about p { max-width: 64ch; }
.about code { font-family: var(--font-app); }
.about-links { list-style: none; padding: 0; display: grid; gap: 0.6rem; max-width: 64ch; }
.about-links a { color: var(--green-deep); font-weight: 600; text-decoration: none; }
.about-links a:hover { text-decoration: underline; }
.about-back { margin-top: 2.4rem; }
.about-back a { color: var(--ink-soft); text-decoration: none; font-weight: 500; }
.about-back a:hover { color: var(--green-deep); }
</style>
