// Nuxt 4 — Time Calculator Cardamon marketing site + web calculator.
// SSR/prerendered (crawlable HTML for SEO + AI answer engines), self-hosted
// fonts, and @nuxtjs/seo for robots / sitemap / schema.org / OG images.
import { execSync } from 'node:child_process'
import { GUIDES, GUIDE_UPDATED } from './app/utils/guides'
import { CONVERSIONS } from './app/utils/conversions'

// Sitemap <lastmod>: the last git commit that touched a page's CONTENT source,
// not the deploy time (autoLastmod stamped every URL with the prerender
// timestamp, which Google discounts as "unverifiable" — Mueller/Illyes; see
// https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap).
// When several files feed one page, the newest wins. If git can't answer
// (shallow CI clone, file outside history), the URL just OMITS lastmod —
// omitting is honest; a fake fresh date erodes Google's trust in all of them.
const gitDateCache = new Map<string, string | undefined>()
function gitLastmod(...files: string[]): string | undefined {
  const dates = files
    .map((f) => {
      if (!gitDateCache.has(f)) {
        try {
          gitDateCache.set(
            f,
            execSync(`git log -1 --format=%cI -- "${f}"`, { cwd: __dirname, encoding: 'utf8' }).trim() || undefined,
          )
        } catch {
          gitDateCache.set(f, undefined)
        }
      }
      return gitDateCache.get(f)
    })
    .filter((d): d is string => !!d)
  return dates.sort().pop()
}

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

  // Sitemap: real per-page lastmod (see gitLastmod above), NOT the deploy time
  // (autoLastmod is off for that reason). Guides use GUIDE_UPDATED — the same
  // editorial date their on-page schema.org dateModified declares, so sitemap
  // and schema agree. Convert pages date from conversions.ts; static pages from
  // their .vue file plus the data files that render into them. The home URL
  // also attaches the social card as an <image:image>. These entries merge onto
  // the app-discovered URLs by loc; absolute URLs resolve from site.url.
  sitemap: {
    autoLastmod: false,
    urls: () => [
      {
        loc: '/',
        lastmod: gitLastmod('app/pages/index.vue', 'app/utils/faqs.ts', 'app/components/TimeCalculator.vue'),
        images: [
          {
            loc: '/og.png',
            title: 'Time Calculator by Cardamon',
            caption: '5h 30m + 2h 15m = 7 Hours 45 Minutes',
          },
        ],
      },
      { loc: '/app', lastmod: gitLastmod('app/pages/app/index.vue', 'app/utils/showcase.ts') },
      { loc: '/convert', lastmod: gitLastmod('app/pages/convert/index.vue', 'app/utils/conversions.ts') },
      { loc: '/dmitrii-kargashin', lastmod: gitLastmod('app/pages/dmitrii-kargashin.vue', 'app/utils/author.ts') },
      { loc: '/guides', lastmod: gitLastmod('app/pages/guides/index.vue', 'app/utils/guides.ts') },
      { loc: '/reviews', lastmod: gitLastmod('app/pages/reviews/index.vue') },
      { loc: '/support', lastmod: gitLastmod('app/pages/support.vue') },
      { loc: '/whats-new', lastmod: gitLastmod('app/pages/whats-new.vue') },
      ...GUIDES.map((g) => ({ loc: `/guides/${g.slug}`, lastmod: g.updated ?? GUIDE_UPDATED })),
      ...CONVERSIONS.map((c) => ({
        loc: `/convert/${c.slug}`,
        lastmod: gitLastmod('app/utils/conversions.ts', 'app/pages/convert/[pair].vue'),
      })),
    ],
  },

  // Google Analytics 4 (gtag.js). The Measurement ID is read from
  // NUXT_PUBLIC_GTAG_ID (env, never hardcoded). Consent Mode v2: analytics is
  // DENIED by default (nothing stored) until a visitor accepts in the cookie
  // banner, which pushes a live `consent update`. See composables/useConsent.ts.
  gtag: {
    // Deferred: gtag.js (~169 KiB, ~350 ms of mobile main-thread) loads at
    // browser idle via app/plugins/gtag-idle.client.ts instead of blocking
    // startup. initCommands (Consent Mode defaults) still run at initialize.
    initMode: 'manual',
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
