import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../shared/event_formatters.dart';
import '../arrange_style.dart';

typedef QuadrantEventDropHandler =
    Future<void> Function(Event event, ArrangeQuadrantStyle quadrant);

class QuadrantView extends StatelessWidget {
  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final QuadrantEventDropHandler onEventDrop;

  const QuadrantView({
    super.key,
    required this.events,
    required this.onEventTap,
    required this.onEventDrop,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final gap = metrics.compact ? 10.0 : 12.0;
    final axisTopGutter = metrics.compact ? 20.0 : 22.0;
    final axisSideGutter = metrics.compact ? 16.0 : 18.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.compact ? 4 : 8,
        metrics.compact ? 2 : 4,
        metrics.compact ? 4 : 8,
        metrics.compact ? 8 : 10,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gridMaxWidth = constraints.maxWidth - axisSideGutter * 2;
          final gridMaxHeight = constraints.maxHeight - axisTopGutter;
          final childAspectRatio = gridMaxHeight <= 0
              ? 1.0
              : gridMaxWidth / gridMaxHeight;

          return Padding(
            padding: EdgeInsets.only(
              top: axisTopGutter,
              left: axisSideGutter,
              right: axisSideGutter,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: _QuadrantAxis(
                    compact: metrics.compact,
                    topGutter: axisTopGutter,
                    sideGutter: axisSideGutter,
                  ),
                ),
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: gap,
                  crossAxisSpacing: gap,
                  childAspectRatio: childAspectRatio,
                  children: ArrangeQuadrants.displayOrder.map((quadrant) {
                    return _QuadrantPanel(
                      quadrant: quadrant,
                      events: _eventsFor(quadrant),
                      compact: metrics.compact,
                      onEventTap: onEventTap,
                      onEventDrop: onEventDrop,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Event> _eventsFor(ArrangeQuadrantStyle quadrant) {
    return events
        .where(
          (event) => ArrangeQuadrants.sameQuadrant(event.quadrant, quadrant),
        )
        .toList();
  }
}

class _QuadrantAxis extends StatelessWidget {
  final bool compact;
  final double topGutter;
  final double sideGutter;

  const _QuadrantAxis({
    required this.compact,
    required this.topGutter,
    required this.sideGutter,
  });

  @override
  Widget build(BuildContext context) {
    const axisColor = Color(0xFF8FB9EA);
    final labelStyle = TextStyle(
      fontSize: compact ? 11 : 13,
      height: 1,
      fontWeight: FontWeight.w800,
      color: ArrangeStyle.accent,
    );

    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: _AxisLine(horizontal: true, color: axisColor)),
          ),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: _AxisLine(horizontal: false, color: axisColor),
            ),
          ),
          Positioned(
            top: -topGutter,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _AxisLabel(text: '紧急', style: labelStyle),
                  Icon(
                    Icons.arrow_drop_up_rounded,
                    color: ArrangeStyle.accent,
                    size: compact ? 22 : 26,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -6,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(
                Icons.arrow_right_rounded,
                color: ArrangeStyle.accent,
                size: compact ? 20 : 24,
              ),
            ),
          ),
          Positioned(
            right: -sideGutter,
            top: 0,
            bottom: 0,
            child: Center(
              child: _AxisLabel(text: '重要', style: labelStyle, vertical: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool vertical;

  const _AxisLabel({
    required this.text,
    required this.style,
    this.vertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ArrangeStyle.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: vertical
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: text.characters
                    .map((character) => Text(character, style: style))
                    .toList(),
              )
            : Text(text, style: style),
      ),
    );
  }
}

class _AxisLine extends StatelessWidget {
  final bool horizontal;
  final Color color;

  const _AxisLine({required this.horizontal, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: horizontal ? double.infinity : 2,
      height: horizontal ? 2 : double.infinity,
      margin: horizontal
          ? const EdgeInsets.symmetric(horizontal: 8)
          : const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _QuadrantPanel extends StatelessWidget {
  final ArrangeQuadrantStyle quadrant;
  final List<Event> events;
  final bool compact;
  final ValueChanged<Event> onEventTap;
  final QuadrantEventDropHandler onEventDrop;

  const _QuadrantPanel({
    required this.quadrant,
    required this.events,
    required this.compact,
    required this.onEventTap,
    required this.onEventDrop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = quadrant.colors;
    return DragTarget<Event>(
      onWillAcceptWithDetails: (details) => details.data.status != 'completed',
      onAcceptWithDetails: (details) {
        onEventDrop(details.data, quadrant);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(compact ? 7 : 9),
          decoration: BoxDecoration(
            color: (isHovering ? colors.soft : colors.softer).withValues(
              alpha: isHovering ? 0.9 : 0.76,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: (isHovering ? colors.accent : colors.border).withValues(
                alpha: isHovering ? 0.72 : 0.72,
              ),
            ),
            boxShadow: ArrangeStyle.itemShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _QuadrantIcon(quadrant: quadrant, compact: compact),
                  SizedBox(width: compact ? 4 : 6),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          quadrant.title,
                          maxLines: 1,
                          softWrap: false,
                          style: TextStyle(
                            fontSize: compact ? 13 : 15,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: ArrangeStyle.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.more_vert_rounded,
                    size: compact ? 15 : 17,
                    color: ArrangeStyle.textSecondary,
                  ),
                ],
              ),
              SizedBox(height: compact ? 8 : 10),
              Expanded(
                child: ListView.separated(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: events.length,
                  separatorBuilder: (_, _) => SizedBox(height: compact ? 6 : 8),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _QuadrantEventChip(
                      event: event,
                      colors: colors,
                      compact: compact,
                      onTap: () => onEventTap(event),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuadrantIcon extends StatelessWidget {
  final ArrangeQuadrantStyle quadrant;
  final bool compact;

  const _QuadrantIcon({required this.quadrant, required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 32.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: quadrant.colors.badge,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: size * 0.68,
          height: size * 0.68,
          decoration: BoxDecoration(
            color: quadrant.colors.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            quadrant.icon,
            size: compact ? 15 : 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _QuadrantEventChip extends StatelessWidget {
  final Event event;
  final ArrangeEventColors colors;
  final bool compact;
  final VoidCallback onTap;

  const _QuadrantEventChip({
    required this.event,
    required this.colors,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: compact ? 30 : 34),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 5 : 6,
        ),
        decoration: BoxDecoration(
          color: ArrangeStyle.surface.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border.withValues(alpha: 0.82)),
          boxShadow: ArrangeStyle.itemShadow,
        ),
        child: Row(
          children: [
            Container(
              width: compact ? 8 : 9,
              height: compact ? 8 : 9,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: compact ? 8 : 10),
            Expanded(
              child: Text(
                eventDisplayTitle(event),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: ArrangeStyle.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
