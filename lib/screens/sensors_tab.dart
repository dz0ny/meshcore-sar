import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/connection_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/sensors_provider.dart';
import '../utils/location_formats.dart';

class SensorsTab extends StatelessWidget {
  const SensorsTab({super.key});

  Future<void> _showAddSensorSheet(BuildContext context) async {
    final sensorsProvider = context.read<SensorsProvider>();
    final contactsProvider = context.read<ContactsProvider>();
    final candidates = sensorsProvider.availableCandidates(contactsProvider);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        if (candidates.isEmpty) {
          return const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No eligible nodes available. Discover a relay or node first.',
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              const ListTile(
                title: Text(
                  'Add sensor node',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Pick a relay or node to watch in Sensors.'),
              ),
              ...candidates.map(
                (contact) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFDDEAF8),
                    child: Icon(
                      _typeIcon(contact),
                      color: const Color(0xFF1E4F7A),
                    ),
                  ),
                  title: Text(contact.displayName),
                  subtitle: _SensorCandidatePreview(contact: contact),
                  isThreeLine: true,
                  onTap: () async {
                    await sensorsProvider.addSensor(contact);
                    if (!sheetContext.mounted) return;
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${contact.displayName} added to Sensors',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMetricSelector(
    BuildContext context,
    String publicKeyHex,
    Contact? contact,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer<SensorsProvider>(
        builder: (context, sensorsProvider, child) {
          final visibleFields = sensorsProvider.visibleFieldsFor(publicKeyHex);
          final options = _fieldOptionsFor(contact);
          return SafeArea(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(
                  'Visible fields',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which values appear on sensor cards.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ...options.map((option) {
                  final visible = visibleFields.contains(option.key);
                  final span = sensorsProvider.fieldSpanFor(
                    publicKeyHex,
                    option.key,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilterChip(
                            selected: visible,
                            label: Text(option.label),
                            onSelected: (value) {
                              sensorsProvider.toggleMetric(
                                publicKeyHex,
                                option.key,
                                value,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment<int>(value: 1, label: Text('1x')),
                            ButtonSegment<int>(value: 2, label: Text('2x')),
                          ],
                          selected: <int>{span},
                          onSelectionChanged: (selection) {
                            sensorsProvider.setFieldSpan(
                              publicKeyHex,
                              option.key,
                              selection.first,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _refreshAll(BuildContext context) async {
    await context.read<SensorsProvider>().refreshAll(
      contactsProvider: context.read<ContactsProvider>(),
      connectionProvider: context.read<ConnectionProvider>(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSensorSheet(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer2<SensorsProvider, ContactsProvider>(
        builder: (context, sensorsProvider, contactsProvider, child) {
          final watchedKeys = sensorsProvider.watchedSensorKeys;

          return RefreshIndicator(
            onRefresh: () => _refreshAll(context),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (watchedKeys.isEmpty)
                  const _EmptySensorsState()
                else
                  ...watchedKeys.map((key) {
                    Contact? contact;
                    for (final entry in contactsProvider.contacts) {
                      if (entry.publicKeyHex == key) {
                        contact = entry;
                        break;
                      }
                    }
                    return _SensorCard(
                      contact: contact,
                      state: sensorsProvider.stateFor(key),
                      visibleFields: sensorsProvider.visibleFieldsFor(key),
                      fieldSpans: {
                        for (final field in sensorsProvider.visibleFieldsFor(
                          key,
                        ))
                          field: sensorsProvider.fieldSpanFor(key, field),
                      },
                      onRemove: () async {
                        await sensorsProvider.removeSensor(key);
                      },
                      onCustomize: () =>
                          _showMetricSelector(context, key, contact),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SensorCandidatePreview extends StatelessWidget {
  final Contact contact;

  const _SensorCandidatePreview({required this.contact});

  @override
  Widget build(BuildContext context) {
    final telemetry = contact.telemetry;
    final previewLines = <String>[
      '${contact.type.displayName} • ${contact.publicKeyShort}',
      if (telemetry?.batteryPercentage != null)
        'Battery ${telemetry!.batteryPercentage!.toStringAsFixed(0)}% • '
            'Temp ${telemetry.temperature?.toStringAsFixed(1) ?? '--'}°C',
      if (telemetry?.gpsLocation != null)
        'GPS ${telemetry!.gpsLocation!.latitude.toStringAsFixed(3)}, '
            '${telemetry.gpsLocation!.longitude.toStringAsFixed(3)}',
    ];

    if (previewLines.length == 1) {
      previewLines.add('No telemetry preview available yet');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: previewLines
          .take(3)
          .map(
            (line) => Text(line, maxLines: 1, overflow: TextOverflow.ellipsis),
          )
          .toList(),
    );
  }
}

class _EmptySensorsState extends StatelessWidget {
  const _EmptySensorsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
              color: Color(0xFFDDEAF8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sensors_outlined,
              size: 40,
              color: Color(0xFF1E4F7A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No sensor nodes added',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Use + to add discovered relays or nodes. Pull down to refresh telemetry after adding them.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final Contact? contact;
  final SensorRefreshState state;
  final Set<String> visibleFields;
  final Map<String, int> fieldSpans;
  final Future<void> Function() onRemove;
  final VoidCallback onCustomize;

  const _SensorCard({
    required this.contact,
    required this.state,
    required this.visibleFields,
    required this.fieldSpans,
    required this.onRemove,
    required this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final telemetry = contact?.telemetry;
    final theme = Theme.of(context);
    final metrics = contact == null || telemetry == null
        ? const <_MetricCardData>[]
        : _buildMetricCards(l10n, telemetry, contact!);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            contact?.displayName ?? 'Unavailable node',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (state == SensorRefreshState.timeout)
                            const _InlineAlertBadge(label: 'No response'),
                        ],
                      ),
                      if (telemetry != null) ...[
                        const SizedBox(height: 2),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${_formatTelemetryDateTime(telemetry.timestamp)} • ${_formatTelemetryTime(telemetry.timestamp)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (state == SensorRefreshState.refreshing)
                              const _InlineStateMeta(
                                label: 'Refreshing',
                                color: Color(0xFF266AC2),
                                spinning: true,
                              ),
                            if (state == SensorRefreshState.success)
                              const _InlineStateMeta(
                                label: 'Updated',
                                color: Color(0xFF218B63),
                                icon: Icons.check_circle,
                              ),
                            if (state == SensorRefreshState.unavailable)
                              const _InlineStateMeta(
                                label: 'Unavailable',
                                color: Color(0xFFB13B55),
                                icon: Icons.error_outline,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'remove') {
                      await onRemove();
                    } else if (value == 'customize') {
                      onCustomize();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'customize',
                      child: Text('Customize fields'),
                    ),
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('Remove'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (contact == null)
              const Text(
                'This node is no longer available in the contact list.',
              )
            else if (telemetry == null)
              const Text('No telemetry received yet. Pull down to fetch it.')
            else if (metrics.isEmpty)
              const Text(
                'All fields are hidden. Use Visible fields to choose what to show.',
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final compactWidth = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: metrics
                        .map(
                          (metric) => _MetricTile(
                            data: metric,
                            width:
                                (fieldSpans[metric.fieldKey] == 2 ||
                                    metric.wide)
                                ? constraints.maxWidth
                                : compactWidth,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  List<_MetricCardData> _buildMetricCards(
    AppLocalizations l10n,
    dynamic telemetry,
    Contact contact,
  ) {
    final items = <_MetricCardData>[];

    if (visibleFields.contains('voltage') &&
        telemetry.batteryMilliVolts != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'voltage',
          icon: Icons.bolt,
          label: l10n.voltage,
          value: '${(telemetry.batteryMilliVolts! / 1000).toStringAsFixed(3)}V',
          accent: const Color(0xFF0A7D61),
        ),
      );
    }
    if (visibleFields.contains('battery') &&
        telemetry.batteryPercentage != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'battery',
          icon: Icons.battery_5_bar,
          label: l10n.battery,
          value: '${telemetry.batteryPercentage!.toStringAsFixed(0)}%',
          accent: const Color(0xFF4B8E2F),
        ),
      );
    }
    if (visibleFields.contains('temperature') &&
        telemetry.temperature != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'temperature',
          icon: Icons.thermostat,
          label: l10n.temperature,
          value: '${telemetry.temperature!.toStringAsFixed(1)}°C',
          accent: const Color(0xFFC76821),
        ),
      );
    }
    if (visibleFields.contains('humidity') && telemetry.humidity != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'humidity',
          icon: Icons.water_drop,
          label: l10n.humidity,
          value: '${telemetry.humidity!.toStringAsFixed(1)}%',
          accent: const Color(0xFF246BB2),
        ),
      );
    }
    if (visibleFields.contains('pressure') && telemetry.pressure != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'pressure',
          icon: Icons.compress,
          label: l10n.pressure,
          value: '${telemetry.pressure!.toStringAsFixed(1)} hPa',
          accent: const Color(0xFF6B4BAE),
        ),
      );
    }
    if (visibleFields.contains('gps') && telemetry.gpsLocation != null) {
      items.add(
        _MetricCardData(
          fieldKey: 'gps',
          icon: Icons.place,
          label: l10n.gpsTelemetry,
          value:
              '${telemetry.gpsLocation!.latitude.toStringAsFixed(5)}, ${telemetry.gpsLocation!.longitude.toStringAsFixed(5)}',
          accent: const Color(0xFFAA3F57),
          wide: true,
          mapLocation: LatLng(
            telemetry.gpsLocation!.latitude,
            telemetry.gpsLocation!.longitude,
          ),
          secondaryValue: formatPlusCode(
            telemetry.gpsLocation!.latitude,
            telemetry.gpsLocation!.longitude,
          ),
        ),
      );
    }
    if (telemetry.extraSensorData != null) {
      for (final entry in telemetry.extraSensorData!.entries) {
        final fieldKey = _extraFieldKey(entry.key);
        if (!visibleFields.contains(fieldKey)) {
          continue;
        }
        items.add(
          _MetricCardData(
            fieldKey: fieldKey,
            icon: Icons.sensors,
            label: _formatExtraFieldLabel(entry.key),
            value: '${entry.value}',
            accent: const Color(0xFF3E657C),
          ),
        );
      }
    }

    return items;
  }

  String _formatTelemetryTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatTelemetryDateTime(DateTime timestamp) {
    final local = timestamp.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

class _InlineStateMeta extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool spinning;

  const _InlineStateMeta({
    required this.label,
    required this.color,
    this.icon,
    this.spinning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinning)
            SizedBox(
              width: 11,
              height: 11,
              child: CircularProgressIndicator(
                strokeWidth: 1.7,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            )
          else if (icon != null)
            Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineAlertBadge extends StatelessWidget {
  final String label;

  const _InlineAlertBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFC17B1D).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFFC17B1D),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final _MetricCardData data;
  final double width;

  const _MetricTile({required this.data, required this.width});

  Future<void> _showExpandedMap(BuildContext context) async {
    final location = data.mapLocation;
    if (location == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            height: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data.label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data.value,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            if (data.secondaryValue != null)
                              Text(
                                data.secondaryValue!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: flutter_map.FlutterMap(
                    options: flutter_map.MapOptions(
                      initialCenter: location,
                      initialZoom: 15,
                    ),
                    children: [
                      flutter_map.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.meshcore.sar.meshcore_sar_app',
                      ),
                      flutter_map.MarkerLayer(
                        markers: [
                          flutter_map.Marker(
                            point: location,
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.location_on,
                              color: data.accent,
                              size: 34,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: data.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.accent.withValues(alpha: 0.14)),
      ),
      child: data.mapLocation == null
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricIcon(accent: data.accent, icon: data.icon),
                const SizedBox(width: 10),
                Expanded(child: _MetricText(data: data)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricIcon(accent: data.accent, icon: data.icon),
                    const SizedBox(width: 10),
                    Expanded(child: _MetricText(data: data)),
                  ],
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _showExpandedMap(context),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 104,
                        width: double.infinity,
                        child: Stack(
                          children: [
                            flutter_map.FlutterMap(
                              options: flutter_map.MapOptions(
                                initialCenter: data.mapLocation!,
                                initialZoom: 14,
                                interactionOptions:
                                    const flutter_map.InteractionOptions(
                                      flags: flutter_map.InteractiveFlag.none,
                                    ),
                              ),
                              children: [
                                flutter_map.TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName:
                                      'com.meshcore.sar.meshcore_sar_app',
                                ),
                                flutter_map.MarkerLayer(
                                  markers: [
                                    flutter_map.Marker(
                                      point: data.mapLocation!,
                                      width: 32,
                                      height: 32,
                                      child: Icon(
                                        Icons.location_on,
                                        color: data.accent,
                                        size: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.open_in_full,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Open map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MetricIcon extends StatelessWidget {
  final Color accent;
  final IconData icon;

  const _MetricIcon({required this.accent, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: accent, size: 18),
    );
  }
}

class _MetricText extends StatelessWidget {
  final _MetricCardData data;

  const _MetricText({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: data.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
        ),
        if (data.secondaryValue != null) ...[
          const SizedBox(height: 4),
          Text(
            data.secondaryValue!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _MetricCardData {
  final String fieldKey;
  final IconData icon;
  final String label;
  final String value;
  final String? secondaryValue;
  final Color accent;
  final bool wide;
  final LatLng? mapLocation;

  const _MetricCardData({
    required this.fieldKey,
    required this.icon,
    required this.label,
    required this.value,
    this.secondaryValue,
    required this.accent,
    this.wide = false,
    this.mapLocation,
  });
}

class _FieldOption {
  final String key;
  final String label;

  const _FieldOption({required this.key, required this.label});
}

List<_FieldOption> _fieldOptionsFor(Contact? contact) {
  final telemetry = contact?.telemetry;
  final options = <_FieldOption>[
    if (telemetry?.batteryMilliVolts != null)
      const _FieldOption(key: 'voltage', label: 'Voltage'),
    if (telemetry?.batteryPercentage != null)
      const _FieldOption(key: 'battery', label: 'Battery'),
    if (telemetry?.temperature != null)
      const _FieldOption(key: 'temperature', label: 'Temperature'),
    if (telemetry?.humidity != null)
      const _FieldOption(key: 'humidity', label: 'Humidity'),
    if (telemetry?.pressure != null)
      const _FieldOption(key: 'pressure', label: 'Pressure'),
    if (telemetry?.gpsLocation != null)
      const _FieldOption(key: 'gps', label: 'GPS'),
  ];

  final extraSensorData = telemetry?.extraSensorData;
  if (extraSensorData != null) {
    for (final key in extraSensorData.keys) {
      options.add(
        _FieldOption(
          key: _extraFieldKey(key),
          label: _formatExtraFieldLabel(key),
        ),
      );
    }
  }

  return options;
}

String _extraFieldKey(String label) {
  return 'extra:$label';
}

String _formatExtraFieldLabel(String rawKey) {
  final knownPrefixes = <String, String>{
    'altitude': 'Altitude',
    'illuminance': 'Illuminance',
    'presence': 'Presence',
    'digital_input': 'Digital input',
    'digital_output': 'Digital output',
    'analog_input': 'Analog input',
    'analog_output': 'Analog output',
    'accelerometer': 'Accelerometer',
    'gyrometer': 'Gyrometer',
  };

  for (final entry in knownPrefixes.entries) {
    final prefix = '${entry.key}_';
    if (rawKey == entry.key) {
      return entry.value;
    }
    if (rawKey.startsWith(prefix)) {
      final suffix = rawKey.substring(prefix.length);
      final channel = int.tryParse(suffix);
      if (channel != null) {
        return '${entry.value} (ch $channel)';
      }
      return entry.value;
    }
  }

  final parts = rawKey.split('_');
  if (parts.isEmpty) return rawKey;
  final channel = parts.length > 1 ? parts.last : null;
  final base = parts.length > 1
      ? parts.sublist(0, parts.length - 1).join(' ')
      : rawKey;
  final title = base
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
  if (channel != null && int.tryParse(channel) != null) {
    return '$title (ch $channel)';
  }
  return title;
}

IconData _typeIcon(Contact contact) {
  if (contact.isRepeater) {
    return Icons.router;
  }
  if (contact.isChat) {
    return Icons.sensors;
  }
  return Icons.device_hub;
}
