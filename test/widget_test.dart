// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshcore_sar_app/main.dart';
import 'package:meshcore_sar_app/screens/home_screen.dart';
import 'package:meshcore_sar_app/screens/welcome_wizard_screen.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    // Build app.
    await tester.pumpWidget(const MeshCoreSarApp());

    // During async initialization, loading indicator is shown.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Give async startup a bounded amount of time without requiring full settle
    // (the app may keep background animations/timers alive).
    await tester.pump(const Duration(seconds: 2));
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.byType(HomeScreen).evaluate().isNotEmpty ||
          find.byType(WelcomeWizardScreen).evaluate().isNotEmpty,
      isTrue,
    );
  });
}
