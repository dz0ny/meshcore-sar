import 'package:flutter/material.dart';
import 'package:meshcore_client/meshcore_client.dart' show LogRxDataInfo;

class SignalMetric {
  final String valueLabel;
  final Color color;
  final int activeBars;

  const SignalMetric({
    required this.valueLabel,
    required this.color,
    required this.activeBars,
  });

  static SignalMetric? fromRxInfo(LogRxDataInfo? rxInfo) {
    if (rxInfo == null) return null;
    return fromValues(rssiDbm: rxInfo.rssiDbm, snrDb: rxInfo.snrDb);
  }

  static SignalMetric? fromValues({int? rssiDbm, double? snrDb}) {
    if (snrDb != null) {
      return SignalMetric(
        valueLabel: '${snrDb.toStringAsFixed(1)}dB',
        color: snrDb >= 10
            ? Colors.green
            : snrDb >= 0
            ? Colors.amber
            : Colors.redAccent,
        activeBars: snrDb >= 10
            ? 3
            : snrDb >= 0
            ? 2
            : 1,
      );
    }
    if (rssiDbm != null) {
      return SignalMetric(
        valueLabel: '$rssiDbm dBm',
        color: rssiDbm >= -80
            ? Colors.green
            : rssiDbm >= -95
            ? Colors.amber
            : Colors.redAccent,
        activeBars: rssiDbm >= -80
            ? 3
            : rssiDbm >= -95
            ? 2
            : 1,
      );
    }
    return null;
  }
}

class CompactSignalIndicator extends StatelessWidget {
  final SignalMetric metric;
  final bool dense;

  const CompactSignalIndicator({
    super.key,
    required this.metric,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(context).colorScheme.outlineVariant;
    final barWidth = dense ? 4.0 : 5.0;
    final baseHeight = dense ? 8.0 : 10.0;
    final barStep = dense ? 6.0 : 8.0;
    final barSpacing = dense ? 2.0 : 3.0;
    final labelGap = dense ? 4.0 : 6.0;
    final labelFontSize = dense ? 10.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var index = 0; index < 3; index++) ...[
              if (index > 0) SizedBox(width: barSpacing),
              Container(
                width: barWidth,
                height: baseHeight + (index * barStep),
                decoration: BoxDecoration(
                  color: index < metric.activeBars ? metric.color : inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: labelGap),
        Text(
          metric.valueLabel,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
