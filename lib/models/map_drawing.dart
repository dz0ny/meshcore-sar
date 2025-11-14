import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Drawing shape type
enum DrawingShapeType {
  line,
  rectangle,
}

/// Drawing color enum for compact network transmission
enum DrawingColor {
  red,      // 0
  blue,     // 1
  green,    // 2
  yellow,   // 3
  orange,   // 4
  purple,   // 5
  pink,     // 6
  cyan,     // 7
}

/// Drawing colors available for user selection
class DrawingColors {
  static const List<Color> palette = [
    Colors.red,     // index 0
    Colors.blue,    // index 1
    Colors.green,   // index 2
    Colors.yellow,  // index 3
    Colors.orange,  // index 4
    Colors.purple,  // index 5
    Colors.pink,    // index 6
    Colors.cyan,    // index 7
  ];

  static String colorToName(Color color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.green) return 'Green';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.cyan) return 'Cyan';
    return 'Unknown';
  }

  /// Convert Color to enum index for network transmission
  static int colorToIndex(Color color) {
    for (int i = 0; i < palette.length; i++) {
      if (palette[i].value == color.value) {
        return i;
      }
    }
    return 0; // Default to red if not found
  }

  /// Convert enum index to Color for network reception
  static Color indexToColor(int index) {
    if (index >= 0 && index < palette.length) {
      return palette[index];
    }
    return palette[0]; // Default to red if invalid index
  }
}

/// Base class for map drawings
abstract class MapDrawing {
  final String id;
  final DrawingShapeType type;
  final Color color;
  final DateTime createdAt;
  final String? senderName; // Name of sender (null if local drawing)
  final bool isReceived; // True if drawing was received from another node
  final String? messageId; // ID of the source message (for navigation)
  final bool isShared; // Whether drawing has been broadcast over mesh
  final bool isSent; // Whether this is a sent drawing (vs received)
  final bool isHidden; // Temporary visibility toggle (session only, not persisted)

  MapDrawing({
    required this.id,
    required this.type,
    required this.color,
    required this.createdAt,
    this.senderName,
    this.isReceived = false,
    this.messageId,
    this.isShared = false,
    this.isSent = false,
    this.isHidden = false,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson();

  /// Convert to JSON for network transmission (compact format)
  /// Uses short field names and excludes createdAt to minimize message size
  /// Sender will be fetched from packet metadata
  Map<String, dynamic> toNetworkJson();

  /// Parse network JSON (compact format)
  /// senderName and messageId will be populated from packet metadata
  static MapDrawing? fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
  }) {
    final typeNum = json['t'] as int?;
    if (typeNum == null || typeNum < 0 || typeNum >= DrawingShapeType.values.length) {
      return null;
    }

    try {
      final type = DrawingShapeType.values[typeNum];

      switch (type) {
        case DrawingShapeType.line:
          return LineDrawing.fromNetworkJson(
            json,
            senderName: senderName,
            messageId: messageId,
          );
        case DrawingShapeType.rectangle:
          return RectangleDrawing.fromNetworkJson(
            json,
            senderName: senderName,
            messageId: messageId,
          );
      }
    } catch (e) {
      return null;
    }
  }

  /// Create from JSON
  static MapDrawing? fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String?;
    if (typeStr == null) return null;

    try {
      final type = DrawingShapeType.values.firstWhere(
        (e) => e.toString() == 'DrawingShapeType.$typeStr',
      );

      switch (type) {
        case DrawingShapeType.line:
          return LineDrawing.fromJson(json);
        case DrawingShapeType.rectangle:
          return RectangleDrawing.fromJson(json);
      }
    } catch (e) {
      return null;
    }
  }

  /// Get the center point of the drawing
  LatLng getCenter();

  /// Get the bounds of the drawing
  LatLngBounds getBounds();
}

/// Line drawing on map
class LineDrawing extends MapDrawing {
  final List<LatLng> points;

  LineDrawing({
    required super.id,
    required super.color,
    required super.createdAt,
    required this.points,
    super.senderName,
    super.isReceived,
    super.messageId,
    super.isShared,
    super.isSent,
    super.isHidden,
  }) : super(type: DrawingShapeType.line);

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'points': points.map((p) => {'lat': p.latitude, 'lon': p.longitude}).toList(),
      'isShared': isShared,
      // Note: isHidden is not persisted - it's session-only
    };
  }

  @override
  Map<String, dynamic> toNetworkJson() {
    // Ultra-compact format: t=type (0=line, 1=rect), c=color index (0-7), p=points
    // Points are encoded as flat array [lat1,lon1,lat2,lon2,...]
    // Coordinates rounded to 5 decimal places (~1m precision, like SAR markers)
    // Sender is fetched from packet metadata, not included in JSON
    return {
      't': type.index,
      'c': DrawingColors.colorToIndex(color),
      'p': points.expand((p) => [
        double.parse(p.latitude.toStringAsFixed(5)),
        double.parse(p.longitude.toStringAsFixed(5)),
      ]).toList(),
    };
  }

  static LineDrawing fromJson(Map<String, dynamic> json) {
    final pointsJson = json['points'] as List<dynamic>;
    final points = pointsJson.map((p) => LatLng(p['lat'] as double, p['lon'] as double)).toList();
    final senderName = json['sender'] as String?;

    return LineDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      points: points,
      senderName: senderName,
      isReceived: senderName != null, // Mark as received if sender is present
      isShared: json['isShared'] as bool? ?? false,
    );
  }

  static LineDrawing fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
  }) {
    // Parse ultra-compact format
    final pointsFlat = (json['p'] as List<dynamic>).cast<double>();
    final points = <LatLng>[];
    for (int i = 0; i < pointsFlat.length; i += 2) {
      points.add(LatLng(pointsFlat[i], pointsFlat[i + 1]));
    }

    return LineDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate new ID
      color: DrawingColors.indexToColor(json['c'] as int),
      createdAt: DateTime.now(),
      points: points,
      senderName: senderName,
      isReceived: true,
      messageId: messageId, // Link to source message
      isShared: false, // Received drawings are not marked as shared
    );
  }

  /// Create a copy with updated points
  LineDrawing copyWith({List<LatLng>? points}) {
    return LineDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      points: points ?? this.points,
    );
  }

  @override
  LatLng getCenter() {
    if (points.isEmpty) return LatLng(0, 0);
    if (points.length == 1) return points[0];

    // Calculate center as average of all points
    double sumLat = 0;
    double sumLon = 0;
    for (final point in points) {
      sumLat += point.latitude;
      sumLon += point.longitude;
    }
    return LatLng(sumLat / points.length, sumLon / points.length);
  }

  @override
  LatLngBounds getBounds() {
    if (points.isEmpty) return LatLngBounds(LatLng(0, 0), LatLng(0, 0));
    if (points.length == 1) return LatLngBounds(points[0], points[0]);

    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLon = points[0].longitude;
    double maxLon = points[0].longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLon) minLon = point.longitude;
      if (point.longitude > maxLon) maxLon = point.longitude;
    }

    return LatLngBounds(LatLng(minLat, minLon), LatLng(maxLat, maxLon));
  }
}

/// Rectangle drawing on map
class RectangleDrawing extends MapDrawing {
  final LatLng topLeft;
  final LatLng bottomRight;

  RectangleDrawing({
    required super.id,
    required super.color,
    required super.createdAt,
    required this.topLeft,
    required this.bottomRight,
    super.senderName,
    super.isReceived,
    super.messageId,
    super.isShared,
    super.isSent,
    super.isHidden,
  }) : super(type: DrawingShapeType.rectangle);

  /// Get all corner points for rendering
  List<LatLng> get corners => [
        topLeft,
        LatLng(topLeft.latitude, bottomRight.longitude), // top right
        bottomRight,
        LatLng(bottomRight.latitude, topLeft.longitude), // bottom left
        topLeft, // close the rectangle
      ];

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'color': color.toARGB32(),
      'createdAt': createdAt.toIso8601String(),
      'topLeft': {'lat': topLeft.latitude, 'lon': topLeft.longitude},
      'bottomRight': {'lat': bottomRight.latitude, 'lon': bottomRight.longitude},
      'isShared': isShared,
      // Note: isHidden is not persisted - it's session-only
    };
  }

  @override
  Map<String, dynamic> toNetworkJson() {
    // Ultra-compact format: t=type (0=line, 1=rect), c=color index (0-7), b=bounds [lat1,lon1,lat2,lon2]
    // Coordinates rounded to 5 decimal places (~1m precision, like SAR markers)
    // Sender is fetched from packet metadata, not included in JSON
    return {
      't': type.index,
      'c': DrawingColors.colorToIndex(color),
      'b': [
        double.parse(topLeft.latitude.toStringAsFixed(5)),
        double.parse(topLeft.longitude.toStringAsFixed(5)),
        double.parse(bottomRight.latitude.toStringAsFixed(5)),
        double.parse(bottomRight.longitude.toStringAsFixed(5)),
      ],
    };
  }

  static RectangleDrawing fromJson(Map<String, dynamic> json) {
    final topLeftJson = json['topLeft'] as Map<String, dynamic>;
    final bottomRightJson = json['bottomRight'] as Map<String, dynamic>;
    final senderName = json['sender'] as String?;

    return RectangleDrawing(
      id: json['id'] as String,
      color: Color(json['color'] as int),
      createdAt: DateTime.parse(json['createdAt'] as String),
      topLeft: LatLng(topLeftJson['lat'] as double, topLeftJson['lon'] as double),
      bottomRight: LatLng(bottomRightJson['lat'] as double, bottomRightJson['lon'] as double),
      senderName: senderName,
      isReceived: senderName != null, // Mark as received if sender is present
      isShared: json['isShared'] as bool? ?? false,
    );
  }

  static RectangleDrawing fromNetworkJson(
    Map<String, dynamic> json, {
    String? senderName,
    String? messageId,
  }) {
    // Parse ultra-compact format
    final bounds = (json['b'] as List<dynamic>).cast<double>();

    return RectangleDrawing(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Generate new ID
      color: DrawingColors.indexToColor(json['c'] as int),
      createdAt: DateTime.now(),
      topLeft: LatLng(bounds[0], bounds[1]),
      bottomRight: LatLng(bounds[2], bounds[3]),
      senderName: senderName,
      isReceived: true,
      messageId: messageId, // Link to source message
      isShared: false, // Received drawings are not marked as shared
    );
  }

  /// Create a copy with updated corners
  RectangleDrawing copyWith({
    LatLng? topLeft,
    LatLng? bottomRight,
  }) {
    return RectangleDrawing(
      id: id,
      color: color,
      createdAt: createdAt,
      topLeft: topLeft ?? this.topLeft,
      bottomRight: bottomRight ?? this.bottomRight,
    );
  }

  @override
  LatLng getCenter() {
    // Center is the midpoint between top-left and bottom-right
    return LatLng(
      (topLeft.latitude + bottomRight.latitude) / 2,
      (topLeft.longitude + bottomRight.longitude) / 2,
    );
  }

  @override
  LatLngBounds getBounds() {
    // Bounds are simply the two corners
    return LatLngBounds(topLeft, bottomRight);
  }
}
