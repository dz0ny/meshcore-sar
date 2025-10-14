import 'dart:async';
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

/// Callback types for MeshCore events
typedef OnContactCallback = void Function(Contact contact);
typedef OnContactsCompleteCallback = void Function(List<Contact> contacts);
typedef OnMessageCallback = void Function(Message message);
typedef OnTelemetryCallback = void Function(Uint8List publicKey, Uint8List lppData);
typedef OnSelfInfoCallback = void Function(Map<String, dynamic> selfInfo);
typedef OnNoMoreMessagesCallback = void Function();
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
  OnNoMoreMessagesCallback? onNoMoreMessages;
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
      print('📝 [BLE] Writing ${data.length} bytes to RX characteristic...');
      print('  RX Characteristic properties: ${_rxCharacteristic!.properties}');

      // Check if the characteristic supports write without response
      final supportsWriteWithoutResponse = _rxCharacteristic!.properties.writeWithoutResponse;
      final supportsWrite = _rxCharacteristic!.properties.write;

      print('  Supports writeWithoutResponse: $supportsWriteWithoutResponse');
      print('  Supports write: $supportsWrite');

      if (supportsWriteWithoutResponse) {
        print('  Using write without response');
        await _rxCharacteristic!.write(data, withoutResponse: true);
      } else if (supportsWrite) {
        print('  Using write with response');
        await _rxCharacteristic!.write(data, withoutResponse: false);
      } else {
        throw Exception('Characteristic does not support write operations');
      }

      // Log TX packet (extract command code from first byte)
      final commandCode = data.isNotEmpty ? data[0] : null;
      _logPacket(data, PacketDirection.tx, responseCode: commandCode);

      // Increment TX packet counter and trigger activity indicator
      _txPacketCount++;
      onTxActivity?.call();

      print('✅ [BLE] Write successful');
    } catch (e) {
      print('❌ [BLE] Write error: $e');
      onError?.call('Write error: $e');
      rethrow;
    }
  }

  /// Handle incoming data from TX characteristic
  void _onDataReceived(List<int> data) {
    try {
      print('📥 [BLE] Received ${data.length} bytes from TX characteristic');

      // Handle empty data
      if (data.isEmpty) {
        print('  ⚠️ Empty data received, ignoring');
        return;
      }

      final dataBytes = Uint8List.fromList(data);

      // Increment RX packet counter and trigger activity indicator
      _rxPacketCount++;
      onRxActivity?.call();

      print('  Raw data: ${data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');

      final reader = BufferReader(dataBytes);
      final responseCode = reader.readByte();
      print('  Response code: $responseCode (0x${responseCode.toRadixString(16)})');
      print('  Remaining bytes: ${reader.remainingBytesCount}');

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
        case MeshCoreConstants.pushLogRxData:
          print('  → Handling LogRxData push');
          _handleLogRxData(reader);
          break;
        case MeshCoreConstants.pushNewAdvert:
          print('  → Handling NewAdvert push');
          _handleNewAdvert(reader);
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

  /// Handle Sent confirmation response
  void _handleSentConfirmation(BufferReader reader) {
    try {
      print('  [Sent] Parsing sent confirmation...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // Sent confirmation format (from protocol):
      // - 1 byte: reserved
      // - 4 bytes: public key prefix (recipient)
      // - 2 bytes: message ID
      // - 2 bytes: reserved

      if (reader.remainingBytesCount >= 9) {
        final reserved1 = reader.readByte();
        print('    Reserved: $reserved1');

        final pubKeyPrefix = reader.readBytes(4);
        print('    Recipient public key prefix: ${pubKeyPrefix.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');

        final messageId = reader.readUInt16LE();
        print('    Message ID: $messageId');

        if (reader.remainingBytesCount >= 2) {
          final reserved2 = reader.readUInt16LE();
          print('    Reserved2: $reserved2');
        }
      }

      print('  ✅ [Sent] Message sent confirmation');
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

      final text = reader.readString();
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

      final text = reader.readString();
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

  /// Handle DeviceInfo response
  void _handleDeviceInfo(BufferReader reader) {
    try {
      print('  [DeviceInfo] Parsing device info...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // DeviceInfo format (based on MeshCore protocol):
      // - 1 byte: protocol version
      // - 32 bytes: public key
      // - 1 byte: device name length
      // - N bytes: device name (UTF-8)
      // - remaining: additional info (firmware version, etc.)

      if (reader.remainingBytesCount < 1) {
        print('  [DeviceInfo] No data to parse');
        return;
      }

      final protocolVersion = reader.readByte();
      print('    Protocol version: $protocolVersion');

      if (reader.remainingBytesCount >= 32) {
        final publicKey = reader.readBytes(32);
        print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      }

      // Read remaining data as device info details
      if (reader.hasRemaining) {
        final remainingData = reader.readRemainingBytes();
        print('    Additional info: ${remainingData.length} bytes');
        // Could parse device name, firmware version, etc. here if needed
      }

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

      // SelfInfo format (from MeshCore protocol):
      // - 1 byte: protocol version
      // - 1 byte: device type
      // - 1 byte: tx power
      // - 1 byte: max tx power
      // - 32 bytes: public key
      // - 4 bytes: adv lat (int32)
      // - 4 bytes: adv lon (int32)
      // - 1 byte: manual add contacts flag
      // - 4 bytes: radio freq (uint32)
      // - 2 bytes: radio bw (uint16)
      // - 1 byte: radio sf
      // - 1 byte: radio cr
      // - remaining: self name (null-terminated string)

      if (reader.remainingBytesCount < 54) {
        print('  [SelfInfo] Insufficient data: ${reader.remainingBytesCount} bytes');
        // Just consume remaining bytes to avoid errors
        reader.readRemainingBytes();
        return;
      }

      final protocolVersion = reader.readByte();
      final deviceType = reader.readByte();
      final txPower = reader.readByte();
      final maxTxPower = reader.readByte();
      final publicKey = reader.readBytes(32);
      final advLat = reader.readInt32LE();
      final advLon = reader.readInt32LE();
      final manualAddContacts = reader.readByte();
      final radioFreq = reader.readUInt32LE();
      final radioBw = reader.readUInt16LE();
      final radioSf = reader.readByte();
      final radioCr = reader.readByte();

      print('    Protocol version: $protocolVersion');
      print('    Device type: $deviceType');
      print('    TX power: $txPower / $maxTxPower dBm');
      print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      print('    Position: ${advLat / 1000000.0}, ${advLon / 1000000.0}');
      print('    Radio: freq=$radioFreq, bw=$radioBw, sf=$radioSf, cr=$radioCr');

      String? selfName;
      if (reader.hasRemaining) {
        selfName = String.fromCharCodes(reader.readRemainingBytes().takeWhile((b) => b != 0));
        print('    Self name: $selfName');
      }

      // Call callback with parsed data
      onSelfInfoReceived?.call({
        'protocolVersion': protocolVersion,
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

  /// Handle Advert push
  void _handleAdvert(BufferReader reader) {
    try {
      print('  [Advert] Parsing advert...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // Advert format: 32 bytes public key
      if (reader.remainingBytesCount >= 32) {
        final publicKey = reader.readBytes(32);
        print('    Public key prefix: ${publicKey.sublist(0, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(':')}');
      }

      // Consume any remaining bytes
      if (reader.hasRemaining) {
        reader.readRemainingBytes();
      }

      print('  ✅ [Advert] Parsed successfully');
    } catch (e) {
      print('  ❌ [Advert] Parsing error: $e');
      // Don't call onError - adverts are informational
    }
  }

  /// Handle LogRxData push
  void _handleLogRxData(BufferReader reader) {
    try {
      print('  [LogRxData] Parsing log rx data...');
      print('    Remaining bytes: ${reader.remainingBytesCount}');

      // This is encrypted/encoded data - just consume it
      final data = reader.readRemainingBytes();
      print('    Data length: ${data.length} bytes');
      print('  ✅ [LogRxData] Parsed successfully');
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

  /// Send AppStart command
  Future<void> _sendAppStart() async {
    print('📤 [BLE] Preparing AppStart command...');
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdAppStart);
    writer.writeByte(1); // appVer
    writer.writeBytes(Uint8List(6)); // reserved
    writer.writeString('MeshCore SAR'); // appName
    final data = writer.toBytes();
    print('  Command: ${MeshCoreConstants.cmdAppStart}');
    print('  Data length: ${data.length} bytes');
    await _writeData(data);
    print('✅ [BLE] AppStart command sent');
  }

  /// Send DeviceQuery command
  Future<void> _sendDeviceQuery() async {
    print('📤 [BLE] Preparing DeviceQuery command...');
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdDeviceQuery);
    writer.writeByte(MeshCoreConstants.supportedCompanionProtocolVersion);
    final data = writer.toBytes();
    print('  Command: ${MeshCoreConstants.cmdDeviceQuery}');
    print('  Protocol version: ${MeshCoreConstants.supportedCompanionProtocolVersion}');
    print('  Data length: ${data.length} bytes');
    await _writeData(data);
    print('✅ [BLE] DeviceQuery command sent');
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

  /// Send text message to contact
  Future<void> sendTextMessage({
    required Uint8List contactPublicKey,
    required String text,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTxtMsg);
    writer.writeByte(MeshCoreConstants.txtTypePlain);
    writer.writeByte(0); // attempt
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeBytes(contactPublicKey.sublist(0, 6));
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Send channel text message
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendChannelTxtMsg);
    writer.writeByte(MeshCoreConstants.txtTypePlain);
    writer.writeByte(channelIdx);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    writer.writeString(text);
    await _writeData(writer.toBytes());
  }

  /// Request telemetry from contact
  /// [zeroHop] - if true, only direct connection (no mesh forwarding)
  Future<void> requestTelemetry(Uint8List contactPublicKey, {bool zeroHop = false}) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendTelemetryReq);
    writer.writeByte(zeroHop ? 0 : 255); // hop count: 0 = direct only, 255 = unlimited
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeBytes(contactPublicKey);
    await _writeData(writer.toBytes());
  }

  /// Get battery voltage
  Future<void> getBatteryVoltage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdGetBatteryVoltage);
    await _writeData(writer.toBytes());
  }

  /// Sync next message from device queue
  /// Returns true if a message was retrieved, false if no more messages
  Future<void> syncNextMessage() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSyncNextMessage);
    await _writeData(writer.toBytes());
  }

  /// Set device time
  Future<void> setDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSetDeviceTime);
    writer.writeUInt32LE(DateTime.now().millisecondsSinceEpoch ~/ 1000);
    await _writeData(writer.toBytes());
  }

  /// Send flood advertisement with current location
  Future<void> sendFloodAdvertisement({
    required double latitude,
    required double longitude,
  }) async {
    final writer = BufferWriter();
    writer.writeByte(MeshCoreConstants.cmdSendSelfAdvert);
    writer.writeByte(MeshCoreConstants.selfAdvertFlood);
    writer.writeInt32LE((latitude * 1000000).round());
    writer.writeInt32LE((longitude * 1000000).round());
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
        case MeshCoreConstants.pushLogRxData:
          return 'Log RX Data';
        case MeshCoreConstants.pushNewAdvert:
          return 'New Advertisement';
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
