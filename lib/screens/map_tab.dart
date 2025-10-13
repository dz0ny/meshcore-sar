import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/contacts_provider.dart';
import '../providers/messages_provider.dart';
import '../providers/map_provider.dart';
import '../providers/app_provider.dart';
import '../models/contact.dart';
import '../models/sar_marker.dart';
import '../models/map_layer.dart';
import '../services/tile_cache_service.dart';
import '../widgets/map_markers.dart';
import 'map_management_screen.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final TileCacheService _tileCache = TileCacheService();
  bool _isInitialized = false;
  MapLayer _currentLayer = MapLayer.openStreetMap;
  Position? _currentPosition;
  bool _showLegend = true;
  double _gpsUpdateDistance = 3.0; // meters
  StreamSubscription<Position>? _positionStreamSubscription;

  // Default center point (will be updated based on markers)
  static const LatLng _defaultCenter = LatLng(46.0569, 14.5058); // Ljubljana, Slovenia
  static const double _defaultZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _initializeTileCache();
    _requestLocationPermission();

    // Listen to map provider for navigation requests
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapProvider = context.read<MapProvider>();
      mapProvider.addListener(_handleMapNavigation);
    });
  }

  Future<void> _requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get initial position
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    // Start listening to location updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _gpsUpdateDistance.toInt(),
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  void _handleMapNavigation() {
    final mapProvider = context.read<MapProvider>();
    if (mapProvider.targetLocation != null && _isInitialized) {
      _mapController.move(
        mapProvider.targetLocation!,
        mapProvider.targetZoom ?? _defaultZoom,
      );
      // Clear the navigation request after handling
      mapProvider.clearNavigation();
    }
  }

  Future<void> _initializeTileCache() async {
    try {
      await _tileCache.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing tile cache: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Continue without caching
        });
      }
    }
  }

  @override
  void dispose() {
    final mapProvider = context.read<MapProvider>();
    mapProvider.removeListener(_handleMapNavigation);
    _positionStreamSubscription?.cancel();
    _mapController.dispose();
    _tileCache.dispose();
    super.dispose();
  }

  LatLng _calculateCenter(List<Contact> contacts, List<SarMarker> sarMarkers) {
    final allPoints = <LatLng>[];

    for (final contact in contacts) {
      if (contact.displayLocation != null) {
        allPoints.add(contact.displayLocation!);
      }
    }

    for (final marker in sarMarkers) {
      allPoints.add(marker.location);
    }

    if (allPoints.isEmpty) return _defaultCenter;

    double lat = 0, lng = 0;
    for (final point in allPoints) {
      lat += point.latitude;
      lng += point.longitude;
    }

    return LatLng(lat / allPoints.length, lng / allPoints.length);
  }

  void _showLayerSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.layers),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select Map Layer',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Download visible area',
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToDownload(context);
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            ...MapLayer.allLayers.map((layer) => ListTile(
                  leading: _currentLayer.type == layer.type
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.radio_button_unchecked),
                  title: Text(layer.name),
                  subtitle: Text(layer.attribution),
                  onTap: () {
                    setState(() {
                      _currentLayer = layer;
                    });
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _navigateToDownload(BuildContext context) {
    // Get current map bounds
    final bounds = _mapController.camera.visibleBounds;
    final currentZoom = _mapController.camera.zoom.round();

    // Navigate to Map Management screen with pre-populated data
    final appProvider = context.read<AppProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapManagementScreen(
          tileCacheService: appProvider.tileCacheService,
          initialLayer: _currentLayer,
          initialBounds: bounds,
          initialZoom: currentZoom,
        ),
      ),
    );
  }

  void _showOptionsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 12),
                    Text(
                      'Map Options',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // Legend toggle
              SwitchListTile(
                secondary: const Icon(Icons.info_outline),
                title: const Text('Show Legend'),
                subtitle: const Text('Display marker type counts'),
                value: _showLegend,
                onChanged: (value) {
                  setState(() {
                    _showLegend = value;
                  });
                  setModalState(() {});
                },
              ),
              const Divider(),
              // GPS Update Distance
              ListTile(
                leading: const Icon(Icons.gps_fixed),
                title: const Text('GPS Update Distance'),
                subtitle: Text('${_gpsUpdateDistance.toStringAsFixed(0)} meters'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Slider(
                      value: _gpsUpdateDistance,
                      min: 1,
                      max: 20,
                      divisions: 19,
                      label: '${_gpsUpdateDistance.toStringAsFixed(0)}m',
                      onChanged: (value) {
                        setModalState(() {
                          _gpsUpdateDistance = value;
                        });
                      },
                      onChangeEnd: (value) {
                        setState(() {
                          _gpsUpdateDistance = value;
                        });
                        // Restart location stream with new distance
                        _restartLocationStream();
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '1m',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '20m',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _restartLocationStream() {
    // Cancel existing subscription
    _positionStreamSubscription?.cancel();

    // Start new stream with updated distance
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: _gpsUpdateDistance.toInt(),
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ContactsProvider, MessagesProvider>(
      builder: (context, contactsProvider, messagesProvider, child) {
        final contactsWithLocation = contactsProvider.chatContactsWithLocation;
        final sarMarkers = messagesProvider.sarMarkers;
        final center = _calculateCenter(contactsWithLocation, sarMarkers);

        return Stack(
          children: [
            // Map widget
            _isInitialized
                ? FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _defaultZoom,
                      minZoom: 5,
                      maxZoom: 18,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _currentLayer.urlTemplate,
                        tileProvider: _tileCache.getTileProvider(_currentLayer),
                        userAgentPackageName: 'com.meshcore.sar',
                        maxZoom: _currentLayer.maxZoom.toDouble(),
                      ),
                      MarkerLayer(
                        markers: [
                          ...MapMarkers.createTeamMemberMarkers(
                            contactsWithLocation,
                            context,
                          ),
                          ...MapMarkers.createSarMarkers(
                            sarMarkers,
                            context,
                          ),
                          // User location marker
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              width: 40,
                              height: 40,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.navigation,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing map...',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
            // Map legend overlay
            if (_showLegend)
              Positioned(
                top: 16,
                right: 16,
                child: _MapLegend(
                  teamMemberCount: contactsWithLocation.length,
                  foundPersonCount: messagesProvider.foundPersonMarkers.length,
                  fireCount: messagesProvider.fireMarkers.length,
                  stagingAreaCount: messagesProvider.stagingAreaMarkers.length,
                ),
              ),
            // Map controls - right side
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'center_map',
                    onPressed: () async {
                      // Force update GPS location and jump to it
                      try {
                        final position = await Geolocator.getCurrentPosition(
                          locationSettings: const LocationSettings(
                            accuracy: LocationAccuracy.best,
                            distanceFilter: 0,
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _currentPosition = position;
                          });
                          _mapController.move(
                            LatLng(position.latitude, position.longitude),
                            16,
                          );
                        }
                      } catch (e) {
                        debugPrint('Error getting location: $e');
                        // Fallback to cached position or default center
                        if (_currentPosition != null) {
                          _mapController.move(
                            LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            16,
                          );
                        } else {
                          _mapController.move(center, _defaultZoom);
                        }
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'layer_selector',
                    onPressed: () => _showLayerSelector(context),
                    child: const Icon(Icons.layers),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'options_menu',
                    onPressed: () => _showOptionsMenu(context),
                    child: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapLegend extends StatelessWidget {
  final int teamMemberCount;
  final int foundPersonCount;
  final int fireCount;
  final int stagingAreaCount;

  const _MapLegend({
    required this.teamMemberCount,
    required this.foundPersonCount,
    required this.fireCount,
    required this.stagingAreaCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              icon: Icons.person,
              color: Colors.blue,
              label: 'Team',
              count: teamMemberCount,
            ),
            _LegendItem(
              icon: Icons.person_pin,
              color: Colors.green,
              label: 'Found',
              count: foundPersonCount,
            ),
            _LegendItem(
              icon: Icons.local_fire_department,
              color: Colors.red,
              label: 'Fire',
              count: fireCount,
            ),
            _LegendItem(
              icon: Icons.home_work,
              color: Colors.orange,
              label: 'Staging',
              count: stagingAreaCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

