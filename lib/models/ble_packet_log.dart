import 'dart:typed_data';
import '../services/meshcore_opcode_names.dart';

/// Decoded LOG_RX_DATA packet structure
class LogRxDataInfo {
  final int? airtimeMs;
  final Uint8List? senderPublicKey;
  final int? ackCode;
  final List<String> embeddedStrings;
  final double entropy;
  final bool isLikelyEncrypted;
  final double? snrDb;  // Signal-to-Noise Ratio in dB
  final int? rssiDbm;   // Received Signal Strength Indicator in dBm

  LogRxDataInfo({
    this.airtimeMs,
    this.senderPublicKey,
    this.ackCode,
    this.embeddedStrings = const [],
    required this.entropy,
    required this.isLikelyEncrypted,
    this.snrDb,
    this.rssiDbm,
  });

  /// Get sender public key as hex string (short)
  String? get senderKeyShort {
    if (senderPublicKey == null || senderPublicKey!.length < 6) return null;
    return senderPublicKey!
        .sublist(0, 6)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  String get summary {
    final parts = <String>[];
    if (rssiDbm != null) parts.add('RSSI:${rssiDbm}dBm');
    final snr = snrDb;
    if (snr != null) parts.add('SNR:${snr.toStringAsFixed(1)}dB');
    if (airtimeMs != null) parts.add('airtime:${airtimeMs}ms');
    if (ackCode != null) parts.add('ACK:$ackCode');
    if (senderKeyShort != null) parts.add('from:$senderKeyShort');
    if (embeddedStrings.isNotEmpty) parts.add('strings:${embeddedStrings.length}');
    if (isLikelyEncrypted) parts.add('encrypted');
    return parts.join(', ');
  }
}

/// Represents a logged BLE packet with timestamp and metadata
class BlePacketLog {
  final DateTime timestamp;
  final Uint8List rawData;
  final PacketDirection direction;
  final int? responseCode;
  final String? description;
  final LogRxDataInfo? logRxDataInfo; // Decoded LOG_RX_DATA information

  BlePacketLog({
    required this.timestamp,
    required this.rawData,
    required this.direction,
    this.responseCode,
    this.description,
    this.logRxDataInfo,
  });

  /// Convert raw data to hex string for display
  String get hexData {
    return rawData.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  /// Get opcode name for this packet
  String get opcodeName {
    if (responseCode == null) return 'N/A';
    return MeshCoreOpcodeNames.getOpcodeName(
      responseCode!,
      isTx: direction == PacketDirection.tx,
    );
  }

  /// Get full opcode description (name + hex code)
  String get opcodeDescription {
    if (responseCode == null) return 'N/A';
    return MeshCoreOpcodeNames.getOpcodeDescription(
      responseCode!,
      isTx: direction == PacketDirection.tx,
    );
  }

  /// Get short summary of the packet
  String get summary {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? '0x${responseCode!.toRadixString(16).padLeft(2, '0')}' : 'N/A';
    final name = responseCode != null ? opcodeName : '';
    return '[$dir] $name Code: $code, Size: ${rawData.length} bytes';
  }

  /// Convert to CSV format for export
  String toCsvRow() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode?.toString() ?? '';
    final name = responseCode != null ? opcodeName : '';
    final hex = hexData;
    final desc = description ?? '';
    return '${timestamp.toIso8601String()},$dir,${rawData.length},$name,$code,"$hex","$desc"';
  }

  /// Convert to human-readable log format
  String toLogString() {
    final dir = direction == PacketDirection.rx ? 'RX' : 'TX';
    final code = responseCode != null ? ' [$opcodeDescription]' : '';
    final desc = description != null ? ' - $description' : '';
    final logRxInfo = logRxDataInfo != null ? ' [${logRxDataInfo!.summary}]' : '';
    return '${timestamp.toIso8601String()} [$dir]$code ${rawData.length} bytes: $hexData$desc$logRxInfo';
  }
}

enum PacketDirection {
  rx, // Received from device
  tx, // Sent to device
}
