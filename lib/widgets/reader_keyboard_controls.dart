import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shortcuts stay within the reader route and leave editable fields alone.
class ReaderKeyboardControls extends StatelessWidget {
  const ReaderKeyboardControls({
    super.key,
    required this.child,
    required this.onNext,
    required this.onPrevious,
    required this.onToggleControls,
    this.rightToLeft = false,
  });

  final Widget child;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onToggleControls;
  final bool rightToLeft;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent ||
            ModalRoute.of(context)?.isCurrent == false ||
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isAltPressed ||
            HardwareKeyboard.instance.isMetaPressed ||
            FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.pageDown ||
            key == LogicalKeyboardKey.arrowDown ||
            (key == LogicalKeyboardKey.space && !HardwareKeyboard.instance.isShiftPressed)) {
          onNext();
        } else if (key == LogicalKeyboardKey.pageUp || key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.space) {
          onPrevious();
        } else if (key == LogicalKeyboardKey.arrowRight) {
          (rightToLeft ? onPrevious : onNext)();
        } else if (key == LogicalKeyboardKey.arrowLeft) {
          (rightToLeft ? onNext : onPrevious)();
        } else if (key == LogicalKeyboardKey.escape) {
          onToggleControls();
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: child,
    );
  }
}
