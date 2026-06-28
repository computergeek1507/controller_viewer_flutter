# Changelog

All notable changes to this project are documented here. The format is loosely
based on [Keep a Changelog](https://keepachangelog.com/), and the project
follows semantic-ish versioning (`major.minor.patch+build`).

## [1.2.0+5]

### Fixed
- **Edge-to-edge (Android 15)** — opt into `SystemUiMode.edgeToEdge` with
  transparent system bars and inset-aware bottom padding on the detail pages,
  clearing the Play Console "edge-to-edge may not display for all users"
  warning.

## [1.2.0+4]

### Added
- **ESPixelStick support** — read-only vendor client (type ids `0xC2`/`0xC3`).
  Identity from `/api/system/info`, live stats from `/XJ`, and per-output
  config from `/conf/output_config.json` (pixel count, color order, GPIO,
  grouping, zigzag, null pixels, brightness).
- **Falcon V5 support** — new vendor (type ids `0x8A–0x8C`) reusing the Falcon
  V4 `/api` protocol.
- **MultiSync test mode** — an "Apply to MultiSync remotes" toggle on the FPP
  page that fans Start/Stop/Test-Model out to every MultiSync peer.
- **WLED string output configuration** — per-bus details (pixel count, GPIO,
  LED type, color order, LED range) read from `/json/cfg`.
- **FPP per-string output detail** — pixel ports now show pixel count, color
  order, start channel, group size, start/end nulls, zigzag, reverse,
  brightness, and gamma per virtual string, including the smart-receiver letter.
- **FPP cape info** — a Cape section on the FPP page showing the cape/hat EEPROM
  identity (name, version, serial, vendor, provides) from `/api/cape`.

### Changed
- **WLED detection** — HTTP enrichment now falls back to `/json/info` when the
  FPP probe is empty, and ignores WLED's empty `{}` reply to `/api/system/info`,
  so manually-added/saved WLEDs classify correctly instead of staying "unknown".
- FPP page reorganized: outputs render inline at the bottom (like the WLED page)
  instead of behind a "View Outputs" button; section order is now
  Testing → Sequence → Playlist → Cape → Outputs.
- Web-UI action moved to a single top-right `open_in_new` icon; removed the
  redundant in-body "Open Web UI" button on the FPP page.
- The controller Testing section is gated on `supportsTestMode`, so read-only
  controllers (ESPixelStick) no longer show non-functional test buttons.

## [1.1.0+3]
- Internal testing build.

## [1.0.1+2]
- Maintenance release.

## [1.0.0]
- Initial release: PCB icon, package rename, store assets, signing.
