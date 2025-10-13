import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/connection_provider.dart';
import 'providers/contacts_provider.dart';
import 'providers/messages_provider.dart';
import 'providers/map_provider.dart';
import 'providers/app_provider.dart';
import 'services/tile_cache_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MeshCoreSarApp());
}

class MeshCoreSarApp extends StatefulWidget {
  const MeshCoreSarApp({super.key});

  @override
  State<MeshCoreSarApp> createState() => _MeshCoreSarAppState();
}

class _MeshCoreSarAppState extends State<MeshCoreSarApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('theme_mode') ?? 'system';
    setState(() {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.name == themeName,
        orElse: () => ThemeMode.system,
      );
    });
  }

  void _handleThemeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => MessagesProvider()),
        ChangeNotifierProvider(create: (_) => MapProvider()),

        // Tile cache service
        Provider(create: (_) => TileCacheService()),

        // App provider that coordinates everything
        ChangeNotifierProxyProvider4<ConnectionProvider, ContactsProvider,
            MessagesProvider, TileCacheService, AppProvider>(
          create: (context) => AppProvider(
            connectionProvider: context.read<ConnectionProvider>(),
            contactsProvider: context.read<ContactsProvider>(),
            messagesProvider: context.read<MessagesProvider>(),
            tileCacheService: context.read<TileCacheService>(),
          ),
          update: (context, conn, contacts, messages, tileCache, previous) =>
              previous ??
              AppProvider(
                connectionProvider: conn,
                contactsProvider: contacts,
                messagesProvider: messages,
                tileCacheService: tileCache,
              ),
        ),
      ],
      child: MaterialApp(
        title: 'MeshCore SAR',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
        ),
        themeMode: _themeMode,
        home: HomeScreen(onThemeChanged: _handleThemeChanged, currentTheme: _themeMode),
      ),
    );
  }
}
