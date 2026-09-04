import 'package:flutter/material.dart';

/// Utility class for battery and signal display helpers
/// Used across home_screen.dart and contact_tile.dart
class BatteryDisplayHelper {
  /// Get battery icon based on percentage level
  static IconData getBatteryIcon(double percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 50) return Icons.battery_5_bar;
    if (percentage > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  /// Get battery color based on percentage level
  static Color getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }

  /// Get signal strength color based on RSSI value
  static Color getSignalColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -70) return Colors.orange;
    return Colors.red;
  }

  /// Number of active signal bars (0-5) for a BLE RSSI value.
  static int getSignalBars(int rssi) {
    if (rssi > -50) return 5;
    if (rssi > -60) return 4;
    if (rssi > -70) return 3;
    if (rssi > -80) return 2;
    if (rssi > -90) return 1;
    return 0;
  }
}
