// Store-listing screenshot generator.
// Frames the REAL app screens (captured at 3x by the Flutter golden harness,
// see flutter_app/test/store_capture_test.dart) inside device-accurate frames
// (iPhone 17 Pro / Galaxy S25) + brand backgrounds + captions, then rasterizes
// to exact Play / App Store pixel sizes via headless Chrome + sips.
//
// Templates:
//   panorama  frames 1+2 — ONE angled phone spanning a 2-wide canvas, then
//             sliced into two store images that reassemble side by side.
//   straight  frames 3+  — full phone + top headline.
//
// Run:  node src/build.mjs            (all specs)
//       node src/build.mjs combo      (only ids containing "combo")
import { execSync } from 'node:child_process'
import { writeFileSync, mkdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import { dirname, resolve, join } from 'node:path'

const __dir = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dir, '..')
const FONTS = join(__dir, 'fonts')
const SHOTS = join(__dir, 'screens')
const BUILD = join(ROOT, '.build')
mkdirSync(BUILD, { recursive: true })
mkdirSync(join(ROOT, 'android'), { recursive: true })
mkdirSync(join(ROOT, 'ios'), { recursive: true })
mkdirSync(join(ROOT, 'android-tab-10'), { recursive: true })
mkdirSync(join(ROOT, 'android-tab-7'), { recursive: true })
mkdirSync(join(ROOT, 'ios-tab-13'), { recursive: true })

const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const shotUrl = (f) => `file://${join(SHOTS, f)}`
const R = Math.round

const PHONE_AR = 2532 / 1170, TAB_AR = 3200 / 2000, IPAD_AR = 2732 / 2048
const PLAT = {
  ios: {
    dir: 'ios', w: 1290, h: 2796, device: 'iphone', ar: PHONE_AR, swFrac: 0.75, stageTop: 0.205,
    bezel: 0.028, outerR: 0.165, innerR: 0.135,
    frame: 'linear-gradient(135deg,#48484b 0%,#2a2a2d 38%,#161618 100%)', rim: '#5b5b5f',
  },
  android: {
    dir: 'android', w: 1080, h: 1920, device: 'galaxy', ar: PHONE_AR, swFrac: 0.59, stageTop: 0.225,
    bezel: 0.020, outerR: 0.11, innerR: 0.092,
    frame: 'linear-gradient(135deg,#3a3a40 0%,#202024 45%,#0e0e10 100%)', rim: '#4a4a50',
  },
  // Android 10-inch tablet (9:16 canvas, 16:10 portrait device). The 7-inch set
  // is produced by downscaling these outputs.
  tablet: {
    dir: 'android-tab-10', w: 1800, h: 3200, device: 'tablet', ar: TAB_AR, swFrac: 0.8, stageTop: 0.235,
    bezel: 0.026, outerR: 0.04, innerR: 0.026,
    frame: 'linear-gradient(135deg,#3a3a40 0%,#202024 45%,#101012 100%)', rim: '#4a4a50',
  },
  // Apple iPad 13" (2064x2752, 3:4 portrait). A thin uniform-bezel space-black
  // frame; renders straight to its exact store size (no downscale step). The 3:4
  // canvas is much wider than the phones, so the width-relative caption font is
  // scaled DOWN (capScale) to keep headlines from wrapping into the device.
  ipad: {
    dir: 'ios-tab-13', w: 2064, h: 2752, device: 'tablet', ar: IPAD_AR, swFrac: 0.7, stageTop: 0.245,
    bezel: 0.019, outerR: 0.032, innerR: 0.02, capScale: 0.64,
    frame: 'linear-gradient(135deg,#48484b 0%,#2a2a2d 38%,#161618 100%)', rim: '#5b5b5f',
  },
}

const ic = {
  signal: `<svg viewBox="0 0 20 14" fill="currentColor"><rect x="0" y="9" width="3.2" height="5" rx="1"/><rect x="5" y="6" width="3.2" height="8" rx="1"/><rect x="10" y="3" width="3.2" height="11" rx="1"/><rect x="15" y="0" width="3.2" height="14" rx="1"/></svg>`,
  wifi: `<svg viewBox="0 0 20 15" fill="currentColor"><path d="M10 3.2c3.2 0 6.1 1.3 8.2 3.4l-1.7 1.8A9 9 0 0 0 10 5.8 9 9 0 0 0 3.5 8.4L1.8 6.6A11.6 11.6 0 0 1 10 3.2Z"/><path d="M10 8.1c1.8 0 3.5.7 4.8 2l-1.8 1.8A4.4 4.4 0 0 0 10 10.6c-1.2 0-2.3.4-3 1.3L5.2 10.1A6.9 6.9 0 0 1 10 8.1Z"/><circle cx="10" cy="13" r="1.6"/></svg>`,
  battery: `<svg viewBox="0 0 28 14" fill="none"><rect x="0.7" y="0.7" width="23" height="12.6" rx="3.2" stroke="currentColor" stroke-width="1.3" opacity="0.5"/><rect x="2.4" y="2.4" width="17" height="9.2" rx="1.8" fill="currentColor"/><rect x="25" y="4.6" width="2.2" height="4.8" rx="1.1" fill="currentColor" opacity="0.6"/></svg>`,
}

// ---- a framed device (returns {css, html}) ----
function device({ p, id, sw, dark, shot }) {
  const bezel = R(sw * p.bezel)
  const outerW = sw + bezel * 2
  const screenH = R(sw * p.ar)
  const outerR = R(sw * p.outerR)
  const innerR = R(sw * p.innerR)
  const sbS = p.device === 'tablet' ? 0.45 : 1 // tablets have a smaller status bar relative to width
  const sbH = R(sw * 0.10 * sbS), sbTop = R(sw * 0.018 * sbS), sbFs = R(sw * 0.032 * sbS), sbIc = R(sw * 0.021 * sbS), sbPad = R(sw * 0.06)
  const islandW = R(sw * 0.30), islandH = R(sw * 0.082), holeD = R(sw * 0.032)
  const btnW = Math.max(3, R(sw * 0.012))
  const paper = dark ? '#16140d' : '#f7f4ec'
  const sbColor = dark ? '#f2ecdb' : '#1c1b15'
  const buttons = p.device === 'iphone'
    ? `<i class="b bl" style="top:${R(screenH * 0.18)}px;height:${R(sw * 0.085)}px"></i>
       <i class="b bl" style="top:${R(screenH * 0.30)}px;height:${R(sw * 0.13)}px"></i>
       <i class="b bl" style="top:${R(screenH * 0.46)}px;height:${R(sw * 0.13)}px"></i>
       <i class="b br" style="top:${R(screenH * 0.30)}px;height:${R(sw * 0.20)}px"></i>`
    : p.device === 'galaxy'
    ? `<i class="b br" style="top:${R(screenH * 0.22)}px;height:${R(sw * 0.10)}px"></i>
       <i class="b br" style="top:${R(screenH * 0.34)}px;height:${R(sw * 0.17)}px"></i>`
    : '' // tablet: no visible side buttons
  const notch = p.device === 'iphone'
    ? `<div class="notch" style="top:${R(sw * 0.020)}px;width:${islandW}px;height:${islandH}px;border-radius:999px;background:#070707"></div>`
    : p.device === 'galaxy'
    ? `<div class="notch" style="top:${R(sw * 0.024)}px;width:${holeD}px;height:${holeD}px;border-radius:999px;background:#0a0a0a;box-shadow:0 0 0 2px rgba(0,0,0,.3)"></div>`
    : `<div class="notch" style="top:${R(sw * 0.013)}px;width:${R(sw * 0.013)}px;height:${R(sw * 0.013)}px;border-radius:999px;background:#0a0a0a;box-shadow:0 0 0 ${Math.max(1, R(sw * 0.002))}px rgba(0,0,0,.3)"></div>` // tablet front camera
  const css = `
.dev-${id}{position:relative;width:${outerW}px;padding:${bezel}px;background:${p.frame};border-radius:${outerR}px;
  box-shadow:0 0 0 1px ${p.rim} inset,0 2px 0 rgba(255,255,255,.06) inset,
    0 ${R(sw * 0.05)}px ${R(sw * 0.11)}px rgba(20,18,10,.34),0 ${R(sw * 0.013)}px ${R(sw * 0.03)}px rgba(20,18,10,.24)}
.dev-${id} .b{position:absolute;width:${btnW}px;border-radius:${btnW}px;background:#0c0c0e}
.dev-${id} .b.bl{left:-${btnW - 1}px}.dev-${id} .b.br{right:-${btnW - 1}px}
.dev-${id} .screen{position:relative;width:${sw}px;height:${screenH}px;overflow:hidden;border-radius:${innerR}px;background:${paper}}
.dev-${id} .screen img{display:block;width:${sw}px;height:${screenH}px}
.dev-${id} .sb{position:absolute;z-index:4;top:${sbTop}px;left:0;right:0;height:${sbH}px;display:flex;align-items:center;justify-content:space-between;padding:0 ${sbPad}px;color:${sbColor}}
.dev-${id} .sb-time{font-weight:600;font-size:${sbFs}px}
.dev-${id} .sb-icons{display:flex;align-items:center;gap:${R(sw * 0.013)}px}
.dev-${id} .sb-icons svg{height:${sbIc}px;width:auto}
.dev-${id} .notch{position:absolute;z-index:5;left:50%;transform:translateX(-50%)}`
  const html = `<div class="dev-${id}">${buttons}<div class="screen">
    <img src="${shotUrl(shot)}">
    <div class="sb"><div class="sb-time">9:41</div><div class="sb-icons">${ic.signal}${ic.wifi}${ic.battery}</div></div>
    ${notch}</div></div>`
  return { css, html }
}

const FONTFACE = `@font-face{font-family:'Hanken Grotesk';src:url('file://${FONTS}/HankenGrotesk.ttf');font-weight:100 900;font-style:normal}`
const TYPO = `.h1{font-weight:800;letter-spacing:-0.025em;color:#1c1b15}.h1 .a{color:#1f6c10}
.sub{font-weight:500;color:#524d3f;letter-spacing:-0.005em}
.dark .h1{color:#f2ecdb}.dark .h1 .a{color:#7fd24a}.dark .sub{color:#bdb6a3}`

// ONE continuous gradient across the whole 8-frame row: light at both ends,
// smoothly dipping to dark in the CENTER (aligned to the dark-theme frame at
// index 4), then back to light. Each frame paints its slice via a row-wide
// background + a per-frame x offset, so the backgrounds flow seamlessly when
// the screenshots sit side by side.
const ROW_W = 8
// Eases from light at the very first frame, smoothly down to dark at the
// centered dark-theme frame (idx 4), then smoothly back to light by the last.
const ROW_STOPS = '#e9f1dd 0%, #dceac2 16%, #b9d69b 29%, #5a7540 39%, #1a2414 47%, #0d0c08 56%, #1a2414 65%, #5a7540 71%, #b9d69b 81%, #dceac2 94%, #e9f1dd 100%'
const rowBg = (p, idx) =>
  `background:linear-gradient(91deg, ${ROW_STOPS});background-size:${p.w * ROW_W}px ${p.h}px;background-position:-${idx * p.w}px 0;background-repeat:no-repeat`

// Band streak colors track the bg lightness but a step lighter, so each streak
// is only a subtle highlight over whatever is beneath (never a harsh white on
// the dark center). Route colors lighten over the dark center so the path stays
// readable there without being contrasty.
const BAND_STOPS = '#ffffff 0%, #f2f8e8 16%, #d6ecb8 29%, #8aa86a 39%, #3e5230 47%, #313f24 56%, #3e5230 65%, #8aa86a 71%, #d6ecb8 81%, #f2f8e8 94%, #ffffff 100%'
const ROUTE_STOPS = '#2f7d18 0%, #2f7d18 30%, #6f9a4e 44%, #a8cf80 56%, #6f9a4e 65%, #2f7d18 78%, #2f7d18 100%'
const gradStops = (s) => s.split(',').map((part) => {
  const m = part.trim().match(/(#[0-9a-fA-F]+)\s+([\d.]+)%/)
  return `<stop offset="${(+m[2]) / 100}" stop-color="${m[1]}"/>`
}).join('')

// ONE continuous decorative layer across the whole row: a WIDE set of diagonal
// light streaks plus a wavy "map route" dotted path, both sliced per frame so
// they read as a single element from the first image to the last. The streak
// band is so wide its BOTTOM edge sits off-screen on the combo (frames 1-2) and
// only reveals from frame 3 on. Each streak's fill tracks the bg lightness, so
// the band is a soft highlight everywhere rather than a hard white on the dark.
function rowDecor(p, idx) {
  const W8 = p.w * ROW_W, h = p.h
  const yB0 = 1.18 * h, yB8 = 0.46 * h // band bottom edge: off-screen left, rises into view by frame 3
  const TH = 0.92 * h, K = 7
  let streaks = ''
  for (let k = 0; k < K; k++) {
    const f = (k + 0.5) / K
    const sh = (TH / K) * 0.32
    const yc0 = yB0 - (1 - f) * TH, yc8 = yB8 - (1 - f) * TH
    const o = (0.24 + 0.2 * Math.sin(Math.PI * f)).toFixed(3)
    streaks += `<polygon points="0,${R(yc0 - sh)} ${W8},${R(yc8 - sh)} ${W8},${R(yc8 + sh)} 0,${R(yc0 + sh)}" fill="url(#bandG)" opacity="${o}"/>`
  }
  const pts = []
  const N = 120
  for (let i = 0; i <= N; i++) {
    const t = i / N
    const base = (yB0 + (yB8 - yB0) * t) - TH * 0.72
    pts.push(`${R(t * W8)},${R(base + Math.sin(t * Math.PI * 5) * h * 0.06)}`)
  }
  const route = `<polyline points="${pts.join(' ')}" fill="none" stroke="url(#routeG)" stroke-width="${R(p.w * 0.0075)}" stroke-linecap="round" stroke-dasharray="2 ${R(p.w * 0.03)}" opacity="0.65"/>`
  return `<svg class="rowdecor" width="${W8}" height="${h}" viewBox="0 0 ${W8} ${h}" preserveAspectRatio="none" style="left:-${idx * p.w}px">
    <defs>
      <linearGradient id="bandG" x1="0" y1="0" x2="1" y2="0">${gradStops(BAND_STOPS)}</linearGradient>
      <linearGradient id="routeG" x1="0" y1="0" x2="1" y2="0">${gradStops(ROUTE_STOPS)}</linearGradient>
    </defs>
    ${streaks}${route}</svg>`
}

// decorative layer for straight frames: faint clock ring behind the phone plus
// sparkles, plus-marks and dots in the side margins (cohesive with the panorama,
// fills the space without crowding the feature). Adapts to the dark frame.
function straightDecor(p, dark, idx, leftFrac) {
  const c1 = dark ? '#7fd24a' : '#2f9412'
  const c2 = dark ? 'rgba(255,255,255,.6)' : '#ffffff'
  const c3 = dark ? '#5aa336' : '#1f6c10'
  const cols = [c1, c2, c3]
  // seeded by idx so every frame scatters its stars/plus/dots differently
  let s = ((idx + 1) * 1103515245 + 12345) % 2147483647
  if (s <= 0) s += 2147483646
  const rnd = () => (s = (s * 16807) % 2147483647) / 2147483647
  // scatter only in the side margins beside the centered device
  const m = leftFrac || 0.14
  const wdt = Math.max(0.02, m - 0.03)
  let items = ''
  for (let i = 0; i < 13; i++) {
    const x = i % 2 === 0 ? 0.012 + rnd() * wdt : (1 - m + 0.018) + rnd() * wdt
    const y = 0.13 + rnd() * 0.79
    const c = cols[Math.floor(rnd() * 3)]
    const o = (0.32 + rnd() * 0.4).toFixed(2)
    const sc = 1.4 + rnd() * 1.4
    const kind = Math.floor(rnd() * 3)
    if (kind === 0) items += dStar(p.w * x, p.h * y, sc, c, o)
    else if (kind === 1) items += dPlus(p.w * x, p.h * y, sc * 0.9, c, o)
    else items += dDot(p.w * x, p.h * y, 5 + rnd() * 3, c, o)
  }
  return `<svg class="decor" viewBox="0 0 ${p.w} ${p.h}" width="${p.w}" height="${p.h}">
    <circle cx="${R(p.w * 0.5)}" cy="${R(p.h * 0.64)}" r="${R(p.w * 0.62)}" fill="none" stroke="${c1}" stroke-width="2" stroke-dasharray="2 ${R(p.w * 0.02)}" opacity="${dark ? 0.16 : 0.12}"/>
    ${items}</svg>`
}

// ---- straight frame ----
function straightHtml(spec) {
  const p = PLAT[spec.platform]
  const id = spec.id.replace(/[^a-z0-9]/gi, '')
  const sw = R(p.w * p.swFrac)
  const d = device({ p, id, sw, dark: spec.dark, shot: spec.screenshot })
  const cs = p.capScale || 1 // wide canvases (iPad) shrink the caption to avoid device collisions
  const hSize = R(p.w * 0.082 * cs), subSize = R(p.w * 0.04 * cs), pad = R(p.w * 0.072)
  const top = R(p.h * p.stageTop), capTop = R(p.h * 0.063)
  const leftFrac = (1 - p.swFrac * (1 + 2 * p.bezel)) / 2 // x where the device starts
  // lightCap = this frame sits in the dark zone of the row gradient, so the
  // headline must be light even though the app screenshot itself may be light.
  const lc = spec.lightCap
  const css = `${FONTFACE}*{margin:0;padding:0;box-sizing:border-box}html,body{width:${p.w}px;height:${p.h}px}
.poster{position:relative;width:${p.w}px;height:${p.h}px;overflow:hidden;font-family:'Hanken Grotesk',sans-serif;-webkit-font-smoothing:antialiased;${rowBg(p, spec.idx)}}
.rowdecor{position:absolute;top:0;z-index:0}
.decor{position:absolute;top:0;left:0;z-index:1}
${TYPO}${d.css}
.cap{position:absolute;z-index:3;top:${capTop}px;left:0;right:0;padding:0 ${pad}px;text-align:center}
.cap .h1{font-size:${hSize}px;line-height:1.05}.cap .sub{margin-top:${R(subSize * 0.7)}px;font-size:${subSize}px;line-height:1.3}
.stage{position:absolute;z-index:2;top:${top}px;left:0;right:0;display:flex;justify-content:center}`
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css}</style></head>
<body><div class="poster${lc ? ' dark' : ''}">
  ${rowDecor(p, spec.idx)}
  ${straightDecor(p, lc, spec.idx, leftFrac)}
  <div class="cap"><div class="h1">${spec.headline}</div><div class="sub">${spec.sub}</div></div>
  <div class="stage">${d.html}</div></div></body></html>`
}

// shared SVG decoration primitives
const dStar = (x, y, s, c, o) => `<path d="M0,-10C1.2,-3 3,-1.2 10,0C3,1.2 1.2,3 0,10C-1.2,3 -3,1.2 -10,0C-3,-1.2 -1.2,-3 0,-10Z" transform="translate(${R(x)} ${R(y)}) scale(${s})" fill="${c}" opacity="${o}"/>`
const dPlus = (x, y, s, c, o) => `<path d="M-1.6,-7 H1.6 V-1.6 H7 V1.6 H1.6 V7 H-1.6 V1.6 H-7 V-1.6 H-1.6 Z" transform="translate(${R(x)} ${R(y)}) scale(${s})" fill="${c}" opacity="${o}"/>`
const dDot = (x, y, r, c, o) => `<circle cx="${R(x)}" cy="${R(y)}" r="${r}" fill="${c}" opacity="${o}"/>`

// decorative layer for the panorama: dotted "timeline" arcs, sparkles, plus
// marks + dots scattered to fill the space, and floating time-conversion chips.
function panoDecor(p, W2) {
  const h = p.h
  const svg = `<svg class="decor" viewBox="0 0 ${W2} ${h}" width="${W2}" height="${h}">
    ${dStar(W2 * 0.13, h * 0.20, 2.6, '#2f9412', 0.55)}
    ${dStar(W2 * 0.88, h * 0.16, 3.0, '#ffffff', 0.9)}
    ${dStar(W2 * 0.82, h * 0.46, 2.0, '#1f6c10', 0.5)}
    ${dStar(W2 * 0.10, h * 0.55, 2.2, '#ffffff', 0.85)}
    ${dStar(W2 * 0.93, h * 0.74, 2.4, '#2f9412', 0.5)}
    ${dStar(W2 * 0.07, h * 0.82, 1.8, '#1f6c10', 0.45)}
    ${dStar(W2 * 0.5, h * 0.07, 1.6, '#ffffff', 0.7)}
    ${dPlus(W2 * 0.18, h * 0.40, 2.2, '#2f9412', 0.4)}
    ${dPlus(W2 * 0.9, h * 0.34, 2.0, '#1f6c10', 0.4)}
    ${dPlus(W2 * 0.04, h * 0.30, 1.8, '#2f9412', 0.35)}
    ${dPlus(W2 * 0.78, h * 0.86, 2.0, '#2f9412', 0.4)}
    ${dPlus(W2 * 0.22, h * 0.72, 1.8, '#1f6c10', 0.35)}
    ${dDot(W2 * 0.27, h * 0.16, 6, '#2f9412', 0.4)}
    ${dDot(W2 * 0.73, h * 0.24, 7, '#1f6c10', 0.35)}
    ${dDot(W2 * 0.15, h * 0.66, 6, '#2f9412', 0.4)}
    ${dDot(W2 * 0.85, h * 0.6, 6, '#1f6c10', 0.35)}
    ${dDot(W2 * 0.4, h * 0.9, 7, '#2f9412', 0.35)}
  </svg>`
  return svg
}

// real calculator use cases (from the site), shown as bold rounded pills with
// icons flanking the combo phone (and partially overlapping it).
const ICON = {
  clock: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v4.5l3 1.8"/></svg>',
  receipt: '<svg viewBox="0 0 24 24"><path d="M6 3h12v18l-2.2-1.4-2 1.4-2-1.4-2 1.4L6 21z"/><path d="M9 8h6M9 12h6"/></svg>',
  truck: '<svg viewBox="0 0 24 24"><path d="M3 6.5h11v9H3z"/><path d="M14 9.5h3.6l3 3v3H14z"/><circle cx="7" cy="17.5" r="1.7"/><circle cx="17" cy="17.5" r="1.7"/></svg>',
  play: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M10.5 9.2l4.6 2.8-4.6 2.8z" fill="#fff" stroke="none"/></svg>',
  code: '<svg viewBox="0 0 24 24"><path d="M8.5 8l-4 4 4 4"/><path d="M15.5 8l4 4-4 4"/></svg>',
  coffee: '<svg viewBox="0 0 24 24"><path d="M4 8.5h12V13a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5z"/><path d="M16 9.5h2.4a2.3 2.3 0 0 1 0 4.6H16"/><path d="M7.5 3.5v2M11 3.5v2"/></svg>',
}
const USE_CASES = [
  { label: 'Work timesheets', icon: ICON.clock },
  { label: 'Billing &amp; splits', icon: ICON.receipt },
  { label: 'Driver hours', icon: ICON.truck },
  { label: 'Audio &amp; video', icon: ICON.play },
  { label: 'Developers', icon: ICON.code },
  { label: 'Everyday math', icon: ICON.coffee },
]

// ---- panorama: one angled phone spanning a 2-wide canvas; `half` selects the slice ----
function panoramaHtml(spec, half) {
  const p = PLAT[spec.platform]
  const W2 = p.w * 2
  const left = half === 'left' ? 0 : -p.w
  const sw = R(p.w * (spec.platform === 'ios' ? 0.84 : 0.73))
  const d = device({ p, id: 'pano', sw, dark: false, shot: spec.screenshot })
  const hSize = R(p.w * 0.1), subSize = R(p.w * 0.046), pad = R(p.w * 0.07)
  const ucFs = R(p.w * 0.038)
  // phone edges (so the pills align to them and overlap by `ov` on both platforms)
  const phoneLeft = R((W2 - (sw + R(sw * p.bezel) * 2)) / 2)
  const phoneRight = W2 - phoneLeft
  const ov = R(p.w * 0.05)
  const css = `${FONTFACE}*{margin:0;padding:0;box-sizing:border-box}html,body{width:${p.w}px;height:${p.h}px;overflow:hidden}
.pano{position:absolute;top:0;left:${left}px;width:${W2}px;height:${p.h}px;font-family:'Hanken Grotesk',sans-serif;-webkit-font-smoothing:antialiased;${rowBg(p, 0)}}
.rowdecor{position:absolute;top:0;z-index:0}
.decor{position:absolute;top:0;left:0;z-index:1}
${TYPO}${d.css}
/* frame 1 headline top-left; frame 2 headline BOTTOM-right (frees the top-right
   for the big tilted phone, fills the lower-right corner). */
.capL{position:absolute;z-index:3;left:${pad}px;top:${R(p.h * 0.06)}px;max-width:${R(p.w * 0.47)}px;text-align:left}
.capR{position:absolute;z-index:3;right:${pad}px;bottom:${R(p.h * 0.07)}px;max-width:${R(p.w * 0.47)}px;text-align:right}
.h1{font-size:${hSize}px;line-height:1.0;letter-spacing:-0.03em}.sub{margin-top:${R(subSize * 0.65)}px;font-size:${subSize}px;line-height:1.24}
/* flat tilt, top to the right (clockwise), no perspective; the big phone fits
   whole into the two-frame canvas. The drop-shadow lives on the NON-rotated
   .stage so it falls straight down in screen space (a natural soft shadow)
   rather than tilting into a weird vertical streak. */
.stage{position:absolute;z-index:2;left:${p.w}px;top:50%;transform:translate(-50%,-50%);
  filter:drop-shadow(0 ${R(sw * 0.05)}px ${R(sw * 0.075)}px rgba(20,18,10,.32))}
.phrot{transform:rotateZ(8deg)}
.phrot .dev-pano{box-shadow:0 0 0 1px ${p.rim} inset,0 2px 0 rgba(255,255,255,.06) inset}
.uc{position:absolute;z-index:4;display:flex;align-items:center;gap:.5em;background:linear-gradient(135deg,#37a015,#1d770b);
  color:#fff;border-radius:${R(p.w * 0.026)}px;padding:.52em .95em;font-weight:700;font-size:${ucFs}px;letter-spacing:-0.01em;
  box-shadow:0 ${R(ucFs * 0.5)}px ${R(ucFs * 0.95)}px rgba(20,18,10,.26);white-space:nowrap}
.uc svg{width:1.35em;height:1.35em;flex:none;stroke:#fff;stroke-width:2;fill:none;stroke-linecap:round;stroke-linejoin:round}
.uc.l{right:${W2 - phoneLeft - ov}px}.uc.r{left:${phoneRight - ov}px}`
  const uc = (item, side, ty) => `<div class="uc ${side}" style="top:${R(ty)}px">${item.icon}<span>${item.label}</span></div>`
  const pills = [
    uc(USE_CASES[0], 'l', p.h * 0.43), uc(USE_CASES[1], 'l', p.h * 0.565), uc(USE_CASES[2], 'l', p.h * 0.70),
    uc(USE_CASES[3], 'r', p.h * 0.2), uc(USE_CASES[4], 'r', p.h * 0.335), uc(USE_CASES[5], 'r', p.h * 0.47),
  ].join('')
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css}</style></head>
<body><div class="pano">
  ${rowDecor(p, 0)}
  ${panoDecor(p, W2)}
  ${pills}
  <div class="capL"><div class="h1">${spec.headlineL}</div><div class="sub">${spec.subL}</div></div>
  <div class="capR"><div class="h1">${spec.headlineR}</div><div class="sub">${spec.subR}</div></div>
  <div class="stage"><div class="phrot">${d.html}</div></div></div></body></html>`
}

// ---------- specs ----------
const PANO = {
  headlineL: 'Add &amp;<br>subtract<br><span class="a">time</span>',
  subL: 'Mix hours, minutes,<br>seconds and days,<br>then read the answer.',
  headlineR: 'Convert<br>to <span class="a">any<br>unit</span>',
  subR: 'See it as decimal<br>hours, total minutes<br>or seconds.',
}
const SPECS = [
  { id1: 'ios-01-combo', id2: 'ios-02-combo', platform: 'ios', template: 'panorama', screenshot: 'calc_light_ios.png', ...PANO },
  { id1: 'android-01-combo', id2: 'android-02-combo', platform: 'android', template: 'panorama', screenshot: 'calc_light_android.png', ...PANO },

  // straight frames 3-8 (both platforms)
  // Order chosen so the dark-theme frame lands in the CENTER (idx 4), giving the
  // row gradient a smooth, symmetric light -> dark -> light flow.
  ...['ios', 'android'].flatMap((pf) => [
    { id: `${pf}-03-rate`, idx: 2, platform: pf, template: 'straight', screenshot: 'rate.png', headline: 'Turn time into <span class="a">pay</span>', sub: 'Totals per hour, day, week, month or year.' },
    { id: `${pf}-04-formats`, idx: 3, lightCap: true, platform: pf, template: 'straight', screenshot: 'formats.png', headline: 'See any result <span class="a">your way</span>', sub: 'Decimal hours, total minutes, seconds and more.' },
    { id: `${pf}-05-dark`, idx: 4, lightCap: true, platform: pf, template: 'straight', screenshot: `calc_dark_${pf}.png`, dark: true, headline: 'Easy on the eyes, <span class="a">day or night</span>', sub: 'A full dark theme, free on every platform.' },
    { id: `${pf}-06-keypad`, idx: 5, lightCap: true, platform: pf, template: 'straight', screenshot: 'keypad.png', headline: 'A keypad <span class="a">for your work</span>', sub: 'Presets and per-unit keys you can customize.' },
    { id: `${pf}-07-history`, idx: 6, platform: pf, template: 'straight', screenshot: 'history.png', headline: 'Every total, <span class="a">saved with a note</span>', sub: 'Revisit, copy or edit past calculations.' },
    { id: `${pf}-08-resize`, idx: 7, platform: pf, template: 'straight', screenshot: `resized_${pf}.png`, headline: 'Sized to <span class="a">your hands</span>', sub: 'Drag to grow the display or the keypad.' },
  ]),

  // Android tablet straight frames (10-inch base; 7-inch produced by downscaling).
  ...[
    { id: 'tab-01-calc', idx: 0, screenshot: 'calc_tab_light.png', headline: 'Add &amp; subtract <span class="a">time</span>', sub: 'Mix hours, minutes, seconds and days.' },
    { id: 'tab-02-rate', idx: 1, screenshot: 'rate_tab.png', headline: 'Turn time into <span class="a">pay</span>', sub: 'Totals per hour, day, week, month or year.' },
    { id: 'tab-03-formats', idx: 2, screenshot: 'formats_tab.png', headline: 'See any result <span class="a">your way</span>', sub: 'Decimal hours, total minutes, seconds and more.' },
    { id: 'tab-04-keypad', idx: 3, lightCap: true, screenshot: 'keypad_tab.png', headline: 'A keypad <span class="a">for your work</span>', sub: 'Presets and per-unit keys you can customize.' },
    { id: 'tab-05-dark', idx: 4, lightCap: true, dark: true, screenshot: 'calc_tab_dark.png', headline: 'Easy on the eyes, <span class="a">day or night</span>', sub: 'A full dark theme, free on every platform.' },
    { id: 'tab-06-history', idx: 5, lightCap: true, screenshot: 'history_tab.png', headline: 'Every total, <span class="a">saved with a note</span>', sub: 'Revisit, copy or edit past calculations.' },
    { id: 'tab-07-resize', idx: 6, screenshot: 'resized_tab.png', headline: 'Sized to <span class="a">your hands</span>', sub: 'Drag to grow the display or the keypad.' },
    { id: 'tab-08-convert', idx: 7, screenshot: 'calc_tab_convert.png', headline: 'Convert to <span class="a">any unit</span>', sub: 'See it as decimal hours, total minutes or seconds.' },
  ].map((s) => ({ ...s, platform: 'tablet', template: 'straight' })),

  // Apple iPad 13" straight frames (fully unlocked; dark centered at idx 4).
  ...[
    { id: 'ipad-01-calc', idx: 0, screenshot: 'calc_ipad_light.png', headline: 'Add &amp; subtract <span class="a">time</span>', sub: 'Mix hours, minutes, seconds and days.' },
    { id: 'ipad-02-rate', idx: 1, screenshot: 'rate_ipad.png', headline: 'Turn time into <span class="a">pay</span>', sub: 'Totals per hour, day, week, month or year.' },
    { id: 'ipad-03-formats', idx: 2, screenshot: 'formats_ipad.png', headline: 'See any result <span class="a">your way</span>', sub: 'Decimal hours, total minutes, seconds and more.' },
    { id: 'ipad-04-keypad', idx: 3, lightCap: true, screenshot: 'keypad_ipad.png', headline: 'A keypad <span class="a">for your work</span>', sub: 'Presets and per-unit keys you can customize.' },
    { id: 'ipad-05-dark', idx: 4, lightCap: true, dark: true, screenshot: 'calc_ipad_dark.png', headline: 'Easy on the eyes, <span class="a">day or night</span>', sub: 'A full dark theme, on every device.' },
    { id: 'ipad-06-history', idx: 5, lightCap: true, screenshot: 'history_ipad.png', headline: 'Every total, <span class="a">saved with a note</span>', sub: 'Revisit, copy or edit past calculations.' },
    { id: 'ipad-07-resize', idx: 6, screenshot: 'resized_ipad.png', headline: 'Sized to <span class="a">your screen</span>', sub: 'Drag to grow the display or the keypad.' },
    { id: 'ipad-08-convert', idx: 7, screenshot: 'calc_ipad_convert.png', headline: 'Convert to <span class="a">any unit</span>', sub: 'See it as decimal hours, total minutes or seconds.' },
  ].map((s) => ({ ...s, platform: 'ipad', template: 'straight' })),
]

// Play feature graphic (1024x500): wordmark + tagline (with the millisecond
// range) + use cases, and a fanned stack of phones showing the calculator, rate
// and result-format views. No alpha; focal text kept off the dead edges.
function featureGraphicHtml() {
  const W = 1024, H = 500
  const fp = { w: W, h: H, device: 'galaxy', ar: PHONE_AR, bezel: 0.02, outerR: 0.11, innerR: 0.092, frame: PLAT.android.frame, rim: PLAT.android.rim }
  const icon = `file://${resolve(ROOT, '..', 'site/public/icons/app-logo.png')}`
  const dRate = device({ p: fp, id: 'fgr', sw: R(W * 0.172), dark: false, shot: 'rate.png' })
  const dForm = device({ p: fp, id: 'fgf', sw: R(W * 0.172), dark: false, shot: 'formats.png' })
  const dCalc = device({ p: fp, id: 'fgc', sw: R(W * 0.205), dark: false, shot: 'calc_light_android.png' })
  const decor = `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" preserveAspectRatio="none" style="position:absolute;inset:0;z-index:1">
    <defs><linearGradient id="fgB" x1="0" y1="0" x2="1" y2="0">${gradStops(BAND_STOPS)}</linearGradient></defs>
    <polygon points="0,${R(H * 0.66)} ${W},${R(H * 0.2)} ${W},${R(H * 0.5)} 0,${R(H * 0.96)}" fill="url(#fgB)" opacity="0.5"/>
    <polygon points="0,${R(H * 0.42)} ${W},${R(H * -0.04)} ${W},${R(H * 0.12)} 0,${R(H * 0.58)}" fill="url(#fgB)" opacity="0.32"/>
    ${dStar(W * 0.46, H * 0.12, 2.2, '#2f9412', 0.4)}${dStar(W * 0.07, H * 0.74, 1.8, '#1f6c10', 0.4)}${dPlus(W * 0.43, H * 0.82, 2, '#2f9412', 0.35)}${dDot(W * 0.04, H * 0.3, 5, '#2f9412', 0.35)}${dPlus(W * 0.05, H * 0.5, 1.7, '#1f6c10', 0.32)}${dStar(W * 0.4, H * 0.5, 1.5, '#2f9412', 0.3)}</svg>`
  const ph = (cls, d2, left, top, rot, z) =>
    `<div class="ph" style="left:${left}px;top:${top}px;z-index:${z}"><div class="rot" style="transform:rotate(${rot}deg)">${d2.html}</div></div>`
  const css = `${FONTFACE}*{margin:0;box-sizing:border-box}html,body{width:${W}px;height:${H}px}
.fg{position:relative;width:${W}px;height:${H}px;overflow:hidden;font-family:'Hanken Grotesk',sans-serif;-webkit-font-smoothing:antialiased;
  background:linear-gradient(108deg,#eef2e2 0%,#dceac2 46%,#c2e0aa 100%)}
${dRate.css}${dForm.css}${dCalc.css}
.txt{position:absolute;z-index:5;left:58px;top:0;height:${H}px;display:flex;flex-direction:column;justify-content:space-between;padding:86px 0;max-width:408px}
.brand{display:flex;align-items:center;gap:16px}
.brand img{width:58px;height:58px;display:block}
.brand .wmstack{display:flex;flex-direction:column;line-height:1.02}
.brand .wm{font-weight:800;font-size:41px;letter-spacing:-0.025em;color:#1c1b15}
.brand .wmsub{font-weight:800;font-size:41px;letter-spacing:-0.025em;color:#2f9412}
.tag{font-weight:700;font-size:28px;color:#26331c;letter-spacing:-0.015em;line-height:1.24}
.tag .a{color:#2f9412}
.cases{font-weight:600;font-size:19px;color:#5c7d0e;letter-spacing:.005em}
.ph{position:absolute;filter:drop-shadow(0 14px 24px rgba(20,18,10,.26))}
.ph .dev-fgr,.ph .dev-fgf,.ph .dev-fgc{box-shadow:0 0 0 1px ${fp.rim} inset,0 2px 0 rgba(255,255,255,.06) inset}`
  return `<!doctype html><html><head><meta charset="utf-8"><style>${css}</style></head>
<body><div class="fg">
  ${decor}
  ${ph('rate', dRate, 502, 36, -8, 2)}
  ${ph('form', dForm, 822, 70, 11, 2)}
  ${ph('calc', dCalc, 644, 26, 3, 3)}
  <div class="txt">
    <div class="brand"><img src="${icon}"><div class="wmstack"><span class="wm">Time Calculator</span><span class="wmsub">Cardamon</span></div></div>
    <div class="tag">Add, subtract &amp; convert <span class="a">time</span>,<br>from days to <span class="a">milliseconds</span>.</div>
    <div class="cases">Timesheets · Billing · Audio &amp; video · Code</div>
  </div>
</div></body></html>`
}

function render(p, outName, html) {
  const htmlPath = join(BUILD, `${outName}.html`)
  const rawPath = join(BUILD, `${outName}@2x.png`)
  const outPath = join(ROOT, p.dir, `${outName}.png`)
  writeFileSync(htmlPath, html)
  const args = [
    '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
    '--force-device-scale-factor=2', '--run-all-compositor-stages-before-draw',
    '--virtual-time-budget=3500', `--window-size=${p.w},${p.h}`,
    `--screenshot=${rawPath}`, `file://${htmlPath}`,
  ]
  execSync(`"${CHROME}" ${args.map((a) => `'${a}'`).join(' ')}`, { stdio: 'ignore' })
  execSync(`sips -z ${p.h} ${p.w} "${rawPath}" --out "${outPath}"`, { stdio: 'ignore' })
}

const only = process.argv[2]
const match = (s) => !only || (s.id || s.id1 || '').includes(only) || (s.id2 || '').includes(only)
for (const spec of SPECS.filter(match)) {
  const p = PLAT[spec.platform]
  if (spec.template === 'panorama') {
    render(p, spec.id1, panoramaHtml(spec, 'left'))
    render(p, spec.id2, panoramaHtml(spec, 'right'))
    console.log(`✓ ${spec.id1} + ${spec.id2}  (panorama)`)
  } else {
    render(p, spec.id, straightHtml(spec))
    if (spec.platform === 'tablet') {
      // Android 10-inch is rendered; downscale to the 7-inch set (1200x2133, 9:16).
      // iPad renders straight to its exact store size, so it skips this.
      const src = join(ROOT, p.dir, `${spec.id}.png`)
      execSync(`sips -z 2133 1200 "${src}" --out "${join(ROOT, 'android-tab-7', `${spec.id}.png`)}"`, { stdio: 'ignore' })
    }
    console.log(`✓ ${spec.id}`)
  }
}

if (!only || only === 'feature') {
  const htmlPath = join(BUILD, 'feature.html')
  const rawPath = join(BUILD, 'feature@2x.png')
  writeFileSync(htmlPath, featureGraphicHtml())
  execSync(`"${CHROME}" '--headless=new' '--disable-gpu' '--hide-scrollbars' '--allow-file-access-from-files' '--force-device-scale-factor=2' '--run-all-compositor-stages-before-draw' '--virtual-time-budget=3500' '--window-size=1024,500' '--screenshot=${rawPath}' 'file://${htmlPath}'`, { stdio: 'ignore' })
  execSync(`sips -z 500 1024 "${rawPath}" --out "${join(ROOT, 'feature-graphic.png')}"`, { stdio: 'ignore' })
  console.log('✓ feature-graphic.png (1024x500)')
}
console.log('done')
