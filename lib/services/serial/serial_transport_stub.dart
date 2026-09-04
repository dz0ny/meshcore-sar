import 'serial_transport.dart';

class _UnsupportedSerialTransport implements SerialTransport {
  @override
  bool get isSupported => false;

  @override
  bool get canRequestDevice => false;

  @override
  String get actionLabel => 'Serial unsupported';

  @override
  String get emptyStateTitle => 'Serial is unavailable on this platform.';

  @override
  String get unsupportedMessage =>
      'Serial is supported on Android, macOS, Windows, and compatible web browsers.';

  @override
  Future<List<SerialDeviceInfo>> listDevices() async => const [];

  @override
  Future<SerialDeviceInfo?> requestDevice() async => null;

  @override
  Future<SerialConnection> connect(SerialDeviceInfo device) async {
    throw UnsupportedError(unsupportedMessage);
  }

  @override
  void dispose() {}
}

SerialTransport createSerialTransportImpl() => _UnsupportedSerialTransport();
