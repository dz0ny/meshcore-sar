import 'dart:async';

/// Tracks one or more in-flight waiters for the same fragment ACK key.
///
/// Duplicate fetch requests can race and wait on the same fragment ACK at once.
/// Completing all registered waiters avoids losing the earlier completer when a
/// later request registers for the same key.
class FragmentAckWaitRegistry {
  final Map<String, List<Completer<void>>> _waiters = {};

  Future<bool> waitFor(
    String key, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final completer = Completer<void>();
    final waiters = _waiters.putIfAbsent(key, () => <Completer<void>>[]);
    waiters.add(completer);
    try {
      await completer.future.timeout(timeout);
      return true;
    } catch (_) {
      final pending = _waiters[key];
      pending?.remove(completer);
      if (pending != null && pending.isEmpty) {
        _waiters.remove(key);
      }
      return false;
    }
  }

  int complete(String key) {
    final waiters = _waiters.remove(key);
    if (waiters == null || waiters.isEmpty) {
      return 0;
    }
    for (final completer in waiters) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    return waiters.length;
  }
}
