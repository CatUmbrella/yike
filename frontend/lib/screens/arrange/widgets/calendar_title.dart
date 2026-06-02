import 'package:flutter/material.dart';

import '../arrange_style.dart';

class CalendarTitle extends StatelessWidget {
  final String title;
  final String dateText;
  final String actionText;
  final VoidCallback onActionTap;

  const CalendarTitle({
    super.key,
    required this.title,
    required this.dateText,
    required this.actionText,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final metrics = ArrangeLayoutMetrics.forWidth(
      MediaQuery.sizeOf(context).width,
    );
    return SizedBox(
      height: metrics.calendarHeaderHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: metrics.calendarTitleSize,
              fontWeight: FontWeight.bold,
              color: ArrangeStyle.textPrimary,
              height: 1,
            ),
          ),
          SizedBox(width: metrics.compact ? 10 : 14),
          Text(
            dateText,
            style: TextStyle(
              fontSize: metrics.compact ? 12 : 14,
              fontWeight: FontWeight.w600,
              color: ArrangeStyle.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onActionTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: metrics.compact ? 12 : 14,
                  fontWeight: FontWeight.w600,
                  color: ArrangeStyle.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
