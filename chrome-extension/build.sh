#!/usr/bin/env bash
# Build a Chrome Web Store–ready copy of the extension into ./release/.
#
# Usage: ./build.sh [prod|dev]
#   prod (default) — minify the hand-written runtime JS with UglifyJS (a Web
#                    Store–approved minifier) and the two hand-written CSS files
#                    with esbuild. Ships smaller, less trivially readable source.
#   dev            — copy the hand-written files readable (easier to debug a
#                    loaded build). Same file layout either way.
#
# What is and isn't minified:
#   - dist/popup.js, dist/popup.css   already minified by Vite/esbuild (npm run build)
#   - src/engine/time_engine.js       already minified by dart2js
#   These are copied verbatim. Only the small hand-written files get processed.
#
# The output mirrors the source paths so manifest.json (at the release root) and
# panel.html's relative refs resolve unchanged. Load ./release/ via
# chrome://extensions → Load unpacked, or zip it with `npm run pack`.
set -euo pipefail

EXT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$EXT_DIR"
MODE="${1:-prod}"
OUT="release"

if [ "$MODE" != "prod" ] && [ "$MODE" != "dev" ]; then
  echo "usage: ./build.sh [prod|dev]" >&2; exit 2
fi
echo "🚀 Building Time Calculator Cardamon extension ($MODE)…"

# 1) Vue popup bundle (production-minified by Vite/esbuild) → dist/popup.{js,css}
echo "📦 vite build → dist/…"
npm run build >/dev/null

# 2) Fresh release tree, mirroring the paths the manifest + panel.html expect.
echo "🧹 Reset ./$OUT/…"
rm -rf "$OUT"
mkdir -p "$OUT"/icons "$OUT"/dist "$OUT"/src/engine "$OUT"/src/lib "$OUT"/src/popup

# 3) Already-minified + static assets: copy verbatim.
echo "📁 Copy prebuilt + static assets…"
cp manifest.json "$OUT/"
cp icons/icon-16.png icons/icon-48.png icons/icon-128.png "$OUT/icons/"
cp dist/popup.js dist/popup.css "$OUT/dist/"
cp src/engine/time_engine.js "$OUT/src/engine/"
cp src/popup/panel.html "$OUT/src/popup/"
cp src/popup/ABeeZee-Regular.ttf src/popup/HankenGrotesk.ttf "$OUT/src/popup/"

# --- helpers ------------------------------------------------------------------
# Minify one JS file with UglifyJS; fall back to a plain copy if uglify can't run
# (offline / npx failure) so the release is always complete and loadable.
minify_js() {
  local in="$1" out="$OUT/$1"
  if [ "$MODE" = "prod" ] && [ "${UGLIFY_OK:-0}" = "1" ]; then
    if npx --yes uglify-js "$in" --compress --mangle --output "$out" 2>/dev/null; then
      echo "   ⚡ min  $in"; return
    fi
    echo "   ⚠️  uglify failed on $in — copying readable"
  fi
  cp "$in" "$out"; echo "   📄 copy $in"
}
# Minify one CSS file with esbuild (already a dependency via Vite); copy on failure.
minify_css() {
  local in="$1" out="$OUT/$1"
  if [ "$MODE" = "prod" ] && [ -x node_modules/.bin/esbuild ]; then
    if node_modules/.bin/esbuild "$in" --minify --outfile="$out" --log-level=silent 2>/dev/null; then
      echo "   ⚡ min  $in"; return
    fi
    echo "   ⚠️  esbuild failed on $in — copying readable"
  fi
  cp "$in" "$out"; echo "   📄 copy $in"
}

# 4) Hand-written runtime JS + CSS.
UGLIFY_OK=0
if [ "$MODE" = "prod" ]; then
  if npx --yes uglify-js --version >/dev/null 2>&1; then UGLIFY_OK=1
  else echo "   ⚠️  uglify-js unavailable (offline?) — JS will be copied readable"; fi
  echo "🔒 Minifying hand-written source…"
else
  echo "📝 Copying hand-written source (readable)…"
fi
minify_js  src/background.js
minify_js  src/lib/time-bridge.js
minify_js  src/popup/panel-init.js
minify_js  src/popup/theme.js
minify_css src/popup/panel.css
minify_css src/popup/theme-base.css

# 5) Summary.
total="$(find "$OUT" -type f -exec cat {} + | wc -c | tr -d ' ')"
count="$(find "$OUT" -type f | wc -l | tr -d ' ')"
echo ""
echo "📊 ./$OUT/ assembled — $((total / 1024)) KB across $count files"
echo "✅ Build complete ($MODE)."
echo "   • Test:    chrome://extensions → Developer mode → Load unpacked → ./$OUT/"
echo "   • Package: npm run pack   (zips ./$OUT/ with manifest at the root)"
