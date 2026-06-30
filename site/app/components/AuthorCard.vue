<script setup lang="ts">
import { AUTHOR } from '~/utils/author'
// Bio box for the foot of guides and convert pages (E-E-A-T: real author + bio +
// LinkedIn). Swap the initials avatar for a headshot once one is supplied.
</script>

<template>
  <aside class="author-card">
    <NuxtLink to="/dmitrii-kargashin" class="ac-avatar" aria-label="About the author">
      <img :src="AUTHOR.photo" :alt="AUTHOR.name" width="60" height="60" loading="lazy" />
    </NuxtLink>
    <div class="ac-body">
      <p class="ac-kicker">Written by</p>
      <p class="ac-name"><NuxtLink to="/dmitrii-kargashin">{{ AUTHOR.name }}</NuxtLink></p>
      <p class="ac-title">{{ AUTHOR.jobTitle }}</p>
      <p class="ac-bio">{{ AUTHOR.bio }}</p>
      <a :href="AUTHOR.linkedin" target="_blank" rel="noopener" class="ac-link">
        <svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor" aria-hidden="true"><path d="M4.98 3.5a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5zM3 9h4v12H3zM10 9h3.8v1.7h.05c.53-.95 1.83-1.95 3.77-1.95C21.4 8.75 22 11.1 22 14.1V21h-4v-6c0-1.43-.03-3.27-2-3.27-2 0-2.3 1.56-2.3 3.17V21h-4z"/></svg>
        Connect on LinkedIn
      </a>
    </div>
  </aside>
</template>

<style scoped>
.author-card { display: flex; gap: 1.1rem; align-items: flex-start; margin: 2.4rem 0 0; padding: 1.4rem; background: var(--card); border: 1px solid var(--card-edge); border-radius: var(--radius); box-shadow: var(--shadow-card); }
.ac-avatar { flex: none; display: block; width: 3.4rem; height: 3.4rem; border-radius: 50%; overflow: hidden; background: var(--green); }
.ac-avatar img { width: 100%; height: 100%; object-fit: cover; display: block; }
.ac-body { min-width: 0; }
.ac-kicker { margin: 0; font-family: var(--font-mono); font-size: 0.64rem; letter-spacing: 0.16em; text-transform: uppercase; color: var(--olive); }
.ac-name { margin: 0.15rem 0 0; font-family: var(--font-display); font-size: 1.1rem; font-weight: 600; }
.ac-name a { color: var(--ink); text-decoration: none; }
.ac-name a:hover { color: var(--green-deep); }
.ac-title { margin: 0.05rem 0 0.6rem; font-size: 0.86rem; color: var(--ink-faint); }
.ac-bio { margin: 0 0 0.8rem; font-size: 0.94rem; color: var(--ink-soft); max-width: 60ch; }
.ac-link { display: inline-flex; align-items: center; gap: 0.4rem; font-weight: 600; font-size: 0.9rem; color: var(--green-deep); text-decoration: none; }
.ac-link:hover { text-decoration: underline; }
</style>
