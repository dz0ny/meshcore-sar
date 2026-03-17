import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../l10n/app_localizations.dart';
import '../common/contact_avatar.dart';

/// Bottom sheet for selecting message recipient (channel, contact, or room)
class RecipientSelectorSheet extends StatefulWidget {
  final List<Contact> contacts;
  final List<Contact> rooms;
  final List<Contact> channels;
  final int unreadCount;
  final Map<String, int> unreadCountsByPublicKey;
  final String? currentDestinationType;
  final String? currentRecipientPublicKey;
  final bool showAllOption;
  final Function(String type, Contact? recipient) onSelect;

  const RecipientSelectorSheet({
    super.key,
    required this.contacts,
    required this.rooms,
    required this.channels,
    required this.unreadCount,
    required this.unreadCountsByPublicKey,
    this.currentDestinationType,
    this.currentRecipientPublicKey,
    this.showAllOption = true,
    required this.onSelect,
  });

  @override
  State<RecipientSelectorSheet> createState() => _RecipientSelectorSheetState();
}

class _RecipientSelectorSheetState extends State<RecipientSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Contact> _filterContacts(List<Contact> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    final query = _searchQuery.toLowerCase();
    return contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      return name.contains(query);
    }).toList();
  }

  bool _isSelected(String type, Contact? contact) {
    if (widget.currentDestinationType != type) return false;
    if (contact == null) return widget.currentRecipientPublicKey == null;
    return contact.publicKeyHex == widget.currentRecipientPublicKey;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredContacts = _filterContacts(widget.contacts);
    final filteredRooms = _filterContacts(widget.rooms);
    final filteredChannels = _filterContacts(widget.channels);
    final showChannelsSection = widget.channels.isNotEmpty;
    final showContactsSection = widget.contacts.isNotEmpty;
    final showRoomsSection = widget.rooms.isNotEmpty;
    final showAnyRecipients =
        showChannelsSection || showContactsSection || showRoomsSection;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  l10n.selectRecipient,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  tooltip: l10n.close,
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchRecipients,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Recipients list
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                if (widget.showAllOption) ...[
                  _buildOptionTile(
                    context: context,
                    icon: Icons.all_inbox,
                    title: l10n.showAll,
                    subtitle: l10n.allMessages,
                    unreadCount: widget.unreadCount,
                    isSelected: _isSelected('all', null),
                    onTap: () {
                      widget.onSelect('all', null);
                      Navigator.pop(context);
                    },
                  ),
                  if (showAnyRecipients) const Divider(),
                ],
                // Channels section
                if (showChannelsSection) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      l10n.channels,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (filteredChannels.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        l10n.noChannelsFound,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...filteredChannels.map((channel) {
                      return _buildRecipientTile(
                        context: context,
                        contact: channel,
                        title: channel.getLocalizedDisplayName(context),
                        subtitle: channel.isPublicChannel
                            ? l10n.broadcastToAllNearby
                            : '${l10n.channel} ${channel.publicKey[1]}', // Show slot number
                        unreadCount:
                            widget.unreadCountsByPublicKey[channel
                                .publicKeyHex] ??
                            0,
                        isSelected: _isSelected('channel', channel),
                        onTap: () {
                          widget.onSelect('channel', channel);
                          Navigator.pop(context);
                        },
                      );
                    }),
                ],

                if (showChannelsSection &&
                    (showContactsSection || showRoomsSection))
                  const Divider(),

                // Contacts section
                if (showContactsSection) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      l10n.contacts,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (filteredContacts.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        l10n.noContactsFound,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...filteredContacts.map((contact) {
                      return _buildRecipientTile(
                        context: context,
                        contact: contact,
                        title: contact.displayName,
                        subtitle: contact.publicKeyShort,
                        unreadCount:
                            widget.unreadCountsByPublicKey[contact
                                .publicKeyHex] ??
                            0,
                        isSelected: _isSelected('contact', contact),
                        onTap: () {
                          widget.onSelect('contact', contact);
                          Navigator.pop(context);
                        },
                      );
                    }),
                ],

                if (showContactsSection && showRoomsSection) const Divider(),

                // Rooms section
                if (showRoomsSection) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Text(
                      l10n.rooms,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (filteredRooms.isEmpty)
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        l10n.noRoomsFound,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ...filteredRooms.map((room) {
                      return _buildRecipientTile(
                        context: context,
                        contact: room,
                        title: room.displayName,
                        subtitle: room.publicKeyShort,
                        unreadCount:
                            widget.unreadCountsByPublicKey[room.publicKeyHex] ??
                            0,
                        isSelected: _isSelected('room', room),
                        onTap: () {
                          widget.onSelect('room', room);
                          Navigator.pop(context);
                        },
                      );
                    }),
                ],

                // Empty state
                if (!showAnyRecipients) ...[
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Theme.of(context).disabledColor,
                        ),
                        SizedBox(height: 16),
                        Text(
                          l10n.noRecipientsAvailable,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientTile({
    required BuildContext context,
    required Contact contact,
    required String title,
    required String subtitle,
    required int unreadCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: ContactAvatar(contact: contact, radius: 20, displayName: title),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace').copyWith(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
      ),
      trailing: _buildTrailing(
        context,
        unreadCount: unreadCount,
        isSelected: isSelected,
      ),
      onTap: onTap,
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int unreadCount,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, fontFamily: 'monospace').copyWith(
          color: Theme.of(
            context,
          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
        ),
      ),
      trailing: _buildTrailing(
        context,
        unreadCount: unreadCount,
        isSelected: isSelected,
      ),
      onTap: onTap,
    );
  }

  Widget? _buildTrailing(
    BuildContext context, {
    required int unreadCount,
    required bool isSelected,
  }) {
    if (unreadCount <= 0 && !isSelected) {
      return null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unreadCount > 0)
          Container(
            key: Key('unread-badge-$unreadCount'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (unreadCount > 0 && isSelected) const SizedBox(width: 8),
        if (isSelected)
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.primary,
          ),
      ],
    );
  }
}
