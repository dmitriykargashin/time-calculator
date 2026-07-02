#!/usr/bin/env bash
# Keep the extension's copy of the time engine in lockstep with the apps/site.
# The engine is built from the SHARED Dart source by the site's own sync script
# (dart compile js flutter_app/web_engine/time_engine_bridge.dart). Here we just
# rebuild that (if dart is available) and copy the result into the extension, so
# there is a single source of truth for the math.
set -euo pipefail

EXT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$(cd "$EXT_DIR/../site" && pwd)"
SRC="$SITE_DIR/public/engine/time_engine.js"
DEST="$EXT_DIR/src/engine/time_engine.js"

# Rebuild from Dart when possible (no-op if dart isn't installed).
if [ -x "$SITE_DIR/scripts/sync-engine.sh" ]; then
  bash "$SITE_DIR/scripts/sync-engine.sh" || echo "note: site engine rebuild skipped (dart missing?) — copying the committed engine"
fi

if [ ! -f "$SRC" ]; then
  echo "error: $SRC not found — build the site engine first" >&2
  exit 1
fi

cp "$SRC" "$DEST"

# The extension doesn't ship the source map, so drop the dangling
# //# sourceMappingURL=time_engine.js.map reference (it would 404 in the panel /
# service worker). Handle both BSD (macOS) and GNU sed.
sed -i '' '/sourceMappingURL=time_engine.js.map/d' "$DEST" 2>/dev/null \
  || sed -i '/sourceMappingURL=time_engine.js.map/d' "$DEST"

echo "✓ engine synced -> $DEST ($(du -h "$DEST" | cut -f1))"
