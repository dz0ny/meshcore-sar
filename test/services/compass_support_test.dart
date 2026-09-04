import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/services/compass_support.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('reports compass support only on mobile targets', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(CompassSupport.isAvailable, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(CompassSupport.isAvailable, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(CompassSupport.isAvailable, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(CompassSupport.isAvailable, isFalse);
  });
}
