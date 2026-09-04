import '../models/device_info.dart';

class ProfileDeviceKeyResolver {
  static String? resolve({
    required DeviceInfo deviceInfo,
    required ConnectionMode connectionMode,
  }) {
    // Always prefer the public key — it's the only truly stable identifier.
    // Don't fall back to deviceId to avoid creating duplicate profiles when
    // publicKey arrives late (after initial connection but before DeviceInfo).
    final publicKey = deviceInfo.publicKey;
    if (publicKey == null || publicKey.isEmpty) {
      return null; // Wait until publicKey is available
    }

    final hex = publicKey
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return hex.isNotEmpty ? 'pk:$hex' : null;
  }
}
