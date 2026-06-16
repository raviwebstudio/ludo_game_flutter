import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/domain/game_repository.dart';
import 'package:ludo_game/domain/models/player.dart';
import 'package:ludo_game/presentation/bloc/game_bloc.dart'; // For GameState
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';

class OnlineWaitingRoom extends StatefulWidget {
  const OnlineWaitingRoom({super.key});

  @override
  State<OnlineWaitingRoom> createState() => _OnlineWaitingRoomState();
}

class _OnlineWaitingRoomState extends State<OnlineWaitingRoom> {
  final _firebaseService = getIt<FirebaseService>();
  final _gameRepository = getIt<GameRepository>();
  bool _isActionLoading = false;
  bool _hasNavigatedToGame = false;

  @override
  Widget build(BuildContext context) {
    final lobbyId = ModalRoute.of(context)!.settings.arguments as String;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          // Trigger leave in background
          _firebaseService.leaveLobby(lobbyId);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'WAITING ROOM',
            style: LudoTextStyles.displayMedium.copyWith(fontSize: 20, letterSpacing: 1.5),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [LudoColors.darkNavyDark, LudoColors.darkNavy],
            ),
          ),
          child: StreamBuilder<dynamic>(
            stream: _firebaseService.streamLobby(lobbyId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: LudoColors.brightBlue),
                );
              }

              if (!snapshot.hasData || !snapshot.data.exists) {
                return _buildLobbyClosedView();
              }

              final lobbyData = snapshot.data.data() as Map<String, dynamic>;
              final status = lobbyData['status'] as String;

              // If status changed to playing, route to Online Game screen
              if (status == 'playing' && !_hasNavigatedToGame) {
                _hasNavigatedToGame = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pushReplacementNamed(
                    context,
                    '/online/game',
                    arguments: lobbyId,
                  );
                });
                return const Center(
                  child: CircularProgressIndicator(color: LudoColors.mintGreen),
                );
              }

              final players = List<Map<String, dynamic>>.from(lobbyData['players'] as List);
              final playerCount = lobbyData['playerCount'] as int;
              final hostId = lobbyData['hostId'] as String;
              final currentUid = _firebaseService.currentUid;
              final isHost = hostId == currentUid;

              final currentPlayerMap = players.firstWhere(
                (p) => p['uid'] == currentUid,
                orElse: () => <String, dynamic>{},
              );
              final isCurrentPlayerReady = currentPlayerMap['isReady'] as bool? ?? false;

              // Check if all players are ready
              final allReady = players.length >= 2 && players.every((p) => p['isReady'] as bool == true);

              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(LudoDimensions.spacing16),
                  child: Column(
                    children: [
                      // Lobby Title
                      Text(
                        'Room Code: ${lobbyId.substring(0, 5).toUpperCase()}',
                        style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.mintGreen),
                      ).animate().fadeIn(),

                      const SizedBox(height: 8),

                      Text(
                        'Waiting for players ($allReady)...',
                        style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                      ),

                      const SizedBox(height: 24),

                      // Player list
                      Expanded(
                        child: ListView.builder(
                          itemCount: playerCount,
                          itemBuilder: (context, index) {
                            if (index < players.length) {
                              final player = players[index];
                              return _buildPlayerCard(player, hostId)
                                  .animate()
                                  .fadeIn(delay: (index * 100).ms)
                                  .slideX(begin: -0.1);
                            } else {
                              return _buildEmptySlotCard()
                                  .animate()
                                  .fadeIn(delay: (index * 100).ms);
                            }
                          },
                        ),
                      ),

                      // Actions section
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Column(
                          children: [
                            if (isHost)
                              GradientButton(
                                label: 'START GAME',
                                isLoading: _isActionLoading,
                                onPressed: allReady ? () => _startGame(lobbyId, players) : () {},
                                colors: allReady
                                    ? const [LudoColors.mintGreen, LudoColors.brightBlue]
                                    : [Colors.grey.shade700, Colors.grey.shade800],
                              )
                            else
                              GradientButton(
                                label: isCurrentPlayerReady ? 'MARK NOT READY' : 'MARK READY',
                                isLoading: _isActionLoading,
                                onPressed: () => _toggleReady(lobbyId, !isCurrentPlayerReady),
                                colors: isCurrentPlayerReady
                                    ? const [LudoColors.redToken, Color(0xFFC0392B)]
                                    : const [LudoColors.brightBlue, LudoColors.purple],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLobbyClosedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: LudoColors.redToken, size: 64),
            const SizedBox(height: 16),
            Text(
              'Lobby Closed',
              style: LudoTextStyles.headlineSmall.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'The host has cancelled the session or you were disconnected.',
              textAlign: TextAlign.center,
              style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: LudoColors.brightBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Lobby'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, String hostId) {
    final uid = player['uid'] as String;
    final name = player['name'] as String;
    final colorVal = player['colorValue'] as int;
    final isReady = player['isReady'] as bool;
    final isHost = uid == hostId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(colorVal).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(colorVal),
            radius: 18,
            child: const Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: LudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const ShapeDecoration(
                          color: LudoColors.gold,
                          shape: StadiumBorder(),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              Icon(
                isReady ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isReady ? LudoColors.mintGreen : LudoColors.textMedium,
                size: 20,
              ),
              const SizedBox(width: 6),
              Text(
                isReady ? 'READY' : 'WAITING',
                style: TextStyle(
                  color: isReady ? LudoColors.mintGreen : LudoColors.textMedium,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            radius: 18,
            child: Icon(Icons.person_add_alt_1, color: Colors.white.withValues(alpha: 0.3), size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            'Waiting for player...',
            style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium.withValues(alpha: 0.5)),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleReady(String lobbyId, bool isReady) async {
    setState(() => _isActionLoading = true);
    try {
      await _firebaseService.toggleReady(lobbyId, isReady);
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      setState(() => _isActionLoading = false);
    }
  }

  int _getColorId(int colorValue) {
    if (colorValue == LudoColors.redToken.toARGB32()) return 0;
    if (colorValue == LudoColors.greenToken.toARGB32()) return 1;
    if (colorValue == LudoColors.yellowToken.toARGB32()) return 2;
    if (colorValue == LudoColors.blueToken.toARGB32()) return 3;
    return 0;
  }

  Future<void> _startGame(String lobbyId, List<Map<String, dynamic>> playersData) async {
    setState(() => _isActionLoading = true);
    try {
      // Build Player list based on color IDs
      final List<Player> players = playersData.map((pData) {
        final colorVal = pData['colorValue'] as int;
        final id = _getColorId(colorVal);

        return Player(
          id: id,
          color: Color(colorVal),
          name: pData['name'] as String,
          tokens: List.generate(
            4,
            (tokenIndex) => Token(
              id: tokenIndex,
              position: _gameRepository.getTokenHomePosition(id, tokenIndex),
            ),
          ),
          path: _gameRepository.getPlayerPath(id),
        );
      }).toList();

      // Ensure players are ordered such that turn goes sequentially through the active player IDs
      // In Ludo Elite offline, player id determines turn quadrant. We sort them by ID.
      players.sort((a, b) => a.id.compareTo(b.id));

      final initialGameState = GameState(
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
      );

      await _firebaseService.startLobbyGame(lobbyId, initialGameState.toJson());
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isActionLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: LudoColors.redToken,
      ),
    );
  }
}
