import 'package:ludo_game/domain/models/board_position.dart';

class SafeZoneService {
  static const Map<int, BoardPosition> playerStartSafeZones = {
    0: BoardPosition(1, 6),
    1: BoardPosition(8, 1),
    2: BoardPosition(13, 8),
    3: BoardPosition(6, 13),
  };

  static const List<BoardPosition> starCells = [
    BoardPosition(6, 2),
    BoardPosition(8, 1),
    BoardPosition(1, 6),
    BoardPosition(2, 8),
    BoardPosition(6, 13),
    BoardPosition(8, 12),
    BoardPosition(12, 6),
    BoardPosition(13, 8),
  ];

  static final Set<BoardPosition> safeZones = Set.unmodifiable(starCells);

  const SafeZoneService._();

  static bool isSafeZone(BoardPosition? position) {
    return position != null && safeZones.contains(position);
  }
}
