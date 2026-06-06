import 'package:flutter/material.dart';

import '../pomodoro_style.dart';

class PomodoroDialogShell extends StatelessWidget {
  const PomodoroDialogShell({
    super.key,
    required this.title,
    required this.child,
    this.onClose,
    this.maxWidth = 430,
    this.padding = const EdgeInsets.fromLTRB(28, 22, 28, 28),
  });

  final String title;
  final Widget child;
  final VoidCallback? onClose;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: PomodoroStyle.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
            boxShadow: [
              BoxShadow(
                color: PomodoroStyle.accent.withValues(alpha: 0.14),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PomodoroDialogHeader(title: title, onClose: onClose),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class PomodoroDialogHeader extends StatelessWidget {
  const PomodoroDialogHeader({super.key, required this.title, this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: IconButton(
              onPressed: onClose ?? () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
              color: PomodoroStyle.textPrimary,
              iconSize: 28,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
