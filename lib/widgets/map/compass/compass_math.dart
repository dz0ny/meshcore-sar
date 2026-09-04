import 'dart:math';

/// Rotate the compass rose opposite the device heading so the current heading
/// stays under the fixed indicator at the top of the dial.
double compassRoseRotationRadians(double headingDegrees) {
  final normalizedHeading = headingDegrees % 360;
  return _normalizeRadians(-normalizedHeading * pi / 180);
}

/// Convert a compass marker bearing into an on-screen angle for the dial.
double compassDialAngleRadians({
  required double markerDegrees,
  required double headingDegrees,
}) {
  return _normalizeRadians(
    markerDegrees * pi / 180 -
        pi / 2 +
        compassRoseRotationRadians(headingDegrees),
  );
}

double _normalizeRadians(double angle) => atan2(sin(angle), cos(angle));
