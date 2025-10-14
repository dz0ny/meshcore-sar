import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/ble_packet_log.dart';
import '../services/meshcore_ble_service.dart';

class PacketLogScreen extends StatefulWidget {
  final MeshCoreBleService bleService;

  const PacketLogScreen({
    super.key,
    required this.bleService,
  });

  @override
  State<PacketLogScreen> createState() => _PacketLogScreenState();
}

class _PacketLogScreenState extends State<PacketLogScreen> {
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  PacketDirection? _filterDirection;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<BlePacketLog> get _filteredLogs {
    var logs = widget.bleService.packetLogs;

    // Filter by direction
    if (_filterDirection != null) {
      logs = logs.where((log) => log.direction == _filterDirection).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      logs = logs.where((log) {
        return log.hexData.toLowerCase().contains(query) ||
            (log.description?.toLowerCase().contains(query) ?? false) ||
            log.summary.toLowerCase().contains(query);
      }).toList();
    }

    return logs;
  }

  Future<void> _exportLogs(BuildContext context) async {
    try {
      final logs = _filteredLogs;
      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logs to export')),
          );
        }
        return;
      }

      // Create CSV content
      final buffer = StringBuffer();
      buffer.writeln('Timestamp,Direction,Size (bytes),Code,Hex Data,Description');
      for (final log in logs) {
        buffer.writeln(log.toCsvRow());
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ble_packets_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(buffer.toString());

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MeshCore BLE Packet Logs',
        text: 'Exported ${logs.length} BLE packets from MeshCore SAR app',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _exportAsText(BuildContext context) async {
    try {
      final logs = _filteredLogs;
      if (logs.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No logs to export')),
          );
        }
        return;
      }

      // Create text content
      final buffer = StringBuffer();
      buffer.writeln('MeshCore BLE Packet Logs');
      buffer.writeln('=' * 80);
      buffer.writeln('Exported: ${DateTime.now().toIso8601String()}');
      buffer.writeln('Total packets: ${logs.length}');
      buffer.writeln('=' * 80);
      buffer.writeln();

      for (final log in logs) {
        buffer.writeln(log.toLogString());
      }

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ble_packets_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(buffer.toString());

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'MeshCore BLE Packet Logs',
        text: 'Exported ${logs.length} BLE packets from MeshCore SAR app',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, BlePacketLog log) {
    Clipboard.setData(ClipboardData(text: log.hexData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hex data copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearLogs(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Packet Logs'),
        content: const Text('Are you sure you want to clear all packet logs? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.bleService.clearPacketLogs();
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Packet logs cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = _filteredLogs;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BLE Packet Logs'),
            Text(
              '${logs.length} packets',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          // Direction filter
          PopupMenuButton<PacketDirection?>(
            icon: Icon(_filterDirection == null
                ? Icons.filter_list
                : _filterDirection == PacketDirection.rx
                    ? Icons.arrow_downward
                    : Icons.arrow_upward),
            tooltip: 'Filter by direction',
            onSelected: (direction) {
              setState(() {
                _filterDirection = direction;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: null,
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: _filterDirection == null ? Theme.of(context).colorScheme.primary : null),
                    const SizedBox(width: 8),
                    Text('All',
                        style: TextStyle(
                            fontWeight: _filterDirection == null ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PacketDirection.rx,
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward,
                        color: _filterDirection == PacketDirection.rx
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('RX (Received)',
                        style: TextStyle(
                            fontWeight:
                                _filterDirection == PacketDirection.rx ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: PacketDirection.tx,
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward,
                        color: _filterDirection == PacketDirection.tx
                            ? Theme.of(context).colorScheme.primary
                            : null),
                    const SizedBox(width: 8),
                    Text('TX (Sent)',
                        style: TextStyle(
                            fontWeight:
                                _filterDirection == PacketDirection.tx ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
          // Auto-scroll toggle
          IconButton(
            icon: Icon(_autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center),
            tooltip: _autoScroll ? 'Disable auto-scroll' : 'Enable auto-scroll',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          // Export menu
          PopupMenuButton(
            icon: const Icon(Icons.share),
            tooltip: 'Export logs',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart),
                    SizedBox(width: 8),
                    Text('Export as CSV'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'txt',
                child: Row(
                  children: [
                    Icon(Icons.text_snippet),
                    SizedBox(width: 8),
                    Text('Export as Text'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'csv') {
                _exportLogs(context);
              } else if (value == 'txt') {
                _exportAsText(context);
              }
            },
          ),
          // Clear logs
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear logs',
            onPressed: () => _clearLogs(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Logs list
          Expanded(
            child: logs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.list_alt,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _filterDirection != null
                              ? 'No matching packets found'
                              : 'No packets logged yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty || _filterDirection != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _filterDirection = null;
                              });
                            },
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];

                      // Auto-scroll to bottom
                      if (_autoScroll && index == logs.length - 1) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      }

                      return _PacketLogCard(
                        log: log,
                        onCopy: () => _copyToClipboard(context, log),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PacketLogCard extends StatelessWidget {
  final BlePacketLog log;
  final VoidCallback onCopy;

  const _PacketLogCard({
    required this.log,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final isRx = log.direction == PacketDirection.rx;
    final directionColor = isRx ? Colors.green : Colors.blue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: directionColor.withOpacity(0.2),
          child: Icon(
            isRx ? Icons.arrow_downward : Icons.arrow_upward,
            color: directionColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              isRx ? 'RX' : 'TX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: directionColor,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            if (log.description != null)
              Flexible(
                child: Text(
                  log.description!,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Text(
                'Code: ${log.responseCode != null ? "0x${log.responseCode!.toRadixString(16).padLeft(2, '0')}" : "N/A"}',
                style: const TextStyle(fontSize: 14),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${log.rawData.length} bytes • ${_formatTimestamp(log.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hex data
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hex: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        log.hexData,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy hex data',
                      onPressed: onCopy,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Metadata
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: Icons.schedule,
                      label: log.timestamp.toIso8601String(),
                    ),
                    _InfoChip(
                      icon: Icons.data_usage,
                      label: '${log.rawData.length} bytes',
                    ),
                    if (log.responseCode != null)
                      _InfoChip(
                        icon: Icons.tag,
                        label: 'Code: 0x${log.responseCode!.toRadixString(16).padLeft(2, '0')} (${log.responseCode})',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 11),
      ),
      padding: const EdgeInsets.all(4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
