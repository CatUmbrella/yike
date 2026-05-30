import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../arrange_constants.dart';
import '../arrange_helpers.dart';

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
    final card = _buildCard(opacity: 1);
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
      childWhenDragging: _buildCard(opacity: 0.32),
      onDraggableCanceled: (_, _) => onDragCanceled?.call(),
      child: card,
    );
  }

  Widget _buildCard({required double opacity}) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.title.isEmpty ? '(无标题)' : event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              if (isDeleted && onRestore != null)
                GestureDetector(
                  onTap: onRestore,
                  child: const Text(
                    '恢复',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                )
              else
                Text(
                  durationText(event.totalMinutes),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
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
        final height = _lerp(34, eventBoxFeedbackEndHeight, value);
        final radius = _lerp(8, 6, value);
        final horizontalPadding = _lerp(10, 3, value);
        final fontSize = _lerp(14, 6.5, value);
        final dotSize = _lerp(16, 0, value);
        final dotGap = _lerp(10, 0, value);

        return Opacity(
          opacity: _lerp(0.9, 0.78, value),
          child: Container(
            width: width,
            height: height,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.grey.shade600),
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
                      color: Colors.grey.shade600,
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
                      color: Colors.black,
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
