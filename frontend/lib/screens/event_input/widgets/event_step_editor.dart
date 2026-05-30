import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../event_input_style.dart';
import 'measured_underline_text_field.dart';

class EventStepEditor extends StatefulWidget {
  const EventStepEditor({
    super.key,
    required this.stepIndex,
    required this.step,
    required this.suggestion,
    required this.isLast,
    required this.onDescriptionChanged,
    required this.onMinutesChanged,
    required this.onEmpty,
  });

  final int stepIndex;
  final StepItem step;
  final bool suggestion;
  final bool isLast;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<int> onMinutesChanged;
  final VoidCallback onEmpty;

  @override
  State<EventStepEditor> createState() => _EventStepEditorState();
}

class _EventStepEditorState extends State<EventStepEditor> {
  late final TextEditingController _descriptionController;
  late final TextEditingController _minutesController;
  late final FocusNode _descriptionFocusNode;
  late final FocusNode _minutesFocusNode;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.step.description,
    );
    _minutesController = TextEditingController(
      text: widget.step.estimatedMin.toString(),
    );
    _descriptionFocusNode = FocusNode();
    _minutesFocusNode = FocusNode();
    _descriptionFocusNode.addListener(_deleteWhenEmptyOnBlur);
  }

  @override
  void didUpdateWidget(covariant EventStepEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_descriptionFocusNode.hasFocus &&
        widget.step.description != _descriptionController.text) {
      _descriptionController.text = widget.step.description;
    }
    final minutesText = widget.step.estimatedMin.toString();
    if (!_minutesFocusNode.hasFocus && minutesText != _minutesController.text) {
      _minutesController.text = minutesText;
    }
  }

  @override
  void dispose() {
    _descriptionFocusNode.removeListener(_deleteWhenEmptyOnBlur);
    _descriptionController.dispose();
    _minutesController.dispose();
    _descriptionFocusNode.dispose();
    _minutesFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    final textColor = widget.suggestion
        ? EventInputStyle.textSecondary
        : EventInputStyle.textPrimary;
    final textStyle = TextStyle(
      color: textColor,
      fontSize: metrics.bodyTextSize,
      height: _stepTextLineHeight,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: metrics.isCompact ? 6 : 8),
      child: Padding(
        padding: EdgeInsets.only(left: _stepRowIndent(metrics)),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final timelineWidth = metrics.isCompact ? 12.0 : 14.0;
            final timelineGap = metrics.isCompact ? 8.0 : 10.0;
            final durationWidth = metrics.isCompact ? 54.0 : 60.0;
            final durationGap = metrics.isCompact ? 6.0 : 8.0;
            final contentWidth =
                constraints.maxWidth - timelineWidth - timelineGap;
            final textFieldWidth = math.max(
              0.0,
              contentWidth - metrics.stepLabelWidth,
            );
            final textLayout = _measureTextLayout(
              textStyle,
              textFieldWidth,
              durationWidth + durationGap,
            );
            final contentHeight = _stepRowTop + textLayout.height;
            final rowHeight = math.max(
              metrics.stepTimelineHeight,
              contentHeight + 6,
            );

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StepTimeline(isLast: widget.isLast, height: rowHeight),
                SizedBox(width: timelineGap),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: metrics.stepLabelWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: _stepRowTop),
                            child: Text(
                              '${_stepName(widget.stepIndex)}:',
                              style: textStyle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: contentHeight,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 0,
                                  top: _stepRowTop,
                                  right: 0,
                                  bottom: 0,
                                  child: _descriptionField(style: textStyle),
                                ),
                                Positioned(
                                  right: 0,
                                  top: _stepRowTop + textLayout.durationTop,
                                  width: durationWidth,
                                  child: _durationField(metrics: metrics),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _descriptionField({required TextStyle style}) {
    return MeasuredUnderlineTextField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      hintText: '',
      style: style,
      minLines: 1,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      contentPadding: _descriptionPadding,
      minUnderlineWidth: 72,
      underlineExtension: _stepUnderlineExtension,
      onChanged: (value) {
        if (value.trim().isEmpty) {
          widget.onEmpty();
          return;
        }
        setState(() {});
        widget.onDescriptionChanged(value);
      },
    );
  }

  Widget _durationField({required EventInputMetrics metrics}) {
    return TextField(
      controller: _minutesController,
      focusNode: _minutesFocusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      cursorColor: EventInputStyle.accent,
      style: TextStyle(
        color: EventInputStyle.accent,
        fontSize: metrics.bodyTextSize,
        fontStyle: FontStyle.italic,
      ),
      decoration: InputDecoration(
        isDense: true,
        suffixText: ' min',
        suffixStyle: TextStyle(
          color: EventInputStyle.accent,
          fontSize: metrics.bodyTextSize,
          fontStyle: FontStyle.italic,
        ),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(top: 1),
      ),
      onChanged: (value) {
        widget.onMinutesChanged(int.tryParse(value) ?? 0);
      },
    );
  }

  _StepTextLayout _measureTextLayout(
    TextStyle textStyle,
    double fieldWidth,
    double reservedDurationWidth,
  ) {
    final textWidth = math.max(
      0.0,
      fieldWidth - _descriptionPadding.horizontal,
    );
    if (textWidth <= 0) {
      return const _StepTextLayout(height: 28, durationTop: 0);
    }

    final painter = TextPainter(
      text: TextSpan(
        text: _descriptionController.text.isEmpty
            ? ' '
            : _descriptionController.text,
        style: textStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: textWidth);
    final lines = painter.computeLineMetrics();
    final fallbackLineHeight = (textStyle.fontSize ?? 14) * 1.35;
    final lineHeight = lines.isEmpty ? fallbackLineHeight : lines.first.height;
    final lineCount = math.max(1, lines.length);
    final lastLineWidth = _descriptionController.text.trim().isEmpty
        ? 0.0
        : lines.last.width + _stepUnderlineExtension;
    final durationThreshold = math.max(0.0, textWidth - reservedDurationWidth);
    final durationLineIndex =
        lastLineWidth >= durationThreshold && durationThreshold > 0
        ? lineCount
        : lineCount - 1;
    final visualLineCount = math.max(lineCount, durationLineIndex + 1);
    final height =
        _descriptionPadding.top +
        (visualLineCount * lineHeight) +
        _descriptionPadding.bottom;

    return _StepTextLayout(
      height: height,
      durationTop: _descriptionPadding.top + durationLineIndex * lineHeight,
    );
  }

  void _deleteWhenEmptyOnBlur() {
    if (mounted &&
        !_descriptionFocusNode.hasFocus &&
        _descriptionController.text.trim().isEmpty) {
      widget.onEmpty();
    }
  }

  String _stepName(int index) {
    const names = ['第一步', '第二步', '第三步', '第四步', '第五步', '第六步'];
    if (index < names.length) return names[index];
    return '第${index + 1}步';
  }

  double _stepRowIndent(EventInputMetrics metrics) {
    return metrics.isCompact ? 18 : 19;
  }
}

const _descriptionPadding = EdgeInsets.only(bottom: 8);
const _stepRowTop = 7.0;
const _stepTextLineHeight = 1.48;
const _stepUnderlineExtension = 18.0;

class _StepTextLayout {
  const _StepTextLayout({required this.height, required this.durationTop});

  final double height;
  final double durationTop;
}

class _StepTimeline extends StatelessWidget {
  const _StepTimeline({required this.isLast, required this.height});

  final bool isLast;
  final double height;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    final dotSize = metrics.isCompact ? 9.0 : 10.0;
    final firstLineHeight = metrics.bodyTextSize * _stepTextLineHeight;
    final dotTop = _stepRowTop + (firstLineHeight - dotSize) / 2;

    return SizedBox(
      width: metrics.isCompact ? 12 : 14,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: dotTop,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(
                color: EventInputStyle.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (!isLast)
            Positioned(
              top: dotTop + dotSize + 4,
              bottom: 0,
              child: Container(width: 1, color: EventInputStyle.border),
            ),
        ],
      ),
    );
  }
}
