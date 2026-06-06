import 'package:equatable/equatable.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/models/player.dart';

class CapturedToken extends Equatable {
  final int playerId;
  final int tokenId;
  final BoardPosition capturePosition;
  final BoardPosition homePosition;

  const CapturedToken({
    required this.playerId,
    required this.tokenId,
    required this.capturePosition,
    required this.homePosition,
  });

  factory CapturedToken.fromJson(Map<String, dynamic> json) {
    return CapturedToken(
      playerId: json['playerId'] as int,
      tokenId: json['tokenId'] as int,
      capturePosition:
          BoardPosition.fromJson(json['capturePosition'] as Map<String, dynamic>),
      homePosition:
          BoardPosition.fromJson(json['homePosition'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'tokenId': tokenId,
        'capturePosition': capturePosition.toJson(),
        'homePosition': homePosition.toJson(),
      };

  @override
  List<Object?> get props => [
        playerId,
        tokenId,
        capturePosition,
        homePosition,
      ];
}

class CaptureResult extends Equatable {
  final List<Player> players;
  final List<CapturedToken> capturedTokens;

  const CaptureResult({
    required this.players,
    this.capturedTokens = const [],
  });

  factory CaptureResult.fromJson(Map<String, dynamic> json) {
    return CaptureResult(
      players: (json['players'] as List<dynamic>)
          .map((value) => Player.fromJson(value as Map<String, dynamic>))
          .toList(),
      capturedTokens: (json['capturedTokens'] as List<dynamic>)
          .map((value) => CapturedToken.fromJson(value as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((player) => player.toJson()).toList(),
        'capturedTokens': capturedTokens.map((token) => token.toJson()).toList(),
      };

  bool get didCapture => capturedTokens.isNotEmpty;

  @override
  List<Object?> get props => [players, capturedTokens];
}
