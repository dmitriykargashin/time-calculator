// Builds the extension popup from the site's real TimeCalculator.vue.
// Run from the extension root: `npm run build` (see package.json). Deps (vue,
// @vitejs/plugin-vue, unplugin-auto-import) resolve from ../site/node_modules via
// the node_modules symlink, so no separate install is needed.
//
// Output: dist/popup.js (iife, precompiled templates -> Manifest-V3 CSP-safe,
// no eval) + dist/popup.css (the component's scoped styles). popup.html loads
// theme-base.css (tokens/fonts) + the engine + these two.
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import AutoImport from 'unplugin-auto-import/vite'
import { fileURLToPath } from 'node:url'
import { dirname, resolve } from 'node:path'

const dir = dirname(fileURLToPath(import.meta.url))
const ext = resolve(dir, '..')
const site = resolve(ext, '..', 'site')

export default defineConfig({
  root: ext,
  define: {
    // Vue's bundler build guards dev-only code behind process.env.NODE_ENV; lib
    // mode doesn't auto-replace it, so define it here (also dead-code-eliminates
    // the dev branches and fixes "process is not defined" in the extension).
    'process.env.NODE_ENV': '"production"',
    __VUE_OPTIONS_API__: 'true',
    __VUE_PROD_DEVTOOLS__: 'false',
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: 'false',
  },
  plugins: [
    vue(),
    AutoImport({
      dts: false,
      imports: [
        'vue',
        { vue: ['useTemplateRef'] },
        { [resolve(dir, 'shims/useTimeEngine.ts')]: ['useTimeEngine'] },
        { [resolve(dir, 'shims/useTrack.ts')]: ['useTrack'] },
      ],
    }),
  ],
  resolve: {
    alias: {
      '~': resolve(site, 'app'),
    },
  },
  build: {
    outDir: resolve(ext, 'dist'),
    emptyOutDir: true,
    cssCodeSplit: false,
    minify: true,
    lib: {
      entry: resolve(ext, 'src/popup/main.ts'),
      formats: ['iife'],
      name: 'TCPopup',
      fileName: () => 'popup.js',
      cssFileName: 'popup',
    },
  },
})
