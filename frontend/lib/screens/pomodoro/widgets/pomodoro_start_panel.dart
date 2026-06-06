import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../shared/event_formatters.dart';
import '../pomodoro_style.dart';
import 'tomato_icon.dart';

class PomodoroStartPanel extends StatelessWidget {
  const PomodoroStartPanel({
    super.key,
    required this.selectedEvent,
    required this.onStart,
  });

  final Event? selectedEvent;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final event = selectedEvent;
    final enabled = event != null;
    const tomatoSize = 70.0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PomodoroStyle.surface,
        borderRadius: PomodoroStyle.cardRadius,
        border: Border.all(color: PomodoroStyle.border),
        boxShadow: PomodoroStyle.panelShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            enabled ? '当前选择' : '选择一个任务',
            style: const TextStyle(
              color: PomodoroStyle.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            enabled ? '确认事件后开始专注' : '点击选择事件箱中的任务开始专注',
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 82,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: enabled
                        ? PomodoroStyle.accent
                        : PomodoroStyle.disabledText,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        enabled ? eventDisplayTitle(event) : '选择一个任务',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PomodoroStyle.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        enabled
                            ? '预计专注时间：${formatEventDuration(event.totalMinutes)}'
                            : '预计专注时间：--',
                        style: const TextStyle(
                          color: PomodoroStyle.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const TomatoIcon(size: tomatoSize, showBackground: false),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: enabled ? onStart : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('开始番茄钟'),
              style: FilledButton.styleFrom(
                disabledBackgroundColor: PomodoroStyle.disabled,
                disabledForegroundColor: PomodoroStyle.disabledText,
                backgroundColor: PomodoroStyle.accentDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            enabled ? '进入专注页面，开始计时' : '先选择任务才能开始哦',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
