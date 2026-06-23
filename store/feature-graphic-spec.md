# Feature Graphic Layout Spec — Controller Viewer

The Play Store **feature graphic** is the wide banner shown at the top of the
store listing and in promotional spots.

## Hard requirements (Google Play)

| Property | Value |
|----------|-------|
| Dimensions | **1024 × 500 px** (exact) |
| Format | PNG or JPEG, **no alpha / transparency** |
| Max file size | 15 MB |
| Text | Keep all text well inside the center; edges may be cropped |

> ⚠️ Google may overlay a **play button** in the dead center when a promo video is
> attached, and crops the graphic differently across surfaces. Keep the logo/title
> out of the exact center and away from all four edges (see safe zone below).

---

## Canvas & coordinate system

All coordinates below assume a 1024 × 500 artboard, origin top-left.

```
0,0 ┌─────────────────────────────────────────────────────────┐ 1024,0
    │  ░ pixel-grid motif (left)        TEXT BLOCK (right) ░    │
    │                                                          │
    │   ● ● ● ● ●          Controller Viewer                   │
    │   ● ● ● ● ●          Discover & control FPP light        │
    │   ● ● ● ● ●          controllers on your network         │
    │                                                          │
0,500└─────────────────────────────────────────────────────────┘ 1024,500
```

### Safe zone
- Keep all essential content within a centered **902 × 442** box
  (≈ 61 px horizontal / 29 px vertical margin on every side).
- Keep the title text in the **right 55%** of the canvas so a centered play-button
  overlay never lands on it.

---

## Background

- **Diagonal gradient**, 160°, top-left → bottom-right:
  - Start: blue `#1565C0`
  - End: navy `#0D1B3E`
- This matches the app icon background and the privacy-policy header.
- Optional: a very subtle vignette (navy, ~12% opacity) in the corners to add depth.
- No transparency anywhere (alpha is rejected by Play).

---

## Left motif — PCB chip (carries the app icon)

Reuse the app icon's circuit-board artwork as the visual anchor on the left, so
the banner and launcher icon read as the same brand.

- **Composition:** a central IC chip with gold pins, teal copper traces routing
  out to glowing LED pads, and gold vias at the trace bends — identical to
  `assets/icon/app_icon_foreground.svg`.
- **Placement:** the 1024² icon artwork is scaled to `0.44` and offset by
  `translate(15, 25)`, so it occupies roughly x ∈ [80, 400], vertically centered.
- **Chip:** rounded square, dark slate gradient (`#1a2747` → `#0a1024`), `#33507f`
  stroke, with a pin-1 ring marker and a 3×3 teal pixel grid etched on its face
  (a nod to the original icon).
- **Traces:** teal `#33C7BC` over a darker `#15706b` underlay for depth, rounded
  joins, with one 45° bend on the diagonal runs.
- **LED pads:** red `#E53935`, green `#43A047`, blue `#1E88E5`, amber `#FDB827`,
  each with a soft glow halo (14 px blur, ~60% opacity) and a white specular
  highlight — reads as a live, lit display.

---

## Right block — title & tagline

Right-aligned or left-aligned within the right half; the example SVG left-aligns
from x ≈ 560.

- **App title:** `Controller Viewer`
  - Weight: Bold (e.g. Roboto/Inter Bold or system sans).
  - Size: ~56 px (fits "Controller Viewer" on one line). Color: white `#FFFFFF`.
  - Optional drop shadow: navy, y+2, 6 px blur, 35% — for legibility on gradient.
- **Tagline (2 lines):** `Discover & control FPP light` / `controllers on your network`
  - Weight: Regular/Medium. Size: ~30 px. Color: `#D7E3F4` (soft blue-white).
  - Line height ~1.3.
- Vertical: title baseline near y ≈ 235; tagline block below it, the pair
  centered as a unit on the canvas mid-line (y = 250).

Keep total text to the title + one short tagline. Feature graphics are small at
display size — don't pack in the full feature list.

---

## Color reference

| Role | Hex |
|------|-----|
| Gradient start (blue) | `#1565C0` |
| Gradient end (navy) | `#0D1B3E` |
| Title text | `#FFFFFF` |
| Tagline text | `#D7E3F4` |
| Pixel red | `#E53935` |
| Pixel green | `#43A047` |
| Pixel blue | `#1E88E5` |
| Pixel amber | `#FDB827` |

---

## Producing the PNG

A ready-to-render `feature-graphic.svg` lives next to this file. It implements the
spec above. Export it to the required PNG with any of:

```bash
# Inkscape
inkscape store/feature-graphic.svg --export-type=png --export-width=1024 \
  --export-height=500 -o store/feature-graphic.png

# rsvg-convert (librsvg)
rsvg-convert -w 1024 -h 500 store/feature-graphic.svg -o store/feature-graphic.png

# ImageMagick (uses an SVG backend)
magick -background none store/feature-graphic.svg -resize 1024x500 store/feature-graphic.png
```

The SVG has no transparency in the visible artwork, but flatten on a solid
background when exporting to be safe (Play rejects alpha):

```bash
magick store/feature-graphic.png -background "#0D1B3E" -alpha remove -alpha off \
  store/feature-graphic.png
```

Verify the result is exactly 1024 × 500 before uploading.
