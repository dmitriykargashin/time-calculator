#!/usr/bin/env bash
# Produce a Chrome Web Store-ready zip. Runs the full release build (./build.sh),
# then zips the ./release/ folder CONTENTS so manifest.json sits at the zip ROOT
# (Chrome requires that). Whatever build.sh assembled is what ships — no separate
# file list to keep in sync. Upload the resulting zip in the Web Store dashboard.
#
# Usage: ./scripts/pack.sh [prod|dev]   (defaults to prod)
set -euo pipefail

EXT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$EXT_DIR"
MODE="${1:-prod}"

# 1) assemble ./release/ (vite build + minify + copy)
bash build.sh "$MODE"

# 2) zip the release CONTENTS (manifest at root), not the folder itself.
OUT="$EXT_DIR/../time-calculator-extension.zip"
rm -f "$OUT"
( cd release && zip -rq "$OUT" . -x '*.DS_Store' )

echo ""
echo "✓ packaged -> $OUT"
echo "contents:"
unzip -l "$OUT" | awk 'NR>3 && $4 {print "  " $4}' | grep -v '^\s*----'
