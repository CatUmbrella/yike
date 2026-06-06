import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../arrange_style.dart';
import 'round_button.dart';

class DraggableAddButton extends StatefulWidget {
  const DraggableAddButton({
    super.key,
    required this.constraints,
    required this.offset,
    required this.onOffsetChanged,
    required this.onTap,
  });

  final BoxConstraints constraints;
  final Offset? offset;
  final ValueChanged<Offset> onOffsetChanged;
  final VoidCallback onTap;

  @override
  State<DraggableAddButton> createState() => _DraggableAddButtonState();
}

class _DraggableAddButtonState extends State<DraggableAddButton> {
  bool _isDragging = false;
  Offset? _dragOffset;

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(widget.constraints.maxWidth);
    final buttonSize = metrics.compact ? 54.0 : 62.0;
    final sideMargin = metrics.horizontalMargin + 14;
    final topMargin = metrics.compact ? 10.0 : 14.0;
    final bottomMargin = (metrics.compact ? 10.0 : 14.0) + 16;
    final defaultOffset = Offset(
      widget.constraints.maxWidth - buttonSize - sideMargin,
      widget.constraints.maxHeight - buttonSize - bottomMargin,
    );
    final baseOffset = _clampOffset(
      widget.offset ?? defaultOffset,
      buttonSize,
      sideMargin,
      topMargin,
      bottomMargin,
    );
    final currentOffset = _isDragging
        ? (_dragOffset ?? baseOffset)
        : baseOffset;

    return AnimatedPositioned(
      duration: _isDragging ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      left: currentOffset.dx,
      top: currentOffset.dy,
      width: buttonSize,
      height: buttonSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
            _dragOffset = currentOffset;
          });
          widget.onOffsetChanged(currentOffset);
        },
        onPanUpdate: (details) {
          final nextOffset = _clampOffset(
            (_dragOffset ?? currentOffset) + details.delta,
            buttonSize,
            sideMargin,
            topMargin,
            bottomMargin,
          );
          setState(() => _dragOffset = nextOffset);
          widget.onOffsetChanged(nextOffset);
        },
        onPanEnd: (_) {
          final offset = _dragOffset ?? currentOffset;
          final targetLeft =
              offset.dx + buttonSize / 2 < widget.constraints.maxWidth / 2
              ? sideMargin
              : widget.constraints.maxWidth - buttonSize - sideMargin;
          final snappedOffset = _clampOffset(
            Offset(targetLeft, offset.dy),
            buttonSize,
            sideMargin,
            topMargin,
            bottomMargin,
          );
          widget.onOffsetChanged(snappedOffset);
          setState(() {
            _isDragging = false;
            _dragOffset = null;
          });
        },
        onPanCancel: () {
          setState(() {
            _isDragging = false;
            _dragOffset = null;
          });
        },
        child: Opacity(
          opacity: _isDragging ? 0.86 : 1,
          child: RoundButton(
            icon: Icons.add,
            color: ArrangeStyle.accent,
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }

  Offset _clampOffset(
    Offset offset,
    double buttonSize,
    double sideMargin,
    double topMargin,
    double bottomMargin,
  ) {
    final maxLeft = math.max(
      sideMargin,
      widget.constraints.maxWidth - buttonSize - sideMargin,
    );
    final maxTop = math.max(
      topMargin,
      widget.constraints.maxHeight - buttonSize - bottomMargin,
    );
    return Offset(
      offset.dx.clamp(sideMargin, maxLeft).toDouble(),
      offset.dy.clamp(topMargin, maxTop).toDouble(),
    );
  }
}
