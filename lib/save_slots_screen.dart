import 'dart:ui';

import 'package:flutter/material.dart';

import 'escape_back_wrapper.dart';
import 'game_content.dart';
import 'game_save_service.dart';

enum SaveSlotMode { save, load }

class SaveSlotsScreen extends StatefulWidget {
  const SaveSlotsScreen({
    super.key,
    required this.mode,
    this.targetIndex,
    this.closeAfterSave = false,
    this.onLoaded,
  });

  final SaveSlotMode mode;
  final int? targetIndex;
  final bool closeAfterSave;
  final VoidCallback? onLoaded;

  @override
  State<SaveSlotsScreen> createState() => _SaveSlotsScreenState();
}

class _SaveSlotsScreenState extends State<SaveSlotsScreen> {
  late Future<List<String?>> _slots;

  bool get _isSaveMode => widget.mode == SaveSlotMode.save;

  @override
  void initState() {
    super.initState();
    _slots = _loadSlots();
  }

  Future<List<String?>> _loadSlots() {
    return Future.wait(
      List.generate(
        GameSaveService.slotCount,
        (index) => GameSaveService.savedAtLabel(slotIndex: index),
      ),
    );
  }

  Future<void> _selectSlot(int index) async {
    if (_isSaveMode) {
      await GameSaveService.saveGame(
        slotIndex: index,
        targetIndex: widget.targetIndex,
      );
      if (!mounted) return;
      if (widget.closeAfterSave) {
        Navigator.of(context).pop(index);
        return;
      }
      setState(() => _slots = _loadSlots());
      _showStatus('SAVED TO SLOT ${index + 1}');
      return;
    }

    final loaded = await GameSaveService.loadGame(slotIndex: index);
    if (!mounted) return;

    if (!loaded) {
      _showStatus('EMPTY SLOT');
      return;
    }

    widget.onLoaded?.call();
    Navigator.of(context).pop(true);
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
      popResult: false,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(mosaicSceneAsset, fit: BoxFit.cover),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.76)),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight <= 430;
                  final spacing = isCompact ? 8.0 : 14.0;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      isCompact ? 34 : 72,
                      isCompact ? 14 : 56,
                      isCompact ? 34 : 72,
                      isCompact ? 18 : 42,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white70,
                            size: isCompact ? 18 : 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                        ),
                        SizedBox(height: isCompact ? 6 : 28),
                        Text(
                          _isSaveMode ? 'SAVE GAME' : 'LOAD GAME',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: isCompact ? 24 : 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                        SizedBox(height: isCompact ? 10 : 28),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, gridConstraints) {
                              final tileHeight = isCompact
                                  ? ((gridConstraints.maxHeight - spacing) / 2)
                                      .clamp(56.0, 72.0)
                                  : 104.0;

                              return FutureBuilder<List<String?>>(
                                future: _slots,
                                builder: (context, snapshot) {
                                  final slots = snapshot.data ??
                                      List<String?>.filled(
                                        GameSaveService.slotCount,
                                        null,
                                      );
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 900),
                                      child: GridView.builder(
                                        padding: EdgeInsets.zero,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: GameSaveService.slotCount,
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          mainAxisExtent: tileHeight,
                                          mainAxisSpacing: spacing,
                                          crossAxisSpacing: spacing,
                                        ),
                                        itemBuilder: (context, index) {
                                          return _SaveSlotTile(
                                            index: index,
                                            savedAt: slots[index],
                                            isSaveMode: _isSaveMode,
                                            onPressed: () => _selectSlot(index),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
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

class _SaveSlotTile extends StatelessWidget {
  const _SaveSlotTile({
    required this.index,
    required this.savedAt,
    required this.isSaveMode,
    required this.onPressed,
  });

  final int index;
  final String? savedAt;
  final bool isSaveMode;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final hasSave = savedAt != null;
    final isCompact = MediaQuery.sizeOf(context).height <= 430;

    return OutlinedButton(
      onPressed: isSaveMode || hasSave ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.26),
        backgroundColor: Colors.black.withValues(alpha: 0.34),
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.2),
        padding: EdgeInsets.all(isCompact ? 8 : 16),
        side: BorderSide(
          color: hasSave
              ? const Color(0xFFD8D3C8).withValues(alpha: 0.44)
              : Colors.white.withValues(alpha: 0.14),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'SLOT ${index + 1}',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: isCompact ? 10 : 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.8,
            ),
          ),
          SizedBox(height: isCompact ? 4 : 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              savedAt ?? 'EMPTY',
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: isCompact ? 8 : 10,
                color: hasSave ? const Color(0xFFD8D3C8) : Colors.white38,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
