import 'dart:async';
import 'package:meshcore_client/meshcore_client.dart';

// Web Serial API is only available on web platform.
// This file provides the interface; the actual JS interop is conditional.

/// Web Serial transport stub for non-web platforms.
/// On web, use [WebSerialTransportImpl] from web_serial_transport_web.dart.
class WebSerialTransport {
  final MeshCoreSerialService service;

  WebSerialTransport(this.service);

  bool get isConnected => false;
  bool get isSupported => false;

  Future<bool> requestAndConnect() async => false;
  Future<void> disconnect() async {}
  void dispose() {}
}
