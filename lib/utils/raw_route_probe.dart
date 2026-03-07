import 'dart:typed_data';

class RawRouteProbeRequest {
  static const int _binaryMagic = 0x70; // 'p'

  final int nonce;
  final String requesterKey6;

  const RawRouteProbeRequest({
    required this.nonce,
    required this.requesterKey6,
  });

  static RawRouteProbeRequest? tryParseBinary(Uint8List payload) {
    if (payload.length != 11 || payload[0] != _binaryMagic) return null;
    try {
      final nonce =
          (payload[1] << 24) |
          (payload[2] << 16) |
          (payload[3] << 8) |
          payload[4];
      final requesterKey6 = payload
          .sublist(5, 11)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join()
          .toLowerCase();
      return RawRouteProbeRequest(nonce: nonce, requesterKey6: requesterKey6);
    } catch (_) {
      return null;
    }
  }

  Uint8List encodeBinary() {
    if (!RegExp(r'^[0-9a-fA-F]{12}$').hasMatch(requesterKey6)) {
      throw ArgumentError.value(
        requesterKey6,
        'requesterKey6',
        'Expected 12 hex chars',
      );
    }
    final out = Uint8List(11);
    out[0] = _binaryMagic;
    out[1] = (nonce >> 24) & 0xFF;
    out[2] = (nonce >> 16) & 0xFF;
    out[3] = (nonce >> 8) & 0xFF;
    out[4] = nonce & 0xFF;
    for (var i = 0; i < 6; i++) {
      out[5 + i] = int.parse(
        requesterKey6.substring(i * 2, i * 2 + 2),
        radix: 16,
      );
    }
    return out;
  }
}

class RawRouteProbeAck {
  static const int _binaryMagic = 0x71; // 'q'

  final int nonce;

  const RawRouteProbeAck({required this.nonce});

  static RawRouteProbeAck? tryParseBinary(Uint8List payload) {
    if (payload.length != 5 || payload[0] != _binaryMagic) return null;
    try {
      final nonce =
          (payload[1] << 24) |
          (payload[2] << 16) |
          (payload[3] << 8) |
          payload[4];
      return RawRouteProbeAck(nonce: nonce);
    } catch (_) {
      return null;
    }
  }

  Uint8List encodeBinary() {
    final out = Uint8List(5);
    out[0] = _binaryMagic;
    out[1] = (nonce >> 24) & 0xFF;
    out[2] = (nonce >> 16) & 0xFF;
    out[3] = (nonce >> 8) & 0xFF;
    out[4] = nonce & 0xFF;
    return out;
  }
}
