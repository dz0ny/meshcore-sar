import '../models/ble_packet_log.dart';
import '../utils/log_rx_route_decoder.dart';

enum LiveTrafficBusyness { quiet, active, busy }

class LiveTrafficEntry {
  final BlePacketLog log;
  final DecodedLogRxRoute? route;

  const LiveTrafficEntry({required this.log, required this.route});

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

  static String payloadTypeLabel(int payloadType) {
    switch (payloadType) {
      case 0x00:
        return 'Request';
      case 0x01:
        return 'Response';
      case 0x02:
        return 'Text message';
      case 0x03:
        return 'Ack';
      case 0x04:
        return 'Advertisement';
      case 0x05:
        return 'Group text';
      case 0x06:
        return 'Group datagram';
      case 0x07:
        return 'Anonymous request';
      case 0x08:
        return 'Returned path';
      case 0x09:
        return 'Trace path';
      case 0x0A:
        return 'Multipart packet';
      case 0x0B:
        return 'Control packet';
      default:
        return '0x${payloadType.toRadixString(16).padLeft(2, '0')}';
    }
  }

  static String payloadTypeMeaning(int payloadType) {
    switch (payloadType) {
      case 0x00:
        return 'Request (destination/source hashes + MAC)';
      case 0x01:
        return 'Response to Request or Anonymous request';
      case 0x02:
        return 'Plain text message';
      case 0x03:
        return 'Simple acknowledgement';
      case 0x04:
        return 'Node advertisement';
      case 0x05:
        return 'Unverified group text message';
      case 0x06:
        return 'Unverified group datagram';
      case 0x07:
        return 'Generic anonymous request';
      case 0x08:
        return 'Returned path payload';
      case 0x09:
        return 'Trace path collecting hop SNR';
      case 0x0A:
        return 'One packet from a multipart set';
      case 0x0B:
        return 'Control or discovery packet';
      default:
        return 'protocol payload';
    }
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
