import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../cloud_saves_screen.dart';
import '../../game_content.dart';
import '../../game_difficulty.dart';
import '../../game_save_service.dart';
import '../../pause_menu.dart';
import '../../save_slots_screen.dart';
import '../../story_scenes_screen.dart';
import '../../voyantix_auth_service.dart';

void main() {
  runApp(const EchoGridApp());
}

class EchoGridApp extends StatelessWidget {
  const EchoGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Echo Grid',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff6fb7b7),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xff101417),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: const Color(0xfff3f0e8),
              displayColor: const Color(0xfff3f0e8),
            ),
      ),
      home: const EchoGridScreen(),
    );
  }
}

class GameWorld {
  const GameWorld({
    required this.title,
    required this.imageAsset,
    required this.storyAsset,
    required this.imageAspectRatio,
    required this.targets,
  });

  final String title;
  final String imageAsset;
  final String storyAsset;
  final double imageAspectRatio;
  final List<EchoTarget> targets;
}

class EchoTarget {
  const EchoTarget({required this.rect});

  final Rect rect;
}

enum _SaveChoice { local, account }

class EchoGridScreen extends StatefulWidget {
  const EchoGridScreen({super.key});

  @override
  State<EchoGridScreen> createState() => _EchoGridScreenState();
}

class _EchoGridScreenState extends State<EchoGridScreen>
    with TickerProviderStateMixin {
  static const _saveChoicePromptSeenKey = 'mosaic_save_choice_prompt_seen';
  static const _world = GameWorld(
    title: 'Mosaic',
    imageAsset: mosaicSceneAsset,
    storyAsset: mosaicStoryAsset,
    imageAspectRatio: 16 / 9,
    targets: <EchoTarget>[
      EchoTarget(rect: Rect.fromLTWH(0.07, 0.08, 0.18, 0.18)),
      EchoTarget(rect: Rect.fromLTWH(0.31, 0.10, 0.18, 0.18)),
      EchoTarget(rect: Rect.fromLTWH(0.58, 0.11, 0.18, 0.18)),
      EchoTarget(rect: Rect.fromLTWH(0.77, 0.30, 0.17, 0.18)),
      EchoTarget(rect: Rect.fromLTWH(0.13, 0.45, 0.20, 0.20)),
      EchoTarget(rect: Rect.fromLTWH(0.45, 0.56, 0.20, 0.20)),
      EchoTarget(rect: Rect.fromLTWH(0.70, 0.70, 0.18, 0.18)),
    ],
  );

  final FocusNode _focusNode = FocusNode();
  late final AnimationController _missController;
  late final AnimationController _unlockController;
  int _targetIndex = 1;
  int? _missedCell;
  final Set<int> _foundCells = <int>{};
  final List<int> _recentWrongClickCells = <int>[];
  bool _isPanelMinimized = false;
  late final AnimationController _successController;
  int? _latestFoundCell;
  final Set<int> _unlockedClues = <int>{};
  GameDifficulty _difficulty = GameDifficulty.hard;
  int _sceneIndex = 0;

  late List<EchoTarget> _targets = List.from(_world.targets);

  String get _sceneImageAsset => mosaicEpisode1SceneAssets[_sceneIndex.clamp(
        0,
        mosaicEpisode1SceneAssets.length - 1,
      )];

  int get _gridColumns => _difficulty.columns;

  int get _gridRows => _difficulty.rows;

  bool get _isComplete => _targetIndex >= _targets.length;

  EchoTarget get _currentTarget => _targets[_targetIndex];

  Map<int, int> get _foundCellNumbers {
    final numbers = <int, int>{};
    for (var index = 0; index < _targetIndex; index += 1) {
      numbers[_cellForRect(_targets[index].rect)] = index + 1;
    }
    return numbers;
  }

  Future<void> _createNewSequence() async {
    await GameSaveService.resetGridSequence();
    await _loadSequence();
  }

  Future<void> _loadSequence() async {
    _difficulty = await GameDifficulty.load();
    final prefs = await SharedPreferences.getInstance();
    _sceneIndex =
        (prefs.getInt(GameSaveService.currentSceneKey) ?? 0).clamp(0, 4);
    List<String>? seqStrings = prefs.getStringList('mosaic_game_pattern_order');
    if (seqStrings == null || seqStrings.length != 7) {
      final indices = [0, 1, 2, 3, 4, 5, 6];
      indices.shuffle();
      seqStrings = indices.map((i) => i.toString()).toList();
      await prefs.setStringList('mosaic_game_pattern_order', seqStrings);
    }
    final seqInts = seqStrings.map((s) => int.parse(s)).toList();
    final progress = prefs.getInt(GameSaveService.progressKey) ?? 1;
    _applySequence(seqInts, targetIndex: progress);
  }

  void _applySequence(List<int> sequence, {int targetIndex = 1}) {
    if (mounted) {
      setState(() {
        _targets = sequence.map((idx) => _world.targets[idx]).toList();
        _targetIndex = targetIndex.clamp(1, _targets.length);
        _foundCells.clear();
        for (var index = 0; index < _targetIndex; index += 1) {
          _foundCells.add(_cellForRect(_targets[index].rect));
        }
        _recentWrongClickCells.clear();
        _missedCell = null;
        _latestFoundCell = null;
        _unlockedClues.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSequence();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSaveChoicePromptIfNeeded();
    });
    _missController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _missedCell = null;
            _foundCells.clear();
            _foundCells.add(_cellForRect(_targets[0].rect));
          });
          _missController.reset();
        }
      });
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _successController.reset();
        }
      });
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
    // Auto-minimize after a brief delay so user sees clue panel on load
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() {
          _isPanelMinimized = true;
        });
      }
    });
  }

  Future<void> _showSaveChoicePromptIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenPrompt = prefs.getBool(_saveChoicePromptSeenKey) ?? false;
    if (!mounted || hasSeenPrompt || VoyantixAuthService.currentUser != null) {
      return;
    }

    final choice = await showDialog<_SaveChoice>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = math.max(280.0, constraints.maxWidth - 64.0);
          final dialogWidth = math.min(560.0, availableWidth);

          return AlertDialog(
            backgroundColor: const Color(0xFF0B1118),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
            title: const Text(
              'SAVE PROGRESS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            content: SizedBox(
              width: dialogWidth,
              child: const Text(
                'Mosaic can save locally on this PC, or you can sign in to prepare cloud saves with your Voyantix account.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.45),
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(_SaveChoice.local),
                child: const Text('LOCAL SAVE'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_SaveChoice.account),
                child: const Text('SIGN IN'),
              ),
            ],
          );
        },
      ),
    );

    await prefs.setBool(_saveChoicePromptSeenKey, true);
    if (!mounted || choice != _SaveChoice.account) {
      _focusNode.requestFocus();
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CloudSavesScreen()),
    );
    if (mounted) _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _missController.dispose();
    _successController.dispose();
    _unlockController.dispose();
    super.dispose();
  }

  void _handleImageTap(TapUpDetails details, Size imageSize) {
    if (_isComplete || _missedCell != null) {
      return;
    }

    final position = details.localPosition;
    if (position.dx < 0 ||
        position.dy < 0 ||
        position.dx > imageSize.width ||
        position.dy > imageSize.height) {
      return;
    }

    final tappedCell = _cellForOffset(position, imageSize);
    final targetCell = _cellForRect(_currentTarget.rect);
    final isCorrectHit = tappedCell == targetCell;

    _recordClick(tappedCell, isCorrectHit: isCorrectHit);
    if (_isGameViolation()) {
      _showGameOver();
      return;
    }

    if (isCorrectHit) {
      final nextIndex = _targetIndex + 1;
      setState(() {
        _foundCells.add(targetCell);
        _latestFoundCell = targetCell;
        _targetIndex = nextIndex;
      });
      _saveProgress(nextIndex);
      _successController.forward(from: 0);
      if (nextIndex >= _targets.length) {
        _unlockController.forward(from: 0);
        _markCompleted();
      }
      return;
    }

    setState(() {
      _missedCell = tappedCell;
      _targetIndex = 1;
    });
    _saveProgress(1);
    _unlockController.reset();
    _missController.forward(from: 0);
  }

  Future<void> _saveProgress(int targetIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(GameSaveService.progressKey, targetIndex);
    await GameSaveService.saveActiveGame(targetIndex: targetIndex);
  }

  void _recordClick(int cell, {required bool isCorrectHit}) {
    if (isCorrectHit) {
      _recentWrongClickCells.clear();
      return;
    }

    _recentWrongClickCells.add(cell);
    if (_recentWrongClickCells.length > 3) {
      _recentWrongClickCells.removeAt(0);
    }
  }

  bool _isGameViolation() {
    if (_recentWrongClickCells.length < 3) return false;

    final rows =
        _recentWrongClickCells.map((cell) => cell ~/ _gridColumns).toSet();
    final columns =
        _recentWrongClickCells.map((cell) => cell % _gridColumns).toSet();
    return rows.length == 1 || columns.length == 1;
  }

  Future<void> _showGameOver() async {
    HapticFeedback.heavyImpact();
    _missController.reset();
    _unlockController.reset();

    if (mounted) {
      setState(() {
        _missedCell = null;
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.42)),
        ),
        title: const Text(
          'GAME OVER',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 3,
          ),
        ),
        content: const Text(
          'Pattern scanning detected.\nThe sequence has reset.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    await _createNewSequence();
    _focusNode.requestFocus();
  }

  Future<void> _markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final wasCompleted = prefs.getBool('mosaic_game_completed') ?? false;
    await prefs.setBool('mosaic_game_completed', true);
    if (!wasCompleted) {
      final completedPages = prefs.getInt(mosaicCompletedGamePagesKey) ?? 0;
      await prefs.setInt(
        mosaicCompletedGamePagesKey,
        math.max(completedPages, _sceneIndex + 1),
      );
      await GameSaveService.saveActiveGame(targetIndex: _targetIndex);
    }
  }

  int _cellForOffset(Offset offset, Size imageSize) {
    final column = (offset.dx / imageSize.width * _gridColumns).floor().clamp(
          0,
          _gridColumns - 1,
        );
    final row = (offset.dy / imageSize.height * _gridRows).floor().clamp(
          0,
          _gridRows - 1,
        );
    return row * _gridColumns + column;
  }

  int _cellForRect(Rect rect) {
    final column = (rect.center.dx * _gridColumns).floor().clamp(
          0,
          _gridColumns - 1,
        );
    final row = (rect.center.dy * _gridRows).floor().clamp(0, _gridRows - 1);
    return row * _gridColumns + column;
  }

  void _openStoryScenes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoryScenesScreen(),
      ),
    );
  }

  Future<void> _openNextScene() async {
    final nextScene = (_sceneIndex + 1).clamp(0, mosaicSceneCount - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(GameSaveService.currentSceneKey, nextScene);
    await prefs.setInt(
      mosaicCompletedGamePagesKey,
      math.max(prefs.getInt(mosaicCompletedGamePagesKey) ?? 0, _sceneIndex + 1),
    );
    await GameSaveService.resetCurrentSceneSequence();
    await GameSaveService.saveActiveGame(targetIndex: 1);
    await _loadSequence();
    _unlockController.reset();
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      showPauseMenu(
        context,
        onSaveGame: _saveGame,
        onDifficulty: _showDifficultyMenu,
        onResetGridSequence: _resetGridSequence,
        onQuitGame: _quitToGameMenu,
      );
    }
  }

  Future<void> _showDifficultyMenu() async {
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF0B1118),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
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
                Row(
                  children: [
                    for (final difficulty in GameDifficulty.values) ...[
                      Expanded(
                        child: SizedBox(
                          height: 42,
                          child: OutlinedButton(
                            onPressed: () async {
                              Navigator.of(context).pop();
                              await difficulty.save();
                              await GameSaveService.resetCurrentSceneSequence();
                              await GameSaveService.saveActiveGame(
                                targetIndex: 1,
                              );
                              if (!mounted) return;
                              await _loadSequence();
                              _showStatus(
                                'DIFFICULTY ${difficulty.label.toUpperCase()}',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              backgroundColor: difficulty == _difficulty
                                  ? const Color(0xFFD8D3C8)
                                  : Colors.transparent,
                              foregroundColor: difficulty == _difficulty
                                  ? Colors.black
                                  : Colors.white70,
                              side: BorderSide(
                                color: difficulty == _difficulty
                                    ? const Color(0xFFD8D3C8)
                                    : Colors.white.withValues(alpha: 0.16),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: Text(
                              difficulty.label.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (difficulty != GameDifficulty.values.last)
                        const SizedBox(width: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _quitToGameMenu() {
    Navigator.of(context).pop();
  }

  Future<void> _saveGame() async {
    final slotIndex = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => SaveSlotsScreen(
          mode: SaveSlotMode.save,
          targetIndex: _targetIndex,
          closeAfterSave: true,
        ),
      ),
    );
    if (mounted && slotIndex != null) {
      _showStatus('SAVED TO SLOT ${slotIndex + 1}');
    }
  }

  Future<void> _resetGridSequence() async {
    await GameSaveService.resetGridSequence();
    await GameSaveService.saveActiveGame(targetIndex: 1);
    if (!mounted) return;

    await _loadSequence();
    if (mounted) {
      _showStatus('GRID SEQUENCE RESET');
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= 1000 && size.height >= 560;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: Scaffold(
        body: isWide ? _buildDesktopLayout() : _buildPhoneLayoutStack(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Stack(
      children: [
        Positioned.fill(child: _buildImageBoard(fullBleed: true)),
        if (!_isComplete) _buildDesktopClueDrawer(),
        if (_isComplete) _buildUnlockOverlay(),
      ],
    );
  }

  Widget _buildPhoneLayoutStack() {
    return Stack(
      children: [
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildPhoneLayout(),
              ),
            ),
          ),
        ),
        if (_isComplete) _buildUnlockOverlay(),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactLandscape = constraints.maxHeight <= 430;
        final headerHeight = isCompactLandscape ? 0.0 : 32.0;
        final panelHeight = math.min(
          isCompactLandscape ? 214.0 : 290.0,
          constraints.maxHeight * 0.62,
        );
        final minimizedOffset = -(panelHeight - 44);

        return Column(
          children: [
            if (!isCompactLandscape) ...[
              SizedBox(height: headerHeight, child: _buildHeader()),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _unlockController,
                      builder: (context, child) {
                        final scale = 1.0 + (0.08 * _unlockController.value);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: _buildImageBoard(),
                    ),
                  ),
                  // Floating puzzle panel — minimized/expanded by user, hidden when complete
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOutCubic,
                    left: isCompactLandscape ? 8 : 16,
                    right: isCompactLandscape ? 8 : 16,
                    bottom: _isComplete
                        ? -(panelHeight + 32)
                        : _isPanelMinimized
                            ? minimizedOffset
                            : 0.0,
                    child: SizedBox(
                      height: panelHeight,
                      child: _buildPuzzlePanel(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'ESC opens the in-game menu',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: Colors.white.withValues(alpha: 0.46),
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        const Spacer(),
        Text(
          '${math.min(_targetIndex, _targets.length)} / ${_targets.length}',
          style: const TextStyle(
            color: Color(0xffD8D3C8),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildImageBoard({bool fullBleed = false}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                32;
        final widthByHeight = maxHeight * _world.imageAspectRatio;
        final boardWidth = math.min(constraints.maxWidth, widthByHeight);

        return Center(
          child: SizedBox(
            width: boardWidth,
            child: AspectRatio(
              aspectRatio: _world.imageAspectRatio,
              child: LayoutBuilder(
                builder: (context, imageConstraints) {
                  final imageSize = Size(
                    imageConstraints.maxWidth,
                    imageConstraints.maxHeight,
                  );

                  return GestureDetector(
                    onTapUp: (details) => _handleImageTap(details, imageSize),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(fullBleed ? 0 : 8),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            _sceneImageAsset,
                            fit: fullBleed ? BoxFit.cover : BoxFit.contain,
                          ),
                          if (!_isComplete)
                            CustomPaint(
                              painter: GridOverlayPainter(
                                columns: _gridColumns,
                                rows: _gridRows,
                                foundCells: _foundCells,
                                foundCellNumbers: _foundCellNumbers,
                                latestFoundCell: _latestFoundCell,
                                successProgress: _successController,
                                missedCell: _missedCell,
                                missProgress: _missController,
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
      },
    );
  }

  Widget _buildDesktopClueDrawer() {
    const tabWidth = 44.0;
    const panelWidth = 300.0;
    const panelHeight = 360.0;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      top: 0,
      bottom: 0,
      right: _isPanelMinimized ? -panelWidth : 24,
      child: Center(
        child: SizedBox(
          width: tabWidth + panelWidth,
          height: panelHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    _isPanelMinimized = !_isPanelMinimized;
                  });
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xff142126).withValues(alpha: 0.94),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                    border: Border.all(
                      color: const Color(0xffD8D3C8).withValues(alpha: 0.26),
                    ),
                  ),
                  child: SizedBox(
                    width: tabWidth,
                    height: 128,
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: Center(
                        child: Text(
                          _isPanelMinimized ? 'CLUE' : 'HIDE',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xffD8D3C8),
                            letterSpacing: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: panelWidth,
                height: panelHeight,
                child: _buildPuzzlePanel(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnlockOverlay() {
    return Positioned.fill(
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _unlockController,
          builder: (context, child) {
            final value = _unlockController.value;
            final fade = Curves.easeOutCubic.transform(value.clamp(0, 1));
            final pop = Curves.easeOutBack.transform(
              (value / 0.48).clamp(0, 1),
            );
            final flip = Curves.easeInOutCubic.transform(value.clamp(0, 1));
            final rotation = math.sin(flip * math.pi) * math.pi;

            final matrix = Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(rotation);

            return ColoredBox(
              color: Color.lerp(
                Colors.transparent,
                const Color(0xcc050809),
                fade,
              )!,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth - 96;
                  final availableHeight = constraints.maxHeight - 64;
                  final widthFromHeight = availableHeight * 16 / 9;
                  final cardWidth = math.min(
                    availableWidth,
                    math.min(widthFromHeight, 980.0),
                  );
                  final cardHeight = cardWidth * 9 / 16;

                  return Center(
                    child: SizedBox(
                      width: cardWidth,
                      height: cardHeight,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: matrix,
                        child: Transform.scale(
                          scale: 0.72 + (0.28 * pop),
                          child: Opacity(opacity: fade, child: child),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xff1b2326),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(color: Color(0x22D8D3C8), blurRadius: 26),
                BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 42,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: _buildUnlockedImageCard(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPuzzlePanel() {
    return AnimatedBuilder(
      animation: _unlockController,
      builder: (context, child) {
        final pulse = Curves.easeOutBack.transform(
          _unlockController.value.clamp(0, 0.68) / 0.68,
        );
        final settle = Curves.easeInOut.transform(_unlockController.value);
        final lift = _isComplete ? -10.0 * (1 - settle) : 0.0;

        return Transform.translate(
          offset: Offset(0, lift),
          child: Transform.scale(
            scale: _isComplete ? 1 + (0.035 * pulse * (1 - settle)) : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xff1b2326),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xff304349),
                    const Color(0xfff1d07a),
                    _isComplete ? 0.75 * (1 - settle) : 0,
                  )!,
                  width: _isComplete ? 1.4 : 1,
                ),
                boxShadow: [
                  if (_isComplete)
                    BoxShadow(
                      color: Color.lerp(
                        const Color(0x00000000),
                        const Color(0x99f1d07a),
                        (1 - settle) * 0.7,
                      )!,
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 360),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: const ValueKey('echo-prompt'),
            child: _buildEchoPrompt(),
          ),
        ),
      ),
    );
  }

  Widget _buildEchoPrompt() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel handle row — title, score, and minimize/expand chevron
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => _isPanelMinimized = !_isPanelMinimized),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLUE',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${math.min(_targetIndex, _targets.length)} / ${_targets.length}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        color: Color(0xffD8D3C8),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: _isPanelMinimized ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white54,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Find six Mosaic segments in a row to win. One miss resets the lock. Use the arrow button to minimise or open the next clue.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _unlockedClues.contains(_targetIndex)
                      ? const Color(0xffD8D3C8)
                      : Colors.white.withOpacity(0.12),
                  width: 1.4,
                ),
                boxShadow: [
                  if (_unlockedClues.contains(_targetIndex))
                    const BoxShadow(
                      color: Color(0x552aa198),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: Builder(
                  builder: (context) {
                    if (_unlockedClues.contains(_targetIndex)) {
                      return EchoCrop(
                        imageAsset: _sceneImageAsset,
                        sourceRect: _currentTarget.rect,
                      );
                    }

                    return Container(
                      color: const Color(0xff12181b),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white.withOpacity(0.35),
                            size: 28,
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                _unlockedClues.add(_targetIndex);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFD8D3C8,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFFD8D3C8,
                                  ).withOpacity(0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'REVEAL CLUE',
                                    style: TextStyle(
                                      fontFamily: 'Orbitron',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(
              _targets.length,
              (index) => _ProgressPip(isActive: index < _targetIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockedImageCard() {
    return KeyedSubtree(
      key: const ValueKey('image-unlocked'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            _sceneImageAsset,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.16),
                  Colors.black.withValues(alpha: 0.84),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 22,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: Tween<double>(begin: 0.7, end: 1).animate(
                        CurvedAnimation(
                          parent: _unlockController,
                          curve: Curves.elasticOut,
                        ),
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Color(0xffD8D3C8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Image Unlocked',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _openNextScene,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xffD8D3C8),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33D8D3C8),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.skip_next_rounded,
                                color: Color(0xff090f11),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'NEXT SCENE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xff090f11),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _openStoryScenes,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'STORY EPISODES',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white70,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class EchoCrop extends StatefulWidget {
  const EchoCrop({
    required this.imageAsset,
    required this.sourceRect,
    super.key,
  });

  final String imageAsset;
  final Rect sourceRect;

  @override
  State<EchoCrop> createState() => _EchoCropState();
}

class _EchoCropState extends State<EchoCrop> {
  ui.Image? _image;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant EchoCrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageAsset != widget.imageAsset) {
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _resolveImage() {
    _removeListener();
    final provider = AssetImage(widget.imageAsset);
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _image = info.image;
        });
      }
    });
    _stream = stream..addListener(_listener!);
  }

  void _removeListener() {
    final listener = _listener;
    if (listener != null) {
      _stream?.removeListener(listener);
    }
    _listener = null;
    _stream = null;
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      return const ColoredBox(color: Color(0xff253035));
    }

    return CustomPaint(
      painter: EchoCropPainter(image: image, sourceRect: widget.sourceRect),
    );
  }
}

class EchoCropPainter extends CustomPainter {
  const EchoCropPainter({required this.image, required this.sourceRect});

  final ui.Image image;
  final Rect sourceRect;

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSource = Rect.fromLTWH(
      sourceRect.left * image.width,
      sourceRect.top * image.height,
      sourceRect.width * image.width,
      sourceRect.height * image.height,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..colorFilter = const ColorFilter.matrix(<double>[
        0.95,
        0,
        0,
        0,
        8,
        0,
        0.92,
        0,
        0,
        8,
        0,
        0,
        0.86,
        0,
        10,
        0,
        0,
        0,
        1,
        0,
      ]);

    canvas.drawImageRect(image, pixelSource, Offset.zero & size, paint);

    final vignette = Paint()
      ..shader = ui.Gradient.radial(
        size.center(Offset.zero),
        size.longestSide * 0.75,
        const [Color(0x00000000), Color(0x77000000)],
        const [0.35, 1],
      );
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant EchoCropPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.sourceRect != sourceRect;
  }
}

class GridOverlayPainter extends CustomPainter {
  GridOverlayPainter({
    required this.columns,
    required this.rows,
    required this.foundCells,
    required this.foundCellNumbers,
    required this.latestFoundCell,
    required this.successProgress,
    required this.missedCell,
    required this.missProgress,
  }) : super(repaint: Listenable.merge([missProgress, successProgress]));

  final int columns;
  final int rows;
  final Set<int> foundCells;
  final Map<int, int> foundCellNumbers;
  final int? latestFoundCell;
  final Animation<double> successProgress;
  final int? missedCell;
  final Animation<double> missProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / columns;
    final cellHeight = size.height / rows;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    for (var index = 1; index < columns; index += 1) {
      final dx = cellWidth * index;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }

    for (var index = 1; index < rows; index += 1) {
      final dy = cellHeight * index;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }

    for (final cell in foundCells) {
      final isLatest = cell == latestFoundCell && successProgress.value > 0;
      final scale =
          isLatest ? Curves.easeOutBack.transform(successProgress.value) : 1.0;

      // Fade out all found cells smoothly if a miss is animating
      final double fadeOut = missedCell != null
          ? (1.0 - Curves.easeIn.transform(missProgress.value))
          : 1.0;

      final opacity = isLatest ? (successProgress.value * fadeOut) : fadeOut;

      final baseRect = _cellRect(cell, cellWidth, cellHeight).deflate(3);
      final center = baseRect.center;
      final rect = Rect.fromCenter(
        center: center,
        width: baseRect.width * scale,
        height: baseRect.height * scale,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0x55D8D3C8).withOpacity(0.33 * opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xffD8D3C8).withOpacity(opacity),
      );

      final number = foundCellNumbers[cell];
      if (number != null) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$number',
            style: TextStyle(
              color: Colors.white.withOpacity(opacity),
              fontSize: math.max(10, math.min(cellWidth, cellHeight) * 0.2),
              fontWeight: FontWeight.w800,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final badgeSize = math.max(22.0, textPainter.width + 12);
        final badgeRect = Rect.fromLTWH(
          baseRect.right - badgeSize,
          baseRect.top,
          badgeSize,
          badgeSize,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(badgeRect, const Radius.circular(6)),
          Paint()..color = const Color(0xCC050A0F).withOpacity(0.8 * opacity),
        );
        textPainter.paint(
          canvas,
          Offset(
            badgeRect.center.dx - textPainter.width / 2,
            badgeRect.center.dy - textPainter.height / 2,
          ),
        );
      }
    }

    final missed = missedCell;
    if (missed != null) {
      final opacity = 1.0 - Curves.easeOut.transform(missProgress.value);

      // Horizontal decaying sine wave shake: 4 full cycles, amplitude starts at 14px and decays
      final double shakeOffset = 14.0 *
          math.sin(missProgress.value * 8.0 * math.pi) *
          (1.0 - missProgress.value);

      final rect = _cellRect(
        missed,
        cellWidth,
        cellHeight,
      ).deflate(5).translate(shakeOffset, 0.0);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = const Color(0xffff7b6f).withOpacity(0.35 * opacity),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + (missProgress.value * 8)
          ..color = Color.lerp(
            Colors.transparent,
            const Color(0xffff7b6f),
            opacity,
          )!,
      );
    }
  }

  Rect _cellRect(int cell, double cellWidth, double cellHeight) {
    final row = cell ~/ columns;
    final column = cell % columns;
    return Rect.fromLTWH(
      column * cellWidth,
      row * cellHeight,
      cellWidth,
      cellHeight,
    );
  }

  @override
  bool shouldRepaint(covariant GridOverlayPainter oldDelegate) {
    return oldDelegate.columns != columns ||
        oldDelegate.rows != rows ||
        oldDelegate.foundCells != foundCells ||
        oldDelegate.foundCellNumbers != foundCellNumbers ||
        oldDelegate.latestFoundCell != latestFoundCell ||
        oldDelegate.successProgress != successProgress ||
        oldDelegate.missedCell != missedCell ||
        oldDelegate.missProgress != missProgress;
  }
}

class _ProgressPip extends StatelessWidget {
  const _ProgressPip({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: isActive ? 30 : 18,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xffD8D3C8) : const Color(0xff34464b),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

enum StoryReadingMode { light, dark, sepia }

class FullScreenStoryReaderScreen extends StatefulWidget {
  final String title;
  final String storyAsset;

  const FullScreenStoryReaderScreen({
    super.key,
    required this.title,
    required this.storyAsset,
  });

  @override
  State<FullScreenStoryReaderScreen> createState() =>
      _FullScreenStoryReaderScreenState();
}

class _FullScreenStoryReaderScreenState
    extends State<FullScreenStoryReaderScreen> {
  late final Future<String> _storyLoader;
  StoryReadingMode _readingMode = StoryReadingMode.dark;

  @override
  void initState() {
    super.initState();
    _storyLoader = rootBundle.loadString(widget.storyAsset);
  }

  void _toggleReadingMode() {
    setState(() {
      _readingMode = switch (_readingMode) {
        StoryReadingMode.dark => StoryReadingMode.sepia,
        StoryReadingMode.sepia => StoryReadingMode.light,
        StoryReadingMode.light => StoryReadingMode.dark,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color bgColor = switch (_readingMode) {
      StoryReadingMode.dark => const Color(0xFF0D0D0D),
      StoryReadingMode.sepia => const Color(0xFFF5E6D3),
      StoryReadingMode.light => const Color(0xFFF5F5F5),
    };
    final Color surfaceColor = switch (_readingMode) {
      StoryReadingMode.dark => const Color(0xFF141414),
      StoryReadingMode.sepia => const Color(0xFFEDD9BD),
      StoryReadingMode.light => Colors.white,
    };
    final Color textColor = switch (_readingMode) {
      StoryReadingMode.dark => Colors.white.withOpacity(0.9),
      StoryReadingMode.sepia => const Color(0xFF3B2E1E),
      StoryReadingMode.light => Colors.black.withOpacity(0.85),
    };
    final Color headingColor = switch (_readingMode) {
      StoryReadingMode.dark => Colors.white,
      StoryReadingMode.sepia => const Color(0xFF2A1F0E),
      StoryReadingMode.light => Colors.black,
    };
    final Color iconColor = switch (_readingMode) {
      StoryReadingMode.dark => Colors.white70,
      StoryReadingMode.sepia => const Color(0xFF6B4C2A),
      StoryReadingMode.light => Colors.black87,
    };
    final IconData modeIcon = switch (_readingMode) {
      StoryReadingMode.dark => Icons.brightness_3,
      StoryReadingMode.sepia => Icons.book,
      StoryReadingMode.light => Icons.wb_sunny,
    };
    final Color accentColor = _readingMode == StoryReadingMode.sepia
        ? const Color(0xFFC4956A)
        : const Color(0xffD8D3C8);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: iconColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 14,
            color: headingColor,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(modeIcon, color: iconColor),
            onPressed: _toggleReadingMode,
          ),
        ],
      ),
      body: FutureBuilder<String>(
        future: _storyLoader,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Story could not be loaded.',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  color: textColor.withOpacity(0.6),
                ),
              ),
            );
          }
          final storyText = snapshot.data;
          if (storyText == null) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: headingColor,
                    height: 1.3,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  height: 4,
                  width: 60,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  storyText,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.85,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
    );
  }
}
