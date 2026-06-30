// Authorship / E-E-A-T. One source for the byline, the bio box, the /dmitrii-kargashin page,
// and the Person JSON-LD reused across pages. Grounded in real facts (the user's
// LinkedIn + the apps): solo founder of Cardamon Inc who built Time Calculator
// and the calculation engine behind it.
export const AUTHOR = {
  name: 'Dmitrii Kargashin',
  firstName: 'Dmitrii',
  jobTitle: 'Founder, Cardamon Inc',
  // one-liner for bylines / meta
  tagline: 'Solo founder of Cardamon Inc and the developer behind Time Calculator.',
  // bio box + /dmitrii-kargashin page (only facts, from the solo-founder angle)
  bio:
    'Dmitrii Kargashin is the solo founder of Cardamon Inc and the developer behind '
    + 'Time Calculator. He builds and ships his products end to end, from the first idea '
    + 'to deployment, and he wrote the calculation engine that runs the same way here on '
    + 'the web as it does in the Android and iOS apps. Before going solo he led engineering '
    + 'teams and built large-scale enterprise systems used by thousands of people. He works '
    + 'across the stack in TypeScript, Node, Vue 3, and PostgreSQL.',
  // LinkedIn / GitHub keep their existing handles (links, not the display name)
  linkedin: 'https://www.linkedin.com/in/dmitriy-kargashin',
  github: 'https://github.com/dmitriykargashin',
  // real headshot (public/author/…); initials are the fallback
  photo: '/author/dmitrii-kargashin.jpg',
  initials: 'DK',
  // other products he builds under Cardamon
  projects: [
    { name: 'JSON Copilot', url: 'https://www.jsoncopilot.com', desc: 'an LLM-assisted JSON tool that explains, transforms, and validates JSON for people who do not write code' },
    { name: 'noHuman Team', url: 'https://www.nohuman.team', desc: 'a platform that turns AI agents into collaborative startup teams with real roles and tools' },
  ],
}

const MONTHS = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
]

/** "2026-06-30" → "June 2026" (no Date dependency, SSR-safe). */
export function monthYear(iso: string): string {
  const parts = iso.split('-')
  const y = parts[0] ?? ''
  const m = Number(parts[1] ?? 0)
  return m >= 1 && m <= 12 ? `${MONTHS[m - 1]} ${y}` : y
}

/** The Person node for a JSON-LD @graph. `@id` is stable site-wide so any page
 *  can name it as the author; url/mainEntity point at /dmitrii-kargashin. Self-contained
 *  worksFor avoids dangling references on pages that don't emit the Org node. */
export function personNode(siteUrl: string) {
  return {
    '@type': 'Person',
    '@id': `${siteUrl}/#person`,
    name: AUTHOR.name,
    url: `${siteUrl}/dmitrii-kargashin`,
    jobTitle: AUTHOR.jobTitle,
    description: AUTHOR.tagline,
    image: `${siteUrl}${AUTHOR.photo}`,
    knowsAbout: ['Time calculation', 'Full-stack web development', 'TypeScript', 'Vue', 'Mobile apps'],
    sameAs: [AUTHOR.linkedin, AUTHOR.github],
    worksFor: { '@type': 'Organization', name: 'Cardamon Inc', url: 'https://www.cardamon.org' },
  }
}
