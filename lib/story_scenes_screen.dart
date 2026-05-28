import 'dart:math' as math;
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'escape_back_wrapper.dart';
import 'game_content.dart';
import 'game_save_service.dart';

const mosaicCompletedGamePagesKey = 'mosaic_completed_game_pages';
const mosaicSceneCount = 5;
const mosaicEpisodeCount = 12;

class StoryScenesScreen extends StatefulWidget {
  const StoryScenesScreen({super.key});

  @override
  State<StoryScenesScreen> createState() => _StoryScenesScreenState();
}

class _StoryScenesScreenState extends State<StoryScenesScreen> {
  int _completedPages = 0;
  int _currentSceneIndex = 0;
  bool _hasStartedEpisodeOne = false;

  int get _unlockedScenes => _completedPages.clamp(0, mosaicSceneCount);

  bool get _isEpisodeUnlocked => _unlockedScenes >= mosaicSceneCount;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _completedPages = prefs.getInt(mosaicCompletedGamePagesKey) ?? 0;
      _currentSceneIndex =
          (prefs.getInt(GameSaveService.currentSceneKey) ?? 0).clamp(
        0,
        mosaicSceneCount - 1,
      );
      _hasStartedEpisodeOne = _completedPages > 0 ||
          prefs.getInt(GameSaveService.currentSceneKey) != null;
    });
  }

  void _openEpisode(int index) {
    if (index == 0) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => _EpisodeScenesScreen(
            completedPages: _completedPages,
            currentSceneIndex: _currentSceneIndex,
            hasStarted: _hasStartedEpisodeOne,
            onRefresh: _loadProgress,
          ),
        ),
      );
      return;
    }

    _showLockedEpisode(index);
  }

  void _showLockedEpisode(int index) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF070A10),
        behavior: SnackBarBehavior.floating,
        content: Text(
          'EPISODE ${index + 1} LOCKED',
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackWrapper(
      child: Scaffold(
        backgroundColor: const Color(0xFF05050A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              mosaicHomeScreenAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.78)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, safeConstraints) {
                  final isCompact = safeConstraints.maxHeight <= 430;
                  final screenPadding = EdgeInsets.fromLTRB(
                    isCompact ? 34 : 48,
                    isCompact ? 14 : 28,
                    isCompact ? 34 : 48,
                    isCompact ? 18 : 36,
                  );
                  final headerGap = isCompact ? 12.0 : 24.0;
                  final gridSpacing = isCompact ? 10.0 : 16.0;

                  return Padding(
                    padding: screenPadding,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                                size: isCompact ? 18 : 20,
                              ),
                            ),
                            SizedBox(width: isCompact ? 8 : 14),
                            Expanded(
                              child: Text(
                                'STORY EPISODES',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: isCompact ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                            Text(
                              '$_unlockedScenes/$mosaicSceneCount',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: isCompact ? 12 : 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD8D3C8),
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: headerGap),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const columns = 3;
                              const rows = 4;
                              final maxTileWidth = (constraints.maxWidth -
                                      (columns - 1) * gridSpacing) /
                                  columns;
                              final maxTileHeight = (constraints.maxHeight -
                                      (rows - 1) * gridSpacing) /
                                  rows;
                              final tileWidth = math.min(
                                maxTileWidth,
                                maxTileHeight * 16 / 9,
                              );
                              final tileHeight = tileWidth * 9 / 16;
                              final gridWidth = tileWidth * columns +
                                  (columns - 1) * gridSpacing;
                              final gridHeight =
                                  tileHeight * rows + (rows - 1) * gridSpacing;

                              return Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: gridWidth,
                                  height: gridHeight,
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: mosaicEpisodeCount,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: gridSpacing,
                                      crossAxisSpacing: gridSpacing,
                                      childAspectRatio: 16 / 9,
                                    ),
                                    itemBuilder: (context, index) {
                                      final isEpisodeOne = index == 0;
                                      return _StoryEpisodeTile(
                                        index: index,
                                        imageAsset: isEpisodeOne &&
                                                _hasStartedEpisodeOne &&
                                                !_isEpisodeUnlocked
                                            ? mosaicEpisode1SceneAssets.first
                                            : null,
                                        isUnlocked: isEpisodeOne,
                                        isVideoUnlocked:
                                            isEpisodeOne && _isEpisodeUnlocked,
                                        onTap: () => _openEpisode(index),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: isCompact ? 8 : 12),
                        LinearProgressIndicator(
                          value:
                              (_completedPages / mosaicSceneCount).clamp(0, 1),
                          minHeight: 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          color: const Color(0xFFD8D3C8),
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

class _EpisodeScenesScreen extends StatefulWidget {
  const _EpisodeScenesScreen({
    required this.completedPages,
    required this.currentSceneIndex,
    required this.hasStarted,
    required this.onRefresh,
  });

  final int completedPages;
  final int currentSceneIndex;
  final bool hasStarted;
  final VoidCallback onRefresh;

  @override
  State<_EpisodeScenesScreen> createState() => _EpisodeScenesScreenState();
}

class _EpisodeScenesScreenState extends State<_EpisodeScenesScreen> {
  late final int _completedPages = widget.completedPages;

  int get _unlockedScenes {
    if (!widget.hasStarted && _completedPages <= 0) return 0;
    if (_completedPages >= mosaicSceneCount) return mosaicSceneCount;
    return (widget.currentSceneIndex + 1).clamp(1, mosaicSceneCount);
  }

  bool get _isEpisodeUnlocked => _completedPages >= mosaicSceneCount;

  void _openEpisodeVideo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const _EpisodeVideoScreen(),
      ),
    );
  }

  void _showLockedScene(int index) {
    final message = index >= mosaicSceneCount
        ? 'COMPLETE ALL 5 SCENES'
        : 'COMPLETE SCENE ${index + 1}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF070A10),
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  void _previewScene(int index) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Scene Preview',
      barrierColor: Colors.black.withValues(alpha: 0.78),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1160),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        mosaicEpisode1SceneAssets[index],
                        fit: BoxFit.cover,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
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
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const columns = 3;
    const rows = 2;
    return EscapeBackWrapper(
      onBack: widget.onRefresh,
      child: Scaffold(
        backgroundColor: const Color(0xFF05050A),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(mosaicHomeScreenAsset, fit: BoxFit.cover),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.78)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, safeConstraints) {
                  final isCompact = safeConstraints.maxHeight <= 430;
                  final spacing = isCompact ? 12.0 : 16.0;
                  final screenPadding = EdgeInsets.fromLTRB(
                    isCompact ? 34 : 48,
                    isCompact ? 14 : 44,
                    isCompact ? 34 : 48,
                    isCompact ? 18 : 64,
                  );

                  return Padding(
                    padding: screenPadding,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back',
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                widget.onRefresh();
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white70,
                                size: isCompact ? 18 : 20,
                              ),
                            ),
                            SizedBox(width: isCompact ? 8 : 14),
                            Expanded(
                              child: Text(
                                'EPISODE 1',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: isCompact ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 14 : 32),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final maxTileWidth = (constraints.maxWidth -
                                      (columns - 1) * spacing) /
                                  columns;
                              final maxTileHeight = (constraints.maxHeight -
                                      (rows - 1) * spacing) /
                                  rows;
                              final tileWidth = math.min(
                                maxTileWidth,
                                maxTileHeight * 16 / 9,
                              );
                              final tileHeight = tileWidth * 9 / 16;
                              final gridWidth =
                                  tileWidth * columns + (columns - 1) * spacing;
                              final gridHeight =
                                  tileHeight * rows + (rows - 1) * spacing;

                              return Align(
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  width: gridWidth,
                                  height: gridHeight,
                                  child: GridView.builder(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: mosaicSceneCount + 1,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      mainAxisSpacing: spacing,
                                      crossAxisSpacing: spacing,
                                      childAspectRatio: 16 / 9,
                                    ),
                                    itemBuilder: (context, index) {
                                      final isEpisodeTile =
                                          index == mosaicSceneCount;
                                      final isUnlocked = isEpisodeTile
                                          ? _isEpisodeUnlocked
                                          : index < _unlockedScenes;
                                      return _StorySceneTile(
                                        index: index,
                                        imageAsset: isEpisodeTile
                                            ? null
                                            : mosaicEpisode1SceneAssets[index],
                                        isEpisodeTile: isEpisodeTile,
                                        isUnlocked: isUnlocked,
                                        onTap: isUnlocked
                                            ? isEpisodeTile
                                                ? _openEpisodeVideo
                                                : () => _previewScene(index)
                                            : () => _showLockedScene(index),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
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

class _StoryEpisodeTile extends StatelessWidget {
  const _StoryEpisodeTile({
    required this.index,
    required this.imageAsset,
    required this.isUnlocked,
    required this.isVideoUnlocked,
    required this.onTap,
  });

  final int index;
  final String? imageAsset;
  final bool isUnlocked;
  final bool isVideoUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: isUnlocked
                ? const Color(0xFF1E1D1A).withValues(alpha: 0.78)
                : Colors.black.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageAsset case final image?)
                Image.asset(image, fit: BoxFit.cover),
              if (isVideoUnlocked)
                const Center(
                  child: Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                )
              else if (!isUnlocked)
                Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white.withValues(alpha: 0.34),
                    size: 34,
                  ),
                ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'EPISODE ${index + 1}',
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isUnlocked
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorySceneTile extends StatelessWidget {
  const _StorySceneTile({
    required this.index,
    required this.imageAsset,
    required this.isEpisodeTile,
    required this.isUnlocked,
    required this.onTap,
  });

  final int index;
  final String? imageAsset;
  final bool isEpisodeTile;
  final bool isUnlocked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: isUnlocked
                      ? const Color(0xFF1E1D1A).withValues(alpha: 0.78)
                      : Colors.black.withValues(alpha: 0.62),
                ),
                if (isUnlocked)
                  if (imageAsset case final image?)
                    Image.asset(
                      image,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF2A2823).withValues(alpha: 0.9),
                            const Color(0xFF11100E).withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                    ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: isUnlocked ? 0.52 : 0.3),
                      ],
                    ),
                  ),
                ),
                if (!isUnlocked || isEpisodeTile)
                  Center(
                    child: Icon(
                      isUnlocked && isEpisodeTile
                          ? Icons.play_circle_outline_rounded
                          : Icons.lock_rounded,
                      color: isUnlocked
                          ? const Color(0xFFD8D3C8)
                          : Colors.white.withValues(alpha: 0.34),
                      size: 34,
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      isEpisodeTile ? 'EPISODE 1' : 'SCENE ${index + 1}',
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isUnlocked
                          ? Colors.white.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodeVideoScreen extends StatefulWidget {
  const _EpisodeVideoScreen();

  @override
  State<_EpisodeVideoScreen> createState() => _EpisodeVideoScreenState();
}

class _EpisodeVideoScreenState extends State<_EpisodeVideoScreen> {
  late final Player _player;
  late final VideoController _controller;
  StreamSubscription<bool>? _completedSubscription;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _completedSubscription = _player.stream.completed.listen((completed) {
      if (completed && mounted) {
        Navigator.of(context).pop();
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    await _player.open(
      Media('asset:///$mosaicEpisode1UnlockVideoAsset'),
      play: false,
    );
    await _player.play();
    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    _completedSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: _isReady
                  ? Video(controller: _controller, controls: NoVideoControls)
                  : const CircularProgressIndicator(color: Color(0xFFD8D3C8)),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white70,
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
