import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'package:usb_serial/usb_serial.dart';

import 'serial_transport.dart';

class _IoSerialTransport implements SerialTransport {
  @override
  bool get isSupported =>
      Platform.isAndroid || Platform.isMacOS || Platform.isWindows;

  @override
  bool get canRequestDevice => false;

  @override
  String get actionLabel =>
      Platform.isAndroid ? 'Scan USB devices' : 'Scan serial ports';

  @override
  String get emptyStateTitle => Platform.isAndroid
      ? 'No USB serial devices found.\nConnect a MeshCore device via OTG cable.'
      : 'No serial ports found.\nConnect a MeshCore device over USB serial.';

  @override
  String get unsupportedMessage =>
      'Serial is supported on Android, macOS, Windows, and compatible web browsers.';

  @override
  Future<List<SerialDeviceInfo>> listDevices() async {
    if (Platform.isAndroid) {
      final devices = await UsbSerial.listDevices();
      return devices.map(_androidDeviceInfo).toList(growable: false);
    }
    if (Platform.isMacOS || Platform.isWindows) {
      return _desktopSerialDevices();
    }
    return const [];
  }

  @override
  Future<SerialDeviceInfo?> requestDevice() async => null;

  @override
  Future<SerialConnection> connect(SerialDeviceInfo device) async {
    if (Platform.isAndroid) {
      return _connectAndroid(device);
    }
    if (Platform.isMacOS || Platform.isWindows) {
      return _connectDesktop(device);
    }
    throw UnsupportedError(unsupportedMessage);
  }

  SerialDeviceInfo _androidDeviceInfo(UsbDevice device) {
    final title = _firstNonEmpty([
      device.productName,
      device.manufacturerName,
      'USB Serial Device',
    ]);
    final subtitleParts = <String>[
      if ((device.manufacturerName ?? '').trim().isNotEmpty)
        device.manufacturerName!.trim(),
      if (device.vid != null && device.pid != null)
        'VID:${_hex(device.vid!)} PID:${_hex(device.pid!)}',
    ];

    return SerialDeviceInfo(
      id: '${device.deviceId}:${device.vid ?? 'na'}:${device.pid ?? 'na'}:${device.productName ?? 'usb'}',
      title: title,
      subtitle: subtitleParts.isEmpty
          ? 'Ready over OTG serial'
          : subtitleParts.join(' • '),
      handle: device,
    );
  }

  Future<List<SerialDeviceInfo>> _desktopSerialDevices() async {
    final ports = <SerialDeviceInfo>[];
    for (final address in SerialPort.availablePorts) {
      final port = SerialPort(address);
      try {
        final title = _firstNonEmpty([
          port.productName,
          port.description,
          address,
        ]);
        final subtitleParts = <String>[
          address,
          if ((port.manufacturer ?? '').trim().isNotEmpty)
            port.manufacturer!.trim(),
          if (port.vendorId != null && port.productId != null)
            'VID:${_hex(port.vendorId!)} PID:${_hex(port.productId!)}',
        ];
        ports.add(
          SerialDeviceInfo(
            id: address,
            title: title,
            subtitle: subtitleParts.join(' • '),
            handle: address,
          ),
        );
      } finally {
        port.dispose();
      }
    }
    return ports;
  }

  Future<SerialConnection> _connectAndroid(SerialDeviceInfo device) async {
    final usbDevice = device.handle as UsbDevice;
    final service = MeshCoreSerialService(appName: 'MeshCore SAR');
    StreamSubscription<Uint8List>? inputSubscription;
    UsbPort? port;

    try {
      port = await usbDevice.create();
      if (port == null) {
        throw Exception('Failed to create USB port');
      }
      final opened = await port.open();
      if (!opened) {
        throw Exception('Failed to open USB port');
      }

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        kSerialBaudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      service.writeRaw = (data) async {
        await port!.write(data);
      };

      inputSubscription = port.inputStream?.listen(
        (data) => service.feedRawBytes(data),
        onError: (error) {
          debugPrint('❌ [Serial/Android] Read error: $error');
          service.markDisconnected();
        },
        onDone: () {
          debugPrint('⚠️ [Serial/Android] Port closed');
          service.markDisconnected();
        },
      );

      final connected = await service.markConnected();
      if (!connected) {
        throw Exception('Serial session initialization failed');
      }

      return SerialConnection(
        service: service,
        deviceId:
            '${usbDevice.deviceId}:${usbDevice.vid ?? 'na'}:${usbDevice.pid ?? 'na'}',
        deviceName: device.title,
        disconnect: () async {
          await inputSubscription?.cancel();
          inputSubscription = null;
          service.writeRaw = null;
          await port?.close();
          port = null;
        },
      );
    } catch (_) {
      await inputSubscription?.cancel();
      service.writeRaw = null;
      await port?.close();
      service.dispose();
      rethrow;
    }
  }

  Future<SerialConnection> _connectDesktop(SerialDeviceInfo device) async {
    final portName = device.handle as String;
    final port = SerialPort(portName);
    final config = SerialPortConfig();
    final service = MeshCoreSerialService(appName: 'MeshCore SAR');
    SerialPortReader? reader;
    StreamSubscription<Uint8List>? inputSubscription;

    try {
      if (!port.openReadWrite()) {
        throw Exception(
          SerialPort.lastError?.message ?? 'Failed to open serial port',
        );
      }

      config.baudRate = kSerialBaudRate;
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      config.setFlowControl(SerialPortFlowControl.none);
      config.dtr = SerialPortDtr.on;
      config.rts = SerialPortRts.on;
      port.config = config;

      service.writeRaw = (data) async {
        var offset = 0;
        while (offset < data.length) {
          final written = port.write(data.sublist(offset));
          if (written <= 0) {
            throw Exception(
              SerialPort.lastError?.message ?? 'Failed to write to serial port',
            );
          }
          offset += written;
        }
      };

      reader = SerialPortReader(port);
      inputSubscription = reader.stream.listen(
        (data) => service.feedRawBytes(data),
        onError: (error) {
          debugPrint('❌ [Serial/Desktop] Read error: $error');
          service.markDisconnected();
        },
        onDone: () {
          debugPrint('⚠️ [Serial/Desktop] Reader closed');
          service.markDisconnected();
        },
      );

      final connected = await service.markConnected();
      if (!connected) {
        throw Exception('Serial session initialization failed');
      }

      return SerialConnection(
        service: service,
        deviceId: portName,
        deviceName: device.title,
        disconnect: () async {
          await inputSubscription?.cancel();
          inputSubscription = null;
          reader?.close();
          reader = null;
          service.writeRaw = null;
          if (port.isOpen) {
            port.close();
          }
          port.dispose();
          config.dispose();
        },
      );
    } catch (_) {
      await inputSubscription?.cancel();
      reader?.close();
      service.writeRaw = null;
      if (port.isOpen) {
        port.close();
      }
      port.dispose();
      config.dispose();
      service.dispose();
      rethrow;
    }
  }

  @override
  void dispose() {}
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }
  return 'Serial Device';
}

String _hex(int value) => value.toRadixString(16).padLeft(4, '0');

SerialTransport createSerialTransportImpl() => _IoSerialTransport();
