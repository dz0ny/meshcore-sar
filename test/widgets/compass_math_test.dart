import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_sar_app/widgets/map/compass/compass_math.dart';

void main() {
  group('compass dial math', () {
    test('rotates the rose opposite the heading', () {
      expect(compassRoseRotationRadians(0), closeTo(0, 1e-10));
      expect(compassRoseRotationRadians(90), closeTo(-pi / 2, 1e-10));
      expect(compassRoseRotationRadians(450), closeTo(-pi / 2, 1e-10));
    });

    test('places east at the top when heading east', () {
      expect(
        compassDialAngleRadians(markerDegrees: 90, headingDegrees: 90),
        closeTo(-pi / 2, 1e-10),
      );
      expect(
        compassDialAngleRadians(markerDegrees: 270, headingDegrees: 90),
        closeTo(pi / 2, 1e-10),
      );
    });

    test('places west at the top when heading west', () {
      expect(
        compassDialAngleRadians(markerDegrees: 270, headingDegrees: 270),
        closeTo(-pi / 2, 1e-10),
      );
      expect(
        compassDialAngleRadians(markerDegrees: 90, headingDegrees: 270),
        closeTo(pi / 2, 1e-10),
      );
    });
  });
}
