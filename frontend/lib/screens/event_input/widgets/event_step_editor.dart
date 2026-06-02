import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../event_input_style.dart';
import 'event_duration_formatter.dart';
import 'event_duration_picker_sheet.dart';
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
  late final FocusNode _descriptionFocusNode;
  MeasuredUnderlineTextLayout? _descriptionTextLayout;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.step.description,
    );
    _descriptionFocusNode = FocusNode();
    _descriptionFocusNode.addListener(_deleteWhenEmptyOnBlur);
  }

  @override
  void didUpdateWidget(covariant EventStepEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_descriptionFocusNode.hasFocus &&
        widget.step.description != _descriptionController.text) {
      _descriptionController.text = widget.step.description;
      _descriptionTextLayout = null;
    }
  }

  @override
  void dispose() {
    _descriptionFocusNode.removeListener(_deleteWhenEmptyOnBlur);
    _descriptionController.dispose();
    _descriptionFocusNode.dispose();
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
        padding: const EdgeInsets.only(left: _stepRowIndent),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const timelineWidth = _stepTimelineWidth;
            final timelineGap = metrics.isCompact ? 8.0 : 10.0;
            final durationWidth = metrics.isCompact ? 70.0 : 82.0;
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
      textAreaInset: _stepTextAreaInset,
      fullWidthLine: true,
      onTextLayoutChanged: _handleTextLayoutChanged,
      onChanged: (value) {
        setState(() {});
        if (value.trim().isEmpty) return;
        widget.onDescriptionChanged(value);
      },
    );
  }

  Widget _durationField({required EventInputMetrics metrics}) {
    return Semantics(
      button: true,
      label: '修改预计耗时',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showDurationPicker,
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            formatEventDuration(widget.step.estimatedMin),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: EventInputStyle.accent,
              fontSize: metrics.bodyTextSize,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDurationPicker() async {
    FocusScope.of(context).unfocus();
    final selectedMinutes = await showEventDurationPickerSheet(
      context: context,
      initialMinutes: widget.step.estimatedMin,
    );
    if (!mounted || selectedMinutes == null) return;
    widget.onMinutesChanged(selectedMinutes);
  }

  _StepTextLayout _measureTextLayout(
    TextStyle textStyle,
    double fieldWidth,
    double reservedDurationWidth,
  ) {
    final textWidth = math.max(
      0.0,
      fieldWidth - _descriptionPadding.horizontal - _stepTextAreaInset,
    );
    if (textWidth <= 0) {
      return const _StepTextLayout(height: 28, durationTop: 0);
    }

    final liveLayout = _descriptionTextLayout;
    if (liveLayout != null && liveLayout.text == _descriptionController.text) {
      return _layoutFromLineInfo(
        lineCount: liveLayout.lineCount,
        lineHeight: liveLayout.lineHeight,
        lastLineWidth: _descriptionController.text.trim().isEmpty
            ? 0.0
            : liveLayout.lastLineWidth + _stepUnderlineExtension,
        textWidth: textWidth,
        reservedDurationWidth: reservedDurationWidth,
      );
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
    return _layoutFromLineInfo(
      lineCount: lineCount,
      lineHeight: lineHeight,
      lastLineWidth: lastLineWidth,
      textWidth: textWidth,
      reservedDurationWidth: reservedDurationWidth,
    );
  }

  _StepTextLayout _layoutFromLineInfo({
    required int lineCount,
    required double lineHeight,
    required double lastLineWidth,
    required double textWidth,
    required double reservedDurationWidth,
  }) {
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

  void _handleTextLayoutChanged(MeasuredUnderlineTextLayout layout) {
    if (!mounted || layout == _descriptionTextLayout) return;
    setState(() {
      _descriptionTextLayout = layout;
    });
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
}

const _descriptionPadding = EdgeInsets.only(bottom: 8);
const _stepRowTop = 7.0;
const _stepRowIndent = 19.0;
const _stepTextLineHeight = 1.48;
const _stepUnderlineExtension = 18.0;
const _stepTextAreaInset = 2.0;

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
    const dotSize = _stepDotSize;
    final firstLineHeight = metrics.bodyTextSize * _stepTextLineHeight;
    final dotTop = _stepRowTop + (firstLineHeight - dotSize) / 2;

    return SizedBox(
      width: _stepTimelineWidth,
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

const _stepDotSize = 10.0;
const _stepTimelineWidth = 14.0;
