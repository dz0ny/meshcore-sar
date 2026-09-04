import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'profiles_feature_service.dart';

/// Stores per-channel region scope settings.
///
/// Each channel can optionally have a region scope assigned. When set, the app
/// will set the flood scope on the device before sending channel messages so
/// that repeaters outside the region won't forward them.
class RegionScopePreferences {
  static const String _namePrefix = 'region_scope_name_';
  static const String _keyPrefix = 'region_scope_key_';

  /// Get the saved scope for a channel.
  /// Returns null if no scope is set.
  static Future<({String name, Uint8List key})?> getScope(
    int channelIdx,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(
      ProfileStorageScope.scopedKey('$_namePrefix$channelIdx'),
    );
    final keyBase64 = prefs.getString(
      ProfileStorageScope.scopedKey('$_keyPrefix$channelIdx'),
    );
    if (name == null || keyBase64 == null) return null;
    try {
      return (name: name, key: Uint8List.fromList(base64.decode(keyBase64)));
    } catch (_) {
      return null;
    }
  }

  /// Save a region scope for a channel.
  static Future<void> setScope(
    int channelIdx,
    String name,
    Uint8List key,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      ProfileStorageScope.scopedKey('$_namePrefix$channelIdx'),
      name,
    );
    await prefs.setString(
      ProfileStorageScope.scopedKey('$_keyPrefix$channelIdx'),
      base64.encode(key),
    );
  }

  /// Clear the region scope for a channel.
  static Future<void> clearScope(int channelIdx) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(
      ProfileStorageScope.scopedKey('$_namePrefix$channelIdx'),
    );
    await prefs.remove(
      ProfileStorageScope.scopedKey('$_keyPrefix$channelIdx'),
    );
  }

  /// Clear all region scopes (all channels).
  static Future<void> clearAllScopes() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.contains(_namePrefix) || key.contains(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }

  /// Derive the 16-byte transport key for a region name.
  ///
  /// Matches firmware `TransportKeyStore::getAutoKeyFor`:
  /// `SHA256("#regionname")` → first 16 bytes.
  /// The name must include the leading `#` (auto-prepended if missing).
  static Uint8List deriveRegionKey(String regionName) {
    final normalized =
        regionName.startsWith('#') ? regionName : '#$regionName';
    final digest = sha256.convert(utf8.encode(normalized));
    return Uint8List.fromList(digest.bytes.sublist(0, 16));
  }
}
