import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/connection_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/map_provider.dart';
import 'providers/drawing_provider.dart';
import 'providers/app_provider.dart';
import 'services/tile_cache_service.dart';
import 'services/locale_preferences.dart';
import 'screens/home_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadThemePreference();
    await _loadLocalePreference();
    setState(() {
      _isInitialized = true;
    });
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
            // Don't initialize here - it will be initialized in AppProvider.initialize()
            // after connection is established and device info is available
            return ContactsProvider();
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

        // Tile cache service
        Provider(create: (_) => TileCacheService()),

        // App provider that coordinates everything
        ChangeNotifierProxyProvider5<ConnectionProvider, ContactsProvider,
            MessagesProvider, DrawingProvider, TileCacheService, AppProvider>(
          create: (context) => AppProvider(
            connectionProvider: context.read<ConnectionProvider>(),
            contactsProvider: context.read<ContactsProvider>(),
            messagesProvider: context.read<MessagesProvider>(),
            drawingProvider: context.read<DrawingProvider>(),
            tileCacheService: context.read<TileCacheService>(),
          ),
          update: (context, conn, contacts, messages, drawings, tileCache, previous) =>
              previous ??
              AppProvider(
                connectionProvider: conn,
                contactsProvider: contacts,
                messagesProvider: messages,
                drawingProvider: drawings,
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
          home: HomeScreen(
            onThemeChanged: _handleThemeChanged,
            onLocaleChanged: _handleLocaleChanged,
            currentTheme: _themeMode,
            currentLocale: _locale,
          ),
        );
      },
    );
  }
}
