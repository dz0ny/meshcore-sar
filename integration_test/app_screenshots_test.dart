import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/main.dart';
import 'package:meshcore_sar_app/providers/contacts_provider.dart';
import 'package:meshcore_sar_app/providers/messages_provider.dart';
import 'package:meshcore_sar_app/screens/home_screen.dart';
import 'package:meshcore_sar_app/services/wizard_preferences.dart';
import 'package:meshcore_sar_app/utils/sample_data_generator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const screenshotPrefix = String.fromEnvironment('SCREENSHOT_PREFIX');

  testWidgets('captures App Store screenshots', (tester) async {
    SharedPreferences.setMockInitialValues({
      'wizard_completed': true,
      'wizard_version': 1,
    });
    await WizardPreferences.setWizardCompleted(true);

    await tester.pumpWidget(const MeshCoreSarApp());
    await _pumpUntilFound(tester, find.byType(HomeScreen));
    await binding.convertFlutterSurfaceToImage();

    final homeContext = tester.element(find.byType(HomeScreen));
    _loadSampleData(homeContext);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    await _takeScreenshot(binding, tester, '${screenshotPrefix}01-messages');

    await _tapTab(tester, 'Contacts');
    await _takeScreenshot(binding, tester, '${screenshotPrefix}02-contacts');

    await _tapTab(tester, 'Map');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await _takeScreenshot(binding, tester, '${screenshotPrefix}03-map');

    await _openOverflowItem(tester, Icons.more_vert, 'Settings');
    await _takeScreenshot(binding, tester, '${screenshotPrefix}04-settings');
  });
}

void _loadSampleData(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  const centerLocation = LatLng(46.0569, 14.5058);
  final contacts = SampleDataGenerator.generateContacts(
    centerLocation: centerLocation,
    l10n: l10n,
    teamMemberCount: 5,
    channelCount: 2,
  );
  final sampleMessages = SampleDataGenerator.generateAllMessages(
    centerLocation: centerLocation,
    l10n: l10n,
    foundPersonCount: 2,
    fireCount: 1,
    stagingCount: 1,
    objectCount: 1,
    generalChannelMessages: 8,
    emergencyChannelMessages: 5,
  );
  context.read<ContactsProvider>().addContacts(contacts);
  for (final message in sampleMessages.messages) {
    context.read<MessagesProvider>().addMessage(
      message,
      contactLocationSnapshot: sampleMessages.contactLocations[message.id],
    );
  }
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapTab(WidgetTester tester, String label) async {
  final tab = find.text(label).last;
  await tester.tap(tab);
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
}

Future<void> _openOverflowItem(
  WidgetTester tester,
  IconData buttonIcon,
  String label,
) async {
  await tester.tap(find.byIcon(buttonIcon));
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  await tester.tap(find.text(label));
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

Future<void> _takeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 500));
  final bytes = await binding.takeScreenshot(name);
  expect(bytes.isNotEmpty, isTrue);
}
