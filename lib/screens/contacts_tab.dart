import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/app_localizations.dart';
import '../models/contact.dart';
import '../providers/contacts_provider.dart';
import '../providers/app_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/messages_provider.dart';
import '../services/message_destination_preferences.dart';
import '../utils/contact_grouping.dart';
import '../utils/avatar_label_helper.dart';
import '../widgets/common/contact_avatar.dart';
import '../widgets/contacts/contact_tile.dart';
import '../widgets/contacts/add_channel_dialog.dart';

class ContactsTab extends StatefulWidget {
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const ContactsTab({
    super.key,
    this.onNavigateToMap,
    this.onNavigateToMessages,
  });

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  Position? _currentPosition;
  final Set<String> _resolvingAdvertKeys = <String>{};
  final Map<ContactSection, ContactSortMode> _sortModes = {
    ContactSection.teamMembers: ContactSortMode.lastSeen,
    ContactSection.repeaters: ContactSortMode.lastSeen,
    ContactSection.rooms: ContactSortMode.lastSeen,
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    // Mark all contacts as viewed when tab is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsProvider>().markAllAsViewed();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Silently fail if location not available
      debugPrint('Failed to get location: $e');
    }
  }

  Future<void> _handleRefresh() async {
    if (!mounted) return;
    final appProvider = context.read<AppProvider>();
    await appProvider.refresh();
    // Also refresh location
    if (!mounted) return;
    await _getCurrentLocation();
  }

  Future<void> _handleResolveAdvert(PendingAdvert advert) async {
    final keyHex = advert.publicKeyHex;
    if (_resolvingAdvertKeys.contains(keyHex)) return;

    setState(() {
      _resolvingAdvertKeys.add(keyHex);
    });

    try {
      await context.read<ConnectionProvider>().getContact(advert.publicKey);
    } finally {
      if (mounted) {
        setState(() {
          _resolvingAdvertKeys.remove(keyHex);
        });
      }
    }
  }

  /// Calculate distance between two points in meters
  double _calculateDistanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371000; // Earth's radius in meters
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else if (meters < 10000) {
      return '${(meters / 1000).toStringAsFixed(2)}km';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatRelativeTime(BuildContext context, DateTime when) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) return l10n.justNow;
    if (diff.inMinutes < 60) return l10n.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l10n.hoursAgo(diff.inHours);
    return l10n.daysAgo(diff.inDays);
  }

  List<Contact> _sortContacts(List<Contact> contacts, ContactSection section) {
    final sorted = List<Contact>.from(contacts);
    if (section == ContactSection.channels) {
      sorted.sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
      return sorted;
    }

    final sortMode = _sortModes[section] ?? ContactSortMode.lastSeen;

    sorted.sort((a, b) {
      if (sortMode == ContactSortMode.distance) {
        final distanceA = _distanceFromCurrentPosition(a);
        final distanceB = _distanceFromCurrentPosition(b);

        if (distanceA != null && distanceB != null) {
          final distanceCompare = distanceA.compareTo(distanceB);
          if (distanceCompare != 0) return distanceCompare;
        } else if (distanceA != null) {
          return -1;
        } else if (distanceB != null) {
          return 1;
        }
      }

      return b.lastSeenTime.compareTo(a.lastSeenTime);
    });

    return sorted;
  }

  double? _distanceFromCurrentPosition(Contact contact) {
    final currentPosition = _currentPosition;
    final contactLocation = contact.displayLocation;
    if (currentPosition == null || contactLocation == null) {
      return null;
    }

    return _calculateDistanceInMeters(
      currentPosition.latitude,
      currentPosition.longitude,
      contactLocation.latitude,
      contactLocation.longitude,
    );
  }

  /// Show the add channel dialog
  Future<void> _showAddChannelDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    await showDialog(
      context: context,
      builder: (context) => AddChannelDialog(
        onCreateChannel: (name, secret) async {
          final connectionProvider = context.read<ConnectionProvider>();
          try {
            await connectionProvider.createChannel(
              channelName: name,
              channelSecret: secret,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.channelCreatedSuccessfully),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.channelCreationFailed(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
            rethrow; // Re-throw to let dialog handle the error state
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<ContactsProvider>(
        builder: (context, contactsProvider, child) {
          final messagesProvider = context.watch<MessagesProvider>();
          final chatContacts = _sortContacts(
            contactsProvider.chatContacts,
            ContactSection.teamMembers,
          );
          final repeaters = _sortContacts(
            contactsProvider.repeaters,
            ContactSection.repeaters,
          );
          final rooms = _sortContacts(
            contactsProvider.rooms,
            ContactSection.rooms,
          );
          final channels = _sortContacts(
            contactsProvider.channels,
            ContactSection.channels,
          );
          final pendingAdverts = contactsProvider.pendingAdverts;

          // Check if there are any displayable contacts
          final hasDisplayableContacts =
              chatContacts.isNotEmpty ||
              repeaters.isNotEmpty ||
              rooms.isNotEmpty ||
              channels.isNotEmpty ||
              pendingAdverts.isNotEmpty;

          if (!hasDisplayableContacts) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.contacts_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noContactsYet,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.connectToDeviceToLoadContacts,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Pending adverts (public key only; quick resolve)
                if (pendingAdverts.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.pending,
                    count: pendingAdverts.length,
                    icon: Icons.person_add_alt_1,
                  ),
                  ...pendingAdverts.map(
                    (advert) => _PendingAdvertTile(
                      advert: advert,
                      subtitle:
                          '${l10n.publicKey}: ${advert.publicKeyHex}\n${l10n.lastSeen}: ${_formatRelativeTime(context, advert.receivedAt)}',
                      isResolving: _resolvingAdvertKeys.contains(
                        advert.publicKeyHex,
                      ),
                      onResolve: () => _handleResolveAdvert(advert),
                    ),
                  ),
                  const Divider(height: 32),
                ],

                // Team Members (Chat contacts)
                if (chatContacts.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.teamMembers,
                    count: chatContacts.length,
                    icon: Icons.people,
                    trailing: _buildSortMenu(
                      context,
                      ContactSection.teamMembers,
                    ),
                  ),
                  ..._buildContactSectionItems(chatContacts),
                  const Divider(height: 32),
                ],

                // Repeaters
                if (repeaters.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.repeaters,
                    count: repeaters.length,
                    icon: Icons.router,
                    trailing: _buildSortMenu(context, ContactSection.repeaters),
                  ),
                  ..._buildContactSectionItems(repeaters),
                  const Divider(height: 32),
                ],

                // Rooms
                if (rooms.isNotEmpty) ...[
                  _SectionHeader(
                    title: l10n.rooms,
                    count: rooms.length,
                    icon: Icons.tag,
                    trailing: _buildSortMenu(context, ContactSection.rooms),
                  ),
                  ..._buildContactSectionItems(rooms),
                  const Divider(height: 32),
                ],

                // Channels (visible in both simple and advanced mode)
                _SectionHeader(
                  title: l10n.channels,
                  count: channels.length,
                  icon: Icons.broadcast_on_personal,
                ),
                if (channels.isNotEmpty) ...[
                  ...channels.map(
                    (channel) => _ChannelActivityCard(
                      channel: channel,
                      messagesProvider: messagesProvider,
                      contactsProvider: contactsProvider,
                      onNavigateToMessages: widget.onNavigateToMessages,
                    ),
                  ),
                ],

                // Add Channel Button (visible in both simple and advanced mode, only show when connected)
                if (context.watch<ConnectionProvider>().deviceInfo.isConnected)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () => _showAddChannelDialog(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: Text(l10n.addChannel),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildContactSectionItems(List<Contact> contacts) {
    final items = ContactGrouping.buildItemsFromSorted(contacts);

    return items.map((item) {
      if (item.isGroup) {
        return _InferredContactGroupCard(
          label: item.group!.label,
          contacts: item.group!.contacts,
          currentPosition: _currentPosition,
          calculateDistance: _calculateDistanceInMeters,
          formatDistance: _formatDistance,
          onNavigateToMap: widget.onNavigateToMap,
          onNavigateToMessages: widget.onNavigateToMessages,
        );
      }

      return ContactTile(
        contact: item.contact!,
        currentPosition: _currentPosition,
        calculateDistance: _calculateDistanceInMeters,
        formatDistance: _formatDistance,
        onNavigateToMap: widget.onNavigateToMap,
        onNavigateToMessages: widget.onNavigateToMessages,
      );
    }).toList();
  }

  Widget _buildSortMenu(BuildContext context, ContactSection section) {
    final l10n = AppLocalizations.of(context)!;
    final selectedMode = _sortModes[section] ?? ContactSortMode.lastSeen;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<ContactSortMode>(
      tooltip: 'Sort',
      initialValue: selectedMode,
      onSelected: (sortMode) {
        setState(() {
          _sortModes[section] = sortMode;
        });
      },
      itemBuilder: (context) => [
        PopupMenuItem<ContactSortMode>(
          value: ContactSortMode.lastSeen,
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                size: 18,
                color: selectedMode == ContactSortMode.lastSeen
                    ? colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Text(l10n.lastSeen),
            ],
          ),
        ),
        PopupMenuItem<ContactSortMode>(
          value: ContactSortMode.distance,
          child: Row(
            children: [
              Icon(
                Icons.near_me,
                size: 18,
                color: selectedMode == ContactSortMode.distance
                    ? colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 8),
              Text(l10n.distance),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          Icons.more_horiz,
          size: 18,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

enum ContactSortMode { lastSeen, distance }

enum ContactSection { teamMembers, repeaters, rooms, channels }

class _PendingAdvertTile extends StatelessWidget {
  final PendingAdvert advert;
  final String subtitle;
  final bool isResolving;
  final VoidCallback onResolve;

  const _PendingAdvertTile({
    required this.advert,
    required this.subtitle,
    required this.isResolving,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.campaign_outlined)),
        title: Text(
          advert.shortDisplayKey,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: isResolving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.person_add_alt_1),
                tooltip: 'Quick add',
                onPressed: onResolve,
              ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),
          if (trailing != null) ...[const Spacer(), trailing!],
        ],
      ),
    );
  }
}

class _InferredContactGroupCard extends StatelessWidget {
  final String label;
  final List<Contact> contacts;
  final Position? currentPosition;
  final double Function(double, double, double, double) calculateDistance;
  final String Function(double) formatDistance;
  final VoidCallback? onNavigateToMap;
  final VoidCallback? onNavigateToMessages;

  const _InferredContactGroupCard({
    required this.label,
    required this.contacts,
    required this.currentPosition,
    required this.calculateDistance,
    required this.formatDistance,
    required this.onNavigateToMap,
    required this.onNavigateToMessages,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          initiallyExpanded: false,
          leading: Icon(
            Icons.folder_copy_outlined,
            size: 18,
            color: colorScheme.primary,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  contacts.length.toString(),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
          children: [
            ...contacts.map(
              (contact) => ContactTile(
                contact: contact,
                currentPosition: currentPosition,
                calculateDistance: calculateDistance,
                formatDistance: formatDistance,
                onNavigateToMap: onNavigateToMap,
                onNavigateToMessages: onNavigateToMessages,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelActivityCard extends StatelessWidget {
  final Contact channel;
  final MessagesProvider messagesProvider;
  final ContactsProvider contactsProvider;
  final VoidCallback? onNavigateToMessages;

  const _ChannelActivityCard({
    required this.channel,
    required this.messagesProvider,
    required this.contactsProvider,
    required this.onNavigateToMessages,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final channelIdx = channel.publicKey.length > 1 ? channel.publicKey[1] : 0;
    final channelMessages = messagesProvider.getMessagesForChannel(channelIdx)
      ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    final participantNames = <String>[];
    for (final message in channelMessages) {
      final senderName = message.senderName?.trim();
      if (senderName == null || senderName.isEmpty) continue;
      if (!participantNames.contains(senderName)) {
        participantNames.add(senderName);
      }
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.tertiaryContainer.withValues(alpha: 0.45),
          ],
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await MessageDestinationPreferences.setDestination(
              MessageDestinationPreferences.destinationTypeChannel,
              recipientPublicKey: channel.publicKeyHex,
            );
            messagesProvider.navigateToDestination(
              MessageDestinationPreferences.destinationTypeChannel,
              recipientPublicKeyHex: channel.publicKeyHex,
            );
            onNavigateToMessages?.call();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ContactAvatar(contact: channel, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              height: 1.05,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (participantNames.isNotEmpty)
                        _ExpandableParticipantStack(
                          names: participantNames,
                          contactForName: _findParticipantContact,
                        )
                      else
                        Text(
                          'No recent chatters',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _MetricChip(
                            icon: Icons.forum_outlined,
                            label: '${channelMessages.length}',
                            helper: 'messages',
                          ),
                          _MetricChip(
                            icon: Icons.group_outlined,
                            label: '${participantNames.length}',
                            helper: 'active',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Contact? _findParticipantContact(String name) {
    for (final contact in contactsProvider.contacts) {
      if (!contact.isChannel && contact.advName == name) {
        return contact;
      }
    }
    return null;
  }
}

class _ExpandableParticipantStack extends StatefulWidget {
  final List<String> names;
  final Contact? Function(String name) contactForName;

  const _ExpandableParticipantStack({
    required this.names,
    required this.contactForName,
  });

  @override
  State<_ExpandableParticipantStack> createState() =>
      _ExpandableParticipantStackState();
}

class _ExpandableParticipantStackState
    extends State<_ExpandableParticipantStack> {
  bool _expanded = false;
  static const int _collapsedVisibleCount = 4;

  @override
  Widget build(BuildContext context) {
    final hasOverflow = widget.names.length > _collapsedVisibleCount;
    final visibleNames = _expanded
        ? widget.names
        : widget.names.take(_collapsedVisibleCount).toList();
    final overflowCount = _expanded
        ? 0
        : widget.names.length - visibleNames.length;
    final spacing = _expanded ? 20.0 : 16.0;
    const avatarSize = 24.0;
    final itemCount = visibleNames.length + (overflowCount > 0 ? 1 : 0);
    final width = itemCount == 0 ? 0.0 : avatarSize + (itemCount - 1) * spacing;

    return GestureDetector(
      onTap: hasOverflow
          ? () {
              setState(() {
                _expanded = !_expanded;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        height: avatarSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < visibleNames.length; i++)
              Positioned(
                left: i * spacing,
                top: 0,
                child: _ParticipantAvatar(
                  name: visibleNames[i],
                  contact: widget.contactForName(visibleNames[i]),
                ),
              ),
            if (overflowCount > 0)
              Positioned(
                left: visibleNames.length * spacing,
                top: 0,
                child: _OverflowAvatar(count: overflowCount),
              ),
          ],
        ),
      ),
    );
  }
}

class _OverflowAvatar extends StatelessWidget {
  final int count;

  const _OverflowAvatar({required this.count});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _ParticipantAvatar extends StatelessWidget {
  final String name;
  final Contact? contact;
  static const double _size = 24;

  const _ParticipantAvatar({required this.name, required this.contact});

  @override
  Widget build(BuildContext context) {
    if (contact != null) {
      final surfaceColor = Theme.of(context).colorScheme.surface;
      return SizedBox(
        width: _size,
        height: _size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: surfaceColor, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: ClipOval(child: ContactAvatar(contact: contact!, radius: 8)),
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        AvatarLabelHelper.buildLabel(name),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onTertiaryContainer,
          fontSize: 9,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String helper;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 4),
          Text(
            helper,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
