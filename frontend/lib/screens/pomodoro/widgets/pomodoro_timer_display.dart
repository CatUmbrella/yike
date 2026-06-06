import 'package:flutter/material.dart';

import '../pomodoro_models.dart';
import '../pomodoro_style.dart';

class PomodoroTimerDisplay extends StatelessWidget {
  const PomodoroTimerDisplay({
    super.key,
    required this.elapsedSeconds,
    required this.status,
  });

  final int elapsedSeconds;
  final PomodoroTimerStatus status;

  @override
  Widget build(BuildContext context) {
    final running = status == PomodoroTimerStatus.running;
    return Column(
      children: [
        Text(
          PomodoroTimerDisplay.formatElapsed(elapsedSeconds),
          style: const TextStyle(
            color: PomodoroStyle.textPrimary,
            fontSize: 58,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: running ? PomodoroStyle.accent : PomodoroStyle.paused,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (running ? PomodoroStyle.accent : PomodoroStyle.paused)
                            .withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              running ? '专注中' : '暂停中',
              style: const TextStyle(
                color: PomodoroStyle.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String formatElapsed(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(hours)}:${two(minutes)}:${two(rest)}';
  }
}
