import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/update_info.dart';
import 'build_info_service.dart';

/// Service for checking if a new app version is available
/// Compares current build's commit hash with latest GitHub release
class UpdateCheckerService {
  static final UpdateCheckerService _instance =
      UpdateCheckerService._internal();
  factory UpdateCheckerService() => _instance;
  UpdateCheckerService._internal();

  final BuildInfoService _buildInfoService = BuildInfoService();

  static const String _repoOwner = 'dz0ny';
  static const String _repoName = 'meshcore-sar';
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Check if an update is available
  /// Returns UpdateInfo with availability status and download URL if available
  Future<UpdateInfo> checkForUpdate() async {
    try {
      // Get current build's commit hash
      final currentCommitHash = await _buildInfoService.getCommitHash();

      // Skip check for dev builds (local development)
      if (currentCommitHash == 'dev' || currentCommitHash == 'unknown') {
        debugPrint(
          '[UpdateChecker] Skipping update check for dev/unknown build',
        );
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Current commit hash: $currentCommitHash');
      debugPrint(
        '[UpdateChecker] Fetching latest release from: $_latestReleaseUrl',
      );

      // Fetch latest release from GitHub
      final response = await http
          .get(
            Uri.parse(_latestReleaseUrl),
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[UpdateChecker] Latest release fetch timed out');
              throw Exception('Latest release fetch timed out');
            },
          );

      if (response.statusCode != 200) {
        debugPrint(
          '[UpdateChecker] Failed to fetch release: ${response.statusCode}',
        );
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      // Parse release JSON
      final Map<String, dynamic> release = json.decode(response.body);
      final tagName = release['tag_name'] as String?;
      final targetCommitish = release['target_commitish'] as String?;
      final publishedAt = release['published_at'] as String?;
      final assets = release['assets'] as List<dynamic>?;

      if (tagName == null) {
        debugPrint('[UpdateChecker] Invalid release: missing tag_name');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Latest release tag: $tagName');
      if (targetCommitish != null && targetCommitish.isNotEmpty) {
        debugPrint(
          '[UpdateChecker] Release target commitish: $targetCommitish',
        );
      }

      final isUpdateAvailable = await _isUpdateAvailable(
        currentCommitHash: currentCommitHash,
        releaseTag: tagName,
        targetCommitish: targetCommitish,
      );

      if (!isUpdateAvailable) {
        debugPrint('[UpdateChecker] No update available');
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      // Find Android APK in release assets
      final String? apkUrl = _findAndroidApkUrl(assets);

      if (apkUrl == null) {
        debugPrint(
          '[UpdateChecker] Update available but no APK found in artifacts',
        );
        return UpdateInfo.noUpdate(currentCommitHash);
      }

      debugPrint('[UpdateChecker] Update available! APK URL: $apkUrl');

      return UpdateInfo.available(
        currentCommitHash: currentCommitHash,
        latestCommitHash: _formatLatestVersion(targetCommitish, tagName),
        downloadUrl: apkUrl,
        buildId: tagName,
        timestamp: publishedAt,
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

  Future<bool> _isUpdateAvailable({
    required String currentCommitHash,
    required String releaseTag,
    required String? targetCommitish,
  }) async {
    // Prefer direct SHA compare when release target is a hash.
    if (_looksLikeSha(targetCommitish)) {
      return !_compareCommitHashes(currentCommitHash, targetCommitish!);
    }

    // Fallback: ask GitHub how current commit compares to the release tag.
    final compareResult = await _compareWithReleaseTag(
      currentCommitHash,
      releaseTag,
    );
    if (compareResult != null) {
      return compareResult;
    }

    // If we cannot compare, do not force update prompts.
    return false;
  }

  Future<bool?> _compareWithReleaseTag(
    String currentCommitHash,
    String releaseTag,
  ) async {
    try {
      final compareUrl =
          'https://api.github.com/repos/$_repoOwner/$_repoName/compare/$currentCommitHash...$releaseTag';
      final response = await http
          .get(
            Uri.parse(compareUrl),
            headers: {
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
          '[UpdateChecker] Compare API failed: ${response.statusCode}',
        );
        return null;
      }

      final Map<String, dynamic> comparison = json.decode(response.body);
      final status = comparison['status'] as String?;
      debugPrint('[UpdateChecker] Compare status: $status');

      if (status == 'behind') return true;
      if (status == 'identical' || status == 'ahead') return false;

      // "diverged" means the release and current commit differ.
      if (status == 'diverged') return true;
    } catch (e) {
      debugPrint('[UpdateChecker] Compare API error: $e');
    }
    return null;
  }

  bool _looksLikeSha(String? value) {
    if (value == null) return false;
    final v = value.trim();
    if (v.length < 7 || v.length > 40) return false;
    return RegExp(r'^[a-fA-F0-9]+$').hasMatch(v);
  }

  String _formatLatestVersion(String? targetCommitish, String tagName) {
    if (_looksLikeSha(targetCommitish)) {
      return targetCommitish!.substring(0, 7).toLowerCase();
    }
    return tagName;
  }

  /// Find Android APK URL in release assets list
  String? _findAndroidApkUrl(List<dynamic>? assets) {
    if (assets == null || assets.isEmpty) return null;

    for (final asset in assets) {
      if (asset is! Map<String, dynamic>) continue;
      final name = (asset['name'] as String?)?.toLowerCase() ?? '';
      if (!name.endsWith('.apk')) continue;

      final browserDownloadUrl = asset['browser_download_url'] as String?;
      if (browserDownloadUrl != null && browserDownloadUrl.isNotEmpty) {
        return browserDownloadUrl;
      }
    }

    return null;
  }
}
