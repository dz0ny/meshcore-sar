import 'package:flutter/material.dart';

import '../../models/contact.dart';
import '../../services/trail_color_service.dart';
import '../../utils/avatar_label_helper.dart';

class ContactAvatar extends StatelessWidget {
  final Contact contact;
  final double radius;
  final String? displayName;

  const ContactAvatar({
    super.key,
    required this.contact,
    this.radius = 20,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _getBackgroundColor(context);
    final foregroundColor = _getForegroundColor(backgroundColor);
    final emoji = contact.roleEmoji;

    if (_showsLeadingEmoji && emoji != null && emoji.isNotEmpty) {
      return _buildAvatarFrame(
        backgroundColor: backgroundColor,
        child: Text(emoji, style: TextStyle(fontSize: radius * 1.05)),
      );
    }

    if (_shouldUseLabelFallback) {
      return _buildAvatarFrame(
        backgroundColor: backgroundColor,
        child: Text(
          AvatarLabelHelper.buildLabel(displayName ?? contact.displayName),
          style: TextStyle(
            color: foregroundColor,
            fontSize: radius * 0.68,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      );
    }

    return _buildAvatarFrame(
      backgroundColor: backgroundColor,
      child: Icon(
        _getTypeIcon(contact.type),
        color: foregroundColor,
        size: radius,
      ),
    );
  }

  Widget _buildAvatarFrame({
    required Color backgroundColor,
    required Widget child,
  }) {
    if (_usesSquareShape) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius * 0.6),
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: child,
    );
  }

  bool get _shouldUseLabelFallback =>
      contact.type == ContactType.chat ||
      contact.type == ContactType.channel ||
      contact.type == ContactType.room;

  bool get _usesSquareShape =>
      contact.type == ContactType.channel || contact.type == ContactType.room;

  bool get _showsLeadingEmoji {
    final emoji = contact.roleEmoji;
    if (emoji == null || emoji.isEmpty) return false;

    final effectiveName = (displayName ?? contact.displayName).trimLeft();
    return effectiveName.startsWith(emoji);
  }

  Color _getBackgroundColor(BuildContext context) {
    if (_shouldUseLabelFallback || _showsLeadingEmoji) {
      return TrailColorService.getTrailColor(contact);
    }

    switch (contact.type) {
      case ContactType.none:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case ContactType.chat:
        return Colors.blue;
      case ContactType.repeater:
        return Colors.orange;
      case ContactType.room:
        return Colors.purple;
      case ContactType.sensor:
        return Colors.green;
      case ContactType.channel:
        return Colors.teal;
    }
  }

  Color _getForegroundColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) ==
            Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  IconData _getTypeIcon(ContactType type) {
    switch (type) {
      case ContactType.none:
        return Icons.help_outline;
      case ContactType.chat:
        return Icons.person;
      case ContactType.repeater:
        return Icons.router;
      case ContactType.room:
        return Icons.meeting_room;
      case ContactType.sensor:
        return Icons.sensors;
      case ContactType.channel:
        return Icons.public;
    }
  }
}
