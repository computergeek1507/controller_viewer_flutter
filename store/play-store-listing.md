# Google Play Store Listing — Controller Viewer

Copy/paste-ready text for the Play Console **Main store listing** page. Character
limits are noted next to each field and the supplied text is within them.

---

## App details

| Field | Value |
|-------|-------|
| **App name** (max 30) | `Controller Viewer` |
| **Package name** | `com.sandbdesigns.controller_viewer` |
| **Default language** | English (United States) – `en-US` |
| **App or game** | App |
| **Free or paid** | Free |
| **Category** | Tools |
| **Tags** | utilities, networking, smart home |
| **Contact email** | scott@scottnation.com |
| **Website** | https://computergeek1507.github.io/controller_viewer_flutter/ |
| **Privacy policy URL** | https://computergeek1507.github.io/controller_viewer_flutter/privacy-policy.html |

---

## Short description (max 80 characters)

> Discover and control Falcon Player (FPP) light controllers on your local network.

*(79 characters)*

---

## Full description (max 4000 characters)

```
Controller Viewer is a fast, no-fuss companion for managing Falcon Player (FPP)
light controllers on your local network — perfect for holiday light shows, props,
and pixel displays.

Point it at your network and it finds your controllers automatically: no accounts,
no cloud, no sign-in. Everything happens directly between your phone and the
controllers on your own Wi-Fi.

ZERO-CONFIG DISCOVERY
• Automatically finds FPP devices using multicast and mDNS
• Pulls in peers that any discovered device already knows about
• Add devices manually by hostname or IP — saved across launches

LIVE DEVICE LIST
• See every controller at a glance with its current status
• Playback state, hostname, IP address, version, platform, and mode
• Status refreshes automatically so you always see what's really happening

PER-DEVICE CONTROLS
• Start and stop the hardware test pattern (RGB chase)
• Test a single model's channel range
• Play or stop an individual sequence
• Start a playlist, then stop it gracefully or immediately
• View channel outputs — pixel, serial, matrix, and more
• Jump straight to the device's built-in web UI

BULK ACTIONS
• Start or stop testing on every controller at once — great for quickly checking
  wiring across a whole display

PRIVATE BY DESIGN
• No accounts, no analytics, no ads, no tracking
• Communicates only with the controllers on your local network
• Your device list is stored on your phone and never leaves it

Controller Viewer is an independent, open-source utility. It is not affiliated with
or endorsed by the Falcon Player (FPP) project.

Note: This app controls FPP devices on your own local network. You need one or more
FPP controllers reachable over Wi-Fi for it to be useful.
```

---

## Content rating

Complete the **Content rating** questionnaire in Play Console (required before
publishing). Suggested answers for this app:

- **Category:** Utility, Productivity, Communication, or Other → *Tool / Utility*
- Violence, sexual content, profanity, controlled substances: **No** to all
- User-generated content / user interaction: **No**
- Shares user location: **No**
- Collects personal/sensitive data: **No**

Expected outcome: rated for **Everyone**.

---

## Data safety

In Play Console → **App content → Data safety**, declare:

- **Does your app collect or share any required user data types?** → **No**
- **Is all of the user data encrypted in transit?** → N/A (no data collected; the
  app talks to local devices over HTTP)
- **Do you provide a way for users to request that their data be deleted?** → N/A
  (data is stored only on-device; uninstalling removes it)

This matches the privacy policy: no data is collected, transmitted, or sold.

---

## Graphic assets (must be supplied separately)

Play Store requires images you'll need to produce. The app's brand colors are
navy `#0D1B3E` and blue `#1565C0` (from the launcher icon / privacy page).

| Asset | Spec | Status |
|-------|------|--------|
| **App icon** | 512 × 512 px, 32-bit PNG | Source: `assets/icon/app_icon.png` — export at 512² |
| **Feature graphic** | 1024 × 500 px, PNG/JPG (no alpha) | ✅ `store/feature-graphic.png` |
| **Phone screenshots** | 2–8 images, 16:9 or 9:16, min 320 px side | ✅ `store/screenshots/` (1080 × 2400) |
| **7" tablet screenshots** (optional) | up to 8 | Optional |
| **10" tablet screenshots** (optional) | up to 8 | Optional |

### Captured screenshots (`store/screenshots/`)
1. `01-device-list.png` — Controllers list with live status across FPP / Genius / WLED / Falcon
2. `02-fpp-control.png` — FPP player control screen (playback info + test/sequence/playlist controls)
3. `03-pixel-controller.png` — Falcon V4 controller monitor (status, test, per-port outputs)
4. `04-add-controller.png` — "Add Controller" dialog (manual add by hostname/IP)

These were captured on an Android emulator using the built-in demo seed:
`flutter run -d <device> --dart-define=SCREENSHOT=true`
(seeds sample controllers + canned status/outputs; excluded from release builds —
see `lib/screenshot_mode.dart`).

---

## Release checklist

- [x] Replace the debug signing config in `android/app/build.gradle.kts` with a
      real upload key. (Upload keystore generated; secrets in `android/key.properties`
      + `android/upload-keystore.jks`, both gitignored — **back these up**.)
- [ ] Bump `version` in `pubspec.yaml` for each release (currently `1.0.0+1`).
- [x] Build an app bundle: `flutter build appbundle --release`
      (→ `build/app/outputs/bundle/release/app-release.aab`, signed with upload key)
- [ ] Upload `build/app/outputs/bundle/release/app-release.aab`
- [ ] Fill in the store listing fields above.
- [ ] Complete Content rating and Data safety sections.
- [ ] Add the privacy policy URL.
- [ ] Upload icon, feature graphic, and screenshots.
