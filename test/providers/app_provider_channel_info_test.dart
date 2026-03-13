import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/providers/app_provider.dart';

void main() {
  group('AppProvider channel info handling', () {
    test('treats zeroed unnamed non-public channel as deleted', () {
      expect(
        AppProvider.isDeletedChannelInfo(2, '', Uint8List(16)),
        isTrue,
      );
    });

    test('keeps unnamed non-public channel when secret is configured', () {
      final secret = Uint8List.fromList([
        1,
        ...List<int>.filled(15, 0),
      ]);

      expect(
        AppProvider.isDeletedChannelInfo(2, '', secret),
        isFalse,
      );
      expect(
        AppProvider.channelContactName(2, ''),
        'Channel 2',
      );
    });
  });
}
