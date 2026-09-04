import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:meshcore_client/meshcore_client.dart';

/// Android USB OTG transport for MeshCore serial connection.
///
/// Wraps the `usb_serial` package to provide raw byte I/O to
/// [MeshCoreSerialService].
class UsbSerialTransport {
  static const int _baudRate = 115200;

  UsbPort? _port;
  StreamSubscription? _inputSubscription;
  final MeshCoreSerialService _service;

  UsbSerialTransport(this._service);

  MeshCoreSerialService get service => _service;

  bool get isConnected => _port != null;

  /// List available USB serial devices.
  static Future<List<UsbDevice>> listDevices() async {
    return UsbSerial.listDevices();
  }

  /// Connect to a USB serial device.
  Future<bool> connect(UsbDevice device) async {
    try {
      _port = await device.create();
      if (_port == null) {
        debugPrint('❌ [USB] Failed to create port for ${device.productName}');
        return false;
      }

      final opened = await _port!.open();
      if (!opened) {
        debugPrint('❌ [USB] Failed to open port');
        _port = null;
        return false;
      }

      await _port!.setDTR(true);
      await _port!.setRTS(true);
      await _port!.setPortParameters(
        _baudRate,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      // Wire write callback
      _service.writeRaw = _write;

      // Listen for incoming data
      _inputSubscription = _port!.inputStream?.listen(
        (data) => _service.feedRawBytes(data),
        onError: (error) {
          debugPrint('❌ [USB] Read error: $error');
          disconnect();
        },
        onDone: () {
          debugPrint('⚠️ [USB] Port closed');
          disconnect();
        },
      );

      debugPrint(
        '✅ [USB] Connected to ${device.productName} at $_baudRate baud',
      );

      // Initialize MeshCore session
      return _service.markConnected();
    } catch (e) {
      debugPrint('❌ [USB] Connection failed: $e');
      await disconnect();
      return false;
    }
  }

  /// Disconnect from the USB device.
  Future<void> disconnect() async {
    _service.markDisconnected();
    _service.writeRaw = null;
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    await _port?.close();
    _port = null;
  }

  Future<void> _write(Uint8List data) async {
    if (_port == null) throw Exception('USB not connected');
    await _port!.write(data);
  }

  void dispose() {
    disconnect();
  }
}
