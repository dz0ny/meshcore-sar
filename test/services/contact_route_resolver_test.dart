import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/contact_route_resolver.dart';

void main() {
  test('prefers known repeater route when available', () {
    final recipient = _contact(
      name: 'Target',
      type: ContactType.chat,
      seed: 90,
      lat: 46.20,
      lon: 14.70,
    );
    final routedRepeater = _contact(
      name: 'Routed',
      type: ContactType.repeater,
      seed: 10,
      lat: 46.15,
      lon: 14.60,
      signedPathLen: ContactRouteCodec.toSignedDescriptor(1),
      outPath: Uint8List.fromList([0xAA]),
    );

    final plan = ContactRouteResolver.resolveAutomaticRoute(
      senderLocation: const LatLng(46.00, 14.50),
      recipient: recipient,
      availableContacts: [routedRepeater],
      hashSize: 1,
    );

    expect(plan, isNotNull);
    expect(plan!.tokens, [
      'AA',
      routedRepeater.publicKeyHex.substring(0, 2).toUpperCase(),
    ]);
  });

  test('falls back to location-only repeaters', () {
    final recipient = _contact(
      name: 'Target',
      type: ContactType.chat,
      seed: 90,
      lat: 46.20,
      lon: 14.70,
    );
    final nearRepeater = _contact(
      name: 'Near',
      type: ContactType.repeater,
      seed: 10,
      lat: 46.08,
      lon: 14.55,
    );
    final farRepeater = _contact(
      name: 'Far',
      type: ContactType.repeater,
      seed: 11,
      lat: 46.40,
      lon: 15.10,
    );

    final plan = ContactRouteResolver.resolveAutomaticRoute(
      senderLocation: const LatLng(46.00, 14.50),
      recipient: recipient,
      availableContacts: [nearRepeater, farRepeater],
      hashSize: 1,
    );

    expect(plan, isNotNull);
    expect(plan!.selectedContacts.first.displayName, 'Near');
  });

  test('for known routes prefers anchor closest to the chain end', () {
    final recipient = _contact(
      name: 'Target',
      type: ContactType.chat,
      seed: 90,
      lat: 46.20,
      lon: 14.70,
    );
    final chainHop = _contact(
      name: 'Chain Hop',
      type: ContactType.repeater,
      seed: 0xAA,
      lat: 46.01,
      lon: 14.51,
    );
    final nearAnchor = _contact(
      name: 'Near Anchor',
      type: ContactType.repeater,
      seed: 10,
      lat: 46.03,
      lon: 14.53,
      signedPathLen: ContactRouteCodec.toSignedDescriptor(1),
      outPath: Uint8List.fromList([0xAA]),
    );
    final farAnchor = _contact(
      name: 'Far Anchor',
      type: ContactType.repeater,
      seed: 11,
      lat: 46.18,
      lon: 14.68,
      signedPathLen: ContactRouteCodec.toSignedDescriptor(1),
      outPath: Uint8List.fromList([0xAA]),
    );

    final plan = ContactRouteResolver.resolveAutomaticRoute(
      senderLocation: const LatLng(46.00, 14.50),
      recipient: recipient,
      availableContacts: [chainHop, nearAnchor, farAnchor],
      hashSize: 1,
    );

    expect(plan, isNotNull);
    expect(plan!.selectedContacts.last.displayName, 'Near Anchor');
  });
}

Contact _contact({
  required String name,
  required ContactType type,
  required int seed,
  required double lat,
  required double lon,
  int signedPathLen = -1,
  Uint8List? outPath,
}) {
  final publicKey = Uint8List(32)..fillRange(0, 32, seed);
  return Contact(
    publicKey: publicKey,
    type: type,
    flags: 0,
    outPathLen: signedPathLen,
    outPath: outPath ?? Uint8List(64),
    advName: name,
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: (lat * 1e6).round(),
    advLon: (lon * 1e6).round(),
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}
