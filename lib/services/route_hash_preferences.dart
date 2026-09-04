import 'package:shared_preferences/shared_preferences.dart';
import 'profiles_feature_service.dart';

class RouteHashPreferences {
  static const String _hashSizeKey = 'route_hash_size';
  static const int defaultHashSize = 1;

  static Future<int> getHashSize() async {
    final prefs = await SharedPreferences.getInstance();
    final value =
        prefs.getInt(ProfileStorageScope.scopedKey(_hashSizeKey)) ??
        defaultHashSize;
    return _normalize(value);
  }

  static Future<void> setHashSize(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      ProfileStorageScope.scopedKey(_hashSizeKey),
      _normalize(value),
    );
  }

  static int normalizeSync(int value) => _normalize(value);

  /// Valid hash sizes per the MeshCore protocol.
  /// The path encoding uses 2 bits: 00=1B, 01=2B, 10=3B, 11=4B.
  static const List<int> supportedSizes = [1, 2, 3];

  static int _normalize(int value) {
    if (supportedSizes.contains(value)) return value;
    return defaultHashSize;
  }
}
