import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'providers/connection_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/map_provider.dart';
import 'providers/drawing_provider.dart';
import 'providers/channels_provider.dart';
import 'providers/app_provider.dart';
import 'services/tile_cache_service.dart';
import 'services/notification_service.dart';
import 'services/locale_preferences.dart';
import 'services/update_checker_service.dart';
import 'services/wizard_preferences.dart';
import 'widgets/update_dialog.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_wizard_screen.dart';
import 'theme/app_theme.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const MeshCoreSarApp());
}

class MeshCoreSarApp extends StatefulWidget {
  const MeshCoreSarApp({super.key});

  @override
  State<MeshCoreSarApp> createState() => _MeshCoreSarAppState();
}

class _MeshCoreSarAppState extends State<MeshCoreSarApp> {
  AppThemeMode _themeMode = AppThemeMode.system;
  Locale? _locale;
  bool _isInitialized = false;
  bool _shouldShowPermissionDialog = false;
  bool _wizardCompleted = true; // Will be updated in _initializeApp()

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadThemePreference();
    await _loadLocalePreference();

    // Check if welcome wizard has been completed
    final wizardCompleted = await WizardPreferences.isWizardCompleted();

    // Initialize notification service
    await NotificationService().initialize();

    // Check if we need to request location permissions
    await _checkLocationPermissions();

    // Check for app updates (Android only) - runs in background
    // Shows dialog if update is available
    _checkForUpdates();

    setState(() {
      _wizardCompleted = wizardCompleted;
      _isInitialized = true;
    });
  }

  Future<void> _checkLocationPermissions() async {
    try {
      final permission = await Geolocator.checkPermission();

      // Show dialog if permission is denied or not determined
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _shouldShowPermissionDialog = true;
      }
    } catch (e) {
      debugPrint('Error checking location permissions: $e');
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = AppTheme.themeFromString(themeName);
    });
  }

  Future<void> _loadLocalePreference() async {
    final locale = await LocalePreferences.getLocale();
    setState(() {
      _locale = locale;
    });
  }

  void _handleThemeChanged(AppThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  void _handleLocaleChanged(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _handleWizardCompleted() {
    setState(() {
      _wizardCompleted = true;
    });
  }

  /// Check for app updates on Android only
  /// Shows dialog if update is available
  Future<void> _checkForUpdates() async {
    // Only check for updates on Android
    if (!Platform.isAndroid) {
      debugPrint('[UpdateChecker] Skipping update check (not Android)');
      return;
    }

    try {
      debugPrint('[UpdateChecker] Starting update check...');
      final updateInfo = await UpdateCheckerService().checkForUpdate();

      if (!updateInfo.isAvailable) {
        debugPrint('[UpdateChecker] No update available');
        return;
      }

      debugPrint('[UpdateChecker] Update available! Showing dialog...');

      // Wait for widget tree to be built before showing dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          UpdateDialog.show(context, updateInfo);
        }
      });
    } catch (e) {
      debugPrint('[UpdateChecker] Error checking for updates: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(
          create: (_) {
            // Initialize early to load persisted contacts for offline viewing
            // Self-contact filtering will happen later when BLE connects
            final provider = ContactsProvider();
            provider.initializeEarly();
            return provider;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final provider = MessagesProvider();
            // Initialize messages provider asynchronously
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => MapProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final provider = DrawingProvider();
            // Initialize drawing provider asynchronously
            provider.initialize();
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => ChannelsProvider()),

        // Tile cache service
        Provider(create: (_) => TileCacheService()),

        // App provider that coordinates everything
        ChangeNotifierProxyProvider6<ConnectionProvider, ContactsProvider,
            MessagesProvider, DrawingProvider, ChannelsProvider, TileCacheService, AppProvider>(
          create: (context) => AppProvider(
            connectionProvider: context.read<ConnectionProvider>(),
            contactsProvider: context.read<ContactsProvider>(),
            messagesProvider: context.read<MessagesProvider>(),
            drawingProvider: context.read<DrawingProvider>(),
            channelsProvider: context.read<ChannelsProvider>(),
            tileCacheService: context.read<TileCacheService>(),
          ),
          update: (context, conn, contacts, messages, drawings, channels, tileCache, previous) =>
              previous ??
              AppProvider(
                connectionProvider: conn,
                contactsProvider: contacts,
                messagesProvider: messages,
                drawingProvider: drawings,
                channelsProvider: channels,
                tileCacheService: tileCache,
              ),
        ),
      ],
      child: _buildMaterialApp(),
    );
  }

  Widget _buildMaterialApp() {
    return Builder(
      builder: (context) {
        final systemBrightness = MediaQuery.platformBrightnessOf(context);
        return MaterialApp(
          key: ValueKey<String?>('${_locale?.languageCode ?? 'system'}_${_themeMode.name}'),
          title: 'MeshCore SAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(_themeMode, systemBrightness),
          locale: _locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: LocalePreferences.supportedLocales,
          home: _wizardCompleted
              ? HomeScreen(
                  onThemeChanged: _handleThemeChanged,
                  onLocaleChanged: _handleLocaleChanged,
                  currentTheme: _themeMode,
                  currentLocale: _locale,
                  shouldShowPermissionDialog: _shouldShowPermissionDialog,
                )
              : WelcomeWizardScreen(
                  onCompleted: _handleWizardCompleted,
                ),
        );
      },
    );
  }
}
