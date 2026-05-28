import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'main_menu_screen.dart';
import 'voyantix_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await VoyantixAuthService.initialize();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final useDesktopWindow =
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  if (!useDesktopWindow) {
    runApp(const MosaicHubApp());
    return;
  }

  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(1280, 720),
    center: true,
    minimumSize: Size(960, 540),
    title: 'Mosaic',
    titleBarStyle: TitleBarStyle.hidden,
    windowButtonVisibility: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.maximize();
    await windowManager.focus();
  });

  runApp(const MosaicHubApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 450), () async {
      await windowManager.setFullScreen(true);
      await windowManager.focus();
    });
  });
}

class MosaicHubApp extends StatelessWidget {
  const MosaicHubApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mosaic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Orbitron',
        scaffoldBackgroundColor: const Color(0xFF05050A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD8D3C8),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: home ?? const MainMenuScreen(),
    );
  }
}
