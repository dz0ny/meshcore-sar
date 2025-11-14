import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/update_info.dart';
import 'build_info_service.dart';

/// Service for checking if a new app version is available
/// Compares current build's commit hash with latest manifest from server
class UpdateCheckerService {
  static final UpdateCheckerService _instance = UpdateCheckerService._internal();
  factory UpdateCheckerService() => _instance;
  UpdateCheckerService._internal();

  final BuildInfoService _buildInfoService = BuildInfoService();

  // Manifest URL for the latest unstable build
  static const String _manifestUrl = 'https://meshcore-sar.dz0ny.dev/unstable/latest/manifest.json';

  /// Check if an update is available
  /// Returns UpdateInfo with availability status and download URL if available
  Future<UpdateInfo> checkForUpdate() async {
    try {
      // Get current build's commit hash
      final currentCommitHash = await _buildInfoService.getCommitHash();

      // Skip check for dev builds (local development)
      if (currentCommitHash == 'dev' || currentCommitHash == 'unknown') {
        debugPrint('[UpdateChecker] Skipping update check for dev/unknown build');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Current commit hash: $currentCommitHash');
      debugPrint('[UpdateChecker] Fetching latest manifest from: $_manifestUrl');

      // Fetch manifest from server
      final response = await http.get(
        Uri.parse(_manifestUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[UpdateChecker] Manifest fetch timed out');
          throw Exception('Manifest fetch timed out');
        },
      );

      if (response.statusCode != 200) {
        debugPrint('[UpdateChecker] Failed to fetch manifest: ${response.statusCode}');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      // Parse manifest JSON
      final Map<String, dynamic> manifest = json.decode(response.body);
      final latestCommitHash = manifest['commit'] as String?;
      final commitShort = manifest['commit_short'] as String?;
      final buildId = manifest['build_id'] as String?;
      final timestamp = manifest['timestamp'] as String?;
      final artifacts = manifest['artifacts'] as List<dynamic>?;

      if (latestCommitHash == null || commitShort == null) {
        debugPrint('[UpdateChecker] Invalid manifest: missing commit information');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Latest commit hash: $latestCommitHash');
      debugPrint('[UpdateChecker] Latest commit short: $commitShort');

      // Compare commit hashes
      // Current hash might be full SHA or short (7 chars)
      // Latest from manifest is full SHA
      final isUpdateAvailable = !_compareCommitHashes(currentCommitHash, latestCommitHash);

      if (!isUpdateAvailable) {
        debugPrint('[UpdateChecker] No update available (same commit)');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      // Find Android APK in artifacts
      final String? apkUrl = _findAndroidApkUrl(artifacts);

      if (apkUrl == null) {
        debugPrint('[UpdateChecker] Update available but no APK found in artifacts');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Update available! APK URL: $apkUrl');

      return UpdateInfo.available(
        currentCommitHash: currentCommitHash,
        latestCommitHash: commitShort,
        downloadUrl: apkUrl,
        buildId: buildId,
        timestamp: timestamp,
      );
    } catch (e) {
      debugPrint('[UpdateChecker] Error checking for update: $e');
      // Return no update on error to avoid disrupting app startup
      final currentCommitHash = await _buildInfoService.getCommitHash();
      return UpdateInfo.noUpdate(currentCommitHash);
    }
  }

  /// Compare two commit hashes (handles both full SHA and short format)
  bool _compareCommitHashes(String current, String latest) {
    // Normalize to lowercase for comparison
    final currentLower = current.toLowerCase();
    final latestLower = latest.toLowerCase();

    // Direct match
    if (currentLower == latestLower) return true;

    // Check if current is short form of latest
    if (latestLower.startsWith(currentLower)) return true;

    // Check if latest is short form of current
    if (currentLower.startsWith(latestLower)) return true;

    return false;
  }

  /// Find Android APK URL in artifacts list
  String? _findAndroidApkUrl(List<dynamic>? artifacts) {
    if (artifacts == null || artifacts.isEmpty) return null;

    // Look for .apk file in artifacts
    for (final artifact in artifacts) {
      if (artifact is String && artifact.toLowerCase().endsWith('.apk')) {
        // Construct full URL
        return 'https://meshcore-sar.dz0ny.dev/unstable/latest/$artifact';
      }
    }

    return null;
  }
}
