import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/connection_provider.dart';

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
      text: deviceInfo.advLat != null ? (deviceInfo.advLat! / 1000000).toStringAsFixed(6) : '0.0',
    );
    _lonController = TextEditingController(
      text: deviceInfo.advLon != null ? (deviceInfo.advLon! / 1000000).toStringAsFixed(6) : '0.0',
    );
    _freqController = TextEditingController(
      text: deviceInfo.radioFreq != null ? (deviceInfo.radioFreq! / 1000).toStringAsFixed(3) : '869.618',
    );
    _txPowerController = TextEditingController(
      text: deviceInfo.txPower?.toString() ?? '20',
    );

    if (deviceInfo.radioBw != null && deviceInfo.radioBw! >= 0 && deviceInfo.radioBw! <= 9) {
      _selectedBandwidth = _bandwidthFromValue(deviceInfo.radioBw!);
    }
    if (deviceInfo.radioSf != null && deviceInfo.radioSf! >= 7 && deviceInfo.radioSf! <= 12) {
      _selectedSpreadingFactor = deviceInfo.radioSf!;
    }
    if (deviceInfo.radioCr != null && deviceInfo.radioCr! >= 5 && deviceInfo.radioCr! <= 8) {
      _selectedCodingRate = deviceInfo.radioCr!;
    }

    // Check if telemetry is enabled (check if lat/lon are set and not zero)
    _telemetryEnabled = (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
                        (deviceInfo.advLon != null && deviceInfo.advLon! != 0);
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
      case 0: return '7.8 kHz';
      case 1: return '10.4 kHz';
      case 2: return '15.6 kHz';
      case 3: return '20.8 kHz';
      case 4: return '31.25 kHz';
      case 5: return '41.7 kHz';
      case 6: return '62.5 kHz';
      case 7: return '125 kHz';
      case 8: return '250 kHz';
      case 9: return '500 kHz';
      default: return '62.5 kHz';
    }
  }

  int _bandwidthToValue(String bw) {
    return _bandwidthOptions.indexOf(bw);
  }

  Future<void> _savePublicInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();
    final deviceInfo = connectionProvider.deviceInfo;

    try {
      // Save name
      if (_nameController.text.isNotEmpty) {
        await connectionProvider.setAdvertName(_nameController.text);
      }

      // Save position and telemetry settings
      if (_telemetryEnabled) {
        final lat = double.tryParse(_latController.text) ?? 0.0;
        final lon = double.tryParse(_lonController.text) ?? 0.0;
        await connectionProvider.setAdvertLatLon(
          latitude: lat,
          longitude: lon,
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
        await connectionProvider.setAdvertLatLon(
          latitude: 0.0,
          longitude: 0.0,
        );

        // Set telemetry modes to "Deny" (mode 0)
        final telemetryModes = 0x00;
        await connectionProvider.setOtherParams(
          manualAddContacts: deviceInfo.manualAddContacts == true ? 1 : 0,
          telemetryModes: telemetryModes,
          advertLocationPolicy: 0,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Public info saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRadioSettings() async {
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      // Parse and save frequency (convert from MHz to kHz)
      final freq = (double.tryParse(_freqController.text) ?? 869.618) * 1000;

      await connectionProvider.setRadioParams(
        frequency: freq.round(),
        bandwidth: _bandwidthToValue(_selectedBandwidth),
        spreadingFactor: _selectedSpreadingFactor,
        codingRate: _selectedCodingRate,
      );

      // Save TX power
      final txPower = int.tryParse(_txPowerController.text) ?? 20;
      await connectionProvider.setTxPower(txPower);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Radio settings saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
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
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _telemetryEnabled = true;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Device Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _InfoRow('BLE Name', deviceInfo.deviceName ?? 'Unknown'),
                  _InfoRow('Mesh Name', deviceInfo.selfName ?? 'Not set'),
                  _InfoRow('Type', _getDeviceTypeString(deviceInfo.deviceType)),
                  _InfoRow('Firmware', deviceInfo.firmwareVersion?.toString() ?? 'Unknown'),
                  _InfoRow('Max Contacts', deviceInfo.maxContacts?.toString() ?? 'Unknown'),
                  _InfoRow('Max Channels', deviceInfo.maxChannels?.toString() ?? 'Unknown'),
                  _InfoRow('Public Key', _getPublicKeyShort(deviceInfo.publicKey)),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Public Info Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Public Info',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _savePublicInfo,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mesh Network Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Mesh Network Name',
                      border: OutlineInputBorder(),
                      helperText: 'Name broadcast in mesh advertisements',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Telemetry Toggle
                  SwitchListTile(
                    title: const Text('Enable Telemetry & Location Sharing'),
                    subtitle: const Text('Allow others to query your location and telemetry'),
                    value: _telemetryEnabled,
                    onChanged: (value) {
                      setState(() {
                        _telemetryEnabled = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // GPS Coordinates (only show if telemetry enabled)
                  if (_telemetryEnabled) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latController,
                            decoration: const InputDecoration(
                              labelText: 'Latitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _lonController,
                            decoration: const InputDecoration(
                              labelText: 'Longitude',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use Current Location'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Radio Settings Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Radio Settings',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _saveRadioSettings,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // LoRa Frequency
                  TextField(
                    controller: _freqController,
                    decoration: const InputDecoration(
                      labelText: 'Frequency (MHz)',
                      border: OutlineInputBorder(),
                      helperText: 'e.g., 869.618',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),

                  // Bandwidth
                  DropdownButtonFormField<String>(
                    value: _selectedBandwidth,
                    decoration: const InputDecoration(
                      labelText: 'Bandwidth',
                      border: OutlineInputBorder(),
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

                  // Spreading Factor
                  DropdownButtonFormField<int>(
                    value: _selectedSpreadingFactor,
                    decoration: const InputDecoration(
                      labelText: 'Spreading Factor',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(6, (index) => index + 7).map((int value) {
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

                  // Coding Rate
                  DropdownButtonFormField<int>(
                    value: _selectedCodingRate,
                    decoration: const InputDecoration(
                      labelText: 'Coding Rate',
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(4, (index) => index + 5).map((int value) {
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

                  // TX Power
                  TextField(
                    controller: _txPowerController,
                    decoration: InputDecoration(
                      labelText: 'TX Power (dBm)',
                      border: const OutlineInputBorder(),
                      helperText: 'Max: ${deviceInfo.maxTxPower ?? 22} dBm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getDeviceTypeString(int? deviceType) {
    if (deviceType == null) return 'Unknown';
    switch (deviceType) {
      case 0: return 'None/Unknown';
      case 1: return 'Chat Node';
      case 2: return 'Repeater';
      case 3: return 'Room/Channel';
      default: return 'Type $deviceType';
    }
  }

  String _getPublicKeyShort(List<int>? publicKey) {
    if (publicKey == null || publicKey.isEmpty) return 'N/A';
    final hex = publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    if (hex.length >= 16) {
      return '${hex.substring(0, 8)}...${hex.substring(hex.length - 8)}';
    }
    return hex;
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
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
