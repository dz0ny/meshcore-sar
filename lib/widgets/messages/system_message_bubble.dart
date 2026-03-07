import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../utils/message_extensions.dart';

class SystemMessageBubble extends StatelessWidget {
  final Message message;

  const SystemMessageBubble({super.key, required this.message});

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue.shade300;
    }
  }

  IconData _getLevelIcon(String? level) {
    switch (level?.toLowerCase()) {
      case 'success':
        return Icons.check_circle_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'error':
        return Icons.error_outline;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final level = message.senderName ?? 'info';
    final levelColor = _getLevelColor(level);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: levelColor.withValues(alpha: isDarkMode ? 0.18 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: levelColor.withValues(alpha: isDarkMode ? 0.3 : 0.16),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(_getLevelIcon(level), size: 16, color: levelColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          level.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: levelColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ),
                      Text(
                        message.getLocalizedTimeAgo(context),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.3,
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
