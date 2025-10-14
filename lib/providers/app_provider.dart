import 'package:flutter/foundation.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';
import 'messages_provider.dart';
import '../services/tile_cache_service.dart';

/// Main App Provider - coordinates all other providers
class AppProvider with ChangeNotifier {
  final ConnectionProvider connectionProvider;
  final ContactsProvider contactsProvider;
  final MessagesProvider messagesProvider;
  final TileCacheService tileCacheService;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppProvider({
    required this.connectionProvider,
    required this.contactsProvider,
    required this.messagesProvider,
    required this.tileCacheService,
  }) {
    _setupCallbacks();
    _initializeTileCache();
    _isInitialized = true;
  }

  /// Initialize tile cache service
  Future<void> _initializeTileCache() async {
    try {
      await tileCacheService.initialize();
      debugPrint('Tile cache initialized');
    } catch (e) {
      debugPrint('Error initializing tile cache: $e');
    }
  }

  /// Setup callbacks between providers
  void _setupCallbacks() {
    // When a contact is received from BLE
    connectionProvider.onContactReceived = (contact) {
      contactsProvider.addOrUpdateContact(contact);
    };

    // When all contacts are received
    connectionProvider.onContactsComplete = (contacts) {
      contactsProvider.addContacts(contacts);
      debugPrint('Received ${contacts.length} contacts');
    };

    // When a message is received
    connectionProvider.onMessageReceived = (message) {
      messagesProvider.addMessage(message);

      // Optionally update sender name from contacts
      if (message.senderPublicKeyPrefix != null) {
        final contact = contactsProvider
            .findContactByKey(message.senderPublicKeyPrefix!);
        if (contact != null) {
          final updatedMessage = message.copyWith(senderName: contact.advName);
          // Note: You might want to update the message in the list
        }
      }
    };

    // When telemetry is received
    connectionProvider.onTelemetryReceived = (publicKey, lppData) {
      contactsProvider.updateTelemetry(publicKey, lppData);
    };
  }

  /// Initialize the app (load contacts, sync time, etc.)
  Future<void> initialize() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      // Sync device time
      await connectionProvider.syncDeviceTime();

      // Load contacts
      await connectionProvider.getContacts();

      // Sync any waiting messages from device queue
      await _syncMessages();

      notifyListeners();
    } catch (e) {
      debugPrint('Initialization error: $e');
    }
  }

  /// Sync messages from device queue
  Future<void> _syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      debugPrint('🔄 [AppProvider] Starting message sync...');
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint('✅ [AppProvider] Synced $messageCount messages');
    } catch (e) {
      debugPrint('❌ [AppProvider] Message sync error: $e');
    }
  }

  /// Refresh data (contacts, messages)
  Future<void> refresh() async {
    if (!connectionProvider.deviceInfo.isConnected) return;

    try {
      await connectionProvider.getContacts();
      await _syncMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  /// Manually sync messages (useful for pull-to-refresh)
  Future<int> syncMessages() async {
    if (!connectionProvider.deviceInfo.isConnected) return 0;

    try {
      debugPrint('🔄 [AppProvider] Manual message sync requested');
      final messageCount = await connectionProvider.syncAllMessages();
      debugPrint('✅ [AppProvider] Synced $messageCount messages');
      notifyListeners();
      return messageCount;
    } catch (e) {
      debugPrint('❌ [AppProvider] Message sync error: $e');
      return 0;
    }
  }

  /// Clear all data
  void clearAllData() {
    contactsProvider.clearContacts();
    messagesProvider.clearAll();
    notifyListeners();
  }

  /// Get app statistics
  Map<String, dynamic> get statistics {
    return {
      'connection': {
        'isConnected': connectionProvider.deviceInfo.isConnected,
        'deviceName': connectionProvider.deviceInfo.deviceName,
        'battery': connectionProvider.deviceInfo.batteryPercent,
      },
      'contacts': contactsProvider.contactCounts,
      'messages': messagesProvider.messageStats,
      'sarMarkers': messagesProvider.sarMarkerStats,
    };
  }
}
