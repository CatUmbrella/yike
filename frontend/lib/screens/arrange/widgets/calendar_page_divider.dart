import 'package:flutter/material.dart';

class CalendarPageDivider extends StatelessWidget {
  final PageController controller;
  final int pageIndex;
  final double width;

  const CalendarPageDivider({
    super.key,
    required this.controller,
    required this.pageIndex,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final page = controller.hasClients
            ? controller.page ?? pageIndex.toDouble()
            : pageIndex.toDouble();
        final fraction = page - page.floorToDouble();
        final distanceFromRest = fraction < 0.5 ? fraction : 1.0 - fraction;
        if (distanceFromRest < 0.001) return const SizedBox.shrink();

        final rawLeft = (1.0 - fraction) * width;
        final maxLeft = width > 1 ? width - 1 : 0.0;
        final left = rawLeft.clamp(0.0, maxLeft).toDouble();

        return Positioned(
          left: left,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(width: 1, color: Colors.grey.shade600),
          ),
        );
      },
    );
  }
}
