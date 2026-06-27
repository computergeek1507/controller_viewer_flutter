# Controller Viewer

A cross-platform Flutter app to discover and control lighting controllers on the
local network — FPP, Falcon (V3/V4/V5), Genius, WLED, and ESPixelStick.

Runs on Windows, Android, iOS, macOS, and Linux.

**Try it in your browser:** [computergeek1507.github.io/controller_viewer_flutter](https://computergeek1507.github.io/controller_viewer_flutter/)

> ⚠️ **The web build has major limitations** — for full functionality, use the native desktop or mobile build instead.
>
> - **Use Microsoft Edge.** The web build is currently only known to work in Edge; other browsers (Chrome, Firefox, Safari) block the requests it makes to FPP devices.
> - **No auto-discovery.** Browsers can't open the raw UDP/mDNS sockets discovery requires, so you must add every device manually by hostname/IP.
> - **CORS / mixed content.** FPP devices serve plain HTTP and don't send CORS headers, so browsers may block the app from reading their responses — devices can silently fail to come online. This can't be fixed in the app; it requires enabling CORS on the FPP device or running a local proxy.

## Features

- **Zero-config discovery** of devices via:
  - UDP MultiSync ping (multicast `239.70.80.80` + broadcast, port `32320`)
  - mDNS (`_fppd._udp`)
  - Peer pull from any found device (`/api/fppd/multiSyncSystems`)
  - HTTP probing — FPP sysinfo with a WLED `/json/info` fallback
  - Manual add by hostname/IP (persisted across launches)
- **Multi-vendor support** — each controller family is classified from its
  MultiSync type id (or HTTP identity) and talked to via a vendor client:
  | Vendor | Type id | Notes |
  |--------|---------|-------|
  | FPP | `0x01–0x7F` | Full player: playback, sequences, playlists |
  | Falcon V3 | `0x85, 0x87` | `/api` test + output config |
  | Falcon V4 | `0x88, 0x89` | `/api` test + output config |
  | Falcon V5 | `0x8A–0x8C` | Same protocol as V4 |
  | Genius | `0xA0–0xAF` | Per-port test + output config |
  | WLED | `0xFB` | `/json` test + per-bus output config |
  | ESPixelStick | `0xC2, 0xC3` | Read-only info + output config |
- **Device list** with live status: playback state, hostname, IP, version, platform, vendor badge, and mode.
- **FPP controls**:
  - Start / stop hardware test pattern (RGB chase), with an optional
    **MultiSync** toggle that fans the test out to all of the device's peers
  - Test a single model's channel range
  - Play / stop a single sequence
  - Start a playlist; stop gracefully or immediately
  - Cape/hat EEPROM info (`/api/cape`)
  - Inline channel outputs with full per-string wiring (pixel count, color
    order, start channel, nulls, zigzag, brightness, gamma)
- **Pixel-controller pages** (Falcon / Genius / WLED / ESPixelStick): live
  status, test controls (where supported), and per-output configuration.
- **Open the device's web UI** in a browser.
- **Bulk actions**: start/stop testing on all devices at once.

## Architecture

| Path | Responsibility |
|------|----------------|
| `lib/models/fpp_device.dart` | Device model + version-aware JSON parsing |
| `lib/models/fpp_output.dart` | FPP channel-output parsing |
| `lib/models/controller_vendor.dart` | Vendor enum + type-id/platform classification |
| `lib/services/fpp_api.dart` | FPP HTTP REST client |
| `lib/services/controllers/` | Vendor clients (Falcon, Genius, WLED, ESPixelStick) behind a common interface |
| `lib/services/fpp_discovery.dart` | UDP + mDNS + peer + HTTP discovery |
| `lib/services/device_manager.dart` | Device list, status polling, persistence |
| `lib/ui/` | Device list, FPP detail, and pixel-controller detail pages |

## Running

```
flutter pub get
flutter run -d windows   # or: android, macos, linux
```

On Windows, building plugins requires **Developer Mode** to be enabled
(Settings -> For Developers) for symlink support.

## Testing

```
flutter test
```

Unit tests cover the discovery packet decoder, sysinfo/status JSON parsing, and IP persistence.
