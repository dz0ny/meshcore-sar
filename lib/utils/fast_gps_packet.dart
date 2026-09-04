import 'dart:typed_data';

/// Fast-GPS position beacon, wire-compatible with the MeshUI firmware
/// (`maybeSendFastGpsUpdate` in MyMesh.cpp).
///
/// 16-byte binary payload sent as a `DATA_TYPE_DEV` group datagram on a
/// non-public channel:
///
/// ```
/// [0]      magic 0x47 ('G')
/// [1..6]   sender public-key prefix (6 bytes)
/// [7..10]  latitude  in microdegrees (int32, little-endian)
/// [11..14] longitude in microdegrees (int32, little-endian)
/// [15]     ground speed in km/h (uint8, clamped 0..255)
/// ```
///
/// The beacon carries no timestamp — receivers stamp their own RX time.
class FastGpsPacket {
  static const int magic = 0x47; // 'G'
  static const int _payloadLength = 16;
  // Store coordinates in microdegrees. This preserves sub-meter precision,
  // which comfortably satisfies the meter-accuracy requirement.
  static const double coordinateScale = 1e6;

  final String senderKey6;
  final double latitude;
  final double longitude;

  /// Ground speed in km/h (0..255), as carried in the beacon's trailing byte.
  final int speedKmh;

  const FastGpsPacket({
    required this.senderKey6,
    required this.latitude,
    required this.longitude,
    this.speedKmh = 0,
  });

  static bool isFastGpsBinary(Uint8List payload) =>
      payload.length == _payloadLength && payload[0] == magic;

  static FastGpsPacket? tryParseBinary(Uint8List payload) {
    if (!isFastGpsBinary(payload)) return null;

    final key6 = payload
        .sublist(1, 7)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final data = ByteData.sublistView(payload);
    final latitude = data.getInt32(7, Endian.little) / coordinateScale;
    final longitude = data.getInt32(11, Endian.little) / coordinateScale;
    final speedKmh = data.getUint8(15);

    if (!_isValidCoordinate(latitude, longitude)) {
      return null;
    }

    return FastGpsPacket(
      senderKey6: key6,
      latitude: latitude,
      longitude: longitude,
      speedKmh: speedKmh,
    );
  }

  Uint8List encodeBinary() {
    final out = Uint8List(_payloadLength);
    final data = ByteData.sublistView(out);
    out[0] = magic;
    for (var i = 0; i < 6; i++) {
      out[1 + i] = int.parse(senderKey6.substring(i * 2, i * 2 + 2), radix: 16);
    }
    data.setInt32(7, (latitude * coordinateScale).round(), Endian.little);
    data.setInt32(11, (longitude * coordinateScale).round(), Endian.little);
    data.setUint8(15, speedKmh.clamp(0, 255));
    return out;
  }

  static bool _isValidCoordinate(double latitude, double longitude) {
    if (!latitude.isFinite || !longitude.isFinite) return false;
    return latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }
}
