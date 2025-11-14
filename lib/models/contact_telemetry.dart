import 'package:latlong2/latlong.dart';

/// Contact telemetry data from MeshCore device
class ContactTelemetry {
  final LatLng? gpsLocation;
  final double? batteryPercentage;
  final double? batteryMilliVolts;
  final double? temperature;
  final DateTime timestamp;

  // Additional sensor data
  final double? humidity;
  final double? pressure;
  final Map<String, dynamic>? extraSensorData;

  ContactTelemetry({
    this.gpsLocation,
    this.batteryPercentage,
    this.batteryMilliVolts,
    this.temperature,
    required this.timestamp,
    this.humidity,
    this.pressure,
    this.extraSensorData,
  });

  /// Check if telemetry data is recent (within last 5 minutes)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inMinutes < 5;
  }

  /// Check if battery level is low (< 20%)
  bool get isLowBattery {
    return batteryPercentage != null && batteryPercentage! < 20.0;
  }

  /// Check if battery level is critical (< 10%)
  bool get isCriticalBattery {
    return batteryPercentage != null && batteryPercentage! < 10.0;
  }

  /// Get battery status color indicator
  String get batteryStatus {
    if (batteryPercentage == null) return 'unknown';
    if (batteryPercentage! > 50) return 'good';
    if (batteryPercentage! > 20) return 'medium';
    return 'low';
  }

  ContactTelemetry copyWith({
    LatLng? gpsLocation,
    double? batteryPercentage,
    double? batteryMilliVolts,
    double? temperature,
    DateTime? timestamp,
    double? humidity,
    double? pressure,
    Map<String, dynamic>? extraSensorData,
  }) {
    return ContactTelemetry(
      gpsLocation: gpsLocation ?? this.gpsLocation,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      batteryMilliVolts: batteryMilliVolts ?? this.batteryMilliVolts,
      temperature: temperature ?? this.temperature,
      timestamp: timestamp ?? this.timestamp,
      humidity: humidity ?? this.humidity,
      pressure: pressure ?? this.pressure,
      extraSensorData: extraSensorData ?? this.extraSensorData,
    );
  }

  @override
  String toString() {
    return 'ContactTelemetry(gps: $gpsLocation, battery: $batteryPercentage%, temp: $temperature°C, time: $timestamp)';
  }
}
