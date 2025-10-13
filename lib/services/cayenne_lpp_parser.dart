import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import '../models/contact_telemetry.dart';
import 'buffer_reader.dart';
import 'meshcore_constants.dart';

/// Cayenne LPP (Low Power Payload) data parser
/// Used for decoding telemetry sensor data from MeshCore devices
class CayenneLppParser {
  /// Parse Cayenne LPP data into ContactTelemetry
  static ContactTelemetry parse(Uint8List data) {
    final reader = BufferReader(data);

    LatLng? gpsLocation;
    double? batteryPercentage;
    double? batteryMilliVolts;
    double? temperature;
    double? humidity;
    double? pressure;
    final extraSensorData = <String, dynamic>{};

    while (reader.hasRemaining) {
      try {
        final channel = reader.readByte();
        final type = reader.readByte();

        switch (type) {
          case MeshCoreConstants.lppDigitalInput:
            final value = reader.readByte();
            extraSensorData['digital_input_$channel'] = value;
            break;

          case MeshCoreConstants.lppDigitalOutput:
            final value = reader.readByte();
            extraSensorData['digital_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppAnalogInput:
            final value = reader.readInt16LE() / 100.0;
            extraSensorData['analog_input_$channel'] = value;
            // If this is a battery reading
            if (channel == 0 || channel == 1) {
              batteryMilliVolts = value * 1000;
              batteryPercentage = _calculateBatteryPercentage(value);
            }
            break;

          case MeshCoreConstants.lppAnalogOutput:
            final value = reader.readInt16LE() / 100.0;
            extraSensorData['analog_output_$channel'] = value;
            break;

          case MeshCoreConstants.lppIlluminanceSensor:
            final value = reader.readUInt16LE();
            extraSensorData['illuminance_$channel'] = value;
            break;

          case MeshCoreConstants.lppPresenceSensor:
            final value = reader.readByte();
            extraSensorData['presence_$channel'] = value;
            break;

          case MeshCoreConstants.lppTemperatureSensor:
            temperature = reader.readInt16LE() / 10.0;
            break;

          case MeshCoreConstants.lppHumiditySensor:
            humidity = reader.readByte() / 2.0;
            break;

          case MeshCoreConstants.lppAccelerometer:
            final x = reader.readInt16LE() / 1000.0;
            final y = reader.readInt16LE() / 1000.0;
            final z = reader.readInt16LE() / 1000.0;
            extraSensorData['accelerometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppBarometer:
            pressure = reader.readUInt16LE() / 10.0;
            break;

          case MeshCoreConstants.lppGyrometer:
            final x = reader.readInt16LE() / 100.0;
            final y = reader.readInt16LE() / 100.0;
            final z = reader.readInt16LE() / 100.0;
            extraSensorData['gyrometer_$channel'] = {'x': x, 'y': y, 'z': z};
            break;

          case MeshCoreConstants.lppGps:
            final lat = reader.readInt32LE() / 10000.0;
            final lon = reader.readInt32LE() / 10000.0;
            final alt = reader.readInt32LE() / 100.0;
            gpsLocation = LatLng(lat, lon);
            extraSensorData['altitude_$channel'] = alt;
            break;

          default:
            // Unknown type, skip remaining to avoid parsing errors
            reader.skip(reader.remainingBytesCount);
            break;
        }
      } catch (e) {
        // If we encounter a parsing error, break and return what we have
        break;
      }
    }

    return ContactTelemetry(
      gpsLocation: gpsLocation,
      batteryPercentage: batteryPercentage,
      batteryMilliVolts: batteryMilliVolts,
      temperature: temperature,
      humidity: humidity,
      pressure: pressure,
      timestamp: DateTime.now(),
      extraSensorData: extraSensorData.isNotEmpty ? extraSensorData : null,
    );
  }

  /// Calculate battery percentage from voltage (V)
  static double _calculateBatteryPercentage(double voltage) {
    // Standard lithium battery curve: 3.0V = 0%, 4.2V = 100%
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  /// Create Cayenne LPP data for GPS location
  static Uint8List createGpsData({
    required double latitude,
    required double longitude,
    double altitude = 0.0,
    int channel = 0,
  }) {
    final buffer = <int>[];

    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppGps);

    // Latitude (3 bytes, signed, 0.0001° precision)
    final lat = (latitude * 10000).round();
    buffer.add((lat >> 16) & 0xFF);
    buffer.add((lat >> 8) & 0xFF);
    buffer.add(lat & 0xFF);

    // Longitude (3 bytes, signed, 0.0001° precision)
    final lon = (longitude * 10000).round();
    buffer.add((lon >> 16) & 0xFF);
    buffer.add((lon >> 8) & 0xFF);
    buffer.add(lon & 0xFF);

    // Altitude (3 bytes, signed, 0.01m precision)
    final alt = (altitude * 100).round();
    buffer.add((alt >> 16) & 0xFF);
    buffer.add((alt >> 8) & 0xFF);
    buffer.add(alt & 0xFF);

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for temperature
  static Uint8List createTemperatureData(double celsius, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppTemperatureSensor);

    final temp = (celsius * 10).round();
    buffer.add((temp >> 8) & 0xFF);
    buffer.add(temp & 0xFF);

    return Uint8List.fromList(buffer);
  }

  /// Create Cayenne LPP data for battery voltage
  static Uint8List createBatteryData(double voltage, {int channel = 0}) {
    final buffer = <int>[];
    buffer.add(channel);
    buffer.add(MeshCoreConstants.lppAnalogInput);

    final volts = (voltage * 100).round();
    buffer.add((volts >> 8) & 0xFF);
    buffer.add(volts & 0xFF);

    return Uint8List.fromList(buffer);
  }
}
