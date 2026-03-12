import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/device_info.dart';
import '../providers/connection_provider.dart';
import '../services/validation_service.dart';
import '../l10n/app_localizations.dart';

class DeviceConfigScreen extends StatefulWidget {
  const DeviceConfigScreen({super.key});

  @override
  State<DeviceConfigScreen> createState() => _DeviceConfigScreenState();
}

class _DeviceConfigScreenState extends State<DeviceConfigScreen> {
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _freqController;
  late TextEditingController _txPowerController;

  bool _telemetryEnabled = false;
  bool _repeatEnabled = false;
  String _selectedBandwidth = '62.5 kHz';
  int _selectedSpreadingFactor = 8;
  int _selectedCodingRate = 8;

  final List<String> _bandwidthOptions = [
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

  @override
  void initState() {
    super.initState();
    final deviceInfo = context.read<ConnectionProvider>().deviceInfo;

    _nameController = TextEditingController(
      text: deviceInfo.selfName ?? deviceInfo.deviceName ?? '',
    );
    _latController = TextEditingController(
      text: deviceInfo.advLat != null
          ? (deviceInfo.advLat! / 1000000).toStringAsFixed(6)
          : '0.0',
    );
    _lonController = TextEditingController(
      text: deviceInfo.advLon != null
          ? (deviceInfo.advLon! / 1000000).toStringAsFixed(6)
          : '0.0',
    );
    _freqController = TextEditingController(
      text: deviceInfo.radioFreq != null
          ? (deviceInfo.radioFreq! / 1000).toStringAsFixed(3)
          : '869.618',
    );
    _txPowerController = TextEditingController(
      text: deviceInfo.txPower?.toString() ?? '20',
    );

    if (deviceInfo.radioBw != null &&
        deviceInfo.radioBw! >= 0 &&
        deviceInfo.radioBw! <= 9) {
      _selectedBandwidth = _bandwidthFromValue(deviceInfo.radioBw!);
    }
    if (deviceInfo.radioSf != null &&
        deviceInfo.radioSf! >= 7 &&
        deviceInfo.radioSf! <= 12) {
      _selectedSpreadingFactor = deviceInfo.radioSf!;
    }
    if (deviceInfo.radioCr != null &&
        deviceInfo.radioCr! >= 5 &&
        deviceInfo.radioCr! <= 8) {
      _selectedCodingRate = deviceInfo.radioCr!;
    }

    // Check if telemetry is enabled (check if lat/lon are set and not zero)
    _telemetryEnabled =
        (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
        (deviceInfo.advLon != null && deviceInfo.advLon! != 0);

    // Initialize repeat mode from device info (firmware v9+)
    _repeatEnabled = deviceInfo.clientRepeat ?? false;

    // Fetch allowed repeat frequencies on open if device supports repeat mode
    if (deviceInfo.clientRepeat != null &&
        deviceInfo.allowedRepeatFreqRanges == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<ConnectionProvider>().getAllowedRepeatFreq();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConnectionProvider>().getBatteryAndStorage();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _freqController.dispose();
    _txPowerController.dispose();
    super.dispose();
  }

  String _bandwidthFromValue(int bw) {
    switch (bw) {
      case 0:
        return '7.8 kHz';
      case 1:
        return '10.4 kHz';
      case 2:
        return '15.6 kHz';
      case 3:
        return '20.8 kHz';
      case 4:
        return '31.25 kHz';
      case 5:
        return '41.7 kHz';
      case 6:
        return '62.5 kHz';
      case 7:
        return '125 kHz';
      case 8:
        return '250 kHz';
      case 9:
        return '500 kHz';
      default:
        return '62.5 kHz';
    }
  }

  int _bandwidthToValue(String bw) {
    return _bandwidthOptions.indexOf(bw);
  }

  Future<void> _savePublicInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final deviceInfo = connectionProvider.deviceInfo;
    final validator = ValidationService();

    try {
      // Save name
      if (_nameController.text.isNotEmpty) {
        await connectionProvider.setAdvertName(_nameController.text);
      }

      // Save position and telemetry settings
      if (_telemetryEnabled) {
        // Parse and validate coordinates
        final latResult = validator.parseLatitude(_latController.text);
        if (!latResult.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(latResult.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        final lonResult = validator.parseLongitude(_lonController.text);
        if (!lonResult.isSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(lonResult.errorMessage!),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        await connectionProvider.setAdvertLatLon(
          latitude: latResult.value!,
          longitude: lonResult.value!,
        );

        // Set telemetry modes to "Allow All" (mode 2 for both base and location)
        final telemetryModes = 0x0A; // binary: 00001010 (base=2, location=2)
        await connectionProvider.setOtherParams(
          manualAddContacts: deviceInfo.manualAddContacts == true ? 1 : 0,
          telemetryModes: telemetryModes,
          advertLocationPolicy: 1,
        );
      } else {
        // Clear position
        await connectionProvider.setAdvertLatLon(latitude: 0.0, longitude: 0.0);

        // Set telemetry modes to "Deny" (mode 0)
        final telemetryModes = 0x00;
        await connectionProvider.setOtherParams(
          manualAddContacts: deviceInfo.manualAddContacts == true ? 1 : 0,
          telemetryModes: telemetryModes,
          advertLocationPolicy: 0,
        );
      }

      // Refetch device info to update UI with new settings
      await connectionProvider.refreshDeviceInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.save),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToSave(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRadioSettings() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final validator = ValidationService();
    final deviceInfo = connectionProvider.deviceInfo;

    try {
      // Parse and validate frequency
      final freqResult = validator.parseFrequency(_freqController.text);
      if (!freqResult.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(freqResult.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Parse and validate TX power
      final txPowerResult = validator.parseTxPower(
        _txPowerController.text,
        maxPower: deviceInfo.maxTxPower,
      );
      if (!txPowerResult.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(txPowerResult.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Convert from MHz to kHz for protocol
      final freqKhz = (freqResult.value! * 1000).round();

      await connectionProvider.setRadioParams(
        frequency: freqKhz,
        bandwidth: _bandwidthToValue(_selectedBandwidth),
        spreadingFactor: _selectedSpreadingFactor,
        codingRate: _selectedCodingRate,
        repeat: deviceInfo.clientRepeat != null ? _repeatEnabled : null,
      );

      // Save TX power
      await connectionProvider.setTxPower(txPowerResult.value!);

      // Refetch device info to update UI with new settings
      await connectionProvider.refreshDeviceInfo();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.save),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToSave(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.locationServicesDisabled,
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationPermissionDenied,
                ),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(
                  context,
                )!.locationPermissionPermanentlyDenied,
              ),
            ),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      if (!mounted) return;

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _telemetryEnabled = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.locationBroadcast(
                position.latitude.toStringAsFixed(6),
                position.longitude.toStringAsFixed(6),
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.failedToGetLocation(e.toString()),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationSet =
        (deviceInfo.advLat != null && deviceInfo.advLat != 0) ||
        (deviceInfo.advLon != null && deviceInfo.advLon != 0);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _ConfigHeroCard(
              title: deviceInfo.selfName ?? deviceInfo.deviceName ?? 'MeshCore',
              subtitle:
                  '${_getDeviceTypeString(context, deviceInfo.deviceType)} • ${deviceInfo.semanticVersion ?? deviceInfo.manufacturerModel ?? AppLocalizations.of(context)!.unknown}',
              chips: [
                _StatusChipData(
                  icon: Icons.bluetooth,
                  label:
                      '${AppLocalizations.of(context)!.bleName}: ${deviceInfo.deviceName ?? AppLocalizations.of(context)!.unknown}',
                ),
                _StatusChipData(
                  icon: Icons.my_location,
                  label: locationSet ? 'Location ready' : 'Location off',
                  emphasized: locationSet,
                ),
                _StatusChipData(
                  icon: Icons.settings_input_antenna,
                  label: '${_freqController.text} MHz • $_selectedBandwidth',
                ),
                _StatusChipData(
                  icon: Icons.key,
                  label: 'FW v${deviceInfo.firmwareVersion?.toString() ?? "?"}',
                ),
                if (deviceInfo.storageUsedKb != null &&
                    deviceInfo.storageTotalKb != null)
                  _StatusChipData(
                    icon: Icons.storage_rounded,
                    label:
                        '${_formatStorage(deviceInfo.storageUsedKb!)} / ${_formatStorage(deviceInfo.storageTotalKb!)}',
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _ConfigSectionCard(
              title: AppLocalizations.of(context)!.deviceInformation,
              subtitle:
                  '${deviceInfo.manufacturerModel ?? AppLocalizations.of(context)!.unknown} • ${deviceInfo.firmwareBuildDate ?? AppLocalizations.of(context)!.unknown}',
              icon: Icons.memory_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    AppLocalizations.of(context)!.bleName,
                    deviceInfo.deviceName ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.meshName,
                    deviceInfo.selfName ?? AppLocalizations.of(context)!.notSet,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.type,
                    _getDeviceTypeString(context, deviceInfo.deviceType),
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.model,
                    deviceInfo.manufacturerModel ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.version,
                    deviceInfo.semanticVersion ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.buildDate,
                    deviceInfo.firmwareBuildDate ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.firmware,
                    'v${deviceInfo.firmwareVersion?.toString() ?? "?"}',
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.maxContacts,
                    deviceInfo.maxContacts?.toString() ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    AppLocalizations.of(context)!.maxChannels,
                    deviceInfo.maxChannels?.toString() ??
                        AppLocalizations.of(context)!.unknown,
                  ),
                  _InfoRow(
                    'Storage used',
                    _formatStorageValue(deviceInfo.storageUsedKb),
                  ),
                  _InfoRow(
                    'Storage limit',
                    _formatStorageValue(deviceInfo.storageTotalKb),
                  ),
                  _InfoRow('Storage status', _formatStorageStatus(deviceInfo)),
                  if (deviceInfo.storageUsedPercent != null) ...[
                    const SizedBox(height: 10),
                    _StorageUsageMeter(deviceInfo: deviceInfo),
                  ],
                  _CopyableInfoRow(
                    AppLocalizations.of(context)!.publicKey,
                    _getPublicKeyHex(deviceInfo.publicKey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ConfigSectionCard(
              title: AppLocalizations.of(context)!.publicInfo,
              subtitle: AppLocalizations.of(context)!.nameBroadcastInMesh,
              icon: Icons.public_rounded,
              trailing: FilledButton.icon(
                onPressed: _savePublicInfo,
                icon: const Icon(Icons.save_outlined),
                label: Text(AppLocalizations.of(context)!.save),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _telemetryEnabled
                              ? Icons.travel_explore
                              : Icons.location_disabled,
                          color: _telemetryEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.telemetryAndLocationSharing,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _telemetryEnabled
                                    ? 'This device advertises position data to the mesh.'
                                    : 'Position broadcasting is currently disabled.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _telemetryEnabled,
                          onChanged: (value) {
                            setState(() {
                              _telemetryEnabled = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.meshNetworkName,
                      border: const OutlineInputBorder(),
                      helperText: AppLocalizations.of(
                        context,
                      )!.nameBroadcastInMesh,
                    ),
                  ),
                  if (_telemetryEnabled) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CompactCoordinateField(
                            controller: _latController,
                            label: AppLocalizations.of(context)!.lat,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _CompactCoordinateField(
                            controller: _lonController,
                            label: AppLocalizations.of(context)!.lon,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _useCurrentLocation,
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: AppLocalizations.of(
                            context,
                          )!.useCurrentLocation,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            _ConfigSectionCard(
              title: AppLocalizations.of(context)!.radioSettings,
              subtitle:
                  '${_freqController.text} MHz • SF$_selectedSpreadingFactor • CR$_selectedCodingRate',
              icon: Icons.settings_input_antenna_rounded,
              trailing: FilledButton.icon(
                onPressed: _saveRadioSettings,
                icon: const Icon(Icons.save_outlined),
                label: Text(AppLocalizations.of(context)!.save),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RadioMetricTile(
                          label: AppLocalizations.of(context)!.bandwidth,
                          value: _selectedBandwidth,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RadioMetricTile(
                          label: AppLocalizations.of(context)!.spreadingFactor,
                          value: 'SF$_selectedSpreadingFactor',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RadioMetricTile(
                          label: AppLocalizations.of(context)!.codingRate,
                          value: 'CR$_selectedCodingRate',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _freqController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.frequencyMHz,
                      border: const OutlineInputBorder(),
                      helperText: AppLocalizations.of(
                        context,
                      )!.frequencyExample,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBandwidth,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.bandwidth,
                      border: const OutlineInputBorder(),
                    ),
                    items: _bandwidthOptions.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedBandwidth = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedSpreadingFactor,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.spreadingFactor,
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(6, (index) => index + 7).map((
                      int value,
                    ) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSpreadingFactor = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedCodingRate,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.codingRate,
                      border: const OutlineInputBorder(),
                    ),
                    items: List.generate(4, (index) => index + 5).map((
                      int value,
                    ) {
                      return DropdownMenuItem<int>(
                        value: value,
                        child: Text(value.toString()),
                      );
                    }).toList(),
                    onChanged: (int? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCodingRate = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _txPowerController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.txPowerDbm,
                      border: const OutlineInputBorder(),
                      helperText: AppLocalizations.of(
                        context,
                      )!.maxPowerDbm(deviceInfo.maxTxPower ?? 22),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  if (deviceInfo.clientRepeat != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Client Repeat Mode'),
                        subtitle:
                            deviceInfo.allowedRepeatFreqRanges != null &&
                                deviceInfo.allowedRepeatFreqRanges!.isNotEmpty
                            ? Text(
                                'Allowed: ${deviceInfo.allowedRepeatFreqRanges!.map((r) => r.lower == r.upper ? '${(r.lower / 1000).toStringAsFixed(3)} MHz' : '${(r.lower / 1000).toStringAsFixed(3)}–${(r.upper / 1000).toStringAsFixed(3)} MHz').join(', ')}',
                              )
                            : const Text(
                                'Repeat packets on behalf of nearby nodes',
                              ),
                        value: _repeatEnabled,
                        onChanged: (value) {
                          setState(() {
                            _repeatEnabled = value;
                          });
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDeviceTypeString(BuildContext context, int? deviceType) {
    if (deviceType == null) return AppLocalizations.of(context)!.unknown;
    switch (deviceType) {
      case 0:
        return AppLocalizations.of(context)!.noneUnknown;
      case 1:
        return AppLocalizations.of(context)!.chatNode;
      case 2:
        return AppLocalizations.of(context)!.repeater;
      case 3:
        return AppLocalizations.of(context)!.roomChannel;
      default:
        return AppLocalizations.of(context)!.typeNumber(deviceType);
    }
  }

  String _getPublicKeyHex(List<int>? publicKey) {
    if (publicKey == null || publicKey.isEmpty) return 'N/A';
    return publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  String _formatStorageValue(int? storageKb) {
    if (storageKb == null) {
      return AppLocalizations.of(context)!.unknown;
    }
    return _formatStorage(storageKb);
  }

  String _formatStorageStatus(DeviceInfo deviceInfo) {
    final used = deviceInfo.storageUsedKb;
    final total = deviceInfo.storageTotalKb;
    final percent = deviceInfo.storageUsedPercent;

    if (used == null || total == null || percent == null) {
      return AppLocalizations.of(context)!.unknown;
    }

    return '${percent.toStringAsFixed(0)}% full (${_formatStorage(total - used)} free)';
  }

  String _formatStorage(int storageKb) {
    if (storageKb >= 1024 * 1024) {
      return '${(storageKb / (1024 * 1024)).toStringAsFixed(2)} GB';
    }
    if (storageKb >= 1024) {
      return '${(storageKb / 1024).toStringAsFixed(1)} MB';
    }
    return '$storageKb KB';
  }
}

class _ConfigHeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_StatusChipData> chips;

  const _ConfigHeroCard({
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.tune_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.82,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: chips.map(_StatusChip.new).toList(),
          ),
        ],
      ),
    );
  }
}

class _ConfigSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _ConfigSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _StatusChipData {
  final IconData icon;
  final String label;
  final bool emphasized;

  const _StatusChipData({
    required this.icon,
    required this.label,
    this.emphasized = false,
  });
}

class _StatusChip extends StatelessWidget {
  final _StatusChipData data;

  const _StatusChip(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chipColor = data.emphasized
        ? colorScheme.primary.withValues(alpha: 0.14)
        : colorScheme.onPrimaryContainer.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 16, color: colorScheme.onPrimaryContainer),
          const SizedBox(width: 8),
          Text(
            data.label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactCoordinateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _CompactCoordinateField({
    required this.controller,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
    );
  }
}

class _RadioMetricTile extends StatelessWidget {
  final String label;
  final String value;

  const _RadioMetricTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyableInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyableInfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(
                        context,
                      )!.copiedToClipboardShort(label),
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageUsageMeter extends StatelessWidget {
  final DeviceInfo deviceInfo;

  const _StorageUsageMeter({required this.deviceInfo});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = ((deviceInfo.storageUsedPercent ?? 0) / 100).clamp(
      0.0,
      1.0,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storage_rounded, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Device storage',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 10,
              backgroundColor: colorScheme.surface,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(deviceInfo.storageUsedPercent ?? 0).toStringAsFixed(0)}% used',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
