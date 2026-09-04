import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';

void main() {
  group('ConnectionProvider channel slot occupancy', () {
    test('treats non-zero secret as configured', () {
      expect(
        ConnectionProvider.channelHasConfiguredSecret(Uint8List(16)),
        isFalse,
      );
      expect(
        ConnectionProvider.channelHasConfiguredSecret(
          Uint8List.fromList([1, ...List<int>.filled(15, 0)]),
        ),
        isTrue,
      );
    });

    test('treats duplicate hashtag channels as conflicts', () {
      expect(
        ConnectionProvider.isDuplicateChannelName(
          requestedName: '#sar',
          existingName: '#sar',
        ),
        isTrue,
      );
    });

    test('allows private channels with the same name to coexist', () {
      expect(
        ConnectionProvider.isDuplicateChannelName(
          requestedName: 'Ops',
          existingName: 'Ops',
        ),
        isFalse,
      );
    });

    test('does not treat arbitrary empty channel info as deletion', () {
      final provider = ConnectionProvider();
      expect(
        provider.shouldTreatChannelInfoAsDeleted(3, '', Uint8List(16)),
        isFalse,
      );
    });

    test('finds first missing custom channel slot', () {
      expect(
        ConnectionProvider.firstAvailableChannelSlot(
          occupiedIndices: {1, 2, 4},
          maxChannels: 6,
        ),
        3,
      );
    });

    test('returns null when all custom channel slots are occupied', () {
      expect(
        ConnectionProvider.firstAvailableChannelSlot(
          occupiedIndices: {1, 2, 3, 4},
          maxChannels: 5,
        ),
        isNull,
      );
    });

    test('private channels with same name do not block slot selection', () {
      expect(
        ConnectionProvider.isDuplicateChannelName(
          requestedName: 'RPT_admins',
          existingName: 'RPT_admins',
        ),
        isFalse,
      );
      expect(
        ConnectionProvider.firstAvailableChannelSlot(
          occupiedIndices: {1, 2, 3},
          maxChannels: 6,
        ),
        4,
      );
    });
  });
}
