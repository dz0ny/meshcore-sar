import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'profiles_feature_service.dart';

/// Centralized location tracking service for MeshCore SAR
///
/// Handles GPS tracking, distance thresholds, background updates,
/// and location broadcasting to the mesh network.
///
/// Features:
/// - Singleton pattern for app-wide access
/// - Configurable distance thresholds (min/max)
/// - Configurable time intervals
/// - Permission handling
/// - SharedPreferences persistence
/// - MeshCore mesh network integration
/// - Real-time position updates via callbacks
class LocationTrackingService {
  static const double _defaultFastLocationMovementThresholdMeters = 10.0;
  static const double _minFastLocationMovementThresholdMeters = 10.0;
  static const int _defaultFastLocationActiveCadenceSeconds = 60;
  static const int _minFastLocationActiveCadenceSeconds = 60;
  static const int _maxFastLocationActiveCadenceSeconds = 60;
  // Moving cadence tiers — identical to the MeshUI firmware
  // (FAST_GPS_*_INTERVAL_MS / FAST_GPS_SPEED_*_MAX_MPS in MyMesh.cpp).
  static const Duration _fastLocationWalkingInterval = Duration(seconds: 30);
  static const Duration _fastLocationFastInterval = Duration(seconds: 15);
  static const Duration _fastLocationVeryFastInterval = Duration(seconds: 5);
  static const double _fastLocationIdleSpeedMaxMetersPerSecond = 0.75;
  static const double _fastLocationWalkingSpeedMaxMetersPerSecond = 1.8;
  static const double _fastLocationFastSpeedMaxMetersPerSecond = 4.0;

  // Stationary keepalive — a parked node still beacons, but only every 9 min
  // (FAST_GPS_STATIONARY_*_INTERVAL_MS), not on GPS jitter.
  static const Duration _fastLocationStationaryInterval = Duration(minutes: 9);

  // Moving/stationary detection: anchor + dwell hysteresis (position-only, no
  // Doppler), mirroring FAST_GPS_MOVE_* in MyMesh.cpp. A parked node holds an
  // anchor; jitter inside the radius is absorbed and the stable anchor is
  // reported, so multipath wander can't paint a fake track.
  static const double _fastLocationMoveRadiusMeters = 25.0;
  static const Duration _fastLocationMoveDwell = Duration(seconds: 15);
  static const Duration _fastLocationStopDwell = Duration(seconds: 60);
  static const Duration _fastLocationMoveEval = Duration(seconds: 1);
  static const double _fastLocationSpeedGateMeters = 5.0;
  static const Duration _fastLocationSpeedRebaseline = Duration(seconds: 8);
  static const double _fastLocationSpeedGlitchMaxKmh = 300.0;

  // Fix-quality gate. The firmware requires >= 5 satellites (FAST_GPS_MIN_SATS);
  // Geolocator does not expose a satellite count on all platforms, so we gate on
  // horizontal accuracy as the closest available proxy.
  static const double _fastLocationMaxAccuracyMeters = 50.0;

  // Yield ~5s after hearing a peer beacon, to avoid channel collisions
  // (FAST_GPS_CHANNEL_RX_HOLDOFF_MS).
  static const Duration _fastLocationRxHoldoff = Duration(seconds: 5);

  // Background keepalive tick when not in active use — cheap, just enough to fire
  // the 9-min stationary beacon while parked.
  static const Duration _fastLocationActiveTick = Duration(seconds: 15);
  // ============================================================================
  // Singleton Pattern
  // ============================================================================

  static final LocationTrackingService _instance =
      LocationTrackingService._internal();

  /// Get the singleton instance
  factory LocationTrackingService() => _instance;

  LocationTrackingService._internal();

  // ============================================================================
  // SharedPreferences Keys
  // ============================================================================

  static const String _prefKeyEnabled = 'background_tracking_enabled';
  static const String _prefKeyMinDistance = 'map_gps_min_distance';
  static const String _prefKeyMaxDistance = 'map_gps_max_distance';
  static const String _prefKeyMinTimeInterval = 'map_gps_min_time_interval';
  static const String _prefKeyGpsUpdateDistance = 'map_gps_update_distance';
  static const String _prefKeyLastLat = 'background_last_lat';
  static const String _prefKeyLastLon = 'background_last_lon';
  static const String _prefKeyFastLocationEnabled =
      'fast_location_updates_enabled';
  static const String _prefKeyFastMovementThreshold =
      'fast_location_movement_threshold_meters';
  static const String _prefKeyFastActiveCadence =
      'fast_location_active_cadence_seconds';
  static const String _prefKeyFastChannelIdx = 'fast_location_channel_idx';

  String _scopedKey(String baseKey) {
    return ProfileStorageScope.scopedKey(baseKey);
  }

  // ============================================================================
  // Configuration Properties
  // ============================================================================

  /// Minimum distance in meters before broadcasting update
  double minDistanceMeters = 5.0;

  /// Maximum distance in meters that forces a broadcast regardless of time
  double maxDistanceMeters = 100.0;

  /// Minimum time interval in seconds between broadcasts
  int minTimeIntervalSeconds = 30;

  /// GPS update distance filter for position stream
  double gpsUpdateDistance = 10.0;

  /// Whether private fast GPS updates are enabled
  bool fastLocationUpdatesEnabled = false;

  /// Distance threshold for fast GPS updates
  double fastLocationMovementThresholdMeters =
      _defaultFastLocationMovementThresholdMeters;

  /// Cadence for active-use fast GPS updates
  int fastLocationActiveCadenceSeconds =
      _defaultFastLocationActiveCadenceSeconds;

  /// Target channel index for fast GPS updates; null means disabled/unset.
  int? fastLocationChannelIdx;

  // ============================================================================
  // State Properties
  // ============================================================================

  /// Current GPS position
  Position? currentPosition;

  /// Whether tracking is currently active
  bool isTracking = false;

  /// Whether service has been initialized with BLE service
  bool _isInitialized = false;

  /// Whether the first stable position has been set (without broadcast)
  bool _firstPositionSet = false;

  // ============================================================================
  // Private Properties
  // ============================================================================

  /// Reference to MeshCore BLE service for broadcasting
  MeshCoreBleService? _bleService;

  /// Position stream subscription
  StreamSubscription<Position>? _positionSubscription;

  Timer? _fastLocationTimer;
  bool _isFastLocationActiveUse = false;
  DateTime? _lastFastLocationSentAt;
  int? _lastFastLocationSentLatE6;
  int? _lastFastLocationSentLonE6;

  // Firmware-mirrored fast-GPS motion state (app-fallback path). See
  // MyMesh::updateGpsStatusCache / maybeSendFastGpsUpdate.
  int? _fastGpsAnchorLatE6;
  int? _fastGpsAnchorLonE6;
  bool _fastGpsRefValid = false;
  bool _fastGpsIsMoving = false;
  DateTime? _fastGpsMoveStateSince;
  DateTime? _fastGpsMoveEvalAt;
  double _fastGpsSpeedKmh = 0.0;
  int? _fastGpsSpeedPrevLatE6;
  int? _fastGpsSpeedPrevLonE6;
  DateTime? _fastGpsSpeedPrevAt;
  DateTime? _fastGpsRxHoldoffUntil;

  // ============================================================================
  // Callback Properties
  // ============================================================================

  /// Called when position is updated
  void Function(Position)? onPositionUpdate;

  /// Called when an error occurs
  void Function(String error)? onError;

  /// Called when a location broadcast is sent to mesh network
  void Function(Position)? onBroadcastSent;

  /// Called when tracking state changes
  void Function(bool isTracking)? onTrackingStateChanged;

  /// Called when a fast private GPS update should be sent. Carries the resolved
  /// beacon coordinates (de-jittered anchor when parked) and EMA ground speed in
  /// km/h, so the caller just encodes and transmits.
  void Function(double latitude, double longitude, int speedKmh, String reason)?
  onFastLocationUpdate;

  // ============================================================================
  // Initialization
  // ============================================================================

  /// Initialize the service with MeshCore BLE service reference
  ///
  /// Must be called before starting tracking.
  Future<bool> initialize(MeshCoreBleService bleService) async {
    _bleService = bleService;
    _isInitialized = true;

    // Load saved settings
    await loadSettings();

    debugPrint('✅ [LocationTracking] Service initialized');
    return true;
  }

  // ============================================================================
  // Permission Handling
  // ============================================================================

  /// Check if location permissions are granted
  Future<bool> checkPermissions() async {
    final permission = await Geolocator.checkPermission();
    if (Platform.isIOS) {
      return permission == LocationPermission.always;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permissions from user
  ///
  /// Returns true if granted, false otherwise.
  Future<bool> requestPermissions() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      onError?.call('Location services are disabled');
      return false;
    }

    // Check current permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        onError?.call('Location permission denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      onError?.call(
        'Location permission permanently denied. Please enable in settings.',
      );
      return false;
    }

    if (Platform.isIOS && permission != LocationPermission.always) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always) {
        onError?.call(
          'Background tracking on iOS requires "Always" location access. Enable it in Settings.',
        );
        return false;
      }
    }

    debugPrint('✅ [LocationTracking] Location permissions granted');
    return true;
  }

  // ============================================================================
  // GPS Position Methods
  // ============================================================================

  /// Get current GPS position
  ///
  /// Returns null if position unavailable or permissions denied.
  /// [timeLimit] - Maximum time to wait for position (default: 15 seconds)
  /// [retryCount] - Number of retry attempts (default: 2)
  Future<Position?> getCurrentPosition({
    Duration timeLimit = const Duration(seconds: 15),
    int retryCount = 2,
  }) async {
    for (int attempt = 0; attempt <= retryCount; attempt++) {
      try {
        if (attempt > 0) {
          debugPrint(
            '🔄 [LocationTracking] Retry attempt $attempt/$retryCount',
          );
          // Exponential backoff: wait 2^attempt seconds before retry
          await Future.delayed(Duration(seconds: 1 << attempt));
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: _buildLocationSettings(
            timeLimit: timeLimit,
            distanceFilter: 0,
          ),
        );

        currentPosition = position;
        if (attempt > 0) {
          debugPrint(
            '✅ [LocationTracking] Position acquired after $attempt retries',
          );
        }
        return position;
      } catch (e) {
        final isLastAttempt = attempt == retryCount;
        if (isLastAttempt) {
          debugPrint(
            '❌ [LocationTracking] Failed to get position after $retryCount retries: $e',
          );
          // Only call error callback on final failure, and make it user-friendly
          if (e.toString().contains('TimeoutException')) {
            onError?.call(
              'GPS signal weak. Position stream will continue trying...',
            );
          } else {
            onError?.call('Failed to get GPS position. Check device settings.');
          }
        } else {
          debugPrint(
            '⚠️ [LocationTracking] Position attempt $attempt failed: $e',
          );
        }

        if (isLastAttempt) {
          return null;
        }
      }
    }
    return null;
  }

  /// Get position stream with configurable distance filter
  ///
  /// [distanceFilter] - Minimum distance in meters between position updates
  Stream<Position> getPositionStream({double distanceFilter = 10.0}) {
    return Geolocator.getPositionStream(
      locationSettings: _buildLocationSettings(
        distanceFilter: distanceFilter.toInt(),
      ),
    );
  }

  LocationSettings _buildLocationSettings({
    int distanceFilter = 10,
    Duration? timeLimit,
  }) {
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.best,
        activityType: ActivityType.fitness,
        allowBackgroundLocationUpdates: true,
        distanceFilter: distanceFilter,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        timeLimit: timeLimit,
      );
    }

    return LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: distanceFilter,
      timeLimit: timeLimit,
    );
  }

  // ============================================================================
  // Tracking Control
  // ============================================================================

  /// Start location tracking
  ///
  /// [distanceThreshold] - GPS update distance filter
  ///
  /// Returns true if successful, false otherwise.
  /// Note: This method returns immediately after starting the position stream.
  /// Initial position acquisition happens asynchronously in the background.
  ///
  /// GPS tracking works WITHOUT BLE connection - device broadcasts are simply skipped.
  Future<bool> startTracking({double? distanceThreshold}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ [LocationTracking] Service not initialized');
      onError?.call('Location tracking service not initialized');
      return false;
    }

    // Allow tracking without BLE connection - broadcasts will be skipped
    if (_bleService == null || !_bleService!.isConnected) {
      debugPrint(
        'ℹ️ [LocationTracking] Starting GPS tracking without BLE connection (broadcasts disabled)',
      );
    }

    // Check permissions
    final hasPermission = await requestPermissions();
    if (!hasPermission) {
      return false;
    }

    // Use provided threshold or current setting
    final threshold = distanceThreshold ?? gpsUpdateDistance;
    gpsUpdateDistance = threshold;

    // Save settings
    await saveSettings();

    // Try to get initial position in background (non-blocking)
    // This will populate currentPosition but won't block tracking startup
    getCurrentPosition(timeLimit: const Duration(seconds: 10), retryCount: 1)
        .then((position) {
          if (position != null) {
            debugPrint(
              '✅ [LocationTracking] Initial position acquired in background',
            );
          }
        })
        .catchError((error) {
          debugPrint(
            '⚠️ [LocationTracking] Background initial position failed: $error',
          );
          // Not critical - position stream will eventually provide position
        });

    // Start position stream immediately (don't wait for initial position)
    try {
      _positionSubscription = getPositionStream(distanceFilter: threshold)
          .listen(
            _handlePositionUpdate,
            onError: (error) {
              debugPrint('❌ [LocationTracking] Position stream error: $error');
              onError?.call('GPS stream error. Retrying...');
            },
          );

      isTracking = true;
      onTrackingStateChanged?.call(true);
      _refreshFastLocationTimer();

      debugPrint(
        '✅ [LocationTracking] Tracking started with ${threshold}m threshold',
      );
      debugPrint('📡 [LocationTracking] Waiting for GPS signal...');
      return true;
    } catch (e) {
      debugPrint('❌ [LocationTracking] Failed to start tracking: $e');
      onError?.call('Failed to start GPS tracking: $e');
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    debugPrint('🛑 [LocationTracking] Stopping tracking');

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    isTracking = false;
    onTrackingStateChanged?.call(false);
    _refreshFastLocationTimer();
    _resetFastGpsMotionState();

    // Reset first position flag so next connection starts fresh
    _firstPositionSet = false;

    // Save disabled state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_scopedKey(_prefKeyEnabled), false);

    debugPrint('✅ [LocationTracking] Tracking stopped');
  }

  /// Update the distance threshold and restart tracking if active
  Future<void> updateDistanceThreshold(double meters) async {
    gpsUpdateDistance = meters;
    await saveSettings();

    debugPrint(
      '📏 [LocationTracking] Distance threshold updated to ${meters}m',
    );

    // Restart tracking if currently active
    if (isTracking) {
      await stopTracking();
      await startTracking(distanceThreshold: meters);
    }
  }

  // ============================================================================
  // Position Update Handler
  // ============================================================================

  /// Handle incoming position updates from GPS stream
  void _handlePositionUpdate(Position position) {
    debugPrint(
      '📍 [LocationTracking] New position: ${position.latitude}, ${position.longitude}',
    );

    // Update current position
    currentPosition = position;

    // Notify listeners
    onPositionUpdate?.call(position);

    _evaluateFastLocationMovement(position);

    // SPECIAL CASE: First stable position after connection
    // Set lat/lon on device WITHOUT broadcasting to mesh network
    if (!_firstPositionSet) {
      _setInitialPosition(position);
      return;
    }

    // Check if we should broadcast to mesh network
    _checkAndBroadcast(position);
  }

  /// Set initial position on device without broadcasting
  ///
  /// Called only for the first stable GPS position after connection starts.
  /// Updates the device's advertised lat/lon but does NOT send an advertisement.
  void _setInitialPosition(Position position) async {
    if (_bleService == null || !_bleService!.isConnected) {
      debugPrint(
        '⚠️ [LocationTracking] Cannot set initial position: BLE not connected',
      );
      return;
    }

    try {
      debugPrint(
        '📍 [LocationTracking] Setting initial position (no broadcast)',
      );

      // Update device's advertised location WITHOUT sending advertisement
      await _bleService!.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      // Mark first position as set
      _firstPositionSet = true;

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_scopedKey(_prefKeyLastLat), position.latitude);
      await prefs.setDouble(_scopedKey(_prefKeyLastLon), position.longitude);

      debugPrint('✅ [LocationTracking] Initial position set without broadcast');
      debugPrint('   Next broadcast allowed in ${minTimeIntervalSeconds}s');
    } catch (e) {
      debugPrint('⚠️ [LocationTracking] Failed to set initial position: $e');
      debugPrint('   Will retry on next GPS update');
      // Don't mark as set on failure, so it will retry on next update
      // Don't call onError - this is not critical since it will retry automatically
    }
  }

  /// Check if position should be broadcast based on distance and time thresholds
  /// DISABLED: Automatic broadcasting removed - use advert button for manual broadcasts
  void _checkAndBroadcast(Position position) {
    // Automatic broadcasting disabled
    // Use the manual advert button instead
    debugPrint(
      '   ⏸️ [LocationTracking] Automatic broadcasting disabled (use advert button)',
    );
  }

  void setFastLocationActiveUse(bool isActive) {
    if (_isFastLocationActiveUse == isActive) return;
    _isFastLocationActiveUse = isActive;
    _refreshFastLocationTimer();
  }

  Future<void> setFastLocationUpdatesEnabled(bool enabled) async {
    fastLocationUpdatesEnabled = enabled;
    if (!enabled) {
      _resetFastGpsMotionState();
    }
    await saveSettings();
    _refreshFastLocationTimer();
  }

  Future<void> updateFastLocationMovementThreshold(double meters) async {
    fastLocationMovementThresholdMeters = meters.clamp(
      _minFastLocationMovementThresholdMeters,
      1000.0,
    );
    await saveSettings();
  }

  Future<void> updateFastLocationActiveCadenceSeconds(int seconds) async {
    fastLocationActiveCadenceSeconds = seconds.clamp(
      _minFastLocationActiveCadenceSeconds,
      _maxFastLocationActiveCadenceSeconds,
    );
    await saveSettings();
    _refreshFastLocationTimer();
  }

  Future<void> updateFastLocationChannelIdx(int? channelIdx) async {
    fastLocationChannelIdx = channelIdx;
    await saveSettings();
    _refreshFastLocationTimer();
  }

  /// Arms the post-RX send hold-off after hearing a peer's fast-GPS beacon, so
  /// the phone yields the channel briefly to avoid collisions
  /// (FAST_GPS_CHANNEL_RX_HOLDOFF_MS). Called by the app's incoming-beacon path.
  void noteFastGpsBeaconHeard() {
    _fastGpsRxHoldoffUntil = DateTime.now().add(_fastLocationRxHoldoff);
  }

  /// Clears all fast-GPS motion/anchor state. Mirrors resetFastGpsShareState.
  void _resetFastGpsMotionState() {
    _lastFastLocationSentAt = null;
    _lastFastLocationSentLatE6 = null;
    _lastFastLocationSentLonE6 = null;
    _fastGpsAnchorLatE6 = null;
    _fastGpsAnchorLonE6 = null;
    _fastGpsRefValid = false;
    _fastGpsIsMoving = false;
    _fastGpsMoveStateSince = null;
    _fastGpsMoveEvalAt = null;
    _fastGpsSpeedKmh = 0.0;
    _fastGpsSpeedPrevLatE6 = null;
    _fastGpsSpeedPrevLonE6 = null;
    _fastGpsSpeedPrevAt = null;
    _fastGpsRxHoldoffUntil = null;
  }

  void _evaluateFastLocationMovement(Position position) {
    if (!fastLocationUpdatesEnabled || fastLocationChannelIdx == null) return;
    _updateFastGpsMotionState(position);
    _maybeSendFastLocation();
  }

  void _refreshFastLocationTimer() {
    _fastLocationTimer?.cancel();
    _fastLocationTimer = null;
    if (!isTracking ||
        !fastLocationUpdatesEnabled ||
        fastLocationChannelIdx == null) {
      return;
    }

    // Always tick (even when parked) so the stationary keepalive fires without a
    // position-stream event. Tick fast while in active use; otherwise just often
    // enough to drive the 9-min keepalive cheaply.
    final period = _isFastLocationActiveUse
        ? _fastLocationActiveTick
        : _fastLocationStationaryInterval;
    _fastLocationTimer = Timer.periodic(period, (_) => _maybeSendFastLocation());
  }

  /// Updates the EMA ground speed and the moving/stationary anchor state machine
  /// from a fresh fix. Faithful port of MyMesh::updateGpsStatusCache.
  void _updateFastGpsMotionState(Position position) {
    // Fix-quality gate (firmware: satellitesCount >= FAST_GPS_MIN_SATS).
    final accuracy = position.accuracy;
    if (accuracy.isFinite &&
        accuracy > 0 &&
        accuracy > _fastLocationMaxAccuracyMeters) {
      return;
    }

    final now = DateTime.now();
    final latE6 = (position.latitude * 1e6).round();
    final lonE6 = (position.longitude * 1e6).round();

    // Ground speed from successive fixes, EMA-smoothed (0.4 prev / 0.6 inst).
    if (_fastGpsSpeedPrevLatE6 == null || _fastGpsSpeedPrevAt == null) {
      _fastGpsSpeedPrevLatE6 = latE6;
      _fastGpsSpeedPrevLonE6 = lonE6;
      _fastGpsSpeedPrevAt = now;
    } else {
      final distM = _distanceE6(
        _fastGpsSpeedPrevLatE6!,
        _fastGpsSpeedPrevLonE6!,
        latE6,
        lonE6,
      );
      final dtMs = now.difference(_fastGpsSpeedPrevAt!).inMilliseconds;
      if (distM >= _fastLocationSpeedGateMeters && dtMs >= 1000) {
        final instKmh = (distM / 1000.0) / (dtMs / 3600000.0);
        if (instKmh <= _fastLocationSpeedGlitchMaxKmh) {
          _fastGpsSpeedKmh = _fastGpsSpeedKmh * 0.4 + instKmh * 0.6;
        }
        _fastGpsSpeedPrevLatE6 = latE6;
        _fastGpsSpeedPrevLonE6 = lonE6;
        _fastGpsSpeedPrevAt = now;
      } else if (dtMs >= _fastLocationSpeedRebaseline.inMilliseconds) {
        _fastGpsSpeedKmh = 0.0;
        _fastGpsSpeedPrevLatE6 = latE6;
        _fastGpsSpeedPrevLonE6 = lonE6;
        _fastGpsSpeedPrevAt = now;
      }
    }

    // Moving/stationary state machine (anchor + dwell hysteresis), ~1 Hz.
    final evalAt = _fastGpsMoveEvalAt;
    if (evalAt != null && now.difference(evalAt) < _fastLocationMoveEval) {
      return;
    }
    _fastGpsMoveEvalAt = now;

    if (!_fastGpsRefValid) {
      _fastGpsAnchorLatE6 = latE6;
      _fastGpsAnchorLonE6 = lonE6;
      _fastGpsRefValid = true;
      _fastGpsMoveStateSince = null;
      _fastGpsIsMoving = false;
      return;
    }

    final refDist = _distanceE6(
      _fastGpsAnchorLatE6!,
      _fastGpsAnchorLonE6!,
      latE6,
      lonE6,
    );
    if (!_fastGpsIsMoving) {
      if (refDist > _fastLocationMoveRadiusMeters) {
        if (_fastGpsMoveStateSince == null) {
          _fastGpsMoveStateSince = now;
        } else if (now.difference(_fastGpsMoveStateSince!) >=
            _fastLocationMoveDwell) {
          _fastGpsIsMoving = true;
          _fastGpsAnchorLatE6 = latE6;
          _fastGpsAnchorLonE6 = lonE6;
          _fastGpsMoveStateSince = null;
        }
      } else {
        _fastGpsMoveStateSince = null;
        // Track slow GPS bias so cumulative drift never reaches the radius.
        _fastGpsAnchorLatE6 =
            _fastGpsAnchorLatE6! + ((latE6 - _fastGpsAnchorLatE6!) ~/ 8);
        _fastGpsAnchorLonE6 =
            _fastGpsAnchorLonE6! + ((lonE6 - _fastGpsAnchorLonE6!) ~/ 8);
      }
    } else {
      if (refDist > _fastLocationMoveRadiusMeters) {
        _fastGpsAnchorLatE6 = latE6;
        _fastGpsAnchorLonE6 = lonE6;
        _fastGpsMoveStateSince = null;
      } else if (_fastGpsMoveStateSince == null) {
        _fastGpsMoveStateSince = now;
      } else if (now.difference(_fastGpsMoveStateSince!) >=
          _fastLocationStopDwell) {
        _fastGpsIsMoving = false;
        _fastGpsAnchorLatE6 = latE6;
        _fastGpsAnchorLonE6 = lonE6;
        _fastGpsMoveStateSince = null;
      }
    }
  }

  /// Decides whether to emit a beacon now, mirroring maybeSendFastGpsUpdate:
  /// moving → speed-tier cadence once past the movement threshold; parked →
  /// flat 9-min keepalive of the stable anchor. Honours the RX hold-off.
  void _maybeSendFastLocation() {
    if (!fastLocationUpdatesEnabled || fastLocationChannelIdx == null) return;
    final position = currentPosition;
    if (position == null) return;
    // No valid anchor yet means no good fix has landed — don't beacon (the
    // firmware likewise bails until it has a usable fix).
    if (!_fastGpsRefValid) return;

    final int reportLatE6;
    final int reportLonE6;
    if (_fastGpsIsMoving) {
      reportLatE6 = (position.latitude * 1e6).round();
      reportLonE6 = (position.longitude * 1e6).round();
    } else {
      // Parked: report the stable anchor, not the wander.
      reportLatE6 = _fastGpsAnchorLatE6!;
      reportLonE6 = _fastGpsAnchorLonE6!;
    }

    final now = DateTime.now();
    final lastAt = _lastFastLocationSentAt;
    bool shouldSend = lastAt == null || _lastFastLocationSentLatE6 == null;
    String reason = 'initial';
    if (!shouldSend) {
      if (_fastGpsIsMoving) {
        final distM = _distanceE6(
          _lastFastLocationSentLatE6!,
          _lastFastLocationSentLonE6!,
          reportLatE6,
          reportLonE6,
        );
        if (distM > fastLocationMovementThresholdMeters) {
          final elapsed = now.difference(lastAt!);
          final interval = _movingIntervalForSpeedKmh(_fastGpsSpeedKmh);
          shouldSend = elapsed >= interval;
          reason = 'movement';
        }
      } else if (now.difference(lastAt!) >= _fastLocationStationaryInterval) {
        shouldSend = true;
        reason = 'stationary';
      }
    }
    if (!shouldSend) return;

    // Yield the channel briefly after hearing a peer beacon.
    final holdoff = _fastGpsRxHoldoffUntil;
    if (holdoff != null) {
      if (now.isBefore(holdoff)) return;
      _fastGpsRxHoldoffUntil = null;
    }

    _lastFastLocationSentLatE6 = reportLatE6;
    _lastFastLocationSentLonE6 = reportLonE6;
    _lastFastLocationSentAt = now;

    final speedKmh = _fastGpsSpeedKmh < 0
        ? 0
        : (_fastGpsSpeedKmh > 255.0 ? 255 : (_fastGpsSpeedKmh + 0.5).floor());
    onFastLocationUpdate?.call(
      reportLatE6 / 1e6,
      reportLonE6 / 1e6,
      speedKmh,
      reason,
    );
  }

  Duration _movingIntervalForSpeedKmh(double speedKmh) {
    final speedMps = speedKmh / 3.6;
    if (speedMps < _fastLocationIdleSpeedMaxMetersPerSecond) {
      return _fastLocationStationaryInterval;
    }
    if (speedMps < _fastLocationWalkingSpeedMaxMetersPerSecond) {
      return _fastLocationWalkingInterval;
    }
    if (speedMps < _fastLocationFastSpeedMaxMetersPerSecond) {
      return _fastLocationFastInterval;
    }
    return _fastLocationVeryFastInterval;
  }

  double _distanceE6(int latA, int lonA, int latB, int lonB) {
    return Geolocator.distanceBetween(
      latA / 1e6,
      lonA / 1e6,
      latB / 1e6,
      lonB / 1e6,
    );
  }

  // ============================================================================
  // Mesh Network Broadcasting
  // ============================================================================

  /// Manually broadcast current location immediately
  ///
  /// Useful for "Send Location Now" button functionality.
  /// Note: Manual broadcasts bypass automatic throttling and can be sent anytime.
  /// However, they still update the last broadcast time to maintain proper spacing
  /// for subsequent automatic broadcasts.
  Future<bool> broadcastLocationNow() async {
    if (!_isInitialized || _bleService == null) {
      onError?.call('Location tracking service not initialized');
      return false;
    }

    if (!_bleService!.isConnected) {
      onError?.call('Not connected to mesh device');
      return false;
    }

    try {
      // Get current position
      final position = await getCurrentPosition();
      if (position == null) {
        onError?.call('Failed to get current position');
        return false;
      }

      debugPrint('📤 [LocationTracking] Manual broadcast requested');

      // Broadcast regardless of automatic throttling thresholds
      await _bleService!.setAdvertLatLon(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      await _bleService!.sendSelfAdvert(floodMode: true);

      debugPrint('✅ [LocationTracking] Manual broadcast successful');
      debugPrint(
        '   Automatic broadcasts will resume after ${minTimeIntervalSeconds}s',
      );
      onBroadcastSent?.call(position);

      return true;
    } catch (e) {
      debugPrint('❌ [LocationTracking] Manual broadcast failed: $e');
      onError?.call('Failed to broadcast location: $e');
      return false;
    }
  }

  // ============================================================================
  // Settings Persistence
  // ============================================================================

  /// Load settings from SharedPreferences
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    minDistanceMeters = prefs.getDouble(_scopedKey(_prefKeyMinDistance)) ?? 5.0;
    maxDistanceMeters =
        prefs.getDouble(_scopedKey(_prefKeyMaxDistance)) ?? 100.0;
    minTimeIntervalSeconds =
        prefs.getInt(_scopedKey(_prefKeyMinTimeInterval)) ?? 30;
    gpsUpdateDistance =
        prefs.getDouble(_scopedKey(_prefKeyGpsUpdateDistance)) ?? 10.0;
    fastLocationUpdatesEnabled =
        prefs.getBool(_scopedKey(_prefKeyFastLocationEnabled)) ?? false;
    fastLocationMovementThresholdMeters =
        (prefs.getDouble(_scopedKey(_prefKeyFastMovementThreshold)) ??
                _defaultFastLocationMovementThresholdMeters)
            .clamp(_minFastLocationMovementThresholdMeters, 1000.0);
    fastLocationActiveCadenceSeconds =
        (prefs.getInt(_scopedKey(_prefKeyFastActiveCadence)) ??
                _defaultFastLocationActiveCadenceSeconds)
            .clamp(
          _minFastLocationActiveCadenceSeconds,
          _maxFastLocationActiveCadenceSeconds,
        );
    fastLocationChannelIdx = prefs.getInt(_scopedKey(_prefKeyFastChannelIdx));

    debugPrint('✅ [LocationTracking] Settings loaded');
    debugPrint('    Min distance: ${minDistanceMeters}m');
    debugPrint('    Max distance: ${maxDistanceMeters}m');
    debugPrint('    Min time interval: ${minTimeIntervalSeconds}s');
    debugPrint('    GPS update distance: ${gpsUpdateDistance}m');
    debugPrint('    Fast updates enabled: $fastLocationUpdatesEnabled');
    debugPrint(
      '    Fast movement threshold: ${fastLocationMovementThresholdMeters}m',
    );
    debugPrint('    Fast active cadence: ${fastLocationActiveCadenceSeconds}s');
    debugPrint('    Fast channel idx: ${fastLocationChannelIdx ?? "unset"}');
  }

  /// Save settings to SharedPreferences
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setDouble(_scopedKey(_prefKeyMinDistance), minDistanceMeters);
    await prefs.setDouble(_scopedKey(_prefKeyMaxDistance), maxDistanceMeters);
    await prefs.setInt(
      _scopedKey(_prefKeyMinTimeInterval),
      minTimeIntervalSeconds,
    );
    await prefs.setDouble(
      _scopedKey(_prefKeyGpsUpdateDistance),
      gpsUpdateDistance,
    );
    await prefs.setBool(_scopedKey(_prefKeyEnabled), isTracking);
    await prefs.setBool(
      _scopedKey(_prefKeyFastLocationEnabled),
      fastLocationUpdatesEnabled,
    );
    await prefs.setDouble(
      _scopedKey(_prefKeyFastMovementThreshold),
      fastLocationMovementThresholdMeters,
    );
    await prefs.setInt(
      _scopedKey(_prefKeyFastActiveCadence),
      fastLocationActiveCadenceSeconds,
    );
    final channelKey = _scopedKey(_prefKeyFastChannelIdx);
    if (fastLocationChannelIdx == null) {
      await prefs.remove(channelKey);
    } else {
      await prefs.setInt(channelKey, fastLocationChannelIdx!);
    }

    debugPrint('✅ [LocationTracking] Settings saved');
  }

  // ============================================================================
  // Cleanup
  // ============================================================================

  /// Dispose resources and cleanup
  void dispose() {
    debugPrint('🗑️ [LocationTracking] Disposing service');
    _positionSubscription?.cancel();
    _fastLocationTimer?.cancel();
    _positionSubscription = null;
    _bleService = null;
    _isInitialized = false;
    isTracking = false;
  }
}
