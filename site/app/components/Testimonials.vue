<script setup lang="ts">
defineProps<{
  items: { name: string; stars: number; use?: string; text: string }[]
  rating: { value: number; count: number }
  playUrl: string
}>()
</script>

<template>
  <section id="reviews" class="wrap block reviews" data-reveal>
    <span class="eyebrow">Reviews</span>
    <h2>Loved on Google&nbsp;Play</h2>

    <div class="rating-summary">
      <span class="rs-score">{{ rating.value.toFixed(1) }}</span>
      <span class="rs-stars" aria-hidden="true">
        <svg v-for="n in 5" :key="n" viewBox="0 0 24 24" width="20" height="20"><path fill="currentColor" d="M12 2l2.9 6.3 6.9.6-5.2 4.6 1.6 6.8L12 17.3 5.8 20.9l1.6-6.8L2.2 8.9l6.9-.6z"/></svg>
      </span>
      <span class="rs-meta">
        from {{ rating.count.toLocaleString() }} ratings on
        <a :href="playUrl" target="_blank" rel="noopener">Google&nbsp;Play</a>
      </span>
    </div>

    <div class="tgrid">
      <figure v-for="(t, i) in items" :key="i" class="tcard">
        <div class="tstars" :aria-label="`${t.stars} out of 5 stars`">
          <svg v-for="n in t.stars" :key="n" viewBox="0 0 24 24" width="16" height="16"><path fill="currentColor" d="M12 2l2.9 6.3 6.9.6-5.2 4.6 1.6 6.8L12 17.3 5.8 20.9l1.6-6.8L2.2 8.9l6.9-.6z"/></svg>
        </div>
        <blockquote>{{ t.text }}</blockquote>
        <figcaption>
          <span class="tname">{{ t.name }}</span>
          <span v-if="t.use" class="tuse">{{ t.use }}</span>
        </figcaption>
      </figure>
    </div>

    <p class="reviews-more"><NuxtLink to="/reviews">See more reviews →</NuxtLink></p>
  </section>
</template>

<style scoped>
.rating-summary {
  display: flex;
  align-items: center;
  gap: 0.7rem;
  flex-wrap: wrap;
  margin: 0.2rem 0 2rem;
}
.rs-score {
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 2.1rem;
  line-height: 1;
  color: var(--ink);
}
.rs-stars {
  display: inline-flex;
  color: var(--ochre);
}
.rs-meta {
  font-size: 0.95rem;
  color: var(--ink-soft);
}

.tgrid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(255px, 1fr));
  gap: 1rem;
}
.tcard {
  position: relative;
  overflow: hidden;
  margin: 0;
  background: var(--card);
  border: 1px solid var(--card-edge);
  border-radius: var(--radius);
  padding: 1.15rem 1.25rem 1.05rem;
  box-shadow: var(--shadow-card);
  display: flex;
  flex-direction: column;
  gap: 0.6rem;
}
/* big faded quote glyph marks these as testimonials, not generic cards */
.tcard::before {
  content: "\201C";
  position: absolute;
  top: -1.1rem;
  right: 0.7rem;
  font-family: var(--font-display);
  font-weight: 700;
  font-size: 5.5rem;
  line-height: 1;
  color: var(--green);
  opacity: 0.1;
  pointer-events: none;
}
.tstars {
  display: inline-flex;
  color: var(--ochre);
}
.tcard blockquote {
  margin: 0;
  font-size: 0.98rem;
  line-height: 1.55;
  color: var(--ink);
}
.tcard figcaption {
  margin-top: auto;
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 0.6rem;
}
.tname {
  font-weight: 600;
  font-size: 0.9rem;
  color: var(--ink-soft);
}
.tuse {
  font-family: var(--font-mono);
  font-size: 0.62rem;
  letter-spacing: 0.12em;
  text-transform: uppercase;
  color: var(--olive);
  background: color-mix(in srgb, var(--olive) 13%, transparent);
  padding: 0.22em 0.6em;
  border-radius: 999px;
  white-space: nowrap;
}
.reviews-more {
  margin-top: 1.5rem;
}
.reviews-more a {
  font-weight: 600;
  color: var(--green-deep);
  text-decoration: none;
}
.reviews-more a:hover {
  text-decoration: underline;
}
</style>
