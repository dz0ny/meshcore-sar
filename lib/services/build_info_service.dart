import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, debugPrint, kIsWeb;
import 'package:flutter/services.dart';

/// Service for accessing build information from native platform code
/// Currently supports Android only - returns "unknown" for other platforms
class BuildInfoService {
  static final BuildInfoService _instance = BuildInfoService._internal();
  factory BuildInfoService() => _instance;
  BuildInfoService._internal();

  static const MethodChannel _channel = MethodChannel('com.meshcore.sar/build_info');

  String? _cachedCommitHash;

  /// Get the commit hash that was embedded during build time
  /// Returns "unknown" if:
  /// - Not running on Android
  /// - Platform channel call fails
  /// - Build was not configured with COMMIT_HASH
  Future<String> getCommitHash() async {
    // Return cached value if available
    if (_cachedCommitHash != null) {
      return _cachedCommitHash!;
    }

    // Only Android has the platform channel implementation
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      debugPrint('[BuildInfoService] Not on Android platform, returning "unknown"');
      _cachedCommitHash = 'unknown';
      return _cachedCommitHash!;
    }

    try {
      final String commitHash = await _channel.invokeMethod('getCommitHash');
      _cachedCommitHash = commitHash;
      debugPrint('[BuildInfoService] Commit hash: $commitHash');
      return commitHash;
    } on PlatformException catch (e) {
      debugPrint('[BuildInfoService] Failed to get commit hash: ${e.message}');
      _cachedCommitHash = 'unknown';
      return _cachedCommitHash!;
    } catch (e) {
      debugPrint('[BuildInfoService] Unexpected error getting commit hash: $e');
      _cachedCommitHash = 'unknown';
      return _cachedCommitHash!;
    }
  }

  /// Clear cached commit hash (useful for testing)
  void clearCache() {
    _cachedCommitHash = null;
  }
}
