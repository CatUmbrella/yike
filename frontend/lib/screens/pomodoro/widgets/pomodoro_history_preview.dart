import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../pomodoro_models.dart';
import '../pomodoro_style.dart';
import 'tomato_icon.dart';

class PomodoroHistoryPreview extends StatelessWidget {
  const PomodoroHistoryPreview({
    super.key,
    required this.items,
    required this.onViewAll,
  });

  final List<PomodoroHistoryPreviewItem> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: PomodoroStyle.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Text('历史记录', style: _sectionTitleStyle),
              const Spacer(),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: PomodoroStyle.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('查看全部>'),
              ),
            ],
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '暂无番茄钟记录',
                style: TextStyle(color: PomodoroStyle.textSecondary),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 84,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) =>
                    _HistoryCard(item: items[index]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _sectionTitleStyle = TextStyle(
  color: PomodoroStyle.textPrimary,
  fontSize: 14,
  fontWeight: FontWeight.w800,
);

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item});

  final PomodoroHistoryPreviewItem item;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('M.d HH:mm').format(item.displayTime);
    return Container(
      width: 136,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAF0F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PomodoroStyle.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.15,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              _TomatoCount(count: item.tomatoCount),
            ],
          ),
          const Spacer(),
          Text(
            time,
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 12,
              height: 1.15,
            ),
          ),
          Text(
            item.eventCompleted ? '已完成' : '未完成',
            style: const TextStyle(
              color: PomodoroStyle.textSecondary,
              fontSize: 11,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}

class _TomatoCount extends StatelessWidget {
  const _TomatoCount({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count > 3) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TomatoIcon(size: 14),
          const SizedBox(width: 2),
          Text(
            '×$count',
            style: const TextStyle(
              color: PomodoroStyle.accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (_) => const TomatoIcon(size: 14)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: PomodoroStyle.surface,
        borderRadius: PomodoroStyle.cardRadius,
        border: Border.all(color: PomodoroStyle.border),
        boxShadow: PomodoroStyle.panelShadow,
      ),
      child: child,
    );
  }
}
