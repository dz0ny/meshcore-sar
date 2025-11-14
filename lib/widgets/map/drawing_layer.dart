import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/map_drawing.dart';
import '../../l10n/app_localizations.dart';

/// Widget that renders map drawings as polylines
class DrawingLayer extends StatelessWidget {
  final List<MapDrawing> drawings;
  final MapDrawing? previewDrawing;
  final bool isSimpleMode;

  const DrawingLayer({
    super.key,
    required this.drawings,
    this.previewDrawing,
    this.isSimpleMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Polyline> polylines = [];

    // Add completed drawings
    for (final drawing in drawings) {
      polylines.add(_createPolyline(drawing, isPreview: false));
    }

    // Add preview drawing (if any)
    if (previewDrawing != null) {
      polylines.add(_createPolyline(previewDrawing!, isPreview: true));
    }

    return PolylineLayer(polylines: polylines);
  }

  /// Create a polyline from a drawing
  Polyline _createPolyline(MapDrawing drawing, {required bool isPreview}) {
    final points = _getPoints(drawing);

    // Different styles for different drawing sources
    final double opacity;
    final double strokeWidth;

    if (isPreview) {
      // Preview drawing (currently being drawn)
      opacity = 0.6;
      strokeWidth = 4.0;
    } else if (drawing.isReceived) {
      // Received drawing from another node
      // In simple mode: solid (opacity 1.0), in normal mode: translucent (0.7)
      opacity = isSimpleMode ? 1.0 : 0.7;
      strokeWidth = 3.0;
    } else {
      // Local drawing (solid line, normal thickness)
      opacity = 1.0;
      strokeWidth = 4.0;
    }

    return Polyline(
      points: points,
      color: drawing.color.withValues(alpha: opacity),
      strokeWidth: strokeWidth,
      borderColor: Colors.white.withValues(alpha: opacity * 0.8),
      borderStrokeWidth: 1.0,
      // Use dotted pattern for received drawings
      pattern: drawing.isReceived && !isPreview
          ? StrokePattern.dotted(spacingFactor: 2)
          : const StrokePattern.solid(),
    );
  }

  /// Get points from a drawing based on its type
  List<LatLng> _getPoints(MapDrawing drawing) {
    if (drawing is LineDrawing) {
      return drawing.points;
    } else if (drawing is RectangleDrawing) {
      return drawing.corners;
    }
    return [];
  }
}

/// Widget that shows drawing markers (start/end points)
class DrawingMarkersLayer extends StatelessWidget {
  final List<MapDrawing> drawings;
  final Function(String drawingId)? onDeleteDrawing;
  final Function(MapDrawing drawing)? onTapDrawing;
  final bool showDeleteButtons;
  final bool isSimpleMode;

  const DrawingMarkersLayer({
    super.key,
    required this.drawings,
    this.onDeleteDrawing,
    this.onTapDrawing,
    this.showDeleteButtons = false,
    this.isSimpleMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = [];

    // Add markers for each drawing
    for (final drawing in drawings) {
      final centerPoint = _getCenterPoint(drawing);
      if (centerPoint != null) {
        if (showDeleteButtons) {
          // Show delete button when in drawing mode
          markers.add(
            Marker(
              point: centerPoint,
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  if (onDeleteDrawing != null) {
                    _showDeleteDialog(context, drawing);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: drawing.color.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          );
        } else if (drawing.isReceived && drawing.senderName != null && !isSimpleMode) {
          // Show sender badge for received drawings (when not in drawing mode and not in simple mode)
          // Make it tappable if message ID is available
          markers.add(
            Marker(
              point: centerPoint,
              width: 120,
              height: 30,
              child: GestureDetector(
                onTap: drawing.messageId != null && onTapDrawing != null
                    ? () => onTapDrawing!(drawing)
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: drawing.color.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          drawing.senderName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      // Add indicator that this is tappable
                      if (drawing.messageId != null && onTapDrawing != null) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 10,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }
      }
    }

    if (markers.isEmpty) {
      return const SizedBox.shrink();
    }

    return MarkerLayer(markers: markers);
  }

  /// Get the center point of a drawing
  LatLng? _getCenterPoint(MapDrawing drawing) {
    if (drawing is LineDrawing && drawing.points.isNotEmpty) {
      // Use the middle point of the line
      final midIndex = drawing.points.length ~/ 2;
      return drawing.points[midIndex];
    } else if (drawing is RectangleDrawing) {
      // Use the center of the rectangle
      return LatLng(
        (drawing.topLeft.latitude + drawing.bottomRight.latitude) / 2,
        (drawing.topLeft.longitude + drawing.bottomRight.longitude) / 2,
      );
    }
    return null;
  }

  /// Show delete confirmation dialog
  void _showDeleteDialog(BuildContext context, MapDrawing drawing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteDrawing),
        content: Text(
          'Delete this ${drawing.type.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDeleteDrawing?.call(drawing.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }
}
