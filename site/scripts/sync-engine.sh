#!/usr/bin/env bash
# Recompile the SHARED Dart time engine into the site, so the website math is
# identical to the mobile apps. Run this after changing flutter_app/lib/engine/**
# (or the bridge) — the generated JS is committed and served by Vercel (whose
# build has no Dart SDK).
#
#   npm run sync-engine
set -euo pipefail

SITE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BRIDGE="$SITE_DIR/../flutter_app/web_engine/time_engine_bridge.dart"
OUT="$SITE_DIR/public/engine/time_engine.js"

if ! command -v dart >/dev/null 2>&1; then
  echo "ERROR: the Dart SDK (from Flutter) must be on PATH to sync the engine." >&2
  exit 1
fi

echo "Compiling Dart engine → $OUT"
dart compile js "$BRIDGE" -o "$OUT" -O2
echo "✓ engine synced. Commit public/engine/time_engine.js so Vercel serves it."
