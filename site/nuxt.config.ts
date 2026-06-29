// Nuxt 4 — Time Calculator Cardamon marketing site + web calculator.
// SSR/prerendered (crawlable HTML for SEO + AI answer engines), self-hosted
// fonts, and @nuxtjs/seo for robots / sitemap / schema.org / OG images.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-01',
  devtools: { enabled: true },

  modules: ['@nuxt/fonts', '@nuxtjs/seo'],

  css: ['~/assets/css/main.css'],

  // Drives canonical, robots.txt, sitemap.xml and OG image base URL. Production
  // domain is timecalculator.app (the web home of the Time Calculator app);
  // override per-environment with NUXT_SITE_URL in Vercel if needed.
  site: {
    url: process.env.NUXT_SITE_URL || 'https://timecalculator.app',
    name: 'Time Calculator Cardamon',
    description:
      'Free online time duration calculator. Add and subtract hours, minutes, '
      + 'days and seconds — just type, e.g. "5h 30m + 2h 15m".',
    defaultLocale: 'en',
  },

  // Static-render the landing page → instant, fully crawlable HTML that AI
  // retrieval bots (1–5s fetch windows, little/no JS) can read.
  nitro: {
    prerender: { crawlLinks: true, routes: ['/', '/robots.txt', '/sitemap.xml'] },
  },

  fonts: {
    // Self-hosted (privacy + Core Web Vitals). Only the weights we use.
    families: [
      { name: 'Fraunces', provider: 'google', weights: [400, 500, 600, 700], styles: ['normal', 'italic'] },
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
      link: [
        { rel: 'icon', type: 'image/png', href: '/icons/app-logo.png' },
        { rel: 'icon', type: 'image/png', sizes: '512x512', href: '/icons/icon-512.png' },
        { rel: 'apple-touch-icon', href: '/icons/icon-512.png' },
        { rel: 'manifest', href: '/site.webmanifest' },
      ],
    },
  },
})
