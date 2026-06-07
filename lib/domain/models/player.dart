import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:ludo_game/domain/models/board_position.dart';

class Player extends Equatable {
  final int id;
  final Color color;
  final String name;
  final List<Token> tokens;
  final List<BoardPosition> path;
  final bool hasFinished;
  final int finishRank;

  const Player({
    required this.id,
    required this.color,
    this.name = '',
    required this.tokens,
    required this.path,
    this.hasFinished = false,
    this.finishRank = 0,
  });

  Player copyWith({
    int? id,
    Color? color,
    String? name,
    List<Token>? tokens,
    List<BoardPosition>? path,
    bool? hasFinished,
    int? finishRank,
  }) {
    return Player(
      id: id ?? this.id,
      color: color ?? this.color,
      name: name ?? this.name,
      tokens: tokens ?? this.tokens,
      path: path ?? this.path,
      hasFinished: hasFinished ?? this.hasFinished,
      finishRank: finishRank ?? this.finishRank,
    );
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      color: Color(json['color'] as int),
      name: (json['name'] as String?) ?? '',
      tokens: (json['tokens'] as List<dynamic>)
          .map((value) => Token.fromJson(value as Map<String, dynamic>))
          .toList(),
      path: (json['path'] as List<dynamic>)
          .map((value) => BoardPosition.fromJson(value as Map<String, dynamic>))
          .toList(),
      hasFinished: (json['hasFinished'] as bool?) ?? false,
      finishRank: (json['finishRank'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'color': color.toARGB32(),
        'name': name,
        'tokens': tokens.map((token) => token.toJson()).toList(),
        'path': path.map((position) => position.toJson()).toList(),
        'hasFinished': hasFinished,
        'finishRank': finishRank,
      };

  @override
  List<Object?> get props => [id, color, name, tokens, path, hasFinished, finishRank];
}

class Token extends Equatable {
  final int id;
  final int pathPosition; // Position in player's path
  final bool isHome;
  final bool isFinished;
  final BoardPosition? position; // Current board position

  const Token({
    required this.id,
    this.pathPosition = -1,
    this.isHome = true,
    this.isFinished = false,
    this.position,
  });

  Token copyWith({
    int? id,
    int? pathPosition,
    bool? isHome,
    bool? isFinished,
    BoardPosition? position,
  }) {
    return Token(
      id: id ?? this.id,
      pathPosition: pathPosition ?? this.pathPosition,
      isHome: isHome ?? this.isHome,
      isFinished: isFinished ?? this.isFinished,
      position: position ?? this.position,
    );
  }

  factory Token.fromJson(Map<String, dynamic> json) {
    return Token(
      id: json['id'] as int,
      pathPosition: json['pathPosition'] as int,
      isHome: json['isHome'] as bool,
      isFinished: json['isFinished'] as bool,
      position: json['position'] == null
          ? null
          : BoardPosition.fromJson(json['position'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pathPosition': pathPosition,
        'isHome': isHome,
        'isFinished': isFinished,
        'position': position?.toJson(),
      };

  @override
  List<Object?> get props => [id, pathPosition, isHome, isFinished, position];
}
