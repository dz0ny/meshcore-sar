import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:nsd/nsd.dart';

/// Discovered SSE server on the network
class DiscoveredServer {
  final String ipAddress;
  final int port;
  final int responseTime; // in milliseconds
  final String serverUrl;

  DiscoveredServer({
    required this.ipAddress,
    required this.port,
    required this.responseTime,
  }) : serverUrl = 'http://$ipAddress:$port';

  @override
  String toString() {
    return 'DiscoveredServer($ipAddress:$port, ${responseTime}ms)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredServer &&
        other.ipAddress == ipAddress &&
        other.port == port;
  }

  @override
  int get hashCode => Object.hash(ipAddress, port);
}

/// Network Scanner Service
///
/// Discovers SSE servers on the local network using Bonjour/mDNS.
/// Falls back to port scanning (12929) if no services are discovered.
/// Uses parallel scanning (20 IPs at once) for fast discovery.
class NetworkScannerService {
  static const int defaultPort = 12929;
  static const String serviceType = '_meshcore-sse._tcp';
  static const int parallelScans = 20;
  static const Duration scanTimeout = Duration(seconds: 2);
  static const Duration bonjourTimeout = Duration(seconds: 5);

  Discovery? _activeDiscovery;

  /// Callback for when a server is discovered
  Function(DiscoveredServer)? onServerDiscovered;

  /// Callback for scan progress updates
  Function(int scanned, int total)? onProgressUpdate;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Cached discovered servers from the last scan
  List<DiscoveredServer> _cachedServers = [];
  List<DiscoveredServer> get cachedServers => List.unmodifiable(_cachedServers);

  /// Whether we have cached results from a previous scan
  bool get hasCachedResults => _cachedServers.isNotEmpty;

  /// Get all local IP addresses
  Future<Set<String>> _getLocalIpAddresses() async {
    final Set<String> localIps = {};

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4) {
            localIps.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Error getting local IPs: $e');
    }

    return localIps;
  }

  /// Get local network IP range to scan
  Future<List<String>> _getLocalNetworkRange() async {
    final List<String> ips = [];

    try {
      // Get all network interfaces
      final interfaces = await NetworkInterface.list();

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Only scan IPv4 addresses that are not loopback
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            final ip = addr.address;
            final parts = ip.split('.');

            if (parts.length == 4) {
              // Generate range for the same subnet (e.g., 192.168.1.1-254)
              final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';

              // Scan from .1 to .254 (skip .0 and .255)
              for (int i = 1; i <= 254; i++) {
                ips.add('$subnet.$i');
              }

              debugPrint('📡 [NetworkScanner] Will scan subnet: $subnet.0/24');
              // Only scan first viable subnet
              return ips;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Error getting network interfaces: $e');
    }

    return ips;
  }

  /// Check if an IP has an SSE server running
  Future<DiscoveredServer?> _checkServer(String ip, int port) async {
    try {
      final stopwatch = Stopwatch()..start();
      final url = Uri.parse('http://$ip:$port/api/status');

      final response = await http.get(url).timeout(scanTimeout);

      stopwatch.stop();

      if (response.statusCode == 200) {
        debugPrint('✅ [NetworkScanner] Found server at $ip:$port (${stopwatch.elapsedMilliseconds}ms)');

        return DiscoveredServer(
          ipAddress: ip,
          port: port,
          responseTime: stopwatch.elapsedMilliseconds,
        );
      }
    } on TimeoutException {
      // Timeout - server not responding, ignore
    } on SocketException {
      // Connection refused - no server at this IP, ignore
    } catch (e) {
      // Other errors - ignore
      debugPrint('⚠️ [NetworkScanner] Error checking $ip:$port - $e');
    }

    return null;
  }

  /// Discover servers using Bonjour/mDNS
  Future<List<DiscoveredServer>> _discoverViaBonjourAsync({int? port}) async {
    final scanPort = port ?? defaultPort;
    final List<DiscoveredServer> discoveredServers = [];

    try {
      debugPrint('🔍 [NetworkScanner] Starting Bonjour discovery for $serviceType...');

      // Get local IP addresses to filter out
      final localIps = await _getLocalIpAddresses();
      debugPrint('📍 [NetworkScanner] Local IPs: ${localIps.join(", ")}');

      // Start discovery with IP lookup
      _activeDiscovery = await startDiscovery(
        serviceType,
        ipLookupType: IpLookupType.any,
      );

      // Wait for discovery to find services
      await Future.delayed(bonjourTimeout);

      // Process discovered services
      final services = _activeDiscovery?.services ?? [];
      debugPrint('📡 [NetworkScanner] Bonjour found ${services.length} services');

      for (final service in services) {
        if (service.addresses != null && service.addresses!.isNotEmpty) {
          for (final address in service.addresses!) {
            // Skip if this is a local IP address
            if (localIps.contains(address.address)) {
              debugPrint('⏭️ [NetworkScanner] Skipping local IP: ${address.address}');
              continue;
            }

            // Verify service is actually reachable
            final result = await _checkServer(
              address.address,
              service.port ?? scanPort,
            );

            if (result != null) {
              discoveredServers.add(result);
              onServerDiscovered?.call(result);
            }
          }
        }
      }

      // Stop discovery
      await stopDiscovery(_activeDiscovery!);
      _activeDiscovery = null;

      debugPrint('✅ [NetworkScanner] Bonjour discovery complete. Found ${discoveredServers.length} servers.');
    } catch (e) {
      debugPrint('⚠️ [NetworkScanner] Bonjour discovery failed: $e');
      if (_activeDiscovery != null) {
        try {
          await stopDiscovery(_activeDiscovery!);
        } catch (_) {}
        _activeDiscovery = null;
      }
    }

    return discoveredServers;
  }

  /// Scan the local network for SSE servers
  /// First tries Bonjour/mDNS, then falls back to port scanning if nothing found
  Future<List<DiscoveredServer>> scan({int? port}) async {
    if (_isScanning) {
      debugPrint('⚠️ [NetworkScanner] Scan already in progress');
      return [];
    }

    _isScanning = true;
    final scanPort = port ?? defaultPort;
    List<DiscoveredServer> discoveredServers = [];

    try {
      // Try Bonjour/mDNS discovery first
      discoveredServers = await _discoverViaBonjourAsync(port: scanPort);

      // Fall back to port scanning if Bonjour found nothing
      if (discoveredServers.isEmpty) {
        debugPrint('🔍 [NetworkScanner] Bonjour found nothing, falling back to port scanning...');
        discoveredServers = await _scanByPortAsync(port: scanPort);
      }

      // Cache the results
      _cachedServers = discoveredServers;
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Scan error: $e');
    } finally {
      _isScanning = false;
    }

    return discoveredServers;
  }

  /// Fallback port scanning method
  Future<List<DiscoveredServer>> _scanByPortAsync({int? port}) async {
    final scanPort = port ?? defaultPort;
    final List<DiscoveredServer> discoveredServers = [];

    try {
      debugPrint('🔍 [NetworkScanner] Starting port scan on port $scanPort...');

      // Get local IP addresses to filter out
      final localIps = await _getLocalIpAddresses();
      debugPrint('📍 [NetworkScanner] Local IPs: ${localIps.join(", ")}');

      final ips = await _getLocalNetworkRange();

      if (ips.isEmpty) {
        debugPrint('⚠️ [NetworkScanner] No network interfaces found');
        return [];
      }

      debugPrint('📊 [NetworkScanner] Scanning ${ips.length} IPs with $parallelScans parallel connections');

      int scannedCount = 0;

      // Scan in batches of 20 parallel connections
      for (int i = 0; i < ips.length; i += parallelScans) {
        final batch = ips.skip(i).take(parallelScans).toList();

        // Scan batch in parallel
        final futures = batch.map((ip) => _checkServer(ip, scanPort)).toList();
        final results = await Future.wait(futures);

        // Collect discovered servers (excluding local IPs)
        for (int j = 0; j < results.length; j++) {
          final result = results[j];
          if (result != null) {
            // Skip if this is a local IP address
            if (localIps.contains(result.ipAddress)) {
              debugPrint('⏭️ [NetworkScanner] Skipping local IP: ${result.ipAddress}');
              continue;
            }

            discoveredServers.add(result);
            onServerDiscovered?.call(result);
          }
        }

        scannedCount += batch.length;
        onProgressUpdate?.call(scannedCount, ips.length);
      }

      debugPrint('✅ [NetworkScanner] Port scan complete. Found ${discoveredServers.length} servers.');
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Port scan error: $e');
    }

    return discoveredServers;
  }

  /// Clear cached results (useful for forcing a fresh scan)
  void clearCache() {
    _cachedServers = [];
    debugPrint('🗑️ [NetworkScanner] Cache cleared');
  }

  /// Stop ongoing scan
  void stopScan() {
    if (_isScanning) {
      debugPrint('🛑 [NetworkScanner] Stopping scan...');
      _isScanning = false;
    }
  }

  /// Verify that a previously discovered server is still available
  /// Returns true if server is reachable, false otherwise
  Future<bool> verifyServer(DiscoveredServer server) async {
    try {
      debugPrint('🔍 [NetworkScanner] Verifying server at ${server.ipAddress}:${server.port}...');

      final result = await _checkServer(server.ipAddress, server.port);

      if (result != null) {
        debugPrint('✅ [NetworkScanner] Server verified at ${server.ipAddress}:${server.port}');
        return true;
      } else {
        debugPrint('❌ [NetworkScanner] Server no longer available at ${server.ipAddress}:${server.port}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [NetworkScanner] Server verification failed: $e');
      return false;
    }
  }
}
