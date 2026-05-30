import 'package:flutter/material.dart';

class CalendarGridCell extends StatelessWidget {
  final int column;
  final double? width;
  final EdgeInsets padding;
  final Color? color;
  final Widget child;

  const CalendarGridCell({
    super.key,
    required this.column,
    required this.child,
    this.width,
    this.padding = EdgeInsets.zero,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border(
          left: column == 0
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade600),
          top: BorderSide(color: Colors.grey.shade600),
          right: BorderSide.none,
          bottom: BorderSide.none,
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}
