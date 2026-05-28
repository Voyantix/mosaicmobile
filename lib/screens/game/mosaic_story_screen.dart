import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game_difficulty.dart';
import '../../game_save_service.dart';
import '../../pause_menu.dart';
import '../../story_scenes_screen.dart';
import 'mosaic_game.dart';

class StoryLog {
  final String timestamp;
  final String sender;
  final String title;
  final String content;

  const StoryLog({
    required this.timestamp,
    required this.sender,
    required this.title,
    required this.content,
  });
}

class MosaicStoryScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String? imagePath;
  final List<StoryLog> logs;

  const MosaicStoryScreen({
    super.key,
    required this.title,
    required this.subtitle,
    this.imagePath,
    required this.logs,
  });

  @override
  State<MosaicStoryScreen> createState() => _MosaicStoryScreenState();
}

class _MosaicStoryScreenState extends State<MosaicStoryScreen>
    with SingleTickerProviderStateMixin {
  bool _isLaunching = false;
  late AnimationController _glowController;
  final FocusNode _focusNode = FocusNode();
  GameDifficulty _difficulty = GameDifficulty.hard;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _loadDifficulty();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _triggerLaunchSequence() {
    setState(() {
      _isLaunching = true;
    });

    Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EchoGridScreen()),
        );
      }
    });
  }

  Future<void> _loadDifficulty() async {
    final difficulty = await GameDifficulty.load();
    if (mounted) {
      setState(() => _difficulty = difficulty);
    }
  }

  Future<void> _setDifficulty(GameDifficulty difficulty) async {
    if (_difficulty == difficulty) return;

    setState(() => _difficulty = difficulty);
    await difficulty.save();
    await GameSaveService.resetGridSequence();
    await GameSaveService.saveActiveGame();
  }

  void _openStoryEpisodes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const StoryScenesScreen()),
    );
  }

  void _showDifficultyMenu() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0B1118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withOpacity(0.14)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'DIFFICULTY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 20),
                _LaunchDifficultySelector(
                  selectedDifficulty: _difficulty,
                  onChanged: (difficulty) {
                    Navigator.of(context).pop();
                    _setDifficulty(difficulty);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        !_isLaunching) {
      showPauseMenu(
        context,
        onResetGridSequence: () => _showResetWarningDialog(context),
        onQuitGame: () => Navigator.of(context).pop(),
      );
    }
  }

  void _showResetWarningDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.85),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FadeTransition(
            opacity: anim1,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic),
              ),
              child: AlertDialog(
                backgroundColor: const Color(0xFF0F131A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFFD8D3C8).withOpacity(0.2),
                  ),
                ),
                title: const Text(
                  'RESET SEQUENCE?',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                  textAlign: TextAlign.center,
                ),
                content: const Text(
                  'This will reset your completion progress, lock the story, and generate a completely new random grid sequence to memorize and solve.\n\nAre you sure you want to continue?',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: Colors.white60,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                actionsAlignment: MainAxisAlignment.center,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CANCEL',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _resetSequenceAndGame();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD8D3C8).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD8D3C8)),
                      ),
                      child: const Text(
                        'RESET GAME',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD8D3C8),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetSequenceAndGame() async {
    await GameSaveService.resetGridSequence();
    HapticFeedback.heavyImpact();

    if (mounted) {
      _showStatus('MOSAIC GRID SEQUENCE RESET');
    }
  }

  void _showStatus(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF05050A),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: const Color(0xFFD8D3C8).withOpacity(0.3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        backgroundColor: const Color(0xFF05050A),
        body: Stack(
          children: [
            // Full-screen card background image
            if (widget.imagePath != null)
              Positioned.fill(
                child: Image.asset(widget.imagePath!, fit: BoxFit.cover),
              ),

            // Gorgeous, deep glassmorphic blur covering the entire screen
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(color: Colors.black.withOpacity(0.65)),
                ),
              ),
            ),

            // Core UI Content
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 36),

                  const Spacer(),

                  // Center Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _triggerLaunchSequence,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'LAUNCH GAME',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _showDifficultyMenu,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black.withOpacity(0.28),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.16),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'DIFFICULTY  ${_difficulty.label.toUpperCase()}',
                                    style: const TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _openStoryEpisodes,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black.withOpacity(0.28),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.16),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'STORY EPISODES',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),

            // Beautiful fullscreen launching overlay
            if (_isLaunching)
              Positioned.fill(
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      color: Colors.black.withOpacity(0.85),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _glowController,
                              builder: (context, child) {
                                return Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.transparent,
                                    border: Border.all(
                                      color:
                                          const Color(0xFFD8D3C8).withOpacity(
                                        0.1 + (_glowController.value * 0.4),
                                      ),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            const Color(0xFFD8D3C8).withOpacity(
                                          0.2 * _glowController.value,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFFD8D3C8),
                                      ),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 40),
                            Text(
                              'LOADING WORLD...',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD8D3C8).withOpacity(0.8),
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'LOADING COGNITIVE SEQUENCE 01%',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 9,
                                color: Colors.white30,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LaunchDifficultySelector extends StatelessWidget {
  const _LaunchDifficultySelector({
    required this.selectedDifficulty,
    required this.onChanged,
  });

  final GameDifficulty selectedDifficulty;
  final ValueChanged<GameDifficulty> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final difficulty in GameDifficulty.values) ...[
          Expanded(
            child: SizedBox(
              height: 40,
              child: OutlinedButton(
                onPressed: () => onChanged(difficulty),
                style: OutlinedButton.styleFrom(
                  backgroundColor: difficulty == selectedDifficulty
                      ? const Color(0xFFD8D3C8)
                      : Colors.black.withValues(alpha: 0.26),
                  foregroundColor: difficulty == selectedDifficulty
                      ? Colors.black
                      : Colors.white70,
                  side: BorderSide(
                    color: difficulty == selectedDifficulty
                        ? const Color(0xFFD8D3C8)
                        : Colors.white.withValues(alpha: 0.16),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    difficulty.label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (difficulty != GameDifficulty.values.last)
            const SizedBox(width: 10),
        ],
      ],
    );
  }
}
