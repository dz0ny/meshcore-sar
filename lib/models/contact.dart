import 'dart:typed_data';
import 'package:latlong2/latlong.dart';
import 'contact_telemetry.dart';

/// MeshCore contact types
enum ContactType {
  none(0),
  chat(1),
  repeater(2),
  room(3);

  const ContactType(this.value);
  final int value;

  static ContactType fromValue(int value) {
    return ContactType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ContactType.none,
    );
  }

  String get displayName {
    switch (this) {
      case ContactType.chat:
        return 'Chat';
      case ContactType.repeater:
        return 'Repeater';
      case ContactType.room:
        return 'Room';
      default:
        return 'Unknown';
    }
  }
}

/// MeshCore contact model
class Contact {
  final Uint8List publicKey;
  final ContactType type;
  final int flags;
  final int outPathLen;
  final Uint8List outPath;
  final String advName;
  final int lastAdvert; // Unix timestamp
  final int advLat; // Latitude as int32
  final int advLon; // Longitude as int32
  final int lastMod; // Unix timestamp

  // Telemetry data (updated separately)
  ContactTelemetry? telemetry;

  Contact({
    required this.publicKey,
    required this.type,
    required this.flags,
    required this.outPathLen,
    required this.outPath,
    required this.advName,
    required this.lastAdvert,
    required this.advLat,
    required this.advLon,
    required this.lastMod,
    this.telemetry,
  });

  /// Get public key as hex string (first 8 bytes)
  String get publicKeyShort {
    if (publicKey.length < 8) return '';
    return publicKey.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Get full public key as hex string
  String get publicKeyHex {
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Convert advLat/advLon to LatLng
  LatLng? get advertLocation {
    if (advLat == 0 && advLon == 0) return null;
    // Convert from int32 to double (degrees)
    final lat = advLat / 1e7;
    final lon = advLon / 1e7;
    return LatLng(lat, lon);
  }

  /// Get display location (prefer telemetry over advert)
  LatLng? get displayLocation {
    if (telemetry?.gpsLocation != null && telemetry!.isRecent) {
      return telemetry!.gpsLocation;
    }
    return advertLocation;
  }

  /// Get display battery (from telemetry or null)
  double? get displayBattery {
    return telemetry?.batteryPercentage;
  }

  /// Check if contact is a chat type (team member)
  bool get isChat => type == ContactType.chat;

  /// Check if contact is a repeater
  bool get isRepeater => type == ContactType.repeater;

  /// Check if contact is a room/channel
  bool get isRoom => type == ContactType.room;

  /// Get last seen time
  DateTime get lastSeenTime {
    return DateTime.fromMillisecondsSinceEpoch(lastAdvert * 1000);
  }

  /// Get last modified time
  DateTime get lastModifiedTime {
    return DateTime.fromMillisecondsSinceEpoch(lastMod * 1000);
  }

  /// Check if contact was seen recently (within last 10 minutes)
  bool get isRecentlySeen {
    return DateTime.now().difference(lastSeenTime).inMinutes < 10;
  }

  /// Get friendly time since last seen
  String get timeSinceLastSeen {
    final diff = DateTime.now().difference(lastSeenTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Contact copyWith({
    Uint8List? publicKey,
    ContactType? type,
    int? flags,
    int? outPathLen,
    Uint8List? outPath,
    String? advName,
    int? lastAdvert,
    int? advLat,
    int? advLon,
    int? lastMod,
    ContactTelemetry? telemetry,
  }) {
    return Contact(
      publicKey: publicKey ?? this.publicKey,
      type: type ?? this.type,
      flags: flags ?? this.flags,
      outPathLen: outPathLen ?? this.outPathLen,
      outPath: outPath ?? this.outPath,
      advName: advName ?? this.advName,
      lastAdvert: lastAdvert ?? this.lastAdvert,
      advLat: advLat ?? this.advLat,
      advLon: advLon ?? this.advLon,
      lastMod: lastMod ?? this.lastMod,
      telemetry: telemetry ?? this.telemetry,
    );
  }

  @override
  String toString() {
    return 'Contact(name: $advName, type: ${type.displayName}, key: $publicKeyShort)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
           publicKeyHex == other.publicKeyHex;
  }

  @override
  int get hashCode => publicKeyHex.hashCode;
}
