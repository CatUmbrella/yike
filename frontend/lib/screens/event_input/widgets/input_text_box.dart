import 'package:flutter/material.dart';

import '../event_input_style.dart';

class InputTextBox extends StatelessWidget {
  const InputTextBox({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.parsing,
    required this.onChanged,
    required this.onSubmitted,
    required this.onParseNow,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool parsing;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final VoidCallback onParseNow;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Container(
      height: metrics.inputHeight,
      padding: metrics.inputPadding,
      decoration: BoxDecoration(
        color: EventInputStyle.card,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(color: EventInputStyle.border),
        boxShadow: EventInputStyle.softShadow,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            bottom: metrics.inputButtonHeight + 10,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              expands: true,
              maxLines: null,
              minLines: null,
              textInputAction: TextInputAction.newline,
              cursorColor: EventInputStyle.accent,
              style: TextStyle(
                color: EventInputStyle.textPrimary,
                fontSize: metrics.inputTextSize,
                height: 1.35,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: '点击输入或长按讲话ai会自动区分事件',
                hintStyle: TextStyle(
                  color: const Color(0xFF9AA6B8),
                  fontSize: metrics.inputTextSize,
                  fontStyle: FontStyle.italic,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
              onEditingComplete: onSubmitted,
            ),
          ),
          if (parsing)
            Positioned(
              left: 0,
              bottom: metrics.isCompact ? 2 : 3,
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: EventInputStyle.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '正在拆解计划中...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: metrics.bodyTextSize,
                    ),
                  ),
                ],
              ),
            ),
          Positioned(
            right: 0,
            bottom: 0,
            child: OutlinedButton.icon(
              onPressed: parsing ? null : onParseNow,
              icon: Icon(Icons.auto_awesome, size: metrics.isCompact ? 16 : 18),
              label: const Text('AI拆解'),
              style: OutlinedButton.styleFrom(
                foregroundColor: EventInputStyle.accent,
                disabledForegroundColor: EventInputStyle.accent.withValues(
                  alpha: 0.45,
                ),
                side: const BorderSide(color: EventInputStyle.border),
                minimumSize: Size(
                  metrics.inputButtonWidth,
                  metrics.inputButtonHeight,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: metrics.isCompact ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(
                  fontSize: metrics.inputButtonFontSize,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
