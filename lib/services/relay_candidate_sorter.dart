import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/contact.dart';

class RelayCandidateSorter {
  const RelayCandidateSorter();

  List<Contact> sortByDistanceFromSelf(
    List<Contact> contacts, {
    required LatLng? selfPoint,
  }) {
    final sorted = List<Contact>.from(contacts);
    sorted.sort((a, b) {
      if (selfPoint != null) {
        final distanceCompare = _distanceFrom(
          selfPoint,
          a,
        ).compareTo(_distanceFrom(selfPoint, b));
        if (distanceCompare != 0) {
          return distanceCompare;
        }
      }

      final nameCompare = a.displayName.compareTo(b.displayName);
      if (nameCompare != 0) {
        return nameCompare;
      }

      return a.publicKeyHex.compareTo(b.publicKeyHex);
    });
    return sorted;
  }

  double _distanceFrom(LatLng selfPoint, Contact contact) {
    final location = contact.displayLocation;
    if (location == null) {
      return double.infinity;
    }

    return Geolocator.distanceBetween(
      selfPoint.latitude,
      selfPoint.longitude,
      location.latitude,
      location.longitude,
    );
  }
}
