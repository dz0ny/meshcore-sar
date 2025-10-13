import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/connection_provider.dart';
import '../models/contact.dart';

class ContactsTab extends StatelessWidget {
  const ContactsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ContactsProvider>(
      builder: (context, contactsProvider, child) {
        final chatContacts = contactsProvider.chatContacts;
        final repeaters = contactsProvider.repeaters;
        final rooms = contactsProvider.rooms;

        if (contactsProvider.contacts.isEmpty) {
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
                  'No contacts yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to a device and refresh to load contacts',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            // Team Members (Chat contacts)
            if (chatContacts.isNotEmpty) ...[
              _SectionHeader(
                title: 'Team Members',
                count: chatContacts.length,
                icon: Icons.people,
              ),
              ...chatContacts.map((contact) => _ContactTile(contact: contact)),
              const Divider(height: 32),
            ],

            // Repeaters
            if (repeaters.isNotEmpty) ...[
              _SectionHeader(
                title: 'Repeaters',
                count: repeaters.length,
                icon: Icons.router,
              ),
              ...repeaters.map((contact) => _ContactTile(contact: contact)),
              const Divider(height: 32),
            ],

            // Rooms/Channels
            if (rooms.isNotEmpty) ...[
              _SectionHeader(
                title: 'Rooms/Channels',
                count: rooms.length,
                icon: Icons.tag,
              ),
              ...rooms.map((contact) => _ContactTile(contact: contact)),
            ],
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
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
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;

  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final hasTelemetry = contact.telemetry != null && contact.telemetry!.isRecent;
    final battery = contact.displayBattery;
    final location = contact.displayLocation;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(contact.type),
          child: Icon(
            _getTypeIcon(contact.type),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                contact.advName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Battery indicator
            if (battery != null) ...[
              Icon(
                _getBatteryIcon(battery),
                size: 16,
                color: _getBatteryColor(battery),
              ),
              const SizedBox(width: 4),
              Text(
                '${battery.round()}%',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            // Type and last seen
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(contact.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    contact.type.displayName,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: contact.isRecentlySeen ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  contact.timeSinceLastSeen,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Telemetry info
            Row(
              children: [
                if (hasTelemetry)
                  const Icon(Icons.sensors, size: 12, color: Colors.green)
                else
                  const Icon(Icons.sensors_off, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                if (location != null)
                  Expanded(
                    child: Text(
                      'GPS: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.labelSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  Text(
                    'No GPS data',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          onPressed: () {
            final connectionProvider = context.read<ConnectionProvider>();
            connectionProvider.requestTelemetry(contact.publicKey);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Requesting telemetry from ${contact.advName}'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Request telemetry',
        ),
        onTap: () => _showContactDetails(context, contact),
      ),
    );
  }

  void _showContactDetails(BuildContext context, Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.advName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Type', contact.type.displayName),
              _DetailRow('Public Key', contact.publicKeyShort),
              _DetailRow('Last Seen', contact.timeSinceLastSeen),
              const Divider(),
              if (contact.displayLocation != null) ...[
                const Text('Location:', style: TextStyle(fontWeight: FontWeight.bold)),
                _DetailRow('Latitude', contact.displayLocation!.latitude.toStringAsFixed(6)),
                _DetailRow('Longitude', contact.displayLocation!.longitude.toStringAsFixed(6)),
                const Divider(),
              ],
              if (contact.telemetry != null) ...[
                const Text('Telemetry:', style: TextStyle(fontWeight: FontWeight.bold)),
                if (contact.telemetry!.batteryPercentage != null)
                  _DetailRow('Battery', '${contact.telemetry!.batteryPercentage!.toStringAsFixed(1)}%'),
                if (contact.telemetry!.temperature != null)
                  _DetailRow('Temperature', '${contact.telemetry!.temperature!.toStringAsFixed(1)}°C'),
                _DetailRow('Updated', contact.telemetry!.isRecent ? 'Recently' : 'Stale'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.chat:
        return Icons.person;
      case ContactType.repeater:
        return Icons.router;
      case ContactType.room:
        return Icons.tag;
      default:
        return Icons.help;
    }
  }

  Color _getTypeColor(ContactType type) {
    switch (type) {
      case ContactType.chat:
        return Colors.blue;
      case ContactType.repeater:
        return Colors.green;
      case ContactType.room:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getBatteryIcon(double percentage) {
    if (percentage > 80) return Icons.battery_full;
    if (percentage > 50) return Icons.battery_5_bar;
    if (percentage > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }

  Color _getBatteryColor(double percentage) {
    if (percentage > 50) return Colors.green;
    if (percentage > 20) return Colors.orange;
    return Colors.red;
  }
}
