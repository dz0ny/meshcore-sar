import 'package:meshcore_client/meshcore_client.dart';

import 'serial_transport_stub.dart'
    if (dart.library.io) 'serial_transport_io.dart'
    if (dart.library.js_interop) 'serial_transport_web.dart';

const int kSerialBaudRate = 115200;

class SerialDeviceInfo {
  final String id;
  final String title;
  final String subtitle;
  final Object handle;

  const SerialDeviceInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.handle,
  });
}

class SerialConnection {
  final MeshCoreSerialService service;
  final String deviceId;
  final String deviceName;
  final Future<void> Function() disconnect;

  const SerialConnection({
    required this.service,
    required this.deviceId,
    required this.deviceName,
    required this.disconnect,
  });
}

abstract class SerialTransport {
  bool get isSupported;
  bool get canRequestDevice;
  String get actionLabel;
  String get emptyStateTitle;
  String get unsupportedMessage;

  Future<List<SerialDeviceInfo>> listDevices();
  Future<SerialDeviceInfo?> requestDevice();
  Future<SerialConnection> connect(SerialDeviceInfo device);
  void dispose();
}

SerialTransport createSerialTransport() => createSerialTransportImpl();
