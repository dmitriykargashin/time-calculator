#!/usr/bin/env python3
"""Generate the iOS app-icon set + the 1024 marketing icon from the green
Cardamon clock (site/public/icons/app-logo.svg).

The mark is rendered crisply from the SVG via headless Chrome onto an OPAQUE
white tile (iOS applies its own rounded-corner mask, so the source is a full
square with no rounded corners), then flattened to RGB (App Store rejects icons
that carry an alpha channel) and downscaled with LANCZOS to every size the
asset catalog references.

Run:  python3 src/build-icons.py
"""
import os
import subprocess
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SVG = os.path.join(ROOT, "site/public/icons/app-logo.svg")
APPICON = os.path.join(ROOT, "flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset")
STORE = os.path.join(ROOT, "store-listings")
BUILD = os.path.join(STORE, ".build")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# How many px of the 1024 tile the SVG mark spans. The mark bleeds near its own
# frame edges, so < 1024 buys the ~10% breathing room an app icon wants.
FILL = 900

# Exact filenames + pixel sizes referenced by AppIcon.appiconset/Contents.json.
SIZES = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-50x50@1x.png": 50,
    "Icon-App-50x50@2x.png": 100,
    "Icon-App-57x57@1x.png": 57,
    "Icon-App-57x57@2x.png": 114,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-72x72@1x.png": 72,
    "Icon-App-72x72@2x.png": 144,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}

os.makedirs(BUILD, exist_ok=True)
html = os.path.join(BUILD, "icon.html")
raw = os.path.join(BUILD, "icon_master@2x.png")
with open(html, "w") as f:
    f.write(
        '<!doctype html><meta charset="utf-8">'
        "<style>*{margin:0}html,body{width:1024px;height:1024px}"
        ".t{width:1024px;height:1024px;background:#fff;overflow:hidden;position:relative}"
        ".t img{position:absolute;width:%dpx;height:%dpx;left:50%%;top:50%%;"
        "transform:translate(-50%%,-50%%)}</style>"
        '<div class="t"><img src="file://%s"></div>' % (FILL, FILL, SVG)
    )

subprocess.run(
    [CHROME, "--headless=new", "--disable-gpu", "--hide-scrollbars",
     "--allow-file-access-from-files", "--force-device-scale-factor=2",
     "--run-all-compositor-stages-before-draw", "--virtual-time-budget=2000",
     "--window-size=1024,1024", "--screenshot=%s" % raw, "file://%s" % html],
    check=True, stderr=subprocess.DEVNULL,
)

# Flatten onto white -> RGB (drops the alpha channel entirely).
src = Image.open(raw).convert("RGBA")
master = Image.new("RGB", src.size, (255, 255, 255))
master.paste(src, mask=src.split()[3])

for fn, px in SIZES.items():
    master.resize((px, px), Image.LANCZOS).save(os.path.join(APPICON, fn), "PNG")

# Standalone marketing-icon copy for the listing workspace.
master.resize((1024, 1024), Image.LANCZOS).save(os.path.join(STORE, "app-icon-1024.png"), "PNG")

print("done: %d catalog icons + app-icon-1024.png (RGB, no alpha, %dpx fill)" % (len(SIZES), FILL))
