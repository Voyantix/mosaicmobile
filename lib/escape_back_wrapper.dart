import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EscapeBackWrapper extends StatelessWidget {
  const EscapeBackWrapper({
    super.key,
    required this.child,
    this.popResult,
    this.onBack,
  });

  final Widget child;
  final Object? popResult;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            event.logicalKey != LogicalKeyboardKey.escape) {
          return KeyEventResult.ignored;
        }

        final navigator = Navigator.of(context);
        if (!navigator.canPop()) return KeyEventResult.ignored;

        onBack?.call();
        navigator.pop(popResult);
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}
