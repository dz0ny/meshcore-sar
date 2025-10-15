# Messaging Improvements Implementation Summary

## Date: 2025-01-14

## Overview

This document summarizes the messaging improvements implemented based on the gap analysis in `MESSAGE_SEND_RECEIVE_GAP_ANALYSIS.md`.

## Gap Analysis Results

### Gap #1: Direct Messages UI
**Status**: ✅ ALREADY IMPLEMENTED
- **Location**: `lib/screens/contacts_tab.dart:351-937`
- Direct message UI exists via Contacts tab
- Users can tap message icon on chat contacts to open direct message sheet
- `_DirectMessageSheet` widget provides full message composition UI
- Messages are sent with delivery tracking via `sendTextMessage()`

### Gap #2: Timeout Handling
**Status**: ✅ NEWLY IMPLEMENTED
- **Files Modified**:
  - `lib/providers/messages_provider.dart`

#### Implementation Details

**1. Added Timer Infrastructure** (lines 1, 19):
```dart
import 'dart:async';

// Track timeout timers for pending messages
final Map<int, Timer> _timeoutTimers = {};
```

**2. Start Timeout on Message Sent** (lines 280-291):
```dart
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
```

**3. Cancel Timeout on Delivery** (lines 312-314):
```dart
// Cancel timeout timer
_timeoutTimers[ackCode]?.cancel();
_timeoutTimers.remove(ackCode);
```

**4. Cancel Timeout on Manual Failure** (lines 338-341):
```dart
// Cancel timeout timer if it exists
if (message.expectedAckTag != null) {
  _timeoutTimers[message.expectedAckTag]?.cancel();
  _timeoutTimers.remove(message.expectedAckTag);
  _pendingSentMessages.remove(message.expectedAckTag);
}
```

**5. Clean Up on Dispose** (lines 351-359):
```dart
@override
void dispose() {
  // Cancel all pending timeout timers
  for (final timer in _timeoutTimers.values) {
    timer.cancel();
  }
  _timeoutTimers.clear();
  super.dispose();
}
```

### Gap #3: Retry Logic
**Status**: ✅ NEWLY IMPLEMENTED
- **Files Modified**:
  - `lib/screens/messages_tab.dart`
  - `lib/providers/connection_provider.dart`

#### Implementation Details

**1. Retry Button UI** (lines 570-597 in messages_tab.dart):
```dart
// Show retry button for failed messages
if (message.deliveryStatus == MessageDeliveryStatus.failed) ...[
  const SizedBox(width: 8),
  GestureDetector(
    onTap: () => _retryFailedMessage(context, message),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'Retry',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    ),
  ),
],
```

**2. Retry Logic** (lines 400-479 in messages_tab.dart):
```dart
Future<void> _retryFailedMessage(BuildContext context, Message failedMessage) async {
  // Check connection
  if (!connectionProvider.deviceInfo.isConnected) {
    // Show error
    return;
  }

  // Check if max attempts reached (protocol supports 0-3, so 4 total attempts)
  final currentAttempt = failedMessage.attemptNumber ?? 0;
  if (currentAttempt >= 3) {
    // Show max attempts reached error
    return;
  }

  final nextAttempt = currentAttempt + 1;
  final retryMessageId = '${failedMessage.id}_retry_$nextAttempt';

  // Create retry message with updated attempt number
  final retryMessage = failedMessage.copyWith(
    id: retryMessageId,
    deliveryStatus: MessageDeliveryStatus.sending,
    attemptNumber: nextAttempt,
    sentAt: DateTime.now(),
  );

  messagesProvider.addSentMessage(retryMessage);

  // Resend the message
  if (failedMessage.messageType == MessageType.channel) {
    await connectionProvider.sendChannelMessage(
      channelIdx: failedMessage.channelIdx ?? 0,
      text: failedMessage.text,
      messageId: retryMessageId,
      attempt: nextAttempt,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Retrying message (attempt ${nextAttempt + 1}/4)...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
```

**3. Added Attempt Parameter to Connection Provider** (lines 400-468 in connection_provider.dart):

Updated `sendTextMessage()`:
```dart
Future<bool> sendTextMessage({
  required Uint8List contactPublicKey,
  required String text,
  String? messageId,
  int attempt = 0,  // NEW: retry attempt number (0-3)
}) async {
  await _bleService.sendTextMessage(
    contactPublicKey: contactPublicKey,
    text: text,
    attempt: attempt,  // NEW: pass to BLE service
  );

  if (messageId != null) {
    _pendingSentMessageIds.add(messageId);
    print('  Added message ID to pending queue: $messageId (attempt $attempt)');
  }
}
```

Updated `sendChannelMessage()`:
```dart
Future<void> sendChannelMessage({
  required int channelIdx,
  required String text,
  String? messageId,  // NEW: track delivery
  int attempt = 0,     // NEW: retry attempt number (0-3)
}) async {
  await _bleService.sendChannelMessage(
    channelIdx: channelIdx,
    text: text,
    attempt: attempt,  // NEW: pass to BLE service
  );

  // NEW: Track message ID for delivery confirmation
  if (messageId != null) {
    _pendingSentMessageIds.add(messageId);
    print('  Added message ID to pending queue: $messageId (attempt $attempt)');
  }
}
```

## How It Works

### Timeout Flow

1. User sends message → `addSentMessage()` called with `sending` status
2. BLE service sends message → receives `RESP_CODE_SENT` (code 6)
3. `markMessageSent()` called with ACK tag and timeout value
4. Timer started for specified timeout (e.g., 30000ms)
5. Two possible outcomes:
   - **Success**: `PUSH_CODE_SEND_CONFIRMED` (0x82) arrives → `markMessageDelivered()` cancels timer → message marked `delivered`
   - **Timeout**: Timer expires → message automatically marked `failed`

### Retry Flow

1. Message times out or fails → UI shows red "Failed" status with orange "Retry" button
2. User taps "Retry" button
3. Check attempt number (must be < 3, since protocol supports 0-3 = 4 total attempts)
4. Create new message with:
   - New message ID: `{original_id}_retry_{attempt}`
   - Status: `sending`
   - Attempt number: `currentAttempt + 1`
5. Send message with new attempt number via BLE
6. New timeout timer started automatically
7. Process repeats until delivered or max attempts reached

## Protocol Compliance

All implementations follow the MeshCore BLE Companion Radio protocol:

- **Timeout values**: Use `suggestedTimeoutMs` from `RESP_CODE_SENT` (code 6)
- **Attempt numbers**: Range 0-3 (4 total attempts) as specified in protocol
- **Message tracking**: Use expected ACK tag from `RESP_CODE_SENT` to match with `PUSH_CODE_SEND_CONFIRMED` (0x82)
- **Delivery confirmation**: Round-trip time (RTT) stored from delivery confirmation

## Testing Checklist

### Timeout Handling
- [ ] Send message to unreachable contact
- [ ] Verify message shows "Sent" status initially
- [ ] Wait for timeout period (e.g., 30 seconds)
- [ ] Verify message automatically changes to "Failed" status
- [ ] Check logs for timeout message: `⏱️ [MessagesProvider] Timeout for message...`

### Retry Logic
- [ ] Cause a message to fail (send to non-existent contact or wait for timeout)
- [ ] Verify "Failed" status shows with orange "Retry" button
- [ ] Tap "Retry" button
- [ ] Verify new message appears with "Sending" status
- [ ] Verify snackbar shows "Retrying message (attempt 2/4)..."
- [ ] Repeat retry up to 4 total attempts
- [ ] On 4th attempt, verify "Retry" button disappears
- [ ] Attempt to retry again, verify error: "Maximum retry attempts reached"

### Delivery Success
- [ ] Send message to reachable contact
- [ ] Verify message shows "Sent" status
- [ ] Wait for delivery confirmation
- [ ] Verify message changes to "Delivered" status with green checkmarks
- [ ] Verify timeout timer was cancelled (no failure after timeout period)
- [ ] Check logs for delivery message: `✅ [MessagesProvider] Message {id} delivered in {ms}ms`

## Known Limitations

1. **Direct Message Retry**: Not yet implemented
   - Retry button works only for channel messages
   - Direct message retry would require looking up contact's full public key
   - Shows "Direct message retry not yet implemented" message

2. **Automatic Retry**: Not implemented
   - User must manually tap "Retry" button
   - Future enhancement could add automatic retry with exponential backoff

3. **Retry Deduplication**: Messages show as separate entries
   - Each retry creates a new message in the history
   - Future enhancement could group retries under original message

## Files Changed

1. **lib/providers/messages_provider.dart**
   - Added `dart:async` import
   - Added `_timeoutTimers` map
   - Modified `markMessageSent()` to start timers
   - Modified `markMessageDelivered()` to cancel timers
   - Modified `markMessageFailed()` to cancel timers
   - Added `dispose()` method to clean up timers

2. **lib/providers/connection_provider.dart**
   - Modified `sendTextMessage()` to accept `attempt` parameter
   - Modified `sendChannelMessage()` to accept `messageId` and `attempt` parameters
   - Both methods now track message IDs for delivery confirmation

3. **lib/screens/messages_tab.dart**
   - Added retry button UI to `_MessageBubble` widget
   - Added `_retryFailedMessage()` method
   - Retry UI appears only for failed messages
   - Shows attempt count (e.g., "attempt 2/4")

## Performance Impact

- **Memory**: Minimal - one Timer object per pending message
- **CPU**: Negligible - timers use OS-level scheduling
- **Network**: No change - only affects local message state management

## Future Enhancements

1. **Automatic Retry with Backoff**
   - Implement exponential backoff (e.g., 5s, 10s, 20s, 40s)
   - Configurable via settings

2. **Retry Grouping**
   - Group retry attempts under original message
   - Show retry history in message details

3. **Direct Message Retry**
   - Add contact lookup by public key prefix
   - Implement retry for direct messages

4. **Smart Timeout Adjustment**
   - Learn from network conditions
   - Adjust timeout based on historical RTT

5. **Batch Retry**
   - "Retry All Failed" button
   - Retry multiple failed messages at once

## Conclusion

The messaging system now has robust timeout handling and manual retry capabilities for channel messages. Messages automatically fail after the protocol-specified timeout period, and users can retry failed messages up to 4 times as allowed by the MeshCore protocol.

Direct messages can already be sent via the Contacts tab, so Gap #1 was already addressed. Gaps #2 and #3 are now fully implemented and ready for testing.
