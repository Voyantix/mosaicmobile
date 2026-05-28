import 'package:flutter/material.dart';

class DesktopRatioWrapper extends StatelessWidget {
  const DesktopRatioWrapper({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRect(child: child),
        ),
      ),
    );
  }
}
