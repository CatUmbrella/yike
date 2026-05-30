import 'package:flutter/material.dart';

import '../event_draft.dart';
import '../event_input_style.dart';
import 'event_duration_editor.dart';
import 'event_step_editor.dart';
import 'measured_underline_text_field.dart';

class EditableEventDetailCard extends StatelessWidget {
  const EditableEventDetailCard({
    super.key,
    required this.draftIndex,
    required this.draft,
    required this.onDelete,
    required this.onReset,
    required this.onTitleChanged,
    required this.onSummaryChanged,
    required this.onPurposeChanged,
    required this.onStepDescriptionChanged,
    required this.onStepMinutesChanged,
    required this.onAddStep,
    required this.onRemoveStep,
  });

  final int draftIndex;
  final EventDraft draft;
  final VoidCallback onDelete;
  final VoidCallback onReset;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onSummaryChanged;
  final ValueChanged<String> onPurposeChanged;
  final void Function(int stepIndex, String value) onStepDescriptionChanged;
  final void Function(int stepIndex, int value) onStepMinutesChanged;
  final VoidCallback onAddStep;
  final ValueChanged<int> onRemoveStep;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    final event = draft.event;
    final suggestionColor = draft.fromAi && !draft.edited
        ? EventInputStyle.textSecondary
        : EventInputStyle.textPrimary;

    return Container(
      padding: metrics.cardPadding,
      decoration: BoxDecoration(
        color: EventInputStyle.card,
        borderRadius: BorderRadius.circular(metrics.cardRadius),
        border: Border.all(color: EventInputStyle.border),
        boxShadow: EventInputStyle.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _DraftTextField(
                  value: event.title,
                  hintText: '事件名称',
                  style: TextStyle(
                    color: EventInputStyle.textPrimary,
                    fontSize: metrics.cardTitleSize,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: onTitleChanged,
                ),
              ),
              SizedBox(width: metrics.isCompact ? 8 : 12),
              EventDurationEditor(totalMinutes: draft.displayTotalMinutes),
            ],
          ),
          SizedBox(height: metrics.isCompact ? 8 : 10),
          const Divider(height: 1, color: EventInputStyle.divider),
          SizedBox(height: metrics.isCompact ? 10 : 12),
          _SectionEditor(
            label: '目的:',
            value: event.purpose,
            hintText: '这件事的目的',
            textColor: suggestionColor,
            onChanged: onPurposeChanged,
          ),
          SizedBox(height: metrics.isCompact ? 14 : 16),
          const _SectionTitle(label: '怎么做:'),
          SizedBox(height: metrics.isCompact ? 10 : 12),
          if (event.steps.isEmpty)
            Padding(
              padding: EdgeInsets.only(
                left: metrics.isCompact ? 20 : 24,
                bottom: metrics.isCompact ? 12 : 16,
              ),
              child: Text(
                '暂无步骤，点击加号添加',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: metrics.bodyTextSize,
                ),
              ),
            )
          else
            ...List.generate(event.steps.length, (stepIndex) {
              final step = event.steps[stepIndex];
              return EventStepEditor(
                key: ValueKey('draft-$draftIndex-step-${step.stepOrder}'),
                stepIndex: stepIndex,
                step: step,
                suggestion: draft.stepIsAiSuggestion(stepIndex),
                isLast: stepIndex == event.steps.length - 1,
                onDescriptionChanged: (value) {
                  onStepDescriptionChanged(stepIndex, value);
                },
                onMinutesChanged: (value) {
                  onStepMinutesChanged(stepIndex, value);
                },
                onEmpty: () => onRemoveStep(stepIndex),
              );
            }),
          SizedBox(height: metrics.isCompact ? 6 : 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: '添加步骤',
                onPressed: onAddStep,
                icon: Icon(
                  Icons.add_rounded,
                  size: metrics.isCompact ? 27 : 29,
                ),
                color: EventInputStyle.accent,
                style: IconButton.styleFrom(
                  side: const BorderSide(color: EventInputStyle.accent),
                  fixedSize: Size.square(metrics.isCompact ? 36 : 40),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Spacer(),
              if (draft.fromAi)
                OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EventInputStyle.accent,
                    side: const BorderSide(color: EventInputStyle.accent),
                    minimumSize: Size(metrics.isCompact ? 104 : 116, 38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                    ),
                    textStyle: TextStyle(
                      fontSize: metrics.isCompact ? 12 : 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('重置ai建议'),
                ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: onDelete,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  foregroundColor: Colors.white,
                  minimumSize: Size(metrics.isCompact ? 66 : 72, 38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(19),
                  ),
                  textStyle: TextStyle(
                    fontSize: metrics.isCompact ? 12 : 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Row(
      children: [
        const _BlueBullet(),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: EventInputStyle.textPrimary,
            fontSize: metrics.sectionTitleSize,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _SectionEditor extends StatelessWidget {
  const _SectionEditor({
    required this.label,
    required this.value,
    required this.hintText,
    required this.textColor,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String hintText;
  final Color textColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: metrics.isCompact ? 10 : 11),
          child: const _BlueBullet(),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: EdgeInsets.only(top: metrics.isCompact ? 3 : 4),
          child: Text(
            label,
            style: TextStyle(
              color: EventInputStyle.textPrimary,
              fontSize: metrics.sectionTitleSize,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DraftTextField(
            value: value,
            hintText: hintText,
            style: TextStyle(
              color: textColor,
              fontSize: metrics.bodyTextSize,
              height: 1.35,
            ),
            minLines: 1,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            measuredUnderline: true,
            underlinePadding: const EdgeInsets.only(top: 1, bottom: 5),
            minUnderlineWidth: metrics.isCompact ? 78 : 88,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _BlueBullet extends StatelessWidget {
  const _BlueBullet();

  @override
  Widget build(BuildContext context) {
    final metrics = EventInputMetrics.of(context);
    final size = metrics.isCompact ? 8.0 : 9.0;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: EventInputStyle.accent,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DraftTextField extends StatefulWidget {
  const _DraftTextField({
    required this.value,
    required this.hintText,
    required this.style,
    required this.decoration,
    required this.onChanged,
    this.minLines,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.measuredUnderline = false,
    this.underlinePadding = EdgeInsets.zero,
    this.minUnderlineWidth = 72,
  });

  final String value;
  final String hintText;
  final TextStyle style;
  final InputDecoration decoration;
  final ValueChanged<String> onChanged;
  final int? minLines;
  final int? maxLines;
  final TextInputType keyboardType;
  final bool measuredUnderline;
  final EdgeInsets underlinePadding;
  final double minUnderlineWidth;

  @override
  State<_DraftTextField> createState() => _DraftTextFieldState();
}

class _DraftTextFieldState extends State<_DraftTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _DraftTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.measuredUnderline) {
      return MeasuredUnderlineTextField(
        controller: _controller,
        focusNode: _focusNode,
        hintText: widget.hintText,
        style: widget.style,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        minLines: widget.minLines ?? 1,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        contentPadding: widget.underlinePadding,
        minUnderlineWidth: widget.minUnderlineWidth,
        onChanged: widget.onChanged,
      );
    }

    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      cursorColor: EventInputStyle.accent,
      style: widget.style,
      decoration: widget.decoration.copyWith(
        hintText: widget.hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      onChanged: widget.onChanged,
    );
  }
}
