import 'package:flutter/material.dart';

import '../event_input_style.dart';
import 'event_duration_formatter.dart';
import 'event_duration_picker_sheet.dart';

class EventDurationEditor extends StatelessWidget {
  const EventDurationEditor({
    super.key,
    required this.totalMinutes,
    required this.onChanged,
  });

  final int totalMinutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Semantics(
      button: true,
      label: '修改预计耗时',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          FocusScope.of(context).unfocus();
          final selectedMinutes = await showEventDurationPickerSheet(
            context: context,
            initialMinutes: totalMinutes,
          );
          if (selectedMinutes != null) onChanged(selectedMinutes);
        },
        child: Row(
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
              formatEventDuration(totalMinutes),
              style: TextStyle(
                fontSize: metrics.durationValueSize,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: EventInputStyle.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
