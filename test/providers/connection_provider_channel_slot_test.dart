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
  });
}
