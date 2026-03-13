import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/message.dart';
import '../common/bidirectional_refresh.dart';
import '../../widgets/messages/message_bubble.dart';

class MessagesContent extends StatelessWidget {
  static const double defaultPadding = 8;

  final List<Message> messages;
  final ScrollController scrollController;
  final String? highlightedMessageId;
  final double bottomContentPadding;
  final Future<void> Function() onRefresh;
  final VoidCallback? onNavigateToMap;
  final ValueChanged<Message>? onMessageTap;
  final ValueChanged<Message>? onReplyToMessage;

  const MessagesContent({
    super.key,
    required this.messages,
    required this.scrollController,
    required this.highlightedMessageId,
    this.bottomContentPadding = 0,
    required this.onRefresh,
    this.onNavigateToMap,
    this.onMessageTap,
    this.onReplyToMessage,
  });

  @override
  Widget build(BuildContext context) {
    const scrollPhysics = BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );

    return BidirectionalRefresh(
      onRefresh: onRefresh,
      child: messages.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: scrollPhysics,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
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
                          AppLocalizations.of(context)!.noMessagesYet,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.pullDownToSync,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : ListView.builder(
              controller: scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: scrollPhysics,
              reverse: true,
              padding: EdgeInsets.fromLTRB(
                defaultPadding,
                defaultPadding,
                defaultPadding,
                defaultPadding + bottomContentPadding,
              ),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                return MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  isHighlighted: message.id == highlightedMessageId,
                  onNavigateToMap: onNavigateToMap,
                  onTap: onMessageTap == null
                      ? null
                      : () => onMessageTap!(message),
                  onReply: onReplyToMessage == null
                      ? null
                      : () => onReplyToMessage!(message),
                );
              },
            ),
    );
  }
}
