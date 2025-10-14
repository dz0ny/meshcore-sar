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

  bool _sharePosition = false;
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
      text: deviceInfo.selfName ?? deviceInfo.displayName ?? '',
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
    if (deviceInfo.radioSf != null) {
      // Validate spreading factor is in valid range (7-12)
      if (deviceInfo.radioSf! >= 7 && deviceInfo.radioSf! <= 12) {
        _selectedSpreadingFactor = deviceInfo.radioSf!;
      } else {
        debugPrint('⚠️ Invalid spreading factor from device: ${deviceInfo.radioSf}. Using default: 8');
        _selectedSpreadingFactor = 8;
      }
    }
    if (deviceInfo.radioCr != null) {
      // Validate coding rate is in valid range (5-8)
      if (deviceInfo.radioCr! >= 5 && deviceInfo.radioCr! <= 8) {
        _selectedCodingRate = deviceInfo.radioCr!;
      } else {
        debugPrint('⚠️ Invalid coding rate from device: ${deviceInfo.radioCr}. Using default: 8');
        _selectedCodingRate = 8;
      }
    }
    _sharePosition = (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
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
    // Convert bandwidth value to display string
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

    try {
      // Save name
      if (_nameController.text.isNotEmpty) {
        await connectionProvider.setAdvertName(_nameController.text);
      }

      // Save position if share position is enabled
      if (_sharePosition) {
        final lat = double.tryParse(_latController.text) ?? 0.0;
        final lon = double.tryParse(_lonController.text) ?? 0.0;
        await connectionProvider.setAdvertLatLon(
          latitude: lat,
          longitude: lon,
        );
      } else {
        // Clear position
        await connectionProvider.setAdvertLatLon(
          latitude: 0.0,
          longitude: 0.0,
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
            content: Text('Failed to save public info: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveRadioSettings() async {
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      // Parse and save frequency (convert from MHz to Hz)
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
            content: Text('Failed to save radio settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshDeviceInfo() async {
    final connectionProvider = context.read<ConnectionProvider>();

    try {
      await connectionProvider.refreshDeviceInfo();

      if (context.mounted) {
        // Update controllers with fresh data
        final deviceInfo = connectionProvider.deviceInfo;
        setState(() {
          if (deviceInfo.selfName != null) {
            _nameController.text = deviceInfo.selfName!;
          }
          if (deviceInfo.advLat != null) {
            _latController.text = (deviceInfo.advLat! / 1000000).toStringAsFixed(6);
          }
          if (deviceInfo.advLon != null) {
            _lonController.text = (deviceInfo.advLon! / 1000000).toStringAsFixed(6);
          }
          if (deviceInfo.radioFreq != null) {
            _freqController.text = (deviceInfo.radioFreq! / 1000).toStringAsFixed(3);
          }
          if (deviceInfo.txPower != null) {
            _txPowerController.text = deviceInfo.txPower.toString();
          }
          if (deviceInfo.radioBw != null && deviceInfo.radioBw! >= 0 && deviceInfo.radioBw! <= 9) {
            _selectedBandwidth = _bandwidthFromValue(deviceInfo.radioBw!);
          }
          if (deviceInfo.radioSf != null) {
            // Validate spreading factor is in valid range (7-12)
            if (deviceInfo.radioSf! >= 7 && deviceInfo.radioSf! <= 12) {
              _selectedSpreadingFactor = deviceInfo.radioSf!;
            } else {
              debugPrint('⚠️ Invalid spreading factor from device: ${deviceInfo.radioSf}. Using default: 8');
              _selectedSpreadingFactor = 8;
            }
          }
          if (deviceInfo.radioCr != null) {
            // Validate coding rate is in valid range (5-8)
            if (deviceInfo.radioCr! >= 5 && deviceInfo.radioCr! <= 8) {
              _selectedCodingRate = deviceInfo.radioCr!;
            } else {
              debugPrint('⚠️ Invalid coding rate from device: ${deviceInfo.radioCr}. Using default: 8');
              _selectedCodingRate = 8;
            }
          }
          _sharePosition = (deviceInfo.advLat != null && deviceInfo.advLat! != 0) ||
                           (deviceInfo.advLon != null && deviceInfo.advLon! != 0);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device info refreshed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDeviceTypeString(int? deviceType) {
    if (deviceType == null) return 'Unknown';
    switch (deviceType) {
      case 0:
        return 'None/Unknown';
      case 1:
        return 'Chat Node';
      case 2:
        return 'Repeater';
      case 3:
        return 'Room/Channel Server';
      default:
        return 'Type $deviceType';
    }
  }

  String _getTelemetryModesString(deviceInfo) {
    if (deviceInfo.telemetryModes == null) return 'Unknown';

    final telemetryModes = deviceInfo.telemetryModes!;
    final baseMode = telemetryModes & 0x03; // bits 0-1
    final locationMode = (telemetryModes >> 2) & 0x03; // bits 2-3

    String baseModeStr = _getTelemetryModeString(baseMode);
    String locationModeStr = _getTelemetryModeString(locationMode);

    return 'Base: $baseModeStr, Loc: $locationModeStr';
  }

  String _getTelemetryModeString(int mode) {
    switch (mode) {
      case 0:
        return 'Deny';
      case 1:
        return 'By Contact';
      case 2:
        return 'Allow All';
      default:
        return 'Unknown';
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
        _sharePosition = true;
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
          SnackBar(
            content: Text('Failed to get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceInfo = context.watch<ConnectionProvider>().deviceInfo;
    final publicKeyHex = deviceInfo.publicKey != null
        ? deviceInfo.publicKey!
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join('')
        : '';
    final publicKeyShort = publicKeyHex.isNotEmpty && publicKeyHex.length >= 16
        ? '${publicKeyHex.substring(0, 8)}...${publicKeyHex.substring(publicKeyHex.length - 8)}'
        : 'unknown';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Device Settings'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          const SizedBox(height: 8),

          // Device Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Device Avatar
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade400,
                        Colors.purple.shade700,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      deviceInfo.displayName?.substring(0, 1).toUpperCase() ?? 'M',
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Device Name
                Text(
                  deviceInfo.displayName ?? 'MeshCore Device',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Public Key Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        publicKeyShort,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Device Information Section (Read-only)
          _SectionHeader(
            title: 'Device Information',
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Device Information'),
                    content: const Text(
                      'This information is provided by the MeshCore device '
                      'and cannot be edited. Tap refresh to update.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('GOT IT'),
                      ),
                    ],
                  ),
                );
              },
              iconSize: 20,
            ),
          ),

          _SettingTile(
            icon: Icons.numbers,
            label: 'Device Type',
            isFirst: true,
            trailing: Text(
              _getDeviceTypeString(deviceInfo.deviceType),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.groups,
            label: 'Max Contacts',
            trailing: Text(
              deviceInfo.maxContacts != null
                  ? deviceInfo.maxContacts.toString()
                  : 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.tag,
            label: 'Max Channels',
            trailing: Text(
              deviceInfo.maxChannels != null
                  ? deviceInfo.maxChannels.toString()
                  : 'Unknown',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.settings_suggest,
            label: 'Telemetry Modes',
            trailing: Text(
              _getTelemetryModesString(deviceInfo),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.group_add,
            label: 'Manual Add Contacts',
            isLast: true,
            trailing: Text(
              deviceInfo.manualAddContacts == true ? 'Enabled' : 'Disabled',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Public Info Section
          _SectionHeader(
            title: 'Public Info',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshDeviceInfo,
                  tooltip: 'Refresh',
                  iconSize: 20,
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _savePublicInfo,
                  tooltip: 'Save',
                  iconSize: 20,
                ),
              ],
            ),
          ),

          _SettingTile(
            icon: Icons.person,
            label: 'Name',
            isFirst: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Device name',
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.key,
            label: 'Public Key',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    publicKeyHex.substring(0, 32.clamp(0, publicKeyHex.length)),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: publicKeyHex));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Public key copied'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.copy,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _SettingTile(
            icon: Icons.location_on,
            label: 'Latitude',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IntrinsicWidth(
                child: TextField(
                  controller: _latController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                ),
              ),
            ),
          ),

          _SettingTile(
            icon: null,
            label: 'Longitude',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IntrinsicWidth(
                    child: TextField(
                      controller: _lonController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _useCurrentLocation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.my_location,
                        size: 16,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          _SettingTile(
            icon: Icons.wifi_tethering,
            label: 'Share Position',
            isLast: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: _sharePosition,
                  onChanged: (value) {
                    setState(() {
                      _sharePosition = value;
                    });
                  },
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Share Position'),
                          content: const Text(
                            'When enabled, your device will broadcast its GPS coordinates '
                            'to other devices in the mesh network.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('GOT IT'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Radio Settings Section
          _SectionHeader(
            title: 'Radio Settings',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton(
                  onPressed: () {
                    // TODO: Show preset selection dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Preset selection coming soon')),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Choose Preset', style: TextStyle(fontSize: 12)),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveRadioSettings,
                  tooltip: 'Save',
                  iconSize: 20,
                ),
              ],
            ),
          ),

          _SettingTile(
            icon: Icons.radio,
            label: 'Frequency (MHz)',
            isFirst: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _freqController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ),
          ),

          _SettingTile(
            icon: Icons.graphic_eq,
            label: 'Bandwidth',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _selectedBandwidth,
                underline: const SizedBox(),
                isDense: true,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
            ),
          ),

          _SettingTile(
            icon: Icons.layers,
            label: 'Spreading Factor',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _selectedSpreadingFactor,
                underline: const SizedBox(),
                isDense: true,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
            ),
          ),

          _SettingTile(
            icon: Icons.data_usage,
            label: 'Coding Rate',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<int>(
                value: _selectedCodingRate,
                underline: const SizedBox(),
                isDense: true,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
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
            ),
          ),

          _SettingTile(
            icon: Icons.power,
            label: 'Transmit Power (dBm)',
            isLast: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _txPowerController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMorePressed;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    this.onMorePressed,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            trailing!
          else if (onMorePressed != null)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onMorePressed,
              iconSize: 20,
            ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Widget? child;
  final Widget? trailing;
  final bool isFirst;
  final bool isLast;

  const _SettingTile({
    this.icon,
    required this.label,
    this.child,
    this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 8 : 0,
        bottom: isLast ? 0 : 1,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(12) : Radius.zero,
          bottom: isLast ? const Radius.circular(12) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
          ] else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (child != null)
            Flexible(
              child: child!,
            )
          else if (trailing != null)
            trailing!,
        ],
      ),
    );
  }
}
