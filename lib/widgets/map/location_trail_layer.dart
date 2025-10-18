import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

/// Widget that renders the user's location trail on the map
class LocationTrailLayer extends StatelessWidget {
  const LocationTrailLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        final trail = mapProvider.currentTrail;
        final isVisible = mapProvider.isTrailVisible;

        // Don't render if trail is hidden or empty
        if (!isVisible || trail == null || trail.points.length < 2) {
          return const SizedBox.shrink();
        }

        final points = trail.latLngPoints;

        return PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              strokeWidth: 4.0,
              color: Colors.blue.withValues(alpha: 0.7),
              borderStrokeWidth: 2.0,
              borderColor: Colors.white.withValues(alpha: 0.5),
            ),
          ],
        );
      },
    );
  }
}

/// Widget that shows trail statistics overlay
class TrailStatsOverlay extends StatelessWidget {
  const TrailStatsOverlay({super.key});

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapProvider>(
      builder: (context, mapProvider, child) {
        final trail = mapProvider.currentTrail;
        final isVisible = mapProvider.isTrailVisible;

        // Don't show if trail is hidden or doesn't exist
        if (!isVisible || trail == null || trail.points.isEmpty) {
          return const SizedBox.shrink();
        }

        final distance = mapProvider.totalTrailDistance;
        final duration = mapProvider.trailDuration;
        final pointCount = trail.points.length;

        return Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timeline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Location Trail',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildStatRow(Icons.straighten, _formatDistance(distance)),
                const SizedBox(height: 4),
                _buildStatRow(Icons.access_time, _formatDuration(duration)),
                const SizedBox(height: 4),
                _buildStatRow(Icons.place, '$pointCount points'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
