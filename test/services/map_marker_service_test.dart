import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/services/map_marker_service.dart';
import 'package:meshcore_sar_app/widgets/common/contact_avatar.dart';

void main() {
  Contact buildContact({
    required String name,
    required ContactType type,
    required int advLat,
    required int advLon,
  }) {
    return Contact(
      publicKey: Uint8List(32),
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch,
      advLat: advLat,
      advLon: advLon,
      lastMod: DateTime.now().millisecondsSinceEpoch,
    );
  }

  testWidgets('contact map markers render shared contact avatars', (tester) async {
    final service = MapMarkerService();
    final contact = buildContact(
      name: 'John Smith',
      type: ContactType.chat,
      advLat: (46.0569 * 1e6).round(),
      advLon: (14.5058 * 1e6).round(),
    );

    late Widget markerChild;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            final markers = service.generateContactMarkers(
              contacts: [contact],
              context: context,
            );
            markerChild = markers.single.child;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: Center(child: markerChild))),
    );

    expect(find.byType(ContactAvatar), findsOneWidget);
    expect(find.text('JS'), findsOneWidget);
  });
}
