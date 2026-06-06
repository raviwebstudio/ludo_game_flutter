import 'dart:math';
import 'package:flutter/material.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/models/capture_result.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/domain/services/safe_zones.dart';

class GameRepositoryImpl implements GameRepository {
  static const int _homePathLength = 6;

  final Random _random = Random();

  final List<Color> playerColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
  ];

  final Map<int, List<BoardPosition>> _playerPaths = {
    0: _generateRedPath(),
    1: _generateGreenPath(),
    2: _generateYellowPath(),
    3: _generateBluePath(),
  };

  final Map<int, List<BoardPosition>> _playerHomes = {
    0: [
      BoardPosition(1, 1),
      BoardPosition(4, 1),
      BoardPosition(1, 4),
      BoardPosition(4, 4)
    ],
    1: [
      BoardPosition(10, 1),
      BoardPosition(13, 1),
      BoardPosition(10, 4),
      BoardPosition(13, 4)
    ],
    2: [
      BoardPosition(10, 10),
      BoardPosition(13, 10),
      BoardPosition(10, 13),
      BoardPosition(13, 13)
    ],
    3: [
      BoardPosition(1, 10),
      BoardPosition(4, 10),
      BoardPosition(1, 13),
      BoardPosition(4, 13)
    ],
  };

  @override
  List<Player> initializePlayers(int playerCount) {
    return List.generate(
      playerCount,
      (index) => Player(
        id: index,
        color: playerColors[index],
        name: PlayerPrefs.playerName(index),
        tokens: List.generate(
          4,
          (tokenIndex) => Token(
            id: tokenIndex,
            position: _playerHomes[index]![tokenIndex],
          ),
        ),
        path: _playerPaths[index]!,
      ),
    );
  }

  @override
  bool isValidMove(
    Player player,
    Token token,
    int diceValue, [
    List<Player> players = const [],
  ]) {
    if (token.isFinished) return false;
    if (token.isHome && diceValue != 6) return false;
    if (player.path.isEmpty) return false;

    final nextPathPosition = token.isHome ? 0 : token.pathPosition + diceValue;
    if (nextPathPosition < 0 || nextPathPosition >= player.path.length) {
      return false;
    }

    if (players.isEmpty) {
      return true;
    }

    final firstPathPosition = token.isHome ? 0 : token.pathPosition + 1;
    for (var pathPosition = firstPathPosition;
        pathPosition <= nextPathPosition;
        pathPosition++) {
      final boardPosition = player.path[pathPosition];
      if (!canPassBlockade(player, boardPosition, players)) {
        return false;
      }
    }

    return canLandOnBlockade(
      player,
      player.path[nextPathPosition],
      players,
    );
  }

  @override
  List<Token> getValidTokens(
    Player player,
    int diceValue, [
    List<Player> players = const [],
  ]) {
    return player.tokens.where((token) {
      return isValidMove(player, token, diceValue, players);
    }).toList();
  }

  @override
  Player moveToken(Player player, Token token, int diceValue) {
    final newTokens = List<Token>.from(player.tokens);
    final tokenIndex = newTokens.indexWhere((t) => t.id == token.id);

    if (tokenIndex == -1 || !isValidMove(player, token, diceValue)) {
      return player;
    }

    if (token.isHome && diceValue == 6) {
      newTokens[tokenIndex] = token.copyWith(
        isHome: false,
        pathPosition: 0,
        position: player.path[0],
      );
    } else {
      final newPosition = token.pathPosition + diceValue;
      newTokens[tokenIndex] = token.copyWith(
        pathPosition: newPosition,
        position: player.path[newPosition],
        isFinished: newPosition == player.path.length - 1,
      );
    }

    return player.copyWith(tokens: newTokens);
  }

  @override
  bool checkWinner(Player player) {
    return player.tokens.every((token) => token.isFinished);
  }

  @override
  int rollDice() {
    return _random.nextInt(6) + 1;
  }

  @override
  List<BoardPosition> getPlayerPath(int playerId) {
    return _playerPaths[playerId]!;
  }

  @override
  bool checkCollision(BoardPosition position, List<Player> players) {
    if (isSafeZone(position)) return false;

    for (final player in players) {
      for (final token in player.tokens) {
        if (!token.isHome &&
            !token.isFinished &&
            token.position == position &&
            !isHomePath(player, token)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  CaptureResult handleCollision({
    required List<Player> players,
    required int currentPlayerIndex,
    required Token movedToken,
  }) {
    final landingPosition = movedToken.position;
    if (landingPosition == null ||
        movedToken.isHome ||
        movedToken.isFinished ||
        isSafeZone(landingPosition)) {
      return CaptureResult(players: players);
    }

    final updatedPlayers = List<Player>.from(players);
    final capturedTokens = <CapturedToken>[];

    for (var playerIndex = 0;
        playerIndex < updatedPlayers.length;
        playerIndex++) {
      if (playerIndex == currentPlayerIndex) continue;

      final opponent = updatedPlayers[playerIndex];
      if (isBlockade(opponent, landingPosition)) {
        continue;
      }

      final newTokens = List<Token>.from(opponent.tokens);
      var capturedAnyToken = false;

      for (var tokenIndex = 0; tokenIndex < newTokens.length; tokenIndex++) {
        final token = newTokens[tokenIndex];
        if (token.isHome ||
            token.isFinished ||
            token.position != landingPosition ||
            isHomePath(opponent, token) ||
            isSafeZone(token.position)) {
          continue;
        }

        final homePosition = getTokenHomePosition(opponent.id, token.id);
        newTokens[tokenIndex] = token.copyWith(
          isHome: true,
          pathPosition: -1,
          isFinished: false,
          position: homePosition,
        );
        capturedTokens.add(
          CapturedToken(
            playerId: opponent.id,
            tokenId: token.id,
            capturePosition: landingPosition,
            homePosition: homePosition,
          ),
        );
        capturedAnyToken = true;
      }

      if (capturedAnyToken) {
        updatedPlayers[playerIndex] = opponent.copyWith(tokens: newTokens);
      }
    }

    return CaptureResult(
      players: updatedPlayers,
      capturedTokens: capturedTokens,
    );
  }

  @override
  bool isSafeZone(BoardPosition? position) {
    return SafeZoneService.isSafeZone(position);
  }

  @override
  bool isHomePath(Player player, Token token) {
    if (token.isHome || token.pathPosition < 0) return false;

    final homePathStart = player.path.length - _homePathLength;
    return token.pathPosition >= homePathStart;
  }

  @override
  bool isBlockade(Player player, BoardPosition position) {
    final tokensOnPosition = player.tokens.where((token) {
      return !token.isHome && !token.isFinished && token.position == position;
    }).length;

    return tokensOnPosition >= 2;
  }

  @override
  bool canPassBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  ) {
    for (final player in players) {
      if (player.id == movingPlayer.id) continue;
      if (isBlockade(player, position)) return false;
    }
    return true;
  }

  @override
  bool canLandOnBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  ) {
    return canPassBlockade(movingPlayer, position, players);
  }

  @override
  BoardPosition getTokenHomePosition(int playerId, int tokenId) {
    return _playerHomes[playerId]![tokenId];
  }

  static List<BoardPosition> redBlocPath() => [
        ...straightX(5, 8, 0, 8),
        BoardPosition(0, 7),
        ...straightX(0, 6, 5, 6),
      ];

  static List<BoardPosition> greenBlocPath() => [
        ...straightY(6, 5, 6, 0),
        BoardPosition(7, 0),
        ...straightY(8, 0, 8, 5),
      ];

  static List<BoardPosition> yellowBlocPath() => [
        ...straightX(9, 6, 14, 6),
        BoardPosition(14, 7),
        ...straightX(14, 8, 9, 8),
      ];

  static List<BoardPosition> blueBlocPath() => [
        ...straightY(8, 9, 8, 14),
        BoardPosition(7, 14),
        ...straightY(6, 14, 6, 9),
      ];

  static List<BoardPosition> _generateRedPath() {
    return [
      ...straightX(1, 6, 5, 6),
      ...greenBlocPath(),
      ...yellowBlocPath(),
      ...blueBlocPath(),
      ...straightX(5, 8, 0, 8),
      ...straightX(0, 7, 6, 7),
    ];
  }

  static List<BoardPosition> _generateGreenPath() {
    return [
      ...straightY(8, 1, 8, 5),
      ...yellowBlocPath(),
      ...blueBlocPath(),
      ...redBlocPath(),
      ...straightY(6, 5, 6, 0),
      ...straightY(7, 0, 7, 6),
    ];
  }

  static List<BoardPosition> _generateYellowPath() {
    return [
      ...straightX(13, 8, 9, 8),
      ...blueBlocPath(),
      ...redBlocPath(),
      ...greenBlocPath(),
      ...straightX(9, 6, 14, 6),
      ...straightX(14, 7, 8, 7),
    ];
  }

  static List<BoardPosition> _generateBluePath() {
    return [
      ...straightY(6, 13, 6, 9),
      ...redBlocPath(),
      ...greenBlocPath(),
      ...yellowBlocPath(),
      ...straightY(8, 9, 8, 14),
      ...straightY(7, 14, 7, 8),
    ];
  }

  static List<BoardPosition> straightX(int x1, int y1, int x2, int y2) {
    List<BoardPosition> result = [];
    for (int i = x1; (x1 < x2) ? i <= x2 : i >= x2; (x1 < x2) ? i++ : i--) {
      result.add(BoardPosition(i, y1));
    }
    return result;
  }

  static List<BoardPosition> straightY(int x1, int y1, int x2, int y2) {
    List<BoardPosition> result = [];
    for (int i = y1; (y1 < y2) ? i <= y2 : i >= y2; (y1 < y2) ? i++ : i--) {
      result.add(BoardPosition(x1, i));
    }
    return result;
  }
}
