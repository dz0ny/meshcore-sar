# BLE Packet Log Analysis - Message Send/Receive Flow

**Date**: 2025-01-15
**Purpose**: Analyze BLE packet logs to understand message transmission and delivery

## Overview

This document explains how to use the **BLE Packet Log** feature (already implemented in the app) to diagnose message send/receive issues. The app automatically logs ALL BLE communication between the Flutter app and the MeshCore companion device.

## Quick Start: Viewing Packet Logs

### Access the Packet Log Screen

**Currently**: The packet log screen exists but is not accessible from the main UI.

**Location**: `lib/screens/packet_log_screen.dart`

### How to Add Navigation (Quick Fix)

**Option 1: Add to Home Screen AppBar** (`lib/screens/home_screen.dart`):

```dart
// In HomeScreen's AppBar actions:
actions: [
  // ... existing RX/TX indicators ...

  // NEW: Packet log button
  IconButton(
    icon: const Icon(Icons.list_alt),
    tooltip: 'BLE Packet Logs',
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PacketLogScreen(
            bleService: widget.connectionProvider.bleService,
          ),
        ),
      );
    },
  ),

  // ... existing long press indicator ...
],
```

**Option 2: Add to Debug Menu** (if you have one):

```dart
ListTile(
  leading: const Icon(Icons.bug_report),
  title: const Text('BLE Packet Logs'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PacketLogScreen(
        bleService: connectionProvider.bleService,
      ),
    ),
  ),
),
```

### Packet Log Features (Already Implemented)

1. **Auto-logging**: Every BLE packet automatically logged
2. **Direction indicators**: RX (received) vs TX (sent) with color coding
3. **Opcode names**: Human-readable names (e.g., "CONTACT_MSG_RECV" instead of "0x07")
4. **Hex dump**: Full packet data in hexadecimal
5. **Search/filter**: Search by hex data, description, or opcode name
6. **Export**: Export logs as CSV or TXT for analysis
7. **Auto-scroll**: Option to automatically scroll to newest packets

## Message Send/Receive Protocol Flow

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│ USER SENDS MESSAGE                                                       │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. TX: CMD_SEND_TXT_MSG (0x02) or CMD_SEND_CHANNEL_TXT_MSG (0x03)      │
│    - Contains: message text, recipient pub key, timestamp               │
│    - Logged as: PacketDirection.tx                                      │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. RX: RESP_CODE_SENT (0x06)                                            │
│    - Contains: expected ACK tag, suggested timeout (e.g., 30000ms)     │
│    - Message status: sending → sent                                     │
│    - Logged as: PacketDirection.rx                                      │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ├──────────────────────────┬─────────────────────────────┐
                 │                          │                             │
                 ▼                          ▼                             ▼
     ┌──────────────────────┐   ┌──────────────────────┐   ┌─────────────────────┐
     │ 3a. SUCCESS PATH     │   │ 3b. TIMEOUT PATH     │   │ 3c. DIAGNOSTIC PATH │
     └──────────────────────┘   └──────────────────────┘   └─────────────────────┘
                 │                          │                             │
                 ▼                          ▼                             ▼
     ┌──────────────────────┐   ┌──────────────────────┐   ┌─────────────────────┐
     │ RX: PUSH_CODE_       │   │ Timer expires        │   │ RX: PUSH_CODE_      │
     │ SEND_CONFIRMED       │   │ (30000ms)            │   │ LOG_RX_DATA         │
     │ (0x82)               │   │                      │   │ (0x88)              │
     │                      │   │ Message status:      │   │                     │
     │ Contains:            │   │ sent → failed        │   │ Contains:           │
     │ - ACK code           │   │                      │   │ - SNR, RSSI         │
     │ - RTT (ms)           │   │ No retry triggered   │   │ - Raw packet data   │
     │                      │   │ (manual retry only)  │   │                     │
     │ Message status:      │   └──────────────────────┘   │ Diagnostic only     │
     │ sent → delivered     │                              │ (doesn't affect     │
     └──────────────────────┘                              │  message status)    │
                                                           └─────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│ REMOTE USER SENDS MESSAGE                                                │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 1. Message arrives at companion device over LoRa                        │
│    - Device stores in internal queue                                    │
│    - May trigger LOG_RX_DATA (0x88) diagnostic push                     │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 2. RX: PUSH_CODE_MSG_WAITING (0x83)                                     │
│    - Asynchronous notification: "New message ready"                     │
│    - Contains: no data (just notification)                              │
│    - Logged as: PacketDirection.rx                                      │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ 3. TX: CMD_SYNC_NEXT_MESSAGE (0x0A)                                     │
│    - Request to fetch next message from queue                           │
│    - Contains: no data (just command code)                              │
│    - Logged as: PacketDirection.tx                                      │
└────────────────┬────────────────────────────────────────────────────────┘
                 │
                 ├──────────────────────────┬─────────────────────────────┐
                 │                          │                             │
                 ▼                          ▼                             ▼
     ┌──────────────────────┐   ┌──────────────────────┐   ┌─────────────────────┐
     │ 4a. DIRECT MESSAGE   │   │ 4b. CHANNEL MESSAGE  │   │ 4c. QUEUE EMPTY     │
     └──────────────────────┘   └──────────────────────┘   └─────────────────────┘
                 │                          │                             │
                 ▼                          ▼                             ▼
     ┌──────────────────────┐   ┌──────────────────────┐   ┌─────────────────────┐
     │ RX: RESP_CODE_       │   │ RX: RESP_CODE_       │   │ RX: RESP_CODE_      │
     │ CONTACT_MSG_RECV     │   │ CHANNEL_MSG_RECV     │   │ NO_MORE_MESSAGES    │
     │ (0x07)               │   │ (0x08)               │   │ (0x0A)              │
     │                      │   │                      │   │                     │
     │ Contains:            │   │ Contains:            │   │ Stop syncing loop   │
     │ - Sender pub key     │   │ - Channel index      │   └─────────────────────┘
     │   (6 bytes)          │   │ - Path length        │
     │ - Path length        │   │ - Text type          │
     │ - Text type          │   │ - Timestamp          │
     │ - Timestamp          │   │ - Text (format:      │
     │ - Text (plain)       │   │   "Name: Message")   │
     │                      │   │                      │
     │ App displays message │   │ App displays message │
     └──────────────────────┘   └──────────────────────┘
                 │                          │
                 └──────────────┬───────────┘
                                │
                                ▼
                  ┌──────────────────────────────────┐
                  │ Loop back to CMD_SYNC_NEXT_MSG   │
                  │ until RESP_CODE_NO_MORE_MESSAGES │
                  └──────────────────────────────────┘
```

## BLE Packet Log Interpretation Guide

### Sending a Direct Message

#### Expected Log Sequence

```
1. [TX] SEND_TXT_MSG (0x02) - 18 bytes
   Hex: 02 00 00 e8 76 67 67 8b 33 f2 a1 4c d9 48 65 6c 6c 6f
   Breakdown:
     02          = CMD_SEND_TXT_MSG
     00          = TXT_TYPE_PLAIN
     00          = Attempt 0 (first send)
     e8 76 67 67 = Timestamp (Little Endian): 1734567912
     8b 33 f2 a1 4c d9 = Recipient public key prefix (6 bytes)
     48 65 6c 6c 6f     = "Hello" (UTF-8)

2. [RX] SENT (0x06) - 9 bytes
   Hex: 06 00 d2 04 00 00 30 75 00 00
   Breakdown:
     06          = RESP_CODE_SENT
     00          = Send type: 0=direct route
     d2 04 00 00 = Expected ACK tag (Little Endian): 1234
     30 75 00 00 = Suggested timeout (Little Endian): 30000ms (30 seconds)

   Result: Message now in "Sent" state, waiting for confirmation

3a. [RX] SEND_CONFIRMED (0x82) - 9 bytes (SUCCESS PATH)
    Hex: 82 d2 04 00 00 10 27 00 00
    Breakdown:
      82          = PUSH_CODE_SEND_CONFIRMED
      d2 04 00 00 = ACK code (Little Endian): 1234 (matches expected)
      10 27 00 00 = Round trip time (Little Endian): 10000ms

    Result: Message marked "Delivered", timeout timer cancelled

3b. (No packet received, timeout after 30000ms) (TIMEOUT PATH)
    Result: Timeout timer expires, message marked "Failed"
```

### Sending a Channel Message

#### Expected Log Sequence

```
1. [TX] SEND_CHANNEL_TXT_MSG (0x03) - 13 bytes
   Hex: 03 00 00 e8 76 67 67 48 69 20 61 6c 6c
   Breakdown:
     03          = CMD_SEND_CHANNEL_TXT_MSG
     00          = TXT_TYPE_PLAIN
     00          = Channel index 0 (public)
     e8 76 67 67 = Timestamp (Little Endian): 1734567912
     48 69 20 61 6c 6c = "Hi all" (UTF-8)

2. [RX] SENT (0x06) - 9 bytes
   Hex: 06 01 e3 05 00 00 50 c3 00 00
   Breakdown:
     06          = RESP_CODE_SENT
     01          = Send type: 1=flood mode (broadcast)
     e3 05 00 00 = Expected ACK/TAG (Little Endian): 1507
     50 c3 00 00 = Suggested timeout (Little Endian): 50000ms

   Result: Channel message broadcast, waiting for confirmation

3. [RX] SEND_CONFIRMED (0x82) - 9 bytes
   Hex: 82 e3 05 00 00 88 13 00 00
   Breakdown:
     82          = PUSH_CODE_SEND_CONFIRMED
     e3 05 00 00 = ACK code (Little Endian): 1507 (matches)
     88 13 00 00 = RTT (Little Endian): 5000ms

   Result: Broadcast confirmed delivered
```

### Receiving a Direct Message

#### Expected Log Sequence

```
1. [RX] MSG_WAITING (0x83) - 1 byte
   Hex: 83
   Breakdown:
     83          = PUSH_CODE_MSG_WAITING

   Result: App calls CMD_SYNC_NEXT_MESSAGE

2. [TX] SYNC_NEXT_MESSAGE (0x0A) - 1 byte
   Hex: 0a
   Breakdown:
     0a          = CMD_SYNC_NEXT_MESSAGE

   Result: Request next message from device queue

3. [RX] CONTACT_MSG_RECV (0x07) - 19 bytes
   Hex: 07 8b 33 f2 a1 4c d9 ff 00 e8 76 67 67 48 69
   Breakdown:
     07          = RESP_CODE_CONTACT_MSG_RECV
     8b 33 f2 a1 4c d9 = Sender public key prefix (6 bytes)
     ff          = Path length: 0xFF = direct path (not flood)
     00          = TXT_TYPE_PLAIN
     e8 76 67 67 = Sender timestamp (Little Endian): 1734567912
     48 69       = "Hi" (UTF-8)

   Result: Message displayed in app, matched to contact by pub key prefix

4. [TX] SYNC_NEXT_MESSAGE (0x0A) - 1 byte
   Hex: 0a

   Result: Check for more messages

5. [RX] NO_MORE_MESSAGES (0x0A) - 1 byte
   Hex: 0a
   Breakdown:
     0a          = RESP_CODE_NO_MORE_MESSAGES

   Result: Stop syncing loop, all messages fetched
```

### Receiving a Channel Message

#### Expected Log Sequence

```
1. [RX] MSG_WAITING (0x83) - 1 byte
   Hex: 83

2. [TX] SYNC_NEXT_MESSAGE (0x0A) - 1 byte
   Hex: 0a

3. [RX] CHANNEL_MSG_RECV (0x08) - 22 bytes
   Hex: 08 00 03 00 e8 76 67 67 4a 6f 68 6e 3a 20 48 65 6c 6c 6f
   Breakdown:
     08          = RESP_CODE_CHANNEL_MSG_RECV
     00          = Channel index 0 (public)
     03          = Path length: 3 hops
     00          = TXT_TYPE_PLAIN
     e8 76 67 67 = Sender timestamp (Little Endian): 1734567912
     4a 6f 68 6e 3a 20 48 65 6c 6c 6f = "John: Hello" (UTF-8)

   Result: Parse sender name from text ("John"), display message

4. [TX] SYNC_NEXT_MESSAGE (0x0A) - 1 byte
   Hex: 0a

5. [RX] NO_MORE_MESSAGES (0x0A) - 1 byte
   Hex: 0a
```

## Diagnostic: LOG_RX_DATA Push (0x88)

### What is LOG_RX_DATA?

**Purpose**: Diagnostic push notification containing raw over-the-air LoRa packets

**When it triggers**: Every time the companion device receives a packet from another mesh node

**Frame format**:
```
[0x88] = PUSH_CODE_LOG_RX_DATA
[1 byte] = SNR × 4 (signed int8, divide by 4 for dB)
[1 byte] = RSSI (signed int8, in dBm)
[N bytes] = Raw encrypted LoRa packet data
```

### Example LOG_RX_DATA Packet

```
Hex dump:
88                          = PUSH_CODE_LOG_RX_DATA
14                          = SNR: 20 (÷4 = 5.0 dB)
d6                          = RSSI: -42 dBm (signed)
f3 e2 a1 9c 7f 3d 42 ...   = Raw encrypted mesh packet (high entropy)
```

### App's LOG_RX_DATA Handler

**Location**: `lib/services/meshcore_ble_service.dart:1017-1333`

The app already has EXTENSIVE decoding analysis for LOG_RX_DATA packets:

1. **Signal Quality Metrics**:
   - SNR (Signal-to-Noise Ratio) in dB
   - RSSI (Received Signal Strength) in dBm

2. **Hex Dump**: Formatted 16 bytes per line with ASCII view

3. **Forced Decoding** (9 different interpretations):
   - All uint32 values at each offset
   - All int32 values (GPS coordinates)
   - All uint16 values
   - Byte pair correlation (pattern detection)
   - Nibble distribution analysis
   - XOR pattern detection (simple encryption)
   - Checksum/CRC candidates
   - Bit-level analysis (entropy check)
   - LoRa modulation parameter detection

4. **Entropy Calculation**: Detect if packet is encrypted (>70% entropy)

5. **String Extraction**: Find embedded ASCII strings (4+ printable chars)

### Why LOG_RX_DATA Packets Don't Affect Messages

**Critical**: LOG_RX_DATA is **diagnostic only** - it does NOT affect message delivery status!

```
┌────────────────────────────────────────────────────────────┐
│ Message Send Flow (affects delivery status)               │
├────────────────────────────────────────────────────────────┤
│ TX: CMD_SEND_TXT_MSG (0x02)                               │
│  ↓                                                         │
│ RX: RESP_CODE_SENT (0x06) ← Message now "Sent"           │
│  ↓                                                         │
│ RX: PUSH_CODE_SEND_CONFIRMED (0x82) ← Message "Delivered"│
└────────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────────┐
│ Diagnostic Flow (does NOT affect delivery status)         │
├────────────────────────────────────────────────────────────┤
│ RX: PUSH_CODE_LOG_RX_DATA (0x88)                         │
│  ↓                                                         │
│ Logged to packet log, analyzed for debugging              │
│  ↓                                                         │
│ No state change in MessagesProvider                        │
└────────────────────────────────────────────────────────────┘
```

**Use Cases for LOG_RX_DATA**:
1. Monitor mesh network activity in real-time
2. Analyze signal quality (SNR/RSSI) for received packets
3. Debug packet reception issues
4. Understand network topology
5. Detect interference or poor RF conditions

**Note**: The raw packet data is typically encrypted (high entropy ~95%+), so direct decoding is not possible. The app's exhaustive analysis tries to extract any structured information.

## Troubleshooting Message Issues

### Symptom: Messages Stuck in "Sending" Status

**Check packet log for**:
1. ✅ `[TX] SEND_TXT_MSG (0x02)` present → Message sent to device
2. ❌ `[RX] SENT (0x06)` missing → Device not responding

**Possible causes**:
- BLE connection dropped
- Companion device frozen
- BLE service not properly initialized

**Fix**:
- Reconnect to device
- Check device battery
- Restart companion device

### Symptom: Messages Stuck in "Sent" Status (Never Delivered)

**Check packet log for**:
1. ✅ `[TX] SEND_TXT_MSG (0x02)` present
2. ✅ `[RX] SENT (0x06)` present → Message acknowledged by device
3. ❌ `[RX] SEND_CONFIRMED (0x82)` missing → No delivery confirmation
4. ⏱️ Timeout timer should fire after suggested timeout

**Check LOG_RX_DATA packets**:
- If NO `[RX] LOG_RX_DATA (0x88)` packets: Network is silent, no mesh activity
- If many `[RX] LOG_RX_DATA (0x88)` packets: Network is active
  - Check SNR/RSSI values (should be > -120 dBm)
  - Low SNR/RSSI indicates poor signal quality

**Possible causes**:
- Recipient device out of range
- No mesh route to recipient
- Recipient device off/offline
- Network congestion (many nodes transmitting)
- Poor RF conditions (interference, obstacles)

**Fix**:
- Check recipient device status
- Move closer to establish direct line-of-sight
- Wait for timeout, then retry
- Check if other nodes are receiving messages

### Symptom: Messages Never Received (No MSG_WAITING)

**Check packet log for**:
1. ❌ `[RX] MSG_WAITING (0x83)` missing → No messages in device queue

**Possible causes**:
- No one sent you a message
- Messages filtered by contact flags
- Device message queue full (old messages overwritten)
- Room not logged in (room messages require login)

**Fix**:
- Verify sender actually sent message
- Check contact flags (telemetry_modes, advert_location_policy)
- Login to room if expecting room messages
- Check device storage (CMD_GET_BATT_AND_STORAGE)

### Symptom: Channel Messages Not Received

**Check packet log for**:
1. ❌ `[RX] CHANNEL_MSG_RECV (0x08)` never appears after MSG_WAITING

**Possible causes**:
- Message queue only had direct messages, no channel messages
- Channel message from unknown sender (name not in contacts)

**Fix**:
- Call `CMD_SYNC_NEXT_MESSAGE` repeatedly until `NO_MORE_MESSAGES`
- Check if message appears as `CONTACT_MSG_RECV (0x07)` instead

### Symptom: Room Messages Not Syncing After Login

**Check packet log for**:
1. ✅ `[TX] SEND_LOGIN (0x1A)` present
2. ✅ `[RX] LOGIN_SUCCESS (0x85)` present → Login succeeded
3. ⚠️ Immediately called `CMD_SYNC_NEXT_MESSAGE`? → **WRONG!**

**Protocol compliance check**:
```
WRONG ❌:
  LOGIN_SUCCESS → CMD_SYNC_NEXT_MESSAGE → NO_MORE_MESSAGES
  (Room hasn't pushed messages yet, they arrive 2000ms later!)

CORRECT ✅:
  LOGIN_SUCCESS → wait for MSG_WAITING → CMD_SYNC_NEXT_MESSAGE
  (Room server pushes messages automatically every 1200ms)
```

**Fix**:
- Don't call `syncAllMessages()` immediately after login
- Wait for `PUSH_CODE_MSG_WAITING (0x83)` notifications
- Room server pushes messages automatically (see MESSAGES.md lines 679-728)

## Export and Analysis

### Export Packet Logs

**CSV Export** (for spreadsheet analysis):
```csv
Timestamp,Direction,Size (bytes),Opcode Name,Code,Hex Data,Description
2025-01-15T10:30:15.123,TX,18,SEND_TXT_MSG,2,"02 00 00 e8 76 67 67 8b 33 f2 a1 4c d9 48 65 6c 6c 6f","Send Text Message"
2025-01-15T10:30:15.456,RX,9,SENT,6,"06 00 d2 04 00 00 30 75 00 00",""
2025-01-15T10:30:25.789,RX,9,SEND_CONFIRMED,130,"82 d2 04 00 00 10 27 00 00",""
```

**Text Export** (for log analysis):
```
MeshCore BLE Packet Logs
================================================================================
Exported: 2025-01-15T10:35:00.000Z
Total packets: 127
================================================================================

2025-01-15T10:30:15.123Z [TX] SEND_TXT_MSG (0x02) 18 bytes: 02 00 00 e8 76 67 67 8b 33 f2 a1 4c d9 48 65 6c 6c 6f - Send Text Message
2025-01-15T10:30:15.456Z [RX] SENT (0x06) 9 bytes: 06 00 d2 04 00 00 30 75 00 00
2025-01-15T10:30:25.789Z [RX] SEND_CONFIRMED (0x82) 9 bytes: 82 d2 04 00 00 10 27 00 00
```

### Analyzing Exports

**Python script to analyze CSV**:

```python
import csv
from datetime import datetime

with open('ble_packets.csv') as f:
    reader = csv.DictReader(f)
    packets = list(reader)

# Find all sent messages with their ACK tags
sent_messages = {}
for packet in packets:
    if packet['Opcode Name'] == 'SENT':
        # Parse ACK tag from hex data
        hex_bytes = packet['Hex Data'].split()
        ack_tag = int.join(hex_bytes[2:6], '', 16)  # Little Endian
        sent_messages[ack_tag] = {
            'sent_at': datetime.fromisoformat(packet['Timestamp']),
            'confirmed': False,
        }

# Match with confirmations
for packet in packets:
    if packet['Opcode Name'] == 'SEND_CONFIRMED':
        hex_bytes = packet['Hex Data'].split()
        ack_tag = int.join(hex_bytes[1:5], '', 16)
        if ack_tag in sent_messages:
            sent_messages[ack_tag]['confirmed'] = True
            sent_messages[ack_tag]['confirmed_at'] = datetime.fromisoformat(packet['Timestamp'])
            rtt_ms = int.join(hex_bytes[5:9], '', 16)
            sent_messages[ack_tag]['rtt_ms'] = rtt_ms

# Report
for ack_tag, info in sent_messages.items():
    if info['confirmed']:
        rtt = info['confirmed_at'] - info['sent_at']
        print(f"ACK {ack_tag}: Delivered in {rtt.total_seconds():.3f}s (RTT: {info['rtt_ms']}ms)")
    else:
        print(f"ACK {ack_tag}: NOT DELIVERED (timed out)")
```

## Summary

### Key Takeaways

1. **Packet Log is Already Implemented**: Full BLE packet logging exists in `lib/screens/packet_log_screen.dart`
2. **Just Needs Navigation**: Add a button to navigate to PacketLogScreen from HomeScreen
3. **Comprehensive Diagnostics**: App already logs and analyzes everything
4. **LOG_RX_DATA is Diagnostic Only**: Does NOT affect message delivery status
5. **Timeout Handling Implemented**: Messages automatically fail after timeout (see MESSAGING_IMPROVEMENTS_IMPLEMENTED.md)
6. **Retry Logic Implemented**: Manual retry for failed messages (see MESSAGING_IMPROVEMENTS_IMPLEMENTED.md)

### Quick Reference: Packet Codes

| Code | Name | Direction | Meaning |
|------|------|-----------|---------|
| 0x02 | SEND_TXT_MSG | TX | Sending direct message |
| 0x03 | SEND_CHANNEL_TXT_MSG | TX | Sending channel message |
| 0x06 | SENT | RX | Message accepted, ACK tag provided |
| 0x07 | CONTACT_MSG_RECV | RX | Direct message received |
| 0x08 | CHANNEL_MSG_RECV | RX | Channel message received |
| 0x0A (CMD) | SYNC_NEXT_MESSAGE | TX | Fetch next message |
| 0x0A (RESP) | NO_MORE_MESSAGES | RX | Message queue empty |
| 0x1A | SEND_LOGIN | TX | Login to room |
| 0x82 | SEND_CONFIRMED | RX | Delivery confirmed (with RTT) |
| 0x83 | MSG_WAITING | RX | New message available |
| 0x85 | LOGIN_SUCCESS | RX | Room login succeeded |
| 0x86 | LOGIN_FAIL | RX | Room login failed |
| 0x88 | LOG_RX_DATA | RX | Diagnostic: raw over-the-air packet |

### Next Steps

1. **Add Navigation to Packet Log Screen**:
   - Update `lib/screens/home_screen.dart`
   - Add IconButton in AppBar actions
   - Wire to PacketLogScreen

2. **Test Message Flow**:
   - Send messages and watch packet log in real-time
   - Enable auto-scroll to see newest packets
   - Export logs for offline analysis

3. **Debug Failed Messages**:
   - Check for missing SEND_CONFIRMED packets
   - Analyze LOG_RX_DATA for signal quality issues
   - Verify timeout values from SENT responses

## References

- **BLE Packet Log Implementation**: `lib/screens/packet_log_screen.dart`
- **BLE Packet Model**: `lib/models/ble_packet_log.dart`
- **BLE Service (Logging)**: `lib/services/meshcore_ble_service.dart:275-319`
- **Opcode Names**: `lib/services/meshcore_opcode_names.dart`
- **Message Protocol**: `MESSAGES.md`
- **Gap Analysis**: `MESSAGE_SEND_RECEIVE_GAP_ANALYSIS.md`
- **Timeout/Retry**: `MESSAGING_IMPROVEMENTS_IMPLEMENTED.md`
- **Protocol Spec**: `/Users/dz0ny/meshcore-sar/MeshCore/docs/companion.md`
