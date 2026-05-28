import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';

import 'game_content.dart';
import 'game_management_screen.dart';
import 'settings_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late final Player _musicPlayer;
  bool _musicEnabled = true;
  double _masterVolume = 0.74;
  double _musicVolume = 0.52;

  @override
  void initState() {
    super.initState();
    _musicPlayer = Player();
    _startMusic();
  }

  @override
  void dispose() {
    _musicPlayer.dispose();
    super.dispose();
  }

  Future<void> _startMusic() async {
    try {
      await _musicPlayer.open(
        Media('asset:///$mosaicBackgroundMusicAsset'),
        play: false,
      );
      await _musicPlayer.setVolume(_musicVolume * _masterVolume * 100);
      await _musicPlayer.setPlaylistMode(PlaylistMode.loop);
      if (_musicEnabled) {
        await _musicPlayer.play();
      }
    } catch (_) {
      // The menu can still run if a local audio asset is missing or unavailable.
    }
  }

  Future<void> _openGameManagement() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GameManagementScreen()),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          musicEnabled: _musicEnabled,
          masterVolume: _masterVolume,
          musicVolume: _musicVolume,
          onMusicEnabledChanged: (enabled) {
            setState(() => _musicEnabled = enabled);
            if (enabled) {
              _musicPlayer.play();
            } else {
              _musicPlayer.pause();
            }
          },
          onMasterVolumeChanged: (value) {
            setState(() => _masterVolume = value);
            _musicPlayer.setVolume(_musicVolume * _masterVolume * 100);
          },
          onMusicVolumeChanged: (value) {
            setState(() => _musicVolume = value);
            _musicPlayer.setVolume(_musicVolume * _masterVolume * 100);
          },
        ),
      ),
    );
  }

  void _showHowToPlay() {
    showDialog<void>(
      context: context,
      builder: (context) => const _MenuDialog(
        title: 'HOW TO PLAY',
        children: [
          _HowToPlayRow(
            label: 'Goal',
            value: 'Find each hidden panel in the correct sequence.',
          ),
          _HowToPlayRow(
            label: 'Memory',
            value:
                'Correct panels stay marked. A wrong panel restarts the run.',
          ),
          _HowToPlayRow(
            label: 'Violation',
            value: 'Three row or column selections in succession is Game Over.',
          ),
          _HowToPlayRow(
            label: 'Controls',
            value: 'Use the mouse to select panels. Press ESC for the menu.',
          ),
        ],
      ),
    );
  }

  void _showQuit() {
    showDialog<void>(
      context: context,
      builder: (context) => _MenuDialog(
        title: 'QUIT',
        children: [
          const Text(
            'Exit Mosaic and close the game?',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('CANCEL'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => exit(0),
                  child: const Text('QUIT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCredits() {
    showDialog<void>(
      context: context,
      builder: (context) => const _MenuDialog(
        title: 'CREDITS',
        children: [
          Text(
            'Mosaic\nVoyantix Entertainment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.5,
              letterSpacing: 1.4,
            ),
          ),
          SizedBox(height: 22),
          Text(
            'Copyright (C) 2026 Voyantix Entertainment. All rights reserved. Mosaic, Mosaic Shorts, related story content, gameplay format, artwork, audio, video, logos, and associated materials are proprietary works of Voyantix Entertainment unless otherwise stated.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            mosaicHomeScreenAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.88),
                  Colors.black.withValues(alpha: 0.54),
                  Colors.black.withValues(alpha: 0.2),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.1)),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight <= 430;
                final horizontalPadding = isCompact ? 42.0 : 72.0;
                final verticalPadding = isCompact ? 18.0 : 42.0;
                final titleSize = isCompact ? 34.0 : 46.0;
                final subtitleSize = isCompact ? 11.0 : 15.0;
                final menuGap = isCompact ? 18.0 : 44.0;

                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    verticalPadding,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 382),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'MOSAIC',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ECHO GRID',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: subtitleSize,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD8D3C8),
                                letterSpacing: 4,
                              ),
                            ),
                            SizedBox(height: menuGap),
                            _MenuButton(
                              label: 'PLAY',
                              icon: Icons.save_rounded,
                              onPressed: _openGameManagement,
                              isPrimary: true,
                            ),
                            _MenuButton(
                              label: 'HOW TO PLAY',
                              icon: Icons.help_outline_rounded,
                              onPressed: _showHowToPlay,
                            ),
                            _MenuButton(
                              label: 'SETTINGS',
                              icon: Icons.tune_rounded,
                              onPressed: _openSettings,
                            ),
                            _MenuButton(
                              label: 'CREDITS',
                              icon: Icons.info_outline_rounded,
                              onPressed: _showCredits,
                            ),
                            _MenuButton(
                              label: 'QUIT',
                              icon: Icons.logout_rounded,
                              onPressed: _showQuit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
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
    final background =
        isPrimary ? Colors.white : Colors.black.withValues(alpha: 0.34);
    final foreground = isPrimary ? Colors.black : Colors.white;

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
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 18),
            textStyle: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: BorderSide(
                color: isPrimary
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDialog extends StatelessWidget {
  const _MenuDialog({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0B1118),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
      content: SizedBox(
        width: 620,
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white, fontSize: 17),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _HowToPlayRow extends StatelessWidget {
  const _HowToPlayRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'Orbitron',
                color: Color(0xFFD8D3C8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white70,
                height: 1.45,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
