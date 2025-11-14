/// Message delivery tracking helper
///
/// Manages message delivery tracking for sent messages, including:
/// - FIFO queue for matching RESP_CODE_SENT with message IDs
/// - ACK tag to message ID mapping
/// - Timeout tracking for stale ACK mappings
/// - Message sent/delivered coordination
///
/// IMPORTANT: Based on MeshCore firmware analysis:
/// - Firmware tracks max 8 pending ACKs in circular buffer
/// - ACK entries overwritten after 8 messages → need rate limiting
/// - Duplicate ACKs suppressed after first match
/// - No automatic retry → app must implement
class MessageDeliveryTracker {
  /// FIFO queue of pending message IDs
  /// Messages tracked here before sending, popped when RESP_CODE_SENT arrives
  final List<String> _pendingMessageIds = [];

  /// Map of ACK tag to message ID for delivery confirmation
  final Map<int, String> _ackTagToMessageId = {};

  /// Map of message ID to ACK tag (reverse mapping for cleanup)
  final Map<String, int> _messageIdToAckTag = {};

  /// Map of ACK tag to timestamp for timeout cleanup
  final Map<int, DateTime> _ackTagTimestamps = {};

  /// Track a pending message ID before sending
  ///
  /// This is called BEFORE sending the message. When RESP_CODE_SENT
  /// arrives, we pop from this FIFO queue to match with the ACK tag.
  void trackPendingMessage(String messageId) {
    _pendingMessageIds.add(messageId);
  }

  /// Pop the next pending message ID from FIFO queue
  ///
  /// Called when RESP_CODE_SENT arrives. Returns null if queue empty.
  String? popPendingMessageId() {
    if (_pendingMessageIds.isEmpty) {
      return null;
    }
    return _pendingMessageIds.removeAt(0);
  }

  /// Map ACK tag to message ID after RESP_CODE_SENT received
  ///
  /// Creates bidirectional mapping for efficient cleanup and tracking.
  ///
  /// WARNING: Firmware only tracks 8 pending ACKs! Caller should
  /// enforce rate limiting before calling this.
  void mapAckTagToMessageId(int ackTag, String messageId) {
    // Store bidirectional mapping
    _ackTagToMessageId[ackTag] = messageId;
    _messageIdToAckTag[messageId] = ackTag;
    _ackTagTimestamps[ackTag] = DateTime.now();
  }

  /// Get message ID for ACK code
  ///
  /// Called when SEND_CONFIRMED arrives. Returns the message ID
  /// that corresponds to this ACK code.
  ///
  /// Returns null if ACK tag not found.
  String? getMessageIdForAck(int ackCode) {
    return _ackTagToMessageId[ackCode];
  }

  /// Remove ACK tag mapping after delivery confirmed or timeout
  ///
  /// Cleans up both forward and reverse mappings.
  void removeAckTag(int ackCode) {
    final messageId = _ackTagToMessageId.remove(ackCode);
    if (messageId != null) {
      _messageIdToAckTag.remove(messageId);
    }
    _ackTagTimestamps.remove(ackCode);
  }

  /// Remove ACK tag mapping by message ID
  ///
  /// Used when message times out or is cancelled.
  void removeByMessageId(String messageId) {
    final ackTag = _messageIdToAckTag.remove(messageId);
    if (ackTag != null) {
      _ackTagToMessageId.remove(ackTag);
      _ackTagTimestamps.remove(ackTag);
    }
  }

  /// Clean up stale ACK mappings
  ///
  /// Removes ACK tags that haven't received delivery confirmation
  /// within the specified timeout (default: 5 minutes).
  ///
  /// Returns count of cleaned up entries.
  int cleanupStaleAcks({Duration timeout = const Duration(minutes: 5)}) {
    final now = DateTime.now();
    final staleAcks = <int>[];

    for (final entry in _ackTagTimestamps.entries) {
      if (now.difference(entry.value) > timeout) {
        staleAcks.add(entry.key);
      }
    }

    for (final ackTag in staleAcks) {
      removeAckTag(ackTag);
    }

    return staleAcks.length;
  }

  /// Clear all tracking state
  void clearTracking() {
    _pendingMessageIds.clear();
    _ackTagToMessageId.clear();
    _messageIdToAckTag.clear();
    _ackTagTimestamps.clear();
  }

  /// Get count of pending ACK tags
  ///
  /// WARNING: Firmware only tracks 8 pending ACKs in circular buffer.
  /// If this exceeds 7, message sending should be rate limited.
  int get pendingCount => _ackTagToMessageId.length;

  /// Check if should rate limit message sending
  ///
  /// Returns true if >= 7 pending ACKs (stay under firmware limit of 8)
  bool get shouldRateLimit => pendingCount >= 7;

  /// Get oldest pending ACK timestamp (for debugging)
  DateTime? get oldestPendingTimestamp {
    if (_ackTagTimestamps.isEmpty) return null;
    return _ackTagTimestamps.values.reduce(
      (a, b) => a.isBefore(b) ? a : b,
    );
  }

  /// Get diagnostic info for debugging
  Map<String, dynamic> getDiagnostics() {
    return {
      'pendingCount': pendingCount,
      'shouldRateLimit': shouldRateLimit,
      'oldestPending': oldestPendingTimestamp?.toIso8601String(),
      'ackTags': _ackTagToMessageId.keys.toList(),
    };
  }
}
