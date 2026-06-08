import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/shared/widgets/glass_morphism.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';
import 'package:ludo_game/shared/widgets/modern_card.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _firebaseService = getIt<FirebaseService>();
  bool _isActionLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ONLINE LOBBY',
          style: LudoTextStyles.displayMedium.copyWith(fontSize: 20, letterSpacing: 1.5),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: LudoColors.textLight),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: LudoColors.redToken),
            onPressed: () async {
              await _firebaseService.signOut();
              // AuthGate will redirect automatically
            },
          ),
        ],
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
        child: SafeArea(
          child: Column(
            children: [
              // Welcome banner
              _buildWelcomeBanner(),

              const SizedBox(height: 12),

              // Lobby stream list
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firebaseService.getOpenLobbies(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: LudoColors.brightBlue),
                      );
                    }

                    final lobbies = snapshot.data ?? [];

                    if (lobbies.isEmpty) {
                      return _buildEmptyLobbyView();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: lobbies.length,
                      itemBuilder: (context, index) {
                        final lobby = lobbies[index];
                        return _buildLobbyCard(lobby)
                            .animate()
                            .fadeIn(delay: (index * 50).ms)
                            .slideY(begin: 0.1);
                      },
                    );
                  },
                ),
              ),

              // Host game button area
              Padding(
                padding: const EdgeInsets.all(LudoDimensions.spacing24),
                child: GradientButton(
                  label: 'HOST NEW GAME',
                  isLoading: _isActionLoading,
                  onPressed: _showHostGameBottomSheet,
                  colors: const [LudoColors.purple, LudoColors.purpleLight],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    final name = _firebaseService.currentDisplayName ?? 'Player';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ModernCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: LudoColors.brightBlue.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: LudoColors.brightBlue),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name!',
                  style: LudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Challenge players in open arenas',
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildEmptyLobbyView() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(LudoDimensions.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_esports_outlined,
                color: LudoColors.textMedium.withValues(alpha: 0.4),
                size: 80,
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Arenas',
                style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
              ),
              const SizedBox(height: 8),
              Text(
                'Be the host and create an arena for others to join.',
                textAlign: TextAlign.center,
                style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildLobbyCard(Map<String, dynamic> lobby) {
    final hostName = lobby['hostName'] as String? ?? 'Host';
    final playerCount = lobby['playerCount'] as int? ?? 4;
    final players = lobby['players'] as List? ?? [];
    final joinedCount = players.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          // Lobby info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.circle, color: LudoColors.mintGreen, size: 10),
                    const SizedBox(width: 8),
                    Text(
                      "$hostName's Room",
                      style: LudoTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Players: $joinedCount / $playerCount',
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                ),
              ],
            ),
          ),

          // Join Button
          ElevatedButton(
            onPressed: joinedCount >= playerCount ? null : () => _onJoinLobby(lobby),
            style: ElevatedButton.styleFrom(
              backgroundColor: LudoColors.brightBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              joinedCount >= playerCount ? 'FULL' : 'JOIN',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _onJoinLobby(Map<String, dynamic> lobby) {
    final lobbyId = lobby['id'] as String;
    final players = lobby['players'] as List? ?? [];
    final takenColors = players.map((p) => p['colorValue'] as int).toList();

    _showColorSelectionDialog(
      takenColors: takenColors,
      onColorSelected: (selectedColor) async {
        setState(() => _isActionLoading = true);
        try {
          final name = _firebaseService.currentDisplayName ?? 'Player';
          await _firebaseService.joinLobby(lobbyId, name, selectedColor);

          if (mounted) {
            Navigator.pushNamed(
              context,
              '/online/waiting',
              arguments: lobbyId,
            );
          }
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar(e.toString());
          }
        } finally {
          if (mounted) {
            setState(() => _isActionLoading = false);
          }
        }
      },
    );
  }

  void _showColorSelectionDialog({
    required List<int> takenColors,
    required Function(Color) onColorSelected,
  }) {
    final colors = [
      LudoColors.redToken,
      LudoColors.greenToken,
      LudoColors.yellowToken,
      LudoColors.blueToken,
    ];

    final colorNames = ['Red', 'Green', 'Yellow', 'Blue'];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassMorphism(
            opacity: 0.15,
            blur: 16,
            borderRadius: BorderRadius.circular(24),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Token Color',
                  style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a color that is not already taken.',
                  textAlign: TextAlign.center,
                  style: LudoTextStyles.bodyMedium.copyWith(color: LudoColors.textMedium),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    final color = colors[index];
                    final isTaken = takenColors.contains(color.toARGB32());

                    return GestureDetector(
                      onTap: isTaken
                          ? null
                          : () {
                              Navigator.pop(context);
                              onColorSelected(color);
                            },
                      child: Opacity(
                        opacity: isTaken ? 0.25 : 1.0,
                        child: Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: isTaken ? 1 : 3,
                                ),
                                boxShadow: isTaken
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.4),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                              ),
                              child: isTaken
                                  ? const Icon(Icons.close, color: Colors.white, size: 24)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              colorNames[index],
                              style: TextStyle(
                                color: isTaken ? LudoColors.textMedium : Colors.white,
                                fontWeight: isTaken ? FontWeight.normal : FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: LudoColors.textMedium)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHostGameBottomSheet() {
    int selectedPlayerCount = 4;
    Color selectedColor = LudoColors.redToken;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: LudoColors.darkNavyDark,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Host New Game',
                    style: LudoTextStyles.headlineSmall.copyWith(color: LudoColors.textLight),
                  ),
                  const SizedBox(height: 24),

                  // Player count selection
                  Text(
                    'PLAYER COUNT',
                    style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [2, 3, 4].map((count) {
                      final isSelected = selectedPlayerCount == count;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModalState(() => selectedPlayerCount = count),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LudoColors.brightBlue.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? LudoColors.brightBlue : Colors.white.withValues(alpha: 0.08),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$count Players',
                                style: TextStyle(
                                  color: isSelected ? LudoColors.brightBlue : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Color selection
                  Text(
                    'CHOOSE YOUR COLOR',
                    style: LudoTextStyles.labelSmall.copyWith(color: LudoColors.textMedium, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      LudoColors.redToken,
                      LudoColors.greenToken,
                      LudoColors.yellowToken,
                      LudoColors.blueToken,
                    ].map((color) {
                      final isSelected = selectedColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedColor = color),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 36),

                  GradientButton(
                    label: 'CREATE ROOM',
                    onPressed: () async {
                      Navigator.pop(context);
                      setState(() => _isActionLoading = true);
                      try {
                        final hostName = _firebaseService.currentDisplayName ?? 'Host';
                        final lobbyId = await _firebaseService.createLobby(
                          hostName,
                          selectedPlayerCount,
                          selectedColor,
                        );

                        if (context.mounted) {
                          Navigator.pushNamed(
                            context,
                            '/online/waiting',
                            arguments: lobbyId,
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          _showErrorSnackBar(e.toString());
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isActionLoading = false);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
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
