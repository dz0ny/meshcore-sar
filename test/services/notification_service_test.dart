import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('discovery notification preference persists independently', () async {
    final service = NotificationService();

    await service.setMessageNotificationsEnabled(true);
    await service.setDiscoveryNotificationsEnabled(false);

    final prefs = await SharedPreferences.getInstance();

    expect(service.messageNotificationsEnabled, isTrue);
    expect(service.discoveryNotificationsEnabled, isFalse);
    expect(prefs.getBool('notifications_messages_enabled'), isTrue);
    expect(prefs.getBool('notifications_discovery_enabled'), isFalse);
  });
}
