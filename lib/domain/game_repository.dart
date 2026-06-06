import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/models/capture_result.dart';
import 'package:ludo_game/domain/models/player.dart';

abstract class GameRepository {
  List<Player> initializePlayers(int playerCount);
  bool isValidMove(
    Player player,
    Token token,
    int diceValue, [
    List<Player> players = const [],
  ]);
  List<Token> getValidTokens(
    Player player,
    int diceValue, [
    List<Player> players = const [],
  ]);
  Player moveToken(Player player, Token token, int diceValue);
  bool checkWinner(Player player);
  int rollDice();
  List<BoardPosition> getPlayerPath(int playerId);
  bool checkCollision(BoardPosition position, List<Player> players);
  CaptureResult handleCollision({
    required List<Player> players,
    required int currentPlayerIndex,
    required Token movedToken,
  });
  bool isSafeZone(BoardPosition? position);
  bool isHomePath(Player player, Token token);
  bool isBlockade(Player player, BoardPosition position);
  bool canPassBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  );
  bool canLandOnBlockade(
    Player movingPlayer,
    BoardPosition position,
    List<Player> players,
  );
  BoardPosition getTokenHomePosition(int playerId, int tokenId);
}
