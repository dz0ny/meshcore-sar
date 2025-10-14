# MeshCore Quick Reference Card

Quick lookup for MeshCore protocol constants and structures.

## BLE Service (App ↔ Device)

**Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`
- **RX:** `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` (Write - Commands)
- **TX:** `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` (Notify - Responses)

### BLE Commands (RX)

| Code | Command | Format |
|------|---------|--------|
| `0x04` | Get Contacts | `[0x04]` |
| `0x02` | Send Message | `[0x02][32B pubkey][2B len][text]` |
| `0x27` | Get Telemetry | `[0x27][32B pubkey]` |

### BLE Responses (TX)

| Code | Response | Format |
|------|----------|--------|
| `0x03` | Contact Info | `[0x03][32B pubkey][1B type][64B name][4B lat][4B lon]` |
| `0x07` | Message | `[0x07][1B type][4B src][4B dest][2B len][text]` |
| `0x8B` | Telemetry | `[0x8B][4B pubkey][Cayenne LPP data]` |

---

## Mesh Packet Structure (LoRa Network)

```
[Header: 1B] [Path Len: 1B] [Path: 0-64B] [Payload: 0-184B]
```

### Header Encoding

```
Bits: [Ver:2][Type:4][Route:2]
Route = header & 0x03
Type  = (header >> 2) & 0x0F
Ver   = (header >> 6) & 0x03
```

### Route Types

| Code | Name | Description |
|------|------|-------------|
| `0x01` | FLOOD | Broadcast to all nodes |
| `0x02` | DIRECT | Point-to-point via path |

### Payload Types

| Code | Name | Encrypted | Structure |
|------|------|-----------|-----------|
| `0x00` | REQ | ✓ | `[1B dest][1B src][2B MAC][encrypted]` |
| `0x01` | RESPONSE | ✓ | `[1B dest][1B src][2B MAC][encrypted]` |
| `0x02` | TXT_MSG | ✓ | `[1B dest][1B src][2B MAC][encrypted]` |
| `0x03` | ACK | ✗ | `[ack data]` |
| `0x04` | ADVERT | ✗ | `[32B pubkey][4B ts][app][64B sig]` |
| `0x05` | GRP_TXT | ✓ | `[1B chan][2B MAC][encrypted]` |
| `0x06` | GRP_DATA | ✓ | `[1B chan][2B MAC][encrypted]` |
| `0x07` | ANON_REQ | ✓ | `[1B dest][32B ephemeral][2B MAC][enc]` |
| `0x08` | PATH | ✓ | `[1B dest][1B src][2B MAC][encrypted]` |
| `0x09` | TRACE | ✗ | `[trace data]` |
| `0x0F` | RAW_CUSTOM | ? | Application-defined |

---

## Advertisement App Data

**Format:** `[Flags:1B][Lat:4B?][Lon:4B?][Battery:1B?][Temp:1B?][Name:NB?]`

### Flags Byte

```
Bits: [Name:1][Temp:1][Batt:1][LatLon:1][Type:4]
Type     = flags & 0x0F
Has GPS  = flags & 0x10
Has Batt = flags & 0x20
Has Temp = flags & 0x40
Has Name = flags & 0x80
```

### Contact Types

| Code | Name | Description |
|------|------|-------------|
| `0x00` | NONE | Unknown |
| `0x01` | CHAT | Team member (shown on map) |
| `0x02` | REPEATER | Network node |
| `0x03` | ROOM | Group channel |

---

## Cayenne LPP (Telemetry)

**Format:** `[Channel:1B][Type:1B][Data]`

| Type | Code | Data | Decoding |
|------|------|------|----------|
| GPS | `0x88` | 12B | lat/lon ÷ 10000, alt ÷ 100 |
| Temp | `0x67` | 2B | int16 ÷ 10 for °C |
| Analog | `0x02` | 2B | uint16 ÷ 100 for volts |

**Example:**
```
[01][88][A0C20600][30670200][2C010000]
 ^ch ^gps ^-lat-^  ^-lon-^  ^-alt-^
GPS: 44.304°N, 15.7488°E, 3.00m
```

---

## Constants

### Size Limits
- Max Packet Payload: 184 bytes
- Max Path Size: 64 bytes
- Max Advert Data: 32 bytes
- Public Key: 32 bytes
- Private Key: 64 bytes
- Signature: 64 bytes
- MAC: 2 bytes
- Cipher Block: 16 bytes

### Coordinate Encoding
```dart
// Encode
int32 encoded = (double degrees * 10000).toInt();

// Decode
double degrees = encoded / 10000.0;

// Precision: 4 decimal places (~11m accuracy)
```

---

## Common Operations

### Parse BLE Contact Response
```dart
final pubkey = data.sublist(1, 33);          // 32 bytes
final type = data[33];                       // 0-3
final name = data.sublist(34, 98);          // 64 bytes
final lat = ByteData.view(data.buffer)
    .getInt32(98, Endian.little) / 10000.0;
final lon = ByteData.view(data.buffer)
    .getInt32(102, Endian.little) / 10000.0;
```

### Parse Mesh Packet Header
```dart
final header = packet[0];
final routeType = header & 0x03;
final payloadType = (header >> 2) & 0x0F;
final version = (header >> 6) & 0x03;
final isFlood = routeType == 0x01;
final isTxtMsg = payloadType == 0x02;
```

### Parse Advertisement Flags
```dart
final flags = appData[0];
final contactType = flags & 0x0F;
final hasGPS = (flags & 0x10) != 0;
final hasBattery = (flags & 0x20) != 0;
final hasTemp = (flags & 0x40) != 0;
final hasName = (flags & 0x80) != 0;
```

### Parse Cayenne LPP GPS
```dart
if (data[1] == 0x88) {  // GPS type
  final lat = ByteData.view(data.buffer)
      .getInt32(2, Endian.little) / 10000.0;
  final lon = ByteData.view(data.buffer)
      .getInt32(6, Endian.little) / 10000.0;
  final alt = ByteData.view(data.buffer)
      .getInt32(10, Endian.little) / 100.0;
}
```

---

## Security Notes

1. **Always verify signatures** on ADVERT packets
2. **Validate MAC** before decrypting encrypted payloads
3. **Check timestamps** to prevent replay attacks
4. **Sanitize strings** before display (max length, UTF-8 validation)
5. **Rate limit** packet processing to prevent DoS
6. Use **constant-time comparison** for MAC validation

---

## Flutter Implementation

**Main Files:**
- `lib/services/meshcore_ble_service.dart` - BLE protocol
- `lib/services/buffer_reader.dart` - Binary parsing
- `lib/services/buffer_writer.dart` - Binary encoding
- `lib/services/cayenne_lpp_parser.dart` - Telemetry decoding

---

## Additional Documentation

- **[MESHCORE_PROTOCOL.md](MESHCORE_PROTOCOL.md)** - Complete mesh packet protocol specification
- **[MESHCORE_BLE_PROTOCOL.md](MESHCORE_BLE_PROTOCOL.md)** - Complete BLE command/response protocol
- **[CLAUDE.md](CLAUDE.md)** - Project overview and development guide

---

**Document Version:** 1.0
**Last Updated:** 2025-10-14
