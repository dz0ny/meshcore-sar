import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/services/messaging_route_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('route preference defaults are clear-path disabled and fallback enabled', () async {
    expect(await MessagingRoutePreferences.getClearPathOnMaxRetry(), isFalse);
    expect(
      await MessagingRoutePreferences.getNearestRelayFallbackEnabled(),
      isTrue,
    );
  });

  test('route preferences persist changes', () async {
    await MessagingRoutePreferences.setClearPathOnMaxRetry(true);
    await MessagingRoutePreferences.setNearestRelayFallbackEnabled(false);

    expect(await MessagingRoutePreferences.getClearPathOnMaxRetry(), isTrue);
    expect(
      await MessagingRoutePreferences.getNearestRelayFallbackEnabled(),
      isFalse,
    );
  });

  test('legacy auto route rotation preference is removed during cleanup', () async {
    SharedPreferences.setMockInitialValues({
      'messaging_auto_route_rotation_enabled': true,
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('messaging_auto_route_rotation_enabled'), isTrue);

    await MessagingRoutePreferences.cleanupLegacySettings();

    expect(
      prefs.containsKey('messaging_auto_route_rotation_enabled'),
      isFalse,
    );
  });
}
