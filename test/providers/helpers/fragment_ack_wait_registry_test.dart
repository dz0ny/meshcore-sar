import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/helpers/fragment_ack_wait_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FragmentAckWaitRegistry', () {
    test('completes multiple waiters registered for the same key', () async {
      final registry = FragmentAckWaitRegistry();

      final first = registry.waitFor(
        'voice:1',
        timeout: const Duration(milliseconds: 200),
      );
      final second = registry.waitFor(
        'voice:1',
        timeout: const Duration(milliseconds: 200),
      );

      expect(registry.complete('voice:1'), equals(2));
      expect(await first, isTrue);
      expect(await second, isTrue);
    });

    test('times out and cleans up a waiter when no ack arrives', () async {
      final registry = FragmentAckWaitRegistry();

      final completed = await registry.waitFor(
        'voice:2',
        timeout: const Duration(milliseconds: 20),
      );

      expect(completed, isFalse);
      expect(registry.complete('voice:2'), equals(0));
    });
  });
}
