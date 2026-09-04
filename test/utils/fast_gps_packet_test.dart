import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/fast_gps_packet.dart';

void main() {
  group('FastGpsPacket', () {
    test('encodes and parses a valid 16-byte packet', () {
      final packet = FastGpsPacket(
        senderKey6: 'aabbccddeeff',
        latitude: 46.0569,
        longitude: 14.5058,
        speedKmh: 37,
      );

      final encoded = packet.encodeBinary();
      expect(encoded.length, equals(16));
      expect(encoded[0], equals(FastGpsPacket.magic));

      final parsed = FastGpsPacket.tryParseBinary(encoded);

      expect(parsed, isNotNull);
      expect(parsed!.senderKey6, equals('aabbccddeeff'));
      expect(parsed.latitude, closeTo(46.0569, 0.000001));
      expect(parsed.longitude, closeTo(14.5058, 0.000001));
      expect(parsed.speedKmh, equals(37));
    });

    test('clamps speed to a single unsigned byte', () {
      final packet = FastGpsPacket(
        senderKey6: '001122334455',
        latitude: 1.0,
        longitude: 2.0,
        speedKmh: 999,
      );

      final parsed = FastGpsPacket.tryParseBinary(packet.encodeBinary());
      expect(parsed, isNotNull);
      expect(parsed!.speedKmh, equals(255));
    });

    test('supports negative coordinates', () {
      final packet = FastGpsPacket(
        senderKey6: '001122334455',
        latitude: -33.8688,
        longitude: -151.2093,
        speedKmh: 0,
      );

      final parsed = FastGpsPacket.tryParseBinary(packet.encodeBinary());
      expect(parsed, isNotNull);
      expect(parsed!.latitude, closeTo(-33.8688, 0.000001));
      expect(parsed.longitude, closeTo(-151.2093, 0.000001));
    });

    test('rejects malformed payloads', () {
      // Too short.
      expect(
        FastGpsPacket.tryParseBinary(Uint8List.fromList([0x47, 0x01])),
        isNull,
      );
      // Wrong magic at the correct length.
      expect(
        FastGpsPacket.tryParseBinary(
          Uint8List.fromList(List<int>.filled(16, 0)..[0] = 0x48),
        ),
        isNull,
      );
      // Legacy 19-byte format is no longer accepted.
      expect(
        FastGpsPacket.tryParseBinary(
          Uint8List.fromList(List<int>.filled(19, 0)..[0] = 0x47),
        ),
        isNull,
      );
    });

    test('rejects invalid coordinate ranges', () {
      final payload = Uint8List(16);
      payload[0] = FastGpsPacket.magic;
      payload.setRange(1, 7, [0, 1, 2, 3, 4, 5]);
      final data = ByteData.sublistView(payload);
      data.setInt32(
        7,
        (91.0 * FastGpsPacket.coordinateScale).round(),
        Endian.little,
      );
      data.setInt32(
        11,
        (14.5 * FastGpsPacket.coordinateScale).round(),
        Endian.little,
      );
      data.setUint8(15, 1);

      expect(FastGpsPacket.tryParseBinary(payload), isNull);
    });

    test('preserves at least meter accuracy', () {
      const latitude = 46.0569123;
      const longitude = 14.5058123;
      final packet = FastGpsPacket(
        senderKey6: 'aabbccddeeff',
        latitude: latitude,
        longitude: longitude,
        speedKmh: 5,
      );

      final parsed = FastGpsPacket.tryParseBinary(packet.encodeBinary());
      expect(parsed, isNotNull);

      final latMeters = (parsed!.latitude - latitude).abs() * 111320.0;
      final lonMeters =
          (parsed.longitude - longitude).abs() *
          111320.0 *
          math.cos(latitude * math.pi / 180.0);

      expect(latMeters, lessThan(1.0));
      expect(lonMeters, lessThan(1.0));
    });
  });
}
