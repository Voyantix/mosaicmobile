import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'escape_back_wrapper.dart';
import 'game_content.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.musicEnabled,
    required this.masterVolume,
    required this.musicVolume,
    required this.onMusicEnabledChanged,
    required this.onMasterVolumeChanged,
    required this.onMusicVolumeChanged,
  });

  final bool musicEnabled;
  final double masterVolume;
  final double musicVolume;
  final ValueChanged<bool> onMusicEnabledChanged;
  final ValueChanged<double> onMasterVolumeChanged;
  final ValueChanged<double> onMusicVolumeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isChangingDisplayMode = false;
  bool _isChangingResolution = false;
  bool _isDesktopFullscreen = true;
  _ResolutionOption _selectedResolution = _ResolutionOption.fullHd;
  late bool _musicEnabled;
  late double _masterVolume;
  late double _musicVolume;

  bool get _supportsWindowManager =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    _musicEnabled = widget.musicEnabled;
    _masterVolume = widget.masterVolume;
    _musicVolume = widget.musicVolume;
    if (_supportsWindowManager) {
      _loadDisplayMode();
    }
  }

  Future<void> _loadDisplayMode() async {
    if (!_supportsWindowManager) return;
    final isFullscreen = await windowManager.isFullScreen();
    final windowSize = await windowManager.getSize();
    if (mounted) {
      setState(() {
        _isDesktopFullscreen = isFullscreen;
        _selectedResolution = _ResolutionOption.closestTo(windowSize);
      });
    }
  }

  Future<void> _setDisplayMode(bool desktopFullscreen) async {
    if (!_supportsWindowManager) return;
    if (_isChangingDisplayMode) return;

    setState(() {
      _isChangingDisplayMode = true;
      _isDesktopFullscreen = desktopFullscreen;
    });

    try {
      if (desktopFullscreen) {
        await windowManager.setTitleBarStyle(
          TitleBarStyle.hidden,
          windowButtonVisibility: false,
        );
        await windowManager.setFullScreen(true);
      } else {
        if (await windowManager.isFullScreen()) {
          await windowManager.setFullScreen(false);
        }
        if (await windowManager.isMaximized()) {
          await windowManager.unmaximize();
        }
        await windowManager.setTitleBarStyle(
          TitleBarStyle.normal,
          windowButtonVisibility: true,
        );
        await windowManager.setSize(_selectedResolution.size);
        await windowManager.center();
      }
      await windowManager.focus();

      final isFullscreen = await windowManager.isFullScreen();
      if (mounted) {
        setState(() => _isDesktopFullscreen = isFullscreen);
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingDisplayMode = false);
      }
    }
  }

  Future<void> _setWindowResolution(_ResolutionOption resolution) async {
    if (!_supportsWindowManager) return;
    if (_isChangingDisplayMode || _isChangingResolution) return;

    setState(() {
      _isChangingResolution = true;
      _isDesktopFullscreen = false;
      _selectedResolution = resolution;
    });

    try {
      if (await windowManager.isFullScreen()) {
        await windowManager.setFullScreen(false);
      }
      if (await windowManager.isMaximized()) {
        await windowManager.unmaximize();
      }
      await windowManager.setTitleBarStyle(
        TitleBarStyle.normal,
        windowButtonVisibility: true,
      );
      await windowManager.setSize(resolution.size);
      await windowManager.center();
      await windowManager.focus();

      final currentSize = await windowManager.getSize();
      final isFullscreen = await windowManager.isFullScreen();
      if (mounted) {
        setState(() {
          _isDesktopFullscreen = isFullscreen;
          _selectedResolution = _ResolutionOption.closestTo(currentSize);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingResolution = false);
      }
    }
  }

  void _setMasterVolume(double value) {
    setState(() => _masterVolume = value);
    widget.onMasterVolumeChanged(value);
  }

  void _setMusicVolume(double value) {
    setState(() => _musicVolume = value);
    widget.onMusicVolumeChanged(value);
  }

  void _setMusicEnabled(bool value) {
    setState(() => _musicEnabled = value);
    widget.onMusicEnabledChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _SettingsMetrics.fromSize(MediaQuery.sizeOf(context));

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
              child: Padding(
                padding: metrics.screenPadding,
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
                            constraints: BoxConstraints(
                              maxWidth: metrics.contentMaxWidth,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'SETTINGS',
                                  style: TextStyle(
                                    fontFamily: 'Orbitron',
                                    fontSize: metrics.titleFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 4,
                                  ),
                                ),
                                SizedBox(height: metrics.titleGap),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final useColumns =
                                        constraints.maxWidth >= 900;
                                    final graphicsPanel = _SettingsPanel(
                                      title: 'GRAPHICS',
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _DisplayModeButton(
                                                label: 'FULLSCREEN',
                                                icon: Icons.fullscreen_rounded,
                                                isSelected:
                                                    _isDesktopFullscreen,
                                                isBusy:
                                                    _isChangingDisplayMode ||
                                                        _isChangingResolution,
                                                onPressed: _isDesktopFullscreen ||
                                                        _isChangingDisplayMode ||
                                                        _isChangingResolution
                                                    ? null
                                                    : () =>
                                                        _setDisplayMode(true),
                                                metrics: metrics,
                                              ),
                                            ),
                                            SizedBox(
                                              width: metrics.buttonColumnGap,
                                            ),
                                            Expanded(
                                              child: _DisplayModeButton(
                                                label: 'WINDOWED',
                                                icon: Icons
                                                    .fullscreen_exit_rounded,
                                                isSelected:
                                                    !_isDesktopFullscreen,
                                                isBusy:
                                                    _isChangingDisplayMode ||
                                                        _isChangingResolution,
                                                onPressed: _isDesktopFullscreen &&
                                                        !_isChangingDisplayMode &&
                                                        !_isChangingResolution
                                                    ? () => _setDisplayMode(
                                                          false,
                                                        )
                                                    : null,
                                                metrics: metrics,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: metrics.controlGap),
                                        _ResolutionDropdown(
                                          value: _selectedResolution,
                                          isBusy: _isChangingDisplayMode ||
                                              _isChangingResolution,
                                          onChanged: _setWindowResolution,
                                        ),
                                        SizedBox(height: metrics.controlGap),
                                        _SettingsRow(
                                          label: 'Mode',
                                          value: _isDesktopFullscreen
                                              ? 'Fullscreen'
                                              : 'Windowed',
                                        ),
                                        const _SettingsRow(
                                          label: 'Type',
                                          value: '16:9 Desktop',
                                        ),
                                      ],
                                    );

                                    final soundPanel = _SettingsPanel(
                                      title: 'SOUND',
                                      children: [
                                        _SettingsSwitch(
                                          label: 'Music',
                                          value: _musicEnabled,
                                          onChanged: _setMusicEnabled,
                                        ),
                                        const SizedBox(height: 8),
                                        _SettingsSlider(
                                          label: 'Master',
                                          value: _masterVolume,
                                          onChanged: _setMasterVolume,
                                        ),
                                        _SettingsSlider(
                                          label: 'Music',
                                          value: _musicVolume,
                                          onChanged: _setMusicVolume,
                                        ),
                                        const _SettingsRow(
                                          label: 'Output',
                                          value: 'System Default',
                                        ),
                                      ],
                                    );

                                    if (!_supportsWindowManager) {
                                      return soundPanel;
                                    }

                                    if (!useColumns) {
                                      return Column(
                                        children: [
                                          graphicsPanel,
                                          SizedBox(height: metrics.panelGap),
                                          soundPanel,
                                        ],
                                      );
                                    }

                                    return IntrinsicHeight(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(child: graphicsPanel),
                                          SizedBox(width: metrics.panelGap),
                                          Expanded(child: soundPanel),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolutionOption {
  const _ResolutionOption({
    required this.label,
    required this.size,
  });

  final String label;
  final Size size;

  static const hd = _ResolutionOption(
    label: '1280 x 720',
    size: Size(1280, 720),
  );
  static const fullHd = _ResolutionOption(
    label: '1920 x 1080',
    size: Size(1920, 1080),
  );
  static const twoK = _ResolutionOption(
    label: '2560 x 1440',
    size: Size(2560, 1440),
  );

  static const values = <_ResolutionOption>[twoK, fullHd, hd];

  static _ResolutionOption closestTo(Size size) {
    var closest = values.first;
    var closestDelta = double.infinity;

    for (final option in values) {
      final delta = (option.size.width - size.width).abs() +
          (option.size.height - size.height).abs();
      if (delta < closestDelta) {
        closest = option;
        closestDelta = delta;
      }
    }

    return closest;
  }
}

class _SettingsMetrics {
  const _SettingsMetrics({
    required this.screenPadding,
    required this.contentMaxWidth,
    required this.titleFontSize,
    required this.titleGap,
    required this.panelGap,
    required this.buttonHeight,
    required this.buttonHorizontalPadding,
    required this.buttonIconSize,
    required this.buttonFontSize,
    required this.buttonColumnGap,
    required this.controlGap,
  });

  final EdgeInsets screenPadding;
  final double contentMaxWidth;
  final double titleFontSize;
  final double titleGap;
  final double panelGap;
  final double buttonHeight;
  final double buttonHorizontalPadding;
  final double buttonIconSize;
  final double buttonFontSize;
  final double buttonColumnGap;
  final double controlGap;

  factory _SettingsMetrics.fromSize(Size size) {
    final is2K = size.width >= 2400 || size.height >= 1350;
    final isCompact1080 = size.width <= 1920 && size.height <= 1080;

    if (is2K) {
      return const _SettingsMetrics(
        screenPadding: EdgeInsets.fromLTRB(96, 72, 96, 54),
        contentMaxWidth: 1320,
        titleFontSize: 42,
        titleGap: 34,
        panelGap: 20,
        buttonHeight: 58,
        buttonHorizontalPadding: 16,
        buttonIconSize: 19,
        buttonFontSize: 12.5,
        buttonColumnGap: 14,
        controlGap: 14,
      );
    }

    if (isCompact1080) {
      return const _SettingsMetrics(
        screenPadding: EdgeInsets.fromLTRB(64, 46, 64, 34),
        contentMaxWidth: 1040,
        titleFontSize: 36,
        titleGap: 24,
        panelGap: 14,
        buttonHeight: 48,
        buttonHorizontalPadding: 10,
        buttonIconSize: 16,
        buttonFontSize: 11.5,
        buttonColumnGap: 10,
        controlGap: 10,
      );
    }

    return const _SettingsMetrics(
      screenPadding: EdgeInsets.fromLTRB(72, 56, 72, 42),
      contentMaxWidth: 1120,
      titleFontSize: 38,
      titleGap: 28,
      panelGap: 16,
      buttonHeight: 52,
      buttonHorizontalPadding: 12,
      buttonIconSize: 17,
      buttonFontSize: 12,
      buttonColumnGap: 12,
      controlGap: 12,
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD8D3C8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DisplayModeButton extends StatelessWidget {
  const _DisplayModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isBusy,
    required this.onPressed,
    required this.metrics,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isBusy;
  final VoidCallback? onPressed;
  final _SettingsMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? Colors.black : Colors.white70;
    final background =
        isSelected ? const Color(0xFFD8D3C8) : Colors.transparent;

    return SizedBox(
      height: metrics.buttonHeight,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background,
          disabledForegroundColor: foreground,
          padding: EdgeInsets.symmetric(
            horizontal: metrics.buttonHorizontalPadding,
          ),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFD8D3C8)
                : Colors.white.withValues(alpha: 0.16),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isBusy ? Icons.more_horiz_rounded : icon,
                size: metrics.buttonIconSize,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: metrics.buttonFontSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolutionDropdown extends StatelessWidget {
  const _ResolutionDropdown({
    required this.value,
    required this.isBusy,
    required this.onChanged,
  });

  final _ResolutionOption value;
  final bool isBusy;
  final ValueChanged<_ResolutionOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<_ResolutionOption>(
      value: value,
      isExpanded: true,
      icon: Icon(
        isBusy ? Icons.more_horiz_rounded : Icons.expand_more_rounded,
        color: Colors.white70,
      ),
      dropdownColor: const Color(0xFF0B1118),
      decoration: InputDecoration(
        labelText: 'Resolution',
        labelStyle: const TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white70,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
        prefixIcon: const Icon(
          Icons.aspect_ratio_rounded,
          color: Colors.white70,
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFD8D3C8)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      style: const TextStyle(
        fontFamily: 'Orbitron',
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
      items: _ResolutionOption.values
          .map(
            (resolution) => DropdownMenuItem<_ResolutionOption>(
              value: resolution,
              child: Text(resolution.label),
            ),
          )
          .toList(),
      onChanged: isBusy
          ? null
          : (resolution) {
              if (resolution != null) {
                onChanged(resolution);
              }
            },
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Expanded(
          child: Slider(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFD8D3C8),
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            '${(value * 100).round()}',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        const Spacer(),
        Switch(
          value: value,
          activeColor: const Color(0xFFD8D3C8),
          onChanged: onChanged,
        ),
        SizedBox(
          width: 44,
          child: Text(
            value ? 'ON' : 'OFF',
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
