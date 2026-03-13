import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/connection_provider.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/map_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/widgets/contacts/contact_tile.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Contact buildContact({
    required String name,
    required ContactType type,
    int secondByte = 1,
  }) {
    final publicKey = Uint8List(32);
    publicKey[1] = secondByte;

    return Contact(
      publicKey: publicKey,
      type: type,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 46562000,
      advLon: 14950000,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Future<void> pumpTile(WidgetTester tester, Contact contact) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ConnectionProvider()),
          ChangeNotifierProvider(create: (_) => ContactsProvider()),
          ChangeNotifierProvider(create: (_) => MessagesProvider()),
          ChangeNotifierProvider(create: (_) => SensorsProvider()),
          ChangeNotifierProvider(create: (_) => MapProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ContactTile(contact: contact)),
        ),
      ),
    );
  }

  testWidgets('shows trace action for non-channel contacts', (tester) async {
    await pumpTile(
      tester,
      buildContact(name: 'John Smith', type: ContactType.chat),
    );

    await tester.tap(find.text('John Smith'));
    await tester.pumpAndSettle();

    expect(find.text('Trace'), findsOneWidget);
  });

  testWidgets('does not show trace action for channels', (tester) async {
    await pumpTile(
      tester,
      buildContact(name: 'Ops', type: ContactType.channel, secondByte: 3),
    );

    await tester.tap(find.text('Ops'));
    await tester.pumpAndSettle();

    expect(find.text('Trace'), findsNothing);
  });

  testWidgets('shows overridden contact name as primary label', (tester) async {
    await pumpTile(
      tester,
      buildContact(
        name: 'John Smith',
        type: ContactType.chat,
      ).copyWith(nameOverride: 'Rescue One'),
    );

    expect(find.text('Rescue One'), findsOneWidget);
    expect(find.text('John Smith'), findsNothing);
  });

  testWidgets('hides public key in contact tile', (tester) async {
    final contact = buildContact(name: 'John Smith', type: ContactType.chat);

    await pumpTile(tester, contact);

    expect(find.text(contact.publicKeyShort), findsNothing);
    expect(find.byIcon(Icons.key_outlined), findsNothing);
  });
}
