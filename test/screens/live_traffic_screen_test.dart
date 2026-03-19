import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/ble_packet_log.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/screens/live_traffic_screen.dart';

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

Widget _testApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  testWidgets('shows empty state before traffic arrives', (tester) async {
    final logs = <BlePacketLog>[];
    final refresh = ValueNotifier<int>(0);
    DateTime now = DateTime(2026, 3, 12, 12, 0, 0);

    await tester.pumpWidget(
      _testApp(
        LiveTrafficScreen(
          logReader: () => logs,
          refreshListenable: refresh,
          now: () => now,
        ),
      ),
    );

    expect(find.text('No packets for this filter'), findsOneWidget);
    expect(find.text('Quiet'), findsOneWidget);
  });

  testWidgets('updates summary and stream for incoming live traffic', (
    tester,
  ) async {
    final logs = <BlePacketLog>[];
    final refresh = ValueNotifier<int>(0);
    DateTime now = DateTime(2026, 3, 12, 12, 0, 0);

    await tester.pumpWidget(
      _testApp(
        LiveTrafficScreen(
          logReader: () => logs,
          refreshListenable: refresh,
          now: () => now,
        ),
      ),
    );

    logs.addAll([
      _log(
        timestamp: now.subtract(const Duration(seconds: 10)),
        direction: PacketDirection.rx,
        rawData: _multiHopRaw(hops: [0xC0, 0x10, 0x63, 0x01, 0x68, 0xD9]),
        responseCode: 0x88,
        snrDb: 13.5,
        rssiDbm: -84,
      ),
      _log(
        timestamp: now.subtract(const Duration(seconds: 3)),
        direction: PacketDirection.tx,
        rawData: [0x05, 0x01, 0x02],
        responseCode: 0x88,
      ),
      _log(
        timestamp: now.subtract(const Duration(seconds: 2)),
        direction: PacketDirection.rx,
        rawData: [0x05, 0x01, 0x02],
        responseCode: 0x05,
      ),
    ]);
    refresh.value += 1;
    await tester.pump();

    expect(find.text('1 pkt/min'), findsOneWidget);
    expect(find.text('Device total 1'), findsOneWidget);
    expect(find.text('FLOOD RESPONSE'), findsOneWidget);
    expect(find.text('-84 dBm'), findsOneWidget);
    expect(find.textContaining('Hash:'), findsOneWidget);
    expect(
      find.textContaining('Path: 3 hops [c010,6301,68d9]'),
      findsOneWidget,
    );
    expect(find.textContaining('Path Hashes: 2-byte per hop'), findsOneWidget);
  });

  testWidgets('clear live view only resets transient screen state', (
    tester,
  ) async {
    final logs = <BlePacketLog>[];
    final refresh = ValueNotifier<int>(0);
    DateTime now = DateTime(2026, 3, 12, 12, 0, 0);

    logs.add(
      _log(
        timestamp: now.subtract(const Duration(seconds: 4)),
        direction: PacketDirection.rx,
        rawData: _multiHopRaw(hops: [0xC0, 0x10, 0x63, 0x01]),
        responseCode: 0x88,
      ),
    );

    await tester.pumpWidget(
      _testApp(
        LiveTrafficScreen(
          logReader: () => logs,
          refreshListenable: refresh,
          now: () => now,
        ),
      ),
    );

    expect(find.text('FLOOD RESPONSE'), findsOneWidget);

    await tester.tap(find.byTooltip('Clear live view'));
    await tester.pump();

    expect(find.text('No packets for this filter'), findsOneWidget);

    now = now.add(const Duration(seconds: 2));
    logs.add(
      _log(
        timestamp: now,
        direction: PacketDirection.tx,
        rawData: [0x03, 0x04],
        responseCode: 0x88,
      ),
    );
    logs.add(
      _log(
        timestamp: now,
        direction: PacketDirection.rx,
        rawData: [0x88, 0x00, 0x00],
        responseCode: 0x88,
      ),
    );
    refresh.value += 1;
    await tester.pump();

    expect(find.text('No packets for this filter'), findsNothing);
    expect(find.textContaining('Size: 3 bytes'), findsOneWidget);
  });

  testWidgets('summary metrics expand across wide layouts', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 3, 12, 12, 0, 0);
    final logs = [
      _log(
        timestamp: now.subtract(const Duration(seconds: 10)),
        direction: PacketDirection.rx,
        rawData: _multiHopRaw(hops: [0xC0, 0x10, 0x63, 0x01]),
        responseCode: 0x88,
        snrDb: 9.5,
        rssiDbm: -82,
      ),
    ];

    await tester.pumpWidget(
      _testApp(LiveTrafficScreen(logReader: () => logs, now: () => now)),
    );

    expect(
      tester
              .getSize(
                find.byKey(const ValueKey('liveTrafficMetric:rxPackets')),
              )
              .width >
          200,
      isTrue,
    );
    expect(
      tester
              .getSize(find.byKey(const ValueKey('liveTrafficMetric:multihop')))
              .width >
          200,
      isTrue,
    );
  });
}
