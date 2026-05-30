import 'package:flutter/material.dart';

import '../event_input_style.dart';

class EventDurationEditor extends StatelessWidget {
  const EventDurationEditor({super.key, required this.totalMinutes});

  final int totalMinutes;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '预计耗时:',
          style: TextStyle(
            color: EventInputStyle.textPrimary,
            fontSize: metrics.durationLabelSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${totalMinutes}min',
          style: TextStyle(
            fontSize: metrics.durationValueSize,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: EventInputStyle.accent,
          ),
        ),
      ],
    );
  }
}
