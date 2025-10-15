# MeshCore Messaging System - Complete Implementation Guide

This document provides complete technical specifications for implementing messaging in MeshCore applications.

## Table of Contents

1. [Message Types and Architecture](#1-message-types-and-architecture)
2. [Sending Messages](#2-sending-messages)
3. [Receiving Messages](#3-receiving-messages)
4. [Message Confirmation and ACKs](#4-message-confirmation-and-acks)
5. [Room vs Channel System](#5-room-vs-channel-system)
6. [Binary Protocol Specifications](#6-binary-protocol-specifications)
7. [Implementation Checklist](#7-implementation-checklist)
8. [Common Pitfalls](#8-common-pitfalls)
9. [Testing and Validation](#9-testing-and-validation)

---

## 1. Message Types and Architecture

### 1.1 Payload Types

MeshCore defines several payload types for different message purposes:

```cpp
#define PAYLOAD_TYPE_ADVERT       0x01  // Advertisement packet
#define PAYLOAD_TYPE_PATH         0x02  // Path return packet
#define PAYLOAD_TYPE_TXT_MSG      0x03  // Text message (DM or channel)
#define PAYLOAD_TYPE_DATA         0x04  // Binary data
#define PAYLOAD_TYPE_REQUEST      0x05  // Binary request (telemetry, status)
#define PAYLOAD_TYPE_RESPONSE     0x06  // Binary response
#define PAYLOAD_TYPE_ACK          0x07  // Acknowledgment
#define PAYLOAD_TYPE_TRACE        0x08  // Path trace packet
#define PAYLOAD_TYPE_RAW_CUSTOM   0x09  // Raw custom data
```

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/src/MeshCore.h`, lines 27-35

### 1.2 Text Message Types

Text messages (PAYLOAD_TYPE_TXT_MSG) have subtypes:

```cpp
#define TXT_TYPE_PLAIN         0x00  // Plain text message
#define TXT_TYPE_CLI_DATA      0x01  // CLI command
#define TXT_TYPE_SIGNED_PLAIN  0x02  // Plain text, cryptographically signed
```

**Usage**:
- **TXT_TYPE_PLAIN**: Standard chat messages, SAR markers
- **TXT_TYPE_CLI_DATA**: Remote administration commands (requires admin permissions)
- **TXT_TYPE_SIGNED_PLAIN**: Future use for message authentication

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/src/MeshCore.h`, lines 37-39

### 1.3 Message Length Limits

**Direct Messages** (CMD_SEND_TXT_MSG):
```
Maximum: 160 bytes of UTF-8 text
```

**Channel Messages** (CMD_SEND_CHANNEL_TXT_MSG):
```
Maximum: 160 - len(sender_name) - 2 bytes
Example: If sender name is "John", max is 160 - 4 - 2 = 154 bytes
```

**Why the difference?**
- Channel messages include sender name in the packet payload
- Direct messages use public key for identification (name stored in contacts)

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, CMD_SEND_TXT_MSG and CMD_SEND_CHANNEL_TXT_MSG sections

### 1.4 Message Storage and Queuing

**On Companion Device**:
- Received messages stored in circular buffer (platform-specific size, typically 50-100 messages)
- Messages persist until fetched via `CMD_SYNC_NEXT_MESSAGE`
- Oldest messages overwritten when buffer is full

**In Rooms**:
- Messages stored persistently in flash memory
- Immutable storage (cannot be deleted)
- Room server pushes messages to logged-in clients automatically
- Messages ordered by timestamp

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_repeater/MyMesh.cpp`, lines 498-542

---

## 2. Sending Messages

### 2.1 CMD_SEND_TXT_MSG (Code 2) - Direct Message

Send a direct message to a specific contact using their public key.

#### Binary Frame Format

```
[Command Code: 1 byte] = 0x02
[Text Type: 1 byte] = TXT_TYPE_* (0=plain, 1=CLI, 2=signed)
[Attempt: 1 byte] = 0-3 (retry attempt number, 0 for first send)
[Sender Timestamp: 4 bytes] = uint32, Little Endian, epoch seconds
[Recipient Public Key Prefix: 6 bytes] = First 6 bytes of recipient's public key
[Text: N bytes] = UTF-8 encoded text, max 160 bytes
```

**Total frame size**: 12 + text_length bytes

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, CMD_SEND_TXT_MSG section

#### Implementation Example

```dart
Future<void> sendTextMessage(String recipientPublicKey, String text) async {
  // Validate inputs
  if (text.length > 160) {
    throw Exception('Message exceeds 160 byte limit');
  }

  // Convert hex public key to bytes
  final pubKeyBytes = hex.decode(recipientPublicKey);
  if (pubKeyBytes.length != 32) {
    throw Exception('Invalid public key length');
  }

  // Build frame
  final writer = BufferWriter();
  writer.writeByte(2); // CMD_SEND_TXT_MSG
  writer.writeByte(0); // TXT_TYPE_PLAIN
  writer.writeByte(0); // Attempt 0 (first send)
  writer.writeUint32(DateTime.now().millisecondsSinceEpoch ~/ 1000); // Timestamp
  writer.writeBytes(pubKeyBytes.sublist(0, 6)); // First 6 bytes of public key
  writer.writeString(text); // UTF-8 text

  await _sendCommand(writer.toBytes());
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 380-397

#### Response: RESP_CODE_SENT (Code 6)

The device responds immediately with transmission details:

```
[Response Code: 1 byte] = 0x06
[Send Type: 1 byte] = 0=direct route, 1=flood mode
[Expected ACK/TAG: 4 bytes] = uint32, Little Endian, code to expect in PUSH_CODE_SEND_CONFIRMED
[Suggested Timeout: 4 bytes] = uint32, Little Endian, milliseconds to wait for ACK
```

**Usage**:
- Store `expected_ack_or_tag` to match with future `PUSH_CODE_SEND_CONFIRMED`
- Start timer using `suggested_timeout_ms` (typically 10000-30000ms)
- If timeout expires without confirmation, consider message failed

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, RESP_CODE_SENT section

### 2.2 CMD_SEND_CHANNEL_TXT_MSG (Code 3) - Broadcast Message

Send a message to all nodes in flood mode (public channel).

#### Binary Frame Format

```
[Command Code: 1 byte] = 0x03
[Text Type: 1 byte] = TXT_TYPE_* (0=plain, 1=CLI, 2=signed)
[Channel Index: 1 byte] = Reserved, always 0 for "public channel"
[Sender Timestamp: 4 bytes] = uint32, Little Endian, epoch seconds
[Text: N bytes] = UTF-8 encoded text, max (160 - len(advert_name) - 2) bytes
```

**Total frame size**: 7 + text_length bytes

**Important**: Channel messages are **ephemeral** - they are NOT stored anywhere. Once broadcast over the air, they're gone.

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, CMD_SEND_CHANNEL_TXT_MSG section

#### Implementation Example

```dart
Future<void> sendChannelMessage(String text) async {
  // Calculate max length based on device name
  final maxLength = 160 - (_deviceName?.length ?? 0) - 2;
  if (text.length > maxLength) {
    throw Exception('Message exceeds $maxLength byte limit');
  }

  final writer = BufferWriter();
  writer.writeByte(3); // CMD_SEND_CHANNEL_TXT_MSG
  writer.writeByte(0); // TXT_TYPE_PLAIN
  writer.writeByte(0); // Channel index 0 (public)
  writer.writeUint32(DateTime.now().millisecondsSinceEpoch ~/ 1000); // Timestamp
  writer.writeString(text); // UTF-8 text

  await _sendCommand(writer.toBytes());
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 399-414

### 2.3 Retry Logic

**Manual Retries** (for direct messages):

```dart
Future<void> sendWithRetry(String recipientPubKey, String text) async {
  for (int attempt = 0; attempt < 4; attempt++) {
    try {
      // Modify sendTextMessage to accept attempt parameter
      await sendTextMessage(recipientPubKey, text, attempt: attempt);

      // Wait for ACK or timeout
      final confirmed = await waitForConfirmation(timeout: Duration(seconds: 30));
      if (confirmed) return; // Success

      print('Attempt $attempt failed, retrying...');
    } catch (e) {
      print('Send failed: $e');
    }

    // Exponential backoff
    await Future.delayed(Duration(seconds: 2 << attempt));
  }

  throw Exception('Message failed after 4 attempts');
}
```

**Automatic Retries in MeshCore**:
- The radio layer automatically retries direct messages up to 3 times
- Each retry uses exponentially increasing delay
- Last retry attempt uses flood mode as fallback

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/src/Mesh.cpp`, lines 598-652

---

## 3. Receiving Messages

### 3.1 Message Reception Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Message arrives at device via LoRa                       │
│    (from direct message or channel broadcast)               │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Device stores message in internal queue                  │
│    (circular buffer, typically 50-100 messages)             │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Device sends PUSH_CODE_MSG_WAITING (0x83)                │
│    to connected app via BLE                                 │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. App calls CMD_SYNC_NEXT_MESSAGE (10)                     │
│    to fetch the message                                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Device responds with RESP_CODE_CONTACT_MSG_RECV (7)      │
│    or RESP_CODE_CHANNEL_MSG_RECV (8)                        │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. App parses message and displays to user                  │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ 7. Repeat steps 4-6 until RESP_CODE_NO_MORE_MESSAGES (10)   │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 PUSH_CODE_MSG_WAITING (0x83) - New Message Notification

When a new message arrives, the device sends this asynchronous push notification:

```
[Push Code: 1 byte] = 0x83
```

**No additional data** - this is just a notification to call `CMD_SYNC_NEXT_MESSAGE`.

**Implementation**:

```dart
void _handlePushNotification(int pushCode, Uint8List data) {
  switch (pushCode) {
    case 0x83: // PUSH_CODE_MSG_WAITING
      print('📥 New message waiting');
      onMessageWaiting?.call(); // Trigger callback
      break;
    // ... other push codes
  }
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 231-234

### 3.3 CMD_SYNC_NEXT_MESSAGE (Code 10) - Fetch Next Message

Pull the next message from the device's queue:

```
[Command Code: 1 byte] = 0x0A (10)
```

**No parameters** - just send the command code.

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, CMD_SYNC_NEXT_MESSAGE section

#### Implementation Example

```dart
Future<void> syncNextMessage() async {
  final writer = BufferWriter();
  writer.writeByte(10); // CMD_SYNC_NEXT_MESSAGE
  await _sendCommand(writer.toBytes());
}

// Fetch all pending messages
Future<void> syncAllMessages() async {
  while (true) {
    await syncNextMessage();
    // Wait for response (RESP_CODE_CONTACT_MSG_RECV, RESP_CODE_CHANNEL_MSG_RECV, or RESP_CODE_NO_MORE_MESSAGES)
    // If NO_MORE_MESSAGES received, break loop
    await Future.delayed(Duration(milliseconds: 100)); // Brief delay between fetches
  }
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 416-420

### 3.4 RESP_CODE_CONTACT_MSG_RECV (Code 7) - Direct Message

Response containing a direct message from a contact:

```
[Response Code: 1 byte] = 0x07
[Sender Public Key Prefix: 6 bytes] = First 6 bytes of sender's public key
[Path Length: 1 byte] = 0xFF if direct path, else hop count for flood-mode
[Text Type: 1 byte] = TXT_TYPE_* (0=plain, 1=CLI, 2=signed)
[Sender Timestamp: 4 bytes] = uint32, Little Endian, epoch seconds
[Text: N bytes] = UTF-8 encoded text (remainder of frame)
```

**Parsing Example**:

```dart
void _handleContactMessage(BufferReader reader) {
  final senderPubKeyPrefix = reader.readBytes(6); // First 6 bytes of sender's key
  final pathLen = reader.readByte();
  final textType = reader.readByte();
  final timestamp = reader.readUint32();
  final text = reader.readString(); // Read remainder as UTF-8

  // Find full contact by matching public key prefix
  final contact = contacts.firstWhere(
    (c) => c.publicKey.startsWith(hex.encode(senderPubKeyPrefix)),
    orElse: () => null,
  );

  // Create message object
  final message = Message(
    senderPublicKey: contact?.publicKey ?? hex.encode(senderPubKeyPrefix),
    senderName: contact?.name ?? 'Unknown',
    text: text,
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    isDirect: true,
    pathLength: pathLen == 0xFF ? null : pathLen,
    textType: textType,
  );

  onMessageReceived?.call(message);
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 280-301

### 3.5 RESP_CODE_CHANNEL_MSG_RECV (Code 8) - Channel Message

Response containing a channel/broadcast message:

```
[Response Code: 1 byte] = 0x08
[Channel Index: 1 byte] = Reserved, 0 for "public channel"
[Path Length: 1 byte] = 0xFF if direct, else hop count
[Text Type: 1 byte] = TXT_TYPE_* (0=plain, 1=CLI, 2=signed)
[Sender Timestamp: 4 bytes] = uint32, Little Endian, epoch seconds
[Text: N bytes] = UTF-8 encoded text (remainder of frame)
```

**Key Difference from Contact Messages**:
- **No sender public key prefix** - instead, sender name is embedded in the text
- Text format: `"<sender_name>: <actual_message>"`
- Channel index currently unused (always 0)

**Parsing Example**:

```dart
void _handleChannelMessage(BufferReader reader) {
  final channelIndex = reader.readByte();
  final pathLen = reader.readByte();
  final textType = reader.readByte();
  final timestamp = reader.readUint32();
  final text = reader.readString();

  // Parse sender name from text (format: "Name: Message")
  String senderName = 'Unknown';
  String actualMessage = text;

  if (text.contains(': ')) {
    final parts = text.split(': ');
    senderName = parts[0];
    actualMessage = parts.sublist(1).join(': '); // Handle multiple colons
  }

  final message = Message(
    senderPublicKey: null, // Unknown for channel messages
    senderName: senderName,
    text: actualMessage,
    timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp * 1000),
    isDirect: false,
    channelIndex: channelIndex,
    pathLength: pathLen == 0xFF ? null : pathLen,
    textType: textType,
  );

  onMessageReceived?.call(message);
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 303-321

### 3.6 RESP_CODE_NO_MORE_MESSAGES (Code 10) - Queue Empty

Indicates no more messages are in the queue:

```
[Response Code: 1 byte] = 0x0A (10)
```

**No additional data**.

**Implementation**:

```dart
void _handleNoMoreMessages() {
  print('✅ All messages synced');
  _isSyncing = false; // Stop sync loop
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, RESP_CODE_NO_MORE_MESSAGES section

---

## 4. Message Confirmation and ACKs

### 4.1 PUSH_CODE_SEND_CONFIRMED (0x82) - Delivery Confirmation

When a message is acknowledged by the recipient, the device sends this push notification:

```
[Push Code: 1 byte] = 0x82
[ACK Code: 4 bytes] = uint32, Little Endian, matches expected_ack_or_tag from RESP_CODE_SENT
[Round Trip Time: 4 bytes] = uint32, Little Endian, milliseconds
```

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, PUSH_CODE_SEND_CONFIRMED section

### 4.2 ACK Tracking Implementation

```dart
class PendingMessage {
  final String messageId; // Generate unique ID
  final int expectedAck; // From RESP_CODE_SENT
  final DateTime sentAt;
  final int timeoutMs;

  PendingMessage({
    required this.messageId,
    required this.expectedAck,
    required this.sentAt,
    required this.timeoutMs,
  });

  bool isExpired() {
    return DateTime.now().difference(sentAt).inMilliseconds > timeoutMs;
  }
}

// Track pending messages
Map<int, PendingMessage> _pendingMessages = {};

// When sending message
void _handleSentResponse(BufferReader reader) {
  final sendType = reader.readByte(); // 0=direct, 1=flood
  final expectedAck = reader.readUint32();
  final timeoutMs = reader.readUint32();

  final pending = PendingMessage(
    messageId: generateMessageId(),
    expectedAck: expectedAck,
    sentAt: DateTime.now(),
    timeoutMs: timeoutMs,
  );

  _pendingMessages[expectedAck] = pending;

  // Start timeout timer
  Future.delayed(Duration(milliseconds: timeoutMs), () {
    if (_pendingMessages.containsKey(expectedAck)) {
      print('⚠️ Message timeout: ACK $expectedAck not received');
      _pendingMessages.remove(expectedAck);
      onMessageFailed?.call(pending.messageId);
    }
  });
}

// When receiving confirmation
void _handleSendConfirmed(BufferReader reader) {
  final ackCode = reader.readUint32();
  final rtt = reader.readUint32();

  final pending = _pendingMessages.remove(ackCode);
  if (pending != null) {
    print('✅ Message confirmed: RTT ${rtt}ms');
    onMessageConfirmed?.call(pending.messageId, rtt);
  }
}
```

**Reference**: Implementation pattern derived from `/Users/dz0ny/meshcore-sar/MeshCore/src/Mesh.cpp`, lines 598-652

### 4.3 Timeout Handling

**Recommended Strategy**:

1. **First attempt**: Send with `attempt=0`, wait for suggested timeout
2. **If timeout expires**: Send with `attempt=1`, wait 2× timeout
3. **If timeout expires**: Send with `attempt=2`, wait 4× timeout
4. **If timeout expires**: Send with `attempt=3` (last attempt uses flood mode)
5. **If timeout expires**: Mark message as failed

**UI Feedback**:
- Show "Sending..." while waiting for ACK
- Show "Delivered" with RTT when confirmed
- Show "Failed" if all retries timeout
- Show "Sent" for channel messages (no ACK expected)

---

## 5. Room vs Channel System

### 5.1 Key Differences

| Feature | Channels (Flood Mode) | Rooms (ADV_TYPE_ROOM) |
|---------|----------------------|------------------------|
| **Persistence** | ❌ Ephemeral (over-the-air only) | ✅ Persistent (stored in flash) |
| **Mutability** | N/A | ❌ Immutable (cannot delete) |
| **Authentication** | ❌ No login required | ✅ Password-protected login |
| **Message Sync** | ❌ No sync (broadcast only) | ✅ Full history sync |
| **Delivery** | ⚠️ Best-effort broadcast | ✅ Guaranteed delivery to logged-in clients |
| **Use Case** | General announcements | Mission-critical logs, SAR markers |
| **Command** | CMD_SEND_CHANNEL_TXT_MSG | CMD_SEND_TXT_MSG (to room's pub key) |
| **Channel Index** | Numeric (0=public) | Named contact (has public key) |

**CRITICAL FOR SAR OPERATIONS**:
- **Always send SAR markers to rooms** (not public channel)
- Rooms provide immutable audit trail
- Rooms ensure messages are delivered even if recipient is offline

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_repeater/MyMesh.cpp`, lines 498-542

### 5.2 Room Login Protocol (CRITICAL)

#### Step 1: Send Login Request

```
[Command Code: 1 byte] = 0x1A (26, CMD_SEND_LOGIN)
[Sender Timestamp: 4 bytes] = uint32, Little Endian, epoch seconds
[Sync Since: 4 bytes] = uint32, Little Endian, epoch seconds (0 for all messages)
[Room Public Key: 32 bytes] = Full 32-byte public key of room
[Password: N bytes] = UTF-8 string, max 15 bytes, null-terminated
```

**IMPORTANT**: Room login uses **full 32-byte public key**, not 6-byte prefix!

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, CMD_SEND_LOGIN section

#### Implementation Example

```dart
Future<void> loginToRoom(String roomPublicKey, String password, {int syncSince = 0}) async {
  final pubKeyBytes = hex.decode(roomPublicKey);
  if (pubKeyBytes.length != 32) {
    throw Exception('Room login requires full 32-byte public key');
  }

  final writer = BufferWriter();
  writer.writeByte(26); // CMD_SEND_LOGIN
  writer.writeUint32(DateTime.now().millisecondsSinceEpoch ~/ 1000); // Sender timestamp
  writer.writeUint32(syncSince); // Sync since (0 for all messages)
  writer.writeBytes(pubKeyBytes); // Full 32-byte public key
  writer.writeString(password); // Password (max 15 bytes)

  await _sendCommand(writer.toBytes());
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 422-437

#### Step 2: Handle Login Response

**Success**: `PUSH_CODE_LOGIN_SUCCESS` (0x85)

```
[Push Code: 1 byte] = 0x85
[Permissions: 1 byte] = Lowest bit = is_admin (0=guest, 1=admin)
[Public Key Prefix: 6 bytes] = First 6 bytes of room's public key
[Tag: 4 bytes] = int32, Little Endian (for advanced use)
[New Permissions: 1 byte] = (Firmware v7+) Updated permission flags
```

**Failure**: `PUSH_CODE_LOGIN_FAIL` (0x86)

```
[Push Code: 1 byte] = 0x86
[Public Key Prefix: 6 bytes] = First 6 bytes of room's public key
```

**Implementation**:

```dart
void _handleLoginSuccess(BufferReader reader) {
  final permissions = reader.readByte();
  final roomPubKeyPrefix = reader.readBytes(6);
  final tag = reader.readInt32();
  final isAdmin = (permissions & 0x01) != 0;

  print('✅ Room login success: ${isAdmin ? "Admin" : "Guest"}');

  // Store login state
  _loggedInRooms[hex.encode(roomPubKeyPrefix)] = RoomLoginState(
    isLoggedIn: true,
    isAdmin: isAdmin,
    loginTime: DateTime.now(),
  );

  // DO NOT call syncAllMessages() here!
  // Wait for PUSH_CODE_MSG_WAITING notifications instead
}

void _handleLoginFail(BufferReader reader) {
  final roomPubKeyPrefix = reader.readBytes(6);
  print('❌ Room login failed: Invalid password');

  onRoomLoginFailed?.call(hex.encode(roomPubKeyPrefix));
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 236-259

#### Step 3: Automatic Message Push

**CRITICAL IMPLEMENTATION RULE**:

```
❌ DO NOT call syncAllMessages() immediately after PUSH_CODE_LOGIN_SUCCESS
✅ DO wait for PUSH_CODE_MSG_WAITING push notifications
```

**Why?**

The room server implementation has specific timing:

```cpp
// Room server code (MyMesh.cpp:324-346)
client->extra.room.sync_since = sender_sync_since; // Store sync point
// ... send login success response ...
next_push = futureMillis(PUSH_NOTIFY_DELAY_MILLIS); // 2000ms delay
```

**Room Server Push Loop** (lines 498-542):

1. Server waits 2000ms after login before first push
2. Every 1200ms (SYNC_PUSH_INTERVAL), server checks each logged-in client
3. For each client, finds next message where `post_timestamp > client->extra.room.sync_since`
4. Sends message directly to client via `PAYLOAD_TYPE_TXT_MSG`
5. Waits for ACK
6. Advances `client->extra.room.sync_since` to `post_timestamp`
7. Repeats until all messages where `timestamp > sync_since` are pushed

**Client Implementation**:

```dart
// When login succeeds
void _handleLoginSuccess(BufferReader reader) {
  // ... parse login response ...

  // DO NOT DO THIS:
  // syncAllMessages(); // ❌ WRONG - will get NO_MORE_MESSAGES too early

  // CORRECT: Just set state and wait for pushes
  _loggedInRooms[roomId] = RoomLoginState(isLoggedIn: true);
}

// When message waiting push arrives
void _handleMessageWaiting() {
  // ✅ CORRECT: Now fetch the message
  syncAllMessages();
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_repeater/MyMesh.cpp`, lines 324, 346, 498-542

### 5.3 Sending Messages to Rooms

**IMPORTANT**: Use `CMD_SEND_TXT_MSG` (direct message) with the room's **6-byte public key prefix**:

```dart
// Send SAR marker to room
Future<void> sendSarMarkerToRoom(String roomPublicKey, String sarMarker) async {
  // Use first 6 bytes of room's public key
  final pubKeyBytes = hex.decode(roomPublicKey);
  final pubKeyPrefix = pubKeyBytes.sublist(0, 6);

  final writer = BufferWriter();
  writer.writeByte(2); // CMD_SEND_TXT_MSG (direct message)
  writer.writeByte(0); // TXT_TYPE_PLAIN
  writer.writeByte(0); // Attempt 0
  writer.writeUint32(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  writer.writeBytes(pubKeyPrefix); // 6-byte prefix
  writer.writeString(sarMarker); // e.g., "S:🧑:46.0569,14.5058"

  await _sendCommand(writer.toBytes());
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/providers/connection_provider.dart`, lines 165-178

---

## 6. Binary Protocol Specifications

### 6.1 Data Types and Byte Order

**CRITICAL**: All multi-byte integers use **Little Endian** byte order!

```dart
// CORRECT Little Endian implementation
void writeUint32LE(int value) {
  buffer.add(value & 0xFF);         // Least significant byte first
  buffer.add((value >> 8) & 0xFF);
  buffer.add((value >> 16) & 0xFF);
  buffer.add((value >> 24) & 0xFF); // Most significant byte last
}

uint32 readUint32LE() {
  return buffer[offset] |           // LSB
         (buffer[offset+1] << 8) |
         (buffer[offset+2] << 16) |
         (buffer[offset+3] << 24);  // MSB
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`, Protocol Overview section

### 6.2 Public Key Handling

**Two different formats used**:

| Context | Size | Usage |
|---------|------|-------|
| **Login** | 32 bytes | Full public key (CMD_SEND_LOGIN) |
| **Messages** | 6 bytes | Public key prefix (CMD_SEND_TXT_MSG) |
| **Contacts** | 32 bytes | Full public key (RESP_CODE_CONTACT) |
| **Path Return** | 32 bytes | Full public key (internal protocol) |

**Why 6 bytes for messages?**
- Saves bandwidth (26 bytes per message)
- Collision probability: 1 in 281 trillion (2^48)
- Acceptable risk for contact lookup
- Full key stored in contacts table for validation

**Implementation**:

```dart
// Extract 6-byte prefix from full public key
Uint8List getPubKeyPrefix(String fullPubKey) {
  final bytes = hex.decode(fullPubKey);
  return Uint8List.fromList(bytes.sublist(0, 6));
}

// Find contact by 6-byte prefix
Contact? findContactByPrefix(Uint8List prefix) {
  final prefixHex = hex.encode(prefix);
  return contacts.firstWhere(
    (c) => c.publicKey.startsWith(prefixHex),
    orElse: () => null,
  );
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`, lines 380-397

### 6.3 String Encoding

**All text uses UTF-8 encoding**:

```dart
// Writing strings
void writeString(String text) {
  final bytes = utf8.encode(text);
  buffer.addAll(bytes);
  // Note: No null terminator for variable-length fields at end of frame
}

// Reading strings (remainder of frame)
String readString() {
  final bytes = buffer.sublist(offset); // Read all remaining bytes
  return utf8.decode(bytes);
}

// Reading null-terminated strings (fixed-size fields)
String readNullTerminatedString(int maxLength) {
  final bytes = buffer.sublist(offset, offset + maxLength);
  final nullIndex = bytes.indexOf(0);
  if (nullIndex != -1) {
    return utf8.decode(bytes.sublist(0, nullIndex));
  }
  return utf8.decode(bytes);
}
```

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/buffer_reader.dart`, lines 38-57

### 6.4 Complete Frame Examples

#### Example 1: Send "Hello" to contact

```
Hex dump:
02              // CMD_SEND_TXT_MSG
00              // TXT_TYPE_PLAIN
00              // Attempt 0
E8 76 67 67     // Timestamp: 1734567912 (Little Endian)
8B 33 F2 A1 4C D9  // Public key prefix (6 bytes)
48 65 6C 6C 6F  // "Hello" in UTF-8

Total: 18 bytes
```

#### Example 2: Send "Hi all" to public channel

```
Hex dump:
03              // CMD_SEND_CHANNEL_TXT_MSG
00              // TXT_TYPE_PLAIN
00              // Channel index 0
E8 76 67 67     // Timestamp: 1734567912 (Little Endian)
48 69 20 61 6C 6C  // "Hi all" in UTF-8

Total: 13 bytes
```

#### Example 3: Login to room

```
Hex dump:
1A              // CMD_SEND_LOGIN
E8 76 67 67     // Sender timestamp: 1734567912
00 00 00 00     // Sync since: 0 (all messages)
8B 33 F2 A1 4C D9 E7 22 B5 C1 3A 9F 12 45 67 89
AB CD EF 01 23 45 67 89 AB CD EF 01 23 45 67 89  // 32-byte room public key
70 61 73 73 77 6F 72 64 00  // "password\0" (null-terminated)

Total: 50 bytes
```

**Reference**: Frame formats documented in `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`

---

## 7. Implementation Checklist

### 7.1 Minimum Viable Implementation

- [x] **Send direct text messages** (CMD_SEND_TXT_MSG)
- [x] **Send channel messages** (CMD_SEND_CHANNEL_TXT_MSG)
- [x] **Receive push notification** (PUSH_CODE_MSG_WAITING)
- [x] **Fetch messages** (CMD_SYNC_NEXT_MESSAGE)
- [x] **Parse contact messages** (RESP_CODE_CONTACT_MSG_RECV)
- [x] **Parse channel messages** (RESP_CODE_CHANNEL_MSG_RECV)
- [x] **Handle queue empty** (RESP_CODE_NO_MORE_MESSAGES)
- [x] **Match messages to contacts** (using 6-byte public key prefix)

**Status**: ✅ Fully implemented in current Flutter app

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart`

### 7.2 Enhanced Implementation

- [ ] **Track pending messages** (map expected ACK codes)
- [ ] **Handle send confirmations** (PUSH_CODE_SEND_CONFIRMED)
- [ ] **Display delivery status** (Sending/Delivered/Failed UI)
- [ ] **Implement retry logic** (4 attempts with exponential backoff)
- [ ] **Show round-trip time** (from PUSH_CODE_SEND_CONFIRMED)
- [ ] **Message timeout handling** (use suggested timeout from RESP_CODE_SENT)

**Status**: ⚠️ Not yet implemented

### 7.3 Room Support

- [x] **Login to rooms** (CMD_SEND_LOGIN with 32-byte key)
- [x] **Handle login success** (PUSH_CODE_LOGIN_SUCCESS)
- [x] **Handle login failure** (PUSH_CODE_LOGIN_FAIL)
- [x] **Wait for automatic pushes** (do NOT sync immediately after login)
- [x] **Send messages to rooms** (CMD_SEND_TXT_MSG with 6-byte prefix)
- [ ] **Track room login state** (logged in, admin/guest, sync_since)
- [ ] **Re-login on reconnect** (rooms are per-session)

**Status**: ✅ Partially implemented, needs state tracking enhancement

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/providers/connection_provider.dart`, lines 158-182

### 7.4 SAR-Specific Requirements

- [x] **Parse SAR marker format** (`S:<emoji>:<lat>,<lon>`)
- [x] **Highlight SAR messages** (different UI treatment)
- [x] **Send SAR markers to rooms** (NOT to public channel)
- [ ] **Validate SAR marker delivery** (wait for ACK)
- [ ] **Audit trail export** (from room message history)

**Status**: ✅ SAR parsing implemented, ⚠️ routing needs enforcement

**Reference**: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/utils/sar_message_parser.dart`

---

## 8. Common Pitfalls

### 8.1 ❌ Using Wrong Public Key Size

**WRONG**:
```dart
// Sending message with full 32-byte key
writer.writeBytes(hex.decode(recipientPublicKey)); // 32 bytes - WRONG!
```

**CORRECT**:
```dart
// Sending message with 6-byte prefix
final pubKey = hex.decode(recipientPublicKey);
writer.writeBytes(pubKey.sublist(0, 6)); // 6 bytes - CORRECT
```

**Exception**: Room login requires full 32-byte key.

### 8.2 ❌ Wrong Byte Order (Big Endian vs Little Endian)

**WRONG**:
```dart
// Big Endian (MSB first)
buffer.add((timestamp >> 24) & 0xFF); // MSB
buffer.add((timestamp >> 16) & 0xFF);
buffer.add((timestamp >> 8) & 0xFF);
buffer.add(timestamp & 0xFF);         // LSB
```

**CORRECT**:
```dart
// Little Endian (LSB first)
buffer.add(timestamp & 0xFF);         // LSB first
buffer.add((timestamp >> 8) & 0xFF);
buffer.add((timestamp >> 16) & 0xFF);
buffer.add((timestamp >> 24) & 0xFF); // MSB last
```

### 8.3 ❌ Calling syncAllMessages() After Room Login

**WRONG**:
```dart
void _handleLoginSuccess(BufferReader reader) {
  // ... parse response ...
  syncAllMessages(); // ❌ WRONG - room hasn't pushed messages yet!
}
```

**CORRECT**:
```dart
void _handleLoginSuccess(BufferReader reader) {
  // ... parse response ...
  // Just set state and wait for PUSH_CODE_MSG_WAITING
  _loggedInRooms[roomId] = RoomLoginState(isLoggedIn: true);
}

// Sync when notified
void _handleMessageWaiting() {
  syncAllMessages(); // ✅ CORRECT - room has pushed message
}
```

### 8.4 ❌ Not Handling Message Queue Loop

**WRONG**:
```dart
// Only fetch one message
await syncNextMessage();
```

**CORRECT**:
```dart
// Fetch ALL messages until queue is empty
Future<void> syncAllMessages() async {
  while (true) {
    await syncNextMessage();
    // The response handler will set _hasMoreMessages = false when NO_MORE_MESSAGES received
    if (!_hasMoreMessages) break;
    await Future.delayed(Duration(milliseconds: 100));
  }
}
```

### 8.5 ❌ Exceeding Message Length Limits

**WRONG**:
```dart
// Sending 200-byte message
await sendTextMessage(recipientKey, longMessage); // Will fail!
```

**CORRECT**:
```dart
// Validate length before sending
Future<void> sendTextMessage(String recipientKey, String text) async {
  if (text.length > 160) {
    throw Exception('Message exceeds 160 byte limit');
  }
  // ... send message ...
}

// Or split into multiple messages
void sendLongMessage(String recipientKey, String text) {
  final chunks = _splitIntoChunks(text, 160);
  for (final chunk in chunks) {
    await sendTextMessage(recipientKey, chunk);
    await Future.delayed(Duration(milliseconds: 500)); // Spacing between chunks
  }
}
```

### 8.6 ❌ Sending SAR Markers to Public Channel

**WRONG**:
```dart
// SAR marker sent to ephemeral public channel
await sendChannelMessage('S:🧑:46.0569,14.5058'); // ❌ NOT PERSISTENT!
```

**CORRECT**:
```dart
// SAR marker sent to persistent room
final room = contacts.firstWhere((c) => c.type == ContactType.room);
await sendTextMessage(room.publicKey, 'S:🧑:46.0569,14.5058'); // ✅ PERSISTENT
```

### 8.7 ❌ Not Matching Contacts by Public Key Prefix

**WRONG**:
```dart
// Exact match on 6-byte prefix (will fail if contact has full 32-byte key)
final contact = contacts.firstWhere(
  (c) => c.publicKey == hex.encode(pubKeyPrefix),
);
```

**CORRECT**:
```dart
// Prefix match (works with full or partial keys)
final prefixHex = hex.encode(pubKeyPrefix);
final contact = contacts.firstWhere(
  (c) => c.publicKey.startsWith(prefixHex),
  orElse: () => null,
);
```

---

## 9. Testing and Validation

### 9.1 Unit Tests

```dart
// Test message frame building
test('Build CMD_SEND_TXT_MSG frame correctly', () {
  final writer = BufferWriter();
  writer.writeByte(2); // CMD_SEND_TXT_MSG
  writer.writeByte(0); // TXT_TYPE_PLAIN
  writer.writeByte(0); // Attempt 0
  writer.writeUint32(1734567912); // Timestamp
  writer.writeBytes(hex.decode('8B33F2A14CD9')); // 6-byte pub key
  writer.writeString('Hello');

  final expected = [
    0x02, 0x00, 0x00,
    0xE8, 0x76, 0x67, 0x67, // Little Endian timestamp
    0x8B, 0x33, 0xF2, 0xA1, 0x4C, 0xD9,
    0x48, 0x65, 0x6C, 0x6C, 0x6F, // "Hello"
  ];

  expect(writer.toBytes(), equals(expected));
});

// Test message parsing
test('Parse RESP_CODE_CONTACT_MSG_RECV correctly', () {
  final frame = Uint8List.fromList([
    0x07, // RESP_CODE_CONTACT_MSG_RECV
    0x8B, 0x33, 0xF2, 0xA1, 0x4C, 0xD9, // Sender pub key prefix
    0xFF, // Path length (direct)
    0x00, // TXT_TYPE_PLAIN
    0xE8, 0x76, 0x67, 0x67, // Timestamp (Little Endian)
    0x48, 0x69, // "Hi"
  ]);

  final reader = BufferReader(frame);
  reader.readByte(); // Skip response code

  final pubKeyPrefix = reader.readBytes(6);
  final pathLen = reader.readByte();
  final textType = reader.readByte();
  final timestamp = reader.readUint32();
  final text = reader.readString();

  expect(hex.encode(pubKeyPrefix), equals('8b33f2a14cd9'));
  expect(pathLen, equals(0xFF));
  expect(textType, equals(0));
  expect(timestamp, equals(1734567912));
  expect(text, equals('Hi'));
});
```

### 9.2 Integration Tests

```dart
// Test complete message flow
testWidgets('Send and receive message flow', (tester) async {
  final service = MeshCoreBleService();

  // Setup callbacks
  Message? receivedMessage;
  service.onMessageReceived = (msg) => receivedMessage = msg;

  int? expectedAck;
  service.onSentResponse = (ack, timeout) => expectedAck = ack;

  bool confirmed = false;
  service.onSendConfirmed = (ack, rtt) => confirmed = true;

  // Send message
  await service.sendTextMessage(testContactPubKey, 'Test message');
  await tester.pump();

  // Verify RESP_CODE_SENT received
  expect(expectedAck, isNotNull);

  // Simulate PUSH_CODE_SEND_CONFIRMED
  final confirmFrame = Uint8List.fromList([
    0x82, // PUSH_CODE_SEND_CONFIRMED
    ...encodeUint32LE(expectedAck!),
    0x10, 0x27, 0x00, 0x00, // RTT: 10000ms
  ]);
  service.simulateIncomingData(confirmFrame);
  await tester.pump();

  // Verify confirmation received
  expect(confirmed, isTrue);
});
```

### 9.3 Manual Testing Checklist

**Basic Messaging**:
- [ ] Send direct message to contact
- [ ] Receive direct message from contact
- [ ] Send channel message to public
- [ ] Receive channel message from public
- [ ] Messages display with correct sender name
- [ ] Messages display with correct timestamp

**Message Delivery**:
- [ ] Verify RESP_CODE_SENT received after sending
- [ ] Verify PUSH_CODE_SEND_CONFIRMED received after ACK
- [ ] Verify timeout triggers if no ACK
- [ ] Verify retry logic works (manual test with device off)

**Room Operations**:
- [ ] Login to room with correct password
- [ ] Login fails with wrong password
- [ ] Messages automatically sync after login (wait for push)
- [ ] Send message to room (appears for other logged-in clients)
- [ ] Room messages persist (logout, login, verify history)

**SAR Markers**:
- [ ] SAR marker sent to room (not channel)
- [ ] SAR marker parsed correctly
- [ ] SAR marker appears on map
- [ ] SAR marker delivery confirmed

**Edge Cases**:
- [ ] Message at 160-byte limit sends successfully
- [ ] Message over 160 bytes rejected
- [ ] Message to unknown contact handled gracefully
- [ ] Multiple rapid messages queued correctly
- [ ] Message sync handles empty queue (NO_MORE_MESSAGES)

---

## 10. Current Implementation Status

### 10.1 What's Working ✅

Based on review of the Flutter app code:

1. **`meshcore_ble_service.dart`**: ✅ All protocol implementations correct
   - `sendTextMessage()` uses 6-byte public key prefix
   - `sendChannelMessage()` uses correct format
   - `loginToRoom()` sends with sync_since parameter
   - `_handleLoginSuccess()` does NOT call syncNextMessage
   - Message parsing handles signed messages correctly

2. **`connection_provider.dart`**: ✅ Message sync logic correct
   - Waits for `PUSH_CODE_MSG_WAITING` before syncing
   - Calls `syncAllMessages()` when notified
   - Room login state tracking implemented

3. **`messages_tab.dart`**: ✅ SAR marker routing options available
   - Allows users to choose between channel (ephemeral) and room (persistent)
   - Both sending methods implemented correctly

### 10.2 What's Missing ⚠️

1. **ACK Tracking**:
   - App doesn't track expected ACK codes from `RESP_CODE_SENT`
   - Missing `PUSH_CODE_SEND_CONFIRMED` handling
   - No delivery confirmation UI

2. **Retry Logic**:
   - No automatic retry on timeout
   - No exponential backoff
   - No manual retry UI

3. **Room State Management**:
   - Room login state not persisted across app restarts
   - No UI indication of logged-in rooms
   - No automatic re-login on reconnect

### 10.3 Recommendations

**Priority 1 (High Impact)**:
1. Implement ACK tracking and delivery confirmation UI
2. Add timeout handling with retry logic
3. Enforce SAR marker routing to rooms (not channel)

**Priority 2 (Enhancements)**:
1. Persist room login state
2. Add auto-reconnect for rooms
3. Show RTT in message UI

**Priority 3 (Nice to Have)**:
1. Message read receipts (if protocol supports)
2. Message editing/deletion (if protocol supports)
3. Message search and filtering

---

## File References

| File | Description |
|------|-------------|
| `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md` | Official protocol documentation |
| `/Users/dz0ny/meshcore-sar/MeshCore/src/MeshCore.h` | Protocol constants and definitions |
| `/Users/dz0ny/meshcore-sar/MeshCore/src/Mesh.cpp` | Core message routing logic |
| `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_repeater/MyMesh.cpp` | Room server implementation |
| `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/meshcore_ble_service.dart` | Flutter BLE service |
| `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/providers/connection_provider.dart` | Message sync provider |
| `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/screens/messages_tab.dart` | Messages UI |

---

**Document Version**: 1.0
**Date**: 2025-10-14
**Protocol Version**: MeshCore Companion Radio v3-v7
**Implementation Status**: Production-ready with recommended enhancements

---

## Summary

This guide provides complete specifications for implementing messaging in MeshCore applications. The key takeaways:

1. **Two message types**: Direct (to contact) and Channel (broadcast)
2. **Two delivery modes**: Ephemeral (channels) and Persistent (rooms)
3. **Critical protocol details**: Little Endian, 6-byte vs 32-byte keys, UTF-8 encoding
4. **Room login flow**: Send login → wait for success → wait for pushes → sync messages
5. **SAR requirement**: Always send SAR markers to rooms for persistence
6. **Current implementation**: Mostly correct, missing ACK tracking and retry logic

The Flutter app's current implementation follows the protocol correctly. The main enhancement needed is ACK tracking for delivery confirmation UI.
