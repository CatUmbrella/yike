import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
import '../arrange_helpers.dart';
import '../arrange_style.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final bool isDeleted;
  final bool canDrag;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onDragCanceled;
  final VoidCallback? onRestore;

  const EventCard({
    super.key,
    required this.event,
    required this.isDeleted,
    required this.canDrag,
    this.onTap,
    this.onDoubleTap,
    this.onDragCanceled,
    this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final card = _buildCard(opacity: 1, metrics: metrics);
    if (!canDrag) return card;

    return LongPressDraggable<Event>(
      data: event,
      maxSimultaneousDrags: 1,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.translate(
          offset: const Offset(
            -eventBoxFeedbackEndWidth / 2,
            -eventBoxFeedbackEndHeight / 2,
          ),
          child: _EventDragFeedback(event: event),
        ),
      ),
      childWhenDragging: _buildCard(opacity: 0.32, metrics: metrics),
      onDraggableCanceled: (_, _) => onDragCanceled?.call(),
      child: card,
    );
  }

  Widget _buildCard({
    required double opacity,
    required ArrangeLayoutMetrics metrics,
  }) {
    final colors = ArrangeQuadrants.colorsFor(event.quadrant);
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: metrics.eventCardHeight,
          padding: EdgeInsets.symmetric(horizontal: metrics.compact ? 12 : 16),
          decoration: BoxDecoration(
            color: colors.softer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
            boxShadow: ArrangeStyle.itemShadow,
          ),
          child: Row(
            children: [
              Container(
                width: metrics.compact ? 9 : 10,
                height: metrics.compact ? 9 : 10,
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: metrics.compact ? 10 : 14),
              Expanded(
                child: Text(
                  event.title.isEmpty ? '(无标题)' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: metrics.compact ? 14 : 16,
                    fontWeight: FontWeight.w500,
                    color: ArrangeStyle.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (isDeleted && onRestore != null)
                GestureDetector(
                  onTap: onRestore,
                  child: const Text(
                    '恢复',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ArrangeStyle.accent,
                    ),
                  ),
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: metrics.compact ? 10 : 12,
                    vertical: metrics.compact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.badge,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    durationText(event.totalMinutes),
                    style: TextStyle(
                      fontSize: metrics.compact ? 13 : 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: colors.accent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDragFeedback extends StatelessWidget {
  final Event event;

  const _EventDragFeedback({required this.event});

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    final colors = ArrangeQuadrants.colorsFor(event.quadrant);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final width = _lerp(
          eventBoxFeedbackStartWidth,
          eventBoxFeedbackEndWidth,
          value,
        );
        final height = _lerp(
          metrics.eventCardHeight,
          eventBoxFeedbackEndHeight,
          value,
        );
        final radius = _lerp(16, 6, value);
        final horizontalPadding = _lerp(metrics.compact ? 12 : 16, 3, value);
        final fontSize = _lerp(metrics.compact ? 15 : 17, 6.5, value);
        final dotSize = _lerp(metrics.compact ? 9 : 10, 0, value);
        final dotGap = _lerp(metrics.compact ? 10 : 14, 0, value);

        return Opacity(
          opacity: _lerp(0.9, 0.78, value),
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.softer,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: colors.accent.withValues(alpha: 0.28)),
              boxShadow: ArrangeStyle.itemShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 1 - value,
                  child: Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                SizedBox(width: dotGap),
                Expanded(
                  child: Text(
                    event.summary.isNotEmpty ? event.summary : event.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1,
                      color: ArrangeStyle.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _lerp(double begin, double end, double value) {
    return begin + (end - begin) * value;
  }
}
