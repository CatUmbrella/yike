import 'package:flutter/material.dart';

import '../event_input_style.dart';

class EventInputActions extends StatelessWidget {
  const EventInputActions({
    super.key,
    required this.onAddCustomEvent,
    required this.onVoiceInput,
  });

  final VoidCallback onAddCustomEvent;
  final VoidCallback onVoiceInput;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: metrics.actionBarHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EventInputStyle.card,
              borderRadius: BorderRadius.circular(metrics.actionBarHeight / 2),
              boxShadow: EventInputStyle.softShadow,
            ),
            child: IconButton(
              tooltip: '自定义事件',
              onPressed: onAddCustomEvent,
              icon: Icon(
                Icons.add_rounded,
                color: EventInputStyle.accent,
                size: metrics.addIconSize,
              ),
            ),
          ),
        ),
        SizedBox(height: metrics.isCompact ? 12 : 16),
        SizedBox(
          width: metrics.micButtonSize,
          height: metrics.micButtonSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: EventInputStyle.card,
              shape: BoxShape.circle,
              boxShadow: EventInputStyle.softShadow,
            ),
            child: IconButton(
              tooltip: '语音输入',
              onPressed: onVoiceInput,
              icon: Icon(
                Icons.mic_none_rounded,
                color: EventInputStyle.accent,
                size: metrics.micIconSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
