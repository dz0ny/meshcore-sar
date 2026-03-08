import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/services/messaging_route_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('route preference defaults are disabled', () async {
    expect(
      await MessagingRoutePreferences.getAutoRouteRotationEnabled(),
      isFalse,
    );
    expect(await MessagingRoutePreferences.getClearPathOnMaxRetry(), isFalse);
    expect(
      await MessagingRoutePreferences.getNearestRelayFallbackEnabled(),
      isTrue,
    );
  });

  test('route preferences persist changes', () async {
    await MessagingRoutePreferences.setAutoRouteRotationEnabled(true);
    await MessagingRoutePreferences.setClearPathOnMaxRetry(true);
    await MessagingRoutePreferences.setNearestRelayFallbackEnabled(false);

    expect(
      await MessagingRoutePreferences.getAutoRouteRotationEnabled(),
      isTrue,
    );
    expect(await MessagingRoutePreferences.getClearPathOnMaxRetry(), isTrue);
    expect(
      await MessagingRoutePreferences.getNearestRelayFallbackEnabled(),
      isFalse,
    );
  });
}
