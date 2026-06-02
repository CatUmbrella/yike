import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_style.dart';

class QuadrantView extends StatelessWidget {
  final List<Event> events;
  final ValueChanged<Event> onEventTap;

  const QuadrantView({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final gap = metrics.compact ? 8.0 : 10.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.compact ? 14 : 20,
        metrics.compact ? 6 : 8,
        metrics.compact ? 14 : 20,
        metrics.compact ? 14 : 18,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned.fill(child: _QuadrantAxis(compact: metrics.compact)),
              GridView.count(
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: gap,
                crossAxisSpacing: gap,
                childAspectRatio: constraints.maxWidth / constraints.maxHeight,
                children: ArrangeQuadrants.displayOrder.map((quadrant) {
                  return _QuadrantPanel(
                    quadrant: quadrant,
                    events: _eventsFor(quadrant),
                    compact: metrics.compact,
                    onEventTap: onEventTap,
                  );
                }).toList(),
              ),
            ],
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

  const _QuadrantAxis({required this.compact});

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
            top: compact ? 0 : 2,
            left: 0,
            right: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_drop_up_rounded,
                  color: ArrangeStyle.accent,
                  size: compact ? 22 : 26,
                ),
                Text('紧急', style: labelStyle, textAlign: TextAlign.center),
              ],
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('重要', style: labelStyle),
                  Icon(
                    Icons.arrow_right_rounded,
                    color: ArrangeStyle.accent,
                    size: compact ? 20 : 24,
                  ),
                ],
              ),
            ),
          ),
        ],
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

  const _QuadrantPanel({
    required this.quadrant,
    required this.events,
    required this.compact,
    required this.onEventTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = quadrant.colors;
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: colors.softer.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border.withValues(alpha: 0.72)),
        boxShadow: ArrangeStyle.itemShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _QuadrantIcon(quadrant: quadrant, compact: compact),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  quadrant.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 13 : 15,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: ArrangeStyle.textPrimary,
                  ),
                ),
              ),
              Icon(
                Icons.more_vert_rounded,
                size: compact ? 17 : 19,
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
  }
}

class _QuadrantIcon extends StatelessWidget {
  final ArrangeQuadrantStyle quadrant;
  final bool compact;

  const _QuadrantIcon({required this.quadrant, required this.compact});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 30.0 : 34.0;
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
                _eventDisplayName(event),
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

  String _eventDisplayName(Event event) {
    final summary = event.summary.trim();
    if (summary.isNotEmpty) return summary;
    final title = event.title.trim();
    return title.isEmpty ? '(无标题)' : title;
  }
}
