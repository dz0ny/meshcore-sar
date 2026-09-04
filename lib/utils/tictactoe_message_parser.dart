enum TicTacToeEventType { start, move }

class TicTacToeEvent {
  final TicTacToeEventType type;
  final String gameId;
  final String playerKey6;
  final int? cell;
  final int timestampSec;

  const TicTacToeEvent({
    required this.type,
    required this.gameId,
    required this.playerKey6,
    this.cell,
    required this.timestampSec,
  });
}

class TicTacToeMessageParser {
  static const String _prefix = 'TTT1:';

  static bool isTicTacToe(String text) => text.startsWith(_prefix);

  static TicTacToeEvent? tryParse(String text) {
    if (!isTicTacToe(text)) return null;
    final body = text.substring(_prefix.length);
    final parts = body.split(':');
    if (parts.length < 4) return null;

    final action = parts[0];
    final gameId = parts[1].toLowerCase();
    if (!RegExp(r'^[0-9a-f]{8}$').hasMatch(gameId)) return null;

    if (action == 'S' && parts.length == 4) {
      final starterKey6 = parts[2].toLowerCase();
      final ts = int.tryParse(parts[3]);
      if (!RegExp(r'^[0-9a-f]{12}$').hasMatch(starterKey6)) return null;
      if (ts == null || ts <= 0) return null;
      return TicTacToeEvent(
        type: TicTacToeEventType.start,
        gameId: gameId,
        playerKey6: starterKey6,
        timestampSec: ts,
      );
    }

    if (action == 'M' && parts.length == 5) {
      final cell = int.tryParse(parts[2]);
      final playerKey6 = parts[3].toLowerCase();
      final ts = int.tryParse(parts[4]);
      if (cell == null || cell < 0 || cell > 8) return null;
      if (!RegExp(r'^[0-9a-f]{12}$').hasMatch(playerKey6)) return null;
      if (ts == null || ts <= 0) return null;
      return TicTacToeEvent(
        type: TicTacToeEventType.move,
        gameId: gameId,
        playerKey6: playerKey6,
        cell: cell,
        timestampSec: ts,
      );
    }

    return null;
  }

  static String encodeStart({
    required String gameId,
    required String starterKey6,
    required int timestampSec,
  }) {
    return '$_prefix'
        'S:${gameId.toLowerCase()}:${starterKey6.toLowerCase()}:$timestampSec';
  }

  static String encodeMove({
    required String gameId,
    required int cell,
    required String playerKey6,
    required int timestampSec,
  }) {
    return '$_prefix'
        'M:${gameId.toLowerCase()}:$cell:${playerKey6.toLowerCase()}:$timestampSec';
  }
}

class TicTacToeGameState {
  final String gameId;
  final String xPlayerKey6;
  final String oPlayerKey6;
  final List<String?> board; // 'X' / 'O' / null
  final String nextSymbol;
  final String? winnerSymbol;

  const TicTacToeGameState({
    required this.gameId,
    required this.xPlayerKey6,
    required this.oPlayerKey6,
    required this.board,
    required this.nextSymbol,
    this.winnerSymbol,
  });

  bool get isDraw =>
      winnerSymbol == null && board.every((cell) => cell != null);
  bool get isFinished => winnerSymbol != null || isDraw;
}

TicTacToeGameState buildTicTacToeState({
  required String gameId,
  required String xPlayerKey6,
  required String oPlayerKey6,
  required List<TicTacToeEvent> events,
}) {
  final board = List<String?>.filled(9, null);
  var next = 'X';
  String? winner;

  final sorted = [...events]
    ..sort((a, b) => a.timestampSec.compareTo(b.timestampSec));

  for (final event in sorted) {
    if (event.type != TicTacToeEventType.move) continue;
    if (winner != null) break;

    final expectedKey = next == 'X' ? xPlayerKey6 : oPlayerKey6;
    final cell = event.cell;
    if (cell == null) continue;
    if (event.playerKey6 != expectedKey) continue;
    if (board[cell] != null) continue;

    board[cell] = next;
    winner = _computeWinner(board);
    next = next == 'X' ? 'O' : 'X';
  }

  return TicTacToeGameState(
    gameId: gameId,
    xPlayerKey6: xPlayerKey6,
    oPlayerKey6: oPlayerKey6,
    board: board,
    nextSymbol: next,
    winnerSymbol: winner,
  );
}

String? _computeWinner(List<String?> board) {
  const lines = <List<int>>[
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];
  for (final line in lines) {
    final a = board[line[0]];
    if (a == null) continue;
    if (a == board[line[1]] && a == board[line[2]]) return a;
  }
  return null;
}
