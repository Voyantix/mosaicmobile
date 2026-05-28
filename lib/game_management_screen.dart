import 'dart:ui';

import 'package:flutter/material.dart';

import 'cloud_saves_screen.dart';
import 'escape_back_wrapper.dart';
import 'game_content.dart';
import 'game_save_service.dart';
import 'save_slots_screen.dart';
import 'screens/game/mosaic_story_screen.dart';

class GameManagementScreen extends StatefulWidget {
  const GameManagementScreen({super.key});

  @override
  State<GameManagementScreen> createState() => _GameManagementScreenState();
}

class _GameManagementScreenState extends State<GameManagementScreen> {
  String? _savedAt;

  @override
  void initState() {
    super.initState();
    _loadSavedAt();
  }

  Future<void> _loadSavedAt() async {
    final savedAt = await GameSaveService.savedAtLabel();
    if (mounted) {
      setState(() => _savedAt = savedAt);
    }
  }

  Future<void> _newGame() async {
    await GameSaveService.startNewGame();
    if (!mounted) return;
    await _openLaunchScreen();
  }

  Future<void> _continueGame() async {
    await GameSaveService.loadActiveGame();
    if (!mounted) return;

    await _openLaunchScreen();
  }

  Future<void> _loadGame() async {
    final loaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SaveSlotsScreen(mode: SaveSlotMode.load),
      ),
    );
    if (!mounted) return;

    if (loaded ?? false) await _openLaunchScreen();
  }

  Future<void> _openAccount() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CloudSavesScreen()),
    );
  }

  void _showAccountInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        title: const Text(
          'VOYANTIX ACCOUNT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        content: const SizedBox(
          width: 420,
          child: Text(
            'Mosaic saves progress to local memory on this PC.\n\nSign up for a free Voyantix account to help protect your gameplay data and back up progress, achievements, and future unlocks to the cloud.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openLaunchScreen() {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MosaicStoryScreen(
          title: 'MOSAIC',
          subtitle: 'MOSAIC',
          imagePath: mosaicSceneAsset,
          logs: mosaicStoryLogs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackWrapper(
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              mosaicSceneAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.72)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight <= 430;
                  final horizontalPadding = isCompact ? 42.0 : 72.0;
                  final verticalPadding = isCompact ? 18.0 : 42.0;
                  final titleSize = isCompact ? 30.0 : 38.0;
                  final titleGap = isCompact ? 16.0 : 28.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 448),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'MOSAIC',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: titleSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _savedAt == null
                                          ? 'NO SAVED GAME'
                                          : 'LAST SAVE $_savedAt',
                                      style: TextStyle(
                                        fontFamily: 'Orbitron',
                                        fontSize: 10,
                                        color: Colors.white
                                            .withValues(alpha: 0.48),
                                        letterSpacing: 1.4,
                                      ),
                                    ),
                                    SizedBox(height: titleGap),
                                    _GameActionButton(
                                      label: 'CONTINUE',
                                      icon: Icons.play_circle_outline_rounded,
                                      onPressed: _continueGame,
                                      isPrimary: true,
                                    ),
                                    _GameActionButton(
                                      label: 'LOAD GAME',
                                      icon: Icons.folder_open_rounded,
                                      onPressed: _loadGame,
                                    ),
                                    _GameActionButton(
                                      label: 'NEW GAME',
                                      icon: Icons.add_circle_outline_rounded,
                                      onPressed: _newGame,
                                    ),
                                    _AccountActionRow(
                                      onAccountPressed: _openAccount,
                                      onInfoPressed: _showAccountInfo,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountActionRow extends StatelessWidget {
  const _AccountActionRow({
    required this.onAccountPressed,
    required this.onInfoPressed,
  });

  final VoidCallback onAccountPressed;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).height <= 430;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 8 : 10),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: isCompact ? 38 : 48,
              child: FilledButton.icon(
                onPressed: onAccountPressed,
                icon: Icon(
                  Icons.account_circle_rounded,
                  size: isCompact ? 16 : 20,
                ),
                label: const Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('ACCOUNT', maxLines: 1),
                  ),
                ),
                style: _secondaryActionStyle(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: isCompact ? 38 : 48,
            height: isCompact ? 38 : 48,
            child: IconButton(
              tooltip: 'Account info',
              onPressed: onInfoPressed,
              icon: Icon(
                Icons.info_outline_rounded,
                size: isCompact ? 16 : 20,
              ),
              style: IconButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black.withValues(alpha: 0.34),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameActionButton extends StatelessWidget {
  const _GameActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).height <= 430;

    return Padding(
      padding: EdgeInsets.only(bottom: isCompact ? 8 : 10),
      child: SizedBox(
        height: isCompact ? 38 : 48,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: isCompact ? 16 : 20),
          label: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1),
            ),
          ),
          style: isPrimary ? _primaryActionStyle() : _secondaryActionStyle(),
        ),
      ),
    );
  }
}

ButtonStyle _primaryActionStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    textStyle: const TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 13,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.8,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: const BorderSide(color: Colors.white),
    ),
  );
}

ButtonStyle _secondaryActionStyle() {
  return FilledButton.styleFrom(
    backgroundColor: Colors.black.withValues(alpha: 0.34),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    textStyle: const TextStyle(
      fontFamily: 'Orbitron',
      fontSize: 13,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.8,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
  );
}
