import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/widgets/common/contact_avatar.dart';

void main() {
  Contact buildContact({
    required String name,
    required ContactType type,
    int secondByte = 0,
  }) {
    final publicKey = Uint8List(32);
    publicKey[1] = secondByte;

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(0),
      advName: name,
      lastAdvert: 0,
      advLat: 0,
      advLon: 0,
      lastMod: 0,
    );
  }

  Future<void> pumpAvatar(WidgetTester tester, Contact contact) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: ContactAvatar(contact: contact)),
        ),
      ),
    );
  }

  testWidgets('renders label avatar for rooms', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(name: 'Operations Room', type: ContactType.room),
    );

    expect(find.text('OR'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.meeting_room), findsNothing);
  });

  testWidgets('renders hash label avatar for rooms', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(name: '#ops-room', type: ContactType.room),
    );

    expect(find.text('#OP'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.meeting_room), findsNothing);
  });

  testWidgets('renders compact hash label avatar when name includes spacing', (
    tester,
  ) async {
    await pumpAvatar(
      tester,
      buildContact(name: '# foo alpha', type: ContactType.room),
    );

    expect(find.text('#FO'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.meeting_room), findsNothing);
  });

  testWidgets('renders label avatar for channels', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(name: '#ops', type: ContactType.channel, secondByte: 3),
    );

    expect(find.text('#OP'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.public), findsNothing);
  });

  testWidgets('renders non-hash label avatar for channels', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(
        name: 'Command Net',
        type: ContactType.channel,
        secondByte: 3,
      ),
    );

    expect(find.text('CN'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsNothing);
    expect(find.byIcon(Icons.public), findsNothing);
  });

  testWidgets('renders round avatar for chat contacts', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(name: 'John Smith', type: ContactType.chat),
    );

    expect(find.text('JS'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.person), findsNothing);
  });

  testWidgets('renders sensor icon avatar for sensor contacts', (tester) async {
    await pumpAvatar(
      tester,
      buildContact(name: 'WX Station', type: ContactType.sensor),
    );

    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.byIcon(Icons.sensors), findsOneWidget);
    expect(find.text('WS'), findsNothing);
  });
}
