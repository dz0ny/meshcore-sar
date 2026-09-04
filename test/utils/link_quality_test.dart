import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/utils/link_quality.dart';

void main() {
  group('linkQualityLabel', () {
    test('classifies SNR-only values without forcing them to weak', () {
      expect(linkQualityLabel(null, 12.0), 'Excellent');
      expect(linkQualityLabel(null, 6.0), 'Good');
      expect(linkQualityLabel(null, 1.0), 'Fair');
      expect(linkQualityLabel(null, -6.0), 'Weak');
    });

    test('classifies RSSI-only values using direct thresholds', () {
      expect(linkQualityLabel(-58, null), 'Excellent');
      expect(linkQualityLabel(-68, null), 'Good');
      expect(linkQualityLabel(-78, null), 'Fair');
      expect(linkQualityLabel(-92, null), 'Weak');
    });

    test('averages mixed metrics when both are available', () {
      expect(linkQualityLabel(-72, 11.0), 'Good');
      expect(linkQualityLabel(-85, 7.0), 'Fair');
    });
  });
}
