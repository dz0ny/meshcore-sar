import 'dart:typed_data';

/// BLE connection state
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// MeshCore device information
class DeviceInfo {
  final String? deviceId;
  final String? deviceName;
  final ConnectionState connectionState;
  final int? batteryMilliVolts;
  final double? batteryPercentage;
  final int? signalRssi;
  final double? signalSnr;
  final DateTime? lastUpdate;

  // Self info from MeshCore device
  final int? deviceType;
  final int? txPower;
  final int? maxTxPower;
  final Uint8List? publicKey;
  final int? advLat;
  final int? advLon;
  final bool? manualAddContacts;
  final int? radioFreq;
  final int? radioBw;
  final int? radioSf;
  final int? radioCr;
  final String? selfName;

  // Additional device capabilities (from RESP_CODE_DEVICE_INFO)
  final int? maxContacts;        // Max contacts device supports
  final int? maxChannels;        // Max channels device supports
  final int? telemetryModes;     // Telemetry permission modes (bits 0-1: Base, bits 2-3: Location)
  final int? blePin;             // BLE PIN code
  final int? multiAcks;          // Extra ACK mode (0=no, 1=yes)
  final int? advertLocPolicy;    // Location sharing policy (0=don't share, 1=share)

  // Firmware info
  final int? firmwareVersion;
  final String? firmwareBuildDate;
  final String? manufacturerModel;
  final String? semanticVersion;

  DeviceInfo({
    this.deviceId,
    this.deviceName,
    this.connectionState = ConnectionState.disconnected,
    this.batteryMilliVolts,
    this.batteryPercentage,
    this.signalRssi,
    this.signalSnr,
    this.lastUpdate,
    this.deviceType,
    this.txPower,
    this.maxTxPower,
    this.publicKey,
    this.advLat,
    this.advLon,
    this.manualAddContacts,
    this.radioFreq,
    this.radioBw,
    this.radioSf,
    this.radioCr,
    this.selfName,
    this.maxContacts,
    this.maxChannels,
    this.telemetryModes,
    this.blePin,
    this.multiAcks,
    this.advertLocPolicy,
    this.firmwareVersion,
    this.firmwareBuildDate,
    this.manufacturerModel,
    this.semanticVersion,
  });

  /// Check if device is connected
  bool get isConnected => connectionState == ConnectionState.connected;

  /// Check if device is connecting
  bool get isConnecting => connectionState == ConnectionState.connecting;

  /// Check if device has error
  bool get hasError => connectionState == ConnectionState.error;

  /// Get battery percentage (calculated or provided)
  double? get batteryPercent {
    if (batteryPercentage != null) return batteryPercentage!;
    if (batteryMilliVolts == null) return null;

    // Rough conversion from mV to percentage (3.0V = 0%, 4.2V = 100%)
    final voltage = batteryMilliVolts! / 1000.0;
    if (voltage <= 3.0) return 0.0;
    if (voltage >= 4.2) return 100.0;
    return ((voltage - 3.0) / 1.2) * 100.0;
  }

  /// Get battery status
  String get batteryStatus {
    final percent = batteryPercent;
    if (percent == null) return 'Unknown';
    if (percent > 80) return 'Excellent';
    if (percent > 50) return 'Good';
    if (percent > 20) return 'Low';
    return 'Critical';
  }

  /// Get signal strength category
  String get signalStrength {
    if (signalRssi == null) return 'Unknown';
    if (signalRssi! > -60) return 'Excellent';
    if (signalRssi! > -70) return 'Good';
    if (signalRssi! > -80) return 'Fair';
    return 'Poor';
  }

  /// Get public key as hex string (short)
  String? get publicKeyShort {
    if (publicKey == null || publicKey!.length < 8) return null;
    return publicKey!
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// Get display name with "MeshCore-" prefix removed
  String? get displayName {
    if (deviceName == null) return null;
    if (deviceName!.startsWith('MeshCore-')) {
      return deviceName!.substring(9); // Remove "MeshCore-" (9 characters)
    }
    return deviceName;
  }

  DeviceInfo copyWith({
    String? deviceId,
    String? deviceName,
    ConnectionState? connectionState,
    int? batteryMilliVolts,
    double? batteryPercentage,
    int? signalRssi,
    double? signalSnr,
    DateTime? lastUpdate,
    int? deviceType,
    int? txPower,
    int? maxTxPower,
    Uint8List? publicKey,
    int? advLat,
    int? advLon,
    bool? manualAddContacts,
    int? radioFreq,
    int? radioBw,
    int? radioSf,
    int? radioCr,
    String? selfName,
    int? maxContacts,
    int? maxChannels,
    int? telemetryModes,
    int? blePin,
    int? multiAcks,
    int? advertLocPolicy,
    int? firmwareVersion,
    String? firmwareBuildDate,
    String? manufacturerModel,
    String? semanticVersion,
  }) {
    return DeviceInfo(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      connectionState: connectionState ?? this.connectionState,
      batteryMilliVolts: batteryMilliVolts ?? this.batteryMilliVolts,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      signalRssi: signalRssi ?? this.signalRssi,
      signalSnr: signalSnr ?? this.signalSnr,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      deviceType: deviceType ?? this.deviceType,
      txPower: txPower ?? this.txPower,
      maxTxPower: maxTxPower ?? this.maxTxPower,
      publicKey: publicKey ?? this.publicKey,
      advLat: advLat ?? this.advLat,
      advLon: advLon ?? this.advLon,
      manualAddContacts: manualAddContacts ?? this.manualAddContacts,
      radioFreq: radioFreq ?? this.radioFreq,
      radioBw: radioBw ?? this.radioBw,
      radioSf: radioSf ?? this.radioSf,
      radioCr: radioCr ?? this.radioCr,
      selfName: selfName ?? this.selfName,
      maxContacts: maxContacts ?? this.maxContacts,
      maxChannels: maxChannels ?? this.maxChannels,
      telemetryModes: telemetryModes ?? this.telemetryModes,
      blePin: blePin ?? this.blePin,
      multiAcks: multiAcks ?? this.multiAcks,
      advertLocPolicy: advertLocPolicy ?? this.advertLocPolicy,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      firmwareBuildDate: firmwareBuildDate ?? this.firmwareBuildDate,
      manufacturerModel: manufacturerModel ?? this.manufacturerModel,
      semanticVersion: semanticVersion ?? this.semanticVersion,
    );
  }

  @override
  String toString() {
    return 'DeviceInfo(name: $deviceName, state: $connectionState, battery: ${batteryPercent?.toStringAsFixed(0)}%, signal: $signalRssi dBm)';
  }
}
