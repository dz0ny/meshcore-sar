import '../models/ble_packet_log.dart';
import '../utils/log_rx_route_decoder.dart';

enum LiveTrafficBusyness { quiet, active, busy }

class LiveTrafficPacketTypeDetails {
  final int payloadType;
  final String title;
  final String label;
  final String summary;
  final String description;

  const LiveTrafficPacketTypeDetails({
    required this.payloadType,
    required this.title,
    required this.label,
    required this.summary,
    required this.description,
  });
}

class LiveTrafficEntry {
  final BlePacketLog log;
  final DecodedLogRxRoute? route;

  const LiveTrafficEntry({required this.log, required this.route});

  static const List<LiveTrafficPacketTypeDetails> _knownPayloadTypes = [
    LiveTrafficPacketTypeDetails(
      payloadType: 0x00,
      title: 'FLOOD REQUEST',
      label: 'Request',
      summary: 'Encrypted request to a known peer',
      description:
          'Encrypted request to a known peer. The wire payload carries destination and source hashes plus a MAC, and the decrypted body starts with a timestamp followed by application-defined request data such as stats or keepalive requests.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x01,
      title: 'FLOOD RESPONSE',
      label: 'Response',
      summary: 'Encrypted reply to a request',
      description:
          'Encrypted reply to a Request or Anonymous request. After decryption, the body is application-defined response data with no single generic response envelope.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x02,
      title: 'FLOOD TEXT',
      label: 'Text message',
      summary: 'Encrypted direct text with timestamp and retry flags',
      description:
          'Encrypted direct text message to a known peer. The decrypted body contains a timestamp, a flags and attempt byte, and the message text.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x03,
      title: 'FLOOD ACK',
      label: 'Ack',
      summary: '4-byte acknowledgement for an earlier message',
      description:
          'Short acknowledgement proving that a prior message was received. It carries a 4-byte checksum derived from the original message data.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x04,
      title: 'FLOOD ADVERTISEMENT',
      label: 'Advertisement',
      summary: 'Signed node identity broadcast',
      description:
          'Signed node advertisement announcing a device identity plus app data such as a name or location. Receivers verify the signature before accepting it.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x05,
      title: 'FLOOD GROUP_TEXT',
      label: 'Group text',
      summary: 'Encrypted channel text matched by channel hash',
      description:
          'Encrypted channel text message. It is matched by the first byte of SHA256(channel secret), then decrypted with the channel key. The plaintext is usually in the form "<sender name>: <message body>".',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x06,
      title: 'FLOOD GROUP_DATA',
      label: 'Group datagram',
      summary: 'Encrypted channel data with type and length',
      description:
          'Encrypted channel datagram. After channel-hash matching and decryption, the body starts with a 16-bit data type and a 1-byte data length before the application payload.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x07,
      title: 'FLOOD ANON_REQUEST',
      label: 'Anonymous request',
      summary: 'Request using an ephemeral sender key',
      description:
          'Encrypted request to a destination hash without using a stored sender identity. The packet includes the sender\'s ephemeral public key so the receiver can derive the shared secret.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x08,
      title: 'FLOOD RETURNED_PATH',
      label: 'Returned path',
      summary:
          'Return route back to the sender, with optional bundled ACK or response',
      description:
          'Path reply sent back to the original author to describe the route a received packet took. MeshCore stores that returned path as the peer\'s direct out-path and can bundle an ACK or response in the same payload.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x09,
      title: 'FLOOD TRACE_PATH',
      label: 'Trace path',
      summary: 'Direct trace that records SNR at each hop',
      description:
          'Direct diagnostic packet that walks a supplied path and appends one SNR sample per hop. When it reaches the end of the path, the initiator can inspect hop-by-hop link quality.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x0A,
      title: 'FLOOD MULTIPART',
      label: 'Multipart packet',
      summary: 'Wrapper for one packet in a multipart sequence',
      description:
          'Packet wrapper used when a logical message is split into a sequence. Current MeshCore code uses it for multipart ACKs, where the first nibble says how many parts remain.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x0B,
      title: 'FLOOD CONTROL',
      label: 'Control packet',
      summary: 'Discovery or other control data',
      description:
          'Control or discovery payload, typically unencrypted. Current documented subtypes are discovery request and response packets used to find nearby nodes and report SNR.',
    ),
    LiveTrafficPacketTypeDetails(
      payloadType: 0x0F,
      title: 'RAW CUSTOM',
      label: 'Custom packet',
      summary: 'Application-defined custom packet',
      description:
          'Application-defined raw packet bytes for custom encryption or custom payload formats. MeshCore leaves the inner format up to the higher-level application.',
    ),
  ];

  bool get isMultiHop => (route?.hopCount ?? 0) > 1;

  int? get hopCount => route?.hopCount;

  String get payloadLabel {
    final decodedRoute = route;
    if (decodedRoute == null) {
      return log.responseCode != null ? log.opcodeName : 'Unknown';
    }
    return payloadTypeLabel(decodedRoute.payloadType);
  }

  String? get payloadMeaning {
    final decodedRoute = route;
    if (decodedRoute == null) return null;
    return payloadTypeMeaning(decodedRoute.payloadType);
  }

  String get routePreview {
    final decodedRoute = route;
    if (decodedRoute == null || decodedRoute.hopHashes.isEmpty) {
      return 'Direct packet';
    }
    return decodedRoute.hopHashes
        .map((hashHex) => '0x${hashHex.toUpperCase()}')
        .join(' -> ');
  }

  static List<LiveTrafficPacketTypeDetails> get knownPayloadTypes =>
      _knownPayloadTypes;

  static LiveTrafficPacketTypeDetails payloadTypeDetails(int payloadType) {
    for (final details in _knownPayloadTypes) {
      if (details.payloadType == payloadType) {
        return details;
      }
    }
    return LiveTrafficPacketTypeDetails(
      payloadType: payloadType,
      title: '0x${payloadType.toRadixString(16).padLeft(2, '0').toUpperCase()}',
      label: '0x${payloadType.toRadixString(16).padLeft(2, '0')}',
      summary: 'Unknown or application-specific protocol payload',
      description:
          'Unknown or application-specific packet type. Check the current MeshCore firmware or app-specific protocol docs for the exact payload format.',
    );
  }

  static String payloadTypeLabel(int payloadType) {
    return payloadTypeDetails(payloadType).label;
  }

  static String payloadTypeTitle(int payloadType) {
    return payloadTypeDetails(payloadType).title;
  }

  static String payloadTypeMeaning(int payloadType) {
    return payloadTypeDetails(payloadType).summary;
  }

  static String payloadTypeDescription(int payloadType) {
    return payloadTypeDetails(payloadType).description;
  }
}

class LiveTrafficSnapshot {
  final DateTime windowStart;
  final Duration windowDuration;
  final int packetsPerMinute;
  final int rxCount;
  final int txCount;
  final int totalCount;
  final double? avgSnrDb;
  final double? latestSnrDb;
  final double? avgRssiDbm;
  final int? latestRssiDbm;
  final int multiHopCount;
  final double? avgHopCount;
  final List<LiveTrafficEntry> visibleEntries;
  final LiveTrafficBusyness busyness;

  const LiveTrafficSnapshot({
    required this.windowStart,
    required this.windowDuration,
    required this.packetsPerMinute,
    required this.rxCount,
    required this.txCount,
    required this.totalCount,
    required this.avgSnrDb,
    required this.latestSnrDb,
    required this.avgRssiDbm,
    required this.latestRssiDbm,
    required this.multiHopCount,
    required this.avgHopCount,
    required this.visibleEntries,
    required this.busyness,
  });
}

class LiveTrafficSummary {
  static const Duration rollingWindow = Duration(seconds: 60);
  static const int maxVisibleEntries = 120;
  static const int logRxDataResponseCode = 0x88;

  const LiveTrafficSummary._();

  static bool isRxDataLog(BlePacketLog log) {
    return log.direction == PacketDirection.rx &&
        log.responseCode == logRxDataResponseCode;
  }

  static int countRxDataLogs(Iterable<BlePacketLog> logs, {DateTime? since}) {
    return logs.where((log) {
      return isRxDataLog(log) &&
          (since == null || !log.timestamp.isBefore(since));
    }).length;
  }

  static LiveTrafficSnapshot fromLogs(
    Iterable<BlePacketLog> logs, {
    required DateTime now,
    DateTime? clearedAt,
    int? preferredHashSize,
    Duration window = rollingWindow,
    String? packetTypeFilter,
  }) {
    final windowStart = now.subtract(window);
    final effectiveStart = clearedAt != null && clearedAt.isAfter(windowStart)
        ? clearedAt
        : windowStart;

    final recentLogs =
        logs
            .where(
              (log) =>
                  isRxDataLog(log) && !log.timestamp.isBefore(effectiveStart),
            )
            .toList()
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final entries = <LiveTrafficEntry>[];
    for (final log in recentLogs) {
      final route = LogRxRouteDecoder.decode(
        log.rawData,
        preferredHashSize: preferredHashSize,
      );
      entries.add(LiveTrafficEntry(log: log, route: route));
    }

    final filteredEntries = packetTypeFilter == null
        ? entries
        : entries
              .where((entry) => entry.payloadLabel == packetTypeFilter)
              .toList();

    var rxCount = 0;
    var snrCount = 0;
    var snrSum = 0.0;
    var rssiCount = 0;
    var rssiSum = 0.0;
    double? latestSnrDb;
    int? latestRssiDbm;
    var multiHopCount = 0;
    var hopCountTotal = 0;
    var hopCountSamples = 0;

    for (final entry in filteredEntries) {
      rxCount += 1;

      final rxInfo = entry.log.logRxDataInfo;
      if (rxInfo?.snrDb != null) {
        snrCount += 1;
        snrSum += rxInfo!.snrDb!;
        latestSnrDb = rxInfo.snrDb!;
      }
      if (rxInfo?.rssiDbm != null) {
        rssiCount += 1;
        rssiSum += rxInfo!.rssiDbm!.toDouble();
        latestRssiDbm = rxInfo.rssiDbm!;
      }

      final route = entry.route;
      if (route != null && route.hopCount > 0) {
        hopCountSamples += 1;
        hopCountTotal += route.hopCount;
        if (route.hopCount > 1) {
          multiHopCount += 1;
        }
      }
    }

    final visibleEntries = filteredEntries.reversed
        .take(maxVisibleEntries)
        .toList();
    const txCount = 0;
    final totalCount = rxCount;
    final packetsPerMinute =
        ((totalCount * Duration.secondsPerMinute) / window.inSeconds).round();

    return LiveTrafficSnapshot(
      windowStart: effectiveStart,
      windowDuration: window,
      packetsPerMinute: packetsPerMinute,
      rxCount: rxCount,
      txCount: txCount,
      totalCount: totalCount,
      avgSnrDb: snrCount == 0 ? null : snrSum / snrCount,
      latestSnrDb: latestSnrDb,
      avgRssiDbm: rssiCount == 0 ? null : rssiSum / rssiCount,
      latestRssiDbm: latestRssiDbm,
      multiHopCount: multiHopCount,
      avgHopCount: hopCountSamples == 0
          ? null
          : hopCountTotal / hopCountSamples,
      visibleEntries: visibleEntries,
      busyness: _busynessForPacketsPerMinute(packetsPerMinute),
    );
  }

  static LiveTrafficBusyness _busynessForPacketsPerMinute(int ppm) {
    if (ppm <= 5) return LiveTrafficBusyness.quiet;
    if (ppm <= 20) return LiveTrafficBusyness.active;
    return LiveTrafficBusyness.busy;
  }
}
