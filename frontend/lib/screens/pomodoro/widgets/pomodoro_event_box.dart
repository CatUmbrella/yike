import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../shared/event_formatters.dart';
import '../pomodoro_style.dart';

class PomodoroEventBox extends StatelessWidget {
  const PomodoroEventBox({
    super.key,
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
    required this.onOpenDetail,
  });

  final List<Event> events;
  final int? selectedEventId;
  final ValueChanged<Event> onSelect;
  final ValueChanged<Event> onOpenDetail;

  @override
  Widget build(BuildContext context) {
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
          const Text('事件箱', style: _boxTitleStyle),
          const SizedBox(height: 6),
          const Text(
            '选择一个事件开始专注',
            style: TextStyle(color: PomodoroStyle.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text(
                '暂无可专注事件',
                style: TextStyle(color: PomodoroStyle.textSecondary),
              ),
            )
          else
            _EventList(
              events: events,
              selectedEventId: selectedEventId,
              onSelect: onSelect,
              onOpenDetail: onOpenDetail,
            ),
        ],
      ),
    );
  }
}

class _EventList extends StatelessWidget {
  const _EventList({
    required this.events,
    required this.selectedEventId,
    required this.onSelect,
    required this.onOpenDetail,
  });

  static const _maxVisibleRows = 4;
  static const _rowExtent = 56.0;

  final List<Event> events;
  final int? selectedEventId;
  final ValueChanged<Event> onSelect;
  final ValueChanged<Event> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    if (events.length <= _maxVisibleRows) {
      return Column(
        children: [
          for (final event in events)
            _EventRow(
              event: event,
              selected: selectedEventId == event.id,
              onSelect: () => onSelect(event),
              onOpenDetail: () => onOpenDetail(event),
            ),
        ],
      );
    }

    return SizedBox(
      height: _maxVisibleRows * _rowExtent,
      child: Scrollbar(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemExtent: _rowExtent,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _EventRow(
              event: event,
              selected: selectedEventId == event.id,
              onSelect: () => onSelect(event),
              onOpenDetail: () => onOpenDetail(event),
            );
          },
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.selected,
    required this.onSelect,
    required this.onOpenDetail,
  });

  final Event event;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : PomodoroStyle.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? PomodoroStyle.accentDeep : PomodoroStyle.accentSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onOpenDetail,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected
                    ? PomodoroStyle.accentDeep
                    : const Color(0xFFDCEBFB),
              ),
              color: selected
                  ? PomodoroStyle.accentDeep
                  : PomodoroStyle.accentSoft,
            ),
            child: Row(
              children: [
                InkResponse(
                  onTap: onSelect,
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: selected ? Colors.white : PomodoroStyle.accent,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    eventDisplayTitle(event),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCompactEventDuration(event.totalMinutes),
                  style: TextStyle(
                    color: selected
                        ? const Color(0xE6FFFFFF)
                        : PomodoroStyle.textSecondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _boxTitleStyle = TextStyle(
  color: PomodoroStyle.textPrimary,
  fontSize: 18,
  fontWeight: FontWeight.w900,
);
