import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meshcore_client/meshcore_client.dart';
import 'package:web/web.dart' as web;
import 'package:webserial/webserial.dart';

import 'serial_transport.dart';

class _WebSerialTransport implements SerialTransport {
  @override
  bool get isSupported =>
      web.window.navigator.hasProperty('serial'.toJS).toDart;

  @override
  bool get canRequestDevice => true;

  @override
  String get actionLabel => 'Choose serial device';

  @override
  String get emptyStateTitle =>
      'No serial devices granted yet.\nChoose a device and approve access in your browser.';

  @override
  String get unsupportedMessage =>
      'Web Serial requires a compatible browser such as Chrome or Edge and a secure context (HTTPS or localhost).';

  @override
  Future<List<SerialDeviceInfo>> listDevices() async {
    if (!isSupported) {
      return const [];
    }
    final ports = await serial.getPorts().toDart;
    return ports
        .toDart
        .whereType<JSSerialPort>()
        .map(_deviceInfoForPort)
        .toList(growable: false);
  }

  @override
  Future<SerialDeviceInfo?> requestDevice() async {
    if (!isSupported) {
      return null;
    }
    final port = await requestWebSerialPort(null);
    if (port == null) {
      return null;
    }
    return _deviceInfoForPort(port);
  }

  @override
  Future<SerialConnection> connect(SerialDeviceInfo device) async {
    final port = device.handle as JSSerialPort;
    final service = MeshCoreSerialService(appName: 'MeshCore SAR');
    web.ReadableStreamDefaultReader? reader;
    bool keepReading = false;

    try {
      await port
          .open(
            JSSerialOptions(
              baudRate: kSerialBaudRate,
              dataBits: 8,
              stopBits: 1,
              parity: 'none',
              bufferSize: 1024,
              flowControl: 'none',
            ),
          )
          .toDart;

      await port
          .setSignals(
            JSSerialOutputSignals(
              dataTerminalReady: true,
              requestToSend: true,
            ),
          )
          .toDart;

      service.writeRaw = (data) async {
        final writable = port.writable;
        if (writable == null) {
          throw Exception('Serial port is not writable');
        }
        final writer =
            writable.getWriter() as web.WritableStreamDefaultWriter?;
        if (writer == null) {
          throw Exception('Failed to acquire serial writer');
        }
        try {
          await writer.write(data.toJS).toDart;
        } finally {
          writer.releaseLock();
        }
      };

      final readable = port.readable;
      if (readable == null) {
        throw Exception('Serial port is not readable');
      }

      reader = readable.getReader() as web.ReadableStreamDefaultReader?;
      if (reader == null) {
        throw Exception('Failed to acquire serial reader');
      }

      keepReading = true;
      unawaited(_readLoop(reader, service, () => keepReading));

      final connected = await service.markConnected();
      if (!connected) {
        throw Exception('Serial session initialization failed');
      }

      return SerialConnection(
        service: service,
        deviceId: device.id,
        deviceName: device.title,
        disconnect: () async {
          keepReading = false;
          try {
            await reader?.cancel().toDart;
          } catch (_) {}
          try {
            reader?.releaseLock();
          } catch (_) {}
          reader = null;
          service.writeRaw = null;
          try {
            await port.close().toDart;
          } catch (_) {}
        },
      );
    } catch (_) {
      keepReading = false;
      try {
        await reader?.cancel().toDart;
      } catch (_) {}
      try {
        reader?.releaseLock();
      } catch (_) {}
      service.writeRaw = null;
      try {
        await port.close().toDart;
      } catch (_) {}
      service.dispose();
      rethrow;
    }
  }

  Future<void> _readLoop(
    web.ReadableStreamDefaultReader reader,
    MeshCoreSerialService service,
    bool Function() shouldContinue,
  ) async {
    while (shouldContinue()) {
      try {
        final result = await reader.read().toDart;
        if (result.done) {
          break;
        }
        final value = result.value;
        if (value == null) {
          continue;
        }
        service.feedRawBytes((value as JSUint8Array).toDart);
      } catch (_) {
        break;
      }
    }
    service.markDisconnected();
    try {
      reader.releaseLock();
    } catch (_) {}
  }

  SerialDeviceInfo _deviceInfoForPort(JSSerialPort port) {
    final info = port.getInfo();
    final vendorId = info.usbVendorId;
    final productId = info.usbProductId;
    final title = (vendorId != 0 || productId != 0)
        ? 'USB ${_hex(vendorId)}:${_hex(productId)}'
        : 'Granted serial device';
    final subtitle = [
      if (vendorId != 0 || productId != 0)
        'VID:${_hex(vendorId)} PID:${_hex(productId)}',
      'Web Serial',
    ].join(' • ');

    return SerialDeviceInfo(
      id: '$title::$subtitle',
      title: title,
      subtitle: subtitle,
      handle: port,
    );
  }

  @override
  void dispose() {}
}

String _hex(int value) => value.toRadixString(16).padLeft(4, '0');

SerialTransport createSerialTransportImpl() => _WebSerialTransport();
