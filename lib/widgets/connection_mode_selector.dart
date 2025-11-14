import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../models/sse_server_config.dart';

/// Connection Mode Selector Widget
///
/// Allows user to enable/disable SSE Server mode to share device with multiple clients
class ConnectionModeSelector extends StatefulWidget {
  const ConnectionModeSelector({super.key});

  @override
  State<ConnectionModeSelector> createState() => _ConnectionModeSelectorState();
}

class _ConnectionModeSelectorState extends State<ConnectionModeSelector> {
  List<String> _localIPs = [];

  @override
  void initState() {
    super.initState();
    _loadLocalIPs();
  }

  Future<void> _loadLocalIPs() async {
    final Set<String> ipsSet = {};

    try {
      final interfaces = await NetworkInterface.list();
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            ipsSet.add(addr.address);
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting network interfaces: $e');
    }

    if (mounted) {
      setState(() {
        _localIPs = ipsSet.toList();
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionProvider = Provider.of<ConnectionProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Network Sharing',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // SSE Server Toggle
        SwitchListTile(
          secondary: const Icon(Icons.share),
          title: const Text('Share Device (Server)'),
          subtitle: Text(
            connectionProvider.isSseServerRunning
                ? 'Server running on port ${connectionProvider.sseServerConfig.port} - ${connectionProvider.sseClientCount} client(s) connected'
                : 'Share BLE device with multiple clients over network',
          ),
          value: connectionProvider.isSseServerRunning,
          onChanged: (enabled) async {
            if (enabled) {
              // Start server with default config (port 12929, no auth)
              final config = const SseServerConfig(port: 12929, enabled: true);

              try {
                await connectionProvider.startSseServer(config);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SSE server started on port 12929'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to start server: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            } else {
              // Stop server
              await connectionProvider.stopSseServer();
            }
          },
        ),

        // Show IP addresses when server is running
        if (connectionProvider.isSseServerRunning && _localIPs.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Connect from other devices:',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ..._localIPs.map((ip) {
            final url = 'http://$ip:${connectionProvider.sseServerConfig.port}';
            return ListTile(
              dense: true,
              leading: const Icon(Icons.wifi, size: 20),
              title: Text(
                url,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                tooltip: 'Copy URL',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied $url'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}
