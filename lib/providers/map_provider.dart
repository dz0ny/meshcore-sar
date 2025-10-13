import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapProvider with ChangeNotifier {
  LatLng? _targetLocation;
  double? _targetZoom;
  bool _shouldAnimate = false;

  LatLng? get targetLocation => _targetLocation;
  double? get targetZoom => _targetZoom;
  bool get shouldAnimate => _shouldAnimate;

  void navigateToLocation({
    required LatLng location,
    double zoom = 15.0,
    bool animate = true,
  }) {
    _targetLocation = location;
    _targetZoom = zoom;
    _shouldAnimate = animate;
    notifyListeners();
  }

  void clearNavigation() {
    _targetLocation = null;
    _targetZoom = null;
    _shouldAnimate = false;
    // Don't notify listeners to avoid rebuilds
  }

  void updateZoom(double zoom) {
    _targetZoom = zoom;
    notifyListeners();
  }
}
