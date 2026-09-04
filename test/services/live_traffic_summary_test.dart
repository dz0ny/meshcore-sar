import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/ble_packet_log.dart';
import 'package:meshcore_sar_app/services/live_traffic_summary.dart';

BlePacketLog _log({
  required DateTime timestamp,
  required PacketDirection direction,
  required List<int> rawData,
  int? responseCode,
  double? snrDb,
  int? rssiDbm,
}) {
  return BlePacketLog(
    timestamp: timestamp,
    rawData: Uint8List.fromList(rawData),
    direction: direction,
    responseCode: responseCode ?? (rawData.isEmpty ? null : rawData.first),
    logRxDataInfo: snrDb == null && rssiDbm == null
        ? null
        : LogRxDataInfo(
            entropy: 0,
            isLikelyEncrypted: false,
            snrDb: snrDb,
            rssiDbm: rssiDbm,
          ),
  );
}

List<int> _multiHopRaw({
  required List<int> hops,
  int payloadType = 0x01,
  int hashSize = 2,
}) {
  final hopCount = hops.length ~/ hashSize;
  final pathDescriptor = ((hashSize - 1) << 6) | hopCount;
  return [
    0x88,
    0x00,
    0x00,
    payloadType << 2,
    0x00,
    0x00,
    0x00,
    0x00,
    pathDescriptor,
    ...hops,
  ];
}

void main() {
  group('LiveTrafficSummary', () {
    test('uses only the rolling 60-second window', () {
      final now = DateTime(2026, 3, 12, 12, 0, 0);
      final snapshot = LiveTrafficSummary.fromLogs([
        _log(
          timestamp: now.subtract(const Duration(seconds: 61)),
          direction: PacketDirection.rx,
          rawData: [0x88, 0x00, 0x00],
          responseCode: 0x88,
        ),
        _log(
          timestamp: now.subtract(const Duration(seconds: 20)),
          direction: PacketDirection.rx,
          rawData: [0x88, 0x00, 0x00],
          responseCode: 0x88,
        ),
        _log(
          timestamp: now.subtract(const Duration(seconds: 10)),
          direction: PacketDirection.tx,
          rawData: [0x01, 0x02],
          responseCode: 0x88,
        ),
        _log(
          timestamp: now.subtract(const Duration(seconds: 5)),
          direction: PacketDirection.rx,
          rawData: [0x01, 0x02],
          responseCode: 0x01,
        ),
      ], now: now);

      expect(snapshot.totalCount, 1);
      expect(snapshot.rxCount, 1);
      expect(snapshot.txCount, 0);
      expect(snapshot.packetsPerMinute, 1);
    });

    test('aggregates RSSI, SNR, and multi-hop route metrics', () {
      final now = DateTime(2026, 3, 12, 12, 0, 0);
      final snapshot = LiveTrafficSummary.fromLogs([
        _log(
          timestamp: now.subtract(const Duration(seconds: 30)),
          direction: PacketDirection.rx,
          rawData: _multiHopRaw(hops: [0xC0, 0x10, 0x63, 0x01, 0x68, 0xD9]),
          responseCode: 0x88,
          snrDb: 12.0,
          rssiDbm: -84,
        ),
        _log(
          timestamp: now.subtract(const Duration(seconds: 15)),
          direction: PacketDirection.rx,
          rawData: _multiHopRaw(hops: [0xDE, 0xAD, 0xBE, 0xEF]),
          responseCode: 0x88,
          snrDb: 6.0,
          rssiDbm: -90,
        ),
        _log(
          timestamp: now.subtract(const Duration(seconds: 5)),
          direction: PacketDirection.tx,
          rawData: [0x03, 0x04],
          responseCode: 0x88,
        ),
      ], now: now);

      expect(snapshot.latestRssiDbm, -90);
      expect(snapshot.latestSnrDb, 6.0);
      expect(snapshot.avgRssiDbm, closeTo(-87.0, 0.01));
      expect(snapshot.avgSnrDb, closeTo(9.0, 0.01));
      expect(snapshot.multiHopCount, 2);
      expect(snapshot.avgHopCount, closeTo(2.5, 0.01));
      expect(snapshot.busyness, LiveTrafficBusyness.quiet);
    });

    test('normalizes packet rate for windows longer than one minute', () {
      final now = DateTime(2026, 3, 12, 12, 0, 0);
      final snapshot = LiveTrafficSummary.fromLogs(
        List.generate(
          24,
          (index) => _log(
            timestamp: now.subtract(Duration(seconds: index * 10)),
            direction: PacketDirection.rx,
            rawData: [0x88, 0x00, 0x00],
            responseCode: 0x88,
          ),
        ),
        now: now,
        window: const Duration(minutes: 5),
      );

      expect(snapshot.totalCount, 24);
      expect(snapshot.windowDuration, const Duration(minutes: 5));
      expect(snapshot.packetsPerMinute, 5);
    });

    test('supports clearing the live view without mutating source logs', () {
      final now = DateTime(2026, 3, 12, 12, 0, 0);
      final clearAt = now.subtract(const Duration(seconds: 8));
      final snapshot = LiveTrafficSummary.fromLogs(
        [
          _log(
            timestamp: now.subtract(const Duration(seconds: 10)),
            direction: PacketDirection.rx,
            rawData: [0x88, 0x00, 0x00],
            responseCode: 0x88,
          ),
          _log(
            timestamp: now.subtract(const Duration(seconds: 4)),
            direction: PacketDirection.rx,
            rawData: [0x88, 0x00, 0x00],
            responseCode: 0x88,
          ),
        ],
        now: now,
        clearedAt: clearAt,
      );

      expect(snapshot.totalCount, 1);
      expect(snapshot.visibleEntries, hasLength(1));
    });

    test('counts only RX data packets for device totals', () {
      final now = DateTime(2026, 3, 12, 12, 0, 0);

      expect(
        LiveTrafficSummary.countRxDataLogs([
          _log(
            timestamp: now.subtract(const Duration(seconds: 30)),
            direction: PacketDirection.rx,
            rawData: [0x88, 0x00, 0x00],
            responseCode: 0x88,
          ),
          _log(
            timestamp: now.subtract(const Duration(seconds: 20)),
            direction: PacketDirection.tx,
            rawData: [0x88, 0x00, 0x00],
            responseCode: 0x88,
          ),
          _log(
            timestamp: now.subtract(const Duration(seconds: 10)),
            direction: PacketDirection.rx,
            rawData: [0x05, 0x01, 0x02],
            responseCode: 0x05,
          ),
        ]),
        1,
      );
    });

    test('exposes detailed descriptions for known packet types', () {
      final returnedPath = LiveTrafficEntry.payloadTypeDetails(0x08);
      final control = LiveTrafficEntry.payloadTypeDetails(0x0B);

      expect(returnedPath.title, 'FLOOD RETURNED_PATH');
      expect(
        returnedPath.description,
        contains('stores that returned path as the peer\'s direct out-path'),
      );
      expect(control.label, 'Control packet');
      expect(control.description, contains('discovery request and response'));
    });
  });
}
