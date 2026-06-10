import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/services/player_prefs.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart'; // Reusing CaptureEffect, CapturedTokenInfo, etc.
import 'package:ludo_game/injection.dart';

// Events
abstract class OnlineGameEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitOnlineGame extends OnlineGameEvent {
  final String lobbyId;
  InitOnlineGame(this.lobbyId);

  @override
  List<Object?> get props => [lobbyId];
}

class UpdateFromLobby extends OnlineGameEvent {
  final Map<String, dynamic> lobbyData;
  UpdateFromLobby(this.lobbyData);

  @override
  List<Object?> get props => [lobbyData];
}

class RollDiceOnline extends OnlineGameEvent {
  final Completer<int?>? resultCompleter;
  RollDiceOnline({this.resultCompleter});

  @override
  List<Object?> get props => [resultCompleter];
}

class SelectTokenOnline extends OnlineGameEvent {
  final Token token;
  SelectTokenOnline(this.token);

  @override
  List<Object?> get props => [token];
}

class LeaveGameOnline extends OnlineGameEvent {}

// State
class OnlineGameState extends Equatable {
  final GameState? gameState;
  final String lobbyId;
  final List<Map<String, dynamic>> lobbyPlayers;
  final bool isMyTurn;
  final int myPlayerIndex;
  final bool isLobbyLoading;
  final String? errorMessage;

  const OnlineGameState({
    this.gameState,
    this.lobbyId = '',
    this.lobbyPlayers = const [],
    this.isMyTurn = false,
    this.myPlayerIndex = -1,
    this.isLobbyLoading = true,
    this.errorMessage,
  });

  OnlineGameState copyWith({
    GameState? gameState,
    String? lobbyId,
    List<Map<String, dynamic>>? lobbyPlayers,
    bool? isMyTurn,
    int? myPlayerIndex,
    bool? isLobbyLoading,
    String? errorMessage,
  }) {
    return OnlineGameState(
      gameState: gameState ?? this.gameState,
      lobbyId: lobbyId ?? this.lobbyId,
      lobbyPlayers: lobbyPlayers ?? this.lobbyPlayers,
      isMyTurn: isMyTurn ?? this.isMyTurn,
      myPlayerIndex: myPlayerIndex ?? this.myPlayerIndex,
      isLobbyLoading: isLobbyLoading ?? this.isLobbyLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        gameState,
        lobbyId,
        lobbyPlayers,
        isMyTurn,
        myPlayerIndex,
        isLobbyLoading,
        errorMessage,
      ];
}

class OnlineGameBloc extends Bloc<OnlineGameEvent, OnlineGameState> {
  static const Duration _tokenStepDuration = Duration(milliseconds: 120);
  static const Duration _captureAnimationDuration = Duration(milliseconds: 360);

  final GameRepository gameRepository;
  final FirebaseService _firebaseService = getIt<FirebaseService>();
  StreamSubscription? _lobbySubscription;
  int _captureEffectId = 0;

  OnlineGameBloc({required this.gameRepository}) : super(const OnlineGameState()) {
    on<InitOnlineGame>(_onInitOnlineGame);
    on<UpdateFromLobby>(_onUpdateFromLobby);
    on<RollDiceOnline>(_onRollDiceOnline);
    on<SelectTokenOnline>(_onSelectTokenOnline);
    on<LeaveGameOnline>(_onLeaveGameOnline);
  }

  void _onInitOnlineGame(InitOnlineGame event, Emitter<OnlineGameState> emit) {
    emit(state.copyWith(lobbyId: event.lobbyId, isLobbyLoading: true));

    _lobbySubscription?.cancel();
    _lobbySubscription = _firebaseService.streamLobby(event.lobbyId).listen(
      (snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null) {
            add(UpdateFromLobby(data));
          }
        }
      },
      onError: (error) {
        dev.log('Lobby stream error: $error');
      },
    );
  }

  void _onUpdateFromLobby(UpdateFromLobby event, Emitter<OnlineGameState> emit) {
    final lobbyData = event.lobbyData;
    final gameStateMap = lobbyData['gameState'] as Map<String, dynamic>?;
    final playersList = List<Map<String, dynamic>>.from(lobbyData['players'] as List);

    if (gameStateMap == null) {
      emit(state.copyWith(
        isLobbyLoading: false,
        lobbyPlayers: playersList,
      ));
      return;
    }

    final newGameState = GameState.fromJson(gameStateMap);
    final currentUid = _firebaseService.currentUid;

    // Find my index and turn status based on matching colorValue
    int myPlayerIndex = -1;
    bool isMyTurn = false;

    final myLobbyPlayer = playersList.firstWhere(
      (p) => p['uid'] == currentUid,
      orElse: () => <String, dynamic>{},
    );

    if (myLobbyPlayer.isNotEmpty) {
      final myColorValue = myLobbyPlayer['colorValue'] as int;
      myPlayerIndex = newGameState.players.indexWhere((p) => p.color.toARGB32() == myColorValue);

      if (myPlayerIndex != -1) {
        isMyTurn = newGameState.currentPlayerIndex == myPlayerIndex;
      }
    }

    // Only update if we are not the active player currently animating/moving a token locally
    // to avoid resetting visual intermediate animations.
    if (state.gameState != null && state.gameState!.isMoving && state.isMyTurn) {
      // Keep local state while moving
      emit(state.copyWith(
        lobbyPlayers: playersList,
        myPlayerIndex: myPlayerIndex,
        isLobbyLoading: false,
      ));
    } else {
      emit(state.copyWith(
        gameState: newGameState,
        lobbyPlayers: playersList,
        myPlayerIndex: myPlayerIndex,
        isMyTurn: isMyTurn,
        isLobbyLoading: false,
      ));
    }
  }

  Future<void> _onRollDiceOnline(RollDiceOnline event, Emitter<OnlineGameState> emit) async {
    final currentGameState = state.gameState;
    if (currentGameState == null || !state.isMyTurn || !currentGameState.canRollDice || currentGameState.isMoving) {
      return;
    }

    final diceValue = gameRepository.rollDice();
    dev.log('Dice rolled: $diceValue');

    final currentPlayer = currentGameState.players[currentGameState.currentPlayerIndex];
    final validTokens = gameRepository.getValidTokens(
      currentPlayer,
      diceValue,
      currentGameState.players,
    );

    // If rolling a 6, grant a bonus turn (increment bonusTurns)
    final newBonusTurns = diceValue == 6 ? currentGameState.bonusTurns + 1 : currentGameState.bonusTurns;

    var rolledState = currentGameState.copyWith(
      diceValue: diceValue,
      canRollDice: false,
      validTokens: validTokens,
      captureEffect: null,
      bonusTurns: newBonusTurns,
    );

    // Update locally first for immediate responsiveness
    emit(state.copyWith(gameState: rolledState));

    if (validTokens.isEmpty) {
      // If no moves are valid, either use a bonus turn or move to the next player
      if (newBonusTurns > 0) {
        var finalState = rolledState.copyWith(
          bonusTurns: newBonusTurns - 1,
          diceValue: null,
          canRollDice: true,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
        );
        emit(state.copyWith(gameState: finalState));
        await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
      } else {
        final nextPlayerState = _calculateNextPlayerState(rolledState);
        emit(state.copyWith(gameState: nextPlayerState));
        await _firebaseService.updateGameState(state.lobbyId, nextPlayerState.toJson());
      }
    } else {
      // Push rolled state so guests see the dice value
      await _firebaseService.updateGameState(state.lobbyId, rolledState.toJson());

      // If exactly 1 token is valid, auto-select it
      if (validTokens.length == 1) {
        add(SelectTokenOnline(validTokens.first));
      }
    }
  }

  Future<void> _onSelectTokenOnline(SelectTokenOnline event, Emitter<OnlineGameState> emit) async {
    final currentGameState = state.gameState;
    if (currentGameState == null || !state.isMyTurn || currentGameState.isMoving) {
      return;
    }

    final diceValue = currentGameState.diceValue;
    if (diceValue == null) return;

    final currentPlayerIndex = currentGameState.currentPlayerIndex;
    final currentPlayer = currentGameState.players[currentPlayerIndex];
    final selectedToken = _findTokenById(currentPlayer, event.token.id);

    if (selectedToken == null ||
        !currentGameState.validTokens.any((token) => token.id == selectedToken.id)) {
      return;
    }

    if (!gameRepository.isValidMove(
      currentPlayer,
      selectedToken,
      diceValue,
      currentGameState.players,
    )) {
      return;
    }

    dev.log('Selected token: ${selectedToken.id}');
    dev.log('Moving token ${selectedToken.id} only');

    final updatedPlayer = gameRepository.moveToken(
      currentPlayer,
      selectedToken,
      diceValue,
    );
    final movedToken = _findTokenById(updatedPlayer, selectedToken.id);
    if (movedToken == null) return;

    // Set moving state locally
    var movingGameState = currentGameState.copyWith(
      canRollDice: false,
      isMoving: true,
      validTokens: const [],
      captureEffect: null,
    );
    emit(state.copyWith(gameState: movingGameState));

    // Animate locally step-by-step
    final updatedPlayers = await _moveTokenGradually(
      playerIndex: currentPlayerIndex,
      currentPlayer: currentPlayer,
      targetPlayer: updatedPlayer,
      stackedTokenIds: [selectedToken.id],
      emit: emit,
    );

    final finalPlayer = updatedPlayers[currentPlayerIndex];
    final finalToken = _findTokenById(finalPlayer, selectedToken.id) ?? movedToken;

    // Run collision and win checks on the active player side
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
    required Emitter<OnlineGameState> emit,
  }) async {
    final currentGameState = state.gameState!;
    var animatedPlayers = List<Player>.from(currentGameState.players);
    var animatedPlayer = currentPlayer;

    final tokenId = stackedTokenIds.first;
    final startToken = _findTokenById(currentPlayer, tokenId);
    final targetToken = _findTokenById(targetPlayer, tokenId);

    if (startToken == null || targetToken == null) {
      animatedPlayers[playerIndex] = targetPlayer;
      return animatedPlayers;
    }

    final firstPathIndex = startToken.pathPosition < 0 ? 0 : startToken.pathPosition + 1;
    final lastPathIndex = targetToken.pathPosition;

    if (firstPathIndex > lastPathIndex) {
      animatedPlayers[playerIndex] = targetPlayer;
      emit(state.copyWith(gameState: currentGameState.copyWith(players: animatedPlayers)));
      return animatedPlayers;
    }

    for (var pathIndex = firstPathIndex; pathIndex <= lastPathIndex; pathIndex++) {
      await Future.delayed(_tokenStepDuration);

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

      emit(state.copyWith(gameState: state.gameState!.copyWith(players: animatedPlayers)));
    }

    animatedPlayers = List<Player>.from(animatedPlayers);
    animatedPlayers[playerIndex] = targetPlayer;
    emit(state.copyWith(gameState: state.gameState!.copyWith(players: animatedPlayers)));
    return animatedPlayers;
  }

  Future<void> _checkForCollisionsAndWin(
    List<Player> updatedPlayers,
    int currentPlayerIndex,
    Token token,
    int diceValue,
    Emitter<OnlineGameState> emit,
  ) async {
    final captureResult = gameRepository.handleCollision(
      players: updatedPlayers,
      currentPlayerIndex: currentPlayerIndex,
      movedToken: token,
    );
    final didCapture = captureResult.didCapture;

    var newBonusTurns = state.gameState!.bonusTurns;
    if (didCapture) {
      newBonusTurns += 1;

      final captureEffectsList = captureResult.capturedTokens
          .map((ct) => CapturedTokenInfo(
                tokenId: ct.tokenId,
                homePosition: ct.homePosition,
              ))
          .toList();

      emit(state.copyWith(
        gameState: state.gameState!.copyWith(
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
        ),
      ));

      await Future.delayed(_captureAnimationDuration);

      emit(state.copyWith(
        gameState: state.gameState!.copyWith(
          players: captureResult.players,
          captureEffect: null,
        ),
      ));
    }

    final postCapturePlayers = captureResult.players;
    final isWinner = gameRepository.checkWinner(postCapturePlayers[currentPlayerIndex]);

    if (isWinner && !postCapturePlayers[currentPlayerIndex].hasFinished) {
      final newFinishOrder = List<int>.from(state.gameState!.finishOrder)..add(currentPlayerIndex);
      final finishRank = newFinishOrder.length;

      var winPlayers = List<Player>.from(postCapturePlayers);
      winPlayers[currentPlayerIndex] = winPlayers[currentPlayerIndex].copyWith(
        hasFinished: true,
        finishRank: finishRank,
      );

      // Persist stats when a player finishes first
      if (finishRank == 1) {
        final isMyWin = currentPlayerIndex == state.myPlayerIndex;
        try {
          PlayerPrefs.incrementTotalGames();
          if (isMyWin) {
            PlayerPrefs.incrementWins();
            PlayerPrefs.setWinStreak(PlayerPrefs.winStreak + 1);
          } else {
            PlayerPrefs.setWinStreak(0);
          }

          if (_firebaseService.currentUid != null) {
            _firebaseService.updateUserStats(isWin: isMyWin);
          }
        } catch (_) {}
      }

      final unfinishedPlayers = winPlayers.where((p) => !p.hasFinished).toList();

      if (unfinishedPlayers.length <= 1) {
        // Game Over
        if (unfinishedPlayers.length == 1) {
          final lastPlayer = unfinishedPlayers.first;
          final lastPlayerIndex = winPlayers.indexWhere((p) => p.id == lastPlayer.id);
          newFinishOrder.add(lastPlayerIndex);
          winPlayers[lastPlayerIndex] = winPlayers[lastPlayerIndex].copyWith(
            hasFinished: true,
            finishRank: newFinishOrder.length,
          );
        }

        final finalState = state.gameState!.copyWith(
          players: winPlayers,
          isGameOver: true,
          canRollDice: false,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
          finishOrder: newFinishOrder,
          bonusTurns: 0,
        );

        emit(state.copyWith(gameState: finalState));
        await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
        return;
      }

      // Game continues
      var gameContinuesState = state.gameState!.copyWith(
        players: winPlayers,
        finishOrder: newFinishOrder,
      );

      if (newBonusTurns > 0) {
        final finalState = gameContinuesState.copyWith(
          bonusTurns: newBonusTurns - 1,
          diceValue: null,
          canRollDice: true,
          isMoving: false,
          validTokens: const [],
          captureEffect: null,
        );
        emit(state.copyWith(gameState: finalState));
        await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
      } else {
        final finalState = _calculateNextPlayerState(gameContinuesState);
        emit(state.copyWith(gameState: finalState));
        await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
      }
      return;
    }

    // Standard turn ending
    if (newBonusTurns > 0) {
      final finalState = state.gameState!.copyWith(
        players: postCapturePlayers,
        diceValue: null,
        canRollDice: true,
        isMoving: false,
        validTokens: const [],
        captureEffect: null,
        bonusTurns: newBonusTurns - 1,
      );
      emit(state.copyWith(gameState: finalState));
      await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
    } else {
      final finalState = _calculateNextPlayerState(state.gameState!.copyWith(players: postCapturePlayers));
      emit(state.copyWith(gameState: finalState));
      await _firebaseService.updateGameState(state.lobbyId, finalState.toJson());
    }
  }

  GameState _calculateNextPlayerState(GameState current) {
    final activePlayers = current.players;
    if (activePlayers.isEmpty) return current;

    var nextPlayerIndex = (current.currentPlayerIndex + 1) % activePlayers.length;
    var attempts = 0;
    while (activePlayers[nextPlayerIndex].hasFinished && attempts < activePlayers.length) {
      nextPlayerIndex = (nextPlayerIndex + 1) % activePlayers.length;
      attempts++;
    }

    if (attempts >= activePlayers.length) return current;

    return current.copyWith(
      players: activePlayers,
      currentPlayerIndex: nextPlayerIndex,
      diceValue: null,
      canRollDice: true,
      isMoving: false,
      validTokens: const [],
      captureEffect: null,
      bonusTurns: 0,
    );
  }

  Token? _findTokenById(Player player, int tokenId) {
    for (final token in player.tokens) {
      if (token.id == tokenId) return token;
    }
    return null;
  }

  Future<void> _onLeaveGameOnline(LeaveGameOnline event, Emitter<OnlineGameState> emit) async {
    _lobbySubscription?.cancel();
    if (state.lobbyId.isNotEmpty) {
      await _firebaseService.leaveLobby(state.lobbyId);
    }
  }

  @override
  Future<void> close() {
    _lobbySubscription?.cancel();
    return super.close();
  }
}
