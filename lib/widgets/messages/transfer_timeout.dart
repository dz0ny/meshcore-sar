import 'dart:async';

/// Calculates a transfer timeout as 2× the estimated LoRa airtime,
/// with a minimum of 30 seconds.
///
/// Used by [ImageMessageBubble] and [VoiceMessageBubble] to reset the
/// "loading" spinner when a transfer stalls, allowing the user to retry.
class TransferTimeout {
  static const Duration _minimum = Duration(seconds: 30);

  /// Start a one-shot timer based on [txEstimate] × 2 (min 30s).
  ///
  /// [onTimeout] is called on the UI thread when the timer fires.
  /// Returns the [Timer] so the caller can cancel it (e.g. on dispose or
  /// when the transfer completes).
  static Timer start({
    required Duration txEstimate,
    required void Function() onTimeout,
  }) {
    final timeout = txEstimate * 2;
    final effective = timeout < _minimum ? _minimum : timeout;
    return Timer(effective, onTimeout);
  }
}
