import 'dart:ui';

import 'package:flutter/material.dart';

Future<void> showPauseMenu(
  BuildContext context, {
  VoidCallback? onSaveGame,
  VoidCallback? onLoadGame,
  VoidCallback? onNewGame,
  VoidCallback? onDifficulty,
  VoidCallback? onResetGridSequence,
  VoidCallback? onQuitGame,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Pause Menu',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF0B1118),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD8D3C8).withValues(alpha: 0.28),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x99000000),
                    blurRadius: 32,
                    offset: Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'PAUSED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PauseButton(
                      label: 'RESUME',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (onSaveGame != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'SAVE GAME',
                        icon: Icons.save_outlined,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSaveGame();
                        },
                      ),
                    ],
                    if (onLoadGame != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'LOAD GAME',
                        icon: Icons.folder_open_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onLoadGame();
                        },
                      ),
                    ],
                    if (onNewGame != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'NEW GAME',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onNewGame();
                        },
                      ),
                    ],
                    if (onDifficulty != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'DIFFICULTY',
                        icon: Icons.tune_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onDifficulty();
                        },
                      ),
                    ],
                    if (onResetGridSequence != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'RESET GRID SEQUENCE',
                        icon: Icons.refresh_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onResetGridSequence();
                        },
                      ),
                    ],
                    if (onQuitGame != null) ...[
                      const SizedBox(height: 10),
                      _PauseButton(
                        label: 'QUIT GAME',
                        icon: Icons.logout_rounded,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onQuitGame();
                        },
                      ),
                    ],
                    const SizedBox(height: 10),
                    _PauseButton(
                      label: 'QUIT TO MAIN MENU',
                      icon: Icons.home_rounded,
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          context,
                          rootNavigator: true,
                        ).popUntil((route) => route.isFirst);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

class _PauseButton extends StatelessWidget {
  const _PauseButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        textStyle: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}
