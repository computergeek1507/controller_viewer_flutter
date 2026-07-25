# Apple App Store Listing — Controller Viewer

Copy/paste-ready text for **App Store Connect → App Information** and the
**iOS app version** page. Character limits are noted next to each field and the
supplied text is within them.

---

## App information (set once per app)

| Field | Value |
|-------|-------|
| **Name** (max 30) | `Controller Viewer` |
| **Subtitle** (max 30) | `FPP & pixel light control` |
| **Bundle ID** | `com.sandbdesigns.controllerViewer` |
| **Primary category** | Utilities |
| **Secondary category** (optional) | Lifestyle |
| **Content rights** | Does not use third-party content |
| **Age rating** | 4+ (no objectionable content — see below) |

---

## Localizable version fields (English – U.S.)

### Promotional text (max 170 — editable anytime without review)

> Find every FPP, Falcon, Genius, WLED, and ESPixelStick controller on your
> network automatically — no accounts, no cloud, no sign-in. Just open and go.

*(159 characters)*

### Keywords (max 100, comma-separated, no spaces after commas)

```
fpp,falcon,wled,xlights,pixel,led,christmas lights,controller,multisync,light show,esp,genius
```

*(99 characters)*

### Support URL

> https://computergeek1507.github.io/controller_viewer_flutter/

### Marketing URL (optional)

> https://computergeek1507.github.io/controller_viewer_flutter/

### Privacy Policy URL

> https://computergeek1507.github.io/controller_viewer_flutter/privacy-policy.html

---

## Description (max 4000 characters)

```
Controller Viewer is a fast, no-fuss companion for managing the light
controllers on your local network — perfect for holiday light shows, props, and
pixel displays driven by Falcon Player (FPP) and friends.

Point it at your Wi-Fi and it finds your controllers automatically: no accounts,
no cloud, no sign-in. Everything happens directly between your device and the
controllers on your own network.

SUPPORTS THE CONTROLLERS YOU ALREADY USE
• Falcon Player (FPP) — full player: playback, sequences, and playlists
• Falcon V3, V4, and V5 pixel controllers
• Genius pixel controllers
• WLED
• ESPixelStick

ZERO-CONFIG DISCOVERY
• Automatically finds FPP devices using multicast and mDNS
• Pulls in peers that any discovered device already knows about
• Add devices manually by hostname or IP — saved across launches

LIVE DEVICE LIST
• See every controller at a glance with its current status
• Playback state, hostname, IP address, version, platform, vendor, and mode
• Status refreshes automatically so you always see what's really happening

FPP PLAYER CONTROLS
• Start and stop the hardware test pattern (RGB chase)
• Optional MultiSync toggle fans the test out to all of a device's peers
• Test a single model's channel range
• Play or stop an individual sequence
• Start a playlist, then stop it gracefully or immediately
• View cape/hat EEPROM info and full per-string channel outputs

PIXEL-CONTROLLER PAGES
• Live status for Falcon, Genius, WLED, and ESPixelStick
• Test controls where supported
• Per-output configuration: pixel count, color order, start channel, nulls,
  zigzag, brightness, and gamma

BULK ACTIONS
• Start or stop testing on every controller at once — great for quickly
  checking wiring across a whole display

OPEN THE WEB UI
• Jump straight to any device's built-in web interface

PRIVATE BY DESIGN
• No accounts, no analytics, no ads, no tracking
• Communicates only with the controllers on your local network
• Your device list is stored on your device and never leaves it

Controller Viewer is an independent, open-source utility. It is not affiliated
with or endorsed by the Falcon Player (FPP) project or any controller vendor.

Note: This app controls light controllers on your own local network. You need
one or more compatible controllers reachable over Wi-Fi for it to be useful.
```

---

## What's New in This Version (max 4000 — release notes)

```
• Added Falcon V5 and ESPixelStick controller support
• New MultiSync test mode — fan Start/Stop/Test out to every peer at once
• FPP per-string output detail and cape/hat info
• WLED fixes and various stability improvements
```

*(Mirror `CHANGELOG.md` for each release.)*

---

## App Privacy (App Store Connect → App Privacy)

Declare **Data Not Collected**. The app does not collect, track, or transmit any
user or device data off the local network.

- **Do you or your third-party partners collect data from this app?** → **No**
- Tracking (ATT): **No** — the app does not track users, so no
  `NSUserTrackingUsageDescription` / ATT prompt is required.

This matches the privacy policy: no data is collected, transmitted, or sold.

### Local Network usage

iOS requires a usage-description string for local-network access (discovery via
multicast/mDNS). Ensure `ios/Runner/Info.plist` contains:

- `NSLocalNetworkUsageDescription` — e.g. *"Controller Viewer finds and controls
  light controllers on your local network."*
- `NSBonjourServices` — include `_fppd._udp` so mDNS discovery works.

Verify these are present before submitting, or discovery will silently fail on
device.

---

## Age rating questionnaire

Answer **None / No** to every content category (violence, sexual content,
profanity, gambling, contests, unrestricted web access, etc.).

Expected outcome: **4+**.

---

## Screenshots

App Store Connect requires at least one screenshot set. Apple now accepts a
single 6.9" iPhone set for all iPhone sizes; supply the iPad set too if the app
is offered on iPad (it is — universal Flutter build).

| Display | Required size (portrait) | Status |
|---------|--------------------------|--------|
| **iPhone 6.9"** (16/17 Pro Max) | 1320 × 2868 px | ✅ `store/screenshots/ios/iphone-6.9/` |
| **iPad 13"** (Pro 12.9"/13") | 2064 × 2752 px | ✅ `store/screenshots/ios/ipad-13/` |

Captured screens (same demo seed as Android):
1. `01-device-list` — Controllers list with live status across FPP / Genius / WLED / Falcon
2. `02-fpp-control` — FPP player control screen (playback info + test/sequence/playlist controls)
3. `03-pixel-controller` — Falcon V4 controller monitor (status, test, per-port outputs)
4. `04-add-controller` — "Add Controller" dialog (manual add by hostname/IP)

Captured on the iOS Simulator using the built-in demo seed:
`flutter run -d <udid> --dart-define=SCREENSHOT=true`
(seeds sample controllers + canned status/outputs; tree-shaken out of release
builds — see `lib/screenshot_mode.dart`).

---

## Build & submit checklist

- [ ] Confirm `NSLocalNetworkUsageDescription` + `NSBonjourServices` in `ios/Runner/Info.plist`.
- [ ] Bump `version` in `pubspec.yaml` for each release.
- [ ] Set the signing team in Xcode (`Runner` target → Signing & Capabilities).
- [ ] Archive a release build: `flutter build ipa --release`
      (→ `build/ios/ipa/*.ipa`).
- [ ] Upload via Xcode Organizer or `xcrun altool` / Transporter.
- [ ] Fill in the App Information and version fields above.
- [ ] Complete App Privacy and Age rating sections.
- [ ] Upload icon (1024 × 1024, no alpha), iPhone, and iPad screenshots.
- [ ] Submit for review.
```
