import 'package:flutter/material.dart';
import 'package:meshcore_client/meshcore_client.dart';
import 'package:provider/provider.dart';
import '../models/device_info.dart';
import '../providers/connection_provider.dart';
import '../widgets/device/spectrum_scan_panel.dart';
import '../l10n/app_localizations.dart';

class SpectrumScanScreen extends StatefulWidget {
  const SpectrumScanScreen({super.key});

  @override
  State<SpectrumScanScreen> createState() => _SpectrumScanScreenState();
}

class _SpectrumScanScreenState extends State<SpectrumScanScreen> {
  static const List<String> _bandwidthOptions = [
    '7.8 kHz',
    '10.4 kHz',
    '15.6 kHz',
    '20.8 kHz',
    '31.25 kHz',
    '41.7 kHz',
    '62.5 kHz',
    '125 kHz',
    '250 kHz',
    '500 kHz',
  ];

  String _selectedBandwidth = '62.5 kHz';
  bool _isSpectrumScanRunning = false;
  bool _rangeInitialized = false;
  String? _lastRangeSourceKey;
  late double _scanRangeMinMhz;
  late double _scanRangeMaxMhz;
  late RangeValues _scanRangeValues;
  List<SpectrumScanCandidate> _scanCandidates = const [];
  int? _selectedScanFrequencyKhz;
  int _completedScanSectors = 0;
  int _totalScanSectors = 0;

  List<SpectrumScanCandidate> get _recommendedScanCandidates =>
      _scanCandidates.take(8).toList();

  @override
  void initState() {
    super.initState();
    final deviceInfo = _deviceInfo;
    if (deviceInfo.radioBw != null &&
        deviceInfo.radioBw! >= 0 &&
        deviceInfo.radioBw! < _bandwidthOptions.length) {
      _selectedBandwidth = _bandwidthOptions[deviceInfo.radioBw!];
    }
    _syncRangeFromDevice(deviceInfo);
    _selectedScanFrequencyKhz = deviceInfo.radioFreq;
  }

  DeviceInfo get _deviceInfo => context.read<ConnectionProvider>().deviceInfo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRangeFromDevice(context.watch<ConnectionProvider>().deviceInfo);
  }

  void _syncRangeFromDevice(DeviceInfo deviceInfo) {
    final minKhz = deviceInfo.spectrumScanMinKhz;
    final maxKhz = deviceInfo.spectrumScanMaxKhz;
    late double normalizedMinMhz;
    late double normalizedMaxMhz;
    late String sourceKey;

    if (minKhz != null && maxKhz != null && maxKhz > minKhz) {
      final normalized = _normalizeScanRange(
        minKhz / 1000.0,
        maxKhz / 1000.0,
        deviceInfo.radioFreq != null ? deviceInfo.radioFreq! / 1000.0 : null,
      );
      normalizedMinMhz = normalized.$1;
      normalizedMaxMhz = normalized.$2;
      sourceKey = 'fw:$minKhz:$maxKhz';
    } else {
      final normalized = _normalizeScanRange(
        null,
        null,
        deviceInfo.radioFreq != null ? deviceInfo.radioFreq! / 1000.0 : null,
      );
      normalizedMinMhz = normalized.$1;
      normalizedMaxMhz = normalized.$2;
      sourceKey =
          'fallback:${deviceInfo.radioFreq != null ? deviceInfo.radioFreq! ~/ 1000 : 869525}';
    }

    if (_rangeInitialized && _lastRangeSourceKey == sourceKey) {
      return;
    }

    _scanRangeMinMhz = normalizedMinMhz;
    _scanRangeMaxMhz = normalizedMaxMhz;

    if (_scanRangeMaxMhz <= _scanRangeMinMhz) {
      _scanRangeMaxMhz = _scanRangeMinMhz + 0.5;
    }

    _scanRangeValues = RangeValues(_scanRangeMinMhz, _scanRangeMaxMhz);
    _rangeInitialized = true;
    _lastRangeSourceKey = sourceKey;
  }

  (double, double) _normalizeScanRange(
    double? minMhz,
    double? maxMhz,
    double? centerMhz,
  ) {
    const hardMinMhz = 800.0;
    const hardMaxMhz = 950.0;
    final center = centerMhz ?? 869.525;

    if (minMhz != null && maxMhz != null) {
      final clampedMin = minMhz.clamp(hardMinMhz, hardMaxMhz);
      final clampedMax = maxMhz.clamp(hardMinMhz, hardMaxMhz);
      if (clampedMax > clampedMin) {
        return (clampedMin, clampedMax);
      }
    }

    if (center >= 900.0 && center <= 930.0) {
      return (902.0, 928.0);
    }

    return (863.0, 870.0);
  }

  double _bandwidthToKhz(String bw) {
    switch (bw) {
      case '7.8 kHz':
        return 7.8;
      case '10.4 kHz':
        return 10.4;
      case '15.6 kHz':
        return 15.6;
      case '20.8 kHz':
        return 20.8;
      case '31.25 kHz':
        return 31.25;
      case '41.7 kHz':
        return 41.7;
      case '62.5 kHz':
        return 62.5;
      case '125 kHz':
        return 125.0;
      case '250 kHz':
        return 250.0;
      case '500 kHz':
        return 500.0;
      default:
        return 62.5;
    }
  }

  String _currentParamProfile(DeviceInfo deviceInfo) {
    final sf = deviceInfo.radioSf ?? 8;
    final cr = deviceInfo.radioCr ?? 8;
    return 'BW $_selectedBandwidth  |  SF$sf  |  CR 4/$cr';
  }

  String _recommendationTitle(int index) {
    switch (index) {
      case 0:
        return 'Best candidate';
      case 1:
        return 'Alternate';
      case 2:
        return 'Fallback';
      default:
        return 'Candidate ${index + 1}';
    }
  }

  List<int> _possibleBracketFrequenciesKhz() {
    final bandwidthKhz = _bandwidthToKhz(_selectedBandwidth);
    final halfBandwidthKhz = bandwidthKhz / 2.0;
    final startKhz = (_scanRangeValues.start * 1000).round();
    final stopKhz = (_scanRangeValues.end * 1000).round();
    final firstCenterKhz = (startKhz + halfBandwidthKhz).round();
    final lastCenterKhz = (stopKhz - halfBandwidthKhz).round();

    if (lastCenterKhz < firstCenterKhz) {
      return const [];
    }

    final stepKhz = bandwidthKhz >= 125.0 ? bandwidthKhz.round() : 25;
    final centers = <int>[];
    for (
      var centerKhz = firstCenterKhz;
      centerKhz <= lastCenterKhz && centers.length < 8;
      centerKhz += stepKhz
    ) {
      centers.add(centerKhz);
    }

    if (centers.isEmpty || centers.last != lastCenterKhz) {
      centers.add(lastCenterKhz);
    }

    return centers.toSet().toList()..sort();
  }

  void _resetDerivedScanResults() {
    _scanCandidates = const [];
    _selectedScanFrequencyKhz = null;
  }

  List<(int startKhz, int stopKhz)> _buildScanSectors(double bandwidthKhz) {
    final startKhz = (_scanRangeValues.start * 1000).round();
    final stopKhz = (_scanRangeValues.end * 1000).round();
    final sectorWidthKhz = (bandwidthKhz * 24).round().clamp(250, 1200);
    final overlapKhz = bandwidthKhz.round().clamp(8, 500);
    final sectors = <(int startKhz, int stopKhz)>[];

    var sectorStartKhz = startKhz;
    while (sectorStartKhz < stopKhz) {
      final sectorStopKhz = (sectorStartKhz + sectorWidthKhz).clamp(
        sectorStartKhz + overlapKhz,
        stopKhz,
      );
      sectors.add((sectorStartKhz, sectorStopKhz));
      if (sectorStopKhz >= stopKhz) {
        break;
      }
      sectorStartKhz = sectorStopKhz - overlapKhz;
    }

    return sectors;
  }

  List<SpectrumScanCandidate> _mergeSectorCandidates(
    Iterable<SpectrumScanCandidate> candidates,
  ) {
    final byFrequency = <int, SpectrumScanCandidate>{};
    for (final candidate in candidates) {
      final existing = byFrequency[candidate.centerFrequencyKhz];
      if (existing == null ||
          candidate.occupancyPercent < existing.occupancyPercent ||
          (candidate.occupancyPercent == existing.occupancyPercent &&
              candidate.peakRssiDbm < existing.peakRssiDbm) ||
          (candidate.occupancyPercent == existing.occupancyPercent &&
              candidate.peakRssiDbm == existing.peakRssiDbm &&
              candidate.avgRssiDbm < existing.avgRssiDbm)) {
        byFrequency[candidate.centerFrequencyKhz] = candidate;
      }
    }

    final merged = byFrequency.values.toList()
      ..sort((a, b) {
        final occupancyCompare = a.occupancyPercent.compareTo(
          b.occupancyPercent,
        );
        if (occupancyCompare != 0) return occupancyCompare;
        final peakCompare = a.peakRssiDbm.compareTo(b.peakRssiDbm);
        if (peakCompare != 0) return peakCompare;
        return a.avgRssiDbm.compareTo(b.avgRssiDbm);
      });
    return merged;
  }

  Future<void> _runSpectrumScan() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final bandwidthKhz = _bandwidthToKhz(_selectedBandwidth);
    final sectors = _buildScanSectors(bandwidthKhz);
    final sectorCandidates = <SpectrumScanCandidate>[];

    setState(() {
      _isSpectrumScanRunning = true;
      _resetDerivedScanResults();
      _completedScanSectors = 0;
      _totalScanSectors = sectors.length;
    });

    try {
      for (var i = 0; i < sectors.length; i++) {
        final sector = sectors[i];
        final result = await connectionProvider.scanSpectrum(
          startFrequencyKhz: sector.$1,
          stopFrequencyKhz: sector.$2,
          bandwidthKhz: bandwidthKhz.round(),
          stepKhz: (bandwidthKhz / 2).round().clamp(1, 1000),
          dwellMs: 160,
          thresholdDb: 8,
        );
        if (result != null) {
          sectorCandidates.addAll(result.candidates);
          final mergedCandidates = _mergeSectorCandidates(sectorCandidates);
          if (mounted) {
            setState(() {
              _scanCandidates = mergedCandidates;
              if (_selectedScanFrequencyKhz == null &&
                  mergedCandidates.isNotEmpty) {
                _selectedScanFrequencyKhz =
                    mergedCandidates.first.centerFrequencyKhz;
              }
              _completedScanSectors = i + 1;
            });
          }
        } else if (mounted) {
          setState(() {
            _completedScanSectors = i + 1;
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSpectrumScanRunning = false;
          if (_completedScanSectors == 0) {
            _totalScanSectors = sectors.length;
          }
        });
      }
    }

    if (!mounted) return;

    final mergedCandidates = _mergeSectorCandidates(sectorCandidates);
    if (mergedCandidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.spectrumScanReturnedNoCandidateFrequencies),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _scanCandidates = mergedCandidates;
      _selectedScanFrequencyKhz = mergedCandidates.first.centerFrequencyKhz;
    });
  }

  Future<void> _applySelectedScanFrequency() async {
    if (_selectedScanFrequencyKhz == null) return;

    final connectionProvider = context.read<ConnectionProvider>();
    final deviceInfo = connectionProvider.deviceInfo;

    await connectionProvider.setRadioParams(
      frequency: _selectedScanFrequencyKhz!,
      bandwidth: _bandwidthOptions.indexOf(_selectedBandwidth),
      spreadingFactor: deviceInfo.radioSf ?? 8,
      codingRate: deviceInfo.radioCr ?? 8,
      repeat: deviceInfo.clientRepeat,
    );
    await connectionProvider.refreshDeviceInfo();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Applied ${(_selectedScanFrequencyKhz! / 1000.0).toStringAsFixed(3)} MHz',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  int? _currentPreviewFrequencyKhz(DeviceInfo deviceInfo) {
    if (_selectedScanFrequencyKhz != null) {
      return _selectedScanFrequencyKhz;
    }
    return deviceInfo.radioFreq;
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);
    final possibleBracketFrequencies = _possibleBracketFrequenciesKhz();
    final recommendedScanCandidates = _recommendedScanCandidates;
    final recommendationFrequencies = recommendedScanCandidates.isNotEmpty
        ? recommendedScanCandidates
              .map((candidate) => candidate.centerFrequencyKhz)
              .toList()
        : possibleBracketFrequencies;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.spectrumScan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBandwidth,
                    decoration: const InputDecoration(
                      labelText: 'Bandwidth',
                      border: OutlineInputBorder(),
                      helperText:
                          'Scan and apply frequencies for this bandwidth',
                    ),
                    items: _bandwidthOptions.map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedBandwidth = value;
                        _resetDerivedScanResults();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    deviceInfo.spectrumScanMinKhz != null &&
                            deviceInfo.spectrumScanMaxKhz != null
                        ? 'Firmware scan range: ${_scanRangeMinMhz.toStringAsFixed(3)}-${_scanRangeMaxMhz.toStringAsFixed(3)} MHz'
                        : 'Fallback scan range selected from current band. MeshCore commonly uses EU868 or US915.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_isSpectrumScanRunning) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Scanning sector ${_completedScanSectors + 1} of $_totalScanSectors. Results update as each sector completes.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  SpectrumScanPanel(
                    theme: theme,
                    scanSupported: deviceInfo.supportsSpectrumScan == true,
                    isRunning: _isSpectrumScanRunning,
                    rangeMinMhz: _scanRangeMinMhz,
                    rangeMaxMhz: _scanRangeMaxMhz,
                    rangeValues: _scanRangeValues,
                    bandwidthKhz: _bandwidthToKhz(_selectedBandwidth),
                    selectedFrequencyKhz: _currentPreviewFrequencyKhz(
                      deviceInfo,
                    ),
                    graphCandidates: _scanCandidates,
                    selectableCandidates: recommendedScanCandidates,
                    onRangeChanged: (values) {
                      setState(() {
                        _scanRangeValues = values;
                        _resetDerivedScanResults();
                      });
                    },
                    onCandidateChanged: (value) {
                      setState(() {
                        _selectedScanFrequencyKhz = value;
                      });
                    },
                    onRunScan: _runSpectrumScan,
                    onApplySelected: _applySelectedScanFrequency,
                  ),
                  if (recommendationFrequencies.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      _scanCandidates.isNotEmpty
                          ? 'Recommended profiles'
                          : 'Possible brackets',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _scanCandidates.isNotEmpty
                          ? 'Suggested frequencies from the latest scan with the radio parameters to keep alongside them.'
                          : 'Usable frequency brackets derived from the selected span and bandwidth, even without live scan data.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (
                      var i = 0;
                      i < recommendationFrequencies.length;
                      i++
                    ) ...[
                      _RecommendationTile(
                        title: _recommendationTitle(i),
                        frequencyKhz: recommendationFrequencies[i],
                        candidate: recommendedScanCandidates.isNotEmpty
                            ? recommendedScanCandidates[i]
                            : null,
                        bandwidthKhz: _bandwidthToKhz(_selectedBandwidth),
                        paramsLabel: _currentParamProfile(deviceInfo),
                        isSelected:
                            _selectedScanFrequencyKhz ==
                            recommendationFrequencies[i],
                        onSelect: () {
                          setState(() {
                            _selectedScanFrequencyKhz =
                                recommendationFrequencies[i];
                          });
                        },
                      ),
                      if (i != recommendationFrequencies.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final String title;
  final int frequencyKhz;
  final SpectrumScanCandidate? candidate;
  final double bandwidthKhz;
  final String paramsLabel;
  final bool isSelected;
  final VoidCallback onSelect;

  const _RecommendationTile({
    required this.title,
    required this.frequencyKhz,
    required this.candidate,
    required this.bandwidthKhz,
    required this.paramsLabel,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primaryContainer.withValues(alpha: 0.55)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: scheme.primary, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(frequencyKhz / 1000.0).toStringAsFixed(3)} MHz',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(paramsLabel, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 6),
            Text(
              candidate != null
                  ? 'Occupancy ${candidate!.occupancyPercent}%  |  Avg ${candidate!.avgRssiDbm} dBm  |  Peak ${candidate!.peakRssiDbm} dBm'
                  : 'Bracket ${(frequencyKhz / 1000.0 - bandwidthKhz / 2000.0).toStringAsFixed(3)}-${(frequencyKhz / 1000.0 + bandwidthKhz / 2000.0).toStringAsFixed(3)} MHz',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
