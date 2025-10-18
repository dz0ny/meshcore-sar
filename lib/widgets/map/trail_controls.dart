import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

/// Trail management controls widget
class TrailControls extends StatelessWidget {
  const TrailControls({super.key});

  void _showTrailMenu(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Location Trail',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Trail stats
            if (mapProvider.currentTrail != null && mapProvider.currentTrail!.points.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: _formatDistance(mapProvider.totalTrailDistance),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      icon: Icons.access_time,
                      label: 'Duration',
                      value: _formatDuration(mapProvider.trailDuration),
                    ),
                    const SizedBox(height: 8),
                    _buildStatRow(
                      icon: Icons.place,
                      label: 'Points',
                      value: '${mapProvider.currentTrail!.points.length}',
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Clear trail button
            if (mapProvider.currentTrail != null && mapProvider.currentTrail!.points.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  _showClearConfirmation(context, mapProvider);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Clear Trail'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),

            // No trail message
            if (mapProvider.currentTrail == null || mapProvider.currentTrail!.points.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.timeline, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No trail recorded yet',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start location tracking to record your trail',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearConfirmation(BuildContext context, MapProvider mapProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Trail?'),
        content: const Text(
          'Are you sure you want to clear the current location trail? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              mapProvider.clearCurrentTrail();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close bottom sheet
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

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
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'trail_controls',
      tooltip: 'Trail Controls',
      onPressed: () => _showTrailMenu(context),
      child: const Icon(Icons.timeline),
    );
  }
}
