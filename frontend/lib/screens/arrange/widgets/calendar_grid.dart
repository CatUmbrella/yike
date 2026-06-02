import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
import '../arrange_style.dart';
import 'calendar_cell.dart';
import 'calendar_grid_cell.dart';

typedef CalendarEventDropHandler =
    Future<void> Function(
      Event event,
      DateTime day,
      ArrangeTimeSlot slot,
      int insertIndex,
    );

class CalendarGrid extends StatelessWidget {
  final DateTime monday;
  final List<String> weekLabels;
  final List<ArrangeTimeSlot> timeSlots;
  final VoidCallback onBlankTap;
  final List<Event> Function(DateTime day, ArrangeTimeSlot slot) eventsForCell;
  final CalendarEventDropHandler onEventDrop;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event> onEventComplete;

  const CalendarGrid({
    super.key,
    required this.monday,
    required this.weekLabels,
    required this.timeSlots,
    required this.onBlankTap,
    required this.eventsForCell,
    required this.onEventDrop,
    required this.onEventTap,
    required this.onEventComplete,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return Column(
      children: [
        SizedBox(
          height: metrics.compact ? 24 : 28,
          child: Row(
            children: [
              CalendarGridCell(
                width: calendarTimeAxisWidth,
                column: 0,
                child: const SizedBox.shrink(),
              ),
              ...List.generate(7, (i) {
                final day = monday.add(Duration(days: i));
                return Expanded(
                  child: CalendarGridCell(
                    column: i + 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          weekLabels[i],
                          style: TextStyle(
                            fontSize: metrics.compact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: ArrangeStyle.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '/${day.day}',
                            style: TextStyle(
                              fontSize: metrics.compact ? 7.5 : 9,
                              fontWeight: FontWeight.w500,
                              color: ArrangeStyle.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: metrics.calendarGridBottomPadding),
            child: Column(
              children: List.generate(timeSlots.length, (rowIndex) {
                final slot = timeSlots[rowIndex];
                return Expanded(
                  flex: slot.rowFlex,
                  child: Row(
                    children: [
                      CalendarGridCell(
                        width: calendarTimeAxisWidth,
                        column: 0,
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: _TimeAxisLabel(slot: slot),
                      ),
                      ...List.generate(7, (columnIndex) {
                        final day = monday.add(Duration(days: columnIndex));
                        return Expanded(
                          child: CalendarCell(
                            column: columnIndex + 1,
                            events: eventsForCell(day, slot),
                            onBlankTap: onBlankTap,
                            onEventDrop: (event, insertIndex) {
                              return onEventDrop(event, day, slot, insertIndex);
                            },
                            onEventTap: onEventTap,
                            onEventComplete: onEventComplete,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeAxisLabel extends StatelessWidget {
  final ArrangeTimeSlot slot;

  const _TimeAxisLabel({required this.slot});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 9.5,
      height: 1.0,
      fontWeight: FontWeight.w500,
      color: ArrangeStyle.textPrimary,
    );

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(slot.start, style: textStyle),
            Text(
              '-',
              style: textStyle.copyWith(color: ArrangeStyle.textSecondary),
            ),
            Text(slot.end, style: textStyle),
          ],
        ),
      ),
    );
  }
}
