import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/models/capture_result.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart';

void main() {
  test('capture grants the current player a bonus turn', () async {
    final repository = _CapturingRepository();
    final bloc = GameBloc(gameRepository: repository);

    bloc.add(StartGame(2));
    await Future<void>.delayed(Duration.zero);

    bloc.add(RollDice());
    await Future<void>.delayed(const Duration(milliseconds: 700));

    expect(bloc.state.currentPlayerIndex, 0);
    expect(bloc.state.canRollDice, isTrue);
    expect(bloc.state.diceValue, isNull);
    expect(bloc.state.players[1].tokens.first.isHome, isTrue);
    expect(bloc.state.players[1].tokens.first.pathPosition, -1);

    await bloc.close();
  });
}

class _CapturingRepository implements GameRepository {
  static const _start = BoardPosition(0, 0);
  static const _capture = BoardPosition(1, 0);
  static const _finish = BoardPosition(2, 0);
  static const _capturedHome = BoardPosition(5, 5);

  @override
  List<Player> initializePlayers(int playerCount, {List<Color>? customColors}) {
    return [
      Player(
        id: 0,
        color: Colors.red,
        path: const [_start, _capture, _finish],
        tokens: [
          const Token(
            id: 0,
            isHome: false,
            pathPosition: 0,
            position: _start,
          ),
          const Token(id: 1),
        ],
      ),
      Player(
        id: 1,
        color: Colors.green,
        path: const [_capturedHome, BoardPosition(6, 5), BoardPosition(7, 5)],
        tokens: [
          const Token(
            id: 0,
            isHome: false,
            pathPosition: 0,
            position: _capture,
          ),
          const Token(id: 1),
        ],
      ),
    ];
  }

  @override
  int rollDice() => 1;

  @override
  List<Token> getValidTokens(
    Player player,
    int diceValue, [
    List<Player> players = const [],
  ]) {
    return [player.tokens.first];
  }

  @override
  bool isValidMove(
    Player player,
    Token token,
    int diceValue, [
    List<Player> players = const [],
  ]) {
    return true;
  }

  @override
  Player moveToken(Player player, Token token, int diceValue) {
    final tokens = List<Token>.from(player.tokens);
    tokens[0] = token.copyWith(
      isHome: false,
      isFinished: false,
      pathPosition: 1,
      position: _capture,
    );
    return player.copyWith(tokens: tokens);
  }

  @override
  CaptureResult handleCollision({
    required List<Player> players,
    required int currentPlayerIndex,
    required Token movedToken,
  }) {
    final updatedPlayers = List<Player>.from(players);
    final capturedPlayer = updatedPlayers[1];
    final tokens = List<Token>.from(capturedPlayer.tokens);
    tokens[0] = tokens[0].copyWith(
      isHome: true,
      pathPosition: -1,
      isFinished: false,
      position: _capturedHome,
    );
    updatedPlayers[1] = capturedPlayer.copyWith(tokens: tokens);

    return CaptureResult(
      players: updatedPlayers,
      capturedTokens: const [
        CapturedToken(
          playerId: 1,
          tokenId: 0,
          capturePosition: _capture,
          homePosition: _capturedHome,
        ),
      ],
    );
  }

  @override
  bool checkWinner(Player player) => false;

  @override
  List<BoardPosition> getPlayerPath(int playerId) {
    return initializePlayers(2)[playerId].path;
  }

  @override
  bool checkCollision(BoardPosition position, List<Player> players) => true;

  @override
  bool isSafeZone(BoardPosition? position) => false;

  @override
  bool isHomePath(Player player, Token token) => false;

  @override
  bool isBlockade(Player player, BoardPosition position) => false;

  @override
  bool canPassBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  ) {
    return true;
  }

  @override
  bool canLandOnBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  ) {
    return true;
  }

  @override
  BoardPosition getTokenHomePosition(int playerId, int tokenId) {
    return _capturedHome;
  }
}
