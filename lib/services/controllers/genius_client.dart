import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/controller_vendor.dart';
import 'controller_client.dart';

/// Genius (HolidayCoro / "Experience"): JSON `/api/state` + `/api/config`,
/// test via `/api/test_mode_enable|disable` + `/api/set_test_elements`.
/// Verified against the FPP controller plugin (genius_controller.cpp) and
/// xLights Experience.cpp.
class GeniusClient extends ControllerClient {
  final http.Client _http;
  final Duration timeout;

  GeniusClient(super.ip, {http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _http = client ?? http.Client();

  @override
  ControllerVendor get vendor => ControllerVendor.genius;
  @override
  bool get supportsPerPortTest => true;
  @override
  bool get supportsOutputConfig => true;

  Future<dynamic> _get(String path) async {
    try {
      final r = await _http
          .get(Uri.parse('http://$ip$path'), headers: {'Content-Type': 'application/json'})
          .timeout(timeout);
      if (r.statusCode == 200 && r.body.isNotEmpty) return jsonDecode(r.body);
    } catch (_) {}
    return null;
  }

  @override
  Future<ControllerStatus> fetchStatus() async {
    final state = await _get('/api/state');
    if (state is! Map) return ControllerStatus.unreachable();
    final sys = (state['system'] is Map) ? state['system'] as Map : const {};
    final localOut = _asInt(sys['number_of_local_outputs']);
    final lrPix = _asInt(sys['number_of_long_range_pixel_ports']);
    final lrDmx = _asInt(sys['number_of_long_range_dmx_ports']);
    final extra = <String, String>{};
    if (lrPix > 0) extra['Long-range pixel ports'] = '$lrPix';
    if (lrDmx > 0) extra['Long-range DMX ports'] = '$lrDmx';
    return ControllerStatus(
      reachable: true,
      inTestMode: sys['test_mode_enabled'] == true,
      model: (sys['controller_model_name'] ?? 'Genius').toString(),
      firmware: (sys['firmware_version'] ?? '').toString(),
      mode: (sys['controller_line'] ?? '').toString(),
      portCount: localOut,
      extra: extra,
    );
  }

  @override
  Future<List<ControllerOutput>> fetchOutputs() async {
    final cfg = await _get('/api/config');
    if (cfg is! Map) return const [];
    final lrPorts = (cfg['long_range_ports'] is List) ? cfg['long_range_ports'] as List : const [];
    final outputs = (cfg['outputs'] is List) ? cfg['outputs'] as List : const [];

    final out = <ControllerOutput>[];
    // Long-range outputs chain multiple models down one physical port
    // (through any smart receivers on it); group them by that port instead
    // of listing each model as its own row.
    final byLrPort = <int, List<Map<String, dynamic>>>{};
    var localIdx = 0;
    for (final o in outputs.whereType<Map>()) {
      final om = o.cast<String, dynamic>();
      if (om.containsKey('long_range_port_index')) {
        (byLrPort[_asInt(om['long_range_port_index'])] ??= []).add(om);
        continue;
      }
      localIdx++;
      final disabled = om['disabled'] == true;
      final vs = (om['virtual_strings'] is List) ? om['virtual_strings'] as List : const [];
      final lines = _modelLines(vs);
      if (disabled && lines.isEmpty) continue;
      out.add(ControllerOutput('Output $localIdx', disabled ? 'disabled' : lines.join('\n')));
    }

    for (final idx in byLrPort.keys.toList()..sort()) {
      final lines = <String>[];
      for (final om in byLrPort[idx]!) {
        final vs = (om['virtual_strings'] is List) ? om['virtual_strings'] as List : const [];
        lines.addAll(_modelLines(vs));
      }
      if (lines.isEmpty) continue;
      final receivers = (idx < lrPorts.length) ? _asInt((lrPorts[idx] as Map)['number_of_receivers']) : 0;
      final label = 'Long-Range Port ${idx + 1}'
          '${receivers > 0 ? '  •  $receivers receiver${receivers == 1 ? '' : 's'}' : ''}';
      out.add(ControllerOutput(label, lines.join('\n')));
    }
    return out;
  }

  /// One line per configured model (virtual string). `ec` is the element
  /// (pixel) count, not an end channel — a `0` means an unconfigured slot.
  List<String> _modelLines(List vsList) {
    final lines = <String>[];
    for (final v in vsList.whereType<Map>()) {
      final pixels = _asInt(v['ec']);
      if (pixels <= 0) continue;
      final sc = _asInt(v['sc']);
      final group = _asInt(v['g']);
      final brightness = _asInt(v['b']);
      final parts = <String>['$pixels px'];
      if (sc > 0) parts.add('ch $sc');
      if (group > 1) parts.add('group $group');
      if (brightness >= 0 && brightness != 100) parts.add('$brightness%');
      lines.add(parts.join('  •  '));
    }
    return lines;
  }

  @override
  Future<bool> testOn() async {
    final a = await _get('/api/test_mode_enable');
    final b = await _get('/api/set_test_elements?selected_elements={elements:["all"]}');
    return a != null && b != null;
  }

  @override
  Future<bool> testOff() async => (await _get('/api/test_mode_disable')) != null;

  @override
  Future<bool> testPort(int port) async {
    final a = await _get('/api/test_mode_enable');
    final b = await _get(
        '/api/set_test_elements?selected_elements={elements:[["o","${port - 1}"]]}');
    return a != null && b != null;
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}
