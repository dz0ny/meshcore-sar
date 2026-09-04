import 'package:latlong2/latlong.dart';

class MessageContactLocation {
  final LatLng location;
  final String source;
  final DateTime capturedAt;
  final DateTime? sourceTimestamp;

  const MessageContactLocation({
    required this.location,
    required this.source,
    required this.capturedAt,
    this.sourceTimestamp,
  });

  String get technicalSourceLabel {
    switch (source) {
      case 'shared':
        return 'shared location';
      case 'gps':
        return 'shared location';
      case 'telemetry':
        return 'live telemetry';
      case 'advert':
        return 'shared advert';
      default:
        return source;
    }
  }

  String get formattedCoordinates =>
      '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

  Map<String, dynamic> toJson() {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
      'source': source,
      'capturedAtMillis': capturedAt.millisecondsSinceEpoch,
      'sourceTimestampMillis': sourceTimestamp?.millisecondsSinceEpoch,
    };
  }

  static MessageContactLocation? fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final source = json['source'];
    final capturedAtMillis = json['capturedAtMillis'];
    if (latitude is! num ||
        longitude is! num ||
        source is! String ||
        capturedAtMillis is! int) {
      return null;
    }

    return MessageContactLocation(
      location: LatLng(latitude.toDouble(), longitude.toDouble()),
      source: source,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMillis),
      sourceTimestamp: json['sourceTimestampMillis'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              json['sourceTimestampMillis'] as int,
            )
          : null,
    );
  }
}
