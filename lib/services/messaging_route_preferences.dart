import 'package:shared_preferences/shared_preferences.dart';
import 'profiles_feature_service.dart';

class MessagingRoutePreferences {
  static const bool defaultClearPathOnMaxRetry = false;
  static const bool defaultNearestRelayFallbackEnabled = true;

  static const String _legacyAutoRouteRotationKey =
      'messaging_auto_route_rotation_enabled';
  static const String _clearPathOnMaxRetryKey =
      'messaging_clear_path_on_max_retry';
  static const String _nearestRelayFallbackKey =
      'messaging_nearest_relay_fallback_enabled';

  static Future<void> cleanupLegacySettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      ProfileStorageScope.scopedKey(_legacyAutoRouteRotationKey),
    );
  }

  static Future<bool> getClearPathOnMaxRetry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          ProfileStorageScope.scopedKey(_clearPathOnMaxRetryKey),
        ) ??
        defaultClearPathOnMaxRetry;
  }

  static Future<void> setClearPathOnMaxRetry(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      ProfileStorageScope.scopedKey(_clearPathOnMaxRetryKey),
      enabled,
    );
  }

  static Future<bool> getNearestRelayFallbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(
          ProfileStorageScope.scopedKey(_nearestRelayFallbackKey),
        ) ??
        defaultNearestRelayFallbackEnabled;
  }

  static Future<void> setNearestRelayFallbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      ProfileStorageScope.scopedKey(_nearestRelayFallbackKey),
      enabled,
    );
  }
}
