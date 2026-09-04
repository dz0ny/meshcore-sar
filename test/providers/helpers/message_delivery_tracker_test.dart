import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/helpers/message_delivery_tracker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageDeliveryTracker', () {
    test('matches pending direct messages by contact', () {
      final tracker = MessageDeliveryTracker();
      final alice = Uint8List.fromList(List<int>.filled(32, 0xAA));
      final bob = Uint8List.fromList(List<int>.filled(32, 0xBB));

      tracker.trackPendingDirectMessage('alice-1', alice);
      tracker.trackPendingDirectMessage('bob-1', bob);
      tracker.trackPendingDirectMessage('alice-2', alice);

      expect(tracker.popPendingDirectMessageId(alice), 'alice-1');
      expect(tracker.popPendingDirectMessageId(bob), 'bob-1');
      expect(tracker.popPendingDirectMessageId(alice), 'alice-2');
    });

    test('removeByMessageId clears pending queue state', () {
      final tracker = MessageDeliveryTracker();
      final alice = Uint8List.fromList(List<int>.filled(32, 0xAA));

      tracker.trackPendingDirectMessage('alice-1', alice);
      tracker.mapAckTagToMessageId(42, 'alice-1');

      tracker.removeByMessageId('alice-1');

      expect(tracker.getMessageIdForAck(42), isNull);
      expect(tracker.popPendingDirectMessageId(alice), isNull);
    });
  });
}
