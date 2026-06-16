import 'package:flutter/material.dart';

void dismissTemplateKeyboard() {
  FocusManager.instance.primaryFocus?.unfocus();
}

EdgeInsets templateInputScrollPadding(BuildContext context) {
  return EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom + 48);
}

void ensureTemplateInputVisible(BuildContext context) {
  void adjustIfNeeded() {
    if (!context.mounted) return;

    final scrollable = Scrollable.maybeOf(context);
    final renderObject = context.findRenderObject();
    if (scrollable == null || renderObject is! RenderBox) return;

    final position = scrollable.position;
    if (!position.hasPixels) return;

    final mediaQuery = MediaQuery.maybeOf(context);
    if (mediaQuery == null) return;

    final offset = renderObject.localToGlobal(Offset.zero);
    final rect = offset & renderObject.size;
    final keyboardTop = mediaQuery.size.height - mediaQuery.viewInsets.bottom;
    final topLimit = mediaQuery.padding.top + 12;
    final bottomLimit =
        (mediaQuery.viewInsets.bottom > 0
            ? keyboardTop
            : mediaQuery.size.height - mediaQuery.padding.bottom) -
        24;

    double delta = 0;
    if (rect.bottom > bottomLimit) {
      delta = rect.bottom - bottomLimit;
    } else if (rect.top < topLimit) {
      delta = rect.top - topLimit;
    }

    if (delta.abs() < 2) return;

    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((target - position.pixels).abs() < 1) return;

    position.animateTo(
      target,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
    );
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    adjustIfNeeded();
    Future<void>.delayed(const Duration(milliseconds: 220), adjustIfNeeded);
  });
}

class TemplateKeyboardDismiss extends StatelessWidget {
  final Widget child;

  const TemplateKeyboardDismiss({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: dismissTemplateKeyboard,
      child: child,
    );
  }
}
