import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/domain/models/board_position.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/core/services/player_prefs.dart';

const Object _diceValueNotSet = Object();
const Object _captureEffectNotSet = Object();

// Events
abstract class GameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class StartGame extends GameEvent {
  final int playerCount;
  final List<Color>? playerColors;
  StartGame(this.playerCount, {this.playerColors});

  @override
  List<Object?> get props => [playerCount, playerColors];
}

class RollDice extends GameEvent {
  final Completer<int?>? resultCompleter;

  RollDice({this.resultCompleter});

  @override
  List<Object?> get props => [resultCompleter];
}

class SelectToken extends GameEvent {
  final Token token;
  SelectToken(this.token);

  @override
  List<Object?> get props => [token];
}

class CapturedTokenInfo extends Equatable {
  final int tokenId;
  final BoardPosition homePosition;

  const CapturedTokenInfo({
    required this.tokenId,
    required this.homePosition,
  });

  factory CapturedTokenInfo.fromJson(Map<String, dynamic> json) {
    return CapturedTokenInfo(
      tokenId: json['tokenId'] as int,
      homePosition: BoardPosition.fromJson(json['homePosition'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'tokenId': tokenId,
        'homePosition': homePosition.toJson(),
      };

  @override
  List<Object?> get props => [tokenId, homePosition];
}

class CaptureEffect extends Equatable {
  final int id;
  final int playerId;
  final List<CapturedTokenInfo> tokens;
  final BoardPosition position;

  const CaptureEffect({
    required this.id,
    required this.playerId,
    required this.tokens,
    required this.position,
  });

  factory CaptureEffect.fromJson(Map<String, dynamic> json) {
    return CaptureEffect(
      id: json['id'] as int,
      playerId: json['playerId'] as int,
      tokens: (json['tokens'] as List<dynamic>)
          .map((value) => CapturedTokenInfo.fromJson(value as Map<String, dynamic>))
          .toList(),
      position: BoardPosition.fromJson(json['position'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'tokens': tokens.map((t) => t.toJson()).toList(),
        'position': position.toJson(),
      };

  @override
  List<Object?> get props => [
        id,
        playerId,
        tokens,
        position,
      ];
}

// State
class GameState extends Equatable {
  final List<Player> players;
  final int currentPlayerIndex;
  final int? diceValue;
  final bool isGameOver;
  final DateTime? startTime;
  final bool canRollDice;
  final bool isMoving;
  final List<Token> validTokens;
  final CaptureEffect? captureEffect;
  final List<int> finishOrder;
  final int bonusTurns;

  const GameState({
    this.players = const [],
    this.currentPlayerIndex = 0,
    this.diceValue,
    this.isGameOver = false,
    this.startTime,
    this.canRollDice = true,
    this.isMoving = false,
    this.validTokens = const [],
    this.captureEffect,
    this.finishOrder = const [],
    this.bonusTurns = 0,
  });

  factory GameState.fromJson(Map<String, dynamic> json) {
    return GameState(
      players: (json['players'] as List<dynamic>)
          .map((value) => Player.fromJson(value as Map<String, dynamic>))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      diceValue: json['diceValue'] as int?,
      isGameOver: json['isGameOver'] as bool,
      startTime: json['startTime'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int),
      canRollDice: json['canRollDice'] as bool,
      isMoving: json['isMoving'] as bool,
      validTokens: (json['validTokens'] as List<dynamic>)
          .map((value) => Token.fromJson(value as Map<String, dynamic>))
          .toList(),
      captureEffect: json['captureEffect'] == null
          ? null
          : CaptureEffect.fromJson(
              json['captureEffect'] as Map<String, dynamic>),
      finishOrder: (json['finishOrder'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [],
      bonusTurns: json['bonusTurns'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'players': players.map((player) => player.toJson()).toList(),
        'currentPlayerIndex': currentPlayerIndex,
        'diceValue': diceValue,
        'isGameOver': isGameOver,
        'startTime': startTime?.millisecondsSinceEpoch,
        'canRollDice': canRollDice,
        'isMoving': isMoving,
        'validTokens': validTokens.map((token) => token.toJson()).toList(),
        'captureEffect': captureEffect?.toJson(),
        'finishOrder': finishOrder,
        'bonusTurns': bonusTurns,
      };

  GameState copyWith({
    List<Player>? players,
    int? currentPlayerIndex,
    Object? diceValue = _diceValueNotSet,
    bool? isGameOver,
    DateTime? startTime,
    bool? canRollDice,
    bool? isMoving,
    List<Token>? validTokens,
    Object? captureEffect = _captureEffectNotSet,
    List<int>? finishOrder,
    int? bonusTurns,
  }) {
    return GameState(
      players: players ?? this.players,
      currentPlayerIndex: currentPlayerIndex ?? this.currentPlayerIndex,
      diceValue: identical(diceValue, _diceValueNotSet)
          ? this.diceValue
          : diceValue as int?,
      isGameOver: isGameOver ?? this.isGameOver,
      startTime: startTime ?? this.startTime,
      canRollDice: canRollDice ?? this.canRollDice,
      isMoving: isMoving ?? this.isMoving,
      validTokens: validTokens ?? this.validTokens,
      captureEffect: identical(captureEffect, _captureEffectNotSet)
          ? this.captureEffect
          : captureEffect as CaptureEffect?,
      finishOrder: finishOrder ?? this.finishOrder,
      bonusTurns: bonusTurns ?? this.bonusTurns,
    );
  }

  @override
  List<Object?> get props => [
        players,
        currentPlayerIndex,
        diceValue,
        isGameOver,
        startTime,
        canRollDice,
        isMoving,
        validTokens,
        captureEffect,
        finishOrder,
        bonusTurns,
      ];
}

// Bloc
class GameBloc extends Bloc<GameEvent, GameState> {
  static const Duration _tokenStepDuration = Duration(milliseconds: 120);
  static const Duration _captureAnimationDuration = Duration(milliseconds: 360);

  final GameRepository gameRepository;
  int _captureEffectId = 0;

  GameBloc({required this.gameRepository}) : super(const GameState()) {
    on<StartGame>(_onStartGame);
    on<RollDice>(_onRollDice);
    on<SelectToken>(_onSelectToken);
  }

  void _onStartGame(StartGame event, Emitter<GameState> emit) {
    final players = gameRepository.initializePlayers(event.playerCount, customColors: event.playerColors);
    emit(state.copyWith(
      players: players,
      currentPlayerIndex: 0,
      diceValue: null,
      startTime: DateTime.now(),
      isGameOver: false,
      canRollDice: true,
      isMoving: false,
      validTokens: const [],
      captureEffect: null,
      finishOrder: const [],
      bonusTurns: 0,
    ));
  }

  void _onRollDice(RollDice event, Emitter<GameState> emit) {
    if (!state.canRollDice || state.isMoving || state.players.isEmpty) {
      _completeRoll(event, null);
      return;
    }

    final diceValue = gameRepository.rollDice();
    log('Dice rolled: $diceValue');
    final currentPlayer = state.players[state.currentPlayerIndex];
    final validTokens = gameRepository.getValidTokens(
      currentPlayer,
      diceValue,
      state.players,
    );

    // If rolling a 6, grant a bonus turn (increment bonusTurns)
    final newBonusTurns = diceValue == 6 ? state.bonusTurns + 1 : state.bonusTurns;

    emit(state.copyWith(
      diceValue: diceValue,
      canRollDice: false,
      validTokens: validTokens,
      captureEffect: null,
      bonusTurns: newBonusTurns,
    ));
    _completeRoll(event, diceValue);

    if (validTokens.isEmpty) {
      // If no moves are valid, either use a bonus turn or move to the next player
      if (newBonusTurns > 0) {
        emit(state.copyWith(
          bonusTurns: newBonusTurns - 1,
          diceValue: null,
          canRollDice: true,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
        ));
      } else {
        _moveToNextPlayer(emit);
      }
    } else if (validTokens.length == 1) {
      add(SelectToken(validTokens.first));
    }
  }

  Future<void> _onSelectToken(
    SelectToken event,
    Emitter<GameState> emit,
  ) async {
    final diceValue = state.diceValue;
    if (diceValue == null || state.isMoving || state.players.isEmpty) return;

    final currentPlayerIndex = state.currentPlayerIndex;
    final currentPlayer = state.players[currentPlayerIndex];
    final selectedToken = _findTokenById(currentPlayer, event.token.id);

    if (selectedToken == null ||
        !state.validTokens.any((token) => token.id == selectedToken.id)) {
      return;
    }

    if (!gameRepository.isValidMove(
      currentPlayer,
      selectedToken,
      diceValue,
      state.players,
    )) {
      return;
    }

    log('Selected token: ${selectedToken.id}');
    log('Moving token ${selectedToken.id} only');

    final updatedPlayer = gameRepository.moveToken(
      currentPlayer,
      selectedToken,
      diceValue,
    );
    final movedToken = _findTokenById(updatedPlayer, selectedToken.id);

    if (movedToken == null) return;

    emit(state.copyWith(
      canRollDice: false,
      isMoving: true,
      validTokens: const [],
      captureEffect: null,
    ));

    final updatedPlayers = await _moveTokenGradually(
      playerIndex: currentPlayerIndex,
      currentPlayer: currentPlayer,
      targetPlayer: updatedPlayer,
      stackedTokenIds: [selectedToken.id],
      emit: emit,
    );

    if (emit.isDone) return;

    final finalPlayer = updatedPlayers[currentPlayerIndex];
    final finalToken =
        _findTokenById(finalPlayer, selectedToken.id) ?? movedToken;

    await _checkForCollisionsAndWin(
      updatedPlayers,
      currentPlayerIndex,
      finalToken,
      diceValue,
      emit,
    );
  }

  Future<List<Player>> _moveTokenGradually({
    required int playerIndex,
    required Player currentPlayer,
    required Player targetPlayer,
    required List<int> stackedTokenIds,
    required Emitter<GameState> emit,
  }) async {
    var animatedPlayers = List<Player>.from(state.players);
    var animatedPlayer = currentPlayer;

    // Use selectedToken.id as the leader to determine paths
    final tokenId = stackedTokenIds.first;
    final startToken = _findTokenById(currentPlayer, tokenId);
    final targetToken = _findTokenById(targetPlayer, tokenId);

    if (startToken == null || targetToken == null) {
      animatedPlayers[playerIndex] = targetPlayer;
      return animatedPlayers;
    }

    final firstPathIndex =
        startToken.pathPosition < 0 ? 0 : startToken.pathPosition + 1;
    final lastPathIndex = targetToken.pathPosition;

    if (firstPathIndex > lastPathIndex) {
      animatedPlayers[playerIndex] = targetPlayer;
      emit(state.copyWith(players: animatedPlayers));
      return animatedPlayers;
    }

    for (var pathIndex = firstPathIndex;
        pathIndex <= lastPathIndex;
        pathIndex++) {
      await Future.delayed(_tokenStepDuration);
      if (emit.isDone) return animatedPlayers;

      final updatedTokens = List<Token>.from(animatedPlayer.tokens);
      for (final id in stackedTokenIds) {
        final tokenIndex = updatedTokens.indexWhere((token) => token.id == id);
        if (tokenIndex != -1) {
          updatedTokens[tokenIndex] = updatedTokens[tokenIndex].copyWith(
            isHome: false,
            pathPosition: pathIndex,
            position: animatedPlayer.path[pathIndex],
            isFinished: pathIndex == animatedPlayer.path.length - 1,
          );
        }
      }

      animatedPlayer = animatedPlayer.copyWith(tokens: updatedTokens);
      animatedPlayers = List<Player>.from(animatedPlayers);
      animatedPlayers[playerIndex] = animatedPlayer;

      emit(state.copyWith(players: animatedPlayers));
    }

    animatedPlayers = List<Player>.from(animatedPlayers);
    animatedPlayers[playerIndex] = targetPlayer;
    emit(state.copyWith(players: animatedPlayers));
    return animatedPlayers;
  }

  Future<void> _checkForCollisionsAndWin(
    List<Player> updatedPlayers,
    int currentPlayerIndex,
    Token token,
    int diceValue,
    Emitter<GameState> emit,
  ) async {
    final captureResult = gameRepository.handleCollision(
      players: updatedPlayers,
      currentPlayerIndex: currentPlayerIndex,
      movedToken: token,
    );
    final didCapture = captureResult.didCapture;

    var newBonusTurns = state.bonusTurns;
    if (didCapture) {
      newBonusTurns += 1; // Increment bonus turns on capture!

      final captureEffectsList = captureResult.capturedTokens
          .map((ct) => CapturedTokenInfo(
                tokenId: ct.tokenId,
                homePosition: ct.homePosition,
              ))
          .toList();

      emit(state.copyWith(
        players: updatedPlayers,
        canRollDice: false,
        isMoving: true,
        validTokens: const [],
        captureEffect: CaptureEffect(
          id: ++_captureEffectId,
          playerId: captureResult.capturedTokens.first.playerId,
          tokens: captureEffectsList,
          position: captureResult.capturedTokens.first.capturePosition,
        ),
      ));

      await Future.delayed(_captureAnimationDuration);
      if (emit.isDone) return;

      emit(state.copyWith(
        players: captureResult.players,
        captureEffect: null,
      ));
    }

    updatedPlayers = captureResult.players;
    final isWinner =
        gameRepository.checkWinner(updatedPlayers[currentPlayerIndex]);
    if (isWinner && !updatedPlayers[currentPlayerIndex].hasFinished) {
      // Mark the player as finished with their rank
      final newFinishOrder = List<int>.from(state.finishOrder)
        ..add(currentPlayerIndex);
      final finishRank = newFinishOrder.length;

      updatedPlayers = List<Player>.from(updatedPlayers);
      updatedPlayers[currentPlayerIndex] =
          updatedPlayers[currentPlayerIndex].copyWith(
        hasFinished: true,
        finishRank: finishRank,
      );

      // Persist stats for the first winner
      if (finishRank == 1) {
        try {
          PlayerPrefs.incrementTotalGames();
          PlayerPrefs.incrementWins();
          PlayerPrefs.setWinStreak(PlayerPrefs.winStreak + 1);
        } catch (_) {}
      }

      // Count unfinished players
      final unfinishedPlayers =
          updatedPlayers.where((p) => !p.hasFinished).toList();

      if (unfinishedPlayers.length <= 1) {
        // Game is over — assign last place to the remaining player
        if (unfinishedPlayers.length == 1) {
          final lastPlayer = unfinishedPlayers.first;
          final lastPlayerIndex =
              updatedPlayers.indexWhere((p) => p.id == lastPlayer.id);
          newFinishOrder.add(lastPlayerIndex);
          updatedPlayers[lastPlayerIndex] =
              updatedPlayers[lastPlayerIndex].copyWith(
            hasFinished: true,
            finishRank: newFinishOrder.length,
          );
        }

        emit(state.copyWith(
          players: updatedPlayers,
          isGameOver: true,
          canRollDice: false,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
          finishOrder: newFinishOrder,
          bonusTurns: 0,
        ));
        return;
      }

      // Game continues — move to the next unfinished player
      emit(state.copyWith(
        players: updatedPlayers,
        finishOrder: newFinishOrder,
      ));

      if (newBonusTurns > 0) {
        emit(state.copyWith(
          bonusTurns: newBonusTurns - 1,
          diceValue: null,
          canRollDice: true,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
        ));
      } else {
        _moveToNextPlayer(emit, updatedPlayers);
      }
      return;
    }

    if (newBonusTurns > 0) {
      log('Bonus turn granted, remaining: $newBonusTurns');
      emit(state.copyWith(
        players: updatedPlayers,
        diceValue: null,
        canRollDice: true,
        isMoving: false,
        validTokens: const [],
        captureEffect: null,
        bonusTurns: newBonusTurns - 1,
      ));
    } else {
      _moveToNextPlayer(emit, updatedPlayers);
    }
  }

  void _moveToNextPlayer(
    Emitter<GameState> emit, [
    List<Player>? players,
  ]) {
    final activePlayers = players ?? state.players;
    if (activePlayers.isEmpty) return;

    // Find the next player who hasn't finished
    var nextPlayerIndex =
        (state.currentPlayerIndex + 1) % activePlayers.length;
    var attempts = 0;
    while (activePlayers[nextPlayerIndex].hasFinished &&
        attempts < activePlayers.length) {
      nextPlayerIndex = (nextPlayerIndex + 1) % activePlayers.length;
      attempts++;
    }

    // If all players are finished (shouldn't happen), don't emit
    if (attempts >= activePlayers.length) return;

    emit(state.copyWith(
      players: activePlayers,
      currentPlayerIndex: nextPlayerIndex,
      diceValue: null,
      canRollDice: true,
      isMoving: false,
      validTokens: [],
      captureEffect: null,
      bonusTurns: 0, // Reset bonus turns for the new player
    ));
  }

  Token? _findTokenById(Player player, int tokenId) {
    for (final token in player.tokens) {
      if (token.id == tokenId) return token;
    }
    return null;
  }

  void _completeRoll(RollDice event, int? diceValue) {
    final completer = event.resultCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete(diceValue);
    }
  }
}
