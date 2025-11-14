/// SSE Server Configuration Model
///
/// Configuration for the SSE (Server-Sent Events) web server that enables
/// multiple app instances to share a single MeshCore BLE device.
class SseServerConfig {
  /// Server bind address (e.g., "0.0.0.0" for all interfaces, "127.0.0.1" for localhost)
  final String host;

  /// Server port (default: 12929)
  final int port;

  /// Whether the SSE server is enabled
  final bool enabled;

  /// Optional authentication token for basic security
  /// Clients must include this token in Authorization header
  final String? authToken;

  const SseServerConfig({
    this.host = '0.0.0.0',
    this.port = 12929,
    this.enabled = false,
    this.authToken,
  });

  /// Create a copy with updated fields
  SseServerConfig copyWith({
    String? host,
    int? port,
    bool? enabled,
    String? authToken,
  }) {
    return SseServerConfig(
      host: host ?? this.host,
      port: port ?? this.port,
      enabled: enabled ?? this.enabled,
      authToken: authToken ?? this.authToken,
    );
  }

  /// Get server URL for clients to connect to
  String getServerUrl({String? ipAddress}) {
    final ip = ipAddress ?? host;
    return 'http://$ip:$port';
  }

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'enabled': enabled,
      'authToken': authToken,
    };
  }

  /// Create from JSON
  factory SseServerConfig.fromJson(Map<String, dynamic> json) {
    return SseServerConfig(
      host: json['host'] as String? ?? '0.0.0.0',
      port: json['port'] as int? ?? 12929,
      enabled: json['enabled'] as bool? ?? false,
      authToken: json['authToken'] as String?,
    );
  }

  @override
  String toString() {
    return 'SseServerConfig(host: $host, port: $port, enabled: $enabled, hasAuth: ${authToken != null})';
  }
}
