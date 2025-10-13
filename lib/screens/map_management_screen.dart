import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../services/tile_cache_service.dart';
import '../models/map_layer.dart';

class MapManagementScreen extends StatefulWidget {
  final TileCacheService tileCacheService;
  final MapLayer? initialLayer;
  final LatLngBounds? initialBounds;
  final int? initialZoom;

  const MapManagementScreen({
    super.key,
    required this.tileCacheService,
    this.initialLayer,
    this.initialBounds,
    this.initialZoom,
  });

  @override
  State<MapManagementScreen> createState() => _MapManagementScreenState();
}

class _MapManagementScreenState extends State<MapManagementScreen> {
  bool _isLoading = false;
  String? _statusMessage;
  Map<String, dynamic>? _cacheStats;

  // Download parameters
  late MapLayer _selectedLayer;
  late TextEditingController _northController;
  late TextEditingController _southController;
  late TextEditingController _eastController;
  late TextEditingController _westController;
  late int _minZoom;
  late int _maxZoom;
  double _downloadProgress = 0.0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();

    // Initialize with provided values or defaults
    _selectedLayer = widget.initialLayer ?? MapLayer.openStreetMap;

    if (widget.initialBounds != null) {
      _northController = TextEditingController(
        text: widget.initialBounds!.north.toStringAsFixed(4),
      );
      _southController = TextEditingController(
        text: widget.initialBounds!.south.toStringAsFixed(4),
      );
      _eastController = TextEditingController(
        text: widget.initialBounds!.east.toStringAsFixed(4),
      );
      _westController = TextEditingController(
        text: widget.initialBounds!.west.toStringAsFixed(4),
      );
    } else {
      _northController = TextEditingController(text: '46.1');
      _southController = TextEditingController(text: '46.0');
      _eastController = TextEditingController(text: '14.6');
      _westController = TextEditingController(text: '14.4');
    }

    // Set zoom levels
    if (widget.initialZoom != null) {
      _minZoom = (widget.initialZoom! - 2).clamp(1, 19);
      _maxZoom = (widget.initialZoom! + 2).clamp(1, 19);
    } else {
      _minZoom = 10;
      _maxZoom = 16;
    }

    _loadCacheStats();
  }

  @override
  void dispose() {
    _northController.dispose();
    _southController.dispose();
    _eastController.dispose();
    _westController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheStats() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final stats = await widget.tileCacheService.getStoreStats();
      if (!mounted) return;
      setState(() {
        _cacheStats = stats;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Error loading stats: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadRegion() async {
    try {
      final north = double.tryParse(_northController.text);
      final south = double.tryParse(_southController.text);
      final east = double.tryParse(_eastController.text);
      final west = double.tryParse(_westController.text);

      if (north == null || south == null || east == null || west == null) {
        _showError('Invalid coordinates. Please enter valid numbers.');
        return;
      }

      if (north <= south || east <= west) {
        _showError('Invalid bounds. North must be > South, East must be > West.');
        return;
      }

      final bounds = LatLngBounds(
        LatLng(south, west),
        LatLng(north, east),
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _statusMessage = 'Starting download...';
      });

      await widget.tileCacheService.downloadRegion(
        layer: _selectedLayer,
        bounds: bounds,
        minZoom: _minZoom,
        maxZoom: _maxZoom,
        onProgress: (progress) {
          print('UI received progress update: $progress%');
          if (!mounted) return;
          setState(() {
            _downloadProgress = progress;
            _statusMessage = 'Downloading map tiles...';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download completed successfully!';
      });

      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Map download completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download failed: $e';
      });
      _showError('Download failed: $e');
    }
  }

  Future<void> _cancelDownload() async {
    try {
      if (!mounted) return;
      setState(() => _statusMessage = 'Cancelling download...');

      await widget.tileCacheService.cancelDownload();

      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Download cancelled';
      });

      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Download cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = 'Cancel failed: $e';
      });
      _showError('Cancel failed: $e');
    }
  }

  Future<void> _exportMaps() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final exportPath = await widget.tileCacheService.exportCache();
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (mounted) {
        await Share.shareXFiles(
          [XFile(exportPath)],
          subject: 'MeshCore SAR Maps Export',
          text: 'Offline maps export from MeshCore SAR',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Maps exported to: $exportPath'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Export failed: $e');
    }
  }

  Future<void> _importMaps() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fmtc'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      if (!mounted) return;
      setState(() => _isLoading = true);

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Invalid file path');
      }

      await widget.tileCacheService.importCache(filePath);

      if (!mounted) return;
      setState(() => _isLoading = false);
      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maps imported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError('Import failed: $e');
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to delete all downloaded maps? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      await widget.tileCacheService.clearCache();
      if (!mounted) return;
      setState(() => _isLoading = false);
      await _loadCacheStats();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Clear cache failed: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Management'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cache Statistics
                  _buildStatisticsCard(),
                  const SizedBox(height: 16),

                  // Download Region
                  _buildDownloadCard(),
                  const SizedBox(height: 16),

                  // Import/Export/Clear
                  _buildActionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cache Statistics',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadCacheStats,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_cacheStats != null) ...[
              _buildStatRow(
                'Total Tiles',
                '${_cacheStats!['tileCount'] ?? 0}',
                Icons.grid_on,
              ),
              _buildStatRow(
                'Cache Size',
                '${(_cacheStats!['sizeMB'] ?? 0.0).toStringAsFixed(2)} MB',
                Icons.storage,
              ),
              _buildStatRow(
                'Store Name',
                _cacheStats!['storeName'] ?? 'Unknown',
                Icons.folder,
              ),
            ] else
              const Text('No cache statistics available'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDownloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Download Region',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Map Layer Selection
            DropdownButtonFormField<MapLayer>(
              value: _selectedLayer,
              decoration: const InputDecoration(
                labelText: 'Map Layer',
                border: OutlineInputBorder(),
              ),
              items: MapLayer.allLayers.map((layer) {
                return DropdownMenuItem(
                  value: layer,
                  child: Text(layer.name),
                );
              }).toList(),
              onChanged: _isDownloading ? null : (layer) {
                if (layer != null) {
                  setState(() => _selectedLayer = layer);
                }
              },
            ),
            const SizedBox(height: 16),

            // Coordinates
            Text(
              'Region Bounds',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _northController,
                    decoration: const InputDecoration(
                      labelText: 'North',
                      border: OutlineInputBorder(),
                      hintText: '46.1',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _southController,
                    decoration: const InputDecoration(
                      labelText: 'South',
                      border: OutlineInputBorder(),
                      hintText: '46.0',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _eastController,
                    decoration: const InputDecoration(
                      labelText: 'East',
                      border: OutlineInputBorder(),
                      hintText: '14.6',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _westController,
                    decoration: const InputDecoration(
                      labelText: 'West',
                      border: OutlineInputBorder(),
                      hintText: '14.4',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_isDownloading,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Zoom Levels
            Text(
              'Zoom Levels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Min: $_minZoom'),
                      Slider(
                        value: _minZoom.toDouble(),
                        min: 1,
                        max: 19,
                        divisions: 18,
                        label: '$_minZoom',
                        onChanged: _isDownloading ? null : (value) {
                          setState(() {
                            _minZoom = value.toInt();
                            if (_minZoom > _maxZoom) {
                              _maxZoom = _minZoom;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Max: $_maxZoom'),
                      Slider(
                        value: _maxZoom.toDouble(),
                        min: 1,
                        max: 19,
                        divisions: 18,
                        label: '$_maxZoom',
                        onChanged: _isDownloading ? null : (value) {
                          setState(() {
                            _maxZoom = value.toInt();
                            if (_maxZoom < _minZoom) {
                              _minZoom = _maxZoom;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Download Progress
            if (_isDownloading) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusMessage ?? 'Downloading...',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          '${_downloadProgress.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _downloadProgress / 100,
                        minHeight: 8,
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Download/Cancel Button
            if (_isDownloading)
              ElevatedButton.icon(
                onPressed: _cancelDownload,
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel Download'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _downloadRegion,
                icon: const Icon(Icons.download),
                label: const Text('Download Region'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),

            const SizedBox(height: 8),
            Text(
              'Note: Large regions or high zoom levels may take significant time and storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Map Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Export Button
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _exportMaps,
              icon: const Icon(Icons.upload),
              label: const Text('Export Maps'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),

            // Import Button
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _importMaps,
              icon: const Icon(Icons.download),
              label: const Text('Import Maps'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 8),

            // Clear Cache Button
            OutlinedButton.icon(
              onPressed: _isDownloading ? null : _clearCache,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Maps'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
