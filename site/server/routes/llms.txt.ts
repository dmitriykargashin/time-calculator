// /llms.txt — generated (not a static file) so the home URL always tracks the
// NUXT_SITE_URL env var. Prerendered to a static file at build (nitro.prerender).
export default defineEventHandler((event) => {
  const base = (process.env.NUXT_SITE_URL || getRequestURL(event).origin).replace(/\/+$/, '')
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')
  return `# Time Calculator Cardamon

> A free online time-duration calculator. Type a natural expression such as
> "5h 30m + 2h 15m" or "2 days - 4 hours" and get the result instantly. The
> same calculation engine powers the Android and iOS apps, so results match
> across web and mobile.

## Facts
- Maker: Cardamon (contact: support@cardamon.org)
- What it does: adds, subtracts, multiplies and divides time durations across years, months, weeks, days, hours, minutes, seconds and milliseconds.
- Input: plain text (keyboard/paste friendly) — e.g. "1d 4h", "90 min", "8h15m * 3".
- Output formats: hours:minutes, days/hours/minutes, total minutes, total seconds, full breakdown.
- Reference conversions: 1 day = 24 hours = 1,440 minutes = 86,400 seconds. 1 week = 7 days. 1 hour = 60 minutes = 3,600 seconds.
- Price: free on the web; mobile apps free with optional Pro/donation.

## Pages
- Home / calculator: ${base}/
- Privacy policy: https://www.cardamon.org/products/time-calculator/privacy-policy-time-calculator

## Apps
- Google Play: https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator
- Apple App Store: coming soon
`
})
