import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/services/cayenne_lpp_parser.dart';
import 'package:meshcore_client/meshcore_client.dart';

void main() {
  group('CayenneLppParser - GPS Codec Tests', () {
    test('GPS encoding uses correct 3-byte signed BE format', () {
      // Test coordinates (Ljubljana, Slovenia)
      const double lat = 46.0569;
      const double lon = 14.5058;
      const double alt = 295.0;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
        altitude: alt,
        channel: 0,
      );

      // Expected format (Standard Cayenne LPP):
      // [0] = channel (0)
      // [1] = type (136 = 0x88 = lppGps)
      // [2-4] = lat as 24-bit signed BE
      // [5-7] = lon as 24-bit signed BE
      // [8-10] = alt as 24-bit signed BE
      expect(encoded.length, equals(11));
      expect(encoded[0], equals(0)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppGps)); // type 0x88

      // Verify big-endian encoding (3 bytes each)
      final latEncoded = (encoded[2] << 16) | (encoded[3] << 8) | encoded[4];
      final lonEncoded = (encoded[5] << 16) | (encoded[6] << 8) | encoded[7];
      final altEncoded = (encoded[8] << 16) | (encoded[9] << 8) | encoded[10];

      expect(latEncoded, equals(460569)); // 46.0569 * 10000
      expect(lonEncoded, equals(145058)); // 14.5058 * 10000
      expect(altEncoded, equals(29500)); // 295.0 * 100
    });

    test('GPS decoding uses correct 3-byte BE format and divisor', () {
      // Create raw GPS telemetry packet (standard Cayenne LPP format)
      final buffer = <int>[];
      buffer.add(0); // channel
      buffer.add(MeshCoreConstants.lppGps); // type 0x88

      // Lat: 46.0569 * 10000 = 460569 = 0x070719
      buffer.add(0x07); // MSB
      buffer.add(0x07);
      buffer.add(0x19); // LSB

      // Lon: 14.5058 * 10000 = 145058 = 0x0236A2
      buffer.add(0x02);
      buffer.add(0x36);
      buffer.add(0xA2);

      // Alt: 295.0 * 100 = 29500 = 0x7 33C
      buffer.add(0x00);
      buffer.add(0x73);
      buffer.add(0x3C);

      final telemetry = CayenneLppParser.parse(Uint8List.fromList(buffer));

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(telemetry.gpsLocation!.longitude, closeTo(14.5058, 0.0001));

      // Verify altitude is stored in extra data
      expect(telemetry.extraSensorData, isNotNull);
      expect(telemetry.extraSensorData!['altitude_0'], closeTo(295.0, 0.01));
    });

    test('GPS round-trip encoding/decoding maintains precision', () {
      // Test various coordinates
      final testCases = [
        LatLng(46.0569, 14.5058), // Ljubljana
        LatLng(37.7749, -122.4194), // San Francisco
        LatLng(-33.8688, 151.2093), // Sydney
        LatLng(0.0, 0.0), // Null Island
        LatLng(89.9999, 179.9999), // Near max
        LatLng(-89.9999, -179.9999), // Near min
      ];

      for (final coords in testCases) {
        final encoded = CayenneLppParser.createGpsData(
          latitude: coords.latitude,
          longitude: coords.longitude,
          altitude: 100.0,
        );

        final decoded = CayenneLppParser.parse(encoded);

        expect(
          decoded.gpsLocation,
          isNotNull,
          reason: 'Failed to decode: $coords',
        );
        expect(
          decoded.gpsLocation!.latitude,
          closeTo(coords.latitude, 0.0001),
          reason: 'Latitude mismatch for $coords',
        );
        expect(
          decoded.gpsLocation!.longitude,
          closeTo(coords.longitude, 0.0001),
          reason: 'Longitude mismatch for $coords',
        );
      }
    });

    test('GPS decoding validates coordinate ranges', () {
      // This test documents that coordinates are decoded correctly
      // and any validation warnings are logged (not enforced)

      // Valid coordinates should decode without issue
      final validBuffer = <int>[];
      validBuffer.add(0); // channel
      validBuffer.add(MeshCoreConstants.lppGps);

      // Lat: 45.0 * 10000 = 450000 = 0x06DDD0 (3 bytes BE)
      validBuffer.addAll([0x06, 0xDD, 0xD0]);
      // Lon: 10.0 * 10000 = 100000 = 0x0186A0 (3 bytes BE)
      validBuffer.addAll([0x01, 0x86, 0xA0]);
      // Alt: 0 (3 bytes BE)
      validBuffer.addAll([0x00, 0x00, 0x00]);

      final telemetry = CayenneLppParser.parse(Uint8List.fromList(validBuffer));

      expect(telemetry.gpsLocation, isNotNull);
      expect(telemetry.gpsLocation!.latitude, closeTo(45.0, 0.0001));
      expect(telemetry.gpsLocation!.longitude, closeTo(10.0, 0.0001));
    });

    test('GPS encoding handles negative coordinates correctly', () {
      const lat = -33.8688;
      const lon = -151.2093;

      final encoded = CayenneLppParser.createGpsData(
        latitude: lat,
        longitude: lon,
      );

      // Verify 3-byte signed encoding
      // Lat: -33.8688 * 10000 = -338688
      // In 24-bit two's complement: -338688 + 0x1000000 = 16438528 = 0xFAD500
      final latEncoded = (encoded[2] << 16) | (encoded[3] << 8) | encoded[4];
      // Lon: -151.2093 * 10000 = -1512093
      // In 24-bit two's complement: -1512093 + 0x1000000 = 15265123 = 0xE8ED63
      final lonEncoded = (encoded[5] << 16) | (encoded[6] << 8) | encoded[7];

      expect(latEncoded, equals(0xFAD500)); // Verify two's complement
      expect(lonEncoded, equals(0xE8ED63));

      // Verify decoding
      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation!.latitude, closeTo(lat, 0.0001));
      expect(decoded.gpsLocation!.longitude, closeTo(lon, 0.0001));
    });

    test('GPS encoding with altitude uses correct precision', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 0.0,
        longitude: 0.0,
        altitude: 1234.56,
      );

      // Altitude is at bytes 8-10 (3 bytes BE)
      // Alt: 1234.56 * 100 = 123456 = 0x01E240
      final altEncoded = (encoded[8] << 16) | (encoded[9] << 8) | encoded[10];

      // Altitude precision is 0.01m (divide by 100)
      expect(altEncoded, equals(123456)); // 1234.56 * 100

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.extraSensorData!['altitude_0'], closeTo(1234.56, 0.01));
    });

    test('GPS encoding supports custom channel', () {
      final encoded = CayenneLppParser.createGpsData(
        latitude: 1.0,
        longitude: 2.0,
        channel: 5,
      );

      expect(encoded[0], equals(5)); // channel

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.extraSensorData!['altitude_5'], isNotNull);
    });

    test(
      'OLD BUG: Using 4-byte LE instead of 3-byte BE caused wrong coords',
      () {
        // This test documents the bug that was fixed
        // The old code used 4-byte int32 LE (MeshCore advertisement format)
        // instead of 3-byte signed BE (standard Cayenne LPP format)

        // Real data from device:
        // Hex: 06 f7 08 02 38 0e 01 2c 46
        final realData = <int>[
          0x00, 0x88, // channel 0, type GPS
          0x06, 0xf7, 0x08, // lat (3 bytes BE)
          0x02, 0x38, 0x0e, // lon (3 bytes BE)
          0x01, 0x2c, 0x46, // alt (3 bytes BE)
        ];

        // CORRECT decoding (3-byte BE):
        final correctLat =
            ((0x06 << 16) | (0xf7 << 8) | 0x08) / 10000.0; // 45.6456°
        final correctLon =
            ((0x02 << 16) | (0x38 << 8) | 0x0e) / 10000.0; // 14.5422°

        // OLD BUGGY decoding (4-byte LE - reads wrong bytes!):
        // Would read: lat=06f70802, lon=38010e2c (completely wrong)
        final buggyLatRaw = 0x02 | (0x08 << 8) | (0xf7 << 16) | (0x06 << 24);
        final buggyLat = buggyLatRaw / 10000.0; // 3414.1958° (out of range!)

        // Verify current implementation decodes correctly
        final telemetry = CayenneLppParser.parse(Uint8List.fromList(realData));
        expect(telemetry.gpsLocation, isNotNull);
        expect(telemetry.gpsLocation!.latitude, closeTo(correctLat, 0.0001));
        expect(telemetry.gpsLocation!.longitude, closeTo(correctLon, 0.0001));

        // Verify it doesn't produce the buggy values
        expect(telemetry.gpsLocation!.latitude, isNot(equals(buggyLat)));
        expect(telemetry.gpsLocation!.latitude, lessThan(90.0)); // Valid range
        expect(telemetry.gpsLocation!.latitude, greaterThan(-90.0));
      },
    );
  });

  group('CayenneLppParser - Other Sensor Tests', () {
    test('temperature encoding and decoding', () {
      const tempCelsius = 23.5;

      final encoded = CayenneLppParser.createTemperatureData(
        tempCelsius,
        channel: 1,
      );

      expect(encoded.length, equals(4)); // channel + type + 2 bytes
      expect(encoded[0], equals(1)); // channel
      expect(encoded[1], equals(MeshCoreConstants.lppTemperatureSensor));

      final decoded = CayenneLppParser.parse(encoded);
      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('temperature handles negative values', () {
      const tempCelsius = -15.3;

      final encoded = CayenneLppParser.createTemperatureData(tempCelsius);
      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.temperature, closeTo(tempCelsius, 0.1));
    });

    test('battery voltage encoding and decoding', () {
      const voltage = 3.85;

      final encoded = CayenneLppParser.createBatteryData(voltage);

      expect(encoded.length, equals(4));
      expect(encoded[1], equals(MeshCoreConstants.lppAnalogInput));

      final decoded = CayenneLppParser.parse(encoded);

      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
      expect(decoded.batteryPercentage, greaterThan(0));
      expect(decoded.batteryPercentage, lessThanOrEqualTo(100));
    });

    test('battery percentage calculation', () {
      // Test battery curve: 3.0V = 0%, 4.2V = 100%
      final testCases = {
        2.8: 0.0, // Below minimum
        3.0: 0.0, // Minimum
        3.6: 50.0, // Middle
        4.2: 100.0, // Maximum
        4.5: 100.0, // Above maximum
      };

      for (final entry in testCases.entries) {
        final voltage = entry.key;
        final expectedPercent = entry.value;

        final encoded = CayenneLppParser.createBatteryData(voltage);
        final decoded = CayenneLppParser.parse(encoded);

        expect(
          decoded.batteryPercentage,
          closeTo(expectedPercent, 1),
          reason: 'Battery ${voltage}V should be ~$expectedPercent%',
        );
      }
    });

    test('analog input is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0); // channel 0
      buffer.setUint8(1, MeshCoreConstants.lppAnalogInput);
      buffer.setInt16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('voltage sensor is recognized as battery', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppVoltageSensor);
      buffer.setUint16(2, 385, Endian.big); // 3.85V * 100

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.batteryPercentage, isNotNull);
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('humidity sensor decoding', () {
      final buffer = ByteData(3);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppHumiditySensor);
      buffer.setUint8(2, 130); // 65% humidity (130 / 2)

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.humidity, equals(65.0));
    });

    test('barometer sensor decoding', () {
      final buffer = ByteData(4);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppBarometer);
      buffer.setUint16(2, 10132, Endian.big); // 1013.2 hPa * 10

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.pressure, closeTo(1013.2, 0.1));
    });

    test('accelerometer sensor stores in extra data', () {
      final buffer = ByteData(8);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, MeshCoreConstants.lppAccelerometer);
      buffer.setInt16(2, 1000, Endian.big); // x: 1.0 g
      buffer.setInt16(4, -500, Endian.big); // y: -0.5 g
      buffer.setInt16(6, 2000, Endian.big); // z: 2.0 g

      final decoded = CayenneLppParser.parse(buffer.buffer.asUint8List());

      expect(decoded.extraSensorData, isNotNull);
      final accel = decoded.extraSensorData!['accelerometer_0'];
      expect(accel['x'], closeTo(1.0, 0.001));
      expect(accel['y'], closeTo(-0.5, 0.001));
      expect(accel['z'], closeTo(2.0, 0.001));
    });

    test('unknown sensor type is skipped gracefully', () {
      final buffer = ByteData(5);
      buffer.setUint8(0, 0);
      buffer.setUint8(1, 255); // Unknown type
      buffer.setUint8(2, 1);
      buffer.setUint8(3, 2);
      buffer.setUint8(4, 3);

      // Should not throw, just skip unknown data
      expect(
        () => CayenneLppParser.parse(buffer.buffer.asUint8List()),
        returnsNormally,
      );
    });

    test('multiple sensors in single packet', () {
      // Create a combined packet with multiple sensors
      final buffer = <int>[];

      // GPS (channel 2) - use channel 2 to avoid battery auto-detection
      buffer.add(2); // channel
      buffer.add(MeshCoreConstants.lppGps);
      // Lat: 46.0569 * 10000 = 460569 = 0x070719 (3 bytes BE)
      buffer.addAll([0x07, 0x07, 0x19]);
      // Lon: 14.5058 * 10000 = 145058 = 0x0236A2 (3 bytes BE)
      buffer.addAll([0x02, 0x36, 0xA2]);
      // Alt: 0 (3 bytes BE)
      buffer.addAll([0x00, 0x00, 0x00]);

      // Temperature (channel 3)
      buffer.add(3); // channel
      buffer.add(MeshCoreConstants.lppTemperatureSensor);
      buffer.add(0x00); // 23.5°C * 10 = 235 (2 bytes BE)
      buffer.add(0xEB);

      // Battery (channel 0 - required for battery detection)
      buffer.add(0); // channel
      buffer.add(MeshCoreConstants.lppAnalogInput);
      buffer.add(0x01); // 3.85V * 100 = 385 (2 bytes BE)
      buffer.add(0x81);

      final decoded = CayenneLppParser.parse(Uint8List.fromList(buffer));

      // All sensors should be decoded
      expect(decoded.gpsLocation, isNotNull);
      expect(decoded.gpsLocation!.latitude, closeTo(46.0569, 0.0001));
      expect(decoded.temperature, closeTo(23.5, 0.1));
      expect(decoded.batteryMilliVolts, closeTo(3850, 1));
    });

    test('empty data returns empty telemetry', () {
      final empty = Uint8List(0);
      final decoded = CayenneLppParser.parse(empty);

      expect(decoded.gpsLocation, isNull);
      expect(decoded.batteryPercentage, isNull);
      expect(decoded.temperature, isNull);
      expect(decoded.extraSensorData, isNull);
      expect(decoded.timestamp, isNotNull); // Timestamp is always set
    });

    test('timestamp is set to parse time', () {
      final before = DateTime.now();
      final data = CayenneLppParser.createTemperatureData(20.0);
      final decoded = CayenneLppParser.parse(data);
      final after = DateTime.now();

      expect(
        decoded.timestamp.isAfter(before) ||
            decoded.timestamp.isAtSameMomentAs(before),
        isTrue,
      );
      expect(
        decoded.timestamp.isBefore(after) ||
            decoded.timestamp.isAtSameMomentAs(after),
        isTrue,
      );
    });
  });

  group('CayenneLppParser - ContactTelemetry Properties', () {
    test('isRecent returns true for fresh telemetry', () {
      final data = CayenneLppParser.createTemperatureData(20.0);
      final telemetry = CayenneLppParser.parse(data);

      expect(telemetry.isRecent, isTrue);
    });

    test('battery status helpers work correctly', () {
      final lowBattery = ContactTelemetry(
        batteryPercentage: 15.0,
        timestamp: DateTime.now(),
      );
      expect(lowBattery.isLowBattery, isTrue);
      expect(lowBattery.batteryStatus, equals('low'));

      final criticalBattery = ContactTelemetry(
        batteryPercentage: 5.0,
        timestamp: DateTime.now(),
      );
      expect(criticalBattery.isCriticalBattery, isTrue);

      final goodBattery = ContactTelemetry(
        batteryPercentage: 75.0,
        timestamp: DateTime.now(),
      );
      expect(goodBattery.isLowBattery, isFalse);
      expect(goodBattery.batteryStatus, equals('good'));
    });

    test('copyWith creates modified copy', () {
      final original = ContactTelemetry(
        gpsLocation: LatLng(1, 2),
        batteryPercentage: 50.0,
        temperature: 20.0,
        timestamp: DateTime.now(),
      );

      final modified = original.copyWith(temperature: 25.0);

      expect(modified.temperature, equals(25.0));
      expect(modified.batteryPercentage, equals(50.0)); // Unchanged
      expect(modified.gpsLocation, equals(original.gpsLocation)); // Unchanged
    });

    test('toString provides readable output', () {
      final telemetry = ContactTelemetry(
        gpsLocation: LatLng(46.0569, 14.5058),
        batteryPercentage: 75.0,
        temperature: 23.5,
        timestamp: DateTime.now(),
      );

      final str = telemetry.toString();
      expect(str, contains('ContactTelemetry'));
      expect(str, contains('46.0569'));
      expect(str, contains('75'));
      expect(str, contains('23.5'));
    });
  });
}
