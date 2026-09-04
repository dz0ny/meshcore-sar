import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/connection_provider.dart';
import '../providers/app_provider.dart';
import '../models/device_info.dart' show ConnectionMode, DeviceInfo;
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/sensors_provider.dart';
import '../theme/app_theme.dart';
import 'messages_tab.dart';
import 'contacts_tab.dart';
import 'discovery_screen.dart';
import 'sensors_tab.dart';
import 'map_tab.dart';
import 'repeaters_map_screen.dart';
import 'settings_screen.dart';
import 'device_config_screen.dart';
import 'packet_log_screen.dart';
import 'live_traffic_screen.dart';
import 'profiles_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/permission_request_dialog.dart';
import '../widgets/connection_dialog.dart';
import '../utils/battery_display_helper.dart';
import '../services/mesh_map_nodes_service.dart';
import '../services/profile_device_key_resolver.dart';
import '../services/profile_manager.dart';
import '../services/profile_workspace_coordinator.dart';
import '../services/profiles_feature_service.dart';

enum _HomeTab { messages, contacts, sensors, map }

class HomeScreen extends StatefulWidget {
  final Function(AppThemeMode) onThemeChanged;
  final Function(Locale?) onLocaleChanged;
  final AppThemeMode currentTheme;
  final Locale? currentLocale;
  final bool shouldShowPermissionDialog;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentTheme,
    required this.currentLocale,
    this.shouldShowPermissionDialog = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  late final AppProvider _appProvider;
  late final ConnectionProvider _connectionProvider;
  int _currentIndex = 0;
  bool _isMapFullscreen = false;
  bool _showRxTxIndicators = true;
  bool _isMapEnabled = true;
  bool _isContactsEnabled = true;
  bool _isSensorsEnabled = false;
  bool _isSimpleMode = false;
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;
  String? _lastProfileDeviceKey;
  Timer? _sensorAutoRefreshTicker;

  List<_HomeTab> get _enabledTabs {
    if (_isSimpleMode) {
      return const [_HomeTab.messages, _HomeTab.map];
    }
    return [
      _HomeTab.messages,
      if (_isContactsEnabled) _HomeTab.contacts,
      if (_isSensorsEnabled) _HomeTab.sensors,
      if (_isMapEnabled) _HomeTab.map,
    ];
  }

  _HomeTab get _currentTab {
    final tabs = _enabledTabs;
    final safeIndex = _currentIndex < tabs.length
        ? _currentIndex
        : tabs.length - 1;
    return tabs[safeIndex < 0 ? 0 : safeIndex];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appProvider = context.read<AppProvider>();
    _connectionProvider = context.read<ConnectionProvider>();
    _connectionProvider.addListener(_handleConnectionProviderChanged);
    _isMapEnabled = _appProvider.isMapEnabled;
    _isContactsEnabled = _appProvider.isContactsEnabled;
    _isSensorsEnabled = _appProvider.isSensorsEnabled;
    _isSimpleMode = _appProvider.isSimpleMode;
    _appProvider.addListener(_handleAppProviderChanged);

    // Initialize synchronously so first build always has a valid controller.
    _initTabController();
    _loadRxTxPreference();
    MeshMapNodesService.syncInBackgroundIfStale();

    // Show permission dialog after the first frame if needed
    if (widget.shouldShowPermissionDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleConnectionProviderChanged();
    });
    _configureSensorAutoRefreshTicker();
  }

  void _initTabController() {
    _tabController = TabController(length: _enabledTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _handleTabActivated(_currentTab);
    });
  }

  void _handleAppProviderChanged() {
    if (!mounted) return;
    _updateTabController(
      mapEnabled: _appProvider.isMapEnabled,
      contactsEnabled: _appProvider.isContactsEnabled,
      sensorsEnabled: _appProvider.isSensorsEnabled,
      simpleMode: _appProvider.isSimpleMode,
    );
  }

  void _onTabChanged() {
    final previousTab = _currentTab;
    final nextIndex = _tabController.index;

    setState(() {
      _currentIndex = nextIndex;
      if (_currentTab != _HomeTab.map) {
        _isMapFullscreen = false;
      }
    });

    final nextTab = _currentTab;
    if (previousTab != nextTab) {
      _handleTabActivated(nextTab);
    }
  }

  void _updateTabController({
    required bool mapEnabled,
    required bool contactsEnabled,
    required bool sensorsEnabled,
    required bool simpleMode,
  }) {
    if (_isMapEnabled == mapEnabled &&
        _isContactsEnabled == contactsEnabled &&
        _isSensorsEnabled == sensorsEnabled &&
        _isSimpleMode == simpleMode) {
      return;
    }

    final oldTabs = _enabledTabs;
    final oldIndex = oldTabs.isEmpty
        ? 0
        : _tabController.index.clamp(0, oldTabs.length - 1);
    final oldTab = oldTabs[oldIndex];

    final oldController = _tabController;
    oldController.removeListener(_onTabChanged);
    oldController.dispose();

    // Update state
    _isMapEnabled = mapEnabled;
    _isContactsEnabled = contactsEnabled;
    _isSensorsEnabled = sensorsEnabled;
    _isSimpleMode = simpleMode;
    if (!_isMapEnabled) {
      _isMapFullscreen = false;
    }
    _configureSensorAutoRefreshTicker();

    final newTabs = _enabledTabs;
    final newIndex = newTabs.indexOf(oldTab);

    // Create new controller
    _tabController = TabController(length: newTabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);

    _currentIndex = newIndex >= 0 ? newIndex : 0;
    _tabController.index = _currentIndex;

    setState(() {});
    _handleTabActivated(_currentTab);
  }

  void _navigateToTab(_HomeTab tab) {
    final targetIndex = _enabledTabs.indexOf(tab);
    if (targetIndex >= 0 && targetIndex != _tabController.index) {
      _tabController.animateTo(targetIndex);
    }
  }

  void _handleTabActivated(_HomeTab tab) {
    _syncFastLocationUiState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      switch (tab) {
        case _HomeTab.messages:
          break;
        case _HomeTab.contacts:
          context.read<ContactsProvider>().markAllAsViewed();
          break;
        case _HomeTab.sensors:
          break;
        case _HomeTab.map:
          break;
      }
    });
  }

  void _syncFastLocationUiState() {
    final isActiveTab =
        _currentTab == _HomeTab.map || _currentTab == _HomeTab.messages;
    _appProvider.setFastLocationUiActive(
      _lifecycleState == AppLifecycleState.resumed && isActiveTab,
    );
  }

  void _handleConnectionProviderChanged() {
    final deviceKey = ProfileDeviceKeyResolver.resolve(
      deviceInfo: _connectionProvider.deviceInfo,
      connectionMode: _connectionProvider.connectionMode,
    );
    if (_lastProfileDeviceKey == deviceKey) {
      return;
    }
    _lastProfileDeviceKey = deviceKey;
    if (deviceKey == null || !mounted) {
      return;
    }
    unawaited(
      context
          .read<ProfileWorkspaceCoordinator>()
          .syncActiveProfileForCurrentDevice(),
    );
  }

  @override
  void dispose() {
    _sensorAutoRefreshTicker?.cancel();
    _connectionProvider.removeListener(_handleConnectionProviderChanged);
    WidgetsBinding.instance.removeObserver(this);
    _appProvider.setFastLocationUiActive(false);
    _appProvider.removeListener(_handleAppProviderChanged);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _openLiveTraffic(ConnectionProvider provider) {
    openLiveTrafficScreen(context, provider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    _syncFastLocationUiState();
    _configureSensorAutoRefreshTicker();
    if (state == AppLifecycleState.resumed) {
      MeshMapNodesService.syncInBackgroundIfStale();
    }
  }

  void _configureSensorAutoRefreshTicker() {
    _sensorAutoRefreshTicker?.cancel();
    if (!_isSensorsEnabled || _lifecycleState != AppLifecycleState.resumed) {
      _sensorAutoRefreshTicker = null;
      return;
    }

    unawaited(_runSensorAutoRefreshTick());
    _sensorAutoRefreshTicker = Timer.periodic(
      SensorsProvider.selfAutoRefreshInterval,
      (_) {
        unawaited(_runSensorAutoRefreshTick());
      },
    );
  }

  Future<void> _runSensorAutoRefreshTick() async {
    if (!mounted ||
        !_isSensorsEnabled ||
        _lifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final sensorsProvider = context.read<SensorsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final connectionProvider = context.read<ConnectionProvider>();
    sensorsProvider.clearExpiredRefreshStates();
    await sensorsProvider.refreshDueSensors(
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
      now: DateTime.now(),
    );
    await sensorsProvider.captureTrackedTelemetryHistory(
      contactsProvider: contactsProvider,
      connectionProvider: connectionProvider,
    );
  }

  Future<void> _loadRxTxPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _showRxTxIndicators =
            prefs.getBool(
              ProfileStorageScope.scopedKey('show_rx_tx_indicators'),
            ) ??
            true;
      });
    }
  }

  void _showPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        onPermissionsGranted: () {
          debugPrint('✅ Location permissions granted');
        },
        onPermissionsDenied: () {
          debugPrint('⚠️ Location permissions denied');
          // Show a snackbar to inform the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.locationPermissionRequired,
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
        },
      ),
    );
  }

  void _showDeviceInfoSheet(BuildContext context, DeviceInfo deviceInfo) {
    // Request self telemetry so it's fresh
    context.read<ConnectionProvider>().requestSelfTelemetry();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          final telemetry = contactsProvider.selfTelemetry;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    deviceInfo.selfName ?? deviceInfo.deviceName ?? 'Device',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _deviceInfoRow(
                    context,
                    Icons.bluetooth,
                    'BLE Signal',
                    deviceInfo.signalRssi != null
                        ? '${deviceInfo.signalRssi} dBm'
                        : 'N/A',
                  ),
                  if (deviceInfo.batteryPercent != null)
                    _deviceInfoRow(
                      context,
                      BatteryDisplayHelper.getBatteryIcon(
                        deviceInfo.batteryPercent!,
                      ),
                      'Battery',
                      '${deviceInfo.batteryPercent!.round()}%',
                    ),
                  if (deviceInfo.batteryMilliVolts != null)
                    _deviceInfoRow(
                      context,
                      Icons.bolt,
                      'Voltage',
                      '${(deviceInfo.batteryMilliVolts! / 1000).toStringAsFixed(2)}V',
                    ),
                  if (deviceInfo.storageUsedKb != null &&
                      deviceInfo.storageTotalKb != null)
                    _deviceInfoRow(
                      context,
                      Icons.storage,
                      'Storage',
                      '${deviceInfo.storageUsedKb} / ${deviceInfo.storageTotalKb} KB',
                    ),
                  if (deviceInfo.firmwareVersion != null)
                    _deviceInfoRow(
                      context,
                      Icons.system_update,
                      'Firmware',
                      'v${deviceInfo.firmwareVersion}',
                    ),
                  if (deviceInfo.radioFreq != null)
                    _deviceInfoRow(
                      context,
                      Icons.radio,
                      'Frequency',
                      '${(deviceInfo.radioFreq! / 1000).toStringAsFixed(3)} MHz',
                    ),
                  if (deviceInfo.txPower != null)
                    _deviceInfoRow(
                      context,
                      Icons.power,
                      'TX Power',
                      '${deviceInfo.txPower} dBm',
                    ),
                  if (telemetry != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Self Telemetry',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (telemetry.temperature != null)
                      _deviceInfoRow(
                        context,
                        Icons.thermostat,
                        'Temperature',
                        '${telemetry.temperature!.toStringAsFixed(1)}°C',
                      ),
                    if (telemetry.humidity != null)
                      _deviceInfoRow(
                        context,
                        Icons.water_drop,
                        'Humidity',
                        '${telemetry.humidity!.toStringAsFixed(1)}%',
                      ),
                    if (telemetry.pressure != null)
                      _deviceInfoRow(
                        context,
                        Icons.compress,
                        'Pressure',
                        '${telemetry.pressure!.toStringAsFixed(1)} hPa',
                      ),
                    if (telemetry.gpsLocation != null)
                      _deviceInfoRow(
                        context,
                        Icons.gps_fixed,
                        'GPS',
                        '${telemetry.gpsLocation!.latitude.toStringAsFixed(5)}, ${telemetry.gpsLocation!.longitude.toStringAsFixed(5)}',
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _deviceInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSignalBars({required int activeBars, required Color color}) {
    final inactive = Colors.grey.withValues(alpha: 0.3);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 1.5),
          Container(
            width: 2.5,
            height: 4.0 + (i * 2),
            decoration: BoxDecoration(
              color: i < activeBars ? color : inactive,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactActivityIndicator({
    required bool rxActive,
    required bool txActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: rxActive ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: txActive ? Colors.blue : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConnectionDialog(BuildContext context) async {
    await showConnectionDialogFlow(
      context,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Set localizations for notifications
    final messagesProvider = context.read<MessagesProvider>();
    final localizations = AppLocalizations.of(context);
    if (localizations != null) {
      messagesProvider.setLocalizations(localizations);
    }

    context.watch<AppProvider>();
    final activeProfileId = context.select<ProfileManager, String>(
      (manager) => manager.activeProfileId,
    );

    final enabledTabs = _enabledTabs;
    final isMapTabActive = _currentTab == _HomeTab.map;
    final shouldHideUI = _isMapEnabled && _isMapFullscreen && isMapTabActive;
    final shouldShowTabBar = enabledTabs.length > 1;

    return Scaffold(
      appBar: shouldHideUI
          ? null
          : AppBar(
              toolbarHeight: 64,
              titleSpacing: 8,
              title: _buildCompactStatusBar(),
              actions: [
                Consumer<ConnectionProvider>(
                  builder: (context, provider, child) {
                    final isConnected =
                        provider.deviceInfo.isConnected ||
                        provider.deviceInfo.isConnected;
                    if (isConnected) {
                      return IconButton(
                        onPressed: () async {
                          await provider.disconnect();
                        },
                        icon: Icon(Icons.power_settings_new),
                        tooltip: AppLocalizations.of(context)!.disconnect,
                        color: Colors.red.shade700,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) {
                    final items = <PopupMenuEntry<void>>[];
                    final profilesEnabled =
                        !_isSimpleMode &&
                        context.read<ProfileManager>().profilesEnabled;

                    if (!_isSimpleMode) {
                      items.add(
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.radar_outlined),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.liveTraffic),
                            ],
                          ),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            final provider = context.read<ConnectionProvider>();
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LiveTrafficScreen.fromProvider(
                                        provider,
                                        openPacketLogs: () {
                                          navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) => PacketLogScreen(
                                                bleService: provider.bleService,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                ),
                              );
                            });
                          },
                        ),
                      );

                      items.add(
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.router_outlined),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.repeatersMap),
                            ],
                          ),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RepeatersMapScreen(),
                                  fullscreenDialog: true,
                                ),
                              );
                            });
                          },
                        ),
                      );

                      items.add(
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.person_search),
                              const SizedBox(width: 8),
                              Consumer<ContactsProvider>(
                                builder: (context, contactsProvider, child) {
                                  final pendingCount =
                                      contactsProvider.pendingAdverts.length;
                                  return Text(
                                    pendingCount > 0
                                        ? 'Discovery ($pendingCount)'
                                        : 'Discovery',
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => const DiscoveryScreen(),
                                ),
                              );
                            });
                          },
                        ),
                      );
                    }

                    items.add(
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text(AppLocalizations.of(context)!.settings),
                          ],
                        ),
                        onTap: () {
                          final navigator = Navigator.of(context);
                          Future.delayed(Duration.zero, () async {
                            if (!mounted) return;
                            await navigator.push(
                              MaterialPageRoute(
                                builder: (context) => SettingsScreen(
                                  onThemeChanged: widget.onThemeChanged,
                                  onLocaleChanged: widget.onLocaleChanged,
                                  currentTheme: widget.currentTheme,
                                  currentLocale: widget.currentLocale,
                                ),
                              ),
                            );
                            _loadRxTxPreference();
                          });
                        },
                      ),
                    );

                    if (profilesEnabled) {
                      items.add(
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.layers_outlined),
                              const SizedBox(width: 8),
                              Text(AppLocalizations.of(context)!.profiles),
                            ],
                          ),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            Future.delayed(Duration.zero, () {
                              if (!mounted) return;
                              navigator.push(
                                MaterialPageRoute(
                                  builder: (context) => const ProfilesScreen(),
                                ),
                              );
                            });
                          },
                        ),
                      );
                    }

                    return items;
                  },
                ),
              ],
            ),
      body: TabBarView(
        controller: _tabController,
        children: enabledTabs.map((tab) {
          switch (tab) {
            case _HomeTab.messages:
              return MessagesTab(
                isActive:
                    _currentTab == _HomeTab.messages &&
                    _lifecycleState == AppLifecycleState.resumed,
                onNavigateToMap: _isMapEnabled
                    ? () => _navigateToTab(_HomeTab.map)
                    : null,
              );
            case _HomeTab.contacts:
              return ContactsTab(
                onNavigateToMap: _isMapEnabled
                    ? () => _navigateToTab(_HomeTab.map)
                    : null,
                onNavigateToMessages: () => _navigateToTab(_HomeTab.messages),
              );
            case _HomeTab.sensors:
              return SensorsTab(
                isActive:
                    _currentTab == _HomeTab.sensors &&
                    _lifecycleState == AppLifecycleState.resumed,
              );
            case _HomeTab.map:
              return MapTab(
                key: ValueKey<String>('map:$activeProfileId'),
                onFullscreenChanged: (isFullscreen) {
                  setState(() {
                    _isMapFullscreen = isFullscreen;
                  });
                },
                onNavigateToMessages: () => _navigateToTab(_HomeTab.messages),
              );
          }
        }).toList(),
      ),
      bottomNavigationBar: shouldHideUI || !shouldShowTabBar
          ? null
          : Consumer2<MessagesProvider, ContactsProvider>(
              builder: (context, messagesProvider, contactsProvider, child) {
                final unreadCount = messagesProvider.unreadCount;
                final newContactsCount = contactsProvider.newContactsCount;

                return Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (index) {
                      final tabs = _enabledTabs;
                      if (index < 0 || index >= tabs.length) {
                        return;
                      }
                      _handleTabActivated(tabs[index]);
                    },
                    tabs: enabledTabs.map((tab) {
                      switch (tab) {
                        case _HomeTab.messages:
                          return Tab(
                            icon: _buildTabIconWithBadge(
                              Icons.message,
                              unreadCount,
                            ),
                            text: AppLocalizations.of(context)!.chat,
                          );
                        case _HomeTab.contacts:
                          return Tab(
                            icon: _buildTabIconWithBadge(
                              Icons.contacts,
                              newContactsCount,
                            ),
                            text: AppLocalizations.of(context)!.contacts,
                          );
                        case _HomeTab.map:
                          return Tab(
                            icon: Icon(Icons.map),
                            text: AppLocalizations.of(context)!.map,
                          );
                        case _HomeTab.sensors:
                          return Tab(
                            icon: const Icon(Icons.sensors),
                            text: AppLocalizations.of(context)!.sensors,
                          );
                      }
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCompactStatusBar() {
    return Consumer<ConnectionProvider>(
      builder: (context, provider, child) {
        final deviceInfo = provider.deviceInfo;
        final isConnected = deviceInfo.isConnected;
        final isTcpConnected = provider.connectionMode == ConnectionMode.tcp;

        if (!isConnected) {
          final buttonLabel = provider.isReconnecting
              ? '${provider.reconnectionAttempt}/${provider.maxReconnectionAttempts}'
              : AppLocalizations.of(context)!.connect;
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.appTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      provider.isReconnecting
                          ? AppLocalizations.of(context)!.restoringPreviousLink
                          : AppLocalizations.of(context)!.noDeviceConnected,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: provider.isReconnecting
                    ? null
                    : () => _showConnectionDialog(context),
                icon: provider.isReconnecting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white70,
                          ),
                        ),
                      )
                    : const Icon(Icons.add_link_rounded, size: 18),
                label: Text(buttonLabel),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              if (provider.isReconnecting) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => provider.cancelReconnection(),
                  icon: Icon(Icons.close, size: 20),
                  tooltip: AppLocalizations.of(context)!.cancelReconnection,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ],
            ],
          );
        }

        final theme = Theme.of(context);
        final subtitleColor = theme.colorScheme.onSurfaceVariant;
        final signalColor = isTcpConnected
            ? Colors.green
            : (deviceInfo.signalRssi != null
                  ? BatteryDisplayHelper.getSignalColor(deviceInfo.signalRssi!)
                  : Colors.grey);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isTight = constraints.maxWidth < 360;

            return Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deviceInfo.selfName ??
                                    AppLocalizations.of(context)!.appTitle,
                                style:
                                    (isTight
                                            ? theme.textTheme.titleSmall
                                            : theme.textTheme.titleMedium)
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              GestureDetector(
                                onTap: () =>
                                    _showDeviceInfoSheet(context, deviceInfo),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isTcpConnected
                                          ? Icons.wifi_rounded
                                          : Icons.bluetooth_connected_rounded,
                                      size: 13,
                                      color: signalColor,
                                    ),
                                    if (!isTcpConnected &&
                                        deviceInfo.signalRssi != null) ...[
                                      const SizedBox(width: 4),
                                      _buildMiniSignalBars(
                                        activeBars:
                                            BatteryDisplayHelper.getSignalBars(
                                              deviceInfo.signalRssi!,
                                            ),
                                        color: signalColor,
                                      ),
                                    ],
                                    if (deviceInfo.batteryPercent != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        BatteryDisplayHelper.getBatteryIcon(
                                          deviceInfo.batteryPercent!,
                                        ),
                                        size: 13,
                                        color:
                                            BatteryDisplayHelper.getBatteryColor(
                                              deviceInfo.batteryPercent!,
                                            ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${deviceInfo.batteryPercent!.round()}%',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              BatteryDisplayHelper.getBatteryColor(
                                                deviceInfo.batteryPercent!,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DeviceConfigScreen(),
                              ),
                            );
                          },
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PacketLogScreen(
                                  bleService: provider.bleService,
                                ),
                              ),
                            );
                          },
                          tooltip: AppLocalizations.of(context)!.settings,
                          icon: const Icon(Icons.tune_rounded),
                          color: subtitleColor,
                          style: IconButton.styleFrom(
                            backgroundColor: theme.colorScheme.surface,
                            foregroundColor: subtitleColor,
                            minimumSize: Size.square(isTight ? 38 : 40),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: isTight ? 8 : 12),
                if (_showRxTxIndicators)
                  GestureDetector(
                    onTap: () => _openLiveTraffic(provider),
                    onLongPress: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PacketLogScreen(bleService: provider.bleService),
                        ),
                      );
                    },
                    child: _buildCompactActivityIndicator(
                      rxActive: provider.rxActivity,
                      txActive: provider.txActivity,
                    ),
                  )
                else
                  const SizedBox(width: 24),
              ],
            );
          },
        );
      },
    );
  }

  /// Build tab icon with badge showing count
  Widget _buildTabIconWithBadge(IconData icon, int count) {
    if (count == 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -8,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
