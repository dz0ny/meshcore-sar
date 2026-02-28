export 'package:meshcore_client/meshcore_client.dart'
    show
        Message,
        MessageType,
        MessageTextType,
        MessageDeliveryStatus,
        MessageRecipient;

import 'package:flutter/foundation.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'sar_marker.dart';

extension MessageSarExtension on Message {
  /// Infer the [SarMarkerType] from stored SAR fields.
  /// Returns null if this is not a SAR marker message.
  SarMarkerType? get sarMarkerType {
    if (!isSarMarker) return null;

    if (sarCustomEmoji != null && sarCustomEmoji!.isNotEmpty) {
      return SarMarkerType.fromEmoji(sarCustomEmoji!);
    }

    final trimmed = text.trim();
    if (!trimmed.startsWith('S:')) return null;

    final parts = trimmed.split(':');
    if (parts.length < 3) return null;

    return SarMarkerType.fromEmoji(parts[1]);
  }

  /// Convert to a [SarMarker] if this message contains SAR data.
  SarMarker? toSarMarker() {
    if (!isSarMarker || sarMarkerType == null || sarGpsCoordinates == null) {
      return null;
    }

    debugPrint('📍 [Message.toSarMarker] Converting to marker:');
    debugPrint('   message.text: "$text"');
    debugPrint('   message.sarNotes: "$sarNotes"');
    debugPrint('   message.sarMarkerType: $sarMarkerType');
    debugPrint('   message.sarCustomEmoji: "$sarCustomEmoji"');

    return SarMarker(
      id: id,
      type: sarMarkerType!,
      location: sarGpsCoordinates!,
      timestamp: sentAt,
      senderPublicKey: senderPublicKeyPrefix,
      senderName: senderName,
      notes: sarNotes,
      customEmoji: sarCustomEmoji,
      colorIndex: sarColorIndex,
    );
  }
}
