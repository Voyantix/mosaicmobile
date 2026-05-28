import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'game_content.dart';
import 'main_menu_screen.dart';

class BootSplashScreen extends StatefulWidget {
  const BootSplashScreen({super.key});

  @override
  State<BootSplashScreen> createState() => _BootSplashScreenState();
}

class _BootSplashScreenState extends State<BootSplashScreen> {
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<bool>? _completedSubscription;
  bool _isReady = false;
  bool _didFinish = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed && !_didFinish) {
        _didFinish = true;
        _openMainMenu();
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _player.open(
        Media('asset:///$mosaicTitleSequenceAsset'),
        play: false,
      );
      await _player.play();
    } catch (_) {
      _openMainMenu();
      return;
    }

    if (!mounted) return;
    setState(() {
      _isReady = true;
    });
  }

  void _openMainMenu() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _completedSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openMainMenu,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: _isReady
              ? Video(
                  controller: _controller,
                  controls: NoVideoControls,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}
