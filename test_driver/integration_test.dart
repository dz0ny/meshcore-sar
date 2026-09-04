import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot: (name, image, [args]) async {
      final outputDir = Platform.environment['SCREENSHOT_OUTPUT_DIR'] ??
          'ios/fastlane/screenshots/en-US';
      final file = File('$outputDir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(image);
      return true;
    },
  );
}
