// /llms-full.txt — every page's content concatenated into one markdown file for
// one-shot LLM ingestion. Generated from the same data the pages render, so it
// never drifts. Prerendered fresh on each build (see nitro.prerender).
import { GUIDES } from '../../app/utils/guides'
import { CONVERSIONS } from '../../app/utils/conversions'
import { FAQS } from '../../app/utils/faqs'
import { AUTHOR } from '../../app/utils/author'
import { SHOWCASE } from '../../app/utils/showcase'
import { REVIEWS, REVIEW_RATING } from '../../app/utils/reviews'

const PLAY = 'https://play.google.com/store/apps/details?id=com.dmitriykargashin.cardamontimecalculator'

export default defineEventHandler((event) => {
  const base = (process.env.NUXT_SITE_URL || getRequestURL(event).origin).replace(/\/+$/, '')
  setHeader(event, 'content-type', 'text/plain; charset=utf-8')

  const p: string[] = []

  p.push('# Time Calculator Cardamon — full reference\n')
  p.push('> Free time-duration calculator. Add, subtract, multiply, and divide durations across years, months, weeks, days, hours, minutes, seconds, and milliseconds. Type a natural expression like "5h 30m + 2h 15m" and read the answer. The same engine runs on web, Android, and iOS.\n')
  p.push(`Home: ${base}/`)
  p.push('Maker: Cardamon (support@cardamon.org)')
  p.push(`Rating: ${REVIEW_RATING.value}/5 from ${REVIEW_RATING.count} Google Play ratings`)
  p.push('Pricing: web is free (ad-supported); Android is free with no ads; iOS unlocks the full app with a Pro purchase\n')

  p.push('## About the author')
  p.push(`${AUTHOR.bio}`)
  p.push(`He also builds ${AUTHOR.projects.map((pr) => `${pr.name} (${pr.url}) — ${pr.desc}`).join('; and ')}.`)
  p.push(`LinkedIn: ${AUTHOR.linkedin} | GitHub: ${AUTHOR.github} | Author page: ${base}/dmitrii-kargashin\n`)

  p.push('## How it works')
  p.push('Write durations on one line and join them with operators: + adds, - subtracts, × (or *) multiplies by a number, ÷ (or /) divides by a number. Each duration is a number and a unit, like 2h or 45 min. Every number needs a unit; a bare number is only valid as the ×/÷ multiplier. Choose how the result reads with the format picker, e.g. "Hour Minute" gives "7 Hours 45 Minutes".\n')

  p.push('## Unit conversions')
  p.push('1 day = 24 hours = 1,440 minutes = 86,400 seconds. 1 week = 7 days. 1 hour = 60 minutes = 3,600 seconds. 1 minute = 60 seconds = 60,000 milliseconds. 1 second = 1,000 milliseconds.\n')

  p.push(`## Time unit converter (${base}/convert)`)
  for (const c of CONVERSIONS) p.push(`### ${c.question}\n${c.answer} In the calculator, \`${c.expr}\` returns ${c.result}.\n`)

  p.push('## Frequently asked questions')
  for (const f of FAQS) p.push(`### ${f.q}\n${f.a}\n`)

  p.push('## Guides')
  for (const g of GUIDES) {
    p.push(`### ${g.h1}`)
    p.push(`${g.answer}\n`)
    p.push(`${g.intro}\n`)
    p.push('Steps:')
    g.steps.forEach((s, i) => p.push(`${i + 1}. ${s.title} — ${s.body}`))
    p.push('\nWorked examples:')
    g.examples.forEach((ex) => p.push(`- \`${ex.expr}\` = ${ex.result}  (${ex.note})`))
    p.push('\nQuestions:')
    g.faqs.forEach((f) => p.push(`- ${f.q} — ${f.a}`))
    p.push(`\nFull guide: ${base}/guides/${g.slug}\n`)
  }

  p.push('## Mobile app')
  p.push(`${SHOWCASE.pitch}\n`)
  p.push('Use cases:')
  SHOWCASE.useCases.forEach((u) => p.push(`- ${u.title}: ${u.text}`))
  p.push('\nFeatures:')
  SHOWCASE.features.forEach((f) => p.push(`- ${f}`))
  p.push('\nWhy the app:')
  SHOWCASE.whyApp.forEach((w) => p.push(`- ${w}`))
  p.push(`\nGoogle Play: ${PLAY}\nApple App Store: coming soon\n`)

  p.push("## What's new (app)")
  p.push('Version 2.4.0: a customisable keypad with one-tap presets (Standard, Stopwatch, Media, Hours & minutes, Calendar, Everything) and a live preview; calculation history saved on your device with per-entry notes; quick result actions (copy, change format, rate, share); a redesigned rate calculator; more result formats including milliseconds; and smoother resizing.\n')

  p.push('## Reviews')
  p.push(`${REVIEW_RATING.value}/5 from ${REVIEW_RATING.count} ratings on Google Play (${REVIEW_RATING.written} written). Selected reviews:`)
  for (const r of REVIEWS) p.push(`- "${r.text}" — ${r.name} (${r.stars}/5, ${r.date})`)

  return p.join('\n') + '\n'
})
