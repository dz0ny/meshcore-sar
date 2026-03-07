import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/utils/log_rx_route_decoder.dart';

void main() {
  group('LogRxRouteDecoder.decode', () {
    test('parses route and sender from LOG_RX_DATA packet', () {
      final packet = Uint8List.fromList([
        0x88,
        0x37,
        0xae,
        0x05,
        0x04,
        0xc2,
        0xba,
        0x5f,
        0xde,
        0x5c,
      ]);

      final decoded = LogRxRouteDecoder.decode(packet);

      expect(decoded, isNotNull);
      expect(decoded!.payloadType, 0x01);
      expect(decoded.pathHashes, [0xc2, 0xba, 0x5f, 0xde]);
      expect(decoded.originalSenderHash, 0xc2);
    });
  });

  group('LogRxRouteDecoder.resolveHash', () {
    test('prefers own node when hash matches device key', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        0xc2,
        contacts: const [],
        ownPublicKey: Uint8List.fromList([0xc2, 0x01, 0x02]),
        ownName: 'Base',
      );

      expect(resolved.isOwnNode, isTrue);
      expect(resolved.label, 'Base (you)');
    });

    test('resolves unique contact by first public key byte', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        0xc2,
        contacts: [_contact(name: 'Alpha', keyPrefix: 0xc2)],
      );

      expect(resolved.isUniqueMatch, isTrue);
      expect(resolved.label, 'Alpha');
    });

    test('marks ambiguous matches without pretending certainty', () {
      final resolved = LogRxRouteDecoder.resolveHash(
        0xc2,
        contacts: [
          _contact(name: 'Alpha', keyPrefix: 0xc2),
          _contact(name: 'Bravo', keyPrefix: 0xc2),
        ],
      );

      expect(resolved.isUniqueMatch, isFalse);
      expect(resolved.matchCount, 2);
    });
  });
}

Contact _contact({required String name, required int keyPrefix}) {
  return Contact(
    publicKey: Uint8List.fromList([
      keyPrefix,
      0x11,
      0x22,
      0x33,
      0x44,
      0x55,
      0x66,
      0x77,
    ]),
    type: ContactType.chat,
    flags: 0,
    outPathLen: 0,
    outPath: Uint8List(0),
    advName: name,
    lastAdvert: 0,
    advLat: 0,
    advLon: 0,
    lastMod: 0,
  );
}
