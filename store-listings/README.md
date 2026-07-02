# store-listings

Private asset workspace for the **Google Play** and **Apple App Store** listings.
Not part of the website, never served from `site/public`. It holds the source
templates and the final, store-ready listing images.

## Layout

```
store-listings/
  src/
    build.mjs        # generator: HTML poster -> headless Chrome (2x) -> sips downscale
    fonts/           # Hanken Grotesk (captions)
    screens/         # real-app captures copied from flutter_app/test/goldens/store/
  android/           # Play phone,   1080 x 1920  (9:16)      — 8 frames
  android-tab-10/    # Play 10" tab, 1800 x 3200  (9:16)      — 8 frames
  android-tab-7/     # Play 7" tab,  1200 x 2133  (9:16)      — 8 frames (downscaled from 10")
  ios/               # iPhone 6.9",  1290 x 2796              — 8 frames
  ios-tab-13/        # iPad 13",     2064 x 2752  (3:4)       — 8 frames
  feature-graphic.png# Play feature graphic, 1024 x 500
  .build/            # intermediate HTML + 2x rasters (disposable)
```

## App icon

`src/build-icons.py` renders the green Cardamon clock (`site/public/icons/app-logo.svg`)
onto an opaque white tile, flattens the alpha (App Store rejects icons with an
alpha channel), and writes all 21 sizes straight into
`flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` plus a standalone
`app-icon-1024.png` here. iOS applies its own rounded-corner mask, so the source
is a full white square. Run: `python3 src/build-icons.py`.

## Regenerate

The screens are REAL app UI. Capture pass first (writes to
`flutter_app/test/goldens/store/`), then copy into `src/screens/`, then compose:

```
cd ../flutter_app
flutter test test/store_capture_test.dart --update-goldens          # all captures
flutter test test/store_capture_test.dart --update-goldens --name ipad   # just iPad
cp test/goldens/store/*.png ../store-listings/src/screens/

cd ../store-listings
node src/build.mjs            # all frames + feature graphic
node src/build.mjs ipad       # only ids containing "ipad"
node src/build.mjs feature    # only the feature graphic
```

Each poster is built as HTML at the exact canvas size, rasterized at 2x for
crisp anti-aliasing, then downscaled to the exact store pixel size with `sips`.
A single continuous background gradient (light -> dark at the centered dark-theme
frame -> light), a wide translucent streak band, and a wavy dotted "route" flow
across all frames in a set so they read as one panorama when placed side by side.

## Required sizes (verified against official docs, 2026)

| Store | Asset | Size | Notes |
|---|---|---|---|
| Play | Phone screenshot | 1080 x 1920 | 2–8; flat PNG/JPEG, no alpha |
| Play | 7" tablet screenshot | 1200 x 2133 | 9:16; each side 320–3840 px |
| Play | 10" tablet screenshot | 1800 x 3200 | 9:16; each side 1080–7680 px |
| Play | Feature graphic | 1024 x 500 | required, no alpha |
| Play | Hi-res icon | 512 x 512 | 32-bit PNG |
| App Store | iPhone 6.9" | 1290 x 2796 | 1–10; also fills the 6.7" slot, scales to smaller iPhones |
| App Store | iPad 13" | 2064 x 2752 | required for the universal build (`TARGETED_DEVICE_FAMILY = 1,2`) |
| App Store | Marketing icon | 1024 x 1024 | flat, no alpha, in the asset catalog |

Apple imagery and metadata must avoid the word "timer" (Guideline 4.3); lead
with what a timer cannot do — mixed-unit arithmetic, rate-per-interval, formats.
The iOS/iPad captures grant Pro (`debugGrantPro`) so the store shots show the
FULL unlocked app; there is no donation tea-cup on the Apple toolbar.

## Lineup (8 frames per set, one feature per slot)

Frames 1–2 of each phone set form ONE angled panorama phone; the rest are
straight. The dark-theme frame sits at the center so the row gradient dips to
dark there. Devices: iPhone 17 Pro, Galaxy S25, iPad 13", generic 10"/7" tablet.

1. **Calculator** — mixed-unit add/subtract. *"Add & subtract time"*
2. **Rate** — turn time into pay. *"Turn time into pay"*
3. **Formats** — result-format picker. *"See any result your way"*
4. **Keypad** — customizable keypad (Media preset). *"A keypad for your work"*
5. **Dark mode** — full dark theme (center frame). *"Easy on the eyes, day or night"*
6. **History** — saved calculations with notes. *"Every total, saved with a note"*
7. **Resize** — drag-to-resize display/keypad, All-Units result. *"Sized to your screen"*
8. **Convert** — decimal-hours / any-unit conversion. *"Convert to any unit"*

Status: **complete** — Play phone + 7"/10" tablet + feature graphic; App Store
iPhone 6.9" + iPad 13"; iOS app-icon set + 1024 marketing icon (from the green
Cardamon clock). iOS ships WITH the Pro paywall, so the `pro_unlock`
non-consumable must exist in App Store Connect before the build goes to review.
