# MeshCore Public Channel Message Structure & Detection Research

## 1. Public Channel Message Creation Flow

### 1.1 Message Generation (BaseChatMesh::sendGroupMessage)

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/helpers/BaseChatMesh.cpp` (lines 379-398)

```cpp
bool BaseChatMesh::sendGroupMessage(uint32_t timestamp, 
                                     mesh::GroupChannel& channel, 
                                     const char* sender_name, 
                                     const char* text, 
                                     int text_len) {
  uint8_t temp[5+MAX_TEXT_LEN+32];
  
  // Step 1: Add timestamp (4 bytes, little-endian)
  memcpy(temp, &timestamp, 4);
  
  // Step 2: Add txt_type flag (1 byte) - 0 = TXT_TYPE_PLAIN
  temp[4] = 0;
  
  // Step 3: Format message as "sender_name: message_text"
  sprintf((char *)&temp[5], "%s: ", sender_name);
  char *ep = strchr((char *)&temp[5], 0);
  int prefix_len = ep - (char *)&temp[5];
  
  if (text_len + prefix_len > MAX_TEXT_LEN) 
    text_len = MAX_TEXT_LEN - prefix_len;
  memcpy(ep, text, text_len);
  ep[text_len] = 0;
  
  // Step 4: Create encrypted packet
  auto pkt = createGroupDatagram(PAYLOAD_TYPE_GRP_TXT, channel, temp, 5 + prefix_len + text_len);
  if (pkt) {
    sendFlood(pkt);
    return true;
  }
  return false;
}
```

**Key Points:**
- Unencrypted data format: `[4-byte timestamp][1-byte txt_type][variable "name: text"]`
- txt_type = 0x00 for plain text
- Message includes sender name in plaintext
- No message ID or checksum in plaintext data

### 1.2 Packet Encryption (Mesh::createGroupDatagram)

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/Mesh.cpp` (lines 509-527)

```cpp
Packet* Mesh::createGroupDatagram(uint8_t type, const GroupChannel& channel, 
                                  const uint8_t* data, size_t data_len) {
  if (!(type == PAYLOAD_TYPE_GRP_TXT || type == PAYLOAD_TYPE_GRP_DATA)) 
    return NULL;
  if (data_len + 1 + CIPHER_BLOCK_SIZE-1 > MAX_PACKET_PAYLOAD) 
    return NULL;

  Packet* packet = obtainNewPacket();
  if (packet == NULL) return NULL;
  
  packet->header = (type << PH_TYPE_SHIFT);  // ROUTE_TYPE_* set later
  
  int len = 0;
  // Step 1: Add channel hash (1 byte)
  memcpy(&packet->payload[len], channel.hash, PATH_HASH_SIZE);
  len += PATH_HASH_SIZE;
  
  // Step 2: Encrypt plaintext data + add MAC
  len += Utils::encryptThenMAC(channel.secret, &packet->payload[len], 
                              data, data_len);
  
  packet->payload_len = len;
  return packet;
}
```

**Key Points:**
- Payload structure: `[1-byte channel_hash][2-byte MAC][16+ bytes encrypted data]`
- PATH_HASH_SIZE = 1 byte
- CIPHER_MAC_SIZE = 2 bytes (V1 protocol)
- CIPHER_BLOCK_SIZE = 16 bytes (AES128)
- Uses AES128-ECB encryption with HMAC-SHA256 truncated to 2 bytes

### 1.3 Encryption Algorithm (Utils::encryptThenMAC)

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/Utils.cpp` (lines 63-72)

```cpp
int Utils::encryptThenMAC(const uint8_t* shared_secret, uint8_t* dest, 
                          const uint8_t* src, int src_len) {
  // Step 1: Encrypt plaintext
  int enc_len = encrypt(shared_secret, dest + CIPHER_MAC_SIZE, src, src_len);
  
  // Step 2: Calculate HMAC-SHA256 over ciphertext
  SHA256 sha;
  sha.resetHMAC(shared_secret, PUB_KEY_SIZE);
  sha.update(dest + CIPHER_MAC_SIZE, enc_len);
  sha.finalizeHMAC(shared_secret, PUB_KEY_SIZE, dest, CIPHER_MAC_SIZE);
  
  return CIPHER_MAC_SIZE + enc_len;
}
```

**Encryption Details:**
- Plaintext padded with zero bytes to 16-byte block boundary
- AES128 in ECB mode (Electronic Code Book)
- HMAC-SHA256 truncated to 2 bytes
- Order: HMAC-SHA256(SHA256_HMAC(shared_secret, ciphertext)) -> 2 bytes
- Shared secret = channel.secret (pre-shared key for the channel)

### 1.4 Complete Wire Format for Group Message

```
[1 byte]    = packet header (type=0x05 PAYLOAD_TYPE_GRP_TXT, route type)
[1 byte]    = channel_hash (identifies which channel)
[2 bytes]   = MAC (HMAC-SHA256 truncated to 2 bytes)
[16+ bytes] = AES128 encrypted data:
  [4 bytes]    = timestamp (little-endian)
  [1 byte]     = txt_type (0x00 for plain)
  [variable]   = "sender_name: message_text"
  [0-15 bytes] = zero padding to reach 16-byte boundary
```

**Example for "Alice: Hello":**
```
Plaintext (13 bytes before padding):
  00 01 02 03   <- timestamp (example)
  00            <- txt_type = 0
  41 6C 69 63 65 3A 20 48 65 6C 6C 6F  <- "Alice: Hello"

After padding to 16 bytes:
  00 01 02 03 00 41 6C 69 63 65 3A 20 48 65 6C 6C 6F

After AES128 encryption (16 bytes):
  [16 random-looking bytes]

Final packet:
  [header] [channel_hash] [2-byte MAC] [16-byte ciphertext]
```

---

## 2. Packet Reception & Decryption Flow

### 2.1 Receiving Group Messages (Mesh::onRecvPacket)

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/Mesh.cpp` (lines 196-220)

```cpp
case PAYLOAD_TYPE_GRP_TXT: {
  int i = 0;
  uint8_t channel_hash = pkt->payload[i++];  // Extract 1-byte hash
  
  uint8_t* macAndData = &pkt->payload[i];    // Points to MAC + encrypted data
  
  if (i + 2 >= pkt->payload_len) {
    // incomplete data
  } else if (!_tables->hasSeen(pkt)) {       // Check if we've already processed this
    // Search for all matching channels
    GroupChannel channels[2];
    int num = searchChannelsByHash(&channel_hash, channels, 2);
    
    // Try to decrypt with each matching channel
    for (int j = 0; j < num; j++) {
      uint8_t data[MAX_PACKET_PAYLOAD];
      // Verify MAC, then decrypt
      int len = Utils::MACThenDecrypt(channels[j].secret, data, 
                                      macAndData, pkt->payload_len - i);
      if (len > 0) {  // MAC verified - success!
        onGroupDataRecv(pkt, pkt->getPayloadType(), channels[j], data, len);
        break;
      }
    }
    action = routeRecvPacket(pkt);
  }
  break;
}
```

### 2.2 Processing Decrypted Group Data (BaseChatMesh::onGroupDataRecv)

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/helpers/BaseChatMesh.cpp` (lines 298-310)

```cpp
void BaseChatMesh::onGroupDataRecv(mesh::Packet* packet, uint8_t type, 
                                   const mesh::GroupChannel& channel, 
                                   uint8_t* data, size_t len) {
  uint8_t txt_type = data[4];  // Extract txt_type from decrypted data
  
  if (type == PAYLOAD_TYPE_GRP_TXT && len > 5 && (txt_type >> 2) == 0) {
    uint32_t timestamp;
    memcpy(&timestamp, data, 4);  // Extract timestamp
    
    // Null-terminate the message
    data[len] = 0;
    
    // Notify UI
    onChannelMessageRecv(channel, packet, timestamp, 
                        (const char *)&data[5]);  // Pass message text
  }
}
```

---

## 3. Packet Deduplication & Matching Mechanism

### 3.1 Packet Hash Calculation

File: `/Users/dz0ny/meshcore-sar/MeshCore/src/Packet.cpp` (lines 17-26)

```cpp
void Packet::calculatePacketHash(uint8_t* hash) const {
  SHA256 sha;
  uint8_t t = getPayloadType();
  sha.update(&t, 1);
  
  // Special handling for TRACE packets
  if (t == PAYLOAD_TYPE_TRACE) {
    sha.update(&path_len, sizeof(path_len));
  }
  
  // Hash includes payload type + entire payload
  sha.update(payload, payload_len);
  sha.finalize(hash, MAX_HASH_SIZE);  // Truncate to 8 bytes
}
```

**Hash = SHA256(payload_type || full_payload) -> 8 bytes**

### 3.2 Duplicate Detection (MeshTables::hasSeen)

The `hasSeen()` function maintains a table of recently seen packets:

- When we **send** a packet: `_tables->hasSeen(packet)` marks it as seen
- When we **receive** a packet: check `!_tables->hasSeen(pkt)` to avoid reprocessing
- Prevents duplicate processing via different network paths

**Implementation in Mesh::sendFlood (line 600):**
```cpp
_tables->hasSeen(packet); // mark this packet as already sent in case 
                          // it is rebroadcast back to us
```

**Implementation in Mesh::sendDirect (line 633):**
```cpp
_tables->hasSeen(packet); // mark this packet as already sent in case 
                          // it is rebroadcast back to us
```

---

## 4. Echo Detection: Can We Match Sent vs Received Packets?

### 4.1 What Makes a Packet Unique?

**Encrypted packets (the wire format) are NOT directly matchable:**
- MAC uses HMAC-SHA256 truncated to 2 bytes - collision resistance but NOT deterministic
- Ciphertext appears random due to AES128-ECB
- Each encryption run produces different ciphertext (due to random key derivation?)

**Wait - actually they ARE the same:**
- AES128-ECB is deterministic: same plaintext + key = same ciphertext
- HMAC-SHA256 is deterministic: same data + key = same MAC
- **Therefore: Same plaintext + same channel secret = identical encrypted packet**

### 4.2 How to Match Sent vs Received

```
Sent packet generation:
  1. User sends: "Alice: Hello World"
  2. Timestamp T is captured
  3. Plaintext: [T || 0x00 || "Alice: Hello World"]
  4. Channel secret S is used
  5. AES128(S, plaintext) -> ciphertext C
  6. MAC = HMAC-SHA256(S, C) -> M
  7. Packet = [channel_hash || M || C]

If the same packet echoes back:
  - Exact same plaintext
  - Exact same channel secret
  - Exact same AES128 result
  - Exact same MAC
  - Exact same final packet
```

### 4.3 Matching Strategy

**Option 1: Full Packet Comparison (Strongest)**
```
Store sent packet payload:
  sent_payload = [channel_hash || MAC || ciphertext]

When receive PAYLOAD_TYPE_GRP_TXT:
  if (received_payload == sent_payload) {
    // This is OUR message echoed back!
    // Someone received and rebroadcast it
  }
```

**Option 2: Payload Hash Matching**
```
Calculate hash:
  sent_hash = SHA256(PAYLOAD_TYPE_GRP_TXT || full_payload) -> 8 bytes

The mesh already does this for deduplication!
  Packet::calculatePacketHash() is used in MeshTables::hasSeen()

If packet hash matches = guaranteed same packet
```

**Option 3: Plaintext Content Matching (Weakest)**
```
Store plaintext:
  timestamp + "Alice: Hello World"

When receive decrypted plaintext:
  if (timestamp + sender_name + text) matches {
    // Likely same message
    // But doesn't prove it came from us (collision risk)
  }
```

### 4.4 Matching Challenges & Solutions

| Challenge | Issue | Solution |
|-----------|-------|----------|
| **Timestamp uniqueness** | Same timestamp in plaintext | Use `getRTCClock()->getCurrentTimeUnique()` when sending - increases counter if time doesn't advance |
| **Sender name collision** | Multiple "Alice"s in mesh | Combine timestamp + sender name + text content for match |
| **Text content match** | Same text sent by different user | Timestamp makes it unique (getRTCClock()->getCurrentTimeUnique()) |
| **Encrypted packet change** | Doesn't change if plaintext unchanged | AES128-ECB is deterministic - if plaintext same, ciphertext same |
| **MAC truncation** | 2-byte MAC seems short | HMAC-SHA256 with shared secret - same data = same MAC, truncation doesn't affect determinism |

---

## 5. Flutter App - Packet Interception Points

### 5.1 BLE Response Handler (ble_response_handler.dart)

File: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/ble/ble_response_handler.dart`

```dart
void _onDataReceived(List<int> data) {
  // All RX data comes here
  // Packets are parsed and routed to frame_parser
  
  // Store packet logs for debugging:
  final log = BlePacketLog(
    timestamp: DateTime.now(),
    direction: PacketDirection.incoming,
    rawData: Uint8List.fromList(data),
    responseCode: responseCode,
    decodedInfo: decodedInfo,
  );
  _packetLogs.add(log);
}
```

**Access point for intercepting raw packets:**
- All RX data (including echoed messages) flows through `_onDataReceived()`
- Raw packet data is stored in `_packetLogs`
- Can extract and compare encrypted payloads here

### 5.2 Frame Parser Integration

File: `/Users/dz0ny/meshcore-sar/meshcore_sar_app/lib/services/protocol/frame_parser.dart`

The frame parser processes:
- PUSH_CODE values
- Response codes
- Extracts message content from decrypted payloads

---

## 6. Implementation Strategy for Echo Detection

### 6.1 Store Sent Messages

```dart
// In MessagesProvider or new EchoDetectionService
class SentMessageRecord {
  final DateTime sentTime;
  final Uint8List encryptedPayload;  // [channel_hash || MAC || ciphertext]
  final String plaintext;             // "Alice: Hello"
  final uint32_t timestamp;           // From packet
  final uint8_t channelHash;
  final Uint8List mac;               // 2 bytes
  final Uint8List ciphertext;        // 16+ bytes
  
  String get key => '${sentTime.millisecondsSinceEpoch}_${plaintext.hashCode}';
}
```

### 6.2 Intercept Sent Packets

In `meshcore_ble_service.dart`, before sending:

```dart
// When sendChannelMessage() is called
Future<void> sendChannelMessage(String channelName, String messageText) async {
  // Create message record
  final record = SentMessageRecord(
    sentTime: DateTime.now(),
    plaintext: messageText,
    // ... other fields
  );
  
  // Store for echo detection
  _sentMessages.add(record);
  
  // Send via BLE
  // The BLE layer will encrypt and generate the final packet
  // We need to intercept AFTER encryption
}
```

**Better approach: Intercept at frame builder level**

In `frame_builder.dart`, capture the encrypted payload:

```dart
Uint8List buildChannelMessage(
  String channelName,
  String senderName,
  String messageText,
  Uint8List channelSecret,
  Uint8List channelHash,
) {
  // Existing build logic...
  final encryptedPayload = [
    ...channelHash,
    ...mac,
    ...ciphertext,
  ];
  
  // Store for echo detection
  _sentPackets.add({
    'timestamp': sentTime,
    'payload': encryptedPayload,
    'plaintext': messageText,
  });
  
  return Uint8List.fromList(encryptedPayload);
}
```

### 6.3 Detect Echo in Response Handler

In `ble_response_handler.dart`, when receiving PAYLOAD_TYPE_GRP_TXT:

```dart
void _handleGroupMessage(Uint8List payload) {
  // payload = [channel_hash || MAC || ciphertext]
  
  // Check if this matches any sent message
  for (var sent in _sentPackets) {
    if (listEquals(sent['payload'], payload)) {
      // ECHO DETECTED!
      print('🔄 ECHO: Our message was rebroadcast by other node!');
      _echoDetectionCallbacks.forEach((cb) => cb(sent['plaintext']));
      return;
    }
  }
  
  // Not an echo - process normally
  _processNewGroupMessage(payload);
}
```

### 6.4 Key Insight: Timing

The echo will arrive **at different times**:
- **Sent**: T=0ms
- **Echo received**: T=100-5000ms (depending on network/hops)
- Time gap confirms it's an echo, not just local reflection

---

## 7. Constants Reference

From `/Users/dz0ny/meshcore-sar/MeshCore/src/MeshCore.h`:

```cpp
#define PUB_KEY_SIZE        32
#define CIPHER_KEY_SIZE     16
#define CIPHER_BLOCK_SIZE   16
#define CIPHER_MAC_SIZE      2    // V1 protocol, truncated HMAC-SHA256
#define PATH_HASH_SIZE       1    // Channel hash size
#define MAX_PACKET_PAYLOAD  184   // Maximum payload in a packet
#define MAX_TEXT_LEN        (10*CIPHER_BLOCK_SIZE)  // 160 bytes
```

Payload type codes:
```cpp
#define PAYLOAD_TYPE_GRP_TXT     0x05    // Group text message
#define PAYLOAD_TYPE_ADVERT      0x04    // Advertisement
#define PAYLOAD_TYPE_TXT_MSG     0x02    // Direct text message
```

---

## 8. Packet Structure Summary

### 8.1 Wire Format (Full Packet)

```
[1 byte]        PACKET HEADER
                ├─ [2 bits] Route type (0=FLOOD+TRANSPORT, 1=FLOOD, 2=DIRECT, 3=DIRECT+TRANSPORT)
                ├─ [4 bits] Payload type (0x05 for GRP_TXT)
                └─ [2 bits] Payload version (0=V1)

[0-4 bytes]     TRANSPORT CODES (optional, only if route type = 0 or 3)

[1 byte]        PATH_LEN (or omitted for flood mode)

[0-64 bytes]    PATH (route information)

[1+ bytes]      PAYLOAD (encrypted message)
                ├─ [1 byte]   Channel hash
                ├─ [2 bytes]  MAC (HMAC-SHA256 truncated)
                └─ [16+ bytes] AES128 encrypted data
```

### 8.2 Plaintext Structure (Inside Encryption)

```
[4 bytes]       TIMESTAMP (uint32_t, little-endian)
[1 byte]        TXT_TYPE (0=plain, 1=CLI_DATA, 2=signed)
[variable]      MESSAGE ("sender: text")
[0-15 bytes]    ZERO PADDING (to reach 16-byte boundary)
```

---

## 9. Conclusion: Echo Detection Feasibility

### Can We Detect Our Own Broadcast Echo?

**YES - With High Confidence**

**Methods:**
1. **Full Payload Matching (Recommended)**
   - Store encrypted payload `[channel_hash || MAC || ciphertext]` after sending
   - Compare received encrypted payloads
   - 100% accurate if payload matches exactly
   - No false positives due to deterministic encryption

2. **Plaintext + Timestamp Matching**
   - Use `getRTCClock()->getCurrentTimeUnique()` to ensure unique timestamp
   - Store plaintext: `"sender_name: message_text"` + timestamp
   - Match against decrypted received messages
   - Very high confidence (timestamp uniqueness)

3. **Packet Hash Matching**
   - Calculate `SHA256(PAYLOAD_TYPE_GRP_TXT || payload) -> 8 bytes`
   - Store sent packet hash
   - Compare with received packet hash
   - Collision probability: negligible

### Why It Works:
- AES128-ECB is **deterministic**: same plaintext + key = identical ciphertext
- HMAC-SHA256 is **deterministic**: same data + key = identical MAC
- Timestamp uniqueness prevents collisions from same sender

### When Echo Occurs:
- Another node receives our packet
- Rebroadcasts it (forwarding/relaying)
- We receive it back via different path
- Encrypted payload is **identical** to what we sent

### Implementation Effort:
- **Low**: Store 18-50 bytes per sent message (hash + payload subset)
- **Fast**: Binary comparison or hash lookup
- **Reliable**: No dependencies on network topology or timing

