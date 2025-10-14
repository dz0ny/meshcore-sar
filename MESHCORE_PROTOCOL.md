# MeshCore Protocol Specification

Complete protocol documentation extracted from [MeshCore C++ implementation](https://github.com/meshcore-dev/MeshCore) and [meshcore.js](https://github.com/meshcore-dev/meshcore.js).

## Overview

MeshCore is a mesh networking protocol designed for low-power, long-range communication using LoRa radio and BLE connectivity. This document describes two distinct protocols:

1. **Mesh Packet Protocol** - Complex routing protocol for mesh network communication
   - Supports flood and direct routing
   - End-to-end encryption with Ed25519/AES-128
   - Maximum payload: 184 bytes
   - Used for device-to-device communication over LoRa

2. **BLE Command Protocol** - Simple command/response protocol for local device control
   - Nordic UART Service (NUS) profile
   - Commands: get contacts, send messages, request telemetry
   - Used for smartphone app ↔ MeshCore device communication

**Key Features:**
- End-to-end encryption (AES-128-CTR)
- Digital signatures (Ed25519)
- Advertisement-based node discovery
- Group messaging support
- Telemetry data (GPS, battery, temperature)
- Anonymous messaging with forward secrecy

## Table of Contents
1. [Protocol Constants](#protocol-constants)
2. [Packet Structure](#packet-structure)
3. [Header Encoding](#header-encoding)
4. [Payload Types](#payload-types)
   - [Payload Structures by Type](#payload-structures-by-type)
   - [Advertisement App Data Format](#advertisement-app-data-format)
5. [Route Types](#route-types)
6. [Cryptography](#cryptography)
7. [Binary Serialization](#binary-serialization)
8. [Validation Rules](#validation-rules)
9. [Special Features](#special-features)
10. [JavaScript Implementation Notes](#javascript-implementation-notes)
11. [BLE Transport Layer](#ble-transport-layer)

---

## Protocol Constants

### Size Limits

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX_PACKET_PAYLOAD` | 184 bytes | Maximum payload data size |
| `MAX_PATH_SIZE` | 64 bytes | Maximum routing path size |
| `MAX_TRANS_UNIT` | 255 bytes | Maximum transmission unit |
| `MAX_ADVERT_DATA_SIZE` | 32 bytes | Maximum advertisement data |
| `MAX_HASH_SIZE` | 8 bytes | Maximum hash size for routing |
| `PATH_HASH_SIZE` | 1 byte | Path hash size (V1) |

### Cryptographic Sizes

| Constant | Value | Description |
|----------|-------|-------------|
| `PUB_KEY_SIZE` | 32 bytes | Ed25519 public key size |
| `PRV_KEY_SIZE` | 64 bytes | Ed25519 private key size |
| `SEED_SIZE` | 32 bytes | Key generation seed size |
| `SIGNATURE_SIZE` | 64 bytes | Ed25519 signature size |
| `CIPHER_KEY_SIZE` | 16 bytes | AES-128 key size |
| `CIPHER_BLOCK_SIZE` | 16 bytes | AES block size |
| `CIPHER_MAC_SIZE` | 2 bytes | Message authentication code size (V1) |

### Derived Constants

```cpp
MAX_COMBINED_PATH = MAX_PACKET_PAYLOAD - 2 - CIPHER_BLOCK_SIZE
                  = 184 - 2 - 16 = 166 bytes
```

---

## Packet Structure

### Member Variables

```cpp
class Packet {
    uint8_t header;                    // 1 byte: route type, payload type, version
    uint16_t payload_len;              // 2 bytes: payload data length
    uint16_t path_len;                 // 2 bytes: routing path length
    uint16_t transport_codes[2];       // 4 bytes: optional transport metadata
    uint8_t path[MAX_PATH_SIZE];       // 64 bytes: routing path buffer
    uint8_t payload[MAX_PACKET_PAYLOAD]; // 184 bytes: payload data buffer
    int8_t _snr;                       // 1 byte: signal-to-noise ratio (×4)
};
```

### Binary Layout (Wire Format)

```
+-------------------+--------+
| Header            | 1 byte |
+-------------------+--------+
| Transport Code[0] | 2 bytes| (conditional, only if ROUTE_TYPE_TRANSPORT_*)
| Transport Code[1] | 2 bytes|
+-------------------+--------+
| Path Length       | 1 byte |
+-------------------+--------+
| Path Data         | N bytes| (N = path_len, max 64)
+-------------------+--------+
| Payload Data      | M bytes| (M = payload_len, max 184)
+-------------------+--------+
```

**Total Packet Size Formula:**
```
size = 2 + path_len + payload_len + (hasTransportCodes() ? 4 : 0)
```

**Minimum Packet Size:** 2 bytes (header + path_len with empty path and payload)
**Maximum Packet Size:** 250 bytes (2 + 4 + 64 + 184)

---

## Header Encoding

The header byte encodes three fields using bit manipulation:

```
Bit Layout:
+--------+--------+--------+--------+--------+--------+--------+--------+
|  Ver1  |  Ver0  | Type3  | Type2  | Type1  | Type0  | Route1 | Route0 |
+--------+--------+--------+--------+--------+--------+--------+--------+
  Bit 7    Bit 6    Bit 5    Bit 4    Bit 3    Bit 2    Bit 1    Bit 0
```

### Encoding Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `PH_ROUTE_MASK` | 0x03 | Mask for route type (bits 0-1) |
| `PH_TYPE_SHIFT` | 2 | Left shift for payload type |
| `PH_TYPE_MASK` | 0x0F | Mask for payload type (4 bits) |
| `PH_VER_SHIFT` | 6 | Left shift for payload version |
| `PH_VER_MASK` | 0x03 | Mask for payload version (bits 6-7) |

### Encoding/Decoding Operations

**Encoding:**
```cpp
header = (route_type & PH_ROUTE_MASK) |
         ((payload_type & PH_TYPE_MASK) << PH_TYPE_SHIFT) |
         ((payload_ver & PH_VER_MASK) << PH_VER_SHIFT);
```

**Decoding:**
```cpp
route_type   = header & PH_ROUTE_MASK;
payload_type = (header >> PH_TYPE_SHIFT) & PH_TYPE_MASK;
payload_ver  = (header >> PH_VER_SHIFT) & PH_VER_MASK;
```

### Example Header Values

| Route | Type | Ver | Binary | Hex | Description |
|-------|------|-----|--------|-----|-------------|
| FLOOD | REQ  | V1  | 00000001 | 0x01 | Flood routed request, version 1 |
| DIRECT | TXT_MSG | V1 | 00001010 | 0x0A | Direct text message, version 1 |
| TRANSPORT_FLOOD | ACK | V1 | 00001100 | 0x0C | Flood ACK with transport codes |

---

## Payload Types

| Name | Value | Description | Use Case |
|------|-------|-------------|----------|
| `PAYLOAD_TYPE_REQ` | 0x00 | Request message | Command or query to peer |
| `PAYLOAD_TYPE_RESPONSE` | 0x01 | Response message | Reply to REQ packet |
| `PAYLOAD_TYPE_TXT_MSG` | 0x02 | Text message | User-to-user chat message |
| `PAYLOAD_TYPE_ACK` | 0x03 | Acknowledgment | Confirm packet receipt |
| `PAYLOAD_TYPE_ADVERT` | 0x04 | Advertisement | Node presence announcement |
| `PAYLOAD_TYPE_GRP_TXT` | 0x05 | Group text message | Multi-recipient text |
| `PAYLOAD_TYPE_GRP_DATA` | 0x06 | Group data | Multi-recipient binary data |
| `PAYLOAD_TYPE_ANON_REQ` | 0x07 | Anonymous request | Request without sender ID |
| `PAYLOAD_TYPE_PATH` | 0x08 | Path discovery | Route discovery/return |
| `PAYLOAD_TYPE_TRACE` | 0x09 | Trace packet | Network diagnostics |
| `PAYLOAD_TYPE_MULTIPART` | 0x0A | Multi-part message | Large message fragmentation |
| `PAYLOAD_TYPE_RAW_CUSTOM` | 0x0F | Raw custom data | Application-specific payload |

### Payload Type Categories

**Control Messages:**
- ACK, PATH, TRACE

**User Messages:**
- TXT_MSG, GRP_TXT

**Data Transfer:**
- REQ, RESPONSE, GRP_DATA, RAW_CUSTOM, MULTIPART

**Network Management:**
- ADVERT, ANON_REQ

### Payload Structures by Type

Each payload type has a specific binary structure. All encrypted payloads include a 2-byte MAC at the end.

#### PAYLOAD_TYPE_REQ (0x00)

**Structure:**
```
+-------------------+----------+
| Dest Hash         | 1 byte   | First byte of destination public key
| Src Hash          | 1 byte   | First byte of source public key
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Timestamp (variable length)
- Request blob (application-specific)

**Use Case:** Authenticated request from known sender to known recipient

---

#### PAYLOAD_TYPE_RESPONSE (0x01)

**Structure:**
```
+-------------------+----------+
| Dest Hash         | 1 byte   | First byte of destination public key
| Src Hash          | 1 byte   | First byte of source public key
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Timestamp (variable length)
- Response blob (application-specific)

**Use Case:** Reply to REQ or ANON_REQ packet

---

#### PAYLOAD_TYPE_TXT_MSG (0x02)

**Structure:**
```
+-------------------+----------+
| Dest Hash         | 1 byte   | First byte of destination public key
| Src Hash          | 1 byte   | First byte of source public key
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Timestamp (variable length)
- Text message (UTF-8 string)

**Use Case:** Person-to-person text messages

---

#### PAYLOAD_TYPE_ACK (0x03)

**Structure:**
```
+-------------------+----------+
| ACK Code          | N bytes  | Application-specific acknowledgment data
+-------------------+----------+
```

**No Encryption:** ACK packets are typically unencrypted

**Use Case:** Confirm receipt of packets, simple acknowledgments

---

#### PAYLOAD_TYPE_ADVERT (0x04)

**Structure:**
```
+-------------------+----------+
| Public Key        | 32 bytes | Ed25519 public key of advertiser
| Timestamp         | 4 bytes  | Unix timestamp (uint32, little-endian)
| App Data          | N bytes  | Application-specific advertisement data
| Signature         | 64 bytes | Ed25519 signature over above fields
+-------------------+----------+
```

**Minimum Size:** 100 bytes (32 + 4 + 0 + 64)
**Maximum Size:** 132 bytes (32 + 4 + 32 + 64) with MAX_ADVERT_DATA_SIZE

**Signature Verification:**
```cpp
// Build message to verify
message = public_key || timestamp || app_data

// Verify Ed25519 signature
bool valid = ed25519_verify(signature, message, public_key);
```

**Use Case:** Node presence announcement, identity broadcast, service discovery

### Advertisement App Data Format

The App Data field has a structured format for node advertisements:

**Binary Structure:**
```
+-------------------+----------+
| Flags             | 1 byte   | Type (4 bits) + Feature flags (4 bits)
| Latitude          | 4 bytes  | (Optional) int32 LE, divide by 10000
| Longitude         | 4 bytes  | (Optional) int32 LE, divide by 10000
| Battery           | 1 byte   | (Optional) percentage 0-100
| Temperature       | 1 byte   | (Optional) signed int8, degrees Celsius
| Name              | N bytes  | (Optional) null-terminated UTF-8 string
+-------------------+----------+
```

**Flags Byte Layout:**
```
Bit Layout:
+--------+--------+--------+--------+--------+--------+--------+--------+
|  Name  |  Temp  | Battery| LatLon | Type3  | Type2  | Type1  | Type0  |
+--------+--------+--------+--------+--------+--------+--------+--------+
  Bit 7    Bit 6    Bit 5    Bit 4    Bit 3    Bit 2    Bit 1    Bit 0
```

**Type Field (bits 0-3):**
```cpp
#define ADV_TYPE_NONE      0x00  // Unknown/undefined type
#define ADV_TYPE_CHAT      0x01  // User/team member node
#define ADV_TYPE_REPEATER  0x02  // Network repeater node
#define ADV_TYPE_ROOM      0x03  // Group chat room/channel
```

**Feature Flags (bits 4-7):**
```cpp
#define ADV_LATLON_MASK      0x10  // Bit 4: Latitude/Longitude present
#define ADV_BATTERY_MASK     0x20  // Bit 5: Battery level present
#define ADV_TEMPERATURE_MASK 0x40  // Bit 6: Temperature present
#define ADV_NAME_MASK        0x80  // Bit 7: Name string present
```

**Extracting Fields:**
```cpp
uint8_t flags = app_data[0];
uint8_t type = flags & 0x0F;
bool has_latlon = (flags & ADV_LATLON_MASK) != 0;
bool has_battery = (flags & ADV_BATTERY_MASK) != 0;
bool has_temp = (flags & ADV_TEMPERATURE_MASK) != 0;
bool has_name = (flags & ADV_NAME_MASK) != 0;
```

**Example App Data Parsing:**

```javascript
// Example 1: CHAT node with GPS and name
// Flags: 0x91 (CHAT | LATLON_MASK | NAME_MASK)
// = 10010001 binary
const flags = 0x91;
const type = flags & 0x0F;           // 0x01 = CHAT
const hasLatLon = flags & 0x10;      // true
const hasName = flags & 0x80;        // true

// Bytes: [0x91] [lat: 4B] [lon: 4B] [name: "Alice\0"]
// Total: 1 + 4 + 4 + 6 = 15 bytes

// Example 2: REPEATER with GPS, battery, and temp
// Flags: 0x72 (REPEATER | LATLON_MASK | BATTERY_MASK | TEMP_MASK)
const flags = 0x72;
const type = flags & 0x0F;           // 0x02 = REPEATER
const hasLatLon = flags & 0x10;      // true
const hasBattery = flags & 0x20;     // true
const hasTemp = flags & 0x40;        // true

// Bytes: [0x72] [lat: 4B] [lon: 4B] [battery: 1B] [temp: 1B]
// Total: 1 + 4 + 4 + 1 + 1 = 11 bytes

// Example 3: ROOM with only name
// Flags: 0x83 (ROOM | NAME_MASK)
const flags = 0x83;
const type = flags & 0x0F;           // 0x03 = ROOM
const hasName = flags & 0x80;        // true

// Bytes: [0x83] [name: "SAR Team Alpha\0"]
// Total: 1 + 15 = 16 bytes
```

**GPS Coordinate Encoding:**
```cpp
// Encoding (on device)
int32_t lat_encoded = (int32_t)(latitude * 10000.0);
int32_t lon_encoded = (int32_t)(longitude * 10000.0);

// Decoding (on receiver)
double latitude = lat_encoded / 10000.0;
double longitude = lon_encoded / 10000.0;

// Example: 46.0569°N, 14.5058°E
// Encoded: 460569, 145058
// 4 decimal places precision (~11m accuracy)
```

**Complete Parsing Example (JavaScript):**
```javascript
function parseAdvertAppData(appData) {
    const reader = new BufferReader(appData);
    const flags = reader.readByte();

    const type = flags & 0x0F;
    const result = { type };

    // Parse lat/lon if present
    if (flags & 0x10) {
        result.lat = reader.readInt32LE() / 10000.0;
        result.lon = reader.readInt32LE() / 10000.0;
    }

    // Parse battery if present
    if (flags & 0x20) {
        result.battery = reader.readByte();  // 0-100%
    }

    // Parse temperature if present
    if (flags & 0x40) {
        result.temperature = reader.readInt8();  // -128 to +127°C
    }

    // Parse name if present (remaining bytes)
    if (flags & 0x80) {
        result.name = reader.readString();  // null-terminated UTF-8
    }

    return result;
}
```

**Advertisement Frequency:**
- Typically broadcast every 30-60 seconds
- Can be triggered on-demand for discovery
- Should include timestamp to detect stale advertisements

**Security Considerations:**
1. **Always verify signature** before trusting advertisement data
2. **Check timestamp** to reject old/replayed advertisements
3. **Validate GPS coordinates** are within reasonable ranges
4. **Sanitize name strings** before display (max length, valid UTF-8)
5. **Rate limit** advertisement processing to prevent DoS

---

#### PAYLOAD_TYPE_GRP_TXT (0x05)

**Structure:**
```
+-------------------+----------+
| Channel Hash      | 1 byte   | First byte of group channel hash
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Timestamp (variable length)
- Message text in format: `"sender_name: message_text"`

**Security Note:** Unverified sender identity - anyone with the group key can send

**Use Case:** Group chat messages to a channel

---

#### PAYLOAD_TYPE_GRP_DATA (0x06)

**Structure:**
```
+-------------------+----------+
| Channel Hash      | 1 byte   | First byte of group channel hash
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Timestamp (variable length)
- Binary data blob (application-specific)

**Use Case:** Group data broadcast (telemetry, coordinates, binary files)

---

#### PAYLOAD_TYPE_ANON_REQ (0x07)

**Structure:**
```
+-------------------+----------+
| Dest Hash         | 1 byte   | First byte of destination public key
| Ephemeral Pub Key | 32 bytes | Temporary Ed25519 public key
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Minimum Size:** 35 bytes (1 + 32 + 2 + 0)

**Encrypted Data Contains:**
- Application-specific request data

**Key Derivation:**
- Recipient uses their private key + ephemeral public key to derive shared secret
- Sender discards ephemeral private key after sending (forward secrecy)

**Use Case:** Anonymous requests, forward-secret communications

---

#### PAYLOAD_TYPE_PATH (0x08)

**Structure:**
```
+-------------------+----------+
| Dest Hash         | 1 byte   | First byte of destination public key
| Src Hash          | 1 byte   | First byte of source public key
| MAC               | 2 bytes  | Message authentication code
| Encrypted Data    | N bytes  | AES-128-CTR encrypted payload
+-------------------+----------+
```

**Encrypted Data Contains:**
- Path data: sequence of node hashes showing discovered route
- Extra metadata (optional)

**Use Case:** Return discovered routing path to sender

---

#### PAYLOAD_TYPE_TRACE (0x09)

**Structure:**
```
+-------------------+----------+
| Trace Data        | N bytes  | Application-specific trace payload
+-------------------+----------+
```

**No Standard Format:** Application defines structure

**Common Usage:**
- Collecting SNR (signal-to-noise ratio) at each hop
- Measuring latency through network
- Network topology discovery
- Debugging routing issues

**Path Field:** Used to accumulate node IDs and SNR measurements as packet propagates

---

#### PAYLOAD_TYPE_RAW_CUSTOM (0x0F)

**Structure:**
```
+-------------------+----------+
| Custom Data       | N bytes  | Completely application-defined
+-------------------+----------+
```

**No Standard Format:** Application has full control over:
- Encryption scheme (or no encryption)
- Data encoding
- Protocol semantics

**Use Case:** Application-specific protocols, custom encryption, proprietary formats

---

### Hash Prefixes

Several payload types use 1-byte "hash" fields that represent the first byte of a 32-byte public key:

```cpp
uint8_t dest_hash = public_key[0];
```

**Purpose:**
- Quick filtering: nodes can ignore packets not addressed to them
- Space efficiency: 1 byte vs 32 bytes
- Collision rate: 1/256 (acceptable for mesh routing)

**Collision Handling:**
- When hash matches, validate full public key after decryption
- If decryption fails, packet was for a different node with same hash prefix

---

### Encrypted Payload Format

All encrypted payloads use this structure:

```
+-------------------+----------+
| Encrypted Data    | N bytes  | AES-128-CTR ciphertext
| MAC               | 2 bytes  | Authentication code (included in total payload_len)
+-------------------+----------+
```

**Decryption Process:**
1. Extract last 2 bytes as MAC
2. Verify MAC over encrypted data (bytes 0 to N-2)
3. If valid, decrypt using AES-128-CTR with derived cipher key
4. If invalid, silently discard packet

**Common Encrypted Data Structure:**
```
+-------------------+----------+
| Timestamp         | 4 bytes  | Unix timestamp (uint32) for replay protection
| Payload Data      | N bytes  | Application-specific data
+-------------------+----------+
```

---

## Route Types

| Name | Value | Description | Transport Codes |
|------|-------|-------------|-----------------|
| `ROUTE_TYPE_TRANSPORT_FLOOD` | 0x00 | Flood routing with metadata | Yes (4 bytes) |
| `ROUTE_TYPE_FLOOD` | 0x01 | Simple flood routing | No |
| `ROUTE_TYPE_DIRECT` | 0x02 | Direct peer-to-peer | No |
| `ROUTE_TYPE_TRANSPORT_DIRECT` | 0x03 | Direct with metadata | Yes (4 bytes) |

### Routing Behavior

**FLOOD Mode (0x01, 0x00):**
- Packet is retransmitted by all receiving nodes
- Path field accumulates node IDs as packet propagates
- Used for network-wide broadcasts and discovery
- Path prevents routing loops

**DIRECT Mode (0x02, 0x03):**
- Packet routed only through specified path
- Path field contains complete route to destination
- Used for established peer-to-peer connections
- More efficient than flood routing

**Transport Codes:**
- When present (types 0x00 and 0x03), add 4 bytes after header
- Two 16-bit unsigned integers for transport layer metadata
- Use cases: sequence numbers, retry counts, QoS flags

---

## Cryptography

### Encryption Scheme

**Algorithm:** AES-128-CTR with custom MAC
**Key Derivation:** ECDH using Ed25519 keys
**Authentication:** 2-byte MAC (CIPHER_MAC_SIZE)

### Shared Secret Calculation

```cpp
// Given: local private key (64 bytes), remote public key (32 bytes)
uint8_t shared_secret[32];
calcSharedSecret(local_prv_key, remote_pub_key, shared_secret);
```

### Packet Encryption Process

1. Calculate shared secret from sender private key and recipient public key
2. Generate cipher key from shared secret
3. Encrypt payload using AES-128-CTR
4. Calculate MAC over encrypted payload
5. Append MAC to encrypted data (total: payload_len + 2)

### Packet Decryption Process

1. Extract MAC from last 2 bytes of payload
2. Calculate expected MAC over encrypted data
3. Compare MACs (constant-time comparison required)
4. If MAC valid, decrypt payload using AES-128-CTR
5. If MAC invalid, discard packet

**Security Note:** MAC-then-decrypt pattern requires constant-time MAC comparison to prevent timing attacks.

### Digital Signatures

**Algorithm:** Ed25519
**Signature Size:** 64 bytes

Used for:
- Advertisement packet authentication
- Path discovery verification
- Identity proofs

---

## Binary Serialization

### writeTo() Method

Serializes packet to byte array:

```cpp
size_t writeTo(uint8_t* buffer, size_t buffer_size) {
    size_t offset = 0;

    // 1. Write header byte
    buffer[offset++] = header;

    // 2. Write transport codes (if present)
    if (hasTransportCodes()) {
        buffer[offset++] = (uint8_t)(transport_codes[0] & 0xFF);
        buffer[offset++] = (uint8_t)(transport_codes[0] >> 8);
        buffer[offset++] = (uint8_t)(transport_codes[1] & 0xFF);
        buffer[offset++] = (uint8_t)(transport_codes[1] >> 8);
    }

    // 3. Write path length
    buffer[offset++] = (uint8_t)path_len;

    // 4. Write path data
    memcpy(buffer + offset, path, path_len);
    offset += path_len;

    // 5. Write payload data
    memcpy(buffer + offset, payload, payload_len);
    offset += payload_len;

    return offset; // Total bytes written
}
```

### readFrom() Method

Deserializes packet from byte array:

```cpp
bool readFrom(const uint8_t* buffer, size_t buffer_size) {
    size_t offset = 0;

    // 1. Read header byte
    if (offset >= buffer_size) return false;
    header = buffer[offset++];

    // 2. Read transport codes (if present)
    if (hasTransportCodes()) {
        if (offset + 4 > buffer_size) return false;
        transport_codes[0] = buffer[offset] | (buffer[offset+1] << 8);
        offset += 2;
        transport_codes[1] = buffer[offset] | (buffer[offset+1] << 8);
        offset += 2;
    }

    // 3. Read path length
    if (offset >= buffer_size) return false;
    path_len = buffer[offset++];

    // 4. Validate path length
    if (path_len > MAX_PATH_SIZE) return false;
    if (offset + path_len > buffer_size) return false;

    // 5. Read path data
    memcpy(path, buffer + offset, path_len);
    offset += path_len;

    // 6. Calculate and validate payload length
    payload_len = buffer_size - offset;
    if (payload_len > MAX_PACKET_PAYLOAD) return false;

    // 7. Read payload data
    memcpy(payload, buffer + offset, payload_len);

    return true; // Success
}
```

---

## Validation Rules

### Packet Acceptance Criteria

A valid packet must satisfy:

1. **Header Validation:**
   - Route type ≤ 3 (valid route type)
   - Payload type ≤ 15 (4-bit field)
   - Payload version ≤ 3 (2-bit field)

2. **Path Validation:**
   - `path_len ≤ MAX_PATH_SIZE` (64 bytes)
   - Path data must not exceed buffer size

3. **Payload Validation:**
   - `payload_len ≤ MAX_PACKET_PAYLOAD` (184 bytes)
   - Payload data must not exceed buffer size
   - For encrypted packets: payload_len ≥ CIPHER_MAC_SIZE (2 bytes)

4. **Size Validation:**
   - Total packet size ≤ MAX_TRANS_UNIT (255 bytes)
   - Minimum size: 2 bytes (header + path_len)

5. **Cryptographic Validation (if encrypted):**
   - MAC must match calculated value
   - Decryption must succeed without errors

### Error Handling

**Invalid Packets:**
- Silently discarded (no error response)
- Logged for debugging if trace enabled

**Malformed Data:**
- `readFrom()` returns `false`
- Packet object left in undefined state
- Caller must not use packet after failed read

---

## Packet Hash Calculation

Used for duplicate detection and routing loop prevention:

```cpp
void calculatePacketHash(uint8_t* hash_out, size_t hash_len) {
    // Initialize SHA256
    SHA256 sha256;
    sha256.reset();

    // 1. Hash payload type
    uint8_t type = (header >> PH_TYPE_SHIFT) & PH_TYPE_MASK;
    sha256.update(&type, 1);

    // 2. Hash path length (only for TRACE packets)
    if (type == PAYLOAD_TYPE_TRACE) {
        uint8_t plen = (uint8_t)path_len;
        sha256.update(&plen, 1);
    }

    // 3. Hash payload data
    sha256.update(payload, payload_len);

    // 4. Finalize and copy to output
    uint8_t full_hash[32];
    sha256.finalize(full_hash, 32);
    memcpy(hash_out, full_hash, hash_len);
}
```

**Hash Properties:**
- Based on SHA256
- Configurable output length (typically MAX_HASH_SIZE = 8 bytes)
- Includes payload type and payload data
- TRACE packets include path_len to detect routing changes

---

## Protocol Version

**Current Version:** V1 (PAYLOAD_VER_1 = 0x00)

**Version Features:**
- V1: 2-byte MAC, 1-byte path hash
- V2-V4: Reserved for future use

**Version Compatibility:**
- Nodes must reject packets with unsupported versions
- Forward compatibility requires checking version before processing

---

## Implementation Notes

### Performance Considerations

**Buffer Management:**
- Pre-allocate packet buffers to avoid dynamic allocation
- Use stack allocation for temporary packets
- Pool frequently used packet objects

**Crypto Optimization:**
- Cache shared secrets for active connections
- Use hardware AES acceleration if available
- Batch MAC calculations when possible

**Routing Efficiency:**
- Maintain routing table cache for direct routes
- Limit flood packet retransmissions (hop count)
- Implement exponential backoff for retries

### Security Best Practices

1. **Always validate MAC** before decrypting
2. **Use constant-time comparison** for MAC validation
3. **Clear sensitive data** from memory after use
4. **Implement replay protection** using sequence numbers
5. **Rate limit** flood packets to prevent DoS attacks

### Interoperability

This specification is based on the [MeshCore C++ implementation](https://github.com/meshcore-dev/MeshCore) and is compatible with:

- MeshCore firmware (ESP32, nRF52, STM32)
- meshcore.js library
- This Flutter application

**Byte Order:** All multi-byte integers use **little-endian** encoding.

---

## Special Features

### Do Not Retransmit Flag

Packets can be marked to prevent retransmission:

```javascript
packet.markDoNotRetransmit();  // Sets header to 0xFF
if (packet.isMarkedDoNotRetransmit()) {
    // Don't retransmit this packet
}
```

**When to Use:**
- Packets already flooded to entire network
- Time-sensitive data that's no longer relevant
- Preventing routing loops in edge cases

**Implementation:** Header value of `0xFF` is reserved as a special marker

---

## JavaScript Implementation Notes

The JavaScript implementation (meshcore.js) provides a convenient API for packet parsing:

```javascript
// Parse packet from bytes
const packet = Packet.fromBytes(bytes);

// Access parsed header fields
console.log(packet.route_type_string);    // "FLOOD" or "DIRECT"
console.log(packet.payload_type_string);  // "TXT_MSG", "ADVERT", etc.
console.log(packet.payload_version);      // 0, 1, 2, or 3

// Parse payload based on type
const parsed = packet.parsePayload();
if (packet.payload_type === Packet.PAYLOAD_TYPE_ADVERT) {
    console.log(parsed.public_key);   // 32-byte Uint8Array
    console.log(parsed.timestamp);    // Unix timestamp
    console.log(parsed.app_data);     // Application data
}
```

**Supported Payload Parsers:**
- `PAYLOAD_TYPE_REQ` → `{ src, dest, encrypted }`
- `PAYLOAD_TYPE_RESPONSE` → `{ src, dest }`
- `PAYLOAD_TYPE_TXT_MSG` → `{ src, dest }`
- `PAYLOAD_TYPE_ACK` → `{ ack_code }`
- `PAYLOAD_TYPE_ADVERT` → `{ public_key, timestamp, app_data }`
- `PAYLOAD_TYPE_ANON_REQ` → `{ src, dest }` (src is 32-byte ephemeral key)
- `PAYLOAD_TYPE_PATH` → `{ src, dest }`

**Note:** The JavaScript parsers extract the unencrypted header fields only. Encrypted data decryption requires implementing the crypto layer.

---

## BLE Transport Layer

MeshCore packets are transported over Bluetooth Low Energy (BLE) using the Nordic UART Service (NUS) profile.

### BLE Service Specification

**Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` (Nordic UART Service)

**Characteristics:**

| Characteristic | UUID | Properties | Description |
|----------------|------|------------|-------------|
| RX | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | Write, Write Without Response | Client → Device (commands) |
| TX | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | Notify | Device → Client (responses) |

### BLE vs Mesh Protocol

**Important Distinction:**

The BLE transport layer uses a **different protocol** than the mesh packet protocol documented above.

**BLE Protocol:**
- Simple command/response format
- Used for **local device communication** only
- Commands to query device state, send messages, request data
- Not forwarded through mesh network

**Mesh Protocol:**
- Complex packet structure with routing
- Used for **mesh network communication**
- Packets can be flooded or routed through multiple hops
- Carries encrypted user data

### BLE Command Protocol

Commands sent over BLE RX characteristic:

| Command | Code | Description | Parameters |
|---------|------|-------------|------------|
| Get Contacts | `0x04` | Request list of known contacts | None |
| Send Message | `0x02` | Send text message | 32B pubkey, 2B length, text |
| Request Telemetry | `0x27` (39) | Request telemetry data | 32B contact pubkey |

### BLE Response Protocol

Responses received over BLE TX characteristic:

| Response | Code | Description | Structure |
|----------|------|-------------|-----------|
| Contact Info | `0x03` | Contact details | 32B pubkey, 1B type, 64B name, 4B lat, 4B lon |
| Message Received | `0x07` | Incoming message | 1B type, 4B src, 4B dest, 2B length, text |
| Telemetry | `0x8B` (139) | Cayenne LPP telemetry | 4B pubkey prefix, LPP data |

### BLE Message Format Examples

**Get Contacts Request:**
```
RX: [0x04]
Total: 1 byte
```

**Send Message Request:**
```
RX: [0x02] [32 bytes: recipient pubkey] [2 bytes: length] [N bytes: UTF-8 text]
Example (hex): 02 A1B2C3D4...pubkey...E5F6 0B00 48656C6C6F20576F726C64
                ^cmd  ^----- 32 bytes -----^   ^len  ^----- "Hello World" -----^
Total: 1 + 32 + 2 + N bytes
```

**Contact Response:**
```
TX: [0x03] [32 bytes: pubkey] [1 byte: type] [64 bytes: name] [4 bytes: lat] [4 bytes: lon]
Type: 0=none, 1=chat, 2=repeater, 3=room
Lat/Lon: int32 little-endian, divide by 10000 for degrees
Total: 105 bytes
```

**Message Received:**
```
TX: [0x07] [1 byte: msg type] [4 bytes: src prefix] [4 bytes: dest prefix] [2 bytes: length] [N bytes: text]
Msg Type: 0=contact, 1=channel
Total: 1 + 1 + 4 + 4 + 2 + N bytes
```

**Telemetry Response:**
```
TX: [0x8B] [4 bytes: contact pubkey prefix] [N bytes: Cayenne LPP payload]
Total: 5 + N bytes
```

### Cayenne LPP Format (Telemetry)

Cayenne Low Power Payload format used for telemetry data:

**Structure:**
```
[Channel] [Type] [Data...]
```

**Supported Types:**

| Type | Code | Data Format | Description |
|------|------|-------------|-------------|
| GPS | `0x88` (136) | 12 bytes | lat(4B) + lon(4B) + alt(4B), divide lat/lon by 10000, alt by 100 |
| Temperature | `0x67` (103) | 2 bytes | int16 LE, divide by 10 for °C |
| Analog Input | `0x02` | 2 bytes | uint16 LE, divide by 100 for volts (battery) |

**Example Telemetry Packet:**
```
Channel 1, GPS: [01] [88] [A0 C2 06 00] [30 67 02 00] [2C 01 00 00]
                ^ch  ^type ^-- lat --^  ^-- lon --^  ^-- alt --^
Decoded: lat=443040/10000=44.304°, lon=157488/10000=15.7488°, alt=300/100=3.00m

Channel 2, Temp: [02] [67] [0E 01]
                 ^ch  ^type ^-value-^
Decoded: temp=270/10=27.0°C

Channel 3, Battery: [03] [02] [90 01]
                    ^ch  ^type ^-value-^
Decoded: battery=400/100=4.00V
```

### BLE vs Mesh Packet Flow

```
┌─────────────┐                    ┌──────────────┐
│   Flutter   │ ← BLE Commands  →  │  MeshCore    │
│     App     │    (Simple)         │   Device     │
└─────────────┘                    └──────┬───────┘
                                           │
                                           │ Mesh Packets
                                           │ (Complex)
                                           │
                                   ┌───────▼───────┐
                                   │   LoRa/Radio  │
                                   │     Mesh      │
                                   │   Network     │
                                   └───────────────┘
```

**Data Flow Example:**

1. App sends "Get Contacts" (BLE command 0x04)
2. Device responds with Contact Info (BLE response 0x03) for each contact
3. User sends message via app (BLE command 0x02)
4. Device creates **mesh packet** (PAYLOAD_TYPE_TXT_MSG) and broadcasts on LoRa
5. Remote device receives mesh packet, forwards to its BLE-connected app
6. Remote app receives message (BLE response 0x07)

### Implementation Notes

**BLE MTU Limitations:**
- Default MTU: 23 bytes (20 bytes usable data)
- Extended MTU: up to 512 bytes (device dependent)
- Long messages may require fragmentation

**Buffering:**
- BLE TX notifications arrive in chunks
- App must buffer partial packets until complete
- Use packet length headers to detect boundaries

**Connection Management:**
- Maintain single BLE connection to MeshCore device
- Device acts as BLE peripheral (server)
- App acts as BLE central (client)
- Reconnect automatically on disconnection

**Flutter Implementation:**
See `lib/services/meshcore_ble_service.dart` for complete BLE protocol implementation.

---

## References

### Source Code
- [MeshCore GitHub Repository](https://github.com/meshcore-dev/MeshCore) - C++ firmware implementation
- [Packet.h](https://github.com/meshcore-dev/MeshCore/blob/main/src/Packet.h) - C++ packet class definition
- [Packet.cpp](https://github.com/meshcore-dev/MeshCore/blob/main/src/Packet.cpp) - C++ packet serialization
- [Mesh.h](https://github.com/meshcore-dev/MeshCore/blob/main/src/Mesh.h) - C++ mesh networking
- [Mesh.cpp](https://github.com/meshcore-dev/MeshCore/blob/main/src/Mesh.cpp) - C++ routing implementation
- [MeshCore.h](https://github.com/meshcore-dev/MeshCore/blob/main/src/MeshCore.h) - C++ protocol constants
- [meshcore.js Packet.js](https://github.com/meshcore-dev/meshcore.js) - JavaScript implementation

### Documentation
- This document provides implementation details for the MeshCore SAR Flutter application
- Compatible with MeshCore firmware v1.x protocol specification

---

**Document Version:** 1.1
**Last Updated:** 2025-10-14
**Protocol Version:** V1
