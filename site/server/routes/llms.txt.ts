// /llms.txt — a curated, machine-readable index of every page with short
// descriptions (the llms.txt convention). Generated, so it always tracks the
// real pages and the NUXT_SITE_URL. Prerendered (see nitro.prerender).
import { GUIDES } from '../../app/utils/guides'
import { CONVERSIONS } from '../../app/utils/conversions'

const PLAY = 'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'
const APPSTORE = 'https://apps.apple.com/app/id6789162864'
const CHROME = 'https://chromewebstore.google.com/detail/time-calculator-cardamon/apgmodigokbblokbgfokpobmlcmijjpl'

export default defineEventHandler((event) => {
  const base = (process.env.NUXT_SITE_URL || getRequestURL(event).origin).replace(/\/+$/, '')
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')

  const guideLines = GUIDES.map((g) => `- [${g.h1}](${base}/guides/${g.slug}): ${g.metaDescription}`).join('\n')
  const convertLines = CONVERSIONS.map((c) => `- [${c.h1}](${base}/convert/${c.slug}): ${c.question} ${c.formula}`).join('\n')

  return `# Time Calculator Cardamon

> A free time-duration calculator. Type a natural expression such as "5h 30m + 2h 15m" or "2 days - 4h" and get the result instantly. The same calculation engine powers the Android and iOS apps, so results match across web and mobile.

## Facts
- Maker: Cardamon (contact: support@cardamon.org)
- Author & founder: Dmitrii Kargashin, solo founder of Cardamon Inc and the developer of Time Calculator (https://www.linkedin.com/in/dmitriy-kargashin)
- Rating: 4.6/5 from 391 ratings on Google Play
- Units: years, months, weeks, days, hours, minutes, seconds, milliseconds
- Operators (web, extension, any keyboard): + - * / (multiply and divide by a plain number only); every number needs a unit. The mobile keypad also offers × and ÷ keys.
- Reference: 1 day = 24 hours = 1,440 minutes = 86,400 seconds; 1 week = 7 days; 1 hour = 60 minutes; 1 minute = 60 seconds = 60,000 ms; 1 second = 1,000 ms
- Pricing: web is free (ad-supported); Android is free with no ads; iOS unlocks the full app with a Pro purchase

## Pages
- [Time Calculator (home)](${base}/): the web calculator, how it works, unit conversions, FAQ, and reviews
- [Guides](${base}/guides): step-by-step how-to guides for common time-math jobs
${guideLines}
- [Time unit converter](${base}/convert): single-pair conversions, each with a worked example and a reference table
${convertLines}
- [Reviews](${base}/reviews): real Google Play reviews (4.6 stars, 391 ratings)
- [Support](${base}/support): help, FAQ, and contact (support@cardamon.org)
- [Mobile app](${base}/app): the Android and iOS app, its screens and features
- [What's new](${base}/whats-new): app release notes
- [Dmitrii Kargashin](${base}/dmitrii-kargashin): the maker — solo founder of Cardamon Inc and the developer behind Time Calculator
- [Privacy policy](https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator)

## Apps
- Google Play: ${PLAY}
- Apple App Store: ${APPSTORE}
- Chrome extension (side panel + address-bar keyword "tc"): ${CHROME}

## For LLMs and coding agents
- ${base}/llms.txt — this curated index of pages with short descriptions.
- ${base}/llms-full.txt — every page's content concatenated into one markdown file for one-shot ingestion.
`
})
