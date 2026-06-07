import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/data/game_repository_impl.dart';
import 'package:ludo_game/domain/models/board_position.dart';

void main() {
  group('GameRepositoryImpl', () {
    test('moves a home token to the first path tile only on a six', () {
      final repository = GameRepositoryImpl();
      final player = repository.initializePlayers(1).first;
      final token = player.tokens.first;

      expect(repository.isValidMove(player, token, 5), isFalse);
      expect(repository.isValidMove(player, token, 6), isTrue);

      final updatedPlayer = repository.moveToken(player, token, 6);
      final movedToken = updatedPlayer.tokens.first;

      expect(movedToken.isHome, isFalse);
      expect(movedToken.pathPosition, 0);
      expect(movedToken.position, player.path.first);
    });

    test('rejects path moves that would overshoot the finish tile', () {
      final repository = GameRepositoryImpl();
      final player = repository.initializePlayers(1).first;
      final token = player.tokens.first.copyWith(
        isHome: false,
        pathPosition: player.path.length - 2,
        position: player.path[player.path.length - 2],
      );
      final playerNearFinish =
          player.copyWith(tokens: [token, ...player.tokens.skip(1)]);

      expect(repository.isValidMove(playerNearFinish, token, 1), isTrue);
      expect(repository.isValidMove(playerNearFinish, token, 2), isFalse);
    });

    test('collision sends the collided player token back home', () {
      final repository = GameRepositoryImpl();
      final players = repository.initializePlayers(2);
      final redPlayer = players[0];
      final greenPlayer = players[1];
      final collisionPosition = redPlayer.path[1];
      final redTokenOnTrack = redPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 1,
        position: collisionPosition,
      );
      final greenTokenOnTrack = greenPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 0,
        position: collisionPosition,
      );
      final redPlayerOnTrack = redPlayer.copyWith(
        tokens: [redTokenOnTrack, ...redPlayer.tokens.skip(1)],
      );
      final greenPlayerOnTrack = greenPlayer.copyWith(
        tokens: [greenTokenOnTrack, ...greenPlayer.tokens.skip(1)],
      );

      final captureResult = repository.handleCollision(
        players: [redPlayerOnTrack, greenPlayerOnTrack],
        currentPlayerIndex: 0,
        movedToken: redTokenOnTrack,
      );
      final resetToken = captureResult.players[1].tokens.first;

      expect(captureResult.didCapture, isTrue);
      expect(resetToken.isHome, isTrue);
      expect(resetToken.pathPosition, -1);
      expect(resetToken.position, greenPlayer.tokens.first.position);
    });

    test('safe zones cannot be captured', () {
      final repository = GameRepositoryImpl();
      final players = repository.initializePlayers(2);
      const safePosition = BoardPosition(1, 6);
      final redToken = players[0].tokens.first.copyWith(
            isHome: false,
            pathPosition: 0,
            position: safePosition,
          );
      final greenToken = players[1].tokens.first.copyWith(
            isHome: false,
            pathPosition: 0,
            position: safePosition,
          );
      final redPlayer = players[0].copyWith(
        tokens: [redToken, ...players[0].tokens.skip(1)],
      );
      final greenPlayer = players[1].copyWith(
        tokens: [greenToken, ...players[1].tokens.skip(1)],
      );

      final captureResult = repository.handleCollision(
        players: [redPlayer, greenPlayer],
        currentPlayerIndex: 0,
        movedToken: redToken,
      );

      expect(repository.isSafeZone(safePosition), isTrue);
      expect(captureResult.didCapture, isFalse);
      expect(captureResult.players[1].tokens.first.isHome, isFalse);
    });

    test('opponent blockades cannot be landed on or passed through', () {
      final repository = GameRepositoryImpl();
      final players = repository.initializePlayers(2);
      final redPlayer = players[0];
      final greenPlayer = players[1];
      final blockadePosition = redPlayer.path[1];
      final movingToken = redPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 0,
        position: redPlayer.path[0],
      );
      final redPlayerOnTrack = redPlayer.copyWith(
        tokens: [movingToken, ...redPlayer.tokens.skip(1)],
      );
      final greenBlockadeTokens = List.of(greenPlayer.tokens);
      greenBlockadeTokens[0] = greenBlockadeTokens[0].copyWith(
        isHome: false,
        pathPosition: 0,
        position: blockadePosition,
      );
      greenBlockadeTokens[1] = greenBlockadeTokens[1].copyWith(
        isHome: false,
        pathPosition: 1,
        position: blockadePosition,
      );
      final greenPlayerWithBlockade = greenPlayer.copyWith(
        tokens: greenBlockadeTokens,
      );
      final boardPlayers = [redPlayerOnTrack, greenPlayerWithBlockade];

      expect(
        repository.isBlockade(greenPlayerWithBlockade, blockadePosition),
        isTrue,
      );
      expect(
        repository.isValidMove(redPlayerOnTrack, movingToken, 1, boardPlayers),
        isFalse,
      );
      expect(
        repository.isValidMove(redPlayerOnTrack, movingToken, 2, boardPlayers),
        isFalse,
      );
    });

    test('tokens in the final home path cannot be captured', () {
      final repository = GameRepositoryImpl();
      final players = repository.initializePlayers(2);
      final redPlayer = players[0];
      final greenPlayer = players[1];
      final capturePosition = redPlayer.path[1];
      final redToken = redPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 1,
        position: capturePosition,
      );
      final greenToken = greenPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: greenPlayer.path.length - 2,
        position: capturePosition,
      );
      final redPlayerOnTrack = redPlayer.copyWith(
        tokens: [redToken, ...redPlayer.tokens.skip(1)],
      );
      final greenPlayerInHomePath = greenPlayer.copyWith(
        tokens: [greenToken, ...greenPlayer.tokens.skip(1)],
      );

      final captureResult = repository.handleCollision(
        players: [redPlayerOnTrack, greenPlayerInHomePath],
        currentPlayerIndex: 0,
        movedToken: redToken,
      );

      expect(repository.isHomePath(greenPlayerInHomePath, greenToken), isTrue);
      expect(captureResult.didCapture, isFalse);
      expect(captureResult.players[1].tokens.first.isHome, isFalse);
    });

    test('winner is detected when every token is finished', () {
      final repository = GameRepositoryImpl();
      final player = repository.initializePlayers(1).first;
      final finishedTokens = player.tokens.map((token) {
        return token.copyWith(
          isHome: false,
          isFinished: true,
          pathPosition: player.path.length - 1,
          position: player.path.last,
        );
      }).toList();

      expect(
        repository.checkWinner(player.copyWith(tokens: finishedTokens)),
        isTrue,
      );
    });

    test('playerColors has Yellow at index 2 and Blue at index 3 to align with paths', () {
      final repository = GameRepositoryImpl();
      expect(repository.playerColors[2], Colors.yellow);
      expect(repository.playerColors[3], Colors.blue);
    });
  });
}
