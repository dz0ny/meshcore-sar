import 'dart:typed_data';
import 'package:latlong2/latlong.dart';

/// SAR (Search & Rescue) marker types
enum SarMarkerType {
  foundPerson('🧑', 'Found Person'),
  fire('🔥', 'Fire'),
  stagingArea('🏕️', 'Staging Area'),
  unknown('❓', 'Unknown');

  const SarMarkerType(this.emoji, this.displayName);
  final String emoji;
  final String displayName;

  static SarMarkerType fromEmoji(String emoji) {
    switch (emoji) {
      case '🧑':
      case '👤':
        return SarMarkerType.foundPerson;
      case '🔥':
        return SarMarkerType.fire;
      case '🏕️':
      case '⛺':
        return SarMarkerType.stagingArea;
      default:
        return SarMarkerType.unknown;
    }
  }

  /// Get map marker color
  String get markerColor {
    switch (this) {
      case SarMarkerType.foundPerson:
        return '#4CAF50'; // Green
      case SarMarkerType.fire:
        return '#F44336'; // Red
      case SarMarkerType.stagingArea:
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Gray
    }
  }
}

/// SAR marker from special messages
class SarMarker {
  final String id;
  final SarMarkerType type;
  final LatLng location;
  final DateTime timestamp;
  final Uint8List? senderPublicKey;
  final String? senderName;
  final String? notes;

  SarMarker({
    required this.id,
    required this.type,
    required this.location,
    required this.timestamp,
    this.senderPublicKey,
    this.senderName,
    this.notes,
  });

  /// Get sender public key as hex string (short)
  String? get senderKeyShort {
    if (senderPublicKey == null || senderPublicKey!.length < 8) return null;
    return senderPublicKey!
        .sublist(0, 8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join('');
  }

  /// Get friendly time since marker was created
  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Check if marker is recent (within last hour)
  bool get isRecent {
    return DateTime.now().difference(timestamp).inHours < 1;
  }

  /// Get display name
  String get displayName {
    return '${type.emoji} ${type.displayName}';
  }

  SarMarker copyWith({
    String? id,
    SarMarkerType? type,
    LatLng? location,
    DateTime? timestamp,
    Uint8List? senderPublicKey,
    String? senderName,
    String? notes,
  }) {
    return SarMarker(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      senderPublicKey: senderPublicKey ?? this.senderPublicKey,
      senderName: senderName ?? this.senderName,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'SarMarker(type: ${type.displayName}, location: $location, sender: $senderName, time: $timeAgo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SarMarker && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
