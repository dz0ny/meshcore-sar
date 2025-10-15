import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/contact.dart';
import '../models/contact_telemetry.dart';
import '../models/message.dart';
import '../models/ble_packet_log.dart';
import 'buffer_reader.dart';
import 'buffer_writer.dart';
import 'meshcore_constants.dart';
import 'meshcore_opcode_names.dart';

/// Callback types for MeshCore events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback = void Function(Uint8List publicKey, Uint8List lppData);
typedef OnSelfInfoCallback = void Function(Map<String, dynamic> selfInfo);
typedef OnDeviceInfoCallback = void Function(Map<String, dynamic> deviceInfo);
typedef OnNoMoreMessagesCallback = void Function();
typedef OnMessageWaitingCallback = void Function();
typedef OnLoginSuccessCallback = void Function(Uint8List publicKeyPrefix, int permissions, bool isAdmin, int tag);
typedef OnLoginFailCallback = void Function(Uint8List publicKeyPrefix);
typedef OnAdvertReceivedCallback = void Function(Uint8List publicKey);
typedef OnPathUpdatedCallback = void Function(Uint8List publicKey);
typedef OnMessageSentCallback = void Function(int expectedAckTag, int suggestedTimeoutMs, bool isFloodMode);
typedef OnMessageDeliveredCallback = void Function(int ackCode, int roundTripTimeMs);
typedef OnStatusResponseCallback = void Function(Uint8List publicKeyPrefix, Uint8List statusData);
typedef OnBinaryResponseCallback = void Function(Uint8List publicKeyPrefix, int tag, Uint8List responseData);
typedef OnBatteryAndStorageCallback = void Function(int millivolts, int? usedKb, int? totalKb);
typedef OnErrorCallback = void Function(String error);
typedef OnConnectionStateCallback = void Function(bool isConnected);

/// MeshCore BLE Service - handles all BLE communication
class MeshCoreBleService {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _txCharacteristic;
  StreamSubscription? _txSubscription;

  // Event callbacks
  OnConnectionStateCallback? onConnectionStateChanged;
  OnContactCallback? onContactReceived;
  OnContactsCompleteCallback? onContactsComplete;
  OnMessageCallback? onMessageReceived;
  OnTelemetryCallback? onTelemetryReceived;
  OnSelfInfoCallback? onSelfInfoReceived;
  OnDeviceInfoCallback? onDeviceInfoReceived;
  OnNoMoreMessagesCallback? onNoMoreMessages;
  OnMessageWaitingCallback? onMessageWaiting;
  OnLoginSuccessCallback? onLoginSuccess;
  OnLoginFailCallback? onLoginFail;
  OnAdvertReceivedCallback? onAdvertReceived;
  OnPathUpdatedCallback? onPathUpdated;
  OnMessageSentCallback? onMessageSent;
  OnMessageDeliveredCallback? onMessageDelivered;
  OnStatusResponseCallback? onStatusResponse;
  OnBinaryResponseCallback? onBinaryResponse;
  OnBatteryAndStorageCallback? onBatteryAndStorage;
  OnErrorCallback? onError;

  // Internal state
  final List<Contact> _pendingContacts = [];
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Packet counters
  int _rxPacketCount = 0;
  int _txPacketCount = 0;
  int get rxPacketCount => _rxPacketCount;
  int get txPacketCount => _txPacketCount;

  // Activity callbacks (for blinking indicators)
  VoidCallback? onRxActivity;
  VoidCallback? onTxActivity;

  // Packet logging
  final List<BlePacketLog> _packetLogs = [];
  List<BlePacketLog> get packetLogs => List.unmodifiable(_packetLogs);
  static const int _maxLogSize = 1000; // Keep last 1000 packets

  /// Scan for MeshCore devices
  Stream<BluetoothDevice> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    try {
      print('🔍 [BLE] Starting scan for MeshCore devices...');
      print('  Service UUID: ${MeshCoreConstants.bleServiceUuid}');
      print('  Timeout: ${timeout.inSeconds}s');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withServices: [Guid(MeshCoreConstants.bleServiceUuid)],
      );
      print('✅ [BLE] Scan started successfully');

      // Listen to scan results
      int deviceCount = 0;
      await for (final scanResult in FlutterBluePlus.scanResults) {
        print('📡 [BLE] Scan results batch received: ${scanResult.length} results');
        for (final result in scanResult) {
          print('  Device: ${result.device.platformName} (${result.device.remoteId})');
          print('    RSSI: ${result.rssi}');
          print('    Service UUIDs: ${result.advertisementData.serviceUuids}');

          if (result.advertisementData.serviceUuids
              .contains(Guid(MeshCoreConstants.bleServiceUuid))) {
            deviceCount++;
            print('  ✅ MeshCore device found! Total: $deviceCount');
            yield result.device;
          } else {
            print('  ❌ Not a MeshCore device (service UUID mismatch)');
          }
        }
      }
      print('🏁 [BLE] Scan completed. Found $deviceCount MeshCore devices');
    } catch (e) {
      print('❌ [BLE] Scan error: $e');
      onError?.call('Scan error: $e');
    }
  }

  /// Connect to a MeshCore device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      print('🔵 [BLE] Starting connection to device: ${device.platformName} (${device.remoteId})');
      _device = device;

      // Connect to device
      print('🔵 [BLE] Calling device.connect() with 15s timeout...');
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 15),
        mtu: 512,
      );
      print('✅ [BLE] Device connected successfully');

      // Discover services
      print('🔵 [BLE] Discovering services...');
      final services = await device.discoverServices();
      print('✅ [BLE] Found ${services.length} services');

      // Log all discovered services for debugging
      for (final service in services) {
        print('  📋 Service: ${service.uuid}');
        for (final char in service.characteristics) {
          print('    - Characteristic: ${char.uuid}');
        }
      }

      // Find MeshCore service
      print('🔵 [BLE] Looking for MeshCore service: ${MeshCoreConstants.bleServiceUuid}');
      BluetoothService? meshCoreService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() ==
            MeshCoreConstants.bleServiceUuid.toLowerCase()) {
          meshCoreService = service;
          print('✅ [BLE] Found MeshCore service');
          break;
        }
      }

      if (meshCoreService == null) {
        print('❌ [BLE] MeshCore service not found!');
        throw Exception('MeshCore service not found');
      }

      // Find RX and TX characteristics
      print('🔵 [BLE] Looking for RX and TX characteristics...');
      print('  RX UUID: ${MeshCoreConstants.bleCharacteristicRxUuid}');
      print('  TX UUID: ${MeshCoreConstants.bleCharacteristicTxUuid}');

      for (final characteristic in meshCoreService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        print('  📋 Checking characteristic: $uuid');

        if (uuid == MeshCoreConstants.bleCharacteristicRxUuid.toLowerCase()) {
          _rxCharacteristic = characteristic;
          print('  ✅ Found RX characteristic');
        } else if (uuid ==
            MeshCoreConstants.bleCharacteristicTxUuid.toLowerCase()) {
          _txCharacteristic = characteristic;
          print('  ✅ Found TX characteristic');
        }
      }

      if (_rxCharacteristic == null || _txCharacteristic == null) {
        print('❌ [BLE] Required characteristics not found!');
        print('  RX found: ${_rxCharacteristic != null}');
        print('  TX found: ${_txCharacteristic != null}');
        throw Exception('Required characteristics not found');
      }

      // Enable notifications on TX characteristic
      print('🔵 [BLE] Enabling notifications on TX characteristic...');
      await _txCharacteristic!.setNotifyValue(true);
      print('✅ [BLE] Notifications enabled');

      // Listen to TX characteristic
      print('🔵 [BLE] Setting up TX characteristic listener...');
      _txSubscription = _txCharacteristic!.lastValueStream.listen(
        _onDataReceived,
        onError: (error) {
          print('❌ [BLE] TX notification error: $error');
          onError?.call('TX notification error: $error');
        },
      );
      print('✅ [BLE] TX listener configured');

      _isConnected = true;
      print('🔵 [BLE] Notifying connection state change: connected');
      onConnectionStateChanged?.call(true);

      // Send initial device query
      print('🔵 [BLE] Sending initial device query...');
      await _sendDeviceQuery();
      print('✅ [BLE] Device query sent');

      print('✅✅✅ [BLE] Connection completed successfully!');
      return true;
    } catch (e) {
      print('❌❌❌ [BLE] Connection failed: $e');
      print('Stack trace: ${StackTrace.current}');
      onError?.call('Connection error: $e');
      _isConnected = false;
      onConnectionStateChanged?.call(false);
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      await _txSubscription?.cancel();
      await _device?.disconnect();
      _isConnected = false;
      _device = null;
      _rxCharacteristic = null;
      _txCharacteristic = null;
      onConnectionStateChanged?.call(false);
    } catch (e) {
      onError?.call('Disconnect error: $e');
    }
  }

  /// Write data to RX characteristic
  Future<void> _writeData(Uint8List data) async {
    if (_rxCharacteristic == null) {
      throw Exception('Not connected');
    }
    try {
      // Extract command code from first byte
      final commandCode = data.isNotEmpty ? data[0] : null;
      final opcodeName = commandCode != null
          ? MeshCoreOpcodeNames.getCommandName(commandCode)
          : 'UNKNOWN';
      final opcodeHex = commandCode != null
          ? '0x${commandCode.toRadixString(16).padLeft(2, '0').toUpperCase()}'
          : 'N/A';

      print('📤 [TX] Sending command: $opcodeName ($opcodeHex)');
      print('  Data size: ${data.length} bytes');
      print('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Check if the characteristic supports write without response
      final supportsWriteWithoutResponse = _rxCharacteristic!.properties.writeWithoutResponse;
      final supportsWrite = _rxCharacteristic!.properties.write;

      if (supportsWriteWithoutResponse) {
        await _rxCharacteristic!.write(data, withoutResponse: true);
      } else if (supportsWrite) {
        await _rxCharacteristic!.write(data, withoutResponse: false);
      } else {
        throw Exception('Characteristic does not support write operations');
      }

      // Log TX packet
      _logPacket(data, PacketDirection.tx, responseCode: commandCode);

      // Increment TX packet counter and trigger activity indicator
      _txPacketCount++;
      onTxActivity?.call();

      print('✅ [TX] Command sent successfully');
    } catch (e) {
      print('❌ [TX] Write error: $e');
      onError?.call('Write error: $e');
      rethrow;
    }
  }

  /// Handle incoming data from TX characteristic
  void _onDataReceived(List<int> data) {
    try {
      // Handle empty data
      if (data.isEmpty) {
        print('⚠️ [RX] Empty data received, ignoring');
        return;
      }

      final dataBytes = Uint8List.fromList(data);

      // Increment RX packet counter and trigger activity indicator
      _rxPacketCount++;
      onRxActivity?.call();

      final reader = BufferReader(dataBytes);
      final responseCode = reader.readByte();

      // Get opcode name for logging
      final opcodeName = MeshCoreOpcodeNames.getOpcodeName(responseCode, isTx: false);
      final opcodeHex = '0x${responseCode.toRadixString(16).padLeft(2, '0').toUpperCase()}';

      print('📥 [RX] Received: $opcodeName ($opcodeHex)');
      print('  Data size: ${data.length} bytes');
      print('  Hex: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('  Payload: ${reader.remainingBytesCount} bytes');

      // Log RX packet (before processing so we capture everything)
      _logPacket(dataBytes, PacketDirection.rx, responseCode: responseCode);

      switch (responseCode) {
        case MeshCoreConstants.respContactsStart:
          print('  → Handling ContactsStart');
          _handleContactsStart(reader);
          break;
        case MeshCoreConstants.respContact:
          print('  → Handling Contact');
          _handleContact(reader);
          break;
        case MeshCoreConstants.respEndOfContacts:
          print('  → Handling EndOfContacts');
          _handleEndOfContacts(reader);
          break;
        case MeshCoreConstants.respSent:
          print('  → Handling Sent confirmation');
          _handleSentConfirmation(reader);
          break;
        case MeshCoreConstants.respContactMsgRecv:
          print('  → Handling ContactMessage');
          _handleContactMessage(reader);
          break;
        case MeshCoreConstants.respChannelMsgRecv:
          print('  → Handling ChannelMessage');
          _handleChannelMessage(reader);
          break;
        case MeshCoreConstants.pushTelemetryResponse:
          print('  → Handling TelemetryResponse');
          _handleTelemetryResponse(reader);
          break;
        case MeshCoreConstants.pushBinaryResponse:
          print('  → Handling BinaryResponse');
          _handleBinaryResponse(reader);
          break;
        case MeshCoreConstants.respDeviceInfo:
          print('  → Handling DeviceInfo');
          _handleDeviceInfo(reader);
          break;
        case MeshCoreConstants.respSelfInfo:
          print('  → Handling SelfInfo');
          _handleSelfInfo(reader);
          break;
        case MeshCoreConstants.pushAdvert:
          print('  → Handling Advert push');
          _handleAdvert(reader);
          break;
        case MeshCoreConstants.pushPathUpdated:
          print('  → Handling PathUpdated push');
          _handlePathUpdated(reader);
          break;
        case MeshCoreConstants.pushLogRxData:
          print('  → Handling LogRxData push');
          _handleLogRxData(reader);
          break;
        case MeshCoreConstants.pushNewAdvert:
          print('  → Handling NewAdvert push');
          _handleNewAdvert(reader);
          break;
        case MeshCoreConstants.pushSendConfirmed:
          print('  → Handling SendConfirmed push');
          _handleSendConfirmed(reader);
          break;
        case MeshCoreConstants.pushMsgWaiting:
          print('  → Handling MsgWaiting push');
          _handleMsgWaiting(reader);
          break;
        case MeshCoreConstants.pushLoginSuccess:
          print('  → Handling LoginSuccess push');
          _handleLoginSuccess(reader);
          break;
        case MeshCoreConstants.pushLoginFail:
          print('  → Handling LoginFail push');
          _handleLoginFail(reader);
          break;
        case MeshCoreConstants.pushStatusResponse:
          print('  → Handling StatusResponse push');
          _handleStatusResponse(reader);
          break;
        case MeshCoreConstants.respCurrTime:
          print('  → Handling CurrentTime');
          _handleCurrentTime(reader);
          break;
        case MeshCoreConstants.respBatteryVoltage:
          print('  → Handling BatteryAndStorage');
          _handleBatteryAndStorage(reader);
          break;
        case MeshCoreConstants.respNoMoreMessages:
          print('  → Response: No More Messages');
          onNoMoreMessages?.call();
          break;
        case MeshCoreConstants.respOk:
          print('  → Response: OK');
          break;
        case MeshCoreConstants.respErr:
          print('  → Response: ERROR');
          _handleError(reader);
          break;
        default:
          print('  ⚠️ Unknown response code: $responseCode');
          break;
      }
      print('✅ [BLE] Data parsed successfully');
    } catch (e, stackTrace) {
      print('❌ [BLE] Data parsing error: $e');
      print('  Stack trace: $stackTrace');
      onError?.call('Data parsing error: $e');
    }
  }

  /// Handle ContactsStart response
  void _handleContactsStart(BufferReader reader) {
    _pendingContacts.clear();
    final count = reader.readUInt32LE();
    // Optional: notify about expected count
  }

  /// Handle Contact response
  void _handleContact(BufferReader reader) {
    try {
      print('  [Contact] Parsing contact...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final publicKey = reader.readBytes(32);
      print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final typeByte = reader.readByte();
      final type = ContactType.fromValue(typeByte);
      print('    Type byte: $typeByte → Type: $type');

      final flags = reader.readByte();
      print('    Flags: $flags (0x${flags.toRadixString(16).padLeft(2, '0')})');

      final outPathLen = reader.readInt8();
      print('    Out path length: $outPathLen');

      final outPath = reader.readBytes(64);
      print('    Out path: ${outPath.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');

      final advName = reader.readCString(32);
      print('    Advertised name: "$advName"');

      final lastAdvert = reader.readUInt32LE();
      print('    Last advert timestamp: $lastAdvert');

      final advLat = reader.readInt32LE();
      print('    Latitude (raw int32): $advLat');
      print('    Latitude (decimal): ${advLat / 1000000.0}°');

      final advLon = reader.readInt32LE();
      print('    Longitude (raw int32): $advLon');
      print('    Longitude (decimal): ${advLon / 1000000.0}°');

      final lastMod = reader.readUInt32LE();
      print('    Last modified timestamp: $lastMod');

      final contact = Contact(
        publicKey: publicKey,
        type: type,
        flags: flags,
        outPathLen: outPathLen,
        outPath: outPath,
        advName: advName,
        lastAdvert: lastAdvert,
        advLat: advLat,
        advLon: advLon,
        lastMod: lastMod,
      );

      print('  ✅ [Contact] Parsed successfully');
      _pendingContacts.add(contact);
      onContactReceived?.call(contact);
    } catch (e) {
      print('  ❌ [Contact] Parsing error: $e');
      onError?.call('Contact parsing error: $e');
    }
  }

  /// Handle EndOfContacts response
  void _handleEndOfContacts(BufferReader reader) {
    onContactsComplete?.call(List.from(_pendingContacts));
    _pendingContacts.clear();
  }

  /// Handle Sent confirmation response (RESP_CODE_SENT)
  ///
  /// Protocol format:
  /// - 1 byte: send type (1=flood, 0=direct)
  /// - 4 bytes: expected ACK code or TAG
  /// - 4 bytes: suggested timeout (uint32, milliseconds)
  void _handleSentConfirmation(BufferReader reader) {
    try {
      print('  [Sent] Parsing sent confirmation...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 9) {
        final sendType = reader.readByte();
        final sendTypeStr = sendType == 1 ? 'flood' : 'direct';
        final isFloodMode = sendType == 1;
        print('    Send type: $sendType ($sendTypeStr)');

        final expectedAckOrTagBytes = reader.readBytes(4);
        final expectedAckTag = ByteData.sublistView(Uint8List.fromList(expectedAckOrTagBytes)).getUint32(0, Endian.little);
        print('    Expected ACK/TAG: ${expectedAckOrTagBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} (uint32: $expectedAckTag)');

        final suggestedTimeout = reader.readUInt32LE();
        print('    Suggested timeout: ${suggestedTimeout}ms');

        print('  ✅ [Sent] Message sent successfully ($sendTypeStr mode, timeout: ${suggestedTimeout}ms)');

        // Notify provider that message was sent
        onMessageSent?.call(expectedAckTag, suggestedTimeout, isFloodMode);
      } else {
        print('  ⚠️ [Sent] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [Sent] Parsing error: $e');
      // Don't call onError - sent confirmations are informational
    }
  }

  /// Handle ContactMsgRecv response
  void _handleContactMessage(BufferReader reader) {
    try {
      print('  [ContactMessage] Parsing contact message...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final pubKeyPrefix = reader.readBytes(6);
      print('    Sender public key prefix: ${pubKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final pathLen = reader.readByte();
      print('    Path length: $pathLen');

      final txtTypeByte = reader.readByte();
      final txtType = MessageTextType.fromValue(txtTypeByte);
      print('    Text type byte: $txtTypeByte → Type: $txtType');

      final senderTimestamp = reader.readUInt32LE();
      print('    Sender timestamp: $senderTimestamp (${DateTime.fromMillisecondsSinceEpoch(senderTimestamp * 1000)})');

      // Handle different message types
      String text;
      Uint8List? senderPrefixExtra;

      if (txtType == MessageTextType.signedPlain) {
        // Signed message format: [4-byte sender prefix][UTF-8 text]
        // Note: Despite the name "signed", this doesn't contain a cryptographic signature
        // It contains 4 extra bytes of the sender's public key prefix for verification
        print('    Signed message detected - extracting extra sender prefix');

        if (reader.remainingBytesCount >= 4) {
          senderPrefixExtra = reader.readBytes(4);
          print('    Extra sender prefix (4 bytes): ${senderPrefixExtra.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

          // Remaining bytes are the actual text
          if (reader.hasRemaining) {
            text = reader.readString();
          } else {
            text = '';
            print('    ⚠️ No text content after sender prefix');
          }
        } else {
          print('    ⚠️ Insufficient bytes for sender prefix (${reader.remainingBytesCount} < 4)');
          // Read remaining bytes as text anyway
          text = reader.readString();
        }
      } else {
        // Plain text message
        text = reader.readString();
      }

      print('    Text: "$text"');

      final message = Message(
        id: '${DateTime.now().millisecondsSinceEpoch}_${pubKeyPrefix.map((b) => b.toRadixString(16)).join()}',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: pubKeyPrefix,
        pathLen: pathLen,
        textType: txtType,
        senderTimestamp: senderTimestamp,
        text: text,
        receivedAt: DateTime.now(),
      );

      print('  ✅ [ContactMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      print('  ❌ [ContactMessage] Parsing error: $e');
      onError?.call('Contact message parsing error: $e');
    }
  }

  /// Handle ChannelMsgRecv response
  void _handleChannelMessage(BufferReader reader) {
    try {
      print('  [ChannelMessage] Parsing channel message...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final channelIdx = reader.readInt8();
      print('    Channel index: $channelIdx');

      final pathLen = reader.readByte();
      print('    Path length: $pathLen');

      final txtTypeByte = reader.readByte();
      final txtType = MessageTextType.fromValue(txtTypeByte);
      print('    Text type byte: $txtTypeByte → Type: $txtType');

      final senderTimestamp = reader.readUInt32LE();
      print('    Sender timestamp: $senderTimestamp (${DateTime.fromMillisecondsSinceEpoch(senderTimestamp * 1000)})');

      // Handle different message types
      String text;
      Uint8List? senderPrefixExtra;

      if (txtType == MessageTextType.signedPlain) {
        // Signed message format: [4-byte sender prefix][UTF-8 text]
        // Note: Despite the name "signed", this doesn't contain a cryptographic signature
        // It contains 4 extra bytes of the sender's public key prefix for verification
        print('    Signed message detected - extracting extra sender prefix');

        if (reader.remainingBytesCount >= 4) {
          senderPrefixExtra = reader.readBytes(4);
          print('    Extra sender prefix (4 bytes): ${senderPrefixExtra.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

          // Remaining bytes are the actual text
          if (reader.hasRemaining) {
            text = reader.readString();
          } else {
            text = '';
            print('    ⚠️ No text content after sender prefix');
          }
        } else {
          print('    ⚠️ Insufficient bytes for sender prefix (${reader.remainingBytesCount} < 4)');
          // Read remaining bytes as text anyway
          text = reader.readString();
        }
      } else {
        // Plain text message
        text = reader.readString();
      }

      print('    Text: "$text"');

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

      print('  ✅ [ChannelMessage] Parsed successfully');
      onMessageReceived?.call(message);
    } catch (e) {
      print('  ❌ [ChannelMessage] Parsing error: $e');
      onError?.call('Channel message parsing error: $e');
    }
  }

  /// Handle TelemetryResponse push
  void _handleTelemetryResponse(BufferReader reader) {
    try {
      print('  [Telemetry] Parsing telemetry response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final reserved = reader.readByte();
      print('    Reserved byte: $reserved');

      final pubKeyPrefix = reader.readBytes(6);
      print('    Public key prefix: ${pubKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final lppSensorData = reader.readRemainingBytes();
      print('    LPP sensor data length: ${lppSensorData.length} bytes');
      print('    LPP sensor data (hex): ${lppSensorData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      print('  ✅ [Telemetry] Parsed successfully');
      onTelemetryReceived?.call(pubKeyPrefix, lppSensorData);
    } catch (e) {
      print('  ❌ [Telemetry] Parsing error: $e');
      onError?.call('Telemetry parsing error: $e');
    }
  }

  /// Handle BinaryResponse push (PUSH_CODE_BINARY_RESPONSE 0x8C)
  ///
  /// Protocol format:
  /// - 1 byte: reserved (zero)
  /// - 4 bytes: tag (uint32, matches RESP_CODE_SENT expected_ack_or_tag)
  /// - N bytes: response data (remainder of frame)
  void _handleBinaryResponse(BufferReader reader) {
    try {
      print('  [BinaryResponse] Parsing binary response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final reserved = reader.readByte();
      print('    Reserved byte: $reserved');

      final tag = reader.readUInt32LE();
      print('    Tag: $tag (matches RESP_CODE_SENT expected_ack_or_tag)');

      final responseData = reader.readRemainingBytes();
      print('    Response data length: ${responseData.length} bytes');
      print('    Response data (hex): ${responseData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      // Extract public key prefix from response data if present
      // Note: The firmware doesn't include the sender's public key prefix in binary responses
      // The app must track which request corresponds to which tag
      // For now, we'll use an empty prefix and rely on the tag for matching
      final emptyPrefix = Uint8List(6);

      print('  ✅ [BinaryResponse] Parsed successfully');
      onBinaryResponse?.call(emptyPrefix, tag, responseData);
    } catch (e) {
      print('  ❌ [BinaryResponse] Parsing error: $e');
      onError?.call('Binary response parsing error: $e');
    }
  }

  /// Handle DeviceInfo response
  /// Handle DeviceInfo response (RESP_CODE_DEVICE_INFO)
  ///
  /// Protocol format:
  /// - 1 byte: firmware version
  /// - 1 byte: max contacts ÷ 2 (ver 3+)
  /// - 1 byte: max channels (ver 3+)
  /// - 4 bytes: BLE PIN (uint32, ver 3+)
  /// - 12 bytes: firmware build date (ASCII null-terminated)
  /// - 40 bytes: manufacturer model (ASCII null-terminated)
  /// - 20 bytes: semantic version (ASCII null-terminated)
  void _handleDeviceInfo(BufferReader reader) {
    try {
      print('  [DeviceInfo] Parsing device info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount < 1) {
        print('  [DeviceInfo] No data to parse');
        return;
      }

      final firmwareVersion = reader.readByte();
      print('    Firmware version: $firmwareVersion');

      int? maxContacts;
      int? maxChannels;
      int? blePin;
      if (reader.remainingBytesCount >= 6) {
        final maxContactsDiv2 = reader.readByte();
        maxContacts = maxContactsDiv2 * 2;
        print('    Max contacts: $maxContacts');

        maxChannels = reader.readByte();
        print('    Max channels: $maxChannels');

        blePin = reader.readUInt32LE();
        print('    BLE PIN: $blePin');
      }

      String? firmwareBuildDate;
      if (reader.remainingBytesCount >= 12) {
        final buildDateBytes = reader.readBytes(12);
        firmwareBuildDate = String.fromCharCodes(buildDateBytes.takeWhile((b) => b != 0));
        print('    Firmware build date: "$firmwareBuildDate"');
      }

      String? manufacturerModel;
      if (reader.remainingBytesCount >= 40) {
        final modelBytes = reader.readBytes(40);
        manufacturerModel = String.fromCharCodes(modelBytes.takeWhile((b) => b != 0));
        print('    Manufacturer model: "$manufacturerModel"');
      }

      String? semanticVersion;
      if (reader.remainingBytesCount >= 20) {
        final versionBytes = reader.readBytes(20);
        semanticVersion = String.fromCharCodes(versionBytes.takeWhile((b) => b != 0));
        print('    Semantic version: "$semanticVersion"');
      }

      // Call callback with parsed data
      onDeviceInfoReceived?.call({
        'firmwareVersion': firmwareVersion,
        'maxContacts': maxContacts,
        'maxChannels': maxChannels,
        'blePin': blePin,
        'firmwareBuildDate': firmwareBuildDate,
        'manufacturerModel': manufacturerModel,
        'semanticVersion': semanticVersion,
      });

      print('  ✅ [DeviceInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [DeviceInfo] Parsing error: $e');
      onError?.call('DeviceInfo parsing error: $e');
    }
  }

  /// Handle SelfInfo response
  void _handleSelfInfo(BufferReader reader) {
    try {
      print('  [SelfInfo] Parsing self info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // SelfInfo format (RESP_CODE_SELF_INFO):
      // - 1 byte: type (ADV_TYPE_*)
      // - 1 byte: tx power (dBm, current)
      // - 1 byte: max tx power (dBm, max radio supports)
      // - 32 bytes: public key
      // - 4 bytes: adv lat * 1E6 (int32)
      // - 4 bytes: adv lon * 1E6 (int32)
      // - 1 byte: multi ACKs (0=no extra, 1=send extra ACK)
      // - 1 byte: advert location policy (0=don't share, 1=share)
      // - 1 byte: telemetry modes (bits 0-1: Base, bits 2-3: Location)
      // - 1 byte: manual add contacts (0 or 1)
      // - 4 bytes: radio freq * 1000 (uint32)
      // - 4 bytes: radio bw (kHz) * 1000 (uint32)
      // - 1 byte: spreading factor
      // - 1 byte: coding rate
      // - remaining: self name (null-terminated varchar)

      if (reader.remainingBytesCount < 54) {
        print('  [SelfInfo] Insufficient data: ${reader.remainingBytesCount} bytes');
        // Just consume remaining bytes to avoid errors
        reader.readRemainingBytes();
        return;
      }

      print('    📍 BYTE-BY-BYTE PARSING DEBUG:');
      print('    Position before reads: offset=0, remaining=${reader.remainingBytesCount}');

      // NO protocol version byte - it starts with device type!
      final deviceType = reader.readByte();
      print('    [Byte 0] Device type: $deviceType (0x${deviceType.toRadixString(16).padLeft(2, '0')})');

      final txPower = reader.readByte();
      print('    [Byte 1] TX power: $txPower dBm (0x${txPower.toRadixString(16).padLeft(2, '0')})');

      final maxTxPower = reader.readByte();
      print('    [Byte 2] Max TX power: $maxTxPower dBm (0x${maxTxPower.toRadixString(16).padLeft(2, '0')})');

      final publicKey = reader.readBytes(32);
      print('    [Bytes 3-34] Public key (32 bytes): ${publicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}...');

      final advLatBytes = reader.readBytes(4);
      final advLat = ByteData.sublistView(Uint8List.fromList(advLatBytes)).getInt32(0, Endian.little);
      print('    [Bytes 35-38] Adv Lat (raw bytes): ${advLatBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 35-38] Adv Lat (int32 LE): $advLat');
      print('    [Bytes 35-38] Adv Lat (decimal): ${advLat / 1000000.0}°');

      final advLonBytes = reader.readBytes(4);
      final advLon = ByteData.sublistView(Uint8List.fromList(advLonBytes)).getInt32(0, Endian.little);
      print('    [Bytes 39-42] Adv Lon (raw bytes): ${advLonBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 39-42] Adv Lon (int32 LE): $advLon');
      print('    [Bytes 39-42] Adv Lon (decimal): ${advLon / 1000000.0}°');

      final multiAcks = reader.readByte();
      print('    [Byte 43] Multi ACKs: $multiAcks (0x${multiAcks.toRadixString(16).padLeft(2, '0')})');

      final advertLocPolicy = reader.readByte();
      print('    [Byte 44] Advert Loc Policy: $advertLocPolicy (0x${advertLocPolicy.toRadixString(16).padLeft(2, '0')})');

      final telemetryModes = reader.readByte();
      print('    [Byte 45] Telemetry Modes: $telemetryModes (0x${telemetryModes.toRadixString(16).padLeft(2, '0')})');

      final manualAddContacts = reader.readByte();
      print('    [Byte 46] Manual Add Contacts: $manualAddContacts (0x${manualAddContacts.toRadixString(16).padLeft(2, '0')})');

      final radioFreqBytes = reader.readBytes(4);
      final radioFreq = ByteData.sublistView(Uint8List.fromList(radioFreqBytes)).getUint32(0, Endian.little);
      print('    [Bytes 47-50] Radio Freq (raw bytes): ${radioFreqBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 47-50] Radio Freq (uint32 LE): $radioFreq');
      print('    [Bytes 47-50] Radio Freq (MHz): ${radioFreq / 1000.0}');

      final radioBwBytes = reader.readBytes(4);
      final radioBw = ByteData.sublistView(Uint8List.fromList(radioBwBytes)).getUint32(0, Endian.little);
      print('    [Bytes 51-54] Radio BW (raw bytes): ${radioBwBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      print('    [Bytes 51-54] Radio BW (uint32 LE): $radioBw');
      print('    [Bytes 51-54] Radio BW (kHz): ${radioBw / 1000.0}');

      final radioSf = reader.readByte();
      print('    [Byte 55] Radio SF: $radioSf (0x${radioSf.toRadixString(16).padLeft(2, '0')})');

      final radioCr = reader.readByte();
      print('    [Byte 56] Radio CR: $radioCr (0x${radioCr.toRadixString(16).padLeft(2, '0')})');

      print('    Remaining bytes after radio params: ${reader.remainingBytesCount}');

      String? selfName;
      if (reader.hasRemaining) {
        final nameBytes = reader.readRemainingBytes();
        print('    Self name bytes (hex): ${nameBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        print('    Self name bytes (ASCII): ${nameBytes.map((b) => b >= 32 && b <= 126 ? String.fromCharCode(b) : '.')}');
        selfName = String.fromCharCodes(nameBytes.takeWhile((b) => b != 0));
        print('    Self name (parsed): "$selfName"');
      }

      print('    ✅ PARSED SUMMARY:');
      print('       Type: $deviceType');
      print('       TX Power: $txPower / $maxTxPower dBm');
      print('       Position: ${advLat / 1000000.0}°, ${advLon / 1000000.0}°');
      print('       Flags: multiAcks=$multiAcks, locPolicy=$advertLocPolicy, telemetry=$telemetryModes, manual=$manualAddContacts');
      print('       Radio: freq=${radioFreq / 1000.0} MHz, bw=${radioBw / 1000.0} kHz, sf=$radioSf, cr=$radioCr');
      print('       Name: "$selfName"');

      // Call callback with parsed data
      onSelfInfoReceived?.call({
        'deviceType': deviceType,
        'txPower': txPower,
        'maxTxPower': maxTxPower,
        'publicKey': publicKey,
        'advLat': advLat,
        'advLon': advLon,
        'manualAddContacts': manualAddContacts == 1,
        'radioFreq': radioFreq,
        'radioBw': radioBw,
        'radioSf': radioSf,
        'radioCr': radioCr,
        'selfName': selfName,
      });

      print('  ✅ [SelfInfo] Parsed successfully');
    } catch (e) {
      print('  ❌ [SelfInfo] Parsing error: $e');
      // Don't call onError for self info - it's not critical
    }
  }

  /// Handle Advert push (PUSH_CODE_ADVERT)
  ///
  /// This push notification indicates that a node in the mesh network
  /// has broadcast an advertisement packet. The companion radio received
  /// this over-the-air and is notifying the app.
  ///
  /// Protocol format:
  /// - 32 bytes: public key of the advertising node
  ///
  /// Note: This is a passive notification - the companion radio handles
  /// updating the contact automatically. The app can use this to show
  /// real-time network activity or trigger UI updates.
  ///
  /// Behavior:
  /// - If manual_add_contacts=0: Companion radio auto-updates contact, then sends PUSH_CODE_NEW_ADVERT with full details
  /// - If manual_add_contacts=1: App must call CMD_GET_CONTACTS to sync updated contact
  void _handleAdvert(BufferReader reader) {
    try {
      print('  [Advert] Parsing advert push notification...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // Advert format: 32 bytes public key
      if (reader.remainingBytesCount >= 32) {
        final publicKey = reader.readBytes(32);
        final publicKeyPrefix = publicKey.sublist(0, 6);
        final publicKeyFull = publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

        print('    📡 ADVERT RECEIVED FROM NODE:');
        print('       Public key prefix (6 bytes): ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
        print('       Public key (full 32 bytes): $publicKeyFull');
        print('    ℹ️  This indicates the node is broadcasting its presence on the mesh network');
        print('    ℹ️  The companion radio will automatically update contact info for this node');
        print('    ℹ️  Expected follow-up:');
        print('       - If manual_add_contacts=0: You will receive PUSH_CODE_NEW_ADVERT (0x8A) with full contact details');
        print('       - If manual_add_contacts=1: Call CMD_GET_CONTACTS to sync updated contact');

        // Notify callback so app can trigger contact sync if desired
        onAdvertReceived?.call(publicKey);
      } else {
        print('  ⚠️ [Advert] Insufficient data: expected 32 bytes, got ${reader.remainingBytesCount}');
      }

      // Consume any remaining bytes
      if (reader.hasRemaining) {
        final extraBytes = reader.readRemainingBytes();
        print('  ⚠️ [Advert] Extra bytes found: ${extraBytes.length} bytes');
        print('       Extra data (hex): ${extraBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      }

      print('  ✅ [Advert] Parsed successfully');
    } catch (e) {
      print('  ❌ [Advert] Parsing error: $e');
      // Don't call onError - adverts are informational
    }
  }

  /// Handle PathUpdated push (PUSH_CODE_PATH_UPDATED)
  ///
  /// This push notification indicates that the mesh network has discovered
  /// a new or better routing path to a contact. The companion radio sends
  /// this notification when a contact's out_path is updated.
  ///
  /// Protocol format:
  /// - 32 bytes: public key of the contact whose path was updated
  ///
  /// The app can use this to:
  /// - Trigger a contact sync to get the updated path
  /// - Show network topology changes in the UI
  /// - Update signal quality indicators
  void _handlePathUpdated(BufferReader reader) {
    try {
      print('  [PathUpdated] Parsing path updated push notification...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // PathUpdated format: 32 bytes public key
      if (reader.remainingBytesCount >= 32) {
        final publicKey = reader.readBytes(32);
        final publicKeyPrefix = publicKey.sublist(0, 6);
        final publicKeyFull = publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

        print('    📡 PATH UPDATED FOR CONTACT:');
        print('       Public key prefix (6 bytes): ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
        print('       Public key (full 32 bytes): $publicKeyFull');
        print('    ℹ️  The mesh network has discovered a new/better routing path to this contact');
        print('    ℹ️  The companion radio has updated the contact\'s out_path');
        print('    ℹ️  Recommended action: Call CMD_GET_CONTACTS to sync the updated contact info');

        // Notify callback so app can trigger contact sync or update UI
        onPathUpdated?.call(publicKey);
      } else {
        print('  ⚠️ [PathUpdated] Insufficient data: expected 32 bytes, got ${reader.remainingBytesCount}');
      }

      // Consume any remaining bytes
      if (reader.hasRemaining) {
        final extraBytes = reader.readRemainingBytes();
        print('  ⚠️ [PathUpdated] Extra bytes found: ${extraBytes.length} bytes');
        print('       Extra data (hex): ${extraBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
      }

      print('  ✅ [PathUpdated] Parsed successfully');
    } catch (e) {
      print('  ❌ [PathUpdated] Parsing error: $e');
      // Don't call onError - path updates are informational
    }
  }

  /// Handle LogRxData push (PUSH_CODE_LOG_RX_DATA)
  ///
  /// This push notification contains diagnostic data about packets received over-the-air.
  /// Based on MyMesh.cpp logRxRaw() implementation:
  ///
  /// Frame format (after 0x88 opcode):
  /// - Byte 0: SNR × 4 (signed int8, divide by 4 to get SNR in dB)
  /// - Byte 1: RSSI (signed int8, in dBm)
  /// - Bytes 2+: Raw over-the-air packet data (encrypted mesh packet)
  ///
  /// The "raw" data is the actual LoRa packet received from another mesh node,
  /// which is typically encrypted and has high entropy.
  void _handleLogRxData(BufferReader reader) {
    try {
      print('  [LogRxData] Parsing log rx data from over-the-air packet...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      final data = reader.readRemainingBytes();
      print('    Data length: ${data.length} bytes');

      // Parse signal quality metrics (first 2 bytes)
      if (data.length < 2) {
        print('  ⚠️ [LogRxData] Insufficient data (need at least 2 bytes for SNR+RSSI)');
        return;
      }

      final snrRaw = data[0];
      final snrDb = (snrRaw.toSigned(8)) / 4.0; // Convert from int8 and divide by 4
      print('    SNR: ${snrDb.toStringAsFixed(2)} dB (raw byte: 0x${snrRaw.toRadixString(16).padLeft(2, '0')})');

      final rssiDbm = data[1].toSigned(8); // Signed int8
      print('    RSSI: $rssiDbm dBm (raw byte: 0x${data[1].toRadixString(16).padLeft(2, '0')})');

      // Remaining bytes are the raw over-the-air packet
      if (data.length <= 2) {
        print('  ⚠️ [LogRxData] No raw packet data after signal metrics');
        return;
      }

      final rawPacketData = data.sublist(2);
      print('    Raw packet data: ${rawPacketData.length} bytes');
      print('    ℹ️  This is the encrypted LoRa packet received from another mesh node');

      // Variables to store decoded information
      int? airtimeMs;
      Uint8List? senderPublicKey;
      int? ackCode;
      final List<String> embeddedStrings = [];

      // Enhanced hex dump with 16 bytes per line for readability
      print('    📊 RAW PACKET HEX DUMP:');
      for (int i = 0; i < rawPacketData.length; i += 16) {
        final end = (i + 16 < rawPacketData.length) ? i + 16 : rawPacketData.length;
        final chunk = rawPacketData.sublist(i, end);

        // Offset column (4 hex digits)
        final offset = i.toRadixString(16).padLeft(4, '0');

        // Hex bytes (2 hex digits per byte, space separated)
        final hexBytes = chunk.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');

        // ASCII representation (printable chars or '.')
        final ascii = chunk.map((b) {
          if (b >= 32 && b <= 126) {
            return String.fromCharCode(b);
          } else {
            return '.';
          }
        }).join('');

        // Print formatted line: OFFSET: HEX_BYTES | ASCII
        print('       $offset: ${hexBytes.padRight(47)} | $ascii');
      }

      // 🔥 FORCED DECODING - Try ALL possible interpretations
      print('    🔥 FORCED DECODING - EXHAUSTIVE ANALYSIS:');
      print('');

      // ========== INTERPRETATION 1: All Possible uint32 Values ==========
      print('    🔍 [INTERPRETATION 1] All uint32 LE values at each offset:');
      for (int offset = 0; offset <= rawPacketData.length - 4; offset++) {
        final value = ByteData.sublistView(Uint8List.fromList(rawPacketData.sublist(offset, offset + 4))).getUint32(0, Endian.little);
        final valueHex = '0x${value.toRadixString(16).padLeft(8, '0')}';

        String interpretation = '';

        // Check if it's a valid timestamp
        const minTimestamp = 1577836800; // 2020-01-01
        const maxTimestamp = 1893456000; // 2030-01-01
        if (value >= minTimestamp && value <= maxTimestamp) {
          final date = DateTime.fromMillisecondsSinceEpoch(value * 1000);
          interpretation = ' → TIMESTAMP: $date';
        } else if (value < 100000) {
          interpretation = ' → Airtime/Duration: ${value}ms';
        } else if (value > 900000000 && value < 1000000000) {
          interpretation = ' → Radio freq: ${value / 1000} MHz';
        }

        print('       [Offset $offset] uint32: $value ($valueHex)$interpretation');
      }
      print('');

      // ========== INTERPRETATION 2: All Possible int32 Values ==========
      print('    🔍 [INTERPRETATION 2] All int32 LE values (for GPS coordinates):');
      for (int offset = 0; offset <= rawPacketData.length - 4; offset++) {
        final value = ByteData.sublistView(Uint8List.fromList(rawPacketData.sublist(offset, offset + 4))).getInt32(0, Endian.little);
        final latLon = value / 1000000.0;

        String interpretation = '';
        if (latLon >= -90 && latLon <= 90) {
          interpretation = ' → Possible GPS: ${latLon.toStringAsFixed(6)}°';
        }

        print('       [Offset $offset] int32: $value → ${latLon.toStringAsFixed(6)}$interpretation');
      }
      print('');

      // ========== INTERPRETATION 3: All uint16 Values ==========
      print('    🔍 [INTERPRETATION 3] All uint16 LE values:');
      for (int offset = 0; offset <= rawPacketData.length - 2; offset++) {
        final value = ByteData.sublistView(Uint8List.fromList(rawPacketData.sublist(offset, offset + 2))).getUint16(0, Endian.little);
        print('       [Offset $offset] uint16: $value (0x${value.toRadixString(16).padLeft(4, '0')})');
      }
      print('');

      // ========== INTERPRETATION 4: Byte Pair Analysis ==========
      print('    🔍 [INTERPRETATION 4] Byte pair correlation (detect patterns):');
      final Map<int, List<int>> bytePairs = {};
      for (int i = 0; i < rawPacketData.length - 1; i++) {
        final key = rawPacketData[i];
        bytePairs.putIfAbsent(key, () => []);
        bytePairs[key]!.add(rawPacketData[i + 1]);
      }

      // Find repeating patterns
      final repeatingPatterns = bytePairs.entries.where((e) => e.value.length > 1);
      if (repeatingPatterns.isNotEmpty) {
        print('       Repeating byte transitions found:');
        for (final entry in repeatingPatterns) {
          print('         Byte 0x${entry.key.toRadixString(16).padLeft(2, '0')} → ${entry.value.map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}');
        }
      } else {
        print('       No repeating byte transitions (high randomness)');
      }
      print('');

      // ========== INTERPRETATION 5: Nibble Distribution ==========
      print('    🔍 [INTERPRETATION 5] Nibble (half-byte) distribution:');
      final Map<int, int> nibbleHist = {};
      for (final byte in rawPacketData) {
        final high = (byte >> 4) & 0x0F;
        final low = byte & 0x0F;
        nibbleHist[high] = (nibbleHist[high] ?? 0) + 1;
        nibbleHist[low] = (nibbleHist[low] ?? 0) + 1;
      }

      final sortedNibbles = nibbleHist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      print('       Top nibble frequencies:');
      for (int i = 0; i < (sortedNibbles.length < 5 ? sortedNibbles.length : 5); i++) {
        final entry = sortedNibbles[i];
        final bar = '█' * ((entry.value / sortedNibbles[0].value * 20).round());
        print('         0x${entry.key.toRadixString(16)}: ${entry.value.toString().padLeft(3)} $bar');
      }
      print('');

      // ========== INTERPRETATION 6: XOR Pattern Detection ==========
      print('    🔍 [INTERPRETATION 6] XOR pattern detection (simple encryption):');
      final List<int> xorKeys = [0x00, 0xFF, 0xAA, 0x55, 0x42, 0x69];
      for (final xorKey in xorKeys) {
        final xored = rawPacketData.map((b) => b ^ xorKey).toList();
        final printableCount = xored.where((b) => b >= 32 && b <= 126).length;
        final printableRatio = printableCount / xored.length;

        if (printableRatio > 0.3) {
          final preview = String.fromCharCodes(xored.take(20).map((b) => b >= 32 && b <= 126 ? b : 46));
          print('       XOR key 0x${xorKey.toRadixString(16).padLeft(2, '0')}: ${(printableRatio * 100).toStringAsFixed(1)}% printable → "$preview..."');
        }
      }
      print('');

      // ========== INTERPRETATION 7: Sliding Window CRC/Checksum ==========
      print('    🔍 [INTERPRETATION 7] Checksum/CRC candidates (last 1-4 bytes):');
      if (rawPacketData.length >= 2) {
        // Try last byte as checksum
        final lastByte = rawPacketData[rawPacketData.length - 1];
        final payload = rawPacketData.sublist(0, rawPacketData.length - 1);
        final simpleSum = payload.reduce((a, b) => (a + b) & 0xFF);
        final xorSum = payload.reduce((a, b) => a ^ b);

        print('       Last byte: 0x${lastByte.toRadixString(16).padLeft(2, '0')}');
        print('         Simple sum (mod 256): 0x${simpleSum.toRadixString(16).padLeft(2, '0')} ${simpleSum == lastByte ? '✅ MATCH!' : ''}');
        print('         XOR checksum: 0x${xorSum.toRadixString(16).padLeft(2, '0')} ${xorSum == lastByte ? '✅ MATCH!' : ''}');
      }

      if (rawPacketData.length >= 3) {
        final last2 = ByteData.sublistView(Uint8List.fromList(rawPacketData.sublist(rawPacketData.length - 2))).getUint16(0, Endian.little);
        print('       Last 2 bytes (uint16 LE): 0x${last2.toRadixString(16).padLeft(4, '0')} ($last2)');
      }
      print('');

      // ========== INTERPRETATION 8: Bit Pattern Analysis ==========
      print('    🔍 [INTERPRETATION 8] Bit-level analysis:');
      int bitCount1 = 0;
      int bitCount0 = 0;
      for (final byte in rawPacketData) {
        for (int bit = 0; bit < 8; bit++) {
          if ((byte & (1 << bit)) != 0) {
            bitCount1++;
          } else {
            bitCount0++;
          }
        }
      }
      final bitRatio = bitCount1 / (bitCount0 + bitCount1);
      print('       Bit 1 count: $bitCount1 (${(bitRatio * 100).toStringAsFixed(1)}%)');
      print('       Bit 0 count: $bitCount0 (${((1 - bitRatio) * 100).toStringAsFixed(1)}%)');
      print('       Balance: ${(bitRatio - 0.5).abs() < 0.05 ? '✅ Well-balanced (likely encrypted/random)' : '⚠️ Imbalanced (may have structure)'}');
      print('');

      // ========== INTERPRETATION 9: LoRa Modulation Params ==========
      print('    🔍 [INTERPRETATION 9] LoRa modulation parameter candidates:');
      for (int i = 0; i < rawPacketData.length; i++) {
        final byte = rawPacketData[i];

        // Check if it could be spreading factor (7-12)
        if (byte >= 7 && byte <= 12) {
          print('       [Offset $i] Possible SF (Spreading Factor): $byte');
        }

        // Check if it could be coding rate (5-8)
        if (byte >= 5 && byte <= 8) {
          print('       [Offset $i] Possible CR (Coding Rate): $byte');
        }

        // Check if it could be bandwidth index (0-9)
        if (byte >= 0 && byte <= 9) {
          final bwValues = [7.8, 10.4, 15.6, 20.8, 31.25, 41.7, 62.5, 125, 250, 500];
          print('       [Offset $i] Possible BW index: $byte → ${bwValues[byte]} kHz');
        }
      }
      print('');

      // ========== Final Structure Analysis ==========
      print('    🔍 STRUCTURE ANALYSIS:');

      // Calculate entropy to detect encryption
      final uniqueBytes = rawPacketData.toSet().length;
      final entropy = uniqueBytes / rawPacketData.length;
      final isLikelyEncrypted = entropy > 0.7;
      print('       Entropy: ${(entropy * 100).toStringAsFixed(1)}% (${uniqueBytes}/${rawPacketData.length} unique bytes)');
      if (isLikelyEncrypted) {
        print('       ℹ️  High entropy suggests encrypted or compressed data');
      }

      // Look for printable strings (runs of 4+ printable characters)
      final strings = <String>[];
      StringBuffer currentString = StringBuffer();

      for (int i = 0; i < rawPacketData.length; i++) {
        final byte = rawPacketData[i];
        if (byte >= 32 && byte <= 126) {
          // Printable ASCII
          currentString.write(String.fromCharCode(byte));
        } else {
          // Non-printable - end current string if long enough
          if (currentString.length >= 4) {
            strings.add(currentString.toString());
          }
          currentString.clear();
        }
      }
      // Catch final string
      if (currentString.length >= 4) {
        strings.add(currentString.toString());
      }

      if (strings.isNotEmpty) {
        print('       Embedded strings found:');
        for (final str in strings) {
          print('         → "$str"');
          embeddedStrings.add(str);
        }
      } else {
        print('       No printable strings found (likely encrypted/binary data)');
      }

      print('  ✅ [LogRxData] Forced decode complete');

      // Create decoded info for packet log
      final logRxDataInfo = LogRxDataInfo(
        airtimeMs: airtimeMs,
        senderPublicKey: senderPublicKey,
        ackCode: ackCode,
        embeddedStrings: embeddedStrings,
        entropy: entropy,
        isLikelyEncrypted: isLikelyEncrypted,
      );

      // Update the most recent packet log entry with decoded information
      if (_packetLogs.isNotEmpty) {
        final lastLog = _packetLogs.last;
        if (lastLog.responseCode == MeshCoreConstants.pushLogRxData) {
          _packetLogs[_packetLogs.length - 1] = BlePacketLog(
            timestamp: lastLog.timestamp,
            rawData: lastLog.rawData,
            direction: lastLog.direction,
            responseCode: lastLog.responseCode,
            description: lastLog.description,
            logRxDataInfo: logRxDataInfo,
          );
        }
      }
    } catch (e) {
      print('  ❌ [LogRxData] Parsing error: $e');
      // Don't call onError - logs are informational
    }
  }

  /// Handle NewAdvert push
  void _handleNewAdvert(BufferReader reader) {
    try {
      print('  [NewAdvert] Parsing new advertisement...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // NewAdvert format is identical to Contact response:
      // - 32 bytes: public key
      // - 1 byte: type
      // - 1 byte: flags
      // - 1 byte: outPathLen
      // - 64 bytes: outPath
      // - 32 bytes: advName (null-terminated string)
      // - 4 bytes: lastAdvert (uint32)
      // - 4 bytes: advLat (int32)
      // - 4 bytes: advLon (int32)
      // - 4 bytes: lastMod (uint32)

      final publicKey = reader.readBytes(32);
      print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

      final typeByte = reader.readByte();
      final type = ContactType.fromValue(typeByte);
      print('    Type byte: $typeByte → Type: $type');

      final flags = reader.readByte();
      print('    Flags: $flags (0x${flags.toRadixString(16).padLeft(2, '0')})');

      final outPathLen = reader.readInt8();
      print('    Out path length: $outPathLen');

      final outPath = reader.readBytes(64);
      print('    Out path: ${outPath.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}...');

      final advName = reader.readCString(32);
      print('    Advertised name: "$advName"');

      final lastAdvert = reader.readUInt32LE();
      print('    Last advert timestamp: $lastAdvert');

      final advLat = reader.readInt32LE();
      print('    Latitude (raw int32): $advLat');
      print('    Latitude (decimal): ${advLat / 1000000.0}°');

      final advLon = reader.readInt32LE();
      print('    Longitude (raw int32): $advLon');
      print('    Longitude (decimal): ${advLon / 1000000.0}°');

      final lastMod = reader.readUInt32LE();
      print('    Last modified timestamp: $lastMod');

      final contact = Contact(
        publicKey: publicKey,
        type: type,
        flags: flags,
        outPathLen: outPathLen,
        outPath: outPath,
        advName: advName,
        lastAdvert: lastAdvert,
        advLat: advLat,
        advLon: advLon,
        lastMod: lastMod,
      );

      print('  ✅ [NewAdvert] Parsed successfully - new contact advertised on network');
      // Call the contact received callback to add/update the contact
      onContactReceived?.call(contact);
    } catch (e) {
      print('  ❌ [NewAdvert] Parsing error: $e');
      onError?.call('NewAdvert parsing error: $e');
    }
  }

  /// Handle SendConfirmed push (PUSH_CODE_SEND_CONFIRMED)
  ///
  /// Protocol format:
  /// - 4 bytes: ACK code
  /// - 4 bytes: round trip time (uint32, milliseconds)
  void _handleSendConfirmed(BufferReader reader) {
    try {
      print('  [SendConfirmed] Parsing send confirmed...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 8) {
        final ackCodeBytes = reader.readBytes(4);
        final ackCode = ByteData.sublistView(Uint8List.fromList(ackCodeBytes)).getUint32(0, Endian.little);
        print('    ACK code: ${ackCodeBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')} (uint32: $ackCode)');

        final roundTripTime = reader.readUInt32LE();
        print('    Round trip time: ${roundTripTime}ms');

        print('  ✅ [SendConfirmed] Message delivery confirmed (RTT: ${roundTripTime}ms)');

        // Notify provider that message was delivered
        onMessageDelivered?.call(ackCode, roundTripTime);
      } else {
        print('  ⚠️ [SendConfirmed] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [SendConfirmed] Parsing error: $e');
      // Don't call onError - confirmations are informational
    }
  }

  /// Handle MsgWaiting push (PUSH_CODE_MSG_WAITING)
  ///
  /// This push notification indicates that new messages are waiting
  /// in the device queue and should be fetched using syncNextMessage()
  void _handleMsgWaiting(BufferReader reader) {
    try {
      print('  [MsgWaiting] New message(s) waiting in queue');
      print('  ✅ [MsgWaiting] Notifying callback to fetch messages');
      onMessageWaiting?.call();
    } catch (e) {
      print('  ❌ [MsgWaiting] Parsing error: $e');
      // Don't call onError - this is informational
    }
  }

  /// Handle LoginSuccess push (PUSH_CODE_LOGIN_SUCCESS)
  ///
  /// Protocol format:
  /// - 1 byte: permissions (lowest bit = is_admin)
  /// - 6 bytes: public key prefix (first 6 bytes)
  /// - 4 bytes: tag (int32)
  /// - 1 byte: (V7+) new permissions
  void _handleLoginSuccess(BufferReader reader) {
    try {
      print('  [LoginSuccess] Parsing login success...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 11) {
        final permissions = reader.readByte();
        final isAdmin = (permissions & 0x01) != 0;
        print('    Permissions: $permissions (admin: $isAdmin)');

        final publicKeyPrefix = reader.readBytes(6);
        print('    Room public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        final tag = reader.readInt32LE();
        print('    Tag: $tag');

        // V7+ new permissions byte
        int? newPermissions;
        if (reader.hasRemaining) {
          newPermissions = reader.readByte();
          print('    New permissions (V7+): $newPermissions');
        }

        print('  ✅ [LoginSuccess] Successfully logged into room');
        onLoginSuccess?.call(publicKeyPrefix, permissions, isAdmin, tag);
      } else {
        print('  ⚠️ [LoginSuccess] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [LoginSuccess] Parsing error: $e');
      onError?.call('Login success parsing error: $e');
    }
  }

  /// Handle LoginFail push (PUSH_CODE_LOGIN_FAIL)
  ///
  /// Protocol format:
  /// - 1 byte: reserved (zero)
  /// - 6 bytes: public key prefix (first 6 bytes)
  void _handleLoginFail(BufferReader reader) {
    try {
      print('  [LoginFail] Parsing login fail...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 7) {
        final reserved = reader.readByte();
        print('    Reserved: $reserved');

        final publicKeyPrefix = reader.readBytes(6);
        print('    Room public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        print('  ❌ [LoginFail] Failed to login to room (incorrect password or access denied)');
        onLoginFail?.call(publicKeyPrefix);
      } else {
        print('  ⚠️ [LoginFail] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [LoginFail] Parsing error: $e');
      onError?.call('Login fail parsing error: $e');
    }
  }

  /// Handle StatusResponse push (PUSH_CODE_STATUS_RESPONSE)
  ///
  /// This push notification is received in response to CMD_SEND_STATUS_REQ.
  /// It contains status information from a repeater or sensor node.
  ///
  /// Protocol format (PUSH_CODE_STATUS_RESPONSE, 0x87):
  /// - 1 byte: reserved (zero)
  /// - 6 bytes: public key prefix (first 6 bytes of responding node)
  /// - N bytes: status data (remainder of frame, format depends on node type)
  ///
  /// The status data format is node-specific and may include:
  /// - Repeater nodes: uptime, message counts, relay statistics
  /// - Sensor nodes: sensor readings, battery level, operational state
  /// - Room nodes: user counts, message storage stats
  void _handleStatusResponse(BufferReader reader) {
    try {
      print('  [StatusResponse] Parsing status response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 7) {
        final reserved = reader.readByte();
        print('    Reserved: $reserved');

        final publicKeyPrefix = reader.readBytes(6);
        print('    Node public key prefix: ${publicKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        // Read remaining status data
        final statusData = reader.readRemainingBytes();
        print('    Status data: ${statusData.length} bytes');
        print('    Status data (hex): ${statusData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

        // Try to decode as ASCII text if printable
        try {
          final statusText = utf8.decode(statusData, allowMalformed: true);
          if (statusText.isNotEmpty && _isPrintableAscii(statusText)) {
            print('    Status data (text): $statusText');
          }
        } catch (e) {
          // Not text data, that's fine
        }

        print('  ✅ [StatusResponse] Received status response from node');
        onStatusResponse?.call(publicKeyPrefix, statusData);
      } else {
        print('  ⚠️ [StatusResponse] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [StatusResponse] Parsing error: $e');
      onError?.call('Status response parsing error: $e');
    }
  }

  /// Check if a string contains only printable ASCII characters
  bool _isPrintableAscii(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code < 32 || code > 126) {
        // Not printable ASCII (except newlines and tabs which are common)
        if (code != 10 && code != 13 && code != 9) {
          return false;
        }
      }
    }
    return true;
  }

  /// Handle CurrentTime response (RESP_CODE_CURR_TIME)
  ///
  /// Protocol format:
  /// - 4 bytes: current device time (uint32, epoch seconds, UTC)
  void _handleCurrentTime(BufferReader reader) {
    try {
      print('  [CurrentTime] Parsing device time...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 4) {
        final deviceTime = reader.readUInt32LE();
        final appTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final drift = appTime - deviceTime;

        print('    📍 CLOCK COMPARISON:');
        print('       Radio time: $deviceTime (${DateTime.fromMillisecondsSinceEpoch(deviceTime * 1000)})');
        print('       App time:   $appTime (${DateTime.fromMillisecondsSinceEpoch(appTime * 1000)})');
        print('       Clock drift: $drift seconds');

        if (drift.abs() > 60) {
          print('    ⚠️  WARNING: Clock drift exceeds 60 seconds!');
          print('       This may cause login or message sync issues');
          print('       Consider calling setDeviceTime() to sync the radio\'s clock');
        } else if (drift.abs() > 5) {
          print('    ℹ️  Minor clock drift detected (${drift}s)');
        } else {
          print('    ✅ Clocks are well synchronized (drift: ${drift}s)');
        }

        print('  ✅ [CurrentTime] Parsed successfully');
      } else {
        print('  ⚠️ [CurrentTime] Insufficient data for full parsing');
      }
    } catch (e) {
      print('  ❌ [CurrentTime] Parsing error: $e');
      onError?.call('CurrentTime parsing error: $e');
    }
  }


  /// Handle BatteryAndStorage response (RESP_CODE_BATT_AND_STORAGE)
  ///
  /// Protocol format (RESP_CODE_BATT_AND_STORAGE, code 12):
  /// - 2 bytes: Millivolts (uint16)
  /// - 4 bytes: (Optional) Used KB (uint32)
  /// - 4 bytes: (Optional) Total KB (uint32, zero if unknown)
  void _handleBatteryAndStorage(BufferReader reader) {
    try {
      print('  [BatteryAndStorage] Parsing battery and storage info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.remainingBytesCount >= 2) {
        // Battery voltage is always present (uint16)
        final millivolts = reader.readUInt16LE();
        final voltage = millivolts / 1000.0;
        print('    Battery: ${millivolts}mV (${voltage.toStringAsFixed(2)}V)');

        // Storage fields are optional
        int? usedKb;
        int? totalKb;

        if (reader.remainingBytesCount >= 8) {
          // Both storage fields present
          usedKb = reader.readUInt32LE();
          totalKb = reader.readUInt32LE();

          print('    Storage Used: ${usedKb}KB');
          print('    Storage Total: ${totalKb}KB');

          if (totalKb > 0) {
            final usedPercent = (usedKb / totalKb) * 100.0;
            final availableKb = totalKb - usedKb;
            print('    Storage Available: ${availableKb}KB (${(100 - usedPercent).toStringAsFixed(1)}% free)');
            print('    Storage Usage: ${usedPercent.toStringAsFixed(1)}%');
          } else {
            print('    Storage Total is 0 (size unknown)');
          }
        } else if (reader.remainingBytesCount >= 4) {
          // Only used KB present
          usedKb = reader.readUInt32LE();
          print('    Storage Used: ${usedKb}KB');
          print('    Storage Total: Not available');
        } else {
          print('    Storage: Not available');
        }

        // Trigger callback
        onBatteryAndStorage?.call(millivolts, usedKb, totalKb);
        print('  ✅ [BatteryAndStorage] Parsed successfully');
      } else {
        print('  ⚠️ [BatteryAndStorage] Insufficient data (need at least 2 bytes for battery)');
      }
    } catch (e) {
      print('  ❌ [BatteryAndStorage] Parsing error: $e');
      onError?.call('BatteryAndStorage parsing error: $e');
    }
  }
  /// Handle Error response (RESP_CODE_ERR)
  ///
  /// Protocol format:
  /// - 1 byte: error code (ERR_CODE_*)
  void _handleError(BufferReader reader) {
    try {
      print('  [Error] Parsing error response...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      if (reader.hasRemaining) {
        final errorCode = reader.readByte();
        String errorMsg = 'Error code: $errorCode';

        switch (errorCode) {
          case MeshCoreConstants.errUnsupportedCmd:
            errorMsg = 'Unsupported command';
            break;
          case MeshCoreConstants.errNotFound:
            errorMsg = 'Not found';
            break;
          case MeshCoreConstants.errTableFull:
            errorMsg = 'Table full';
            break;
          case MeshCoreConstants.errBadState:
            errorMsg = 'Bad state';
            break;
          case MeshCoreConstants.errFileIoError:
            errorMsg = 'File I/O error';
            break;
          case MeshCoreConstants.errIllegalArg:
            errorMsg = 'Illegal argument';
            break;
        }

        print('  ❌ [Error] $errorMsg');
        onError?.call(errorMsg);
      }
    } catch (e) {
      print('  ❌ [Error] Parsing error: $e');
    }
  }

  /// Send AppStart command
  Future<void> _sendAppStart() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAppStart);
    writer.writeByte(1); // appVer
    writer.writeBytes(Uint8List(6)); // reserved
    writer.writeString('MeshCore SAR'); // appName
    await _writeData(writer.toBytes());
  }

  /// Send DeviceQuery command
  Future<void> _sendDeviceQuery() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdDeviceQuery);
    writer.writeByte(MeshCoreConstants.supportedCompanionProtocolVersion);
    await _writeData(writer.toBytes());
    await _sendAppStart();
  }

  /// Refresh device info (public method)
  Future<void> refreshDeviceInfo() async {
    await _sendDeviceQuery();
  }

  /// Get contacts from device
  Future<void> getContacts() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetContacts);
    await _writeData(writer.toBytes());
  }

  /// Manually add or update a contact on the companion radio
  ///
  /// This is useful when you need to add a room that hasn't advertised yet,
  /// or restore a contact that was deleted from the radio's table.
  ///
  /// **Use case:** If you get ERR_CODE_NOT_FOUND when logging into a room,
  /// use this to add the room contact to the radio's internal table first.
  ///
  /// Protocol format (CMD_ADD_UPDATE_CONTACT):
  /// - 1 byte: command code (9)
  /// - 32 bytes: public key
  /// - 1 byte: type (ADV_TYPE_*)
  /// - 1 byte: flags
  /// - 1 byte: out path length (signed)
  /// - 64 bytes: out path
  /// - 32 bytes: advertised name (null-terminated)
  /// - 4 bytes: last advert timestamp (uint32)
  /// - 4 bytes: (optional) advert latitude * 1E6 (int32)
  /// - 4 bytes: (optional) advert longitude * 1E6 (int32)
  Future<void> addOrUpdateContact(Contact contact) async {
    print('📝 [BLE] Adding/updating contact on companion radio:');
    print('    Name: ${contact.advName}');
    print('    Public key prefix: ${contact.publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('    Type: ${contact.type} (${contact.type.value})');

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAddUpdateContact); // 0x09
    writer.writeBytes(contact.publicKey); // 32 bytes
    writer.writeByte(contact.type.value); // ADV_TYPE_*
    writer.writeByte(contact.flags); // flags
    writer.writeInt8(contact.outPathLen); // path length (signed byte)
    writer.writeBytes(contact.outPath); // 64 bytes

    // Write name as null-terminated string in 32-byte field
    final nameBytes = Uint8List(32);
    final encoded = utf8.encode(contact.advName);
    final copyLen = encoded.length > 31 ? 31 : encoded.length;
    nameBytes.setRange(0, copyLen, encoded);
    writer.writeBytes(nameBytes);

    writer.writeUInt32LE(contact.lastAdvert); // timestamp
    writer.writeInt32LE(contact.advLat); // latitude * 1E6
    writer.writeInt32LE(contact.advLon); // longitude * 1E6

    await _writeData(writer.toBytes());

    print('✅ [BLE] CMD_ADD_UPDATE_CONTACT sent');
    print('    This adds/updates the contact in the radio\'s internal flash storage');
    print('    The contact will persist across reboots and can be used for login');
  }

  /// Send text message to contact (DM)
  ///
  /// Protocol format (CMD_SEND_TXT_MSG):
  /// - 1 byte: command code (2)
  /// - 1 byte: text type (TXT_TYPE_*, 0=plain)
  /// - 1 byte: attempt (0-3, attempt number)
  /// - 4 bytes: sender timestamp (uint32, epoch seconds)
  /// - 6 bytes: recipient public key prefix (first 6 bytes)
  /// - N bytes: text (remainder of frame, varchar, max 160 bytes)
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
    writer.writeBytes(contactPublicKey.sublist(0, 6)); // first 6 bytes of public key
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Send flood-mode text message to channel
  ///
  /// Protocol format (CMD_SEND_CHANNEL_TXT_MSG):
  /// - 1 byte: command code (3)
  /// - 1 byte: text type (TXT_TYPE_*, 0=plain)
  /// - 1 byte: channel index (reserved, 0 for 'public')
  /// - 4 bytes: sender timestamp (uint32, epoch seconds)
  /// - N bytes: text (remainder of frame, max 160 - len(advert_name) - 2)
  ///
  /// Note: For SAR messages, ensure text starts with "S:<emoji>:<lat>,<lon>"
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
    int textType = 0, // TXT_TYPE_PLAIN
  }) async {
    // Note: Max length depends on advert name length, but typically ~140 chars
    if (text.length > 160) {
      throw ArgumentError('Channel message too long (max ~160 characters)');
    }

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg); // 0x03
    writer.writeByte(textType); // TXT_TYPE_*
    writer.writeByte(channelIdx); // 0 for 'public' channel
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000); // epoch seconds
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Request telemetry from contact
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  @Deprecated('Use sendBinaryRequest() instead for better functionality')
  Future<void> requestTelemetry(Uint8List contactPublicKey, {bool zeroHop = false}) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTelemetryReq);
    writer.writeByte(zeroHop ? 0 : 255); // hop count: 0 = direct only, 255 = unlimited
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeBytes(contactPublicKey);
    await _writeData(writer.toBytes());
  }

  /// Send binary request to contact (CMD_SEND_BINARY_REQ)
  ///
  /// Modern replacement for requestTelemetry() with better functionality.
  /// Supports multiple request types including telemetry, access lists, and neighbors.
  ///
  /// Protocol format:
  /// - 1 byte: command code (50)
  /// - 32 bytes: contact public key
  /// - N bytes: request code and params (requestData)
  ///
  /// Common request codes (first byte of requestData):
  /// - 0x03: Get telemetry data (equivalent to old requestTelemetry)
  /// - 0x04: Get average/min/max telemetry
  /// - 0x05: Get access list
  /// - 0x06: Get neighbors list
  ///
  /// Response arrives via onBinaryResponse callback with matching tag.
  ///
  /// Example - request telemetry:
  /// ```dart
  /// await sendBinaryRequest(
  ///   contactPublicKey: contact.publicKey,
  ///   requestData: Uint8List.fromList([0x03]), // BINARY_REQ_GET_TELEMETRY_DATA
  /// );
  /// ```
  Future<void> sendBinaryRequest({
    required Uint8List contactPublicKey,
    required Uint8List requestData,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendBinaryReq); // 0x32 (50)
    writer.writeBytes(contactPublicKey); // 32 bytes
    writer.writeBytes(requestData); // request code + params
    await _writeData(writer.toBytes());
  }

  /// Get battery voltage and storage information
  ///
  /// Sends CMD_GET_BATT_AND_STORAGE (20) to query:
  /// - Battery voltage in millivolts (uint16)
  /// - Used storage in KB (optional uint32)
  /// - Total storage in KB (optional uint32, 0 if unknown)
  ///
  /// Response arrives via onBatteryAndStorage callback
  Future<void> getBatteryAndStorage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetBatteryVoltage);
    await _writeData(writer.toBytes());
  }

  /// Legacy method name for backward compatibility
  @Deprecated('Use getBatteryAndStorage() instead')
  Future<void> getBatteryVoltage() async {
    await getBatteryAndStorage();
  }

  /// Sync next message from device queue
  /// Returns true if a message was retrieved, false if no more messages
  Future<void> syncNextMessage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSyncNextMessage);
    await _writeData(writer.toBytes());
  }

  /// Get device time from companion radio
  ///
  /// Queries the companion radio's current time to detect clock drift.
  /// Response will be RESP_CODE_CURR_TIME (9).
  ///
  /// Protocol format (CMD_GET_DEVICE_TIME):
  /// - 1 byte: command code (5)
  Future<void> getDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetDeviceTime);
    await _writeData(writer.toBytes());
  }

  /// Set device time
  Future<void> setDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetDeviceTime);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _writeData(writer.toBytes());
  }

  /// Send self advertisement packet to mesh network
  ///
  /// This broadcasts the device's current advertisement data (name, location, etc.)
  /// to the mesh network. The device uses its internally stored values from
  /// setAdvertName() and setAdvertLatLon().
  ///
  /// Protocol format (CMD_SEND_SELF_ADVERT):
  /// - 1 byte: command code (7)
  /// - 1 byte: type (0=zero-hop/local, 1=flood/mesh-wide)
  ///
  /// [floodMode] - if true, broadcast to entire mesh network (default)
  ///               if false, only send to direct neighbors (zero-hop)
  Future<void> sendSelfAdvert({bool floodMode = true}) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendSelfAdvert);
    writer.writeByte(floodMode ? MeshCoreConstants.selfAdvertFlood : MeshCoreConstants.selfAdvertZeroHop);
    await _writeData(writer.toBytes());
  }

  /// Set advertised name
  Future<void> setAdvertName(String name) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertName);
    writer.writeString(name);
    await _writeData(writer.toBytes());
  }

  /// Set advertised latitude and longitude
  Future<void> setAdvertLatLon({
    required double latitude,
    required double longitude,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetAdvertLatLon);
    writer.writeInt32LE((latitude * 1000000).round());
    writer.writeInt32LE((longitude * 1000000).round());
    await _writeData(writer.toBytes());
  }

  /// Set radio parameters
  Future<void> setRadioParams({
    required int frequency, // Hz
    required int bandwidth, // 0-9 (see bandwidth options)
    required int spreadingFactor, // 7-12
    required int codingRate, // 5-8
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetRadioParams);
    writer.writeUInt32LE(frequency);
    writer.writeUInt16LE(bandwidth);
    writer.writeByte(spreadingFactor);
    writer.writeByte(codingRate);
    await _writeData(writer.toBytes());
  }

  /// Set transmit power
  Future<void> setTxPower(int powerDbm) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetTxPower);
    writer.writeByte(powerDbm);
    await _writeData(writer.toBytes());
  }

  /// Set other parameters (telemetry modes, advert location policy, manual add contacts)
  ///
  /// Protocol format (CMD_SET_OTHER_PARAMS):
  /// - 1 byte: command code (38)
  /// - 1 byte: manual add contacts (0 or 1)
  /// - 1 byte: telemetry modes (bits 0-1: Base mode, bits 2-3: Location mode)
  ///           Modes: 0=DENY, 1=apply contact.flags, 2=ALLOW ALL
  /// - 1 byte: advert location policy (0=don't share, 1=share)
  /// - 1 byte: multi ACKs (0=no extra, 1=send extra ACK)
  Future<void> setOtherParams({
    required int manualAddContacts, // 0 or 1
    required int telemetryModes, // bits 0-1: Base, bits 2-3: Location
    required int advertLocationPolicy, // 0=don't share, 1=share
    int multiAcks = 0, // 0=no extra, 1=send extra
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetOtherParams);
    writer.writeByte(manualAddContacts);
    writer.writeByte(telemetryModes);
    writer.writeByte(advertLocationPolicy);
    writer.writeByte(multiAcks);
    await _writeData(writer.toBytes());
  }

  /// Send login request to room or repeater
  ///
  /// This sends a login request to the room server via the companion radio.
  ///
  /// **ACTUAL Protocol format (CMD_SEND_LOGIN):**
  /// - 1 byte: command code (26)
  /// - 32 bytes: room public key
  /// - N bytes: password (varchar, max 15 bytes, null-terminated)
  ///
  /// NOTE: The documentation was wrong - there are NO timestamp/sync_since params
  /// in the companion radio protocol. The companion radio's sendLogin() function
  /// handles timestamp internally when it creates the PAYLOAD_TYPE_ANON_REQ packet.
  ///
  /// Response: PUSH_CODE_LOGIN_SUCCESS (0x85) or PUSH_CODE_LOGIN_FAIL (0x86)
  ///
  /// After successful login, the room server will automatically PUSH stored messages.
  ///
  /// IMPORTANT: The companion radio must have the room contact in its own
  /// internal contact table. If you get ERR_CODE_NOT_FOUND (2), the radio
  /// doesn't know about this room. You need to:
  /// 1. Wait for the room to advertise (it will be added automatically)
  /// 2. Import the room contact using CMD_IMPORT_CONTACT
  /// 3. Manually add the room contact using CMD_ADD_UPDATE_CONTACT
  Future<void> loginToRoom({
    required Uint8List roomPublicKey,
    required String password,
  }) async {
    if (password.length > 15) {
      throw ArgumentError('Password exceeds 15 character limit');
    }

    print('🔐 [BLE] Preparing login request:');
    print('    Room public key prefix: ${roomPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('    Password: ${"*" * password.length} (${password.length} chars)');
    print('    ⚠️  NOTE: The companion radio must have this room in its contact table');
    print('           If you get ERR_CODE_NOT_FOUND, the room needs to advertise first or use CMD_ADD_UPDATE_CONTACT');

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendLogin); // 0x1A
    writer.writeBytes(roomPublicKey); // 32 bytes
    writer.writeString(password); // Max 15 bytes, null-terminated
    await _writeData(writer.toBytes());
  }

  /// Send status request to repeater or sensor node
  ///
  /// This sends a status request (CMD_SEND_STATUS_REQ, 0x1B) to a repeater
  /// or sensor node to query its current operational status.
  ///
  /// Protocol format (CMD_SEND_STATUS_REQ):
  /// - 1 byte: command code (27)
  /// - 32 bytes: public key of target node (repeater or sensor)
  ///
  /// Response: PUSH_CODE_STATUS_RESPONSE (0x87) push notification
  ///
  /// The status data format is node-specific:
  /// - Repeater nodes: uptime, message counts, relay statistics
  /// - Sensor nodes: sensor readings, battery level, operational state
  /// - Room nodes: user counts, message storage statistics
  ///
  /// Example usage:
  /// ```dart
  /// bleService.onStatusResponse = (publicKeyPrefix, statusData) {
  ///   print('Status from node: ${utf8.decode(statusData)}');
  /// };
  /// await bleService.sendStatusRequest(repeaterContact.publicKey);
  /// ```
  Future<void> sendStatusRequest(Uint8List contactPublicKey) async {
    print('📊 [BLE] Preparing status request:');
    print('    Target node public key prefix: ${contactPublicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
    print('    ℹ️  Requesting status from repeater/sensor node');

    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendStatusReq); // 0x1B
    writer.writeBytes(contactPublicKey); // 32 bytes
    await _writeData(writer.toBytes());
  }

  /// Log a packet
  void _logPacket(Uint8List data, PacketDirection direction, {int? responseCode}) {
    // Add new packet
    _packetLogs.add(BlePacketLog(
      timestamp: DateTime.now(),
      rawData: data,
      direction: direction,
      responseCode: responseCode,
      description: _getPacketDescription(responseCode, direction),
    ));

    // Limit log size to prevent memory issues
    if (_packetLogs.length > _maxLogSize) {
      _packetLogs.removeAt(0);
    }
  }

  /// Get human-readable description of packet
  String? _getPacketDescription(int? code, PacketDirection direction) {
    if (direction == PacketDirection.tx) {
      // TX packets - command codes
      switch (code) {
        case MeshCoreConstants.cmdGetContacts:
          return 'Get Contacts';
        case MeshCoreConstants.cmdSendTxtMsg:
          return 'Send Text Message';
        case MeshCoreConstants.cmdSendChannelTxtMsg:
          return 'Send Channel Message';
        case MeshCoreConstants.cmdSendTelemetryReq:
          return 'Request Telemetry';
        case MeshCoreConstants.cmdDeviceQuery:
          return 'Device Query';
        case MeshCoreConstants.cmdAppStart:
          return 'App Start';
        case MeshCoreConstants.cmdSendStatusReq:
          return 'Status Request';
        default:
          return null;
      }
    } else {
      // RX packets - response codes
      switch (code) {
        case MeshCoreConstants.respContactsStart:
          return 'Contacts Start';
        case MeshCoreConstants.respContact:
          return 'Contact Info';
        case MeshCoreConstants.respEndOfContacts:
          return 'End of Contacts';
        case MeshCoreConstants.respSent:
          return 'Message Sent';
        case MeshCoreConstants.respContactMsgRecv:
          return 'Contact Message';
        case MeshCoreConstants.respChannelMsgRecv:
          return 'Channel Message';
        case MeshCoreConstants.pushTelemetryResponse:
          return 'Telemetry Data';
        case MeshCoreConstants.respDeviceInfo:
          return 'Device Info';
        case MeshCoreConstants.respSelfInfo:
          return 'Self Info';
        case MeshCoreConstants.pushAdvert:
          return 'Advertisement';
        case MeshCoreConstants.pushPathUpdated:
          return 'Path Updated';
        case MeshCoreConstants.pushLogRxData:
          return 'Log RX Data';
        case MeshCoreConstants.pushNewAdvert:
          return 'New Advertisement';
        case MeshCoreConstants.pushStatusResponse:
          return 'Status Response';
        case MeshCoreConstants.respNoMoreMessages:
          return 'No More Messages';
        case MeshCoreConstants.respOk:
          return 'OK';
        case MeshCoreConstants.respErr:
          return 'ERROR';
        default:
          return null;
      }
    }
  }

  /// Clear packet logs
  void clearPacketLogs() {
    _packetLogs.clear();
  }

  /// Reset packet counters
  void resetCounters() {
    _rxPacketCount = 0;
    _txPacketCount = 0;
  }

  /// Dispose resources
  void dispose() {
    _txSubscription?.cancel();
    _pendingContacts.clear();
    _packetLogs.clear();
  }
}
