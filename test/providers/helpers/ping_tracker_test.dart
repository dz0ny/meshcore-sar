import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/helpers/ping_tracker.dart';

void main() {
  Uint8List createPublicKey() => Uint8List.fromList(
    List<int>.generate(32, (index) => index + 1),
  );

  group('PingTracker', () {
    test('completes pending ping when response uses public key prefix', () async {
      final tracker = PingTracker();
      final publicKey = createPublicKey();

      final pingFuture = tracker.trackPing(
        publicKey: publicKey,
        wasDirectAttempt: true,
      );

      tracker.markPingSuccessful(publicKey.sublist(0, 6));

      await expectLater(pingFuture, completion(isTrue));
      expect(tracker.hasPendingPing(publicKey), isFalse);
    });
  });
}
