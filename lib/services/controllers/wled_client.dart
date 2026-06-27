import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/controller_vendor.dart';
import 'controller_client.dart';

/// WLED: the `/json` API. Test mode = set every segment to effect 34 and turn
/// the strip on. Verified against the FPP controller plugin (wled_controller.cpp).
class WledClient extends ControllerClient {
  final http.Client _http;
  final Duration timeout;

  WledClient(super.ip, {http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _http = client ?? http.Client();

  @override
  ControllerVendor get vendor => ControllerVendor.wled;
  @override
  bool get supportsOutputConfig => true;

  Future<dynamic> _get(String path) async {
    try {
      final r = await _http.get(Uri.parse('http://$ip$path')).timeout(timeout);
      if (r.statusCode == 200 && r.body.isNotEmpty) return jsonDecode(r.body);
    } catch (_) {}
    return null;
  }

  Future<bool> _postJson(String path, Map<String, dynamic> body) async {
    try {
      final r = await _http
          .post(Uri.parse('http://$ip$path'),
              headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(timeout);
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ControllerStatus> fetchStatus() async {
    final info = await _get('/json/info');
    final state = await _get('/json/state');
    if (info is! Map && state is! Map) return ControllerStatus.unreachable();
    final i = (info is Map) ? info : const {};
    final s = (state is Map) ? state : const {};
    final segs = (s['seg'] is List) ? (s['seg'] as List).length : 0;
    final extra = <String, String>{};
    if (i['leds'] is Map && (i['leds'] as Map)['count'] != null) {
      extra['LEDs'] = '${(i['leds'] as Map)['count']}';
    }
    return ControllerStatus(
      reachable: true,
      inTestMode: s['on'] == true,
      model: (i['arch'] ?? 'WLED').toString(),
      firmware: (i['ver'] ?? '').toString(),
      mode: (i['name'] ?? '').toString(),
      portCount: segs,
      extra: extra,
    );
  }

  @override
  Future<List<ControllerOutput>> fetchOutputs() async {
    // WLED's physical pixel outputs (LED buses) live in /json/cfg under
    // hw.led.ins[]; /json/info only reports aggregate LED count + segments.
    final cfg = await _get('/json/cfg');
    final hw = (cfg is Map && cfg['hw'] is Map) ? cfg['hw'] as Map : null;
    final led = (hw?['led'] is Map) ? hw!['led'] as Map : null;
    final ins = (led?['ins'] is List) ? led!['ins'] as List : const [];
    final out = <ControllerOutput>[];
    var idx = 0;
    for (final b in ins.whereType<Map>()) {
      idx++;
      final len = _asInt(b['len']);
      final start = _asInt(b['start']);
      final pins = (b['pin'] is List)
          ? (b['pin'] as List).map((p) => '$p').join('/')
          : '${b['pin'] ?? ''}';
      final parts = <String>[
        '$len px',
        if (pins.isNotEmpty) 'GPIO $pins',
        _ledType(_asInt(b['type'])),
        if (_colorOrder(_asInt(b['order'])).isNotEmpty) _colorOrder(_asInt(b['order'])),
      ];
      final detail = len > 0
          ? '${parts.join('  •  ')}  (LED $start–${start + len - 1})'
          : parts.join('  •  ');
      out.add(ControllerOutput('Output $idx', detail));
    }
    return out;
  }

  @override
  Future<bool> testOn() async {
    final state = await _get('/json/state');
    final segCount = (state is Map && state['seg'] is List) ? (state['seg'] as List).length : 1;
    final segs = List.generate(segCount, (_) => {'fx': 34});
    final ok1 = await _postJson('/json', {'seg': segs});
    final ok2 = await _postJson('/json', {'on': true});
    return ok1 && ok2;
  }

  @override
  Future<bool> testOff() => _postJson('/json', {'on': false});

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  /// Map WLED's bus LED-type code to a label (common types; others fall back).
  static String _ledType(int t) {
    const types = {
      22: 'WS281x', 24: 'WS2811 400kHz', 30: 'SK6812 RGBW', 31: 'TM1814',
      50: 'WS2801', 51: 'APA102', 52: 'LPD8806', 53: 'P9813', 54: 'LPD6803',
      41: 'Analog 1ch', 42: 'Analog 2ch', 43: 'Analog 3ch',
      44: 'Analog 4ch', 45: 'Analog 5ch',
    };
    return types[t] ?? 'Type $t';
  }

  static String _colorOrder(int o) {
    const orders = ['GRB', 'RGB', 'BRG', 'RBG', 'BGR', 'GBR'];
    return (o >= 0 && o < orders.length) ? orders[o] : '';
  }
}
