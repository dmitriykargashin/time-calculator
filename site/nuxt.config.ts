// Nuxt 4 — Time Calculator Cardamon marketing site + web calculator.
// SSR/prerendered (crawlable HTML for SEO + AI answer engines), self-hosted
// fonts, and @nuxtjs/seo for robots / sitemap / schema.org / OG images.
export default defineNuxtConfig({
  compatibilityDate: '2025-07-01',
  devtools: { enabled: true },

  // Local dev server (yarn dev) port.
  devServer: { port: 3060 },

  // Modules: self-hosted fonts, SEO (robots/sitemap/canonical), Google
  // Analytics 4 (nuxt-gtag), and Vercel Web Analytics (cookieless; auto-injects
  // and no-ops off Vercel). The GA Measurement ID is never hardcoded — it comes
  // from NUXT_PUBLIC_GTAG_ID (set in Vercel). gtag stays inert until that env
  // var exists, so local dev and previews send nothing unless you opt in.
  modules: ['@nuxt/fonts', '@nuxtjs/seo', 'nuxt-gtag', '@vercel/analytics/nuxt'],

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
    prerender: { crawlLinks: true, routes: ['/', '/convert', '/dmitrii-kargashin', '/robots.txt', '/sitemap.xml', '/llms.txt', '/llms-full.txt'] },
  },

  // The author page is the person-brand URL (/dmitrii-kargashin); the old /about
  // 301-redirects to it so any existing or guessed links still resolve.
  routeRules: {
    '/about': { redirect: { to: '/dmitrii-kargashin', statusCode: 301 } },
  },

  // Attach the social card as an <image:image> on the home URL and stamp a
  // build-time lastmod. Absolute URLs still resolve from site.url (NUXT_SITE_URL).
  sitemap: {
    autoLastmod: true,
    urls: [
      {
        loc: '/',
        images: [
          {
            loc: '/og.png',
            title: 'Time Calculator by Cardamon',
            caption: '5h 30m + 2h 15m = 7 Hours 45 Minutes',
          },
        ],
      },
    ],
  },

  // Google Analytics 4 (gtag.js). The Measurement ID is read from
  // NUXT_PUBLIC_GTAG_ID (env, never hardcoded). Consent Mode v2: analytics is
  // DENIED by default (nothing stored) until a visitor accepts in the cookie
  // banner, which pushes a live `consent update`. See composables/useConsent.ts.
  gtag: {
    initCommands: [
      ['consent', 'default', {
        analytics_storage: 'denied',
        ad_storage: 'denied',
        ad_user_data: 'denied',
        ad_personalization: 'denied',
        wait_for_update: 500,
      }],
    ],
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
          // Apply the saved/system theme before first paint so dark mode never
          // flashes light. Mirrors composables/useTheme.ts (key `tc-theme`).
          innerHTML:
            "(function(){try{var t=localStorage.getItem('tc-theme')||'auto';var d=t==='dark'||(t==='auto'&&matchMedia('(prefers-color-scheme: dark)').matches);var e=document.documentElement;e.dataset.theme=d?'dark':'light';if(d)e.classList.add('dark')}catch(e){}})()",
          tagPosition: 'head',
        },
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
