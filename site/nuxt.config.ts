// Nuxt 4 — Time Calculator Cardamon marketing site + web calculator.
// SSR/prerendered (crawlable HTML for SEO + AI answer engines), self-hosted
// fonts, and @nuxtjs/seo for robots / sitemap / schema.org / OG images.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-01',
  devtools: { enabled: true },

  // Local dev server (yarn dev) port.
  devServer: { port: 3060 },

  modules: ['@nuxt/fonts', '@nuxtjs/seo'],

  css: ['~/assets/css/main.css'],

  // The canonical URL is NEVER hardcoded — it comes from the NUXT_SITE_URL env
  // var (set it to https://www.timecalculator.app in Vercel; locally it reads
  // site/.env, and falls back to auto-detected http://localhost:3060 in dev).
  // This single value drives canonical, robots.txt, sitemap.xml, OG and JSON-LD.
  site: {
    name: 'Time Calculator Cardamon',
    description:
      'Free online time duration calculator. Just type something like '
      + '"5h 30m + 2h 15m" to add and subtract hours, minutes, and days.',
    defaultLocale: 'en',
  },

  // Static-render the landing page → instant, fully crawlable HTML that AI
  // retrieval bots (1–5s fetch windows, little/no JS) can read.
  nitro: {
    prerender: { crawlLinks: true, routes: ['/', '/robots.txt', '/sitemap.xml', '/llms.txt'] },
  },

  fonts: {
    // Self-hosted (privacy + Core Web Vitals). Only the weights we use.
    families: [
      { name: 'Hanken Grotesk', provider: 'google', weights: [400, 500, 600, 700] },
      { name: 'JetBrains Mono', provider: 'google', weights: [500, 700] },
      // ABeeZee — the exact font the mobile apps use, for the calculator itself.
      { name: 'ABeeZee', provider: 'google', weights: [400], styles: ['normal', 'italic'] },
    ],
  },

  // @nuxtjs/seo v5 is Nuxt 4-compatible: nuxt-seo-utils (canonical/meta) and
  // robots + sitemap are active. We inject our own JSON-LD @graph, so keep
  // nuxt-schema-org off to avoid a duplicate WebSite node.
  //
  // og-image stays OFF: v6 requires a renderer dep (@takumi-rs/core@beta) +
  // @nuxt/fonts >=0.13 to generate cards — not worth a beta dep in the build
  // yet. We ship a static og:image instead (see pages/index.vue). To enable
  // dynamic cards later: `yarn add -D @takumi-rs/core@beta` + bump @nuxt/fonts,
  // set ogImage: true, and call defineOgImageComponent('NuxtSeo', {...}).
  ogImage: false,
  schemaOrg: false,

  app: {
    head: {
      htmlAttrs: { lang: 'en' },
      meta: [
        { name: 'viewport', content: 'width=device-width, initial-scale=1, viewport-fit=cover' },
        { name: 'theme-color', content: '#f3efe4' },
      ],
      script: [
        {
          // Set the motion gate before first paint so reveal elements never
          // flash; skipped under reduced-motion so content stays fully visible.
          innerHTML:
            "(function(){try{if(matchMedia('(prefers-reduced-motion: reduce)').matches)return}catch(e){}document.documentElement.classList.add('has-motion')})()",
          tagPosition: 'head',
        },
      ],
      link: [
        // Browser-tab favicon: transparent green clock (SVG preferred, PNG fallback).
        { rel: 'icon', type: 'image/svg+xml', href: '/icons/app-logo.svg' },
        { rel: 'icon', type: 'image/png', href: '/icons/app-logo.png' },
        // iOS home-screen tile can't be transparent, so it keeps the white-backed icon.
        { rel: 'apple-touch-icon', href: '/icons/icon-512.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
      ],
    },
  },
})
