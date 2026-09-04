import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/relay_candidate_sorter.dart';

void main() {
  test('sorts relay candidates by distance from self point', () {
    final sorter = RelayCandidateSorter();

    final sorted = sorter.sortByDistanceFromSelf([
      _contact(seed: 1, name: 'Far', lat: 46.08, lon: 14.60),
      _contact(seed: 2, name: 'Near', lat: 46.0570, lon: 14.5060),
      _contact(seed: 3, name: 'Middle', lat: 46.06, lon: 14.52),
    ], selfPoint: const LatLng(46.0569, 14.5058));

    expect(sorted.map((contact) => contact.displayName).toList(), [
      'Near',
      'Middle',
      'Far',
    ]);
  });

  test('falls back to stable name ordering when self point is unavailable', () {
    final sorter = RelayCandidateSorter();

    final sorted = sorter.sortByDistanceFromSelf([
      _contact(seed: 1, name: 'Zulu', lat: 46.08, lon: 14.60),
      _contact(seed: 2, name: 'Alpha', lat: 46.0570, lon: 14.5060),
    ], selfPoint: null);

    expect(sorted.map((contact) => contact.displayName).toList(), [
      'Alpha',
      'Zulu',
    ]);
  });
}

Contact _contact({
  required int seed,
  required String name,
  required double lat,
  required double lon,
}) {
  final publicKey = Uint8List(32)..fillRange(0, 32, seed);
  return Contact(
    publicKey: publicKey,
    type: ContactType.repeater,
    flags: 0,
    outPathLen: -1,
    outPath: Uint8List(64),
    advName: name,
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: (lat * 1e6).round(),
    advLon: (lon * 1e6).round(),
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
