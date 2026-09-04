const int _transmitEstimateToleranceMs = 1500;

int? sanitizeEstimatedTransmitMs({
  required int? estimatedTransmitMs,
  required int? senderToReceiptMs,
}) {
  if (estimatedTransmitMs == null || estimatedTransmitMs <= 0) {
    return null;
  }

  if (senderToReceiptMs == null || senderToReceiptMs <= 0) {
    return estimatedTransmitMs;
  }

  // Sender timestamps are second-granularity, so allow a small cushion before
  // treating the estimate as impossible for the observed delivery time.
  if (estimatedTransmitMs > senderToReceiptMs + _transmitEstimateToleranceMs) {
    return null;
  }

  return estimatedTransmitMs;
}

class MessageReceptionDetails {
  final DateTime capturedAt;
  final DateTime? packetLoggedAt;
  final int? rssiDbm;
  final double? snrDb;
  final List<int>? pathBytes;
  final int? senderToReceiptMs;
  final int? estimatedTransmitMs;
  final int? postTransmitDelayMs;
  final int receivedCopies;

  const MessageReceptionDetails({
    required this.capturedAt,
    this.packetLoggedAt,
    this.rssiDbm,
    this.snrDb,
    this.pathBytes,
    this.senderToReceiptMs,
    this.estimatedTransmitMs,
    this.postTransmitDelayMs,
    this.receivedCopies = 1,
  });

  String? get pathBytesHex => pathBytes == null || pathBytes!.isEmpty
      ? null
      : pathBytes!.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

  Map<String, dynamic> toJson() {
    return {
      'capturedAtMillis': capturedAt.millisecondsSinceEpoch,
      'packetLoggedAtMillis': packetLoggedAt?.millisecondsSinceEpoch,
      'rssiDbm': rssiDbm,
      'snrDb': snrDb,
      'pathBytes': pathBytes,
      'senderToReceiptMs': senderToReceiptMs,
      'estimatedTransmitMs': estimatedTransmitMs,
      'postTransmitDelayMs': postTransmitDelayMs,
      'receivedCopies': receivedCopies,
    };
  }

  MessageReceptionDetails copyWith({
    DateTime? capturedAt,
    DateTime? packetLoggedAt,
    int? rssiDbm,
    double? snrDb,
    List<int>? pathBytes,
    int? senderToReceiptMs,
    int? estimatedTransmitMs,
    int? postTransmitDelayMs,
    int? receivedCopies,
  }) {
    return MessageReceptionDetails(
      capturedAt: capturedAt ?? this.capturedAt,
      packetLoggedAt: packetLoggedAt ?? this.packetLoggedAt,
      rssiDbm: rssiDbm ?? this.rssiDbm,
      snrDb: snrDb ?? this.snrDb,
      pathBytes: pathBytes ?? this.pathBytes,
      senderToReceiptMs: senderToReceiptMs ?? this.senderToReceiptMs,
      estimatedTransmitMs: estimatedTransmitMs ?? this.estimatedTransmitMs,
      postTransmitDelayMs: postTransmitDelayMs ?? this.postTransmitDelayMs,
      receivedCopies: receivedCopies ?? this.receivedCopies,
    );
  }

  static MessageReceptionDetails mergeDuplicate({
    MessageReceptionDetails? existing,
    MessageReceptionDetails? incoming,
  }) {
    final base =
        existing ??
        incoming ??
        MessageReceptionDetails(capturedAt: DateTime.now());

    return base.copyWith(
      capturedAt: incoming?.capturedAt ?? existing?.capturedAt,
      packetLoggedAt: incoming?.packetLoggedAt ?? existing?.packetLoggedAt,
      rssiDbm: incoming?.rssiDbm ?? existing?.rssiDbm,
      snrDb: incoming?.snrDb ?? existing?.snrDb,
      pathBytes: incoming?.pathBytes ?? existing?.pathBytes,
      senderToReceiptMs:
          incoming?.senderToReceiptMs ?? existing?.senderToReceiptMs,
      estimatedTransmitMs:
          incoming?.estimatedTransmitMs ?? existing?.estimatedTransmitMs,
      postTransmitDelayMs:
          incoming?.postTransmitDelayMs ?? existing?.postTransmitDelayMs,
      receivedCopies:
          (existing?.receivedCopies ?? 1) + (incoming?.receivedCopies ?? 1),
    );
  }

  static MessageReceptionDetails? fromJson(Map<String, dynamic> json) {
    final capturedAtMillis = json['capturedAtMillis'];
    if (capturedAtMillis is! int) {
      return null;
    }

    final pathBytes = json['pathBytes'];
    return MessageReceptionDetails(
      capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMillis),
      packetLoggedAt: json['packetLoggedAtMillis'] is int
          ? DateTime.fromMillisecondsSinceEpoch(
              json['packetLoggedAtMillis'] as int,
            )
          : null,
      rssiDbm: json['rssiDbm'] as int?,
      snrDb: (json['snrDb'] as num?)?.toDouble(),
      pathBytes: pathBytes is List
          ? pathBytes.whereType<num>().map((b) => b.toInt()).toList()
          : null,
      senderToReceiptMs: json['senderToReceiptMs'] as int?,
      estimatedTransmitMs: json['estimatedTransmitMs'] as int?,
      postTransmitDelayMs: json['postTransmitDelayMs'] as int?,
      receivedCopies: json['receivedCopies'] as int? ?? 1,
    );
  }
}
