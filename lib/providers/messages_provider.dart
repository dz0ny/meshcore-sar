import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/sar_marker.dart';
import '../services/message_storage_service.dart';
import '../utils/sar_message_parser.dart';

/// Messages Provider - manages message history and SAR markers
class MessagesProvider with ChangeNotifier {
  final List<Message> _messages = [];
  final Map<String, SarMarker> _sarMarkers = {};
  final MessageStorageService _storageService = MessageStorageService();
  bool _isInitialized = false;

  // Track pending sent messages by expected ACK/TAG
  final Map<int, Message> _pendingSentMessages = {};

  // Track timeout timers for pending messages
  final Map<int, Timer> _timeoutTimers = {};

  List<Message> get messages => List.unmodifiable(_messages);

  List<Message> get contactMessages =>
      _messages.where((m) => m.isContactMessage).toList();

  List<Message> get channelMessages =>
      _messages.where((m) => m.isChannelMessage).toList();

  List<Message> get sarMarkerMessages =>
      _messages.where((m) => m.isSarMarker).toList();

  List<SarMarker> get sarMarkers => _sarMarkers.values.toList();

  List<SarMarker> get foundPersonMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.foundPerson).toList();

  List<SarMarker> get fireMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.fire).toList();

  List<SarMarker> get stagingAreaMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.stagingArea).toList();

  List<SarMarker> get objectMarkers =>
      sarMarkers.where((m) => m.type == SarMarkerType.object).toList();

  bool get isInitialized => _isInitialized;

  /// Initialize and load persisted messages
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('📦 [MessagesProvider] Loading persisted messages...');
      final storedMessages = await _storageService.loadMessages();

      // Add stored messages with enhancement to ensure SAR detection
      for (final message in storedMessages) {
        // Re-enhance each message to ensure SAR markers are properly detected
        // This handles cases where messages were stored before enhancement logic
        final enhancedMessage = SarMessageParser.enhanceMessage(message);
        _messages.add(enhancedMessage);

        // Extract SAR markers
        if (enhancedMessage.isSarMarker) {
          final marker = enhancedMessage.toSarMarker();
          if (marker != null) {
            _sarMarkers[marker.id] = marker;
          }
        }
      }

      _isInitialized = true;
      print('✅ [MessagesProvider] Loaded ${storedMessages.length} persisted messages');
      notifyListeners();
    } catch (e) {
      print('❌ [MessagesProvider] Error initializing: $e');
      _isInitialized = true; // Mark as initialized even on error
    }
  }

  /// Add a message
  void addMessage(Message message) {
    // Always enhance message with SAR parser to detect SAR markers
    final enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Debug: Check if message is SAR
    if (message.text.startsWith('S:')) {
      print('🔍 [MessagesProvider] Processing SAR message: ${message.text}');
      print('   isSarMarker: ${enhancedMessage.isSarMarker}');
      print('   sarMarkerType: ${enhancedMessage.sarMarkerType}');
    }

    // Check for duplicates before adding
    // Messages can arrive multiple times due to:
    // - Mesh network retransmissions
    // - Multiple paths in the network
    // - Syncing messages from device queue
    if (_isDuplicate(enhancedMessage)) {
      print('⚠️ [MessagesProvider] Duplicate message detected, skipping: ${enhancedMessage.id}');
      print('   Text: ${enhancedMessage.text.substring(0, enhancedMessage.text.length > 50 ? 50 : enhancedMessage.text.length)}...');
      return; // Skip duplicate
    }

    _messages.add(enhancedMessage);

    // If it's a SAR marker message, extract and store the marker
    if (enhancedMessage.isSarMarker) {
      final marker = enhancedMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;
      }
    }

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Check if a message is a duplicate
  ///
  /// Messages are considered duplicates if they have:
  /// 1. Same sender public key prefix (for contact messages)
  /// 2. Same channel index (for channel messages)
  /// 3. Same sender timestamp
  /// 4. Same text content
  bool _isDuplicate(Message message) {
    return _messages.any((existing) {
      // Check message type matches
      if (existing.messageType != message.messageType) {
        return false;
      }

      // Check sender matches
      if (message.isContactMessage) {
        // For contact messages, compare sender public key prefix
        if (existing.senderKeyShort != message.senderKeyShort) {
          return false;
        }
      } else if (message.isChannelMessage) {
        // For channel messages, compare channel index
        if (existing.channelIdx != message.channelIdx) {
          return false;
        }
      }

      // Check timestamp matches (sender timestamp is the unique identifier from the sender)
      if (existing.senderTimestamp != message.senderTimestamp) {
        return false;
      }

      // Check text content matches
      if (existing.text != message.text) {
        return false;
      }

      // All criteria match - this is a duplicate
      return true;
    });
  }

  /// Add multiple messages
  void addMessages(List<Message> messages) {
    int addedCount = 0;
    int duplicateCount = 0;

    for (final message in messages) {
      // Always enhance message with SAR parser to detect SAR markers
      final enhancedMessage = SarMessageParser.enhanceMessage(message);

      // Check for duplicates
      if (_isDuplicate(enhancedMessage)) {
        duplicateCount++;
        continue; // Skip duplicate
      }

      _messages.add(enhancedMessage);
      addedCount++;

      if (enhancedMessage.isSarMarker) {
        final marker = enhancedMessage.toSarMarker();
        if (marker != null) {
          _sarMarkers[marker.id] = marker;
        }
      }
    }

    print('📥 [MessagesProvider] Added $addedCount messages, skipped $duplicateCount duplicates');

    // Persist to storage asynchronously
    _persistMessages();

    notifyListeners();
  }

  /// Persist messages to storage (async, non-blocking)
  Future<void> _persistMessages() async {
    try {
      await _storageService.saveMessages(_messages);
    } catch (e) {
      print('❌ [MessagesProvider] Error persisting messages: $e');
    }
  }

  /// Get messages for a specific contact
  List<Message> getMessagesForContact(String senderKeyShort) {
    return _messages
        .where((m) =>
            m.isContactMessage &&
            m.senderKeyShort != null &&
            m.senderKeyShort!.startsWith(senderKeyShort))
        .toList();
  }

  /// Get messages for a specific channel
  List<Message> getMessagesForChannel(int channelIdx) {
    return _messages
        .where((m) => m.isChannelMessage && m.channelIdx == channelIdx)
        .toList();
  }

  /// Get recent messages (last N messages)
  List<Message> getRecentMessages({int count = 50}) {
    final sorted = List<Message>.from(_messages)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return sorted.take(count).toList();
  }

  /// Get messages from last N hours
  List<Message> getMessagesSince(Duration duration) {
    final cutoff = DateTime.now().subtract(duration);
    return _messages.where((m) => m.sentAt.isAfter(cutoff)).toList();
  }

  /// Search messages by text
  List<Message> searchMessages(String query) {
    if (query.isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _messages
        .where((m) => m.text.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get SAR marker by ID
  SarMarker? getSarMarker(String id) {
    return _sarMarkers[id];
  }

  /// Get recent SAR markers (within last hour)
  List<SarMarker> getRecentSarMarkers() {
    return sarMarkers.where((m) => m.isRecent).toList();
  }

  /// Remove a SAR marker
  void removeSarMarker(String id) {
    _sarMarkers.remove(id);
    notifyListeners();
  }

  /// Clear all messages
  void clearMessages() {
    _messages.clear();
    _persistMessages();
    notifyListeners();
  }

  /// Clear all SAR markers
  void clearSarMarkers() {
    _sarMarkers.clear();
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _messages.clear();
    _sarMarkers.clear();
    _persistMessages();
    notifyListeners();
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    return await _storageService.getStorageStats();
  }

  /// Get message statistics
  Map<String, int> get messageStats {
    return {
      'total': _messages.length,
      'contact': contactMessages.length,
      'channel': channelMessages.length,
      'sar': sarMarkerMessages.length,
      'sarMarkers': sarMarkers.length,
    };
  }

  /// Get SAR marker statistics
  Map<String, int> get sarMarkerStats {
    return {
      'total': sarMarkers.length,
      'foundPerson': foundPersonMarkers.length,
      'fire': fireMarkers.length,
      'stagingArea': stagingAreaMarkers.length,
      'object': objectMarkers.length,
    };
  }

  /// Add a sent message with initial status
  void addSentMessage(Message message) {
    // Always enhance message with SAR parser to detect SAR markers
    final enhancedMessage = SarMessageParser.enhanceMessage(message);

    // Check for duplicates (shouldn't happen for sent messages, but be safe)
    if (_isDuplicate(enhancedMessage)) {
      print('⚠️ [MessagesProvider] Duplicate sent message detected, skipping: ${enhancedMessage.id}');
      return;
    }

    // Add message with sending status
    final sendingMessage = enhancedMessage.copyWith(
      deliveryStatus: MessageDeliveryStatus.sending,
    );
    _messages.add(sendingMessage);

    // If it's a SAR marker message, extract and store the marker
    if (sendingMessage.isSarMarker) {
      final marker = sendingMessage.toSarMarker();
      if (marker != null) {
        _sarMarkers[marker.id] = marker;
      }
    }

    _persistMessages();
    notifyListeners();
  }

  /// Update message status to sent with ACK tag
  void markMessageSent(String messageId, int expectedAckTag, int suggestedTimeoutMs) {
    print('📤 [MessagesProvider] markMessageSent called');
    print('  Message ID: $messageId');
    print('  Expected ACK tag: $expectedAckTag');
    print('  Timeout: ${suggestedTimeoutMs}ms');

    final index = _messages.indexWhere((m) => m.id == messageId);
    print('  Message index in list: $index');

    if (index != -1) {
      final message = _messages[index];
      print('  Current status: ${message.deliveryStatus}');

      final updatedMessage = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.sent,
        expectedAckTag: expectedAckTag,
        suggestedTimeoutMs: suggestedTimeoutMs,
      );
      _messages[index] = updatedMessage;

      // Track by ACK tag for matching with delivery confirmation
      _pendingSentMessages[expectedAckTag] = updatedMessage;
      print('  Added to pending messages map with ACK: $expectedAckTag');
      print('  Total pending messages: ${_pendingSentMessages.length}');

      // Start timeout timer
      _timeoutTimers[expectedAckTag] = Timer(
        Duration(milliseconds: suggestedTimeoutMs),
        () {
          print('⏱️ [MessagesProvider] Timeout for message $messageId (ACK $expectedAckTag)');
          if (_pendingSentMessages.containsKey(expectedAckTag)) {
            markMessageFailed(messageId);
          }
        },
      );

      print('⏱️ [MessagesProvider] Started ${suggestedTimeoutMs}ms timeout timer for message $messageId (ACK $expectedAckTag)');

      _persistMessages();
      notifyListeners();
    } else {
      print('⚠️ [MessagesProvider] Message not found in list: $messageId');
    }
  }

  /// Update message status to delivered with RTT
  void markMessageDelivered(int ackCode, int roundTripTimeMs) {
    print('🔍 [MessagesProvider] markMessageDelivered called with ACK: $ackCode, RTT: ${roundTripTimeMs}ms');
    print('  Current pending messages: ${_pendingSentMessages.keys.toList()}');
    print('  Looking for ACK: $ackCode');

    // Find message by ACK code
    final message = _pendingSentMessages[ackCode];
    if (message != null) {
      print('  ✅ Found message: ${message.id}');
      final index = _messages.indexWhere((m) => m.id == message.id);
      print('  Message index in list: $index');

      if (index != -1) {
        final updatedMessage = message.copyWith(
          deliveryStatus: MessageDeliveryStatus.delivered,
          roundTripTimeMs: roundTripTimeMs,
          deliveredAt: DateTime.now(),
        );
        _messages[index] = updatedMessage;

        // Cancel timeout timer
        _timeoutTimers[ackCode]?.cancel();
        _timeoutTimers.remove(ackCode);

        // Remove from pending
        _pendingSentMessages.remove(ackCode);

        print('✅ [MessagesProvider] Message ${message.id} delivered in ${roundTripTimeMs}ms (ACK $ackCode)');
        print('  Calling notifyListeners() to update UI');

        _persistMessages();
        notifyListeners();
      } else {
        print('⚠️ [MessagesProvider] Message not found in list (index=-1)');
      }
    } else {
      print('⚠️ [MessagesProvider] No pending message found for ACK code: $ackCode');
      print('  This means either:');
      print('  1. markMessageSent() was never called for this message');
      print('  2. The ACK code doesn\'t match the expected ACK tag from RESP_CODE_SENT');
      print('  3. The message was already delivered or timed out');
    }
  }

  /// Update message status to failed
  void markMessageFailed(String messageId) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final message = _messages[index];
      final updatedMessage = message.copyWith(
        deliveryStatus: MessageDeliveryStatus.failed,
      );
      _messages[index] = updatedMessage;

      // Cancel timeout timer if it exists
      if (message.expectedAckTag != null) {
        _timeoutTimers[message.expectedAckTag]?.cancel();
        _timeoutTimers.remove(message.expectedAckTag);
        _pendingSentMessages.remove(message.expectedAckTag);
      }

      print('❌ [MessagesProvider] Message $messageId marked as failed');

      _persistMessages();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all pending timeout timers
    for (final timer in _timeoutTimers.values) {
      timer.cancel();
    }
    _timeoutTimers.clear();
    super.dispose();
  }
}
