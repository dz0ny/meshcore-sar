import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:nsd/nsd.dart';
import '../models/message.dart';
import '../models/contact.dart';
import '../models/sse_server_config.dart';
import 'network_scanner_service.dart';

/// SSE Server Service
///
/// Provides a web server with SSE (Server-Sent Events) endpoints for
/// real-time message and contact updates, enabling multiple app instances
/// to share a single MeshCore BLE device.
///
/// Endpoints:
/// - GET /sse/messages - SSE stream for message updates
/// - GET /sse/contacts - SSE stream for contact updates
/// - POST /api/messages - Send message
/// - POST /api/messages/channel - Send channel message
/// - POST /api/contacts/sync - Trigger contact sync
/// - GET /api/messages/history - Get all messages
/// - GET /api/contacts - Get all contacts
/// - GET /api/status - Server health check
class SseServerService {
  HttpServer? _server;
  SseServerConfig? _config;
  Registration? _bonjourRegistration;

  /// Active SSE connections for messages
  final Set<StreamController<String>> _messageStreams = {};

  /// Active SSE connections for contacts
  final Set<StreamController<String>> _contactStreams = {};

  /// Message history (for new clients)
  final List<Message> _messageHistory = [];

  /// Contact list (for new clients)
  final Map<String, Contact> _contacts = {};

  /// Timer for cleaning up dead connections
  Timer? _cleanupTimer;

  /// Device name (for status endpoint)
  String? _deviceName;

  /// Set device name
  void setDeviceName(String? name) {
    _deviceName = name;
    debugPrint('📝 [SseServer] Device name set to: $name');
  }

  /// Callback for when a client requests to send a message
  Future<bool> Function(String recipientPublicKey, String text)? onSendMessage;

  /// Callback for when a client requests to send a channel message
  Future<void> Function(int channelIdx, String text)? onSendChannelMessage;

  /// Callback for when a client requests contact sync
  Future<void> Function()? onSyncContacts;

  /// Check if server is running
  bool get isRunning => _server != null;

  /// Get current configuration
  SseServerConfig? get config => _config;

  /// Get number of connected clients
  int get connectedClients => _messageStreams.length;

  /// CORS middleware
  static shelf.Middleware get _corsHeaders {
    return shelf.createMiddleware(
      responseHandler: (shelf.Response response) {
        return response.change(headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
        });
      },
    );
  }

  /// Start the SSE server
  Future<void> startServer(SseServerConfig config) async {
    if (_server != null) {
      debugPrint('⚠️ [SseServer] Server already running');
      return;
    }

    _config = config;

    try {
      debugPrint('🚀 [SseServer] Starting server on ${config.host}:${config.port}');

      // Create shelf handler with CORS support
      final handler = const shelf.Pipeline()
          .addMiddleware(_corsHeaders)
          .addMiddleware(shelf.logRequests())
          .addHandler(_handleRequest);

      // Start HTTP server
      _server = await io.serve(
        handler,
        config.host,
        config.port,
      );

      debugPrint('✅ [SseServer] Server started on ${config.getServerUrl()}');

      // Start cleanup timer for dead connections
      _startCleanupTimer();

      // Register Bonjour/mDNS service
      await _registerBonjourService(config);
    } catch (e) {
      debugPrint('❌ [SseServer] Failed to start server: $e');
      _server = null;
      rethrow;
    }
  }

  /// Register Bonjour/mDNS service for network discovery
  Future<void> _registerBonjourService(SseServerConfig config) async {
    try {
      debugPrint('📡 [SseServer] Registering Bonjour service ${NetworkScannerService.serviceType}...');

      _bonjourRegistration = await register(
        const Service(
          name: 'MeshCore SSE Server',
          type: NetworkScannerService.serviceType,
          port: 0, // Will be set dynamically
        ),
      );

      // Update with actual port
      if (_bonjourRegistration != null) {
        // Unregister and re-register with correct port
        await unregister(_bonjourRegistration!);
        _bonjourRegistration = await register(
          Service(
            name: 'MeshCore SSE Server',
            type: NetworkScannerService.serviceType,
            port: config.port,
          ),
        );
        debugPrint('✅ [SseServer] Bonjour service registered on port ${config.port}');
      }
    } catch (e) {
      debugPrint('⚠️ [SseServer] Failed to register Bonjour service: $e');
      // Don't throw - server can still work without Bonjour
    }
  }

  /// Start cleanup timer to remove dead connections
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _cleanupDeadConnections();
    });
    debugPrint('🧹 [SseServer] Cleanup timer started (60s interval)');
  }

  /// Clean up dead/closed connections
  void _cleanupDeadConnections() {
    // Clean up message streams
    final deadMessageStreams = _messageStreams.where((s) => s.isClosed).toList();
    for (final stream in deadMessageStreams) {
      _messageStreams.remove(stream);
    }

    // Clean up contact streams
    final deadContactStreams = _contactStreams.where((s) => s.isClosed).toList();
    for (final stream in deadContactStreams) {
      _contactStreams.remove(stream);
    }

    if (deadMessageStreams.isNotEmpty || deadContactStreams.isNotEmpty) {
      debugPrint('🧹 [SseServer] Cleaned up ${deadMessageStreams.length} dead message streams, ${deadContactStreams.length} dead contact streams');
      debugPrint('   Active: ${_messageStreams.length} message clients, ${_contactStreams.length} contact clients');
    }
  }

  /// Stop the SSE server
  Future<void> stopServer() async {
    if (_server == null) {
      return;
    }

    debugPrint('🛑 [SseServer] Stopping server...');

    // Stop cleanup timer
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    // Close all SSE streams
    for (final stream in _messageStreams) {
      await stream.close();
    }
    _messageStreams.clear();

    for (final stream in _contactStreams) {
      await stream.close();
    }
    _contactStreams.clear();

    // Unregister Bonjour service
    if (_bonjourRegistration != null) {
      try {
        await unregister(_bonjourRegistration!);
        debugPrint('✅ [SseServer] Bonjour service unregistered');
      } catch (e) {
        debugPrint('⚠️ [SseServer] Failed to unregister Bonjour service: $e');
      }
      _bonjourRegistration = null;
    }

    // Close HTTP server
    await _server!.close(force: true);
    _server = null;
    _config = null;

    debugPrint('✅ [SseServer] Server stopped');
  }

  /// Main request handler
  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    // Check authentication if token is configured
    if (_config?.authToken != null) {
      final authHeader = request.headers['authorization'];
      if (authHeader != 'Bearer ${_config!.authToken}') {
        return shelf.Response.forbidden('Invalid authentication token');
      }
    }

    final path = request.url.path;
    final method = request.method;

    debugPrint('📨 [SseServer] $method /$path');

    // Route requests
    if (method == 'GET' && path == 'sse/messages') {
      return _handleSseMessages(request);
    } else if (method == 'GET' && path == 'sse/contacts') {
      return _handleSseContacts(request);
    } else if (method == 'POST' && path == 'api/messages') {
      return _handlePostMessage(request);
    } else if (method == 'POST' && path == 'api/messages/channel') {
      return _handlePostChannelMessage(request);
    } else if (method == 'POST' && path == 'api/contacts/sync') {
      return _handlePostContactsSync(request);
    } else if (method == 'GET' && path == 'api/messages/history') {
      return _handleGetMessageHistory(request);
    } else if (method == 'GET' && path == 'api/contacts') {
      return _handleGetContacts(request);
    } else if (method == 'GET' && path == 'api/status') {
      return _handleGetStatus(request);
    } else if (method == 'GET' && path == '') {
      return _handleRoot(request);
    }

    return shelf.Response.notFound('Not found');
  }

  /// Handle SSE messages stream
  shelf.Response _handleSseMessages(shelf.Request request) {
    return request.hijack((channel) async {
      debugPrint('📥 [SseServer] New SSE client connected (messages) via hijack');

      // Set up the sink for sending data
      final sink = utf8.encoder.startChunkedConversion(channel.sink);

      // Send SSE headers
      sink.add('HTTP/1.1 200 OK\r\n');
      sink.add('Content-Type: text/event-stream\r\n');
      sink.add('Cache-Control: no-cache\r\n');
      sink.add('Connection: keep-alive\r\n');
      sink.add('\r\n');

      // Create controller for this connection
      final controller = StreamController<String>();
      _messageStreams.add(controller);

      debugPrint('   Total clients: ${_messageStreams.length}');

      // Send initial connection event
      sink.add(': connected\n\n');

      // Send initial message history
      for (final message in _messageHistory) {
        final event = _formatSseEvent('message', _messageToJson(message));
        sink.add(event);
      }

      // Start keep-alive timer
      final keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        try {
          sink.add(': keepalive\n\n');
        } catch (e) {
          debugPrint('⚠️ [SseServer] Keep-alive failed: $e');
          timer.cancel();
        }
      });

      // Listen to controller for new messages to broadcast
      final subscription = controller.stream.listen(
        (data) {
          try {
            sink.add(data);
          } catch (e) {
            debugPrint('⚠️ [SseServer] Failed to send data: $e');
          }
        },
        onDone: () {
          debugPrint('📤 [SseServer] Controller stream closed');
        },
      );

      // Wait for channel to close
      await channel.stream.drain();

      // Cleanup
      keepAliveTimer.cancel();
      await subscription.cancel();
      _messageStreams.remove(controller);
      await controller.close();

      debugPrint('📤 [SseServer] SSE client disconnected (messages)');
      debugPrint('   Total clients: ${_messageStreams.length}');
    });
  }

  /// Handle SSE contacts stream
  shelf.Response _handleSseContacts(shelf.Request request) {
    return request.hijack((channel) async {
      debugPrint('📥 [SseServer] New SSE client connected (contacts) via hijack');

      // Set up the sink for sending data
      final sink = utf8.encoder.startChunkedConversion(channel.sink);

      // Send SSE headers
      sink.add('HTTP/1.1 200 OK\r\n');
      sink.add('Content-Type: text/event-stream\r\n');
      sink.add('Cache-Control: no-cache\r\n');
      sink.add('Connection: keep-alive\r\n');
      sink.add('\r\n');

      // Create controller for this connection
      final controller = StreamController<String>();
      _contactStreams.add(controller);

      debugPrint('   Total clients: ${_contactStreams.length}');

      // Send initial connection event
      sink.add(': connected\n\n');

      // Send initial contact list
      for (final contact in _contacts.values) {
        final event = _formatSseEvent('contact', _contactToJson(contact));
        sink.add(event);
      }

      // Start keep-alive timer
      final keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        try {
          sink.add(': keepalive\n\n');
        } catch (e) {
          debugPrint('⚠️ [SseServer] Keep-alive failed: $e');
          timer.cancel();
        }
      });

      // Listen to controller for new messages to broadcast
      final subscription = controller.stream.listen(
        (data) {
          try {
            sink.add(data);
          } catch (e) {
            debugPrint('⚠️ [SseServer] Failed to send data: $e');
          }
        },
        onDone: () {
          debugPrint('📤 [SseServer] Controller stream closed');
        },
      );

      // Wait for channel to close
      await channel.stream.drain();

      // Cleanup
      keepAliveTimer.cancel();
      await subscription.cancel();
      _contactStreams.remove(controller);
      await controller.close();

      debugPrint('📤 [SseServer] SSE client disconnected (contacts)');
      debugPrint('   Total clients: ${_contactStreams.length}');
    });
  }

  /// Handle POST message request
  Future<shelf.Response> _handlePostMessage(shelf.Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final recipientPublicKey = json['recipientPublicKey'] as String;
      final text = json['text'] as String;

      if (onSendMessage == null) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'Send message callback not configured'}),
        );
      }

      final success = await onSendMessage!(recipientPublicKey, text);

      return shelf.Response.ok(
        jsonEncode({'success': success}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ [SseServer] Error handling POST message: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Handle POST channel message request
  Future<shelf.Response> _handlePostChannelMessage(shelf.Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      final channelIdx = json['channelIdx'] as int;
      final text = json['text'] as String;

      if (onSendChannelMessage == null) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'Send channel message callback not configured'}),
        );
      }

      await onSendChannelMessage!(channelIdx, text);

      return shelf.Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ [SseServer] Error handling POST channel message: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Handle POST contacts sync request
  Future<shelf.Response> _handlePostContactsSync(shelf.Request request) async {
    try {
      if (onSyncContacts == null) {
        return shelf.Response.internalServerError(
          body: jsonEncode({'error': 'Sync contacts callback not configured'}),
        );
      }

      await onSyncContacts!();

      return shelf.Response.ok(
        jsonEncode({'success': true}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      debugPrint('❌ [SseServer] Error handling POST contacts sync: $e');
      return shelf.Response.internalServerError(
        body: jsonEncode({'error': e.toString()}),
      );
    }
  }

  /// Handle GET message history request
  shelf.Response _handleGetMessageHistory(shelf.Request request) {
    final messages = _messageHistory.map(_messageToJson).toList();
    return shelf.Response.ok(
      jsonEncode({'messages': messages}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Handle GET contacts request
  shelf.Response _handleGetContacts(shelf.Request request) {
    final contacts = _contacts.values.map(_contactToJson).toList();
    return shelf.Response.ok(
      jsonEncode({'contacts': contacts}),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Handle GET status request
  shelf.Response _handleGetStatus(shelf.Request request) {
    return shelf.Response.ok(
      jsonEncode({
        'status': 'running',
        'connectedClients': connectedClients,
        'messageCount': _messageHistory.length,
        'contactCount': _contacts.length,
        'deviceName': _deviceName,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  /// Handle root request (landing page)
  shelf.Response _handleRoot(shelf.Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <title>MeshCore SAR - SSE Server</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: sans-serif; margin: 40px; background: #f5f5f5; }
    .container { max-width: 600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    h1 { color: #333; }
    .status { background: #4CAF50; color: white; padding: 10px; border-radius: 4px; margin: 20px 0; }
    .endpoint { background: #f9f9f9; padding: 10px; margin: 10px 0; border-left: 3px solid #2196F3; font-family: monospace; }
    code { background: #eee; padding: 2px 6px; border-radius: 3px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 MeshCore SAR Server</h1>
    <div class="status">✅ Server is running</div>
    <p>This server enables multiple MeshCore SAR clients to share a single BLE device.</p>

    <h2>📡 SSE Endpoints</h2>
    <div class="endpoint">GET /sse/messages</div>
    <div class="endpoint">GET /sse/contacts</div>

    <h2>🔧 API Endpoints</h2>
    <div class="endpoint">POST /api/messages</div>
    <div class="endpoint">POST /api/messages/channel</div>
    <div class="endpoint">POST /api/contacts/sync</div>
    <div class="endpoint">GET /api/messages/history</div>
    <div class="endpoint">GET /api/contacts</div>
    <div class="endpoint">GET /api/status</div>

    <h2>📊 Stats</h2>
    <p>Connected clients: <strong id="clients">Loading...</strong></p>
    <p>Messages: <strong id="messages">Loading...</strong></p>
    <p>Contacts: <strong id="contacts">Loading...</strong></p>
  </div>

  <script>
    async function updateStats() {
      try {
        const res = await fetch('/api/status');
        const data = await res.json();
        document.getElementById('clients').textContent = data.connectedClients;
        document.getElementById('messages').textContent = data.messageCount;
        document.getElementById('contacts').textContent = data.contactCount;
      } catch (e) {
        console.error('Failed to fetch stats:', e);
      }
    }
    updateStats();
    setInterval(updateStats, 5000);
  </script>
</body>
</html>
''';
    return shelf.Response.ok(
      html,
      headers: {'content-type': 'text/html'},
    );
  }

  /// Broadcast a new message to all SSE clients
  void broadcastMessage(Message message) {
    // Add to history (limit to 1000 messages)
    _messageHistory.add(message);
    if (_messageHistory.length > 1000) {
      _messageHistory.removeAt(0);
    }

    // Broadcast to all connected clients
    final event = _formatSseEvent('message', _messageToJson(message));
    final deadStreams = <StreamController<String>>[];

    for (final stream in _messageStreams) {
      if (stream.isClosed) {
        deadStreams.add(stream);
      } else {
        try {
          stream.add(event);
        } catch (e) {
          debugPrint('⚠️ [SseServer] Failed to send to stream, marking as dead: $e');
          deadStreams.add(stream);
        }
      }
    }

    // Remove dead streams
    for (final stream in deadStreams) {
      _messageStreams.remove(stream);
      stream.close().catchError((e) => debugPrint('⚠️ [SseServer] Error closing dead stream: $e'));
    }

    if (deadStreams.isNotEmpty) {
      debugPrint('🧹 [SseServer] Removed ${deadStreams.length} dead message streams during broadcast');
    }

    debugPrint('📢 [SseServer] Broadcasted message to ${_messageStreams.length} clients');
  }

  /// Broadcast a new or updated contact to all SSE clients
  void broadcastContact(Contact contact) {
    // Update contact list
    _contacts[contact.publicKeyHex] = contact;

    // Broadcast to all connected clients
    final event = _formatSseEvent('contact', _contactToJson(contact));
    final deadStreams = <StreamController<String>>[];

    for (final stream in _contactStreams) {
      if (stream.isClosed) {
        deadStreams.add(stream);
      } else {
        try {
          stream.add(event);
        } catch (e) {
          debugPrint('⚠️ [SseServer] Failed to send to stream, marking as dead: $e');
          deadStreams.add(stream);
        }
      }
    }

    // Remove dead streams
    for (final stream in deadStreams) {
      _contactStreams.remove(stream);
      stream.close().catchError((e) => debugPrint('⚠️ [SseServer] Error closing dead stream: $e'));
    }

    if (deadStreams.isNotEmpty) {
      debugPrint('🧹 [SseServer] Removed ${deadStreams.length} dead contact streams during broadcast');
    }

    debugPrint('📢 [SseServer] Broadcasted contact to ${_contactStreams.length} clients');
  }

  /// Format SSE event
  String _formatSseEvent(String eventType, Map<String, dynamic> data) {
    final jsonData = jsonEncode(data);
    return 'event: $eventType\ndata: $jsonData\n\n';
  }

  /// Convert Message to JSON
  Map<String, dynamic> _messageToJson(Message message) {
    return {
      'id': message.id,
      'messageType': message.messageType.name,
      'senderPublicKeyPrefix': message.senderPublicKeyPrefix?.toList(),
      'channelIdx': message.channelIdx,
      'pathLen': message.pathLen,
      'textType': message.textType.value,
      'senderTimestamp': message.senderTimestamp,
      'text': message.text,
      'isSarMarker': message.isSarMarker,
      'sarGpsCoordinates': message.sarGpsCoordinates != null
          ? {
              'latitude': message.sarGpsCoordinates!.latitude,
              'longitude': message.sarGpsCoordinates!.longitude,
            }
          : null,
      'sarNotes': message.sarNotes,
      'sarCustomEmoji': message.sarCustomEmoji,
      'sarColorIndex': message.sarColorIndex,
      'receivedAt': message.receivedAt.toIso8601String(),
      'senderName': message.senderName,
      'deliveryStatus': message.deliveryStatus.name,
      'expectedAckTag': message.expectedAckTag,
      'suggestedTimeoutMs': message.suggestedTimeoutMs,
      'roundTripTimeMs': message.roundTripTimeMs,
      'deliveredAt': message.deliveredAt?.toIso8601String(),
      'recipientPublicKey': message.recipientPublicKey?.toList(),
      'retryAttempt': message.retryAttempt,
      'lastRetryAt': message.lastRetryAt?.toIso8601String(),
      'usedFloodFallback': message.usedFloodFallback,
      'isRead': message.isRead,
      'echoCount': message.echoCount,
      'firstEchoAt': message.firstEchoAt?.toIso8601String(),
      'isDrawing': message.isDrawing,
      'drawingId': message.drawingId,
    };
  }

  /// Convert Contact to JSON
  Map<String, dynamic> _contactToJson(Contact contact) {
    return {
      'publicKey': contact.publicKey.toList(),
      'publicKeyHex': contact.publicKeyHex,
      'type': contact.type.value,
      'flags': contact.flags,
      'outPathLen': contact.outPathLen,
      'outPath': contact.outPath.toList(),
      'advName': contact.advName,
      'lastAdvert': contact.lastAdvert,
      'advLat': contact.advLat,
      'advLon': contact.advLon,
      'lastMod': contact.lastMod,
      'telemetry': contact.telemetry != null
          ? {
              'batteryPercentage': contact.telemetry!.batteryPercentage,
              'batteryMilliVolts': contact.telemetry!.batteryMilliVolts,
              'temperature': contact.telemetry!.temperature,
              'humidity': contact.telemetry!.humidity,
              'pressure': contact.telemetry!.pressure,
              'gpsLocation': contact.telemetry!.gpsLocation != null
                  ? {
                      'latitude': contact.telemetry!.gpsLocation!.latitude,
                      'longitude': contact.telemetry!.gpsLocation!.longitude,
                    }
                  : null,
              'timestamp': contact.telemetry!.timestamp.toIso8601String(),
            }
          : null,
    };
  }

  /// Clear message history
  void clearMessageHistory() {
    _messageHistory.clear();
  }

  /// Clear contact list
  void clearContacts() {
    _contacts.clear();
  }
}
