// Chrome Web Store listing image generator — "Time Calculator Cardamon".
//
// Direction: warm botanical editorial. Cream paper, Cardamon green, heavy two-tone
// Hanken headlines, ONE confident product moment per frame, purposeful negative
// space, atmospheric-but-quiet background (soft gradient + faint streaks + a few
// low-opacity accents that stay OUT of the text). The panel is rendered WIDE (so
// the action row never wraps) and shown large; the hero frames it inside a Chrome
// window with the panel docked on the right, so "it's a side panel" reads instantly.
//
//   • 5 screenshots   1280×800   (1 side-panel hero + Convert + Rate + History + Omnibox)
//   • small promo     440×280
//   • marquee promo   1400×560
//   • store icon      128×128
//
// Run: node store-assets/build.mjs   (from chrome-extension/, after `npm run build`)

import { execSync } from 'node:child_process'
import { writeFileSync, mkdirSync, rmSync, readFileSync, copyFileSync, existsSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const EXT = join(__dirname, '..'), REPO = join(EXT, '..'), POPUP = join(EXT, 'src/popup')
const OUT = __dirname, BUILD = join(OUT, '.build')
const CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
const LOGO = join(REPO, 'site/public/icons/app-logo.svg')
const FONT_DISPLAY = join(POPUP, 'ABeeZee-Regular.ttf')
const FONT_BODY = join(POPUP, 'HankenGrotesk.ttf')
const ICON128 = join(EXT, 'icons/icon-128.png')

const C = {
  paper: '#f3efe4', paperDeep: '#ece5d4', card: '#fbf8f0', cardEdge: '#e4dcc8',
  ink: '#1c1b15', inkSoft: '#524d3f', inkFaint: '#8a8472',
  green: '#2f9412', greenBright: '#3da50c', greenDeep: '#1f6c10', ochre: '#b9791a',
}
const R = (n) => Math.round(n)

// Real calculator use cases (from the mobile listing), as green-gradient pills.
const UC_ICON = {
  clock: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v4.5l3 1.8"/></svg>',
  receipt: '<svg viewBox="0 0 24 24"><path d="M6 3h12v18l-2.2-1.4-2 1.4-2-1.4-2 1.4L6 21z"/><path d="M9 8h6M9 12h6"/></svg>',
  truck: '<svg viewBox="0 0 24 24"><path d="M3 6.5h11v9H3z"/><path d="M14 9.5h3.6l3 3v3H14z"/><circle cx="7" cy="17.5" r="1.7"/><circle cx="17" cy="17.5" r="1.7"/></svg>',
  play: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="14" rx="2.5"/><path d="M10.5 9.2l4.6 2.8-4.6 2.8z" fill="#fff" stroke="none"/></svg>',
  code: '<svg viewBox="0 0 24 24"><path d="M8.5 8l-4 4 4 4"/><path d="M15.5 8l4 4-4 4"/></svg>',
  coffee: '<svg viewBox="0 0 24 24"><path d="M4 8.5h12V13a5 5 0 0 1-5 5H9a5 5 0 0 1-5-5z"/><path d="M16 9.5h2.4a2.3 2.3 0 0 1 0 4.6H16"/><path d="M7.5 3.5v2M11 3.5v2"/></svg>',
}
const USE_CASES = [
  { label: 'Work timesheets', icon: 'clock' }, { label: 'Billing &amp; splits', icon: 'receipt' },
  { label: 'Driver hours', icon: 'truck' }, { label: 'Audio &amp; video', icon: 'play' },
  { label: 'Developers', icon: 'code' }, { label: 'Everyday math', icon: 'coffee' },
]
const ucRow = (list, fs) => list.map((c) => `<span class="uc" style="font-size:${fs}px"><svg viewBox="0 0 24 24">${UC_ICON[c.icon]}</svg>${c.label}</span>`).join('')

if (!existsSync(CHROME)) { console.error('Chrome not found at', CHROME); process.exit(1) }
rmSync(BUILD, { recursive: true, force: true }); mkdirSync(BUILD, { recursive: true })

function shoot(htmlPath, w, h, rawPng, vt = 4200) {
  const args = ['--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
    '--force-device-scale-factor=2', '--run-all-compositor-stages-before-draw',
    `--virtual-time-budget=${vt}`, `--window-size=${w},${h}`, `--screenshot=${rawPng}`, `file://${htmlPath}`]
  execSync(`"${CHROME}" ${args.map((a) => `'${a}'`).join(' ')}`, { stdio: 'ignore' })
}
function finish(rawPng, outPng, w, h, crop) {
  const cropExpr = crop ? `im = im.crop((0, 0, ${crop.w * 2}, ${crop.h * 2}))` : 'im = im'
  const py = ['from PIL import Image', `im = Image.open(${JSON.stringify(rawPng)}).convert("RGB")`, cropExpr,
    `im = im.resize((${w}, ${h}), Image.LANCZOS)`, `im.save(${JSON.stringify(outPng)})`].join('\n')
  const pyf = join(BUILD, '_finish.py'); writeFileSync(pyf, py)
  execSync(`python3 ${JSON.stringify(pyf)}`, { stdio: 'inherit' })
}

// ---------- quiet background: gradient + faint streaks + sparse low accents -----

const dStar = (x, y, s, c, o) => `<path d="M0,-10C1.2,-3 3,-1.2 10,0C3,1.2 1.2,3 0,10C-1.2,3 -3,1.2 -10,0C-3,-1.2 -1.2,-3 0,-10Z" transform="translate(${R(x)} ${R(y)}) scale(${s})" fill="${c}" opacity="${o}"/>`
const dPlus = (x, y, s, c, o) => `<path d="M-1.6,-7 H1.6 V-1.6 H7 V1.6 H1.6 V7 H-1.6 V1.6 H-7 V-1.6 H-1.6 Z" transform="translate(${R(x)} ${R(y)}) scale(${s})" fill="${c}" opacity="${o}"/>`
const dDot = (x, y, r, c, o) => `<circle cx="${R(x)}" cy="${R(y)}" r="${r}" fill="${c}" opacity="${o}"/>`

// Scatter a FEW accents, only where they won't touch text/product. `avoid` is a
// list of [x0,y0,x1,y1] px boxes; items landing inside (plus margin) are rejected.
// Opacity is deliberately low and there is no bright white — accents whisper.
function funBg(W, H, seed, avoid = []) {
  let s = ((seed + 1) * 2654435761) % 2147483647; if (s <= 0) s += 2147483646
  const rnd = () => (s = (s * 16807) % 2147483647) / 2147483647
  const cols = [C.green, C.greenDeep, C.ochre]
  const clear = (x, y) => avoid.every(([x0, y0, x1, y1]) => x < x0 - 46 || x > x1 + 46 || y < y0 - 46 || y > y1 + 46)
  let items = '', placed = 0, tries = 0
  while (placed < 12 && tries < 400) {
    tries++
    const x = rnd() * W, y = rnd() * H
    if (!clear(x, y)) continue
    placed++
    const c = cols[Math.floor(rnd() * 3)]
    const o = (0.06 + rnd() * 0.07).toFixed(3)     // 0.06–0.13, very quiet
    const sc = 1.2 + rnd() * 1.4
    const k = Math.floor(rnd() * 3)
    if (k === 0) items += dStar(x, y, sc, c, o)
    else if (k === 1) items += dPlus(x, y, sc * 0.85, c, o)
    else items += dDot(x, y, 4 + rnd() * 4, c, o)
  }
  return `
    <div class="bg-grad"></div>
    <div class="bg-streaks"></div>
    <svg class="bg-accents" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
      <circle cx="${R(W * 0.82)}" cy="${R(H * 0.2)}" r="${R(W * 0.30)}" fill="none" stroke="${C.green}" stroke-width="2" stroke-dasharray="1 ${R(W * 0.02)}" opacity="0.07"/>
      ${items}</svg>`
}

// ---------- render the real panel WIDE (action row never wraps) ---------------

const panelHtml = readFileSync(join(POPUP, 'panel.html'), 'utf8')
const HISTORY_SEED = `localStorage.setItem('tc-history', JSON.stringify([
  {e:'5h 30m + 2h 15m', r:'7 Hours 45 Minutes', f:'Hour Minute', t:Date.now()-7*60000},
  {e:'40h - 6h 30m', r:'33 Hours 30 Minutes', f:'Hour Minute', t:Date.now()-52*60000},
  {e:'2d 6h + 18h', r:'3 Days 0 Hours', f:'Day Hour', t:Date.now()-3*3600000},
  {e:'3d 4h / 2', r:'1 Day 14 Hours', f:'Day Hour', t:Date.now()-26*3600000},
  {e:'45m * 12', r:'9 Hours', f:'Hour', t:Date.now()-2*86400000}
]));`

function renderPanel(st) {
  const W = st.w || 720, H = st.h || 760
  const histSetup = st.seedHistory ? HISTORY_SEED : "localStorage.removeItem('tc-history');"
  const head = `<script>try{localStorage.setItem('tc-theme',${JSON.stringify(st.theme)});${histSetup}}catch(e){}</script>`
  // Wait-until state machine (robust to virtual-time frame jitter): set the
  // expression, then keep clicking the action button until its panel actually
  // appears, then fill the amount once its input exists, then scroll + settle.
  const actions = `
  <script>
  (function(){
    var EXPR=${JSON.stringify(st.expr || null)}, OPEN=${JSON.stringify(st.open || null)},
        AMOUNT=${JSON.stringify(st.amount || null)}, SCROLL=${st.scrollToPanel ? 'true' : 'false'};
    var setV=function(el,v){var s=Object.getOwnPropertyDescriptor(el.constructor.prototype,'value').set;s.call(el,v);el.dispatchEvent(new Event('input',{bubbles:true}));};
    var exprDone=!EXPR, opened=!OPEN, amtDone=!AMOUNT, settle=0;
    function tick(){
      var app=document.getElementById('app'); var acts=app?app.querySelectorAll('.actions .act'):[];
      if(acts.length<5){ return requestAnimationFrame(tick); }
      if(!exprDone){ var ta=app.querySelector('.expr-input'); if(ta) setV(ta,EXPR); exprDone=true; return requestAnimationFrame(tick); }
      if(!opened){
        if(!app.querySelector('.panel')){ var b=[].slice.call(acts).filter(function(x){return x.textContent.trim().indexOf(OPEN)===0;})[0]; if(b) b.click(); return requestAnimationFrame(tick); }
        opened=true; return requestAnimationFrame(tick);
      }
      if(!amtDone){ var inp=app.querySelector('.per-amt input, .per-inputs input'); if(inp){ setV(inp,AMOUNT); amtDone=true; } return requestAnimationFrame(tick); }
      if(SCROLL){ var pan=app.querySelector('.panel'); if(pan) app.scrollTop=Math.max(0, pan.offsetTop-14); }
      if(++settle<14){ return requestAnimationFrame(tick); }
    }
    requestAnimationFrame(tick);
  })();
  </script>`
  const inner = panelHtml.replace('<head>', '<head>\n' + head).replace('</body>', actions + '\n</body>')
  writeFileSync(join(POPUP, '_shot_inner.html'), inner)
  writeFileSync(join(POPUP, '_shot_wrap.html'), `<!doctype html><html><head><meta charset="utf-8"><style>
    html,body{margin:0;background:#fff}iframe{border:0;display:block;width:${W}px;height:${H}px}
  </style></head><body><iframe src="_shot_inner.html"></iframe></body></html>`)
  const raw = join(BUILD, `panel-${st.id}.raw.png`), out = join(BUILD, `panel-${st.id}.png`)
  shoot(join(POPUP, '_shot_wrap.html'), W + 40, H + 20, raw, 9000)
  finish(raw, out, W, H, { w: W, h: H })
  rmSync(join(POPUP, '_shot_inner.html')); rmSync(join(POPUP, '_shot_wrap.html'))
  return { png: out, w: W, h: H }
}

const STATES = [
  { id: 'light', theme: 'light', w: 720, h: 660 },
  { id: 'convert', theme: 'light', expr: '2d 6h 30m', open: 'Convert', w: 720, h: 940 },
  { id: 'rate', theme: 'light', expr: '40 h', open: 'Rate', amount: '800', w: 720, h: 980 },
  { id: 'history', theme: 'light', open: 'History', seedHistory: true, scrollToPanel: true, w: 720, h: 940 },
]
const P = {}
for (const st of STATES) { console.log('· panel', st.id); P[st.id] = renderPanel(st) }

// ---------- composition chrome ------------------------------------------------

function head() {
  return `<meta charset="utf-8"><style>
  @font-face{font-family:'ABeeZee';src:url('file://${FONT_DISPLAY}') format('truetype');font-weight:400}
  @font-face{font-family:'Hanken';src:url('file://${FONT_BODY}') format('truetype');font-weight:100 900}
  *,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
  html,body{width:100%;height:100%}
  .stage{position:relative;width:100%;height:100%;overflow:hidden;font-family:'Hanken',sans-serif;color:${C.ink}}
  .bg-grad{position:absolute;inset:0;background:linear-gradient(118deg,#f4f2e9 0%,#e7efd6 52%,#d3e6b6 100%)}
  .bg-streaks{position:absolute;inset:-25%;background:
    repeating-linear-gradient(118deg, rgba(255,255,255,.28) 0 3px, rgba(255,255,255,0) 3px 11px),
    repeating-linear-gradient(118deg, rgba(255,255,255,.13) 0 84px, rgba(255,255,255,0) 84px 196px)}
  .bg-accents{position:absolute;inset:0}
  .layer{position:absolute;inset:0;z-index:2}
  .h1{font-family:'Hanken';font-weight:800;letter-spacing:-0.03em;line-height:1.0;color:${C.ink}}
  .h1 .a{color:${C.greenDeep}}
  .kick{font-family:'Hanken';font-weight:800;letter-spacing:.16em;text-transform:uppercase;color:${C.green}}
  .sub{font-family:'Hanken';font-weight:500;color:${C.inkSoft};letter-spacing:-0.004em}
  .brand{display:flex;align-items:center;gap:19px}
  .brand img{width:var(--ls,80px);height:var(--ls,80px);display:block}
  .brand b{font-family:'Hanken';font-weight:800;font-size:var(--wb,38px);letter-spacing:-0.026em;color:${C.ink};line-height:1}
  .brand span{font-family:'Hanken';font-weight:800;font-size:var(--ws,19px);letter-spacing:.17em;text-transform:uppercase;color:${C.green};display:block;margin-top:4px}
  .pill{font-family:'Hanken';font-weight:700;background:${C.card};border:1px solid ${C.cardEdge};border-radius:999px;color:${C.greenDeep}}
  .uc-row{display:flex;flex-wrap:wrap;gap:11px}
  .uc{display:inline-flex;align-items:center;gap:.52em;background:linear-gradient(135deg,#37a015,#1d770b);color:#fff;
      border-radius:999px;padding:.52em 1.05em;font-family:'Hanken';font-weight:700;white-space:nowrap;box-shadow:0 8px 18px -10px rgba(28,54,18,.6)}
  .uc svg{width:1.32em;height:1.32em;flex:none;stroke:#fff;stroke-width:2;fill:none;stroke-linecap:round;stroke-linejoin:round}
  /* side-panel window frame (the extension's own chrome) */
  .win{position:absolute;border-radius:26px;overflow:hidden;background:${C.card};border:1px solid ${C.cardEdge};
       box-shadow:0 60px 120px -38px rgba(28,54,18,.5),0 16px 36px -18px rgba(28,54,18,.34)}
  .win-bar{display:flex;align-items:center;gap:12px;height:var(--bar,50px);padding:0 18px;background:${C.paperDeep};border-bottom:1px solid ${C.cardEdge}}
  .win-bar img{width:23px;height:23px}.win-bar b{font-family:'ABeeZee';font-size:17px;color:${C.inkSoft};font-weight:400}
  .win-bar .dots{margin-left:auto;color:${C.inkFaint};letter-spacing:2px;font-size:20px}
  .win .shot{display:block;width:100%}
  </style>`
}
function brand(ls = 80, wb = 38, ws = 19) {
  return `<div class="brand" style="--ls:${ls}px;--wb:${wb}px;--ws:${ws}px"><img src="file://${LOGO}" alt=""><div><b>Time Calculator</b><span>Cardamon</span></div></div>`
}
// A framed panel window. `showH` = px of the (720-wide) panel to reveal from top.
// `shadow` overrides the default .win drop-shadow — needed on the short marquee,
// where the big shadow would extend past the 560px canvas and clip.
function win(src, x, y, dispW, showH, bar = 50, right = false, shadow = null) {
  const scale = dispW / src.w
  const shotH = R(showH * scale)
  const sh = shadow ? `box-shadow:${shadow};` : ''
  return `<div class="win" style="${sh}width:${dispW}px;top:${y}px;${right ? 'right' : 'left'}:${x}px">
    <div class="win-bar" style="--bar:${bar}px"><img src="file://${LOGO}" alt=""><b>Time Calculator Cardamon</b><span class="dots">⋮</span></div>
    <img class="shot" src="file://${src.png}" style="height:${shotH}px;object-fit:cover;object-position:top">
  </div>`
}
function page(w, h, body, seed, avoid) {
  return `<!doctype html><html><head>${head()}</head><body><div class="stage">${funBg(w, h, seed, avoid)}<div class="layer">${body}</div></div></body></html>`
}
function render(html, w, h, outPng, vt) {
  const raw = join(BUILD, '_c.raw.png')
  // Headless clamps the layout viewport to a ~500px minimum, so a sub-500 window
  // lays out wider than it captures — content centers in ~500 and gets clipped/
  // offset in the narrower output. For narrow canvases, render inside an iframe
  // (which honors the true width) within a >clamp wrapper, then crop the top-left.
  if (w < 520) {
    writeFileSync(join(BUILD, '_c_inner.html'), html)
    writeFileSync(join(BUILD, '_c.html'), `<!doctype html><html><head><meta charset="utf-8"><style>*{margin:0}html,body{background:#fff}iframe{border:0;display:block;width:${w}px;height:${h}px}</style></head><body><iframe src="_c_inner.html"></iframe></body></html>`)
    shoot(join(BUILD, '_c.html'), 560, h + 40, raw, vt)
    finish(raw, outPng, w, h, { w, h })
  } else {
    const p = join(BUILD, '_c.html'); writeFileSync(p, html)
    shoot(p, w, h, raw, vt); finish(raw, outPng, w, h)
  }
}

const SW = 1280, SH = 800

// Single: big two-tone headline left, one wide panel right. Balanced, space filled.
function single({ out, seed, kicker, headline, sub, src, showH, panelW = 566, cases = [] }) {
  const scale = panelW / src.w, winH = R(showH * scale) + 50
  const px = SW - panelW - 40, py = R((SH - winH) / 2)
  const hx = 84, hw = px - hx - 34
  const chips = cases.length ? `<div class="uc-row" style="margin-top:38px;max-width:${hw}px">${ucRow(cases, 17)}</div>` : ''
  const body = `
    <div style="position:absolute;left:${hx}px;top:64px">${brand()}</div>
    <div style="position:absolute;left:${hx}px;top:${R(SH * 0.28)}px;width:${hw}px">
      <div class="kick" style="font-size:21px;margin-bottom:22px">${kicker}</div>
      <div class="h1" style="font-size:84px">${headline}</div>
      <div class="sub" style="font-size:31px;line-height:1.42;margin-top:28px">${sub}</div>
      ${chips}
    </div>
    ${win(src, 40, py, panelW, showH, 50, true)}`
  render(page(SW, SH, body, seed, [[hx, 64, px, 780]]), SW, SH, out)
}

// Hero: a Chrome window with the calculator docked as a right-hand side panel.
// The docked panel shows the FULL width (scaled down, so the action row stays on
// one line) — width:100% + height:auto, never object-fit:cover, so nothing is
// cropped horizontally.
function heroSidePanel({ out, seed }) {
  const sidebarW = 420, pageW = 624, winW = sidebarW + pageW
  const barB = 46, barP = 38
  const panelDispH = R(P.light.h * (sidebarW / P.light.w)) // full panel height at sidebarW
  const rowH = barP + panelDispH, winH = barB + rowH
  const wx = R((SW - winW) / 2), wy = 282
  const dot = (c) => `<span style="width:13px;height:13px;border-radius:50%;background:${c};display:inline-block"></span>`
  const bar1 = (w, t, c = '#d7d3c6') => `<div style="height:11px;width:${w}px;border-radius:6px;background:${c};margin-top:${t}px"></div>`
  const body = `
    <div style="position:absolute;left:0;right:0;top:66px;text-align:center"><div style="display:inline-block">${brand(64, 32, 17)}</div></div>
    <div style="position:absolute;left:0;right:0;top:156px;text-align:center;padding:0 100px">
      <div class="h1" style="font-size:62px">It lives in your <span class="a">side panel</span></div>
      <div class="sub" style="font-size:27px;margin-top:15px">Docked beside any tab. Add, subtract and convert time without leaving the page.</div>
    </div>
    <div class="win" style="width:${winW}px;left:${wx}px;top:${wy}px;border-radius:20px">
      <div style="display:flex;align-items:center;gap:9px;height:${barB}px;padding:0 18px;background:#e6e1d6;border-bottom:1px solid ${C.cardEdge}">
        ${dot('#e8705a')}${dot('#e8b84b')}${dot('#5bbf5b')}
        <div style="margin-left:16px;flex:1;max-width:520px;height:26px;border-radius:999px;background:#faf8f2;border:1px solid ${C.cardEdge};display:flex;align-items:center;padding:0 14px;font-family:'Hanken';font-size:13px;color:${C.inkFaint}">example.com</div>
      </div>
      <div style="display:flex;height:${rowH}px">
        <div style="width:${pageW}px;padding:32px 42px;background:#fffdf8;overflow:hidden">
          ${bar1(224, 0, C.green)}${bar1(500, 22)}${bar1(470, 13)}${bar1(430, 13)}
          <div style="height:152px;border-radius:12px;background:#eef1e6;margin-top:26px"></div>
          ${bar1(490, 24)}${bar1(450, 13)}${bar1(360, 13)}
        </div>
        <div style="width:${sidebarW}px;border-left:1px solid ${C.cardEdge};background:${C.card}">
          <div style="display:flex;align-items:center;gap:10px;height:${barP}px;padding:0 14px;background:${C.paperDeep};border-bottom:1px solid ${C.cardEdge}">
            <img src="file://${LOGO}" style="width:18px;height:18px"><b style="font-family:'ABeeZee';font-size:14px;color:${C.inkSoft};font-weight:400">Time Calculator Cardamon</b><span style="margin-left:auto;color:${C.inkFaint}">⋮</span>
          </div>
          <div style="height:${panelDispH}px;overflow:hidden"><img src="file://${P.light.png}" style="display:block;width:100%;height:auto"></div>
        </div>
      </div>
    </div>`
  render(page(SW, SH, body, seed, [[wx, 150, wx + winW, wy + winH]]), SW, SH, out)
}

function omnibox({ out, seed }) {
  const bx = 84, bw = 1010
  const body = `
    <div style="position:absolute;left:${bx}px;top:64px">${brand()}</div>
    <div style="position:absolute;left:${bx}px;top:${R(SH * 0.30)}px;width:${bw}px">
      <div class="kick" style="font-size:21px;margin-bottom:20px">Omnibox</div>
      <div class="h1" style="font-size:84px">Type it in the <span class="a">address bar</span></div>
      <div class="sub" style="font-size:31px;margin-top:20px">Press <b style="color:${C.greenDeep}">tc</b>, then your expression. The answer appears as you type.</div>
      <div style="margin-top:50px;width:${bw}px;background:${C.card};border:1px solid ${C.cardEdge};border-radius:34px;box-shadow:0 46px 100px -32px rgba(28,54,18,.5);overflow:hidden">
        <div style="display:flex;align-items:center;gap:18px;padding:24px 30px">
          <svg width="30" height="30" viewBox="0 0 24 24" fill="none" stroke="${C.inkFaint}" stroke-width="2" stroke-linecap="round"><circle cx="11" cy="11" r="7"/><path d="M21 21l-4.3-4.3"/></svg>
          <div style="font-family:'ABeeZee';font-size:35px;color:${C.ink}"><span style="background:${C.green};color:${C.paper};border-radius:9px;padding:4px 15px;font-size:27px;vertical-align:3px">tc</span>&nbsp; 90m * 3</div>
        </div>
        <div style="display:flex;align-items:center;gap:18px;padding:24px 30px;border-top:1px solid ${C.cardEdge};background:${C.paperDeep}">
          <img src="file://${LOGO}" style="width:30px;height:30px">
          <div style="font-family:'ABeeZee';font-size:33px"><b style="color:${C.greenDeep}">= 4 Hours 30 Minutes</b><span style="color:${C.inkFaint};font-family:'Hanken';font-size:24px">&nbsp;&nbsp;·&nbsp;&nbsp;Enter to open</span></div>
        </div>
      </div>
    </div>`
  render(page(SW, SH, body, seed, [[bx, 64, bx + bw, 720]]), SW, SH, out)
}

console.log('· screenshots')
heroSidePanel({ out: join(OUT, 'screenshot-1.png'), seed: 11 })
single({ out: join(OUT, 'screenshot-2.png'), seed: 2, src: P.convert, showH: 812, panelW: 560,
  kicker: 'Convert', headline: 'Every unit,<br><span class="a">one tap away</span>',
  sub: 'Read any result as days, hours, minutes, seconds — down to milliseconds. Tap a row to copy.',
  cases: [USE_CASES[3], USE_CASES[4]] })
single({ out: join(OUT, 'screenshot-3.png'), seed: 3, src: P.rate, showH: 872, panelW: 560,
  kicker: 'Rate', headline: 'Turn a duration<br><span class="a">into a rate</span>',
  sub: 'Pay, speed, data — anything per unit of time. See what it adds up to over your duration.',
  cases: [USE_CASES[1], USE_CASES[2]] })
single({ out: join(OUT, 'screenshot-4.png'), seed: 4, src: P.history, showH: 820, panelW: 560,
  kicker: 'History', headline: 'Every total,<br><span class="a">saved</span>',
  sub: 'Star a result to keep it. Revisit, reopen or reuse any past calculation.',
  cases: [USE_CASES[0], USE_CASES[5]] })
omnibox({ out: join(OUT, 'screenshot-5.png'), seed: 5 })

// ---------- promo tiles + icon ------------------------------------------------

console.log('· promo tiles')
// Small tile (the storefront thumbnail): lead with the real calculator UI. The
// panel's own card fills the frame — colored expression, big green result, the
// action row — with the extension's title bar for instant brand recognition.
render(page(440, 280, `
  <div style="position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:15px">
    <div style="width:398px;border-radius:17px;overflow:hidden;background:${C.card};border:1px solid ${C.cardEdge};box-shadow:0 24px 50px -18px rgba(28,54,18,.55)">
      <div style="display:flex;align-items:center;gap:9px;height:33px;padding:0 14px;background:${C.paperDeep};border-bottom:1px solid ${C.cardEdge}">
        <img src="file://${LOGO}" style="width:18px;height:18px"><b style="font-family:'ABeeZee';font-size:13.5px;color:${C.inkSoft};font-weight:400">Time Calculator Cardamon</b><span style="margin-left:auto;color:${C.inkFaint};font-size:14px">⋮</span>
      </div>
      <div style="height:172px;overflow:hidden"><img src="file://${P.light.png}" style="display:block;width:100%;height:auto"></div>
    </div>
    <div style="font-family:'Hanken';font-weight:800;font-size:15px;letter-spacing:-0.008em;color:${C.greenDeep};text-align:center">Add · subtract · multiply · divide · convert</div>
  </div>
`, 7, [[20, 18, 420, 262]]), 440, 280, join(OUT, 'promo-small-440x280.png'))

// Marquee: wide panel (one-line action row) large on the right, headline left.
render(page(1400, 560, `
  <div style="position:absolute;left:100px;top:58px">${brand(64, 33, 17)}</div>
  <div style="position:absolute;left:100px;top:198px;width:592px">
    <div class="h1" style="font-size:74px">Add, subtract &amp;<br><span class="a">convert time</span></div>
    <div class="sub" style="font-size:26px;margin-top:22px">A keyboard-friendly duration calculator in Chrome’s side panel and address bar.</div>
    <div class="uc-row" style="margin-top:28px">${ucRow([USE_CASES[0], USE_CASES[1], USE_CASES[3]], 17)}</div>
    <div style="font-family:'Hanken';font-weight:700;font-size:18px;color:${C.greenDeep};margin-top:16px">Free · Works offline · No sign-in</div>
  </div>
  ${win(P.light, 74, 84, 604, 396, 48, true, '0 24px 54px -28px rgba(28,54,18,.5), 0 9px 22px -14px rgba(28,54,18,.32)')}
`, 6, [[100, 58, 700, 500], [718, 78, 1338, 476]]), 1400, 560, join(OUT, 'promo-marquee-1400x560.png'))

copyFileSync(ICON128, join(OUT, 'store-icon-128.png'))
console.log('\n✓ store assets written to store-assets/')
