import 'package:flutter/material.dart';

import '../pomodoro_style.dart';

class PomodoroLanePanel extends StatelessWidget {
  const PomodoroLanePanel({
    super.key,
    required this.label,
    required this.child,
    this.height = 124,
    this.onLabelTap,
  });

  final String label;
  final Widget child;
  final double height;
  final VoidCallback? onLabelTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: PomodoroStyle.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PomodoroStyle.border),
        boxShadow: PomodoroStyle.panelShadow,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onLabelTap,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(22),
            ),
            child: SizedBox(
              width: 62,
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: onLabelTap == null
                        ? PomodoroStyle.textPrimary
                        : PomodoroStyle.accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: height * 0.56,
            color: PomodoroStyle.border,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
