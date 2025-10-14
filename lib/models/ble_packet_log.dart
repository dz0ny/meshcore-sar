import 'dart:typed_data';

/// Represents a logged BLE packet with timestamp and metadata
class BlePacketLog {
  final DateTime timestamp;
  final Uint8List rawData;
  final PacketDirection direction;
  final int? responseCode;
  final String? description;

  BlePacketLog({
    required this.timestamp,
    required this.rawData,
    required this.direction,
    this.responseCode,
    this.description,
  });

  /// Convert raw data to hex string for display
  String get hexData {
    return rawData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  /// Get short summary of the packet
  String get summary {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? '0x${responseCode!.toRadixString(16).padLeft(2, '0')}' : 'N/A';
    return '[$dir] Code: $code, Size: ${rawData.length} bytes';
  }

  /// Convert to CSV format for export
  String toCsvRow() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode?.toString() ?? '';
    final hex = hexData;
    final desc = description ?? '';
    return '${timestamp.toIso8601String()},$dir,${rawData.length},$code,"$hex","$desc"';
  }

  /// Convert to human-readable log format
  String toLogString() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? ' [0x${responseCode!.toRadixString(16).padLeft(2, '0')}]' : '';
    final desc = description != null ? ' - $description' : '';
    return '${timestamp.toIso8601String()} [$dir]$code ${rawData.length} bytes: $hexData$desc';
  }
}

enum PacketDirection {
  rx, // Received from device
  tx, // Sent to device
}
