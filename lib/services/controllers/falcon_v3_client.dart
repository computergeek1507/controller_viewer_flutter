import 'package:http/http.dart' as http;

import '../../models/controller_vendor.dart';
import 'controller_client.dart';

/// Falcon V2/V3: XML status/config + form-encoded `/test.htm`.
/// Verified against the FPP controller plugin (falconV3_controller.cpp).
class FalconV3Client extends ControllerClient {
  final http.Client _http;
  final Duration timeout;

  FalconV3Client(super.ip, {http.Client? client, this.timeout = const Duration(seconds: 5)})
      : _http = client ?? http.Client();

  @override
  ControllerVendor get vendor => ControllerVendor.falconV3;
  @override
  bool get supportsPerPortTest => true;
  @override
  bool get supportsOutputConfig => true;

  Future<String?> _get(String path) async {
    try {
      final r = await _http.get(Uri.parse('http://$ip$path')).timeout(timeout);
      if (r.statusCode == 200) return r.body;
    } catch (_) {}
    return null;
  }

  Future<bool> _postForm(String path, String body) async {
    try {
      final r = await _http
          .post(Uri.parse('http://$ip$path'),
              headers: {'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8'},
              body: body)
          .timeout(timeout);
      return r.statusCode >= 200 && r.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  String _tag(String xml, String name) {
    final m = RegExp('<$name>(.*?)</$name>').firstMatch(xml);
    return m?.group(1)?.trim() ?? '';
  }

  @override
  Future<ControllerStatus> fetchStatus() async {
    final status = await _get('/status.xml');
    if (status == null) return ControllerStatus.unreachable();
    final strings = await _get('/strings.xml');
    final inTest = strings != null && strings.contains("t='1'");
    return ControllerStatus(
      reachable: true,
      inTestMode: inTest,
      model: _tag(status, 'n').isNotEmpty ? _tag(status, 'n') : 'Falcon',
      firmware: _tag(status, 'v').isNotEmpty ? _tag(status, 'v') : _tag(status, 'fv'),
      mode: _mode(int.tryParse(_tag(status, 'm')) ?? -1),
      portCount: int.tryParse(_tag(status, 'np')) ?? 0,
    );
  }

  String _mode(int m) {
    switch (m) {
      case 0:
        return 'E1.31/ArtNet';
      case 2:
        return 'player';
      case 4:
        return 'remote';
      case 8:
        return 'master';
      case 16:
        return 'ZCPP';
      case 64:
        return 'DDP';
      default:
        return '';
    }
  }

  @override
  Future<List<ControllerOutput>> fetchOutputs() async {
    final xml = await _get('/strings.xml');
    if (xml == null) return const [];
    // Group <vs> tags sharing a port into one row (a smart-receiver chain
    // reports one <vs> per leg; a plain port with chained models reports
    // one per model). 'r' (receiver leg, mirroring the V4 JSON API's field
    // of the same name) is read defensively since it isn't confirmed on V3
    // firmware — absent, it's simply never shown.
    final byPort = <int, List<String>>{};
    for (final m in RegExp(r'<vs\b([^>]*)/?>').allMatches(xml)) {
      final attrs = m.group(1) ?? '';
      String a(String k) {
        final mm = RegExp("$k='([^']*)'").firstMatch(attrs) ??
            RegExp('$k="([^"]*)"').firstMatch(attrs);
        return mm?.group(1) ?? '';
      }

      final port = int.tryParse(a('p')) ?? 0;
      final pixels = a('c');
      final uni = a('u');
      final desc = a('y');
      final leg = int.tryParse(a('r')) ?? 0;
      final tag = leg > 0 ? String.fromCharCode(0x40 + leg.clamp(1, 26)) : '';
      final label = [if (tag.isNotEmpty) tag, if (desc.isNotEmpty) desc].join(' ');
      final parts = ['$pixels px', if (uni.isNotEmpty) 'U$uni'];
      (byPort[port] ??= []).add(label.isEmpty ? parts.join('  •  ') : '$label — ${parts.join('  •  ')}');
    }
    final out = <ControllerOutput>[];
    for (final port in byPort.keys.toList()..sort()) {
      out.add(ControllerOutput('Port ${port + 1}', byPort[port]!.join('\n')));
    }
    return out;
  }

  Future<int> _stringCount() async {
    final status = await _get('/status.xml');
    if (status != null) {
      final n = int.tryParse(_tag(status, 'np'));
      if (n != null && n > 0) return n;
    }
    return 16;
  }

  @override
  Future<bool> testOn() async {
    final n = await _stringCount();
    final b = StringBuffer('t=1&m=5');
    for (var j = 0; j < n; j++) {
      b.write('&e$j=1');
    }
    b.write('&s0=1&s1=1&s2=1&s3=1');
    return _postForm('/test.htm', b.toString());
  }

  @override
  Future<bool> testOff() => _postForm('/test.htm', 't=0&m=5');

  @override
  Future<bool> testPort(int port) async {
    final n = await _stringCount();
    final b = StringBuffer('t=1&m=5');
    for (var j = 0; j < n; j++) {
      b.write('&e$j=${j == (port - 1) ? 1 : 0}');
    }
    b.write('&s0=0&s1=0&s2=0&s3=0');
    return _postForm('/test.htm', b.toString());
  }
}
