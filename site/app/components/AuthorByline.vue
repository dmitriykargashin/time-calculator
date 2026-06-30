<script setup lang="ts">
import { AUTHOR } from '~/utils/author'
// A compact "By Dmitrii Kargashin · Updated June 2026" line for the top of content.
defineProps<{ date?: string }>()
</script>

<template>
  <div class="byline">
    <NuxtLink to="/dmitrii-kargashin" class="byline-av" aria-label="About the author">
      <img :src="AUTHOR.photo" :alt="AUTHOR.name" width="38" height="38" loading="lazy" />
    </NuxtLink>
    <span class="byline-txt">
      By <NuxtLink to="/dmitrii-kargashin" class="byline-name">{{ AUTHOR.name }}</NuxtLink><template v-if="date"> · Updated {{ date }}</template>
    </span>
  </div>
</template>

<style scoped>
.byline { display: inline-flex; align-items: center; gap: 0.55rem; margin: 0.2rem 0 0.4rem; font-size: 0.9rem; color: var(--ink-soft); }
.byline-av { display: block; width: 1.9rem; height: 1.9rem; border-radius: 50%; overflow: hidden; background: var(--green); flex: none; }
.byline-av img { width: 100%; height: 100%; object-fit: cover; display: block; }
.byline-name { color: var(--green-deep); font-weight: 600; text-decoration: none; }
.byline-name:hover { text-decoration: underline; }
</style>
