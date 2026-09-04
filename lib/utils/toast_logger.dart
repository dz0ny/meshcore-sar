import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/messages_provider.dart';

/// Global messenger key wired to [MaterialApp.scaffoldMessengerKey] in main.dart
/// so toasts can be shown even when the calling context has no Scaffold.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Toast logger utility - shows a floating SnackBar and records a system
/// message in the channels tab history
class ToastLogger {
  /// Log an info message
  static void info(BuildContext context, String message) {
    _log(context, message, 'info');
  }

  /// Log a success message
  static void success(BuildContext context, String message) {
    _log(context, message, 'success');
  }

  /// Log a warning message
  static void warning(BuildContext context, String message) {
    _log(context, message, 'warning');
  }

  /// Log an error message
  static void error(BuildContext context, String message) {
    _log(context, message, 'error');
  }

  /// Internal method to show a snackbar and log a system message
  static void _log(BuildContext context, String message, String level) {
    _showSnackBar(context, message, level);

    // Keep recording as a system message (feeds history/stats)
    try {
      final messagesProvider = context.read<MessagesProvider>();
      messagesProvider.logSystemMessage(text: message, level: level);
    } catch (e) {
      // Provider not available - snackbar above is still shown
      debugPrint('[$level] $message');
    }
  }

  static void _showSnackBar(BuildContext context, String message, String level) {
    final messenger =
        rootScaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      debugPrint('[$level] $message');
      return;
    }

    Color? backgroundColor;
    switch (level) {
      case 'error':
        backgroundColor = context.mounted
            ? Theme.of(context).colorScheme.error
            : Colors.red;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        break;
      case 'success':
        backgroundColor = Colors.green;
        break;
      default:
        backgroundColor = null; // default surface color
    }

    // Don't queue rapid toasts behind each other
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: Duration(seconds: level == 'error' ? 4 : 3),
      ),
    );
  }
}
