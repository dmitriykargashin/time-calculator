#!/usr/bin/env bash
# Build the App Store IPA and backfill any missing framework dSYMs.
#
# Why: Flutter's native-assets pipeline builds Dart-FFI frameworks like
# `objective_c.framework` but does NOT copy their dSYMs into the Xcode archive,
# so App Store Connect warns "the archive did not include a dSYM for
# objective_c.framework". The framework binaries keep their DWARF UUID, so we
# regenerate the dSYM with `dsymutil` and drop it into the archive's dSYMs/
# folder. Upload from the archive (Xcode Organizer → Distribute App) and the
# warning is gone.
#
# This loops over EVERY embedded framework and only fills in the ones the archive
# is missing, so it self-heals for any future native-assets framework too.
#
# Usage (from flutter_app/):
#   ./scripts/build_ios_ipa.sh              # normal App Store build
#   ./scripts/build_ios_ipa.sh --obfuscate --split-debug-info=build/symbols
set -euo pipefail

cd "$(dirname "$0")/.."

# Guard: the app shows its version from the hardcoded kAppVersionCode
# (lib/config.dart — no package_info_plus, by design), so it MUST match the
# pubspec build number or Settings prints the wrong version (as build 29 did).
PUB_CODE="$(grep -E '^version:' pubspec.yaml | sed -E 's/.*\+([0-9]+).*/\1/')"
CFG_CODE="$(grep -E 'const int kAppVersionCode' lib/config.dart | grep -oE '[0-9]+' | head -1)"
if [ "$PUB_CODE" != "$CFG_CODE" ]; then
  echo "❌ Version mismatch: pubspec build +$PUB_CODE != kAppVersionCode $CFG_CODE (lib/config.dart)."
  echo "   Bump BOTH to the same number before building."
  exit 1
fi
echo "🔢 Build +$PUB_CODE — kAppVersionCode in sync."

echo "📦 flutter build ipa (App Store)…"
flutter build ipa --export-method app-store "$@"

ARCH="build/ios/archive/Runner.xcarchive"
APP="$ARCH/Products/Applications/Runner.app"
DSYMS="$ARCH/dSYMs"

if [ ! -d "$APP/Frameworks" ]; then
  echo "⚠️  No Frameworks folder in the archive — nothing to backfill."
  exit 0
fi

echo "🔧 Backfilling missing framework dSYMs…"
mkdir -p "$DSYMS"
added=0
for fw in "$APP/Frameworks/"*.framework; do
  [ -d "$fw" ] || continue
  name="$(basename "$fw" .framework)"
  bin="$fw/$name"
  dsym="$DSYMS/$name.framework.dSYM"
  if [ -f "$bin" ] && [ ! -d "$dsym" ]; then
    if dsymutil "$bin" -o "$dsym" 2>/dev/null; then
      uuid="$(dwarfdump --uuid "$dsym" 2>/dev/null | awk 'NR==1{print $2}')"
      echo "   ✓ added $name.framework.dSYM ($uuid)"
      added=$((added + 1))
    else
      echo "   ⚠️  dsymutil could not build a dSYM for $name — skipping"
    fi
  fi
done
echo "   $added dSYM(s) backfilled."

echo ""
echo "✅ Done. Upload via Xcode Organizer (Distribute App → App Store Connect)"
echo "   so the archive's dSYMs — including the backfilled ones — go with it:"
echo "   $ARCH"
