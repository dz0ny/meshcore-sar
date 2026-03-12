import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as flutter_map;
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../models/contact.dart';
import '../../providers/connection_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/contact_route_resolver.dart';
import '../../services/path_history_service.dart';
import '../../services/route_hash_preferences.dart';
import '../../models/path_history.dart';

class ContactRouteDialogResult {
  final ParsedContactRoute? route;
  final bool shouldClear;
  final LatLng? inferredFallbackLocation;

  const ContactRouteDialogResult._({
    this.route,
    required this.shouldClear,
    this.inferredFallbackLocation,
  });

  const ContactRouteDialogResult.set(ParsedContactRoute route)
    : this._(route: route, shouldClear: false);

  const ContactRouteDialogResult.setWithFallback(
    ParsedContactRoute route, {
    LatLng? inferredFallbackLocation,
  }) : this._(
         route: route,
         shouldClear: false,
         inferredFallbackLocation: inferredFallbackLocation,
       );

  const ContactRouteDialogResult.clear() : this._(shouldClear: true);
}

class ContactRouteDialog extends StatefulWidget {
  final Contact contact;
  final List<Contact> availableContacts;

  const ContactRouteDialog({
    super.key,
    required this.contact,
    required this.availableContacts,
  });

  static Future<ContactRouteDialogResult?> show(
    BuildContext context, {
    required Contact contact,
    required List<Contact> availableContacts,
  }) {
    return showModalBottomSheet<ContactRouteDialogResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ContactRouteDialog(
            contact: contact,
            availableContacts: availableContacts,
          ),
        ),
      ),
    );
  }

  @override
  State<ContactRouteDialog> createState() => _ContactRouteDialogState();
}

class _ContactRouteDialogState extends State<ContactRouteDialog> {
  late final TextEditingController _controller;
  final PathHistoryService _pathHistoryService = PathHistoryService();
  int _selectedHashSize = RouteHashPreferences.defaultHashSize;
  ParsedContactRoute? _parsedRoute;
  String? _errorText;
  bool _showRoutingInfo = false;
  List<Contact> _selectedMapHops = const [];
  ContactPathHistory? _pathHistory;
  _RouteEntryMode _entryMode = _RouteEntryMode.map;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.contact.routeCanonicalText,
    );
    _controller.addListener(_reparse);
    _entryMode = widget.contact.routeCanonicalText.isNotEmpty
        ? _RouteEntryMode.manual
        : _RouteEntryMode.map;
    _loadHashSizePreference();
    _loadPathHistory();
    _reparse();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_reparse)
      ..dispose();
    super.dispose();
  }

  void _reparse() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _parsedRoute = null;
        _errorText = null;
        _selectedMapHops = const [];
      });
      return;
    }

    try {
      final parsed = ContactRouteCodec.parse(
        input,
        expectedHashSize: _selectedHashSize,
      );
      final selectedMapHops = _mapSelectionForText(input);
      setState(() {
        _parsedRoute = parsed;
        _errorText = null;
        _selectedMapHops = selectedMapHops;
      });
    } on ContactRouteFormatException catch (error) {
      setState(() {
        _parsedRoute = null;
        _errorText = error.message;
      });
    }
  }

  List<Contact> get _routeCandidates =>
      widget.availableContacts
          .where(
            (contact) => contact.isRepeater && contact.displayLocation != null,
          )
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<Contact> _mapSelectionForText(String text) {
    final tokens = text
        .trim()
        .split(',')
        .map((token) => token.trim().toUpperCase())
        .where((token) => token.isNotEmpty)
        .toList();
    final selected = <Contact>[];
    final seen = <String>{};
    for (final token in tokens) {
      final match = _routeCandidates
          .where(
            (contact) => contact.publicKeyHex.toUpperCase().startsWith(token),
          )
          .firstOrNull;
      if (match != null && seen.add(match.publicKeyHex)) {
        selected.add(match);
      }
    }
    return selected;
  }

  Future<void> _loadHashSizePreference() async {
    final hashSize = await RouteHashPreferences.getHashSize();
    if (!mounted) return;
    setState(() {
      _selectedHashSize = hashSize;
    });
    _reparse();
  }

  Future<void> _loadPathHistory() async {
    await _pathHistoryService.initialize();
    if (!mounted) return;
    setState(() {
      _pathHistory = _pathHistoryService.historyFor(
        widget.contact.publicKeyHex,
      );
    });
  }

  String _tokenFor(Contact contact, int hashSize) {
    final hex = contact.publicKeyHex.toUpperCase();
    final length = hashSize * 2;
    if (hex.length < length) {
      return hex;
    }
    return hex.substring(0, length);
  }

  void _syncControllerFromSelectedHops() {
    final tokens = _selectedMapHops
        .map((contact) => _tokenFor(contact, _selectedHashSize))
        .toList();
    _controller.text = tokens.join(',');
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  void _toggleHop(Contact contact) {
    setState(() {
      if (_selectedMapHops.any(
        (item) => item.publicKeyHex == contact.publicKeyHex,
      )) {
        _selectedMapHops = _selectedMapHops
            .where((item) => item.publicKeyHex != contact.publicKeyHex)
            .toList();
      } else {
        _selectedMapHops = [..._selectedMapHops, contact];
      }
      _syncControllerFromSelectedHops();
      _reparse();
    });
  }

  void _applyResolvedPlan(ResolvedContactRoutePlan plan) {
    setState(() {
      _selectedMapHops = plan.selectedContacts;
      _controller.text = plan.canonicalText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _errorText = null;
      _entryMode = _RouteEntryMode.map;
    });
    _reparse();
  }

  void _applyHistoryRecord(PathRecord record) {
    final canonicalText = _canonicalRouteFromBytes(
      record.pathBytes,
      hashSize: record.hashSize,
    );
    setState(() {
      _controller.text = canonicalText;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      _errorText = null;
      _entryMode = _RouteEntryMode.manual;
    });
    _reparse();
  }

  LatLng? _resolveLastHopLocation() {
    if (_selectedMapHops.isNotEmpty) {
      return _selectedMapHops.last.displayLocation == null
          ? null
          : LatLng(
              _selectedMapHops.last.displayLocation!.latitude,
              _selectedMapHops.last.displayLocation!.longitude,
            );
    }

    final tokens = _controller.text
        .trim()
        .split(',')
        .map((token) => token.trim().toUpperCase())
        .where((token) => token.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;
    final lastToken = tokens.last;
    final match = _routeCandidates
        .where(
          (contact) => contact.publicKeyHex.toUpperCase().startsWith(lastToken),
        )
        .firstOrNull;
    final location = match?.displayLocation;
    if (location == null) return null;
    return LatLng(location.latitude, location.longitude);
  }

  LatLng? _buildSyntheticFallbackLocation() {
    final lastHopLocation = _resolveLastHopLocation();
    if (lastHopLocation == null) return null;

    final seed = widget.contact.publicKey.fold<int>(
      _controller.text.codeUnits.fold<int>(0, (sum, unit) => sum + unit),
      (sum, byte) => sum + byte,
    );
    final angle = (seed % 360) * (math.pi / 180.0);
    const radiusMeters = 500.0;
    final latOffset = (radiusMeters / 111320.0) * math.cos(angle);
    final lonDenominator =
        111320.0 * math.cos(lastHopLocation.latitude * (math.pi / 180.0));
    final lonOffset = lonDenominator.abs() < 1e-6
        ? 0.0
        : (radiusMeters / lonDenominator) * math.sin(angle);
    return LatLng(
      lastHopLocation.latitude + latOffset,
      lastHopLocation.longitude + lonOffset,
    );
  }

  void _resolvePathAutomatically() {
    final connectionProvider = context.read<ConnectionProvider>();
    final advLat = connectionProvider.deviceInfo.advLat;
    final advLon = connectionProvider.deviceInfo.advLon;
    final recipientLocation = widget.contact.displayLocation;
    if (advLat == null ||
        advLon == null ||
        (advLat == 0 && advLon == 0) ||
        recipientLocation == null) {
      setState(() {
        _errorText =
            'Automatic resolve needs both your advertised location and the contact location.';
      });
      return;
    }

    final plan = ContactRouteResolver.resolveAutomaticRoute(
      senderLocation: LatLng(advLat / 1e6, advLon / 1e6),
      recipient: widget.contact,
      availableContacts: widget.availableContacts,
      hashSize: _selectedHashSize,
    );
    if (plan == null) {
      setState(() {
        _errorText =
            'Could not resolve a route from available repeater locations.';
      });
      return;
    }

    _applyResolvedPlan(plan);
  }

  String _canonicalRouteFromBytes(
    List<int> pathBytes, {
    required int hashSize,
  }) {
    final hops = <String>[];
    for (var i = 0; i < pathBytes.length; i += hashSize) {
      final hop = pathBytes.sublist(i, i + hashSize);
      hops.add(
        hop
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
      );
    }
    return hops.join(',');
  }

  String _historySubtitle(PathRecord record) {
    final attempts = record.successCount + record.failureCount;
    final lastSeen = MaterialLocalizations.of(
      context,
    ).formatShortDate(record.lastUsedAt);
    final successRate = attempts == 0
        ? 'No send stats yet'
        : '${(record.successRate * 100).round()}% success over $attempts send${attempts == 1 ? '' : 's'}';
    final latency = record.lastRoundTripTimeMs > 0
        ? ' • ${record.lastRoundTripTimeMs} ms'
        : '';
    return '$successRate • Last used $lastSeen$latency';
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _parsedRoute == null
              ? 'Preview: enter or pick a route to validate it.'
              : 'Preview: ${_parsedRoute!.summary} • ${_parsedRoute!.byteLength} bytes • descriptor 0x${_parsedRoute!.encodedPathLen.toRadixString(16).padLeft(2, '0').toUpperCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_parsedRoute != null) ...[
          const SizedBox(height: 4),
          SelectableText(
            _parsedRoute!.canonicalText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
          ),
        ],
      ],
    );
  }

  Widget _buildBuilderTab(
    BuildContext context, {
    required List<Contact> routeCandidates,
    required List<LatLng> mapPoints,
    required List<LatLng> routePoints,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<_RouteEntryMode>(
          segments: const [
            ButtonSegment<_RouteEntryMode>(
              value: _RouteEntryMode.map,
              icon: Icon(Icons.map_outlined),
              label: Text('Map'),
            ),
            ButtonSegment<_RouteEntryMode>(
              value: _RouteEntryMode.manual,
              icon: Icon(Icons.tune),
              label: Text('Manual'),
            ),
          ],
          selected: {_entryMode},
          onSelectionChanged: (selection) {
            setState(() {
              _entryMode = selection.first;
            });
          },
        ),
        const SizedBox(height: 16),
        if (_entryMode == _RouteEntryMode.manual) ...[
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Route',
              hintText: _selectedHashSize == 1
                  ? 'AA,BB,CC'
                  : _selectedHashSize == 2
                  ? 'AABB,CCDD'
                  : 'AABBCC,DDEEFF',
              helperText:
                  'Enter comma-separated hops. Path byte size comes from global Settings. Colon form like AA:BB is also accepted.',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildPreviewSection(),
        ] else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _resolvePathAutomatically,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Resolve Path'),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: Text(
                  'Tap repeaters on the map to build the path, then review the generated route below.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: mapPoints.length < 2
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Map path builder needs your advertised location, the contact location, and visible repeater locations.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : flutter_map.FlutterMap(
                        options: flutter_map.MapOptions(
                          initialCameraFit: flutter_map.CameraFit.bounds(
                            bounds: flutter_map.LatLngBounds.fromPoints(
                              mapPoints,
                            ),
                            padding: const EdgeInsets.all(32),
                          ),
                        ),
                        children: [
                          flutter_map.TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.meshcore.sar',
                          ),
                          if (routePoints.length >= 2)
                            flutter_map.PolylineLayer(
                              polylines: [
                                flutter_map.Polyline(
                                  points: routePoints,
                                  strokeWidth: 4,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ],
                            ),
                          flutter_map.MarkerLayer(
                            markers: [
                              ...routeCandidates.map((candidate) {
                                final isSelected = _selectedMapHops.any(
                                  (item) =>
                                      item.publicKeyHex ==
                                      candidate.publicKeyHex,
                                );
                                return flutter_map.Marker(
                                  point: LatLng(
                                    candidate.displayLocation!.latitude,
                                    candidate.displayLocation!.longitude,
                                  ),
                                  width: 64,
                                  height: 70,
                                  child: GestureDetector(
                                    onTap: () => _toggleHop(candidate),
                                    child: _RouteMarkerDot(
                                      label: _tokenFor(
                                        candidate,
                                        _selectedHashSize,
                                      ),
                                      color: isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.blueGrey,
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_selectedMapHops.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedMapHops.map((contact) {
                return InputChip(
                  label: Text(contact.displayName),
                  onDeleted: () => _toggleHop(contact),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Generated route',
              helperText: 'Switch to Manual if you want to edit the hop list.',
              errorText: _errorText,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          _buildPreviewSection(),
        ],
      ],
    );
  }

  Widget _buildHistoryTab() {
    final records = List<PathRecord>.from(_pathHistory?.directPaths ?? const [])
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No historical paths for this contact yet.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: records.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final record = records[index];
        final canonicalText = _canonicalRouteFromBytes(
          record.pathBytes,
          hashSize: record.hashSize,
        );
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            title: Text(
              canonicalText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_historySubtitle(record)),
            ),
            trailing: FilledButton.tonal(
              onPressed: () => _applyHistoryRecord(record),
              child: const Text('Use'),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final routeCandidates = _routeCandidates;
    final connectionProvider = context.watch<ConnectionProvider>();
    final selfPoint =
        connectionProvider.deviceInfo.advLat != null &&
            connectionProvider.deviceInfo.advLon != null &&
            !(connectionProvider.deviceInfo.advLat == 0 &&
                connectionProvider.deviceInfo.advLon == 0)
        ? LatLng(
            connectionProvider.deviceInfo.advLat! / 1e6,
            connectionProvider.deviceInfo.advLon! / 1e6,
          )
        : null;
    final recipientLocation = widget.contact.displayLocation;
    final recipientPoint = recipientLocation == null
        ? null
        : LatLng(recipientLocation.latitude, recipientLocation.longitude);
    final routePoints = <LatLng>[
      ...?selfPoint == null ? null : [selfPoint],
      ..._selectedMapHops
          .where((contact) => contact.displayLocation != null)
          .map(
            (contact) => LatLng(
              contact.displayLocation!.latitude,
              contact.displayLocation!.longitude,
            ),
          ),
      ...?recipientPoint == null ? null : [recipientPoint],
    ];
    final mapPoints = <LatLng>[
      ...?selfPoint == null ? null : [selfPoint],
      ...?recipientPoint == null ? null : [recipientPoint],
      ...routeCandidates.map(
        (contact) => LatLng(
          contact.displayLocation!.latitude,
          contact.displayLocation!.longitude,
        ),
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Route for ${widget.contact.displayName}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to build the route, or reuse one from history.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const TabBar(
                tabs: [
                  Tab(text: 'Build'),
                  Tab(text: 'History'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBuilderTab(
                            context,
                            routeCandidates: routeCandidates,
                            mapPoints: mapPoints,
                            routePoints: routePoints,
                          ),
                          const SizedBox(height: 16),
                          _AutomationRoutingInfo(
                            isExpanded: _showRoutingInfo,
                            onToggle: () {
                              setState(() {
                                _showRoutingInfo = !_showRoutingInfo;
                              });
                            },
                            autoRouteRotationEnabled:
                                appProvider.autoRouteRotationEnabled,
                            nearestRelayFallbackEnabled:
                                appProvider.nearestRelayFallbackEnabled,
                            clearPathOnMaxRetry:
                                appProvider.clearPathOnMaxRetry,
                          ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(child: _buildHistoryTab()),
                  ],
                ),
              ),
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                spacing: 8,
                overflowSpacing: 8,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  if (widget.contact.routeHasPath)
                    TextButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop(const ContactRouteDialogResult.clear()),
                      child: const Text('Clear Route'),
                    ),
                  FilledButton(
                    onPressed: _parsedRoute == null
                        ? null
                        : () => Navigator.of(context).pop(
                            ContactRouteDialogResult.setWithFallback(
                              _parsedRoute!,
                              inferredFallbackLocation:
                                  _buildSyntheticFallbackLocation(),
                            ),
                          ),
                    child: const Text('Set Route'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RouteEntryMode { map, manual }

class _RouteMarkerDot extends StatelessWidget {
  final String label;
  final Color color;

  const _RouteMarkerDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Center(
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}

class _AutomationRoutingInfo extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final bool autoRouteRotationEnabled;
  final bool nearestRelayFallbackEnabled;
  final bool clearPathOnMaxRetry;

  const _AutomationRoutingInfo({
    required this.isExpanded,
    required this.onToggle,
    required this.autoRouteRotationEnabled,
    required this.nearestRelayFallbackEnabled,
    required this.clearPathOnMaxRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Automatic direct-send routing',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            Text(
              'Room/contact sends keep one selected path for the whole send chain, retry up to 5 total attempts with 1s, 2s, 4s, and 8s backoff, then try one final nearest repeater if everything else fails.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Public and channel broadcasts are not affected by this automation.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: autoRouteRotationEnabled
                      ? 'Auto route rotation on'
                      : 'Auto route rotation off',
                  icon: Icons.swap_horiz,
                ),
                _InfoChip(
                  label: nearestRelayFallbackEnabled
                      ? 'Nearest repeater fallback on'
                      : 'Nearest repeater fallback off',
                  icon: Icons.router,
                ),
                _InfoChip(
                  label: clearPathOnMaxRetry
                      ? 'Clear path on max retry on'
                      : 'Clear path on max retry off',
                  icon: Icons.route,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Shows retry, rotation, and final repeater fallback behavior.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
