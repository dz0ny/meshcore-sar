import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/sensors_provider.dart';
import 'package:meshcore_sar_app/screens/sensors_tab.dart';
import 'package:meshcore_sar_app/widgets/sensors/sensor_telemetry_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> waitUntilLoaded(SensorsProvider provider) async {
    for (var i = 0; i < 20 && !provider.isLoaded; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(provider.isLoaded, isTrue);
  }

  Contact buildSensorContact({
    int firstByte = 0x44,
    String name = 'WX Station',
  }) {
    final publicKey = Uint8List(32);
    publicKey[0] = firstByte;

    return Contact(
      publicKey: publicKey,
      type: ContactType.sensor,
      flags: 0,
      outPathLen: 0,
      outPath: Uint8List(64),
      advName: name,
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      telemetry: ContactTelemetry(
        batteryPercentage: 84,
        temperature: 21.5,
        extraSensorData: const {
          '__source_channel:battery': 1,
          '__source_channel:temperature': 1,
          'illuminance_2': 500.0,
        },
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
  }

  testWidgets('customize action opens full customization view', (tester) async {
    final contact = buildSensorContact();
    final sensorsProvider = SensorsProvider();
    final contactsProvider = ContactsProvider();

    await waitUntilLoaded(sensorsProvider);
    contactsProvider.addOrUpdateContact(contact);
    await sensorsProvider.addSensor(contact);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ContactsProvider>.value(
            value: contactsProvider,
          ),
          ChangeNotifierProvider<SensorsProvider>.value(value: sensorsProvider),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SensorCustomizeView(
            publicKeyHex: contact.publicKeyHex,
            initialContact: contact,
            onRenameMetric:
                ({
                  required BuildContext context,
                  required String publicKeyHex,
                  required SensorMetricOption option,
                  required SensorsProvider sensorsProvider,
                }) async {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Customize WX Station'), findsOneWidget);
    expect(find.text('Live preview'), findsOneWidget);
    expect(find.text('Refresh schedule'), findsOneWidget);
    expect(
      find.byKey(
        const ValueKey('sensor_selector_metric_channel_extra:illuminance_2'),
      ),
      findsOneWidget,
    );
    expect(find.text('Channel 2'), findsOneWidget);
  });

  testWidgets('add sensor sheet keeps close action available when scrolled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var didClose = false;
    final candidates = List<Contact>.generate(
      20,
      (index) =>
          buildSensorContact(firstByte: index + 1, name: 'Sensor ${index + 1}'),
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddSensorSheet(
            candidates: candidates,
            onSelect: (_) async {},
            onClose: () {
              didClose = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final closeButton = find.byTooltip('Close');
    expect(closeButton, findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pump();

    expect(closeButton, findsOneWidget);

    await tester.tap(closeButton);
    await tester.pump();

    expect(didClose, isTrue);
  });
}
