import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentTheme;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedTheme;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _selectedTheme = widget.currentTheme;
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _saveThemePreference(ThemeMode theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', theme.name);
  }

  void _handleThemeChange(ThemeMode? theme) {
    if (theme != null) {
      setState(() {
        _selectedTheme = theme;
      });
      _saveThemePreference(theme);
      widget.onThemeChanged(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // General Settings Section
          _buildSectionHeader('General'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_getThemeLabel(_selectedTheme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(),
          ),
          const Divider(),

          // About Section
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: Text(
              _packageInfo != null
                  ? '${_packageInfo!.version} (${_packageInfo!.buildNumber})'
                  : 'Loading...',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('App Name'),
            subtitle: Text(_packageInfo?.appName ?? 'MeshCore SAR'),
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('About MeshCore SAR'),
            subtitle: const Text(
              'Search & Rescue application with BLE mesh networking and offline maps',
            ),
            onTap: () => _showAboutDialog(),
          ),
          const Divider(),

          // Developer Section
          _buildSectionHeader('Developer'),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Package Name'),
            subtitle: Text(_packageInfo?.packageName ?? 'com.meshcore.sar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  String _getThemeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'Auto (System)';
    }
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              subtitle: const Text('Always use light theme'),
              value: ThemeMode.light,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              subtitle: const Text('Always use dark theme'),
              value: ThemeMode.dark,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Auto (System)'),
              subtitle: const Text('Follow system theme'),
              value: ThemeMode.system,
              groupValue: _selectedTheme,
              onChanged: (value) {
                _handleThemeChange(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About MeshCore SAR'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MeshCore SAR',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${_packageInfo?.version ?? '1.0.0'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                'A Search & Rescue application designed for emergency response teams. '
                'Features include:\n\n'
                '• BLE mesh networking for device-to-device communication\n'
                '• Offline maps with multiple layer options\n'
                '• Real-time team member tracking\n'
                '• SAR tactical markers (found person, fire, staging)\n'
                '• Contact management and messaging\n'
                '• GPS tracking with compass heading\n'
                '• Map tile caching for offline use',
              ),
              const SizedBox(height: 16),
              Text(
                'Technologies Used:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Flutter for cross-platform development\n'
                '• BLE (Bluetooth Low Energy) for mesh networking\n'
                '• OpenStreetMap for mapping\n'
                '• Provider for state management\n'
                '• SharedPreferences for local storage',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
