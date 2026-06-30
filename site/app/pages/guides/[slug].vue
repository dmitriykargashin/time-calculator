<script setup lang="ts">
// Each prerendered page has a fixed slug, so this can be non-reactive.
const slug = String(useRoute().params.slug)
const guide = getGuide(slug)
if (!guide) throw createError({ statusCode: 404, statusMessage: 'Guide not found', fatal: true })

const site = useSiteConfig()
const url = `${site.url}/guides/${slug}`
const related = relatedGuides(slug)

useSeoMeta({
  title: guide.metaTitle,
  description: guide.metaDescription,
  ogTitle: guide.h1,
  ogDescription: guide.metaDescription,
  ogUrl: url,
  ogType: 'article',
  ogImage: `${site.url}/og.png`,
  twitterCard: 'summary_large_image',
  twitterImage: `${site.url}/og.png`,
})

const jsonLd = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'HowTo',
      '@id': `${url}#howto`,
      name: guide.h1,
      description: guide.answer,
      dateModified: GUIDE_UPDATED,
      publisher: { '@type': 'Organization', name: 'Cardamon', url: 'https://www.cardamon.org' },
      step: guide.steps.map((s, i) => ({ '@type': 'HowToStep', position: i + 1, name: s.title, text: s.body })),
    },
    {
      '@type': 'FAQPage',
      '@id': `${url}#faq`,
      mainEntity: guide.faqs.map((f) => ({ '@type': 'Question', name: f.q, acceptedAnswer: { '@type': 'Answer', text: f.a } })),
    },
    {
      '@type': 'BreadcrumbList',
      itemListElement: [
        { '@type': 'ListItem', position: 1, name: 'Home', item: site.url },
        { '@type': 'ListItem', position: 2, name: 'Guides', item: `${site.url}/guides` },
        { '@type': 'ListItem', position: 3, name: guide.h1, item: url },
      ],
    },
  ],
}
useHead({ script: [{ type: 'application/ld+json', innerHTML: JSON.stringify(jsonLd) }] })
</script>

<template>
  <article class="wrap guide">
    <nav class="crumbs" aria-label="Breadcrumb">
      <NuxtLink to="/">Home</NuxtLink>
      <span aria-hidden="true">/</span>
      <NuxtLink to="/guides">Guides</NuxtLink>
      <span aria-hidden="true">/</span>
      <span aria-current="page">{{ guide.h1 }}</span>
    </nav>

    <h1>{{ guide.h1 }}</h1>
    <p class="g-answer">{{ guide.answer }}</p>
    <p class="g-intro">{{ guide.intro }}</p>

    <h2>Step by step</h2>
    <ol class="g-steps">
      <li v-for="(s, i) in guide.steps" :key="i">
        <h3>{{ s.title }}</h3>
        <p>{{ s.body }}</p>
      </li>
    </ol>

    <h2>Worked examples</h2>
    <div class="g-examples">
      <div v-for="(ex, i) in guide.examples" :key="i" class="g-ex">
        <div class="g-ex-line">
          <code class="g-expr">{{ ex.expr }}</code>
          <span class="g-eq">=</span>
          <code class="g-res">{{ ex.result }}</code>
        </div>
        <p class="g-note">{{ ex.note }}</p>
      </div>
    </div>

    <h2>Try it yourself</h2>
    <div class="g-tool">
      <TimeCalculator :initial-expr="guide.examples[0]?.expr" :initial-format="guide.examples[0]?.format" />
    </div>

    <section class="g-faq">
      <h2>Common questions</h2>
      <details v-for="(f, i) in guide.faqs" :key="i" class="faq-item" :open="i === 0">
        <summary>{{ f.q }}</summary>
        <p>{{ f.a }}</p>
      </details>
    </section>

    <p class="g-usecase">{{ guide.useCaseLine }}</p>

    <nav v-if="related.length" class="g-related" aria-label="Related guides">
      <h2>Related guides</h2>
      <ul>
        <li v-for="r in related" :key="r.slug">
          <NuxtLink :to="`/guides/${r.slug}`">{{ r.h1 }}</NuxtLink>
        </li>
      </ul>
    </nav>

    <p class="g-back"><NuxtLink to="/">← Back to the calculator</NuxtLink></p>
  </article>
</template>

<style scoped>
.guide { padding: 2.2rem 0 1rem; }
.crumbs { display: flex; gap: 0.5rem; align-items: center; font-size: 0.82rem; color: var(--ink-faint); margin-bottom: 1.3rem; flex-wrap: wrap; }
.crumbs a { color: var(--ink-soft); text-decoration: none; }
.crumbs a:hover { color: var(--green-deep); }
.guide h1 { max-width: 20ch; }
.g-answer { font-size: 1.16rem; line-height: 1.6; color: var(--ink); max-width: 64ch; margin: 1rem 0 1.1rem; font-weight: 500; }
.g-intro { max-width: 64ch; }
.guide h2 { margin-top: 2.6rem; }
.g-steps { list-style: none; counter-reset: step; padding: 0; margin: 1rem 0; display: grid; gap: 0.85rem; }
.g-steps li { counter-increment: step; position: relative; padding: 1rem 1.1rem 1rem 3.2rem; background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius-sm); }
.g-steps li::before { content: counter(step); position: absolute; left: 1rem; top: 1rem; width: 1.7rem; height: 1.7rem; display: grid; place-items: center; border-radius: 50%; background: var(--green); color: var(--on-green); font-family: var(--font-mono); font-size: 0.82rem; font-weight: 700; }
.g-steps h3 { margin: 0 0 0.25rem; font-size: 1.02rem; }
.g-steps p { margin: 0; font-size: 0.94rem; max-width: none; }
.g-examples { display: grid; gap: 0.7rem; margin: 1rem 0; }
.g-ex { background: var(--app-display); border: 1px solid var(--card-edge); border-radius: var(--radius-sm); padding: 0.8rem 1rem; }
.g-ex-line { display: flex; align-items: baseline; gap: 0.6rem; flex-wrap: wrap; font-family: var(--font-app); font-size: 1.05rem; }
.g-expr { color: var(--app-num); background: none; padding: 0; }
.g-eq { color: var(--ink-faint); }
.g-res { color: var(--app-res-unit); font-weight: 700; background: none; padding: 0; }
.g-note { margin: 0.4rem 0 0; font-size: 0.85rem; color: var(--ink-faint); max-width: none; }
.g-tool { margin: 1rem 0; }
.g-faq { margin-top: 2.6rem; }
.faq-item { border-top: 1px solid var(--line); }
.faq-item summary { cursor: pointer; font-weight: 600; font-family: var(--font-display); padding: 0.7rem 0; list-style: none; }
.faq-item summary::-webkit-details-marker { display: none; }
.faq-item p { margin: 0 0 0.7rem; max-width: 64ch; }
.g-usecase { margin-top: 2rem; font-size: 0.95rem; color: var(--ink-soft); border-left: 3px solid var(--olive); padding-left: 1rem; font-style: italic; max-width: 60ch; }
.g-related { margin-top: 2.4rem; }
.g-related ul { list-style: none; padding: 0; display: grid; gap: 0.5rem; }
.g-related a { color: var(--green-deep); font-weight: 600; text-decoration: none; }
.g-related a:hover { text-decoration: underline; }
.g-back { margin-top: 2rem; }
.g-back a { color: var(--ink-soft); text-decoration: none; font-weight: 500; }
.g-back a:hover { color: var(--green-deep); }
</style>
