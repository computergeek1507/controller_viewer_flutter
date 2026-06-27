import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/controller_vendor.dart';
import 'controller_client.dart';

/// ESPixelStick (forkineye/ESPixelStick v4): an ESP8266/ESP32 pixel + serial
/// controller. Identity/firmware come from the FPP-compatible
/// `/api/system/info` endpoint; live stats (network, heap, uptime) from the
/// firmware's `/XJ` status JSON; and per-output config from
/// `/conf/output_config.json`.
///
/// Read-only: ESPixelStick test patterns are driven through its input config
/// (over a WebSocket/config upload), so there is no simple HTTP test toggle to
/// expose here. Verified against the ESPixelStick firmware sources
/// (WebMgr.cpp, FPPDiscovery.cpp, NetworkMgr/WiFiDriver, OutputMgr.cpp).
class EspixelstickClient extends ControllerClient {
  final http.Client _http;
  final Duration timeout;

  EspixelstickClient(super.ip, {http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _http = client ?? http.Client();

  @override
  ControllerVendor get vendor => ControllerVendor.espixelstick;
  @override
  bool get supportsTestMode => false;
  @override
  bool get supportsOutputConfig => true;

  Future<dynamic> _get(String path) async {
    try {
      final r = await _http.get(Uri.parse('http://$ip$path')).timeout(timeout);
      if (r.statusCode == 200 && r.body.isNotEmpty) return jsonDecode(r.body);
    } catch (_) {}
    return null;
  }

  @override
  Future<ControllerStatus> fetchStatus() async {
    final info = await _get('/api/system/info');
    final xj = await _get('/XJ');
    if (info is! Map && xj is! Map) return ControllerStatus.unreachable();

    final i = (info is Map) ? info : const {};
    final status = (xj is Map && xj['status'] is Map) ? xj['status'] as Map : const {};
    final system = (status['system'] is Map) ? status['system'] as Map : const {};
    final network = (system['network'] is Map) ? system['network'] as Map : const {};
    final wifi = (network['wifi'] is Map) ? network['wifi'] as Map : const {};
    final outs = (status['output'] is List) ? status['output'] as List : const [];

    final extra = <String, String>{};
    final ssid = (wifi['ssid'] ?? '').toString();
    if (ssid.isNotEmpty) extra['SSID'] = ssid;
    final rssi = wifi['rssi'] ?? i['rssi'];
    if (rssi != null) extra['WiFi signal'] = '$rssi dBm';
    final ip = (wifi['ip'] ?? '').toString();
    if (ip.isNotEmpty && ip != '0.0.0.0') extra['IP'] = ip;
    final mac = (wifi['mac'] ?? i['UUID'] ?? '').toString();
    if (mac.isNotEmpty) extra['MAC'] = mac;
    final freeHeap = _asInt(system['freeheap']);
    if (freeHeap > 0) extra['Free heap'] = '${(freeHeap / 1024).toStringAsFixed(1)} KB';
    final uptimeMs = _asInt(system['uptime']);
    if (uptimeMs > 0) extra['Uptime'] = _formatUptime(uptimeMs);

    final friendly = (i['HostDescription'] ?? '').toString();
    final host = (i['HostName'] ?? network['hostname'] ?? '').toString();

    return ControllerStatus(
      reachable: true,
      model: friendly.isNotEmpty ? friendly : (host.isNotEmpty ? host : 'ESPixelStick'),
      firmware: (i['Version'] ?? '').toString(),
      mode: (i['Mode'] ?? '').toString(),
      portCount: outs.length,
      extra: extra,
    );
  }

  @override
  Future<List<ControllerOutput>> fetchOutputs() async {
    final cfg = await _get('/conf/output_config.json');
    final root = (cfg is Map && cfg['output_config'] is Map) ? cfg['output_config'] as Map : null;
    if (root == null) return const [];
    final channels = (root['channels'] is Map) ? root['channels'] as Map : const {};
    final out = <ControllerOutput>[];
    final keys = channels.keys.map((k) => k.toString()).toList()
      ..sort((a, b) => (int.tryParse(a) ?? 0).compareTo(int.tryParse(b) ?? 0));
    for (final key in keys) {
      final ch = channels[key];
      if (ch is! Map) continue;
      // Each channel nests its driver config under a key equal to its type id.
      final driver = (ch['${ch['type']}'] is Map) ? ch['${ch['type']}'] as Map : const {};
      final name = (driver['type'] ?? 'Disabled').toString();
      final pixels = _asInt(driver['pixel_count']);
      final chans = _asInt(driver['num_chan']);
      final order = (driver['color_order'] ?? '').toString().toUpperCase();
      final pin = driver.containsKey('data_pin') ? _asInt(driver['data_pin']) : -1;
      final group = _asInt(driver['group_size']);
      final zig = _asInt(driver['zig_size']);
      final prepend = _asInt(driver['prependnullcount']);
      final append = _asInt(driver['appendnullcount']);
      final brightness = _asInt(driver['brightness']);

      final parts = <String>[];
      if (pixels > 0) {
        parts.add('$pixels px');
      } else if (chans > 0) {
        parts.add('$chans ch');
      }
      if (order.isNotEmpty) parts.add(order);
      if (pin >= 0) parts.add('GPIO $pin');
      if (group > 1) parts.add('group $group');
      if (zig > 0) parts.add('zigzag $zig');
      if (prepend > 0 || append > 0) parts.add('null $prepend/$append');
      if (brightness > 0 && brightness != 100) parts.add('$brightness%');

      final port = (int.tryParse(key) ?? 0) + 1;
      final detail = parts.isEmpty ? name : '$name  •  ${parts.join('  •  ')}';
      out.add(ControllerOutput('Port $port', detail));
    }
    return out;
  }

  @override
  Future<bool> testOn() async => false;
  @override
  Future<bool> testOff() async => false;

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static String _formatUptime(int ms) {
    final totalSeconds = ms ~/ 1000;
    final d = totalSeconds ~/ 86400;
    final h = (totalSeconds % 86400) ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (d > 0) return '${d}d ${h}h ${m}m';
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
