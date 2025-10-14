# MeshCore BLE Protocol Specification

Complete BLE command/response protocol extracted from [meshcore.js Connection class](https://github.com/meshcore-dev/meshcore.js).

## Overview

The MeshCore BLE protocol provides a command/response interface for smartphone applications to interact with MeshCore devices over Bluetooth Low Energy. This is a **separate protocol** from the mesh packet protocol used for LoRa radio communication.

**Protocol Characteristics:**
- Uses Nordic UART Service (NUS) profile
- Simple command/response model
- App acts as BLE central, device acts as peripheral
- Commands sent over RX characteristic
- Responses/events received over TX characteristic
- Supports asynchronous push notifications

---

## Service Specification

**Service UUID:** `6E400001-B5A3-F393-E0A9-E50E24DCCA9E`

| Characteristic | UUID | Properties | Direction | Description |
|----------------|------|------------|-----------|-------------|
| RX | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | Write, Write Without Response | App → Device | Commands |
| TX | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | Notify | Device → App | Responses & Events |

---

## Protocol Structure

### Command Frame Format
```
[Command Code: 1B] [Parameters...]
```

### Response Frame Format
```
[Response Code: 1B] [Data...]
```

### Push Notification Format
```
[Push Code: 1B] [Data...]
```

---

## Command Codes

Commands sent from app to device over RX characteristic:

| Code | Name | Description |
|------|------|-------------|
| - | `AppStart` | Initialize connection, get device info |
| - | `SendTxtMsg` | Send text message to contact |
| - | `SendChannelTxtMsg` | Send text message to channel |
| - | `GetContacts` | Request list of contacts |
| - | `GetDeviceTime` | Get device's current time |
| - | `SetDeviceTime` | Set device's current time |
| - | `SendSelfAdvert` | Broadcast advertisement |
| - | `SetAdvertName` | Set device's advertised name |
| - | `AddUpdateContact` | Add or update contact details |
| - | `SyncNextMessage` | Retrieve next queued message |
| - | `SetRadioParams` | Configure LoRa radio parameters |
| - | `SetTxPower` | Set transmit power |
| - | `ResetPath` | Reset routing path for contact |
| - | `SetAdvertLatLon` | Set device's GPS coordinates |
| - | `RemoveContact` | Delete contact from device |
| - | `ShareContact` | Send contact to mesh network |
| - | `ExportContact` | Export contact as packet bytes |
| - | `ImportContact` | Import contact from packet bytes |
| - | `Reboot` | Reboot device |
| - | `GetBatteryVoltage` | Read battery voltage |
| - | `DeviceQuery` | Query device firmware info |
| - | `ExportPrivateKey` | Export device's private key |
| - | `ImportPrivateKey` | Import private key to device |
| - | `SendRawData` | Send raw mesh packet |
| - | `SendLogin` | Login to repeater/room |
| - | `SendStatusReq` | Request repeater status |
| - | `SendTelemetryReq` | Request telemetry from contact |
| - | `SendBinaryReq` | Send binary request |
| - | `GetChannel` | Get channel configuration |
| - | `SetChannel` | Set channel configuration |
| - | `SignStart` | Start signing data |
| - | `SignData` | Send data chunk to sign |
| - | `SignFinish` | Finish signing, get signature |
| - | `SendTracePath` | Trace network path |
| - | `SetOtherParams` | Set miscellaneous parameters |

---

## Response Codes

Responses sent from device to app over TX characteristic:

| Code | Name | Description |
|------|------|-------------|
| - | `Ok` | Command succeeded |
| - | `Err` | Command failed |
| - | `SelfInfo` | Device information |
| - | `CurrTime` | Current device time |
| - | `NoMoreMessages` | Message queue empty |
| - | `ContactMsgRecv` | Contact message received |
| - | `ChannelMsgRecv` | Channel message received |
| - | `ContactsStart` | Start of contacts list |
| - | `Contact` | Contact entry |
| - | `EndOfContacts` | End of contacts list |
| - | `Sent` | Message sent to mesh |
| - | `ExportContact` | Exported contact data |
| - | `BatteryVoltage` | Battery voltage reading |
| - | `DeviceInfo` | Firmware version info |
| - | `PrivateKey` | Exported private key |
| - | `Disabled` | Feature disabled |
| - | `ChannelInfo` | Channel configuration |
| - | `SignStart` | Signing session started |
| - | `Signature` | Ed25519 signature |

---

## Push Codes

Asynchronous events pushed from device to app:

| Code | Name | Description |
|------|------|-------------|
| - | `Advert` | Advertisement broadcast |
| - | `PathUpdated` | Routing path updated |
| - | `SendConfirmed` | Message ACK received |
| - | `MsgWaiting` | Messages queued |
| - | `RawData` | Raw packet received |
| - | `LoginSuccess` | Login succeeded |
| - | `StatusResponse` | Status data received |
| - | `LogRxData` | Raw RX data (debug) |
| - | `TelemetryResponse` | Telemetry data received |
| - | `TraceData` | Path trace completed |
| - | `NewAdvert` | New contact advertised |
| - | `BinaryResponse` | Binary request response |

---

## Command Details

### AppStart
Initialize BLE connection and retrieve device information.

**Format:**
```
[AppStart] [1B: appVer] [6B: reserved] [string: appName]
```

**Parameters:**
- `appVer` (uint8): App protocol version (e.g., 1)
- `reserved` (6 bytes): Reserved for future use
- `appName` (string): Application name (null-terminated)

**Response:** `SelfInfo`

**Example:**
```javascript
await connection.sendCommandAppStart();
// Sends: [CMD][0x01][00 00 00 00 00 00]["test\0"]
```

---

### SendTxtMsg
Send a text message to a contact.

**Format:**
```
[SendTxtMsg] [1B: txtType] [1B: attempt] [4B: timestamp] [6B: pubKeyPrefix] [string: text]
```

**Parameters:**
- `txtType` (uint8): Message type (0=Plain, 1=Emergency, etc.)
- `attempt` (uint8): Retry attempt number (usually 0)
- `timestamp` (uint32 LE): Unix timestamp
- `pubKeyPrefix` (6 bytes): First 6 bytes of recipient's public key
- `text` (string): UTF-8 message text (null-terminated)

**Response:** `Sent`

**Example:**
```javascript
const txtType = 0;  // Plain
const attempt = 0;
const timestamp = Math.floor(Date.now() / 1000);
await connection.sendCommandSendTxtMsg(txtType, attempt, timestamp, contactPublicKey, "Hello!");
```

---

### SendChannelTxtMsg
Send a text message to a group channel.

**Format:**
```
[SendChannelTxtMsg] [1B: txtType] [1B: channelIdx] [4B: timestamp] [string: text]
```

**Parameters:**
- `txtType` (uint8): Message type
- `channelIdx` (uint8): Channel index (0-255)
- `timestamp` (uint32 LE): Unix timestamp
- `text` (string): UTF-8 message text

**Response:** `Ok` or `Err`

---

### GetContacts
Request list of all contacts from device.

**Format:**
```
[GetContacts] [4B: since]?
```

**Parameters:**
- `since` (uint32 LE, optional): Only return contacts modified after this timestamp

**Response Sequence:**
1. `ContactsStart` (with count)
2. Multiple `Contact` responses
3. `EndOfContacts`

**Example:**
```javascript
const contacts = await connection.getContacts();
// Returns array of contact objects
```

---

### GetDeviceTime
Get current time from device.

**Format:**
```
[GetDeviceTime]
```

**Response:** `CurrTime`

**Response Format:**
```
[CurrTime] [4B: epochSecs]
```

---

### SetDeviceTime
Set device's current time.

**Format:**
```
[SetDeviceTime] [4B: epochSecs]
```

**Parameters:**
- `epochSecs` (uint32 LE): Unix timestamp

**Response:** `Ok` or `Err`

**Example:**
```javascript
await connection.syncDeviceTime();  // Sets to current system time
```

---

### SendSelfAdvert
Broadcast advertisement to mesh network.

**Format:**
```
[SendSelfAdvert] [1B: type]
```

**Parameters:**
- `type` (uint8): Advertisement type
  - `Flood`: Broadcast to entire network
  - `ZeroHop`: Only adjacent nodes

**Response:** `Ok` or `Err`

**Push:** `Advert` (when broadcast begins)

**Example:**
```javascript
await connection.sendFloodAdvert();    // Network-wide
await connection.sendZeroHopAdvert();  // Adjacent only
```

---

### SetAdvertName
Set device's advertised name.

**Format:**
```
[SetAdvertName] [string: name]
```

**Parameters:**
- `name` (string): Display name (null-terminated, max 31 chars)

**Response:** `Ok` or `Err`

**Example:**
```javascript
await connection.setAdvertName("Alice");
```

---

### AddUpdateContact
Add new contact or update existing contact.

**Format:**
```
[AddUpdateContact] [32B: publicKey] [1B: type] [1B: flags] [1B: outPathLen]
                   [64B: outPath] [32B: advName] [4B: lastAdvert]
                   [4B: advLat] [4B: advLon]
```

**Parameters:**
- `publicKey` (32 bytes): Ed25519 public key
- `type` (uint8): Contact type (0=none, 1=chat, 2=repeater, 3=room)
- `flags` (uint8): Contact flags
- `outPathLen` (int8): Length of routing path
- `outPath` (64 bytes): Routing path (padded)
- `advName` (32 bytes): Name as C-string
- `lastAdvert` (uint32 LE): Last advertisement timestamp
- `advLat` (uint32 LE): GPS latitude (×10000)
- `advLon` (uint32 LE): GPS longitude (×10000)

**Response:** `Ok` or `Err`

---

### SyncNextMessage
Retrieve next message from device's queue.

**Format:**
```
[SyncNextMessage]
```

**Response:** One of:
- `ContactMsgRecv` - Message from contact
- `ChannelMsgRecv` - Message from channel
- `NoMoreMessages` - Queue empty

**Example:**
```javascript
while (true) {
    const msg = await connection.syncNextMessage();
    if (!msg) break;  // No more messages
    console.log(msg);
}
```

---

### SetRadioParams
Configure LoRa radio parameters.

**Format:**
```
[SetRadioParams] [4B: radioFreq] [4B: radioBw] [1B: radioSf] [1B: radioCr]
```

**Parameters:**
- `radioFreq` (uint32 LE): Frequency in Hz (e.g., 915000000)
- `radioBw` (uint32 LE): Bandwidth in Hz (e.g., 125000)
- `radioSf` (uint8): Spreading factor (7-12)
- `radioCr` (uint8): Coding rate (5-8)

**Response:** `Ok` or `Err`

**Example:**
```javascript
await connection.setRadioParams(
    915000000,  // 915 MHz
    125000,     // 125 kHz bandwidth
    7,          // SF7
    5           // CR 4/5
);
```

---

### SetTxPower
Set transmit power level.

**Format:**
```
[SetTxPower] [1B: txPower]
```

**Parameters:**
- `txPower` (uint8): Power level in dBm (device-specific range)

**Response:** `Ok` or `Err`

---

### ResetPath
Clear routing path for a contact (force rediscovery).

**Format:**
```
[ResetPath] [32B: pubKey]
```

**Parameters:**
- `pubKey` (32 bytes): Contact's public key

**Response:** `Ok` or `Err`

---

### SetAdvertLatLon
Set device's GPS coordinates for advertisements.

**Format:**
```
[SetAdvertLatLon] [4B: lat] [4B: lon]
```

**Parameters:**
- `lat` (int32 LE): Latitude × 10000
- `lon` (int32 LE): Longitude × 10000

**Response:** `Ok` or `Err`

**Example:**
```javascript
// Set location to 46.0569°N, 14.5058°E
await connection.setAdvertLatLong(460569, 145058);
```

---

### RemoveContact
Delete contact from device.

**Format:**
```
[RemoveContact] [32B: pubKey]
```

**Parameters:**
- `pubKey` (32 bytes): Contact's public key

**Response:** `Ok` or `Err`

---

### ShareContact
Broadcast contact to mesh network.

**Format:**
```
[ShareContact] [32B: pubKey]
```

**Parameters:**
- `pubKey` (32 bytes): Contact to share

**Response:** `Ok` or `Err`

---

### ExportContact
Export contact as advertisement packet bytes.

**Format:**
```
[ExportContact] [32B: pubKey]?
```

**Parameters:**
- `pubKey` (32 bytes, optional): Contact to export, or omit for self

**Response:** `ExportContact`

**Response Format:**
```
[ExportContact] [N bytes: advertPacketBytes]
```

---

### ImportContact
Import contact from advertisement packet bytes.

**Format:**
```
[ImportContact] [N bytes: advertPacketBytes]
```

**Parameters:**
- `advertPacketBytes`: Complete advertisement packet

**Response:** `Ok` or `Err`

---

### Reboot
Reboot the device.

**Format:**
```
[Reboot] [string: "reboot"]
```

**Response:** None (device reboots)

**Example:**
```javascript
await connection.reboot();
// Device will disconnect and reboot
```

---

### GetBatteryVoltage
Read device's battery voltage.

**Format:**
```
[GetBatteryVoltage]
```

**Response:** `BatteryVoltage`

**Response Format:**
```
[BatteryVoltage] [2B: batteryMilliVolts]
```

**Example:**
```javascript
const { batteryMilliVolts } = await connection.getBatteryVoltage();
console.log(`Battery: ${batteryMilliVolts / 1000}V`);
```

---

### DeviceQuery
Query device firmware information.

**Format:**
```
[DeviceQuery] [1B: appTargetVer]
```

**Parameters:**
- `appTargetVer` (uint8): Protocol version app expects (e.g., 1)

**Response:** `DeviceInfo`

**Response Format:**
```
[DeviceInfo] [1B: firmwareVer] [6B: reserved] [12B: buildDate] [string: model]
```

**Example:**
```javascript
const info = await connection.deviceQuery(1);
console.log(`Firmware v${info.firmwareVer}, ${info.manufacturerModel}`);
```

---

### ExportPrivateKey
Export device's Ed25519 private key.

**Format:**
```
[ExportPrivateKey]
```

**Response:** `PrivateKey` or `Disabled`

**Response Format (PrivateKey):**
```
[PrivateKey] [64B: privateKey]
```

**Security Note:** May be disabled in firmware for security.

---

### ImportPrivateKey
Import Ed25519 private key to device.

**Format:**
```
[ImportPrivateKey] [64B: privateKey]
```

**Parameters:**
- `privateKey` (64 bytes): Ed25519 private key

**Response:** `Ok`, `Err`, or `Disabled`

**Security Note:** May be disabled in firmware.

---

### SendRawData
Send raw custom data through mesh.

**Format:**
```
[SendRawData] [1B: pathLen] [N bytes: path] [M bytes: rawData]
```

**Parameters:**
- `pathLen` (uint8): Length of routing path
- `path` (N bytes): Routing path
- `rawData` (M bytes): Custom payload

**Response:** `Ok` or `Err`

---

### SendLogin
Authenticate with repeater or room server.

**Format:**
```
[SendLogin] [32B: publicKey] [string: password]
```

**Parameters:**
- `publicKey` (32 bytes): Server's public key
- `password` (string): Login password (max 15 chars)

**Response:** `Sent`

**Push:** `LoginSuccess` (when authenticated)

**Example:**
```javascript
await connection.login(repeaterPublicKey, "mypassword");
// Waits for LoginSuccess push
```

---

### SendStatusReq
Request status information from repeater.

**Format:**
```
[SendStatusReq] [32B: publicKey]
```

**Parameters:**
- `publicKey` (32 bytes): Repeater's public key

**Response:** `Sent`

**Push:** `StatusResponse` (with repeater stats)

**Status Response Format:**
```javascript
{
    batt_milli_volts: uint16,      // Battery voltage (mV)
    curr_tx_queue_len: uint16,     // Transmit queue length
    noise_floor: int16,             // Noise floor (dBm)
    last_rssi: int16,               // Last RSSI (dBm)
    n_packets_recv: uint32,         // Total packets received
    n_packets_sent: uint32,         // Total packets sent
    total_air_time_secs: uint32,    // Total air time (seconds)
    total_up_time_secs: uint32,     // Uptime (seconds)
    n_sent_flood: uint32,           // Flood packets sent
    n_sent_direct: uint32,          // Direct packets sent
    n_recv_flood: uint32,           // Flood packets received
    n_recv_direct: uint32,          // Direct packets received
    err_events: uint16,             // Error events
    last_snr: int16,                // Last SNR (×4)
    n_direct_dups: uint16,          // Duplicate direct packets
    n_flood_dups: uint16,           // Duplicate flood packets
}
```

---

### SendTelemetryReq
Request telemetry data from contact.

**Format:**
```
[SendTelemetryReq] [3B: reserved] [32B: publicKey]
```

**Parameters:**
- `reserved` (3 bytes): Reserved (set to 0)
- `publicKey` (32 bytes): Contact's public key

**Response:** `Sent`

**Push:** `TelemetryResponse` (with Cayenne LPP data)

**Example:**
```javascript
const telemetry = await connection.getTelemetry(contactPublicKey);
console.log(telemetry.lppSensorData);  // Parse with Cayenne LPP parser
```

---

### SendBinaryReq
Send custom binary request to contact.

**Format:**
```
[SendBinaryReq] [32B: publicKey] [N bytes: requestCodeAndParams]
```

**Parameters:**
- `publicKey` (32 bytes): Target contact
- `requestCodeAndParams` (variable): Application-specific request

**Response:** `Sent`

**Push:** `BinaryResponse` (with tag and response data)

**Binary Request Types:**
- `GetNeighbours` (0x00): Query repeater for neighbor list

---

### GetChannel
Get channel configuration by index.

**Format:**
```
[GetChannel] [1B: channelIdx]
```

**Parameters:**
- `channelIdx` (uint8): Channel index (0-N)

**Response:** `ChannelInfo` or `Err`

**Response Format:**
```
[ChannelInfo] [1B: idx] [32B: name] [16B: secret]
```

**Example:**
```javascript
const channel = await connection.getChannel(0);
console.log(`Channel: ${channel.name}`);
```

---

### SetChannel
Set channel configuration.

**Format:**
```
[SetChannel] [1B: channelIdx] [32B: name] [16B: secret]
```

**Parameters:**
- `channelIdx` (uint8): Channel index
- `name` (32 bytes): Channel name as C-string
- `secret` (16 bytes): AES-128 shared key

**Response:** `Ok` or `Err`

**Example:**
```javascript
// Delete channel
await connection.deleteChannel(0);
// Internally: setChannel(0, "", new Uint8Array(16))
```

---

### SignStart
Start signing session.

**Format:**
```
[SignStart]
```

**Response:** `SignStart`

**Response Format:**
```
[SignStart] [1B: reserved] [4B: maxSignDataLen]
```

---

### SignData
Send data chunk to sign.

**Format:**
```
[SignData] [N bytes: dataToSign]
```

**Parameters:**
- `dataToSign`: Data chunk (max 128 bytes)

**Response:** `Ok` (send next chunk)

---

### SignFinish
Finish signing and retrieve signature.

**Format:**
```
[SignFinish]
```

**Response:** `Signature`

**Response Format:**
```
[Signature] [64B: signature]
```

**Example:**
```javascript
const signature = await connection.sign(data);
// Automatically handles chunking
```

---

### SendTracePath
Trace path through mesh network.

**Format:**
```
[SendTracePath] [4B: tag] [4B: auth] [1B: flags] [N bytes: path]
```

**Parameters:**
- `tag` (uint32 LE): Random tag for matching response
- `auth` (uint32 LE): Authentication code (usually 0)
- `flags` (uint8): Trace flags
- `path` (variable): Routing path to trace

**Response:** `Sent`

**Push:** `TraceData`

**Trace Data Format:**
```javascript
{
    reserved: uint8,
    pathLen: uint8,
    flags: uint8,
    tag: uint32,
    authCode: uint32,
    pathHashes: Uint8Array,  // Node IDs
    pathSnrs: Uint8Array,    // SNR at each hop
    lastSnr: float,          // Final SNR (÷4)
}
```

**Example:**
```javascript
const trace = await connection.tracePath(path);
console.log(`Path length: ${trace.pathLen}`);
console.log(`SNRs: ${trace.pathSnrs}`);
```

---

### SetOtherParams
Set miscellaneous device parameters.

**Format:**
```
[SetOtherParams] [1B: manualAddContacts]
```

**Parameters:**
- `manualAddContacts` (uint8): 0=auto-add, 1=manual-add

**Response:** `Ok` or `Err`

**Example:**
```javascript
await connection.setAutoAddContacts();    // Auto-add from advertisements
await connection.setManualAddContacts();  // Require manual addition
```

---

## Binary Request Types

Sent via `SendBinaryReq` command:

### GetNeighbours (0x00)
Query repeater for neighbor list.

**Request Format:**
```
[0x00] [1B: version] [1B: count] [2B: offset] [1B: orderBy] [1B: prefixLen] [4B: random]
```

**Parameters:**
- `version` (uint8): Request version (0)
- `count` (uint8): Max neighbors to return
- `offset` (uint16 LE): Pagination offset
- `orderBy` (uint8): Sort order
  - 0: Newest to oldest
  - 1: Oldest to newest
  - 2: Strongest to weakest (SNR)
  - 3: Weakest to strongest
- `prefixLen` (uint8): Public key prefix length (1-32)
- `random` (uint32 LE): Random blob for hash uniqueness

**Response Format:**
```
[2B: totalCount] [2B: resultsCount] [repeated: neighbor entries]
```

**Neighbor Entry:**
```
[N bytes: pubKeyPrefix] [4B: heardSecondsAgo] [1B: snr]
```

**Example:**
```javascript
const result = await connection.getNeighbours(
    repeaterPublicKey,
    10,    // count
    0,     // offset
    2,     // order by strongest
    8      // 8-byte prefix
);
console.log(`Total neighbors: ${result.totalNeighboursCount}`);
result.neighbours.forEach(n => {
    console.log(`  ${n.publicKeyPrefix.toString('hex')} - SNR: ${n.snr} dB`);
});
```

---

## Response Details

### SelfInfo
Device information response.

**Format:**
```
[SelfInfo] [1B: type] [1B: txPower] [1B: maxTxPower] [32B: publicKey]
           [4B: advLat] [4B: advLon] [3B: reserved] [1B: manualAddContacts]
           [4B: radioFreq] [4B: radioBw] [1B: radioSf] [1B: radioCr] [string: name]
```

**Fields:**
```javascript
{
    type: uint8,               // Device type
    txPower: uint8,            // Current TX power (dBm)
    maxTxPower: uint8,         // Maximum TX power
    publicKey: Uint8Array,     // 32-byte public key
    advLat: int32,             // GPS latitude (×10000)
    advLon: int32,             // GPS longitude (×10000)
    reserved: Uint8Array,      // 3 bytes reserved
    manualAddContacts: uint8,  // 0=auto, 1=manual
    radioFreq: uint32,         // Frequency (Hz)
    radioBw: uint32,           // Bandwidth (Hz)
    radioSf: uint8,            // Spreading factor
    radioCr: uint8,            // Coding rate
    name: string,              // Device name
}
```

---

### Contact
Contact entry response.

**Format:**
```
[Contact] [32B: publicKey] [1B: type] [1B: flags] [1B: outPathLen] [64B: outPath]
          [32B: advName] [4B: lastAdvert] [4B: advLat] [4B: advLon] [4B: lastMod]
```

**Fields:**
```javascript
{
    publicKey: Uint8Array,     // 32-byte public key
    type: uint8,               // 0=none, 1=chat, 2=repeater, 3=room
    flags: uint8,              // Contact flags
    outPathLen: int8,          // Path length
    outPath: Uint8Array,       // 64-byte path (padded)
    advName: string,           // Name (32-byte C-string)
    lastAdvert: uint32,        // Last advertisement time
    advLat: uint32,            // GPS latitude (×10000)
    advLon: uint32,            // GPS longitude (×10000)
    lastMod: uint32,           // Last modification time
}
```

---

### ContactMsgRecv
Contact message received.

**Format:**
```
[ContactMsgRecv] [6B: pubKeyPrefix] [1B: pathLen] [1B: txtType] [4B: senderTimestamp] [string: text]
```

**Fields:**
```javascript
{
    pubKeyPrefix: Uint8Array,  // 6-byte sender public key prefix
    pathLen: uint8,            // Hop count (0xFF=direct)
    txtType: uint8,            // Message type
    senderTimestamp: uint32,   // Sender's timestamp
    text: string,              // Message text
}
```

---

### ChannelMsgRecv
Channel message received.

**Format:**
```
[ChannelMsgRecv] [1B: channelIdx] [1B: pathLen] [1B: txtType] [4B: senderTimestamp] [string: text]
```

**Fields:**
```javascript
{
    channelIdx: int8,          // Channel index (0=public)
    pathLen: uint8,            // Hop count (0xFF=direct)
    txtType: uint8,            // Message type
    senderTimestamp: uint32,   // Sender's timestamp
    text: string,              // Message text
}
```

---

### Sent
Message sent to mesh network.

**Format:**
```
[Sent] [1B: result] [4B: expectedAckCrc] [4B: estTimeout]
```

**Fields:**
```javascript
{
    result: int8,              // Send result code
    expectedAckCrc: uint32,    // CRC for ACK matching
    estTimeout: uint32,        // Estimated timeout (ms)
}
```

---

## Push Notifications

### PathUpdated
Routing path updated for contact.

**Format:**
```
[PathUpdated] [32B: publicKey]
```

---

### SendConfirmed
Message ACK received from network.

**Format:**
```
[SendConfirmed] [4B: ackCode] [4B: roundTrip]
```

**Fields:**
```javascript
{
    ackCode: uint32,           // ACK code (matches expectedAckCrc)
    roundTrip: uint32,         // Round-trip time (ms)
}
```

---

### MsgWaiting
Messages queued on device.

**Format:**
```
[MsgWaiting]
```

**Action:** Call `SyncNextMessage` to retrieve.

---

### NewAdvert
New contact advertised on network.

**Format:**
```
[NewAdvert] [32B: publicKey] [1B: type] [1B: flags] [1B: outPathLen] [64B: outPath]
            [32B: advName] [4B: lastAdvert] [4B: advLat] [4B: advLon] [4B: lastMod]
```

(Same structure as `Contact` response)

---

## Error Codes

**Err Response Format:**
```
[Err] [1B: errCode]?
```

Error codes are application-specific. Check firmware documentation for specific codes.

---

## Usage Patterns

### Initialize Connection
```javascript
// Called automatically on connect
await connection.onConnected();
// Sends: AppStart with protocol version
```

### Send Message
```javascript
const contact = await connection.findContactByName("Alice");
await connection.sendTextMessage(contact.publicKey, "Hello!");
```

### Sync Messages
```javascript
const messages = await connection.getWaitingMessages();
messages.forEach(msg => {
    if (msg.contactMessage) {
        console.log(`From contact: ${msg.contactMessage.text}`);
    } else if (msg.channelMessage) {
        console.log(`From channel: ${msg.channelMessage.text}`);
    }
});
```

### Monitor Events
```javascript
connection.on('NewAdvert', (data) => {
    console.log(`New contact: ${data.advName}`);
});

connection.on('SendConfirmed', (data) => {
    console.log(`Message confirmed in ${data.roundTrip}ms`);
});
```

---

## Implementation Notes

### Timeouts
Most commands have default timeouts. For requests expecting mesh responses:
- Use `estTimeout` from `Sent` response
- Add extra buffer time (e.g., +1000ms)
- Implement exponential backoff for retries

### Buffering
BLE packets may arrive fragmented:
- Buffer incoming data until complete frame received
- Use frame length headers when available
- Implement packet boundary detection

### Thread Safety
Connection is event-driven:
- Use promises for request/response pattern
- Remove event listeners after use
- Handle concurrent requests carefully

### Security
- Verify signatures on received advertisements
- Validate public keys before import
- Sanitize user input (names, messages)
- Rate limit commands to prevent DoS

---

## References

- [meshcore.js Connection class](https://github.com/meshcore-dev/meshcore.js/blob/main/src/connection/connection.js)
- [MeshCore Firmware](https://github.com/meshcore-dev/MeshCore)
- [MESHCORE_PROTOCOL.md](MESHCORE_PROTOCOL.md) - Mesh packet protocol
- [MESHCORE_QUICK_REFERENCE.md](MESHCORE_QUICK_REFERENCE.md) - Quick reference card

---

**Document Version:** 1.0
**Last Updated:** 2025-10-14
**Compatible with:** MeshCore firmware v1.9.0+, meshcore.js v1.x
