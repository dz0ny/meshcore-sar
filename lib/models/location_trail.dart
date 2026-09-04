import 'package:latlong2/latlong.dart';

/// Represents a single point in a location trail
class TrailPoint {
  final LatLng position;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;

  TrailPoint({
    required this.position,
    required this.timestamp,
    this.accuracy,
    this.speed,
  });

  Map<String, dynamic> toJson() => {
        'lat': position.latitude,
        'lon': position.longitude,
        'timestamp': timestamp.toIso8601String(),
        'accuracy': accuracy,
        'speed': speed,
      };

  factory TrailPoint.fromJson(Map<String, dynamic> json) {
    return TrailPoint(
      position: LatLng(json['lat'] as double, json['lon'] as double),
      timestamp: DateTime.parse(json['timestamp'] as String),
      accuracy: json['accuracy'] as double?,
      speed: json['speed'] as double?,
    );
  }
}

/// Represents a location trail (breadcrumb trail) on the map
class LocationTrail {
  final String id;
  final List<TrailPoint> points;
  final DateTime startTime;
  DateTime? endTime;
  bool isActive;

  LocationTrail({
    required this.id,
    List<TrailPoint>? points,
    DateTime? startTime,
    this.endTime,
    this.isActive = true,
  })  : points = points ?? [],
        startTime = startTime ?? DateTime.now();

  /// Add a new point to the trail
  void addPoint(TrailPoint point) {
    points.add(point);
  }

  /// Get total distance traveled in meters
  double get totalDistance {
    if (points.length < 2) return 0;

    final distance = Distance();
    double total = 0;

    for (int i = 0; i < points.length - 1; i++) {
      total += distance.as(
        LengthUnit.Meter,
        points[i].position,
        points[i + 1].position,
      );
    }

    return total;
  }

  /// Get duration of the trail
  Duration get duration {
    if (points.isEmpty) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Get list of LatLng points for rendering
  List<LatLng> get latLngPoints => points.map((p) => p.position).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isActive': isActive,
      };

  factory LocationTrail.fromJson(Map<String, dynamic> json) {
    return LocationTrail(
      id: json['id'] as String,
      points: (json['points'] as List)
          .map((p) => TrailPoint.fromJson(p as Map<String, dynamic>))
          .toList(),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
