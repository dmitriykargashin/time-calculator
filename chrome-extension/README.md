# Time Calculator — Chrome extension

A Manifest V3 extension that adds, subtracts and converts durations. The popup is
built from the website's **real `TimeCalculator.vue` component**, and the math comes
from the **same Dart engine** as the iOS/Android apps and the site. Fully offline,
zero permissions, no network calls.

## Surfaces

- **Side panel** — clicking the toolbar icon opens the calculator in Chrome's
  right-hand side panel (which docks and resizes the page). Chrome draws its own
  title header ("Time Calculator Cardamon", from the page `<title>`), so the panel
  itself is just the site's calculator verbatim (colored-token expression, the
  "Show result as" picker, Copy / Clear / Convert / Rate / History, examples) above
  a footer status bar (theme switch + website / app links). It fills and resizes
  with the panel. (Requires Chrome 114+.)
- **Omnibox** — type the keyword **`tc`** then a duration (`tc 90m * 3`). The live
  result shows in the dropdown; Enter opens the calculator in a tab, prefilled.
- **Themes** — a System / Light / Dark switch in the footer status bar (matches the
  app). It sets `[data-theme]` on `<html>` before paint (no flash), follows the OS
  in System mode, and persists in localStorage. The reused component and panel
  chrome both read the CSS tokens, so switching re-colors everything live.

## Layout

```
chrome-extension/
  manifest.json            # MV3; no permissions, no host_permissions
  package.json             # build script
  icons/                   # 16 / 48 / 128 (transparent green Cardamon clock)
  src/
    engine/time_engine.js  # Dart→JS engine (globalThis.evaluateTime); synced, not hand-edited
    lib/time-bridge.js      # free-form input → engine grammar (for the omnibox worker)
    background.js           # service worker: omnibox handler
    popup/
      panel.html            # side-panel page: #app + footer status bar + scripts
      panel.css             # scroll area / footer status bar + panel fit overrides
      panel-init.js         # clears persisted card width; silences the benign ResizeObserver warning; forces a repaint on open (side-panel stale-paint)
      theme.js              # System/Light/Dark switch (sets [data-theme] pre-paint, follows the OS)
      theme-base.css        # design tokens + fonts (light + dark), mirrored from the site's main.css
      main.ts               # mounts ~/components/TimeCalculator.vue
      *.ttf                 # bundled brand fonts (ABeeZee, Hanken Grotesk)
  build/
    vite.config.mjs         # lib build → dist/popup.js + dist/popup.css
    shims/useTimeEngine.ts  # extension engine loader (drops Nuxt useState)
    shims/useTrack.ts        # no-op analytics
  build.sh                  # assemble a minified, store-ready copy in release/
  dist/                     # BUILT popup.js + popup.css (gitignored; build before load/publish)
  release/                  # BUILT store-ready tree (gitignored; `npm run release`)
  scripts/sync-engine.sh    # rebuild + copy the engine from the shared Dart source
  scripts/pack.sh           # build.sh + zip release/ → ../time-calculator-extension.zip
```

## The popup IS the site component

`src/popup/main.ts` mounts `~/components/TimeCalculator.vue` (the `~` alias points
at `../site/app`), so the popup is the exact same UI as timecalculator.app and stays
in sync. The Nuxt-only pieces are swapped at build time:

- `useTimeEngine()` → `build/shims/useTimeEngine.ts` (loads the engine from the
  extension instead of the site's public root; no `useState`).
- `useTrack()` → `build/shims/useTrack.ts` (no-op — the extension collects nothing).
- The framework-free helpers (`colorize`, `expandColon`, `toClockString`, …) are
  still imported straight from the site's `useTimeEngine.ts`.

Templates are precompiled by `@vitejs/plugin-vue`, so the bundle has **no `eval` /
`new Function`** and satisfies the Manifest V3 CSP. The engine is likewise CSP-clean
and needs no DOM, so it also runs in the omnibox service worker.

## Build

The build reuses the site's already-installed dependencies (`vue`, `vite`,
`@vitejs/plugin-vue`, `unplugin-auto-import`) via a `node_modules` symlink — no
separate install:

```
cd chrome-extension
ln -s ../site/node_modules node_modules   # one-time
npm run build                             # → dist/popup.js + dist/popup.css
```

`npm run build` only rebuilds the Vue popup bundle. Rebuild it after changing the
site component, the shims, or the theme. Rebuild the engine (from the shared Dart
source) with `npm run sync-engine`.

## Release build (`build.sh` → `release/`)

`build.sh` assembles a **Chrome Web Store–ready copy** in `release/` (gitignored):
it runs `npm run build`, then minifies the hand-written runtime files and copies
everything with `manifest.json` at the root and every path the manifest / panel
reference preserved. Load `release/` directly, or zip it with `npm run pack`.

```
npm run release        # prod: UglifyJS (JS) + esbuild (CSS) minify → release/
npm run release:dev    # dev:  same layout, hand-written files left readable
```

What gets minified vs. copied verbatim:

- **Minified:** the hand-written runtime — `background.js`, `lib/time-bridge.js`,
  `popup/{config,panel-init,theme}.js` (UglifyJS, a Web Store–approved minifier),
  and `popup/{panel,theme-base}.css` (esbuild).
- **Copied as-is (already minified by their own toolchains):** `dist/popup.js` +
  `dist/popup.css` (Vite/esbuild) and `src/engine/time_engine.js` (dart2js).

Offline-safe: if UglifyJS/esbuild can't run, that file is copied readable so the
release is always complete.

## Run locally

1. `npm run release` (assembles `release/`), or `npm run build` to load this folder directly.
2. Chrome → `chrome://extensions` → **Developer mode** → **Load unpacked** → `release/` (or this folder).
3. Click the toolbar icon, or type `tc ` in the address bar.

> Reloading after a change: `chrome://extensions` → the **reload** ↻ on the card.
> A `manifest.json` change (name, version) or a fresh `release/` needs this reload
> **and** reopening the side panel — an already-open panel won't hot-swap.

## Publish

`npm run pack` runs the release build and zips `release/`'s **contents** (so
`manifest.json` is at the zip root, which Chrome requires) to
`../time-calculator-extension.zip`. Upload that in the Web Store dashboard. No
permissions are requested, so the store privacy label is "no data collected" and
review is fast. Bump `version` in `manifest.json` per release.

## Footer badges

The footer status bar has the color-theme switch on the left and two store-style
badges on the right, "Get it on Google Play" and "Open it on the Web" (with the
Cardamon logo). They mirror the site's `.store-badge` design: a high-contrast pill
that adapts with the theme (dark pill in light mode, light pill in dark mode). No
ads ship.

If you ever add ads or affiliate offers: keep them inside the panel only (never
injected into other sites), serve them in a remote `<iframe>` (MV3 blocks remote
`<script>`), keep them contextual (Limited Use forbids using user data for
personalized ads), label them, and update the Privacy practices disclosures.

## Notes

- Monetization: the Chrome Web Store dropped built-in payments, so this ships free
  as a funnel to the paid apps. A Pro tier would use external licensing (as in the
  other published extensions) — not wired yet.
- The full site component (Convert / Rate / History / format modal) is dense in a
  toolbar popup; it also opens as a roomy full tab from the omnibox.
