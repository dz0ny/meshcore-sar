import 'package:flutter/material.dart';
import 'package:meshcore_client/meshcore_client.dart';
import '../../l10n/app_localizations.dart';

class SpectrumScanPanel extends StatelessWidget {
  final ThemeData theme;
  final bool scanSupported;
  final bool isRunning;
  final double rangeMinMhz;
  final double rangeMaxMhz;
  final RangeValues rangeValues;
  final double bandwidthKhz;
  final int? selectedFrequencyKhz;
  final List<SpectrumScanCandidate> graphCandidates;
  final List<SpectrumScanCandidate> selectableCandidates;
  final ValueChanged<RangeValues> onRangeChanged;
  final ValueChanged<int?> onCandidateChanged;
  final VoidCallback onRunScan;
  final VoidCallback onApplySelected;

  const SpectrumScanPanel({
    super.key,
    required this.theme,
    required this.scanSupported,
    required this.isRunning,
    required this.rangeMinMhz,
    required this.rangeMaxMhz,
    required this.rangeValues,
    required this.bandwidthKhz,
    required this.selectedFrequencyKhz,
    required this.graphCandidates,
    required this.selectableCandidates,
    required this.onRangeChanged,
    required this.onCandidateChanged,
    required this.onRunScan,
    required this.onApplySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Power Scan',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: scanSupported && !isRunning ? onRunScan : null,
                icon: isRunning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.radar),
                label: Text(
                  scanSupported
                      ? (isRunning ? 'Scanning' : 'Scan')
                      : 'Unavailable',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            scanSupported
                ? 'Full range with bandwidth footprint. Firmware enforces hardware band limits and pauses the mesh while scanning.'
                : 'Full range with bandwidth footprint. This companion does not support spectrum scan mode, so scanning is disabled.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          _FrequencyRangePreview(
            minMhz: rangeMinMhz,
            maxMhz: rangeMaxMhz,
            selectedRange: rangeValues,
            selectedBandwidthKhz: bandwidthKhz,
            selectedFrequencyKhz: selectedFrequencyKhz,
            candidates: graphCandidates,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _LegendChip(
                color: theme.colorScheme.primary,
                label: AppLocalizations.of(context)!.quiet,
              ),
              _LegendChip(
                color: Colors.orange,
                label: AppLocalizations.of(context)!.moderate,
              ),
              _LegendChip(
                color: theme.colorScheme.error,
                label: AppLocalizations.of(context)!.busy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${rangeValues.start.toStringAsFixed(3)} MHz',
                style: theme.textTheme.labelMedium,
              ),
              Text(
                '${rangeValues.end.toStringAsFixed(3)} MHz',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
          RangeSlider(
            values: rangeValues,
            min: rangeMinMhz,
            max: rangeMaxMhz,
            divisions: (((rangeMaxMhz - rangeMinMhz) * 20).round()).clamp(
              1,
              400,
            ),
            labels: RangeLabels(
              rangeValues.start.toStringAsFixed(3),
              rangeValues.end.toStringAsFixed(3),
            ),
            onChanged: onRangeChanged,
          ),
          if (selectableCandidates.isEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                scanSupported
                    ? 'No scan results yet. Adjust the range and run a scan to populate candidate frequencies.'
                    : 'Spectrum preview only. This companion can display the configured span, but cannot scan for open channels.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue: selectedFrequencyKhz,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Candidate frequency',
                border: OutlineInputBorder(),
                helperText: 'Best frequencies for the current bandwidth',
              ),
              items: selectableCandidates.map((candidate) {
                return DropdownMenuItem<int>(
                  value: candidate.centerFrequencyKhz,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${candidate.centerFrequencyMhz.toStringAsFixed(3)} MHz',
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${candidate.occupancyPercent}% occupied  |  peak ${candidate.peakRssiDbm} dBm',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
              selectedItemBuilder: (context) {
                return selectableCandidates.map((candidate) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${candidate.centerFrequencyMhz.toStringAsFixed(3)} MHz',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              onChanged: onCandidateChanged,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: selectedFrequencyKhz == null
                    ? null
                    : onApplySelected,
                icon: Icon(Icons.north_east),
                label: Text(AppLocalizations.of(context)!.useSelectedFrequency),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendChip({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}

class _FrequencyRangePreview extends StatelessWidget {
  final double minMhz;
  final double maxMhz;
  final RangeValues selectedRange;
  final double selectedBandwidthKhz;
  final int? selectedFrequencyKhz;
  final List<SpectrumScanCandidate> candidates;

  const _FrequencyRangePreview({
    required this.minMhz,
    required this.maxMhz,
    required this.selectedRange,
    required this.selectedBandwidthKhz,
    required this.selectedFrequencyKhz,
    required this.candidates,
  });

  double _positionFor(double mhz) {
    final span = maxMhz - minMhz;
    if (span <= 0) return 0;
    return ((mhz - minMhz) / span).clamp(0.0, 1.0);
  }

  Color _candidateColor(BuildContext context, int occupancyPercent) {
    final scheme = Theme.of(context).colorScheme;
    if (occupancyPercent <= 10) return scheme.primary;
    if (occupancyPercent <= 35) return Colors.orange;
    return scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final spanMhz = maxMhz - minMhz;
    final selectedFreqMhz = selectedFrequencyKhz != null
        ? selectedFrequencyKhz! / 1000.0
        : null;
    final bwMhz = selectedBandwidthKhz / 1000.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final rangeLeft = _positionFor(selectedRange.start) * width;
        final rangeRight = _positionFor(selectedRange.end) * width;

        double? bwLeft;
        double? bwWidth;
        if (selectedFreqMhz != null && spanMhz > 0) {
          bwLeft = _positionFor(selectedFreqMhz - (bwMhz / 2)) * width;
          final bwRight = _positionFor(selectedFreqMhz + (bwMhz / 2)) * width;
          bwWidth = (bwRight - bwLeft).clamp(4.0, width);
        }

        return Container(
          height: 108,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerLow,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 12,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: rangeLeft,
                top: 12,
                width: (rangeRight - rangeLeft).clamp(8.0, width),
                height: 56,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: scheme.primaryContainer,
                    border: Border.all(color: scheme.primary),
                  ),
                ),
              ),
              if (bwLeft != null && bwWidth != null)
                Positioned(
                  left: bwLeft,
                  top: 28,
                  width: bwWidth,
                  height: 24,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: scheme.tertiaryContainer,
                      border: Border.all(color: scheme.tertiary),
                    ),
                  ),
                ),
              for (final candidate in candidates)
                Positioned(
                  left: (_positionFor(candidate.centerFrequencyMhz) * width)
                      .clamp(10.0, width - 18.0),
                  top: 72,
                  child: Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _candidateColor(
                            context,
                            candidate.occupancyPercent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        candidate.centerFrequencyMhz.toStringAsFixed(3),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
