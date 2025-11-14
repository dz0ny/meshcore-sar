import 'dart:typed_data';

/// Tracks sent public channel messages for echo detection
///
/// When a message is sent to the public channel, it's encrypted with AES128-ECB
/// which is deterministic. When another node receives and rebroadcasts it,
/// the raw packet will be byte-for-byte identical. We can detect these echoes
/// by comparing the raw packet data from PUSH_CODE_LOG_RX_DATA (0x88) against
/// packets we've sent.
class SentMessageTracker {
  /// Unique identifier for the message (timestamp-based)
  final String messageId;

  /// SHA256 hash of the encrypted packet for fast O(1) lookup
  final String packetHashHex;

  /// Original raw encrypted packet bytes (for verification)
  final Uint8List? rawPacket;

  /// When the message was sent
  final DateTime sentTime;

  /// When this tracker expires (default: 5 minutes)
  final DateTime expiryTime;

  /// Number of times we've detected this message being rebroadcast
  int echoCount;

  /// Unique echo paths detected (SNR/RSSI signatures)
  /// Format: "snr_rssi" e.g., "20_-56" means SNR=5.0dB (20/4), RSSI=-56dBm
  final Set<String> uniqueEchoPaths;

  /// Timestamps when echoes were detected
  final List<DateTime> echoTimestamps;

  SentMessageTracker({
    required this.messageId,
    required this.packetHashHex,
    this.rawPacket,
    required this.sentTime,
    required this.expiryTime,
    this.echoCount = 0,
    Set<String>? uniqueEchoPaths,
    List<DateTime>? echoTimestamps,
  })  : uniqueEchoPaths = uniqueEchoPaths ?? {},
        echoTimestamps = echoTimestamps ?? [];

  /// Check if this tracker has expired
  bool get isExpired => DateTime.now().isAfter(expiryTime);

  /// Time until expiry
  Duration get timeUntilExpiry => expiryTime.difference(DateTime.now());

  /// Add an echo detection
  void addEcho(int snrRaw, int rssiDbm) {
    echoCount++;
    uniqueEchoPaths.add('${snrRaw}_$rssiDbm');
    echoTimestamps.add(DateTime.now());
  }

  /// Get the SNR in dB from raw value
  static double snrRawToDb(int snrRaw) {
    return snrRaw.toSigned(8) / 4.0;
  }

  /// Get formatted echo statistics
  String get echoStats {
    if (echoCount == 0) return 'No echoes detected';
    if (echoCount == 1) return '1 echo from ${uniqueEchoPaths.length} path(s)';
    return '$echoCount echoes from ${uniqueEchoPaths.length} path(s)';
  }

  /// Get average time to first echo
  Duration? get timeToFirstEcho {
    if (echoTimestamps.isEmpty) return null;
    return echoTimestamps.first.difference(sentTime);
  }

  @override
  String toString() {
    return 'SentMessageTracker(id=$messageId, echoes=$echoCount, paths=${uniqueEchoPaths.length}, expired=$isExpired)';
  }
}
