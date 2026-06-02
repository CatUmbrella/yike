import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
import '../arrange_style.dart';
import 'calendar_grid_cell.dart';

class CalendarCell extends StatefulWidget {
  final int column;
  final List<Event> events;
  final VoidCallback onBlankTap;
  final Future<void> Function(Event event, int insertIndex) onEventDrop;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event> onEventComplete;

  const CalendarCell({
    super.key,
    required this.column,
    required this.events,
    required this.onBlankTap,
    required this.onEventDrop,
    required this.onEventTap,
    required this.onEventComplete,
  });

  @override
  State<CalendarCell> createState() => _CalendarCellState();
}

class _CalendarCellState extends State<CalendarCell> {
  final _cellKey = GlobalKey();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DragTarget<Event>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) {
        final box = _cellKey.currentContext?.findRenderObject() as RenderBox?;
        final localY = box?.globalToLocal(details.offset).dy ?? 0;
        widget.onEventDrop(
          details.data,
          _insertIndexForDy(localY, widget.events.length),
        );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return GestureDetector(
          key: _cellKey,
          behavior: HitTestBehavior.opaque,
          onTap: widget.onBlankTap,
          child: CalendarGridCell(
            column: widget.column,
            padding: const EdgeInsets.all(3),
            color: isHovering ? ArrangeStyle.accentSofter : null,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.events.map((event) {
                    return _CalendarEventChip(
                      event: event,
                      onTap: () => widget.onEventTap(event),
                      onDoubleTap: event.status == 'completed'
                          ? null
                          : () => widget.onEventComplete(event),
                    );
                  }).toList(),
                );

                if (widget.events.length * calendarEventItemExtent <=
                    constraints.maxHeight) {
                  return content;
                }

                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: content,
                );
              },
            ),
          ),
        );
      },
    );
  }

  int _insertIndexForDy(double dy, int eventCount) {
    final scrollOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    return ((dy + scrollOffset) / calendarEventItemExtent)
        .round()
        .clamp(0, eventCount)
        .toInt();
  }
}

class _CalendarEventChip extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  const _CalendarEventChip({
    required this.event,
    required this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: _buildChip(opacity: 1),
    );

    return LongPressDraggable<Event>(
      data: event,
      maxSimultaneousDrags: 1,
      feedback: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0.92),
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0.78),
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            builder: (context, opacity, child) {
              return Opacity(opacity: opacity, child: child);
            },
            child: SizedBox(
              width: calendarEventChipWidth,
              child: _buildChip(opacity: 1),
            ),
          ),
        ),
      ),
      childWhenDragging: _buildChip(opacity: 0.32),
      child: child,
    );
  }

  Widget _buildChip({required double opacity}) {
    final completed = event.status == 'completed';
    final colors = ArrangeQuadrants.colorsFor(event.quadrant);
    final stateOpacity = completed ? 0.45 : 1.0;
    return Opacity(
      opacity: opacity * stateOpacity,
      child: Container(
        margin: const EdgeInsets.only(bottom: 1),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        constraints: const BoxConstraints(
          minHeight: calendarEventChipMinHeight,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: completed ? const Color(0xFFE9EEF4) : colors.soft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: completed ? const Color(0xFFC9D3DE) : colors.border,
          ),
          boxShadow: completed ? null : ArrangeStyle.itemShadow,
        ),
        child: Text(
          _eventDisplayName(event),
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: completed ? ArrangeStyle.textSecondary : colors.accent,
          ),
        ),
      ),
    );
  }

  String _eventDisplayName(Event event) {
    final summary = event.summary.trim();
    if (summary.isNotEmpty) return summary;
    final title = event.title.trim();
    return title.isEmpty ? '(无标题)' : title;
  }
}
