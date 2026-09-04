import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/l10n/app_localizations.dart';
import 'package:meshcore_sar_app/widgets/contacts/add_channel_dialog.dart';

void main() {
  Future<void> pumpSheet(
    WidgetTester tester, {
    required Future<void> Function(String name, String secret) onCreateChannel,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: AddChannelSheet(onCreateChannel: onCreateChannel),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('submits hash channels with an empty secret', (tester) async {
    String? submittedName;
    String? submittedSecret;

    await pumpSheet(
      tester,
      onCreateChannel: (name, secret) async {
        submittedName = name;
        submittedSecret = secret;
      },
    );

    await tester.enterText(find.byType(TextFormField).first, '#slovenia');
    await tester.pump();
    await tester.tap(find.text('Create Channel'));
    await tester.pumpAndSettle();

    expect(submittedName, '#slovenia');
    expect(submittedSecret, '');
  });

  testWidgets('uses done action for hash channels', (tester) async {
    String? submittedName;

    await pumpSheet(
      tester,
      onCreateChannel: (name, secret) async {
        submittedName = name;
      },
    );

    await tester.enterText(find.byType(TextFormField).first, '#slovenia');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(submittedName, '#slovenia');
  });
}
