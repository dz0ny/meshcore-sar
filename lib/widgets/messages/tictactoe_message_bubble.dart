import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/contact.dart';
import '../../models/message.dart';
import '../../providers/connection_provider.dart';
import '../../providers/contacts_provider.dart';
import '../../providers/messages_provider.dart';
import '../../utils/tictactoe_message_parser.dart';
import '../../utils/toast_logger.dart';
import '../../l10n/app_localizations.dart';

class TicTacToeMessageBubble extends StatelessWidget {
  final Message message;
  final bool isSentByMe;

  const TicTacToeMessageBubble({
    super.key,
    required this.message,
    required this.isSentByMe,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final event = TicTacToeMessageParser.tryParse(message.text);
    if (event == null) {
      return const SizedBox.shrink();
    }

    final conn = context.watch<ConnectionProvider>();
    final contacts = context.read<ContactsProvider>();
    final messages = context.watch<MessagesProvider>().messages;
    final selfKey = conn.deviceInfo.publicKey;
    if (selfKey == null || selfKey.length < 6) {
      return Text(AppLocalizations.of(context)!.tictactoeUnavailable);
    }

    final selfKey6 = _key6Hex(selfKey);
    final opponent = _resolveOpponentContact(
      message: message,
      contactsProvider: contacts,
      isSentByMe: isSentByMe,
    );
    if (opponent == null) {
      return Text(AppLocalizations.of(context)!.tictactoeOpponentUnknown);
    }
    final opponentKey6 = _key6Hex(opponent.publicKey);

    final gameEvents = <TicTacToeEvent>[];
    TicTacToeEvent? start;
    for (final m in messages) {
      if (!m.isContactMessage) continue;
      final parsed = TicTacToeMessageParser.tryParse(m.text);
      if (parsed == null || parsed.gameId != event.gameId) continue;
      if (!_isSameDmThread(
        message: m,
        selfKey: selfKey,
        opponentKey6: opponentKey6,
      )) {
        continue;
      }
      if (parsed.type == TicTacToeEventType.start) {
        start ??= parsed;
      } else {
        gameEvents.add(parsed);
      }
    }

    start ??= event.type == TicTacToeEventType.start ? event : null;
    if (start == null) {
      return Text(AppLocalizations.of(context)!.tictactoeWaitingForStart);
    }

    final xPlayer = start.playerKey6;
    final oPlayer = xPlayer == selfKey6 ? opponentKey6 : selfKey6;
    final state = buildTicTacToeState(
      gameId: event.gameId,
      xPlayerKey6: xPlayer,
      oPlayerKey6: oPlayer,
      events: gameEvents,
    );

    final mySymbol = selfKey6 == state.xPlayerKey6 ? 'X' : 'O';
    final isMyTurn = !state.isFinished && state.nextSymbol == mySymbol;
    final titleColor = isSentByMe
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;
    final statusColor = isSentByMe
        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.85)
        : colorScheme.onSurface.withValues(alpha: 0.85);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 230),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tic-Tac-Toe · Game ${state.gameId}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 8),
          _BoardGrid(
            board: state.board,
            enabled: isMyTurn,
            isSentByMe: isSentByMe,
            onTapCell: (idx) => _onCellTap(
              context: context,
              idx: idx,
              state: state,
              selfKey6: selfKey6,
              opponent: opponent,
              connectionProvider: conn,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusText(state: state, mySymbol: mySymbol),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }

  Future<void> _onCellTap({
    required BuildContext context,
    required int idx,
    required TicTacToeGameState state,
    required String selfKey6,
    required Contact opponent,
    required ConnectionProvider connectionProvider,
  }) async {
    if (idx < 0 || idx > 8 || state.board[idx] != null) return;
    if (!connectionProvider.deviceInfo.isConnected) {
      ToastLogger.error(context, 'Not connected to device');
      return;
    }

    final messagesProvider = context.read<MessagesProvider>();
    final text = TicTacToeMessageParser.encodeMove(
      gameId: state.gameId,
      cell: idx,
      playerKey6: selfKey6,
      timestampSec: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_ttt_move';
    final senderPublicKeyPrefix = connectionProvider.deviceInfo.publicKey!
        .sublist(0, 6);

    final sentMessage = Message(
      id: messageId,
      messageType: MessageType.contact,
      senderPublicKeyPrefix: senderPublicKeyPrefix,
      pathLen: 0,
      textType: MessageTextType.plain,
      senderTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      text: text,
      receivedAt: DateTime.now(),
      deliveryStatus: MessageDeliveryStatus.sending,
      recipientPublicKey: opponent.publicKey,
    );
    messagesProvider.addSentMessage(sentMessage, contact: opponent);

    final sent = await connectionProvider.sendTextMessage(
      contactPublicKey: opponent.publicKey,
      text: text,
      messageId: messageId,
      contact: opponent,
    );
    if (!sent) {
      messagesProvider.markMessageFailed(messageId);
      if (!context.mounted) return;
      ToastLogger.error(context, 'Failed to send Tic-Tac-Toe move');
    }
  }

  static String _statusText({
    required TicTacToeGameState state,
    required String mySymbol,
  }) {
    if (state.winnerSymbol != null) {
      return state.winnerSymbol == mySymbol ? 'You won' : 'Opponent won';
    }
    if (state.isDraw) return 'Draw';
    return state.nextSymbol == mySymbol ? 'Your turn' : 'Opponent turn';
  }

  static String _key6Hex(Uint8List key) => key
      .sublist(0, math.min(6, key.length))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join('')
      .toLowerCase();

  static Contact? _resolveOpponentContact({
    required Message message,
    required ContactsProvider contactsProvider,
    required bool isSentByMe,
  }) {
    if (isSentByMe && message.recipientPublicKey != null) {
      return contactsProvider.findContactByKey(message.recipientPublicKey!);
    }
    final sender = message.senderPublicKeyPrefix;
    if (sender == null || sender.length < 6) return null;
    return contactsProvider.findContactByPrefix(
      Uint8List.fromList(sender.sublist(0, 6)),
    );
  }

  static bool _isSameDmThread({
    required Message message,
    required Uint8List selfKey,
    required String opponentKey6,
  }) {
    final isOwn = message.isSentMessage || message.isFromSelf(selfKey);
    if (isOwn) {
      final recipient = message.recipientPublicKey;
      if (recipient == null || recipient.length < 6) return false;
      return _key6Hex(recipient) == opponentKey6;
    }
    final sender = message.senderPublicKeyPrefix;
    if (sender == null || sender.length < 6) return false;
    return _key6Hex(sender) == opponentKey6;
  }
}

class _BoardGrid extends StatelessWidget {
  final List<String?> board;
  final bool enabled;
  final bool isSentByMe;
  final ValueChanged<int> onTapCell;

  const _BoardGrid({
    required this.board,
    required this.enabled,
    required this.isSentByMe,
    required this.onTapCell,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cellBackground = isSentByMe
        ? colorScheme.primaryContainer.withValues(alpha: 0.35)
        : colorScheme.surface;
    final cellBorder = isSentByMe
        ? colorScheme.primary.withValues(alpha: 0.45)
        : colorScheme.outline.withValues(alpha: 0.35);

    return SizedBox(
      width: 180,
      height: 180,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
        ),
        itemCount: 9,
        itemBuilder: (context, idx) {
          final value = board[idx];
          return InkWell(
            onTap: enabled && value == null ? () => onTapCell(idx) : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: cellBackground,
                border: Border.all(color: cellBorder),
              ),
              child: Text(
                value ?? '',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: value == 'X'
                      ? colorScheme.primary
                      : value == 'O'
                      ? colorScheme.tertiary
                      : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
