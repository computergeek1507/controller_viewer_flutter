/// A single channel output row (pixel port, serial port, matrix, or other),
/// parsed from FPP's `/api/channel/output/*` responses. Ports the POC's
/// FPPOutput hierarchy (PixelOutput/SerialOutput/MatrixOutput/OtherOutput).
class FppOutput {
  final String portLabel;
  final String detail;

  FppOutput(this.portLabel, this.detail);

  /// Parse a `{channelOutputs:[...]}` document into a flat list of rows.
  static List<FppOutput> parseDocument(Map<String, dynamic> json) {
    final out = <FppOutput>[];
    final channelOutputs = json['channelOutputs'];
    if (channelOutputs is! List) return out;

    for (final co in channelOutputs.whereType<Map>()) {
      final type = (co['type'] ?? '').toString();
      final lower = type.toLowerCase();
      if (lower == 'bbb48string' || lower == 'rpiws281x') {
        final outputs = co['outputs'];
        if (outputs is List) {
          for (final o in outputs.whereType<Map>()) {
            out.add(_pixel(o.cast<String, dynamic>()));
          }
        }
      } else if (lower == 'bbbserial') {
        final outputs = co['outputs'];
        if (outputs is List) {
          for (final o in outputs.whereType<Map>()) {
            out.add(_serial(o.cast<String, dynamic>()));
          }
        }
      } else if (lower == 'ledpanelmatrix') {
        out.add(_matrix(co.cast<String, dynamic>()));
      } else {
        out.add(_other(co.cast<String, dynamic>()));
      }
    }
    return out;
  }

  /// A differential/smart-receiver port splits its model chain across
  /// sibling keys 'virtualStrings', 'virtualStringsB', 'virtualStringsC', ...
  /// (one per receiver leg, up to 6 receivers A-F), each itself a list of
  /// models (virtual strings) chained on that leg. A plain port just has
  /// 'virtualStrings'.
  static const _legSuffixes = ['', 'B', 'C', 'D', 'E', 'F'];

  static FppOutput _pixel(Map<String, dynamic> json) {
    final portNumber = _int(json['portNumber'], -1);
    final legs = <String, List<Map<String, dynamic>>>{};
    for (final suf in _legSuffixes) {
      final key = suf.isEmpty ? 'virtualStrings' : 'virtualStrings$suf';
      final vs = json[key];
      if (vs is! List) continue;
      final models = vs.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
      if (models.isNotEmpty) legs[suf] = models;
    }
    final multiLeg = legs.length > 1;
    final lines = <String>[];
    for (final entry in legs.entries) {
      final legTag = multiLeg ? (entry.key.isEmpty ? 'A' : entry.key) : '';
      for (final s in entry.value) {
        final line = _virtualString(s, legTag);
        if (line.isNotEmpty) lines.add(line);
      }
    }
    final detail = lines.join('\n');
    return FppOutput('Pixel Port ${portNumber + 1}', detail.isEmpty ? '(empty)' : detail);
  }

  /// Format one virtual string's wiring config into a single line.
  /// [legTag] is the smart-receiver leg letter ('A', 'B', ...) when this
  /// port is split across multiple receiver legs, else empty.
  static String _virtualString(Map<String, dynamic> s, [String legTag = '']) {
    final desc = (s['description'] ?? '').toString();
    final remoteTag = _remoteTag(s['smartRemote']);
    final tag = [if (legTag.isNotEmpty) legTag, if (remoteTag.isNotEmpty) remoteTag].join(' ');
    final label = [if (tag.isNotEmpty) tag, if (desc.isNotEmpty) desc].join(' ');

    final pixels = _int(s['pixelCount'], 0);
    final order = (s['colorOrder'] ?? '').toString();
    final start = _int(s['startChannel'], -1);
    final group = _int(s['groupCount'], 0);
    final startNulls = _int(s['nullNodes'], 0);
    final endNulls = _int(s['endNulls'], 0);
    final zig = _int(s['zigZag'], 0);
    final reverse = _int(s['reverse'], 0);
    final bri = _int(s['brightness'], -1);
    final gamma = (s['gamma'] ?? '').toString();

    final parts = <String>[];
    if (pixels > 0) parts.add('$pixels px');
    if (order.isNotEmpty) parts.add(order);
    if (start >= 0) parts.add('ch $start');
    if (group > 1) parts.add('group $group');
    if (startNulls > 0 || endNulls > 0) parts.add('null $startNulls/$endNulls');
    if (zig > 0) parts.add('zigzag $zig');
    if (reverse != 0) parts.add('reversed');
    if (bri >= 0 && bri != 100) parts.add('$bri%');
    if (gamma.isNotEmpty && gamma != '1.0') parts.add('γ$gamma');

    if (label.isEmpty && parts.isEmpty) return '';
    if (parts.isEmpty) return label;
    return label.isEmpty ? parts.join(' • ') : '$label — ${parts.join(' • ')}';
  }

  /// FPP smart-receiver index (1->A, 2->B, ...) or '' when not on a receiver.
  static String _remoteTag(dynamic v) {
    final n = _int(v, 0);
    if (n <= 0) return '';
    return String.fromCharCode(0x40 + n.clamp(1, 26)); // 1 -> 'A'
  }

  static FppOutput _serial(Map<String, dynamic> json) {
    final n = _int(json['outputNumber'], -1);
    final start = _int(json['startChannel'], -1);
    final count = _int(json['channelCount'], 0);
    return FppOutput('Serial Port ${n + 1}', 'Start Channel: $start, Channel Count: $count');
  }

  static FppOutput _matrix(Map<String, dynamic> json) {
    final subType = (json['subType'] ?? '').toString();
    final w = _int(json['panelWidth'], 0);
    final h = _int(json['panelHeight'], 0);
    final start = _int(json['startChannel'], -1);
    final count = _int(json['channelCount'], 0);
    final color = (json['colorOrder'] ?? '').toString();
    return FppOutput(
      'Panel Matrix',
      '$subType  H:${h}xW:$w  Start: $start  Count: $count  Color: $color',
    );
  }

  static FppOutput _other(Map<String, dynamic> json) {
    final type = (json['type'] ?? '').toString();
    final start = _int(json['startChannel'], -1);
    final count = _int(json['channelCount'], 0);
    return FppOutput(type.isEmpty ? 'Output' : type, 'Start Channel: $start, Channel Count: $count');
  }

  static int _int(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
