import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/controller_vendor.dart';
import '../models/fpp_device.dart';
import '../screenshot_mode.dart';
import 'controllers/controller_client.dart';
import 'controllers/controller_factory.dart';
import 'fpp_api.dart';
import 'fpp_discovery.dart';

/// Owns the live device list: drives discovery, merges results, persists known
/// IPs, and polls playback status on a timer. UI listens via [ChangeNotifier].
class DeviceManager extends ChangeNotifier {
  static const _prefsKey = 'known_fpp_ips';

  final FppApi api;
  final FppDiscovery discovery;

  final Map<String, FppDevice> _devices = {};
  StreamSubscription<FppDevice>? _discoverySub;
  Timer? _statusTimer;
  bool _scanning = false;

  DeviceManager({FppApi? api, FppDiscovery? discovery})
      : api = api ?? FppApi(),
        discovery = discovery ?? FppDiscovery(api: api ?? FppApi());

  List<FppDevice> get devices {
    final list = _devices.values.toList();
    list.sort((a, b) {
      // Real FPP players first, then by hostname/IP.
      final byType = (b.isFppDevice ? 1 : 0) - (a.isFppDevice ? 1 : 0);
      if (byType != 0) return byType;
      final an = a.hostname.isNotEmpty ? a.hostname : a.ip;
      final bn = b.hostname.isNotEmpty ? b.hostname : b.ip;
      return an.toLowerCase().compareTo(bn.toLowerCase());
    });
    return list;
  }

  bool get scanning => _scanning;

  /// Whether this platform supports zero-config UDP/mDNS discovery. False on
  /// web, where only manual-IP add + HTTP polling are available.
  bool get supportsNetworkDiscovery => discovery.supportsNetworkDiscovery;

  /// Populate the list with representative sample controllers for store
  /// screenshots / demos. Skips all network discovery and polling. Gated by a
  /// `--dart-define=SCREENSHOT=true` in [main]; never runs in normal use.
  void loadDemoDevices() {
    final now = DateTime.now();
    final demo = <FppDevice>[
      FppDevice(
        ip: '192.168.1.21',
        hostname: 'Front-Yard-Pi',
        version: '8.4',
        mode: 'player',
        platform: 'Raspberry Pi 4',
        typeId: 0x01,
        vendor: ControllerVendor.fpp,
        reachable: true,
        statusName: 'playing',
        currentPlaylist: 'Main Show',
        currentSequence: 'Carol of the Bells',
        secondsPlayed: 74,
        secondsRemaining: 121,
        volume: 85,
        lastSeen: now,
      ),
      FppDevice(
        ip: '192.168.1.22',
        hostname: 'Mega-Tree-Pi',
        version: '8.4',
        mode: 'remote',
        platform: 'Raspberry Pi 5',
        typeId: 0x01,
        vendor: ControllerVendor.fpp,
        reachable: true,
        statusName: 'testing',
        lastSeen: now,
      ),
      FppDevice(
        ip: '192.168.1.32',
        hostname: 'Arches-Genius',
        version: '1.4',
        typeId: 0xA0,
        vendor: ControllerVendor.genius,
        reachable: true,
        statusName: 'online',
        portCount: 16,
        lastSeen: now,
      ),
      FppDevice(
        ip: '192.168.1.33',
        hostname: 'Porch-WLED',
        version: '0.14.0',
        typeId: 0xFB,
        vendor: ControllerVendor.wled,
        reachable: true,
        statusName: 'online',
        portCount: 2,
        lastSeen: now,
      ),
      FppDevice(
        ip: '192.168.1.31',
        hostname: 'Roofline-F48',
        version: '4.10',
        mode: 'E1.31 Bridge',
        typeId: 0x88,
        vendor: ControllerVendor.falconV4,
        reachable: true,
        statusName: 'testing',
        inTestMode: true,
        portCount: 48,
        extra: const {
          'Temp': '38°C',
          'Voltage': '12.1 V',
          'Uptime': '6h 12m',
        },
        lastSeen: now,
      ),
    ];
    for (final d in demo) {
      _devices[d.ip] = d;
    }
    notifyListeners();
  }

  Future<void> init() async {
    _discoverySub = discovery.devices.listen(_onDeviceFound);
    final prefs = await SharedPreferences.getInstance();
    final ips = FppDevice.decodeIpList(prefs.getString(_prefsKey));
    for (final ip in ips) {
      _devices.putIfAbsent(ip, () => FppDevice(ip: ip, discoverySource: 'saved'));
      unawaited(discovery.enrichAndPullPeers(ip));
    }
    notifyListeners();
    await refreshAllStatus();
    await scan();
    _startStatusPolling();
  }

  void _onDeviceFound(FppDevice incoming) {
    if (incoming.ip.isEmpty) return;
    final existing = _devices[incoming.ip];
    if (existing == null) {
      _devices[incoming.ip] = incoming;
      unawaited(_refreshStatus(incoming));
      unawaited(_persist());
    } else {
      existing.mergeFrom(incoming);
    }
    notifyListeners();
  }

  Future<void> scan() async {
    _scanning = true;
    notifyListeners();
    discovery.resetEnrichmentCache();
    await discovery.discover(listenFor: const Duration(seconds: 5));
    // Let late UDP/mDNS replies trickle in, then drop the scanning flag.
    Timer(const Duration(seconds: 5), () {
      _scanning = false;
      notifyListeners();
    });
  }

  Future<void> addManual(String host) async {
    final h = host.trim();
    if (h.isEmpty) return;
    await discovery.addManual(h);
  }

  void removeDevice(String ip) {
    _devices.remove(ip);
    _persist();
    notifyListeners();
  }

  /// Enable/disable test mode on every controller at once, each via its own
  /// vendor client (FPP, Falcon V3/V4, Genius, WLED).
  Future<int> setTestAll(bool enabled) async {
    final targets = _devices.values
        .map((d) => controllerClientFor(d, fppApi: api))
        .whereType<ControllerClient>()
        .toList();
    final results = await Future.wait(
      targets.map((c) => enabled ? c.testOn() : c.testOff()),
    );
    await refreshAllStatus();
    return results.where((ok) => ok).length;
  }

  Future<void> clearKnownIps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<void> refreshAllStatus() async {
    await Future.wait(_devices.values.map(_refreshStatus));
    notifyListeners();
  }

  Future<void> _refreshStatus(FppDevice d) async {
    // Screenshot/demo build: keep the seeded sample data static.
    if (kScreenshotMode) return;
    if (d.ip.isEmpty) return;
    // FPP players keep the rich playback status path; other vendors poll via
    // their controller client and map the normalized snapshot onto the device.
    if (d.vendor == ControllerVendor.fpp || d.vendor == ControllerVendor.unknown) {
      final status = await api.systemStatus(d.ip, majorVersion: d.majorVersion);
      if (status != null) {
        d.applyStatus(status);
      } else {
        d.reachable = false;
      }
      return;
    }
    final client = controllerClientFor(d, fppApi: api);
    if (client == null) {
      d.reachable = false;
      return;
    }
    final s = await client.fetchStatus();
    d.reachable = s.reachable;
    if (s.reachable) {
      d.inTestMode = s.inTestMode;
      if (s.firmware.isNotEmpty) d.version = s.firmware;
      if (s.mode.isNotEmpty) d.mode = s.mode;
      if (s.model.isNotEmpty && d.hostname.isEmpty) d.hostname = s.model;
      if (s.portCount > 0) d.portCount = s.portCount;
      if (s.extra.isNotEmpty) d.extra = s.extra;
      d.statusName = (s.inTestMode == true) ? 'testing' : 'online';
      d.lastSeen = DateTime.now();
    }
  }

  /// Refresh one device's status now and notify (used after a control action).
  Future<void> refreshOne(FppDevice d) async {
    await _refreshStatus(d);
    notifyListeners();
  }

  /// Get the vendor-appropriate control client for a device (null if unknown).
  ControllerClient? clientFor(FppDevice d) => controllerClientFor(d, fppApi: api);

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) => refreshAllStatus());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, FppDevice.encodeIpList(_devices.keys));
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _discoverySub?.cancel();
    discovery.dispose();
    api.close();
    super.dispose();
  }
}
