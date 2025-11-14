import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as io_client;
import '../models/message.dart';
import '../models/contact.dart';
import 'package:latlong2/latlong.dart';

/// SSE Client Service
///
/// Connects to a remote SSE server to receive messages and contacts in real-time.
/// This enables multiple app instances to share a single MeshCore BLE device
/// without direct BLE connections.
class SseClientService {
  String? _serverUrl;
  String? _authToken;
  http.Client? _httpClient;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _contactSubscription;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _hasConnectedBefore = false; // Track if we've ever successfully connected
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  /// Callback for when a message is received
  Function(Message)? onMessageReceived;

  /// Callback for when a contact is received
  Function(Contact)? onContactReceived;

  /// Callback for connection state changes
  Function(bool isConnected)? onConnectionStateChanged;

  /// Callback for errors
  Function(String error)? onError;

  /// Check if client is connected
  bool get isConnected => _isConnected;

  /// Check if client is currently connecting
  bool get isConnecting => _isConnecting;

  /// Get current reconnection attempt number
  int get reconnectionAttempts => _reconnectAttempts;

  /// Get maximum reconnection attempts
  int get maxReconnectionAttempts => _maxReconnectAttempts;

  /// Get server URL
  String? get serverUrl => _serverUrl;

  /// Connect to SSE server
  Future<void> connect({
    required String serverUrl,
    String? authToken,
  }) async {
    if (_isConnected) {
      debugPrint('⚠️ [SseClient] Already connected');
      return;
    }

    _serverUrl = serverUrl;
    _authToken = authToken;
    _isConnecting = true;

    debugPrint('🔌 [SseClient] Connecting to $serverUrl (attempt ${_reconnectAttempts + 1}/$_maxReconnectAttempts)');

    try {
      // Create a new HTTP client with custom configuration for SSE streaming
      // Using IOClient with custom HttpClient for better control over connection settings
      final ioHttpClient = io.HttpClient();
      ioHttpClient.connectionTimeout = const Duration(seconds: 10);
      ioHttpClient.idleTimeout = const Duration(hours: 1); // Keep SSE connections alive
      _httpClient = io_client.IOClient(ioHttpClient);

      // Test server availability
      await _checkServerStatus();

      // Fetch initial message history
      await _fetchMessageHistory();

      // Fetch initial contact list
      await _fetchContacts();

      // Subscribe to SSE streams
      debugPrint('🔗 [SseClient] Subscribing to message stream...');
      debugPrint('🔗 [SseClient] Using HTTP client type: ${_httpClient.runtimeType}');
      await _subscribeToMessages();
      debugPrint('🔗 [SseClient] Subscribing to contact stream...');
      await _subscribeToContacts();
      debugPrint('🔗 [SseClient] All subscriptions complete');

      _isConnected = true;
      _isConnecting = false;
      _hasConnectedBefore = true; // Mark that we've successfully connected
      _reconnectAttempts = 0;
      debugPrint('🔔 [SseClient] Calling onConnectionStateChanged(true)');
      onConnectionStateChanged?.call(true);

      // Start heartbeat to detect connection loss
      _startHeartbeat();

      debugPrint('✅ [SseClient] Connected successfully');
    } catch (e) {
      _isConnecting = false;
      _httpClient?.close();
      _httpClient = null;
      debugPrint('❌ [SseClient] Connection failed: $e');
      onError?.call('Connection failed: $e');

      // Only auto-reconnect if we've successfully connected before
      // Initial connection failures should be handled by the user
      if (_hasConnectedBefore) {
        _scheduleReconnect();
      }
    }
  }

  /// Disconnect from SSE server
  Future<void> disconnect() async {
    debugPrint('🔌 [SseClient] Disconnecting...');

    _isConnected = false;
    _isConnecting = false;
    _hasConnectedBefore = false; // Reset on manual disconnect
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    await _messageSubscription?.cancel();
    await _contactSubscription?.cancel();
    _httpClient?.close();

    _serverUrl = null;
    _authToken = null;
    _httpClient = null;

    onConnectionStateChanged?.call(false);

    debugPrint('✅ [SseClient] Disconnected');
  }

  /// Check server status
  Future<void> _checkServerStatus() async {
    final url = Uri.parse('$_serverUrl/api/status');

    try {
      final response = await http.get(url, headers: _getHeaders()).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      debugPrint('📊 [SseClient] Server status: ${data['status']}');
      debugPrint('   Connected clients: ${data['connectedClients']}');
      debugPrint('   Messages: ${data['messageCount']}');
      debugPrint('   Contacts: ${data['contactCount']}');
    } catch (e) {
      // Wrap the error with more user-friendly message
      throw Exception(_formatConnectionError(e));
    }
  }

  /// Format connection error to be more user-friendly
  String _formatConnectionError(dynamic error) {
    final errorStr = error.toString();

    // Extract the actual server URL being connected to
    final serverUri = Uri.tryParse(_serverUrl ?? '');
    final host = serverUri?.host ?? 'unknown';
    final port = serverUri?.port ?? 0;

    if (errorStr.contains('Connection refused')) {
      return 'Server not available at $host:$port. The server may be offline or not running.';
    } else if (errorStr.contains('TimeoutException') || errorStr.contains('timed out')) {
      return 'Connection to $host:$port timed out. Check your network connection.';
    } else if (errorStr.contains('SocketException')) {
      return 'Network error connecting to $host:$port. Check your network connection.';
    } else if (errorStr.contains('Failed host lookup')) {
      return 'Could not resolve hostname: $host';
    }

    // Return the original error if we can't make it more user-friendly
    return errorStr;
  }

  /// Fetch message history on connect
  Future<void> _fetchMessageHistory() async {
    try {
      final url = Uri.parse('$_serverUrl/api/messages/history');
      final response = await http.get(url, headers: _getHeaders()).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch message history: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final messages = data['messages'] as List;

      debugPrint('📥 [SseClient] Received ${messages.length} messages from history');

      for (final msgJson in messages) {
        try {
          final message = _messageFromJson(msgJson);
          onMessageReceived?.call(message);
        } catch (e) {
          debugPrint('⚠️ [SseClient] Failed to parse message: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [SseClient] Error fetching message history: $e');
      // Don't throw - continue with connection even if history fetch fails
    }
  }

  /// Fetch contacts on connect
  Future<void> _fetchContacts() async {
    try {
      final url = Uri.parse('$_serverUrl/api/contacts');
      final response = await http.get(url, headers: _getHeaders()).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch contacts: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final contacts = data['contacts'] as List;

      debugPrint('📥 [SseClient] Received ${contacts.length} contacts');

      for (final contactJson in contacts) {
        try {
          final contact = _contactFromJson(contactJson);
          onContactReceived?.call(contact);
        } catch (e) {
          debugPrint('⚠️ [SseClient] Failed to parse contact: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ [SseClient] Error fetching contacts: $e');
      // Don't throw - continue with connection even if contacts fetch fails
    }
  }

  /// Subscribe to SSE message stream
  Future<void> _subscribeToMessages() async {
    try {
      if (_httpClient == null) {
        throw Exception('HTTP client not initialized');
      }

      debugPrint('📡 [SseClient] Creating message stream request...');
      final url = Uri.parse('$_serverUrl/sse/messages');
      final request = http.Request('GET', url);
      request.headers.addAll(_getHeaders());
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      debugPrint('📡 [SseClient] Sending message stream request to $url');
      debugPrint('📡 [SseClient] Request headers: ${request.headers}');

      final streamedResponse = await _httpClient!.send(request).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('❌ [SseClient] Timeout waiting for response headers');
          throw TimeoutException('Message stream connection timed out after 10 seconds');
        },
      );

      debugPrint('📡 [SseClient] Received response with status: ${streamedResponse.statusCode}');
      debugPrint('📡 [SseClient] Response headers: ${streamedResponse.headers}');
      debugPrint('📡 [SseClient] Response content length: ${streamedResponse.contentLength}');
      debugPrint('📡 [SseClient] Response is redirect: ${streamedResponse.isRedirect}');

      if (streamedResponse.statusCode != 200) {
        throw Exception('SSE messages subscription failed: ${streamedResponse.statusCode}');
      }

      debugPrint('📡 [SseClient] Message stream response received, status: ${streamedResponse.statusCode}');
      debugPrint('📡 [SseClient] Setting up stream listener...');

      _messageSubscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          debugPrint('📨 [SseClient] Received line: "$line"');
          _handleSseLine(line, 'message');
        },
        onError: (error, stackTrace) {
          debugPrint('❌ [SseClient] Message stream error: $error');
          debugPrint('   Stack trace: $stackTrace');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('⚠️ [SseClient] Message stream closed (onDone called)');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      debugPrint('✅ [SseClient] Message stream listener set up successfully');
    } catch (e) {
      debugPrint('❌ [SseClient] Error subscribing to message stream: $e');
      rethrow;
    }
  }

  /// Subscribe to SSE contact stream
  Future<void> _subscribeToContacts() async {
    try {
      if (_httpClient == null) {
        throw Exception('HTTP client not initialized');
      }

      debugPrint('📡 [SseClient] Creating contact stream request...');
      final url = Uri.parse('$_serverUrl/sse/contacts');
      final request = http.Request('GET', url);
      request.headers.addAll(_getHeaders());
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      debugPrint('📡 [SseClient] Sending contact stream request to $url');
      final streamedResponse = await _httpClient!.send(request).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Contact stream connection timed out after 10 seconds');
        },
      );

      if (streamedResponse.statusCode != 200) {
        throw Exception('SSE contacts subscription failed: ${streamedResponse.statusCode}');
      }

      debugPrint('📡 [SseClient] Contact stream response received, status: ${streamedResponse.statusCode}');
      debugPrint('📡 [SseClient] Setting up contact stream listener...');

      _contactSubscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          debugPrint('📨 [SseClient] Received contact line: "$line"');
          _handleSseLine(line, 'contact');
        },
        onError: (error, stackTrace) {
          debugPrint('❌ [SseClient] Contact stream error: $error');
          debugPrint('   Stack trace: $stackTrace');
          _handleDisconnect();
        },
        onDone: () {
          debugPrint('⚠️ [SseClient] Contact stream closed (onDone called)');
          _handleDisconnect();
        },
        cancelOnError: false,
      );

      debugPrint('✅ [SseClient] Contact stream listener set up successfully');
    } catch (e) {
      debugPrint('❌ [SseClient] Error subscribing to contact stream: $e');
      rethrow;
    }
  }

  /// Handle SSE line
  String _eventType = '';
  void _handleSseLine(String line, String streamType) {
    if (line.isEmpty) {
      // Event complete, reset
      _eventType = '';
      return;
    }

    if (line.startsWith('event:')) {
      _eventType = line.substring(6).trim();
    } else if (line.startsWith('data:')) {
      final jsonData = line.substring(5).trim();
      try {
        final data = jsonDecode(jsonData) as Map<String, dynamic>;

        if (streamType == 'message' && _eventType == 'message') {
          final message = _messageFromJson(data);
          onMessageReceived?.call(message);
        } else if (streamType == 'contact' && _eventType == 'contact') {
          final contact = _contactFromJson(data);
          onContactReceived?.call(contact);
        }
      } catch (e) {
        debugPrint('⚠️ [SseClient] Failed to parse SSE data: $e');
      }
    }
  }

  /// Handle disconnect
  void _handleDisconnect() {
    if (!_isConnected) return;

    _isConnected = false;
    onConnectionStateChanged?.call(false);

    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('❌ [SseClient] Max reconnection attempts reached');
      onError?.call('Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;

    debugPrint('🔄 [SseClient] Scheduling reconnect attempt $_reconnectAttempts in ${delay.inSeconds}s');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_serverUrl != null) {
        connect(serverUrl: _serverUrl!, authToken: _authToken);
      }
    });
  }

  /// Start heartbeat to detect connection loss
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        await _checkServerStatus();
      } catch (e) {
        debugPrint('⚠️ [SseClient] Heartbeat failed: $e');
        _handleDisconnect();
      }
    });
  }

  /// Send message to server
  Future<bool> sendMessage({
    required String recipientPublicKey,
    required String text,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Not connected to server');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/messages');
      final response = await http.post(
        url,
        headers: {
          ..._getHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'recipientPublicKey': recipientPublicKey,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Send message failed: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['success'] as bool? ?? false;
    } catch (e) {
      debugPrint('❌ [SseClient] Error sending message: $e');
      rethrow;
    }
  }

  /// Send channel message to server
  Future<void> sendChannelMessage({
    required int channelIdx,
    required String text,
  }) async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Not connected to server');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/messages/channel');
      final response = await http.post(
        url,
        headers: {
          ..._getHeaders(),
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'channelIdx': channelIdx,
          'text': text,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Send channel message failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [SseClient] Error sending channel message: $e');
      rethrow;
    }
  }

  /// Request contact sync
  Future<void> syncContacts() async {
    if (!_isConnected || _serverUrl == null) {
      throw Exception('Not connected to server');
    }

    try {
      final url = Uri.parse('$_serverUrl/api/contacts/sync');
      final response = await http.post(
        url,
        headers: _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Contact sync failed: ${response.statusCode}');
      }

      debugPrint('✅ [SseClient] Contact sync requested');
    } catch (e) {
      debugPrint('❌ [SseClient] Error syncing contacts: $e');
      rethrow;
    }
  }

  /// Get headers for HTTP requests
  Map<String, String> _getHeaders() {
    final headers = <String, String>{};
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  /// Convert JSON to Message
  Message _messageFromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      messageType: MessageType.values.firstWhere(
        (e) => e.name == json['messageType'],
        orElse: () => MessageType.contact,
      ),
      senderPublicKeyPrefix: json['senderPublicKeyPrefix'] != null
          ? Uint8List.fromList((json['senderPublicKeyPrefix'] as List).cast<int>())
          : null,
      channelIdx: json['channelIdx'] as int?,
      pathLen: json['pathLen'] as int,
      textType: MessageTextType.fromValue(json['textType'] as int),
      senderTimestamp: json['senderTimestamp'] as int,
      text: json['text'] as String,
      isSarMarker: json['isSarMarker'] as bool? ?? false,
      sarGpsCoordinates: json['sarGpsCoordinates'] != null
          ? LatLng(
              (json['sarGpsCoordinates']['latitude'] as num).toDouble(),
              (json['sarGpsCoordinates']['longitude'] as num).toDouble(),
            )
          : null,
      sarNotes: json['sarNotes'] as String?,
      sarCustomEmoji: json['sarCustomEmoji'] as String?,
      sarColorIndex: json['sarColorIndex'] as int?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      senderName: json['senderName'] as String?,
      deliveryStatus: MessageDeliveryStatus.values.firstWhere(
        (e) => e.name == json['deliveryStatus'],
        orElse: () => MessageDeliveryStatus.received,
      ),
      expectedAckTag: json['expectedAckTag'] as int?,
      suggestedTimeoutMs: json['suggestedTimeoutMs'] as int?,
      roundTripTimeMs: json['roundTripTimeMs'] as int?,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      recipientPublicKey: json['recipientPublicKey'] != null
          ? Uint8List.fromList((json['recipientPublicKey'] as List).cast<int>())
          : null,
      retryAttempt: json['retryAttempt'] as int? ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'] as String)
          : null,
      usedFloodFallback: json['usedFloodFallback'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      echoCount: json['echoCount'] as int? ?? 0,
      firstEchoAt: json['firstEchoAt'] != null
          ? DateTime.parse(json['firstEchoAt'] as String)
          : null,
      isDrawing: json['isDrawing'] as bool? ?? false,
      drawingId: json['drawingId'] as String?,
    );
  }

  /// Convert JSON to Contact
  Contact _contactFromJson(Map<String, dynamic> json) {
    return Contact(
      publicKey: Uint8List.fromList((json['publicKey'] as List).cast<int>()),
      type: ContactType.fromValue(json['type'] as int),
      flags: json['flags'] as int,
      outPathLen: json['outPathLen'] as int,
      outPath: Uint8List.fromList((json['outPath'] as List).cast<int>()),
      advName: json['advName'] as String,
      lastAdvert: json['lastAdvert'] as int,
      advLat: json['advLat'] as int,
      advLon: json['advLon'] as int,
      lastMod: json['lastMod'] as int,
    );
  }

  /// Dispose resources
  void dispose() {
    disconnect();
  }
}
