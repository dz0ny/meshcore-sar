import 'dart:convert';
import '../models/map_drawing.dart';

/// Parser for drawing messages transmitted over mesh network
class DrawingMessageParser {
  /// Drawing message prefix
  static const String prefix = 'D:';

  /// Check if message is a drawing message
  static bool isDrawingMessage(String text) {
    return text.startsWith(prefix);
  }

  /// Parse drawing message text into MapDrawing object
  /// senderName and messageId should be extracted from packet metadata
  /// Returns null if parsing fails
  static MapDrawing? parseDrawingMessage(
    String text, {
    String? senderName,
    String? messageId,
  }) {
    if (!isDrawingMessage(text)) {
      return null;
    }

    try {
      // Remove prefix
      final jsonStr = text.substring(prefix.length);

      // Parse JSON
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Use ultra-compact network format parser
      // Sender name and message ID come from packet metadata, not JSON
      return MapDrawing.fromNetworkJson(
        json,
        senderName: senderName,
        messageId: messageId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Create drawing message text from MapDrawing object
  /// Sender will be determined from packet metadata on receiving end
  static String createDrawingMessage(MapDrawing drawing) {
    final json = drawing.toNetworkJson();
    final jsonStr = jsonEncode(json).toString();
    return '$prefix$jsonStr';
  }

  /// Get drawing type display name from drawing message text
  /// Returns "Line" or "Rectangle", or null if parsing fails
  static String? getDrawingTypeDisplay(String text) {
    if (!isDrawingMessage(text)) return null;

    try {
      final jsonStr = text.substring(prefix.length);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final typeNum = json['t'] as int?;

      if (typeNum == null) return null;

      switch (typeNum) {
        case 0:
          return 'Line';
        case 1:
          return 'Rectangle';
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Get color name from drawing message text
  /// Returns color name like "Red", "Blue", etc., or null if parsing fails
  static String? getColorName(String text) {
    if (!isDrawingMessage(text)) return null;

    try {
      final jsonStr = text.substring(prefix.length);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final colorIndex = json['c'] as int?;

      if (colorIndex == null) return null;

      // Color mapping from DrawingColor enum
      const colorNames = [
        'Red',    // 0
        'Blue',   // 1
        'Green',  // 2
        'Yellow', // 3
        'Orange', // 4
        'Purple', // 5
        'Pink',   // 6
        'Cyan',   // 7
      ];

      if (colorIndex >= 0 && colorIndex < colorNames.length) {
        return colorNames[colorIndex];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get drawing metadata for display in message bubbles
  /// Returns map with type, color, and pointCount, or null if parsing fails
  static Map<String, dynamic>? getDrawingMetadata(String text) {
    if (!isDrawingMessage(text)) return null;

    try {
      final jsonStr = text.substring(prefix.length);
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;

      final typeNum = json['t'] as int?;
      final colorIndex = json['c'] as int?;

      if (typeNum == null || colorIndex == null) return null;

      // Get type display name
      String type;
      int? pointCount;

      switch (typeNum) {
        case 0: // Line
          type = 'Line';
          final points = json['p'] as List?;
          pointCount = points != null ? points.length ~/ 2 : null;
          break;
        case 1: // Rectangle
          type = 'Rectangle';
          pointCount = 4; // Rectangles always have 4 corners
          break;
        default:
          return null;
      }

      // Get color name
      const colorNames = [
        'Red', 'Blue', 'Green', 'Yellow', 'Orange', 'Purple', 'Pink', 'Cyan',
      ];
      final color = colorIndex >= 0 && colorIndex < colorNames.length
          ? colorNames[colorIndex]
          : 'Unknown';

      return {
        'type': type,
        'color': color,
        'pointCount': pointCount,
      };
    } catch (e) {
      return null;
    }
  }
}
