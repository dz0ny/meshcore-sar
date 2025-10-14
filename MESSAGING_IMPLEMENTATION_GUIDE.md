# MeshCore Messaging System Implementation Guide

**Complete reference for implementing message sending and receiving in the Flutter app**

Date: 2025-01-14
Source: MeshCore C++ firmware (v1.9.1, firmware code 7)
Files analyzed:
- `/Users/dz0ny/meshcore-sar/MeshCore/examples/companion_radio/MyMesh.cpp`
- `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_room_server/MyMesh.cpp`
- `/Users/dz0ny/meshcore-sar/MeshCore/src/helpers/BaseChatMesh.cpp`
- `/Users/dz0ny/meshcore-sar/MeshCore/src/Packet.h`

## Table of Contents

1. [Message Types Overview](#message-types-overview)
2. [Sending Messages](#sending-messages)
3. [Receiving Messages](#receiving-messages)
4. [Room Login Protocol](#room-login-protocol)
5. [Message Confirmation Flow](#message-confirmation-flow)
6. [Binary Protocol Specifications](#binary-protocol-specifications)
7. [Implementation Requirements](#implementation-requirements)
8. [Common Pitfalls](#common-pitfalls)
9. [Complete Example Flows](#complete-example-flows)

---

## Message Types Overview

### Three Message Types

1. **Direct Messages (DM)**
   - **Protocol**: `CMD_SEND_TXT_MSG` (code 2) → `PAYLOAD_TYPE_TXT_MSG` (0x02)
   - **Routing**: Uses contact's `out_path` if available, otherwise flood mode
   - **Confirmation**: Receives ACK from recipient
   - **Use case**: Person-to-person messages, messages to rooms
   - **Persistence**: Only persisted if sent to a room (ADV_TYPE_ROOM)

2. **Channel Messages** (Public Broadcast)
   - **Protocol**: `CMD_SEND_CHANNEL_TXT_MSG` (code 3) → `PAYLOAD_TYPE_GRP_TXT` (0x05)
   - **Routing**: Always flood mode (broadcast to all nodes)
   - **Confirmation**: No ACK (fire-and-forget)
   - **Use case**: Public announcements, SAR markers to all nodes
   - **Persistence**: **EPHEMERAL - not stored anywhere!**

3. **Room Messages** (Persistent Storage)
   - **Protocol**: Same as Direct Messages but recipient is ADV_TYPE_ROOM contact
   - **Routing**: Uses room's `out_path` (after login establishes it)
   - **Confirmation**: Receives ACK from room server
   - **Use case**: Persistent SAR markers, logged communications
   - **Persistence**: **IMMUTABLE storage in room's flash memory**

---

## CRITICAL: Channels vs Rooms

### Channels (Ephemeral Broadcast)

**Definition**: Numeric identifiers (0 = "Public Channel") for over-the-air broadcasts

**Characteristics**:
- Messages broadcast via radio, **NOT stored anywhere**
- No login required
- No persistence - if a node is offline, it misses the message
- Flood routing only (no direct paths)
- No ACK/confirmation
- Channel 0 = "Public Channel" (default)
- Channel 1+ = Reserved for future use

**Protocol**:
```
CMD_SEND_CHANNEL_TXT_MSG (code 3)
[0x03] - Command code
[1 byte] - Text type (TXT_TYPE_PLAIN = 0)
[1 byte] - Channel index (0 for public)
[4 bytes] - Sender timestamp (uint32 LE, epoch seconds)
[N bytes] - Text (remainder, max 160 - name_len - 2)
```

### Rooms (Persistent Storage)

**Definition**: Actual **contacts** with public keys that provide database-backed storage

**Characteristics**:
- Messages sent as **direct messages** to the room contact
- Requires login with password
- **Persistent and immutable** - stored in room's flash even when offline
- Room pushes messages to clients automatically after login
- Provides ACK confirmation
- Supports admin/guest permissions

**How to identify rooms**:
- `contact.type == ADV_TYPE_ROOM` (value 3)
- Appears in Contacts tab
- Has 32-byte public key
- Requires password to access

**Protocol to send to room**:
```
Use CMD_SEND_TXT_MSG with room's public key (same as person-to-person message)
```

---

## Sending Messages

### 1. Send Direct Message to Contact

**File**: `lib/services/meshcore_ble_service.dart:1409-1427`

**Protocol** (`CMD_SEND_TXT_MSG`, code 2):
```
[0x02] - Command code
[1 byte] - Text type (TXT_TYPE_PLAIN=0, TXT_TYPE_CLI_DATA=1, TXT_TYPE_SIGNED_PLAIN=2)
[1 byte] - Attempt number (0-3 for retries)
[4 bytes] - Sender timestamp (uint32 LE, epoch seconds UTC)
[6 bytes] - Recipient public key PREFIX (first 6 bytes only!)
[N bytes] - Message text (remainder, UTF-8, max 160 bytes)
```

**Example**:
```dart
Future<void> sendTextMessage({
  required Uint8List contactPublicKey,
  required String text,
  int textType = 0, // TXT_TYPE_PLAIN
  int attempt = 0,
}) async {
  if (text.length > 160) {
    throw ArgumentError('Text message exceeds 160 character limit');
  }

  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendTxtMsg); // 0x02
  writer.writeByte(textType); // TXT_TYPE_*
  writer.writeByte(attempt); // 0-3
  writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000); // epoch seconds
  writer.writeBytes(contactPublicKey.sublist(0, 6)); // ONLY first 6 bytes!
  writer.writeString(text);
  await _writeData(writer.toBytes());
}
```

**Response** (`RESP_CODE_SENT`, code 6):
```
[0x06] - Response code
[1 byte] - Send type (1=flood, 0=direct)
[4 bytes] - Expected ACK code or TAG (for matching confirmation later)
[4 bytes] - Suggested timeout (uint32 LE, milliseconds)
```

**Source**:
- Command composition: `MyMesh.cpp:818-862` (Companion Radio)
- Protocol implementation: `BaseChatMesh.cpp:334-351` (Core library)
- Message packet creation: `BaseChatMesh.cpp:312-332` (`composeMsgPacket`)

### 2. Send Channel Message (Public Broadcast)

**File**: `lib/services/meshcore_ble_service.dart:1439-1456`

**Protocol** (`CMD_SEND_CHANNEL_TXT_MSG`, code 3):
```
[0x03] - Command code
[1 byte] - Text type (TXT_TYPE_PLAIN=0)
[1 byte] - Channel index (0 for 'public')
[4 bytes] - Sender timestamp (uint32 LE, epoch seconds)
[N bytes] - Message text (remainder, max ~140 chars depending on sender name)
```

**Example**:
```dart
Future<void> sendChannelMessage({
  required int channelIdx,
  required String text,
  int textType = 0, // TXT_TYPE_PLAIN
}) async {
  if (text.length > 160) {
    throw ArgumentError('Channel message too long');
  }

  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg); // 0x03
  writer.writeByte(textType); // TXT_TYPE_*
  writer.writeByte(channelIdx); // 0 for 'public' channel
  writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  writer.writeString(text);
  await _writeData(writer.toBytes());
}
```

**Note**: Channel messages do NOT receive ACK confirmations. They are fire-and-forget broadcasts.

**Source**:
- Command handling: `MyMesh.cpp:863-882` (Companion Radio)
- Message composition: `BaseChatMesh.cpp:379-398` (`sendGroupMessage`)

### 3. Send Message to Room (Persistent Storage)

**CRITICAL**: To send persistent messages to a room, use `CMD_SEND_TXT_MSG` (direct message) with the room's public key, NOT channel messages.

```dart
// ✅ CORRECT - Sends to room for persistent storage
await sendTextMessage(
  contactPublicKey: roomContact.publicKey, // Room's 32-byte public key
  text: 'S:🧑:46.0569,14.5058', // SAR marker
);

// ❌ WRONG - Ephemeral broadcast, NOT stored in room
await sendChannelMessage(
  channelIdx: 0,
  text: 'S:🧑:46.0569,14.5058',
);
```

**Why?**
- Rooms are contacts with `type == ADV_TYPE_ROOM` (value 3)
- Rooms receive direct messages and store them in flash memory
- Channel messages are over-the-air only and never stored
- SAR markers MUST be persistent for search coordination

---

## Receiving Messages

### Message Queue Architecture

The companion radio maintains an **internal message queue** in memory:
- Messages received over the air are added to queue
- Queue holds messages until app fetches them
- Max queue size: `OFFLINE_QUEUE_SIZE` (typically 16 messages)
- When full, oldest channel messages are deleted first

### Message Receive Flow

```
1. Message received over radio
   ↓
2. Companion radio decrypts and validates
   ↓
3. Companion radio adds to internal queue
   ↓
4. Companion radio sends PUSH_CODE_MSG_WAITING (0x83) to app
   ↓
5. App's onMessageWaiting callback fires
   ↓
6. App calls CMD_SYNC_NEXT_MESSAGE (10)
   ↓
7. Companion radio sends RESP_CODE_CONTACT_MSG_RECV or RESP_CODE_CHANNEL_MSG_RECV
   ↓
8. App processes message and adds to UI
   ↓
9. Repeat steps 6-8 until RESP_CODE_NO_MORE_MESSAGES (10)
```

### 1. Handle Message Waiting Notification

**Protocol** (`PUSH_CODE_MSG_WAITING`, code 0x83):
```
[0x83] - Push code
(no additional data)
```

**Implementation**:
```dart
// Set up callback in connection initialization
_bleService.onMessageWaiting = () {
  print('📨 New message(s) waiting in companion radio queue');
  // Start fetching messages from queue
  _fetchAllPendingMessages();
};

Future<void> _fetchAllPendingMessages() async {
  bool hasMore = true;
  while (hasMore) {
    try {
      await _bleService.syncNextMessage();
      // Wait for response (RESP_CODE_CONTACT_MSG_RECV or RESP_CODE_NO_MORE_MESSAGES)
      // Response is handled by _onDataReceived()
      await Future.delayed(Duration(milliseconds: 100)); // Small delay between requests
    } catch (e) {
      print('Error fetching message: $e');
      hasMore = false;
    }
  }
}
```

**Source**: `MyMesh.cpp:363-367, 428-436` (companion radio queue push notification)

### 2. Sync Next Message

**Protocol** (`CMD_SYNC_NEXT_MESSAGE`, code 10):
```
[0x0A] - Command code
(no additional data)
```

**Implementation**:
```dart
Future<void> syncNextMessage() async {
  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSyncNextMessage); // 0x0A
  await _writeData(writer.toBytes());
}
```

**Source**: `MyMesh.cpp:1056-1066` (companion radio command handler)

### 3. Parse Contact Message Response

**Protocol** (`RESP_CODE_CONTACT_MSG_RECV`, code 7):
```
[0x07] - Response code
[6 bytes] - Sender public key PREFIX (first 6 bytes)
[1 byte] - Path length (0xFF if direct, else hop count)
[1 byte] - Text type (TXT_TYPE_*)
[4 bytes] - Sender timestamp (uint32 LE, epoch seconds)
[N bytes] - Message text (remainder, null-terminated)
```

**For signed messages** (`TXT_TYPE_SIGNED_PLAIN`):
```
[0x07] - Response code
[6 bytes] - Sender public key PREFIX
[1 byte] - Path length
[1 byte] - Text type (TXT_TYPE_SIGNED_PLAIN = 2)
[4 bytes] - Sender timestamp
[4 bytes] - Author public key prefix (first 4 bytes of original author)
[N bytes] - Message text (remainder)
```

**Implementation** (file: `lib/services/meshcore_ble_service.dart:512-578`):
```dart
void _handleContactMessage(BufferReader reader) {
  try {
    final pubKeyPrefix = reader.readBytes(6);
    final pathLen = reader.readByte();
    final txtTypeByte = reader.readByte();
    final txtType = MessageTextType.fromValue(txtTypeByte);
    final senderTimestamp = reader.readUInt32LE();

    String text;
    Uint8List? authorPrefix;

    if (txtType == MessageTextType.signedPlain) {
      // Signed message: next 4 bytes are author prefix
      authorPrefix = reader.readBytes(4);
      text = reader.readString();
    } else {
      // Plain message
      text = reader.readString();
    }

    final message = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_${pubKeyPrefix.map((b) => b.toRadixString(16)).join()}',
      messageType: MessageType.contact,
      senderPublicKeyPrefix: pubKeyPrefix,
      pathLen: pathLen,
      textType: txtType,
      senderTimestamp: senderTimestamp,
      text: text,
      receivedAt: DateTime.now(),
      authorPublicKeyPrefix: authorPrefix, // For signed messages from rooms
    );

    onMessageReceived?.call(message);
  } catch (e) {
    print('Error parsing contact message: $e');
    onError?.call('Contact message parsing error: $e');
  }
}
```

**Source**: `MyMesh.cpp:334-379` (companion radio message queueing)

### 4. Parse Channel Message Response

**Protocol** (`RESP_CODE_CHANNEL_MSG_RECV`, code 8):
```
[0x08] - Response code
[1 byte] - Channel index (0 for 'public')
[1 byte] - Path length (0xFF if direct, else hop count)
[1 byte] - Text type (TXT_TYPE_*)
[4 bytes] - Sender timestamp (uint32 LE, epoch seconds)
[N bytes] - Message text (remainder, null-terminated)
```

**Implementation** (file: `lib/services/meshcore_ble_service.dart:581-647`):
```dart
void _handleChannelMessage(BufferReader reader) {
  try {
    final channelIdx = reader.readInt8();
    final pathLen = reader.readByte();
    final txtTypeByte = reader.readByte();
    final txtType = MessageTextType.fromValue(txtTypeByte);
    final senderTimestamp = reader.readUInt32LE();
    final text = reader.readString();

    final message = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}_ch$channelIdx',
      messageType: MessageType.channel,
      channelIdx: channelIdx,
      pathLen: pathLen,
      textType: txtType,
      senderTimestamp: senderTimestamp,
      text: text,
      receivedAt: DateTime.now(),
    );

    onMessageReceived?.call(message);
  } catch (e) {
    print('Error parsing channel message: $e');
    onError?.call('Channel message parsing error: $e');
  }
}
```

**Source**: `MyMesh.cpp:401-446` (companion radio channel message queueing)

### 5. Handle No More Messages

**Protocol** (`RESP_CODE_NO_MORE_MESSAGES`, code 10):
```
[0x0A] - Response code
(no additional data)
```

**Implementation**:
```dart
case MeshCoreConstants.respNoMoreMessages:
  print('No more messages in queue');
  onNoMoreMessages?.call();
  break;
```

**Source**: `MyMesh.cpp:1063-1065` (companion radio queue empty response)

---

## Room Login Protocol

### CRITICAL: Understanding Room Message Push

**How room message sync works**:

1. **Client sends login request** with `sync_since` timestamp
2. **Room server stores** `client->extra.room.sync_since` value
3. **Room server AUTOMATICALLY PUSHES** messages where `post_timestamp > sync_since`
4. **Room server uses round-robin** polling every 1200ms (SYNC_PUSH_INTERVAL)
5. **Room server waits for ACK** before advancing to next message
6. **Client receives pushed messages** via normal `PUSH_CODE_MSG_WAITING` flow

**What the app MUST do**:
- ✅ Wait for `PUSH_CODE_MSG_WAITING` notifications
- ✅ Call `syncNextMessage()` when notified
- ✅ Continue until `RESP_CODE_NO_MORE_MESSAGES`

**What the app MUST NOT do**:
- ❌ DON'T call `syncNextMessage()` immediately after `PUSH_CODE_LOGIN_SUCCESS`
- ❌ DON'T try to "pull" messages manually
- ❌ DON'T implement a timer to check for messages

### Room Login Flow

```
1. App: CMD_SEND_LOGIN (26) with password and sync_since
   ↓
2. Radio: Sends PAYLOAD_TYPE_ANON_REQ to room
   ↓
3. Room: Validates password, stores sync_since
   ↓
4. Room: Sends login response back
   ↓
5. App: Receives PUSH_CODE_LOGIN_SUCCESS (0x85)
   ↓
6. Room: Delays 2000ms (PUSH_NOTIFY_DELAY_MILLIS)
   ↓
7. Room: Starts round-robin message push loop (every 1200ms)
   ↓
8. For each logged-in client:
     If post_timestamp > client.sync_since:
       - Room calls pushPostToClient()
       - Sends PAYLOAD_TYPE_TXT_MSG to client
       - Waits for ACK
       - Advances client.sync_since
       - Continues to next message
   ↓
9. Radio: Receives pushed message from room
   ↓
10. Radio: Adds to internal queue
    ↓
11. Radio: Sends PUSH_CODE_MSG_WAITING (0x83) to app
    ↓
12. App: onMessageWaiting callback fires
    ↓
13. App: Calls syncNextMessage() to fetch from queue
    ↓
14. App: Receives RESP_CODE_CONTACT_MSG_RECV with message
    ↓
15. Repeat steps 7-14 until all messages pushed
```

### Login Request Protocol

**Protocol** (`CMD_SEND_LOGIN`, code 26):
```
[0x1A] - Command code (26)
[4 bytes] - Sender timestamp (uint32 LE, current epoch seconds)
[4 bytes] - sync_since timestamp (uint32 LE, epoch seconds - 0 for all messages)
[32 bytes] - Room public key
[N bytes] - Password (max 15 bytes, null-terminated)
```

**Implementation** (file: `lib/services/meshcore_ble_service.dart:1616-1642`):
```dart
Future<void> loginToRoom({
  required Uint8List roomPublicKey,
  required String password,
  int syncSince = 0, // 0 = get all messages
}) async {
  if (password.length > 15) {
    throw ArgumentError('Password exceeds 15 character limit');
  }

  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // epoch seconds

  final writer = BufferWriter();
  writer.writeByte(MeshCoreConstants.cmdSendLogin); // 0x1A
  writer.writeUInt32LE(now); // sender timestamp
  writer.writeUInt32LE(syncSince); // sync messages since this timestamp (0 = all)
  writer.writeBytes(roomPublicKey); // 32 bytes
  writer.writeString(password); // Max 15 bytes, null-terminated
  await _writeData(writer.toBytes());
}
```

**Source**:
- Login request composition: `BaseChatMesh.cpp:431-464`
- Companion radio command handler: `MyMesh.cpp:1196-1217`
- Room server login processing: `simple_room_server/MyMesh.cpp:282-363` (lines 286-324 critical)

### Login Success Response

**Protocol** (`PUSH_CODE_LOGIN_SUCCESS`, code 0x85):
```
[0x85] - Push code
[1 byte] - Permissions (lowest bit = is_admin)
[6 bytes] - Room public key prefix (first 6 bytes)
[4 bytes] - Tag (int32 LE)
[1 byte] - (V7+) New permissions
```

**Implementation** (file: `lib/services/meshcore_ble_service.dart:1175-1206`):
```dart
void _handleLoginSuccess(BufferReader reader) {
  try {
    if (reader.remainingBytesCount >= 11) {
      final permissions = reader.readByte();
      final isAdmin = (permissions & 0x01) != 0;
      final publicKeyPrefix = reader.readBytes(6);
      final tag = reader.readInt32LE();

      // V7+ new permissions byte
      int? newPermissions;
      if (reader.hasRemaining) {
        newPermissions = reader.readByte();
      }

      print('✅ Successfully logged into room');
      onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);

      // DO NOT call syncAllMessages() here!
      // Wait for PUSH_CODE_MSG_WAITING instead
    }
  } catch (e) {
    print('Login success parsing error: $e');
    onError?.call('Login success parsing error: $e');
  }
}
```

**Source**:
- Companion radio response parsing: `MyMesh.cpp:496-525`
- Room server login success response: `simple_room_server/MyMesh.cpp:335-346`

### Login Fail Response

**Protocol** (`PUSH_CODE_LOGIN_FAIL`, code 0x86):
```
[0x86] - Push code
[1 byte] - Reserved (zero)
[6 bytes] - Room public key prefix
```

**Source**: Room server validation: `simple_room_server/MyMesh.cpp:303-314`

### Room Message Push Implementation

**Room server C++ code** (`simple_room_server/MyMesh.cpp:777-820`):
```cpp
// Round-robin polling every SYNC_PUSH_INTERVAL (1200ms)
void MyMesh::loop() {
  mesh::Mesh::loop();

  if (millisHasNowPassed(next_push) && acl.getNumClients() > 0) {
    // Check for ACK timeouts
    for (int i = 0; i < acl.getNumClients(); i++) {
      auto c = acl.getClientByIdx(i);
      if (c->extra.room.pending_ack && millisHasNowPassed(c->extra.room.ack_timeout)) {
        c->extra.room.push_failures++;
        c->extra.room.pending_ack = 0; // reset
      }
    }

    // Check next Round-Robin client, and sync next new post
    auto client = acl.getClientByIdx(next_client_idx);
    bool did_push = false;

    if (client->extra.room.pending_ack == 0 &&  // not waiting for ACK
        client->last_activity != 0 &&            // not evicted
        client->extra.room.push_failures < 3) {  // retries not maxed

      uint32_t now = getRTCClock()->getCurrentTime();
      for (int k = 0, idx = next_post_idx; k < MAX_UNSYNCED_POSTS; k++) {
        auto p = &posts[idx];
        if (now >= p->post_timestamp + POST_SYNC_DELAY_SECS &&
            p->post_timestamp > client->extra.room.sync_since &&  // is new post?
            !p->author.matches(client->id)) {                      // don't push to author

          // Push this post to Client, then wait for ACK
          pushPostToClient(client, *p);
          did_push = true;
          break;
        }
        idx = (idx + 1) % MAX_UNSYNCED_POSTS; // wrap cyclic queue
      }
    }

    next_client_idx = (next_client_idx + 1) % acl.getNumClients(); // round robin

    if (did_push) {
      next_push = futureMillis(SYNC_PUSH_INTERVAL); // 1200ms
    } else {
      next_push = futureMillis(SYNC_PUSH_INTERVAL / 8); // faster when no pushes
    }
  }
  // ... rest of loop
}
```

**Key constants**:
- `PUSH_NOTIFY_DELAY_MILLIS` = 2000ms (initial delay after login)
- `SYNC_PUSH_INTERVAL` = 1200ms (time between push attempts)
- `POST_SYNC_DELAY_SECS` = 6 (wait 6 seconds after post before pushing)

---

## Message Confirmation Flow

### ACK Protocol for Direct Messages

When you send a direct message, you receive an expected ACK code that you should match later.

**1. Send Message**
```dart
await sendTextMessage(
  contactPublicKey: contact.publicKey,
  text: 'Hello!',
);
```

**2. Receive RESP_CODE_SENT**
```
[0x06] - Response code
[1 byte] - Send type (1=flood, 0=direct)
[4 bytes] - Expected ACK code (store this!)
[4 bytes] - Suggested timeout (milliseconds)
```

**3. Wait for PUSH_CODE_SEND_CONFIRMED**
```
[0x82] - Push code
[4 bytes] - ACK code (match with expected ACK from step 2)
[4 bytes] - Round trip time (uint32 LE, milliseconds)
```

**Implementation**:
```dart
// Store expected ACKs
final Map<String, ExpectedAck> _expectedAcks = {};

// When sending
void _handleSentConfirmation(BufferReader reader) {
  final sendType = reader.readByte();
  final expectedAckOrTag = reader.readBytes(4);
  final suggestedTimeout = reader.readUInt32LE();

  // Store for matching later
  final ackKey = expectedAckOrTag.map((b) => b.toRadixString(16)).join();
  _expectedAcks[ackKey] = ExpectedAck(
    timestamp: DateTime.now(),
    timeout: Duration(milliseconds: suggestedTimeout),
  );

  // Set timeout
  Future.delayed(Duration(milliseconds: suggestedTimeout), () {
    if (_expectedAcks.containsKey(ackKey)) {
      _expectedAcks.remove(ackKey);
      print('⏱️ Message timeout - no ACK received');
      // Notify UI of timeout
    }
  });
}

// When confirmation arrives
void _handleSendConfirmed(BufferReader reader) {
  final ackCode = reader.readBytes(4);
  final roundTripTime = reader.readUInt32LE();

  final ackKey = ackCode.map((b) => b.toRadixString(16)).join();
  if (_expectedAcks.containsKey(ackKey)) {
    _expectedAcks.remove(ackKey);
    print('✅ Message confirmed! RTT: ${roundTripTime}ms');
    // Notify UI of successful delivery
  }
}
```

**Source**:
- Expected ACK calculation: `BaseChatMesh.cpp:323` (SHA256 hash of message)
- ACK table management: `MyMesh.cpp:316-332` (companion radio)
- Confirmation push: `MyMesh.cpp:320-324`

### No ACK for Channel Messages

Channel messages (public broadcasts) do NOT receive ACK confirmations. They are fire-and-forget.

---

## Binary Protocol Specifications

### All Integer Types are Little Endian!

**CRITICAL**: All multi-byte integers in MeshCore protocol use **Little Endian** byte order!

```dart
// ✅ CORRECT - Little Endian
writer.writeUInt32LE(timestamp);
writer.writeInt32LE(latitude);

// ❌ WRONG - Big Endian (will cause protocol errors!)
writer.writeUInt32BE(timestamp);
```

### Text Type Enum

```
TXT_TYPE_PLAIN = 0        // Plain text message
TXT_TYPE_CLI_DATA = 1     // CLI command (admin only)
TXT_TYPE_SIGNED_PLAIN = 2 // Plain text, signed by original author
```

Source: `TxtDataHelpers.h:6-8`

### Contact Types (ADV_TYPE)

```
ADV_TYPE_NONE = 0      // Unknown/invalid
ADV_TYPE_CHAT = 1      // Team member (person-to-person)
ADV_TYPE_REPEATER = 2  // Network repeater node
ADV_TYPE_ROOM = 3      // Room/server with persistent storage
```

Source: `AdvertDataHelpers.h` (inferred from protocol)

### Message Length Limits

```
MAX_TEXT_LEN = 160 bytes  // For direct messages

Channel messages: 160 - len(advert_name) - 2 bytes
Typical: ~140 bytes if name is 18 chars
```

Source:
- `BaseChatMesh.h:8` (MAX_TEXT_LEN definition)
- `MyMesh.cpp:870` (channel message validation)

### Public Key Handling

**CRITICAL**: Different commands use different public key lengths!

```
CMD_SEND_TXT_MSG:         6 bytes (prefix only!)
CMD_SEND_LOGIN:          32 bytes (full key)
CMD_ADD_UPDATE_CONTACT:  32 bytes (full key)
RESP_CODE_CONTACT:       32 bytes (full key)
RESP_CODE_CONTACT_MSG_RECV: 6 bytes (prefix)
```

**Why?** To save bandwidth, message sends use only 6-byte prefix for recipient identification. The companion radio looks up the full 32-byte key from its internal contact table.

---

## Implementation Requirements

### What the App MUST Implement

1. **Message Queue Handling**
   - ✅ Respond to `PUSH_CODE_MSG_WAITING` by calling `syncNextMessage()`
   - ✅ Continue calling `syncNextMessage()` until `RESP_CODE_NO_MORE_MESSAGES`
   - ✅ Handle both `RESP_CODE_CONTACT_MSG_RECV` and `RESP_CODE_CHANNEL_MSG_RECV`

2. **Room Login Flow**
   - ✅ Send `CMD_SEND_LOGIN` with password and `sync_since`
   - ✅ Wait for `PUSH_CODE_LOGIN_SUCCESS` or `PUSH_CODE_LOGIN_FAIL`
   - ✅ After login success, **DO NOTHING** - room will push messages automatically
   - ✅ Handle pushed messages via normal `PUSH_CODE_MSG_WAITING` flow

3. **Contact Management**
   - ✅ Call `CMD_GET_CONTACTS` after connection to sync contacts
   - ✅ Use `CMD_ADD_UPDATE_CONTACT` to add rooms that haven't advertised
   - ✅ Store contacts locally for offline access

4. **Message Sending**
   - ✅ Use `CMD_SEND_TXT_MSG` for direct messages and room messages
   - ✅ Use `CMD_SEND_CHANNEL_TXT_MSG` only for ephemeral public broadcasts
   - ✅ Store expected ACK codes from `RESP_CODE_SENT`
   - ✅ Match ACKs in `PUSH_CODE_SEND_CONFIRMED` to mark messages as delivered

5. **Signed Messages (from Rooms)**
   - ✅ Parse `TXT_TYPE_SIGNED_PLAIN` messages correctly
   - ✅ Extract 4-byte author prefix after sender timestamp
   - ✅ Show original author in UI, not room's public key

### What the App MUST NOT Do

1. **❌ DON'T call `syncNextMessage()` immediately after `PUSH_CODE_LOGIN_SUCCESS`**
   - The room server delays pushes by 2000ms
   - Calling sync immediately will get `RESP_CODE_NO_MORE_MESSAGES`
   - Wait for `PUSH_CODE_MSG_WAITING` instead!

2. **❌ DON'T send SAR markers as channel messages**
   - Channel messages are ephemeral (not stored)
   - SAR markers MUST be persistent
   - Use `CMD_SEND_TXT_MSG` to room contacts instead

3. **❌ DON'T use Big Endian for integers**
   - All multi-byte integers MUST be Little Endian
   - Check your BufferWriter implementation!

4. **❌ DON'T send full 32-byte public key in `CMD_SEND_TXT_MSG`**
   - Only send first 6 bytes (prefix)
   - Sending 32 bytes will cause protocol error

5. **❌ DON'T retry login immediately on failure**
   - Wait at least 5 seconds between retries
   - Excessive retries may get you blocked by room

---

## Common Pitfalls

### 1. Incorrect Room Message Routing

**Problem**: Sending SAR markers to public channel instead of room

```dart
// ❌ WRONG - Ephemeral, not stored
await sendChannelMessage(
  channelIdx: 0,
  text: 'S:🧑:46.0569,14.5058',
);

// ✅ CORRECT - Persistent in room
await sendTextMessage(
  contactPublicKey: roomContact.publicKey,
  text: 'S:🧑:46.0569,14.5058',
);
```

### 2. Calling syncNextMessage() Too Early

**Problem**: Calling `syncNextMessage()` right after login success

```dart
// ❌ WRONG
onLoginSuccess = (prefix, perms, isAdmin, tag) async {
  await syncAllMessages(); // Too early! Room hasn't pushed yet
};

// ✅ CORRECT
onLoginSuccess = (prefix, perms, isAdmin, tag) {
  print('Login successful, waiting for message pushes...');
  // Don't call syncNextMessage() - wait for PUSH_CODE_MSG_WAITING
};

onMessageWaiting = () async {
  // Now fetch messages
  await fetchAllPendingMessages();
};
```

**Why?** Room server delays first push by 2000ms (`PUSH_NOTIFY_DELAY_MILLIS`). Calling sync immediately gets `RESP_CODE_NO_MORE_MESSAGES`.

### 3. Using Wrong Public Key Length

**Problem**: Sending 32-byte public key in `CMD_SEND_TXT_MSG`

```dart
// ❌ WRONG
writer.writeBytes(contactPublicKey); // 32 bytes

// ✅ CORRECT
writer.writeBytes(contactPublicKey.sublist(0, 6)); // Only first 6 bytes
```

### 4. Big Endian vs Little Endian

**Problem**: Using wrong byte order for integers

```dart
// ❌ WRONG - Big Endian
writer.writeUInt32BE(timestamp);

// ✅ CORRECT - Little Endian
writer.writeUInt32LE(timestamp);
```

All integers in MeshCore protocol are Little Endian!

### 5. Not Handling Signed Messages

**Problem**: Displaying room public key as sender instead of original author

```dart
// In room messages, sender is the room, but author is in message data

if (txtType == MessageTextType.signedPlain) {
  // Next 4 bytes are original author's public key prefix
  final authorPrefix = reader.readBytes(4);
  // Show authorPrefix as sender, not room's pubKeyPrefix
}
```

### 6. Room Contact Not in Companion Radio Table

**Problem**: Getting `ERR_CODE_NOT_FOUND` when trying to login

**Solution**: Add room contact to companion radio first:

```dart
// Before login, ensure room contact exists
await _bleService.addOrUpdateContact(roomContact);

// Wait a moment for contact to be added
await Future.delayed(Duration(milliseconds: 500));

// Now login
await _bleService.loginToRoom(
  roomPublicKey: roomContact.publicKey,
  password: 'mypassword',
);
```

### 7. Not Handling Message Queue Overflow

**Problem**: Offline queue fills up (16 messages max), oldest messages lost

**Solution**: Fetch messages promptly when `PUSH_CODE_MSG_WAITING` arrives. Don't delay message fetching.

---

## Complete Example Flows

### Example 1: Send SAR Marker to Room (Persistent)

```dart
// 1. Ensure we have room contact
final room = contacts.firstWhere(
  (c) => c.type == ContactType.room && c.advName == 'SAR Room',
  orElse: () => throw Exception('Room not found'),
);

// 2. Add room to companion radio if not already there
await _bleService.addOrUpdateContact(room);
await Future.delayed(Duration(milliseconds: 500));

// 3. Login to room
await _bleService.loginToRoom(
  roomPublicKey: room.publicKey,
  password: 'sarpassword',
  syncSince: 0, // Get all historical messages
);

// 4. Wait for login success
// (onLoginSuccess callback will fire)

// 5. Send SAR marker as direct message to room
await _bleService.sendTextMessage(
  contactPublicKey: room.publicKey,
  text: 'S:🧑:46.0569,14.5058',
);

// 6. Wait for RESP_CODE_SENT and store expected ACK
// (sendTextMessage will return immediately)

// 7. Wait for PUSH_CODE_SEND_CONFIRMED to confirm delivery
// (onSendConfirmed callback will fire when room ACKs)
```

### Example 2: Receive Messages from Room

```dart
// Set up callbacks
_bleService.onLoginSuccess = (prefix, perms, isAdmin, tag) {
  print('✅ Logged into room successfully');
  print('   Waiting for automatic message push from room...');
  // DO NOT call syncNextMessage() here!
};

_bleService.onMessageWaiting = () async {
  print('📨 Message(s) waiting, fetching from queue...');
  await _fetchAllPendingMessages();
};

_bleService.onMessageReceived = (message) {
  if (message.textType == MessageTextType.signedPlain) {
    // This is a room message - show original author
    print('Room message from author: ${message.authorPublicKeyPrefix}');
  } else {
    // Normal direct message
    print('Direct message from: ${message.senderPublicKeyPrefix}');
  }

  // Add to UI
  setState(() {
    _messages.add(message);
  });
};

_bleService.onNoMoreMessages = () {
  print('✅ All messages fetched from queue');
};

// Fetch all pending messages from queue
Future<void> _fetchAllPendingMessages() async {
  while (true) {
    try {
      await _bleService.syncNextMessage();

      // Wait for response
      await Future.delayed(Duration(milliseconds: 100));

      // If RESP_CODE_NO_MORE_MESSAGES, onNoMoreMessages callback fires
      // and we can break (but it's safer to let it timeout naturally)
    } catch (e) {
      print('Error fetching message: $e');
      break;
    }
  }
}
```

### Example 3: Send to Public Channel (Ephemeral Broadcast)

```dart
// This is for emergency broadcasts that ALL nodes should see immediately
// But it's NOT stored anywhere!

await _bleService.sendChannelMessage(
  channelIdx: 0, // 0 = "Public Channel"
  text: 'Emergency: Flash flood warning!',
);

// No ACK confirmation - fire and forget
// Offline nodes will never see this message
```

### Example 4: Handle Login Failure and Retry

```dart
int _loginAttempts = 0;
const maxLoginAttempts = 3;

_bleService.onLoginFail = (prefix) async {
  print('❌ Login failed to room: $prefix');

  _loginAttempts++;
  if (_loginAttempts < maxLoginAttempts) {
    print('   Retrying in 5 seconds... (attempt ${_loginAttempts + 1}/$maxLoginAttempts)');

    await Future.delayed(Duration(seconds: 5));

    // Retry login
    await _bleService.loginToRoom(
      roomPublicKey: roomContact.publicKey,
      password: _password,
    );
  } else {
    print('   Max login attempts reached. Check password.');
    // Show error to user
  }
};
```

---

## File References

All source code locations in MeshCore C++ firmware:

### Companion Radio Implementation
- **Command handler**: `/Users/dz0ny/meshcore-sar/MeshCore/examples/companion_radio/MyMesh.cpp`
  - Lines 818-862: `CMD_SEND_TXT_MSG` handler
  - Lines 863-882: `CMD_SEND_CHANNEL_TXT_MSG` handler
  - Lines 1056-1066: `CMD_SYNC_NEXT_MESSAGE` handler
  - Lines 1196-1217: `CMD_SEND_LOGIN` handler
  - Lines 334-379: Message queueing (`queueMessage`)
  - Lines 316-332: ACK processing (`processAck`)

### Room Server Implementation
- **Room server**: `/Users/dz0ny/meshcore-sar/MeshCore/examples/simple_room_server/MyMesh.cpp`
  - Lines 282-363: Login processing (`onAnonDataRecv`)
  - Lines 286-324: Password validation and client setup
  - Lines 335-346: Login success response
  - Lines 777-820: Message push loop (`loop()`)
  - Lines 53-89: Push message to client (`pushPostToClient`)
  - Lines 91-100: Count unsynced messages (`getUnsyncedCount`)
  - Lines 102-113: ACK processing for pushed messages (`processAck`)

### Core Library
- **Message sending**: `/Users/dz0ny/meshcore-sar/MeshCore/src/helpers/BaseChatMesh.cpp`
  - Lines 334-351: Send direct message (`sendMessage`)
  - Lines 379-398: Send channel message (`sendGroupMessage`)
  - Lines 431-464: Send login request (`sendLogin`)
  - Lines 312-332: Compose message packet (`composeMsgPacket`)
  - Lines 143-233: Receive and process messages (`onPeerDataRecv`)

### Protocol Definitions
- **Packet types**: `/Users/dz0ny/meshcore-sar/MeshCore/src/Packet.h`
  - Lines 19-31: Payload type definitions
  - Lines 14-17: Route type definitions

---

## Flutter App Implementation Status

### Current Implementation (Correct)

✅ **BLE Service** (`lib/services/meshcore_ble_service.dart`):
- Lines 1409-1427: `sendTextMessage()` - correctly sends direct messages
- Lines 1439-1456: `sendChannelMessage()` - correctly sends channel broadcasts
- Lines 1616-1642: `loginToRoom()` - correctly sends login with sync_since
- Lines 1479-1483: `syncNextMessage()` - correctly fetches from queue
- Lines 1368-1398: `addOrUpdateContact()` - correctly adds room contacts
- Lines 512-578: `_handleContactMessage()` - correctly parses contact messages
- Lines 581-647: `_handleChannelMessage()` - correctly parses channel messages
- Lines 1157-1166: `_handleMsgWaiting()` - correctly triggers onMessageWaiting callback
- Lines 1175-1206: `_handleLoginSuccess()` - correctly parses login success

### Issues to Fix

❌ **Room login state management** (`lib/models/room_login_state.dart`):
- This file exists but implementation details not reviewed yet
- Ensure state machine doesn't call `syncNextMessage()` immediately after login success

❌ **Message routing decision** (`lib/screens/messages_tab.dart`):
- Need to check if SAR markers are being sent to rooms vs channels
- Line 49 (`_sendMessage`): Verify routing logic

❌ **Connection provider** (`lib/providers/connection_provider.dart`):
- Lines 123, 600, 608, 643: Message waiting and sync handling
- Verify `syncNextMessage()` is only called when `onMessageWaiting` fires
- Check if there's any premature syncing after login

### Recommended Next Steps

1. **Review `connection_provider.dart`** message sync logic
2. **Review `messages_tab.dart`** for SAR marker routing
3. **Add ACK tracking** for message delivery confirmation
4. **Implement retry logic** for failed logins
5. **Add UI indicators** for message delivery status (sending/sent/confirmed/failed)

---

## Testing Checklist

### Room Login Testing

- [ ] Login succeeds with correct password
- [ ] Login fails with incorrect password
- [ ] `PUSH_CODE_MSG_WAITING` arrives after 2+ seconds
- [ ] Calling `syncNextMessage()` before push returns `NO_MORE_MESSAGES`
- [ ] Room pushes all messages where `post_timestamp > sync_since`
- [ ] Room pushes continue until all messages delivered
- [ ] Room doesn't push messages to original author
- [ ] Second login with higher `sync_since` only gets new messages

### Message Sending Testing

- [ ] Direct message to person succeeds
- [ ] Direct message to room succeeds
- [ ] Channel message broadcasts successfully
- [ ] SAR marker sent to room is persistent
- [ ] SAR marker sent to channel is NOT persistent (verify by rebooting)
- [ ] Message length limit (160 bytes) enforced
- [ ] Public key prefix (6 bytes) used in direct messages
- [ ] Expected ACK code received in `RESP_CODE_SENT`
- [ ] `PUSH_CODE_SEND_CONFIRMED` arrives after message delivery
- [ ] Round-trip time is reasonable (<10 seconds typically)

### Message Receiving Testing

- [ ] Contact message received and displayed
- [ ] Channel message received and displayed
- [ ] Signed message shows original author, not room
- [ ] `PUSH_CODE_MSG_WAITING` triggers message fetch
- [ ] Multiple messages fetched from queue in sequence
- [ ] `RESP_CODE_NO_MORE_MESSAGES` stops fetch loop
- [ ] Offline messages queued (up to 16) and delivered later
- [ ] Message timestamps are correct (UTC epoch seconds)

### Error Handling Testing

- [ ] `ERR_CODE_NOT_FOUND` when room contact missing
- [ ] `ERR_CODE_NOT_FOUND` resolved by adding contact
- [ ] Login timeout handled gracefully
- [ ] Message send timeout detected
- [ ] Queue overflow handled (oldest messages dropped)
- [ ] Clock drift detected and corrected
- [ ] Invalid message format doesn't crash app

---

## Glossary

**ACK (Acknowledgement)**: Confirmation packet sent by recipient to prove message delivery

**Companion Radio**: The MeshCore hardware device that handles LoRa radio communication

**Contact**: An entity in the mesh network (person, repeater, or room) with a 32-byte public key

**Direct Message**: Message sent point-to-point to a specific contact using their public key prefix

**Channel Message**: Broadcast message sent flood-mode to all nodes listening to a channel

**Epoch Seconds**: Unix timestamp (seconds since 1970-01-01 00:00:00 UTC)

**Flood Mode**: Routing where message is rebroadcast by all nodes to cover entire network

**Little Endian**: Byte order where least significant byte comes first (used for all integers)

**Public Key Prefix**: First 6 bytes of a contact's 32-byte Ed25519 public key

**Room**: A server contact (ADV_TYPE_ROOM) that provides persistent message storage

**sync_since**: Timestamp used by rooms to determine which messages to push to client

**TAG**: Random unique identifier used to match requests with responses

---

## Version History

- **v1.0** (2025-01-14): Initial documentation based on MeshCore firmware v1.9.1

---

## Credits

This guide is based on analysis of the MeshCore firmware source code:
- MeshCore firmware: https://github.com/meshcore-dev/meshcore
- Firmware version: v1.9.1 (firmware code 7, build date: 2 Oct 2025)
- Protocol specification: Derived from C++ source code analysis

For questions or corrections, please refer to the source code comments.
