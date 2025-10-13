import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';
import '../providers/contacts_provider.dart';
import '../providers/map_provider.dart';
import '../models/message.dart';
import '../utils/sar_message_parser.dart';

class MessagesTab extends StatelessWidget {
  final VoidCallback onNavigateToMap;

  const MessagesTab({super.key, required this.onNavigateToMap});

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagesProvider>(
      builder: (context, messagesProvider, child) {
        final messages = messagesProvider.getRecentMessages(count: 100);

        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.message_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No messages yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Connect to a device to start receiving messages',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(8),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _MessageBubble(
              message: message,
              onTap: message.isSarMarker && message.sarGpsCoordinates != null
                  ? () {
                      final mapProvider = context.read<MapProvider>();
                      mapProvider.navigateToLocation(
                        location: message.sarGpsCoordinates!,
                        zoom: 15.0,
                      );
                      onNavigateToMap();
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onTap;

  const _MessageBubble({
    required this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSarMarker = message.isSarMarker;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSarMarker
              ? _getSarMarkerColor(context)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: isSarMarker
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Sender and time
            Row(
              children: [
                if (message.isChannelMessage)
                  const Icon(Icons.tag, size: 16)
                else
                  const Icon(Icons.person, size: 16),
                const SizedBox(width: 4),
                Text(
                  message.displaySender,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                if (isSarMarker)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SAR',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  message.timeAgo,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // SAR marker content
            if (isSarMarker && message.sarMarkerType != null) ...[
              Row(
                children: [
                  Text(
                    message.sarMarkerType!.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.sarMarkerType!.displayName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        if (message.sarGpsCoordinates != null)
                          Text(
                            '${message.sarGpsCoordinates!.latitude.toStringAsFixed(5)}, ${message.sarGpsCoordinates!.longitude.toStringAsFixed(5)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to view on map',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ]
            // Regular message content
            else
              Text(
                message.text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
      ),
    );
  }

  Color _getSarMarkerColor(BuildContext context) {
    return Theme.of(context).colorScheme.primaryContainer;
  }
}
