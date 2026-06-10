
import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_game/data/game_repository_impl.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/core/constants/colors.dart';

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

    test('same-opponent stacked tokens can be landed on but block passing, while safe zone coexisting tokens do not block', () {
      final repository = GameRepositoryImpl();
      final players = repository.initializePlayers(3);
      final redPlayer = players[0];
      final greenPlayer = players[1];
      final yellowPlayer = players[2];

      final blockadePosition = redPlayer.path[1];
      const safePosition = BoardPosition(1, 6);

      final movingToken = redPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 0,
        position: redPlayer.path[0],
      );
      final redPlayerOnTrack = redPlayer.copyWith(
        tokens: [movingToken, ...redPlayer.tokens.skip(1)],
      );

      // 1. Test same opponent stack (blocks passing, but allows landing)
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

      var boardPlayers = [redPlayerOnTrack, greenPlayerWithBlockade, yellowPlayer];

      // Landing on it (1 step) is VALID
      expect(
        repository.isValidMove(redPlayerOnTrack, movingToken, 1, boardPlayers),
        isTrue,
      );
      // Passing it (2 steps) is INVALID because it's a blockade
      expect(
        repository.isValidMove(redPlayerOnTrack, movingToken, 2, boardPlayers),
        isFalse,
      );

      // 2. Test coexisting tokens in a safe zone (does not block passing or landing)
      final movingTokenNearSafe = redPlayer.tokens.first.copyWith(
        isHome: false,
        pathPosition: 0,
        position: safePosition,
      );
      final redPlayerNearSafe = redPlayer.copyWith(
        tokens: [movingTokenNearSafe, ...redPlayer.tokens.skip(1)],
      );

      final greenTokens = List.of(greenPlayer.tokens);
      greenTokens[0] = greenTokens[0].copyWith(
        isHome: false,
        pathPosition: 0,
        position: safePosition,
      );
      final yellowTokens = List.of(yellowPlayer.tokens);
      yellowTokens[0] = yellowTokens[0].copyWith(
        isHome: false,
        pathPosition: 0,
        position: safePosition,
      );

      final updatedGreenPlayer = greenPlayer.copyWith(tokens: greenTokens);
      final updatedYellowPlayer = yellowPlayer.copyWith(tokens: yellowTokens);

      boardPlayers = [redPlayerNearSafe, updatedGreenPlayer, updatedYellowPlayer];

      // Landing on it (1 step) or passing it (2 steps) is VALID in safe zone
      expect(
        repository.isValidMove(redPlayerNearSafe, movingTokenNearSafe, 1, boardPlayers),
        isTrue,
      );
      expect(
        repository.isValidMove(redPlayerNearSafe, movingTokenNearSafe, 2, boardPlayers),
        isTrue,
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
      expect(repository.playerColors[2], LudoColors.yellowToken);
      expect(repository.playerColors[3], LudoColors.blueToken);
    });
  });
}
