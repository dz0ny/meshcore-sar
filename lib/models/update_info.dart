/// Information about an available app update
class UpdateInfo {
  final bool isAvailable;
  final String currentCommitHash;
  final String? latestCommitHash;
  final String? downloadUrl;
  final String? buildId;
  final String? timestamp;

  const UpdateInfo({
    required this.isAvailable,
    required this.currentCommitHash,
    this.latestCommitHash,
    this.downloadUrl,
    this.buildId,
    this.timestamp,
  });

  /// Factory constructor for when no update is available
  factory UpdateInfo.noUpdate(String currentCommitHash) {
    return UpdateInfo(
      isAvailable: false,
      currentCommitHash: currentCommitHash,
    );
  }

  /// Factory constructor for when an update is available
  factory UpdateInfo.available({
    required String currentCommitHash,
    required String latestCommitHash,
    required String downloadUrl,
    String? buildId,
    String? timestamp,
  }) {
    return UpdateInfo(
      isAvailable: true,
      currentCommitHash: currentCommitHash,
      latestCommitHash: latestCommitHash,
      downloadUrl: downloadUrl,
      buildId: buildId,
      timestamp: timestamp,
    );
  }

  @override
  String toString() {
    return 'UpdateInfo(isAvailable: $isAvailable, '
        'current: $currentCommitHash, '
        'latest: $latestCommitHash, '
        'downloadUrl: $downloadUrl)';
  }
}
