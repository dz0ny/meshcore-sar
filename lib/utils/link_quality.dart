import 'package:flutter/material.dart';

int rssiScore(int rssiDbm) {
  if (rssiDbm >= -60) return 5;
  if (rssiDbm >= -70) return 4;
  if (rssiDbm >= -80) return 3;
  if (rssiDbm >= -90) return 2;
  if (rssiDbm >= -100) return 1;
  return 0;
}

int snrScore(double snrDb) {
  if (snrDb >= 10) return 5;
  if (snrDb >= 5) return 4;
  if (snrDb >= 0) return 3;
  if (snrDb >= -5) return 2;
  if (snrDb >= -10) return 1;
  return 0;
}

String linkQualityLabel(int? rssiDbm, double? snrDb) {
  var totalScore = 0;
  var metricCount = 0;

  if (rssiDbm != null) {
    totalScore += rssiScore(rssiDbm);
    metricCount += 1;
  }
  if (snrDb != null) {
    totalScore += snrScore(snrDb);
    metricCount += 1;
  }

  if (metricCount == 0) return 'Weak';

  final averageScore = totalScore / metricCount;
  if (averageScore >= 4.5) return 'Excellent';
  if (averageScore >= 3.5) return 'Good';
  if (averageScore >= 2.5) return 'Fair';
  return 'Weak';
}

Color linkQualityColor(String quality) {
  switch (quality) {
    case 'Excellent':
      return Colors.green;
    case 'Good':
      return Colors.lightGreen;
    case 'Fair':
      return Colors.orange;
    default:
      return Colors.redAccent;
  }
}
